# OpenClash 订阅转换模板

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
