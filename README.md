# OpenClash 订阅转换模板

## AX6000 路由器专用

使用 [`AX6000_Router.ini`](AX6000_Router.ini)，基础设置来自
[`AX6000_Base.yaml`](AX6000_Base.yaml)。转换模板地址为：

`https://raw.githubusercontent.com/DixCouleur/subconverter-profiles/main/AX6000_Router.ini`

此配置用于 AdGuardHome → MosDNS → 选择性 Mihomo Fake-IP 链路。阿里两个
DoH 地址强制 H3，DNSPod 保留 UDP；节点、真实直连目标与 Fake-IP 排除域名
使用这些直连上游，避免回指 AdGuardHome/MosDNS。`prefer-h3` 开启，上游并发竞速，
不保证 H3 的应答优先于更快的 UDP 应答。

日志为 `warning`，关闭进程匹配及 GEO 自动更新，启用 TCP 并发、统一延迟与
Fake-IP 持久化。地区测速改为 600 秒、100 ms 容差；省略 `lazy` 时，Mihomo
1.19.31 默认 `lazy=true`，无需 `regional_urltest.rb`。原有地区匹配、容错顺序
和手动选择组保留，不更改节点的 Hysteria2 带宽与 QUIC 窗口参数。

`local.adguard.org` 精确 `REJECT`；`injections.adguard.org` 按 `adguard.org`
父域名规则走代理。路由器 INI 不引用旧 `AdGuard.list`；其他配置继续保留。
MosDNS 侧的精确 DNS 拒绝仍在本机配置中维护。

OpenClash 原生设置负责运行端口、模式、API 密钥和 LuCI 参数。AX6000 自定义
覆写仅将 DNS 监听恢复为 `127.0.0.1:7874`，并清空 TUN DNS 劫持；上游、规则、
测速及其他性能策略均来自专用配置。不要对这份配置再调用旧的 `dns_h3.rb`、
`smartdns_domestic.rb` 或 `regional_urltest.rb`。

以下章节说明原有通用配置及旧脚本，保持原用途。

`ACL4SSR_Online_NoAuto.ini` 保留原有分流，并按名称生成 JP 日本、SG 新加坡、HK 香港、TW 台湾、US 美国、KR 韩国、DE 德国、AU 澳大利亚、GB 英国、VN 越南、NL 荷兰、CH 瑞士、AT 奥地利、NO 挪威、SE 瑞典、TR 土耳其、IE 爱尔兰、BG 保加利亚 地区组。在“🚀 节点选择”中选地区，该地区每 300 秒通过 Google 204 检查可用性和 HTTP 延迟，切换容差 50ms。该检测不衡量下载带宽。信息条目以及明确标注限速、应急的节点只保留手动选择。

“🛟 节点容错”按 SG 新加坡 → JP 日本 → HK 香港 → TW 台湾 → US 美国 的顺序使用第一个可用地区；每个地区内部继续自动优选节点。当前地区没有可用节点时，切换到下一个可用地区。容错组每 300 秒检查一次，优先地区恢复可用后会重新优先使用。

转换模板地址保持不变：

`https://raw.githubusercontent.com/DixCouleur/subconverter-profiles/main/ACL4SSR_Online_NoAuto.ini`

当前转换后端不能在 INI 中输出 `lazy=false`。将 `regional_urltest.rb` 放到 `/etc/openclash/custom/`，并在 `/etc/openclash/custom/openclash_custom_overwrite.sh` 的 `exit 0` 前加入：

```sh
ruby -ryaml -E UTF-8 /etc/openclash/custom/regional_urltest.rb "$CONFIG_FILE"
```

这样每次订阅更新、OpenClash 启动时都会使所有地区组定时检测，即使该地区当前没有被选中。脚本只修改这些地区 `url-test` 组的 `lazy` 字段。

## Fake-IP 持久化和 HTTP/3 DNS

`dns_h3.rb` 开启 `profile.store-fake-ip`，并将 DNS 上游统一为强制 HTTP/3。国内解析、DNS 服务器引导解析和代理节点域名解析使用阿里 DNS 的 `223.5.5.5`、`223.6.6.6`，经 `DIRECT` 连接；境外解析使用 Cloudflare、Google DNS，经“🛟 节点容错”连接。每个上游设置 `h3=true`，全局 `prefer-h3` 保持关闭。

