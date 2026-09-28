# OpenClash 订阅转换模板

`ACL4SSR_Online_NoAuto.ini` 保留原有分流和 SG07 → SG10 容错，并按名称生成 JP 日本、SG 新加坡、HK 香港、TW 台湾、US 美国、KR 韩国、DE 德国、AU 澳大利亚、GB 英国、VN 越南、NL 荷兰、CH 瑞士、AT 奥地利、NO 挪威、SE 瑞典、TR 土耳其、IE 爱尔兰、BG 保加利亚 地区组。在“🚀 节点选择”中选地区，该地区每 300 秒通过 Google 204 检查可用性和 HTTP 延迟，切换容差 50ms。该检测不衡量下载带宽。信息条目以及明确标注限速、应急的节点只保留手动选择。

转换模板地址保持不变：

`https://raw.githubusercontent.com/DixCouleur/subconverter-profiles/main/ACL4SSR_Online_NoAuto.ini`

当前转换后端不能在 INI 中输出 `lazy=false`。将 `regional_urltest.rb` 放到 `/etc/openclash/custom/`，并在 `/etc/openclash/custom/openclash_custom_overwrite.sh` 的 `exit 0` 前加入：

```sh
ruby -ryaml -E UTF-8 /etc/openclash/custom/regional_urltest.rb "$CONFIG_FILE"
```

这样每次订阅更新、OpenClash 启动时都会使所有地区组定时检测，即使该地区当前没有被选中。脚本只修改这些地区 `url-test` 组的 `lazy` 字段。
