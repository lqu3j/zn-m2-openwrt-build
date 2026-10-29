#!/bin/bash
set -euo pipefail

MANIFESTS=("$FIRMWARE"/*.manifest)
MANIFEST="${MANIFESTS[0]}"
[ -f "$MANIFEST" ] || { echo "ERROR: firmware manifest not found" >&2; exit 1; }
OPENVPN_VER=$(awk -F ' - ' '$1 == "openvpn-openssl" {print $2}' "$MANIFEST")
[ -n "$OPENVPN_VER" ] || { echo "ERROR: OpenVPN missing from firmware manifest" >&2; exit 1; }

BUILD_DATE=$(date -u +%Y%m%d)
RELEASE_TAG="zn-m2-${BUILD_DATE}-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
echo "release_tag=$RELEASE_TAG" >> "$GITHUB_OUTPUT"
echo "release_name=ZN-M2 ${BUILD_DATE} OpenVPN" >> "$GITHUB_OUTPUT"

cat > release.txt <<RELEASE
## ZN-M2 固件

**OpenVPN:** \`$OPENVPN_VER\`

- 不内置 Passwall、其他代理核心、Lucky、NPS 和 USB 支持。
- sing-box 二进制由用户自行上传；保留 TUN、路由工具、诊断模块和 CA 证书。
- sing-box 的配置、启动服务及流量接管规则由用户自行管理。

### 变体说明
- **basic**: 不含集客 AC 控制器。
- **gecoosac-v2**: 含集客 AC 控制器 V2。

完整软件包列表请查看对应的 manifest 文件。
RELEASE