将脚本放到 `/etc/openclash/custom/`，在自定义覆写脚本的 `exit 0` 前加入：

```sh
ruby -ryaml -E UTF-8 /etc/openclash/custom/dns_h3.rb "$CONFIG_FILE"
```

同时开启 OpenClash 的 Fake-IP 缓存选项：`openclash.config.store_fakeip=1`。地区组、容错顺序和原有分流规则保持原样。

在默认的 Fake-IP 排除模式下，脚本还将 `local.adguard.org`、`local.adguard.com`、`injections.adguard.org` 及其子域名加入 `fake-ip-filter`，让 AdGuard 使用真实地址处理网页注入脚本。`AdGuard.list` 同时为这三个域名提供直连规则。路由器配置正确后若仍有脚本超时，需要继续检查终端 AdGuard 的拦截和缓存。

## SmartDNS 与 OpenClash

SmartDNS 仅承接国内域名策略：终端 → dnsmasq:53 → OpenClash:7874 → SmartDNS:6053 → 阿里 H3。国外域名仍由 OpenClash 经“🛟 节点容错”查询 Cloudflare、Google H3。DNS 引导、代理节点域名和未分类域名的默认上游保留 `dns_h3.rb` 的配置，避免对需要代理的地址从本地测速。两个服务之间的本机 DNS 请求使用 UDP/TCP，公网 DNS 上游仍为 H3。

SmartDNS 使用 `6053`，绑定 `lo`，关闭“自动设置 dnsmasq”，让 dnsmasq 继续转发给 OpenClash。缓存限制为 1024 条、1 MiB，启用预获取和最多保留一小时的过期缓存；过期结果回应 TTL 为 3 秒。使用 `tcp:443,ping` 地址检测、`first-ping` 回应模式和 IPv4，关闭额外 WebUI 插件。`smartdns-openclash.conf` 放到 `/etc/smartdns/`，在已有 `custom.conf` 中加入对应的 `conf-file`，其余参数通过 UCI 管理。

SmartDNS 的 IPv6 监听、双栈优选和 DNS64 均关闭；AAAA 查询直接返回 SOA，HTTPS 记录中的 `ipv6hint` 被过滤。UCI 主服务设置 `ipv6_server=0`、`dualstack_ip_selection=0`、`force_aaaa_soa=1`；备用服务保持关闭，并设置 `seconddns_no_dualstack_selection=1`、`seconddns_force_aaaa_soa=1`。客户端规则中的双栈优选也关闭。上游使用 IPv4 地址，保留 H3。

两条 SmartDNS 上游的 UCI `type` 为 `h3`，地址分别为 `h3://223.5.5.5/dns-query`、`h3://223.6.6.6/dns-query`，`host_name`、`tls_host_verify` 和 `http_host` 均为 `dns.alidns.com`。使用 `h3://` 可以避免该版本将 `https://` 重新解释成普通 DoH。

将 `smartdns_domestic.rb` 放到 `/etc/openclash/custom/`，在 `dns_h3.rb` 调用之后加入：

```sh
ruby -ryaml -E UTF-8 /etc/openclash/custom/smartdns_domestic.rb "$CONFIG_FILE"
```

脚本仅改变 `geosite:cn` 和已有 `oc-cn-domain` 规则集对应的 DNS 策略。SmartDNS 在 OpenClash 之前启动。若关闭 SmartDNS，应随后重新加载 OpenClash，完整覆写流程会恢复国内直连 H3 上游。

## 避免版本查询启动额外核心

`openclash_core_version.lua` 放到 `/etc/openclash/custom/`。LuCI 控制器的 `coremetacv()` 改为调用该模块的 `read(cn_port(), dase())`：查询运行核心的 `/version`，API 不可用时返回本轮开机缓存的版本或 `0`，不执行核心的 `-v`。该控制器补丁属于本地修改，更新 `luci-app-openclash` 后需要检查是否被覆盖。
