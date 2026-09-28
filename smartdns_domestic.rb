# Run after dns_h3.rb in OpenClash's custom overwrite hook.
require 'yaml'

enabled = IO.popen(['uci', '-q', 'get', 'smartdns.@smartdns[0].enabled'], &:read).strip
path = ARGV.fetch(0)
config = YAML.load_file(path)
before = YAML.dump(config)
policy = (config['dns'] ||= {})['nameserver-policy'] ||= {}
if enabled == '1'
  policy['geosite:cn'] = ['127.0.0.1:6053#DIRECT']
  if (config['rule-providers'] || {}).key?('oc-cn-domain')
    policy['rule-set:oc-cn-domain'] = ['127.0.0.1:6053#DIRECT']
  elsif policy['rule-set:oc-cn-domain'] == ['127.0.0.1:6053#DIRECT']
    policy.delete('rule-set:oc-cn-domain')
  end
else
  # dns_h3.rb has already restored geosite:cn. Remove our extra rule-set
  # policy as well so disabling SmartDNS cannot leave a dead local upstream.
  policy.delete('rule-set:oc-cn-domain') if policy['rule-set:oc-cn-domain'] == ['127.0.0.1:6053#DIRECT']
end

serialized = YAML.dump(config)
File.open(path, 'w') { |file| file.write(serialized) } if serialized != before
