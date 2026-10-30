# 兆能 ZN-M2 OpenWrt 固件

无 WiFi / 无 USB · 内核 4.4.60 · 推荐内存 512M+

感谢 [sdf8057](https://github.com/sdf8057/ipq6000) 的 IPQ6000 源码贡献。
使用 [openwrt-fork/sdf8057-ipq6000](https://github.com/openwrt-fork/sdf8057-ipq6000) 源码构建。

## 使用目标

保留 OpenVPN，以及独立运行 sing-box 所需的 TUN、`ip-full`、
`kmod-inet-diag`、`kmod-netlink-diag` 和 CA 证书。
**固件不内置 sing-box 二进制**，由用户刷机后自行上传，并管理配置、启动服务和流量接管规则。
上传前需确认所选二进制支持设备架构及当前 4.4 内核；刷机后验证 TUN、DNS 和重启启动行为。

不集成 Passwall、Haproxy、Hysteria、Xray、V2Ray 地理数据、Lucky、NPS
及代理专用辅助程序；不保留 USB 支持。

公共库由保留软件的依赖自动选择，不强制禁用共享库。
保留基础 DHCP/DNS、防火墙、NAT 和 NSS 网络转发组件。
依赖展开后，`pdnsd-alt` 仍由系统默认的 TurboACC 引入；
`wget-ssl` 和 `libpcre` 也仍被保留软件引用，因此不会强制移除。

## 固件版本

仅编译和发布 **basic** 固件，文件名保留 `-basic` 后缀。
不集成集客 AC 控制器，不下载其 feed，也不再构建控制器版本。

## 自动构建与更新

- **手动触发**：在 Actions 页面运行 `zn-m2 build`，始终执行构建。
- **自动检测**：每日北京时间 03:23 检查源码、保留的 feeds 和本仓库提交；有变化时构建。
- **失败重试**：仅成功发布后缓存来源指纹；构建失败将在下一次定时检测时重试。
- **Release Tag**：`zn-m2-YYYYMMDD-<run_id>-<run_attempt>`，不再依赖 Passwall 版本号。

构建仅下载和编译 basic 配置的软件包。
发布包含 basic 固件、manifest 和构建配置，可据此核对实际集成的包。
构建时自动检查展开后的配置及 manifest：必要运行组件缺失，
或集客 AC、代理插件、内网穿透程序、USB 驱动重新被选中时，立即报错停止发布。

## 保留的软件

| 分类 | 软件 |
|------|------|
| VPN | OpenVPN、WireGuard |
| sing-box 运行环境 | TUN、完整 ip 命令、网络诊断模块、CA 证书 |
| DDNS | ddns-scripts（阿里云 / DNSPod） |
| IPTV | udpxy（UDP 组播转 HTTP）、LuCI 管理界面 |
| 管理 | ttyd（Web 终端）、htop、bash、curl |
| 网络排障 | tcpdump（完整版本）、ss、ethtool、dig、mtr、arping |
| BusyBox 常用命令 | nslookup、netstat（支持 `-p` 查看进程）、ping / ping6、traceroute / traceroute6、nc |
| 主题 | Argon、Design（移除代理快捷入口） |
| 其他 | UPnP、WOL 唤醒、ARP 绑定、coremark / stress-ng |

常用排障示例（网口名称按实际设备调整）：

```sh
tcpdump -ni any 'port 53'       # 检查 DNS 请求
nslookup example.com 1.1.1.1   # 指定 DNS 服务器查询
dig @1.1.1.1 example.com AAAA   # 查询 IPv6 DNS 记录
netstat -lntup                 # 查看监听端口与进程
ss -ntup                      # 查看 TCP/UDP 连接
ip rule show                  # 检查策略路由
ip route show table all        # 检查所有路由表
mtr -n -r -c 10 1.1.1.1       # 查看沿途延迟和丢包
ethtool eth0                   # 查看驱动支持的网口信息
arping -I br-lan 192.168.1.2    # 检查局域网二层连通性
```

## 刷机与升级

- 控制台：`192.168.1.1` · 默认密码：`password`

| 场景 | 文件 |
|------|------|
| uboot 刷机 | `*factory-basic.ubi` |
| 系统升级 | `*sysupgrade-basic.bin` |
| 软件包清单 | `*basic.manifest` |

## 手动构建

1. Fork 本仓库。
2. 在 Actions 页面选择 `zn-m2 build` → `Run workflow`。
3. 等待构建，产物自动发布到 Release。
