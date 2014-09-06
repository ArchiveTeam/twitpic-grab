-- From https://github.com/lua-shellscript/lua-shellscript/blob/master/src/sh/commands.lua
local function escape(...)
  local command = type(...) == 'table' and ... or { ... }

  for i, s in ipairs(command) do
    s = (tostring(s) or ''):gsub('"', '\\"')
    if s:find '[^A-Za-z0-9_."/-]' then
      s = '"' .. s .. '"'
    elseif s == '' then
      s = '""'
    end
    command[i] = s
  end

  return table.concat(command, ' ')
end

local failure_report_url = 'http://quitpic.at.ninjawedding.org/fail'

function log_failure(status_code, url, downloader, item_type, item_value)
  local template = 'curl -s -X POST %s -F downloader=%s -F response_code=%s -F url=%s -F item_name=%s:%s'
  local command = template:format(failure_report_url,
    escape(downloader),
    escape(status_code),
    escape(url),
    escape(item_type),
    escape(item_value))

  os.execute(command)
end
