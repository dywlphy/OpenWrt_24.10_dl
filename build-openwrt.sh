#!/bin/bash
#
# build-openwrt.sh - OpenWrt 本地编译脚本
# GitHub 云端下载源码 + 本地编译
#
set -e

WORKDIR="/mnt/ramdisk/openwrt"
SRC="$WORKDIR/openwrt"
CONFIG_DIR="/root/openwrt-config"
DL_CACHE="/root/openwrt-dl-cache"
OUTPUT_DIR="/root/openwrt-output"
BUILD_LOG="$WORKDIR/build.log"
THREADS=$(nproc)

echo "=========================================="
echo " OpenWrt 24.10 本地编译"
echo " 编译目录: $WORKDIR (tmpfs 内存盘)"
echo " CPU 线程: $THREADS"
echo "=========================================="

# ============================================
# 0. 检查环境
# ============================================
echo ""
echo "[0/9] 检查环境..."

if ! mountpoint -q /mnt/ramdisk/openwrt; then
    echo " ⚠️ tmpfs 未挂载，正在挂载..."
    mount -t tmpfs -o size=50g,nr_inodes=5m,mode=1777 tmpfs /mnt/ramdisk/openwrt
fi

if [ ! -f "$CONFIG_DIR/24.10_config.txt" ]; then
    echo " ❌ 配置文件不存在: $CONFIG_DIR/24.10_config.txt"
    echo " 请将 24.10_diy-part1.sh、24.10_diy-part2.sh、24.10_config.txt"
    echo " 放入 $CONFIG_DIR/ 目录"
    exit 1
fi

echo " ✅ 环境检查通过"
df -h /mnt/ramdisk/openwrt | tail -1
free -h | head -2

# ============================================
# 1. 克隆源码
# ============================================
echo ""
echo "[1/9] 克隆 OpenWrt 源码..."
if [ -d "$SRC" ]; then
    echo " ✅ 源码已存在，跳过克隆"
else
    git clone -b openwrt-24.10 --single-branch --depth 1 \
      https://github.com/openwrt/openwrt.git "$SRC"
    echo " ✅ 源码克隆完成"
fi

cd "$SRC"

# ============================================
# 2. 配置 feeds 源
# ============================================
echo ""
echo "[2/9] 配置 feeds 源..."
cp "$CONFIG_DIR/24.10_diy-part1.sh ./
bash 24.10_diy-part1.sh

# ============================================
# 3. 更新 feeds
# ============================================
echo ""
echo "[3/9] 更新 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a
# 排除 geoview（Go >= 1.25.0 required）
./scripts/feeds uninstall -p passwall_packages geoview 2>/dev/null || true
echo " ✅ feeds 更新完成"

# ============================================
# 4. 加载配置 + diy-part2
# ============================================
echo ""
echo "[4/9] 加载配置..."
cp "$CONFIG_DIR/24.10_config.txt" .config
cp "$CONFIG_DIR/24.10_diy-part2.sh ./
# 设置 GITHUB_WORKSPACE 指向配置目录（diy-part2.sh 需要从此目录找 CUPS-zh.zip 和 cups.mo）
export GITHUB_WORKSPACE="$CONFIG_DIR"
bash 24.10_diy-part2.sh

# defconfig + 禁用冲突包
make defconfig
sed -i 's/CONFIG_PACKAGE_geoview=[ym]/# CONFIG_PACKAGE_geoview is not set/' .config
sed -i 's/CONFIG_PACKAGE_dnsmasq=[ym]/# CONFIG_PACKAGE_dnsmasq is not set/' .config
sed -i 's/CONFIG_PACKAGE_kmod-fullconenat=[ym]/# CONFIG_PACKAGE_kmod-fullconenat is not set/' .config
sed -i 's/CONFIG_PACKAGE_kmod-ipt-nat6=[ym]/# CONFIG_PACKAGE_kmod-ipt-nat6 is not set/' .config
sed -i 's/CONFIG_PACKAGE_v2ray-plugin=[ym]/# CONFIG_PACKAGE_v2ray-plugin is not set/' .config
make defconfig
echo " ✅ 配置加载完成"

