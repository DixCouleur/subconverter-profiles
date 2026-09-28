-- Read the running core's version without starting another Mihomo process.
local sys = require "luci.sys"
local json = require "luci.jsonc"
local util = require "luci.util"
local fs = require "nixio.fs"
local cache_path = "/tmp/openclash_api_core_version"
local M = {}

local function valid(value)
  return type(value) == "string" and #value > 0 and #value <= 100
    and value:match("^[%w%.%+%-%_]+$") ~= nil
end

function M.read(port, secret)
  local number = tonumber(port)
  if number and number >= 1 and number <= 65535 and number % 1 == 0 then
    local url = "http://127.0.0.1:" .. string.format("%d", number) .. "/version"
    local command = "curl --noproxy '*' -fsS --connect-timeout 1 --max-time 2 -H "
      .. util.shellquote("Authorization: Bearer " .. tostring(secret or ""))
      .. " " .. util.shellquote(url) .. " 2>/dev/null"
    local data = json.parse(sys.exec(command))
    if type(data) == "table" and valid(data.version) then
      fs.writefile(cache_path, data.version)
      return data.version
    end
  end
  local cached = fs.readfile(cache_path)
  return valid(cached) and cached or "0"
end

return M
