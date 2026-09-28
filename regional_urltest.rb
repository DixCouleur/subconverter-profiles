# OpenClash custom overwrite helper. Run after subscription conversion.
# The INI converter cannot express lazy=false; apply it to regional URLTest groups.
require 'yaml'

path = ARGV.fetch(0)
config = YAML.load_file(path)
regions = ["JP 日本", "SG 新加坡", "HK 香港", "TW 台湾", "US 美国", "KR 韩国", "DE 德国", "AU 澳大利亚", "GB 英国", "VN 越南", "NL 荷兰", "CH 瑞士", "AT 奥地利", "NO 挪威", "SE 瑞典", "TR 土耳其", "IE 爱尔兰", "BG 保加利亚"]
changed = false
Array(config['proxy-groups']).each do |group|
  next unless regions.include?(group['name']) && group['type'] == 'url-test'
  next if group['lazy'] == false
  group['lazy'] = false
  changed = true
end
File.open(path, 'w') { |file| file.write(YAML.dump(config)) } if changed
