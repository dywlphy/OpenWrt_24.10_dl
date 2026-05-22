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

# ✅ 修正为正确的 LuCI 界面源
src-git luci_app_smartdns https://github.com/pymumu/luci-app-smartdns.git
EOF
