# OpenClash custom overwrite helper for persistent Fake-IP and HTTP/3 DNS.
require 'yaml'

path = ARGV.fetch(0)
config = YAML.load_file(path)
before = YAML.dump(config)
domestic = [
  'https://223.5.5.5/dns-query#DIRECT&h3=true',
  'https://223.6.6.6/dns-query#DIRECT&h3=true'
]
overseas = [
  'https://cloudflare-dns.com/dns-query#🛟 节点容错&h3=true',
  'https://dns.google/dns-query#🛟 节点容错&h3=true'
]

(config['profile'] ||= {})['store-fake-ip'] = true
dns = config['dns'] ||= {}
dns['prefer-h3'] = false
# AdGuard intercepts its injected scripts locally using their real addresses.
# Fake-IP addresses prevent that interception and make page scripts time out.
if dns.fetch('fake-ip-filter-mode', 'blacklist') == 'blacklist'
  dns['fake-ip-filter'] = (Array(dns['fake-ip-filter']) + [
    '+.local.adguard.org',
    '+.local.adguard.com',
    '+.injections.adguard.org'
  ]).uniq
end
# Keep lists independent so YAML output has no aliases; OpenClash's loader
# disables alias parsing in its normal overwrite path.
dns['default-nameserver'] = domestic.map(&:dup)
dns['nameserver'] = domestic.map(&:dup)
dns['proxy-server-nameserver'] = domestic.map(&:dup)
dns['fallback'] = overseas.map(&:dup)
policy = dns['nameserver-policy'] ||= {}
policy['geosite:cn'] = domestic.map(&:dup)
policy['geosite:geolocation-!cn'] = overseas.map(&:dup)

serialized = YAML.dump(config)
File.open(path, 'w') { |file| file.write(serialized) } if serialized != before
