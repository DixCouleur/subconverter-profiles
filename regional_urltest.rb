# OpenClash custom overwrite helper. Run after subscription conversion.
# The INI converter cannot express lazy=false; apply it to regional URLTest groups.
require 'yaml'

path = ARGV.fetch(0)
config = YAML.load_file(path)
regions = %w[JP SG HK TW US KR DE AU GB VN NL CH AT SE TR IE BG] + ['NO 挪威']
changed = false
Array(config['proxy-groups']).each do |group|
  next unless regions.include?(group['name']) && group['type'] == 'url-test'
  next if group['lazy'] == false
  group['lazy'] = false
  changed = true
end
File.open(path, 'w') { |file| file.write(YAML.dump(config)) } if changed