# ============================================
# 5. dl 缓存（关键！）
# ============================================
echo ""
echo "[5/9] 检查 dl 缓存..."
if [ -d "$DL_CACHE" ] && [ "$(ls -A $DL_CACHE 2>/dev/null)" ]; then
    DL_SIZE=$(du -sh "$DL_CACHE" | cut -f1)
    echo " ✅ 发现 dl 缓存 ($DL_SIZE)，复制中..."
    mkdir -p dl
    cp -rn "$DL_CACHE"/* dl/ 2>/dev/null || true
    DL_COPIED=$(ls dl/ 2>/dev/null | wc -l)
    echo " ✅ dl 缓存已复制 ($DL_COPIED 个文件)"
else
    echo " ⚠️ 无 dl 缓存，需要下载所有源码"
    echo " 💡 建议：先在 GitHub Actions 跑「只下载」模式，再下载 artifact 到 $DL_CACHE"
fi

# ============================================
# 6. 下载缺失源码
# ============================================
echo ""
echo "[6/9] 下载缺失源码..."
for i in 1 2 3; do
    if make download -j$THREADS; then
        echo " ✅ 源码下载完成"
        break
    fi
    echo " ⚠️ 下载失败，重试第 $i 次..."
    sleep 30
done

# 清理不完整文件
find dl -size -1024c -exec rm -f {} \;

# 保存 dl 缓存到硬盘（下次编译复用）
echo " 💾 保存 dl 缓存到硬盘..."
mkdir -p "$DL_CACHE"
cp -rn dl/* "$DL_CACHE/" 2>/dev/null || true
echo " ✅ dl 缓存已保存 ($(du -sh $DL_CACHE | cut -f1))"

# ============================================
# 7. 编译
# ============================================
echo ""
echo "[7/9] 开始编译 ($THREADS 线程)..."
echo " 开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
START_TIME=$(date +%s)

if make -j$THREADS V=s 2>&1 | tee "$BUILD_LOG"; then
    BUILD_OK=true
else
    # 单线程重试（定位错误）
    echo ""
    echo " ⚠️ 多线程编译失败，单线程重试定位错误..."
    make -j1 V=s 2>&1 | tee -a "$BUILD_LOG"
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        BUILD_OK=true
    else
        BUILD_OK=false
    fi
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# ============================================
# 8. 结果
# ============================================
echo ""
echo "=========================================="
echo " 编译结果"
echo "=========================================="
echo " 耗时: ${MINUTES}分${SECONDS}秒"
echo ""

if [ "$BUILD_OK" = true ]; then
    echo " ✅ 编译成功！"
    echo ""
    echo "固件文件:"
    ls -lh bin/targets/x86/64/*.img.gz 2>/dev/null
    echo ""
    # 保存固件到持久化目录
    SAVE_DIR="$OUTPUT_DIR/$(date +%Y%m%d-%H%M)"
    mkdir -p "$SAVE_DIR"
    cp bin/targets/x86/64/*.img.gz "$SAVE_DIR/" 2>/dev/null
    cp bin/targets/x86/64/*.sha256sums "$SAVE_DIR/" 2>/dev/null
    cp "$BUILD_LOG" "$SAVE_DIR/" 2>/dev/null
    echo " ✅ 固件已保存到: $SAVE_DIR"
else
    echo " ❌ 编译失败！"
    echo ""
    echo "错误信息（最后 30 行）:"
    grep -E "(Error|error:|FAIL|failed|Killed)" "$BUILD_LOG" | tail -30
    echo ""
    echo "完整日志: $BUILD_LOG"
    echo ""
    echo "调试方法:"
    echo "  cd $SRC"
    echo "  grep -n 'Error' $BUILD_LOG | tail -20"
    echo "  cd build_dir/target-x86_64_musl/失败包名/"
    echo "  cat config.log"
fi

echo ""
echo "=========================================="
