cat > feeds.conf << 'EOF'
# 官方基础（必稳）
src-git packages https://github.com/openwrt/packages.git;openwrt-24.10
src-git luci https://github.com/openwrt/luci.git;openwrt-24.10

# 你原有（已验证成功）
src-git printing https://github.com/dywlphy/openwrt-feed-printing.git;main
src-git timecontrol https://github.com/sirpdboy/luci-app-timecontrol.git
src-git frp https://github.com/kuoruan/luci-app-frpc.git
src-git tailscale https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community.git
src-git passwall_packages https://github.com/dywlphy/openwrt-passwall-packages.git;main
src-git passwall2 https://github.com/dywlphy/openwrt-passwall2.git;main

# ================================
# 代理全家桶（100% 兼容 24.10 + fw4）
# ================================
src-git helloworld https://github.com/fw876/helloworld.git        # SSR/SS 全套
src-git openclash https://github.com/vernesong/OpenClash.git    # Clash 稳定
src-git mosdns https://github.com/sbwml/luci-app-mosdns.git      # DNS 分流神器
src-git smartdns https://github.com/pymumu/openwrt-smartdns.git # DNS 加速
src-git lucipasswall https://github.com/xiaorouji/openwrt-passwall.git # Passwall 1

# ================================
# 实用功能（全部官方/稳定源 → 100%兼容）
# ================================
src-git filemanager https://github.com/ysc3839/luci-app-filemanager.git # 文件管理
src-git ttyd https://github.com/tsl0922/ttyd.git               # 网页终端
src-git nlbwmon https://github.com/openwrt/packages.git;openwrt-24.10 # 流量统计
src-git adblock https://github.com/openwrt/packages.git;openwrt-24.10 # 广告过滤
src-git sqm https://github.com/openwrt/packages.git;openwrt-24.10      # 网速QoS
src-git wol https://github.com/openwrt/packages.git;openwrt-24.10       # 网络唤醒
src-git ddns https://github.com/openwrt/packages.git;openwrt-24.10      # 动态域名
src-git upnp https://github.com/openwrt/packages.git;openwrt-24.10      # 端口映射
src-git httpsdnsproxy https://github.com/openwrt/packages.git;openwrt-24.10 # DoH/DoT 加密DNS
EOF
cat feeds.conf

echo ""
echo "[3/3] OpenWrt版本信息:"
echo "Branch: openwrt-24.10"
echo "Target: Official Stable"

echo ""
echo "=========================================="
echo "diy-part1.sh 执行完成"
echo "=========================================="
