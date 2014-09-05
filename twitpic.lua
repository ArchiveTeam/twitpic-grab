local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')


read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local ishtml = urlpos["link_expect_html"]
  local parenturl = parent["url"]
  
  -- Chfoo - Can I use "local html = nil" in "wget.callbacks.download_child_p"?
  local html = nil

  -- Skip redirect from mysite.verizon.net and members.bellatlantic.net
  if item_type == "image" then
    if string.match(url, "cloudfront%.net") or
      string.match(url, "twimg%.com")  or
      string.match(url, "amazonaws%.com") then
      return verdict
    elseif string.match(url, "advertise%.twitpic%.com") then
      return false
    elseif not string.match(url, "twitpic%.com") then
      if ishtml ~= 1 then
        return verdict
      end
    elseif not string.match(url, item_value) then
      if ishtml == 1 then
        return false
      else
        return verdict
      end
    elseif string.match(url, item_value) then
      return verdict
    else
      return false
    end
  elseif item_type == "user" then
    if string.match(url, "cloudfront%.net") or
      string.match(url, "twimg%.com")  or
      string.match(url, "amazonaws%.com") then
      return verdict
    elseif string.match(url, "advertise%.twitpic%.com") then
      return false
    elseif not string.match(url, "twitpic%.com") then
      if ishtml ~= 1 then
        return verdict
      end
    elseif not string.match(url, item_value) then
      if ishtml == 1 then
        return false
      else
        return verdict
      end
    elseif string.match(url, item_value) then
      return verdict
    else
      return false
    end
  elseif item_type == "tag" then
    if string.match(url, "cloudfront%.net") or
      string.match(url, "twimg%.com")  or
      string.match(url, "amazonaws%.com") then
      return verdict
    elseif string.match(url, "advertise%.twitpic%.com") then
      return false
    -- Check if we are on the last page of a tag
    elseif string.match(url, "twitpic%.com/tag/[^%?]+%?page=[0-9]+") then
      if not html then
        html = read_file(file)
      end
      if not string.match(url, '<div class="user%-photo%-content right">') then
        return false
      else
        return verdict
      end
    elseif not string.match(url, "twitpic%.com") then
      if ishtml ~= 1 then
        return verdict
      end
    elseif not string.match(url, item_value) then
      if ishtml == 1 then
        return false
      else
        return verdict
      end
    elseif string.match(url, item_value) then
      return verdict
    else
      return false
    end
  else
    return verdict
  end
end

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \r")
  io.stdout:flush()
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403) then
    if string.match(url["host"], "twitpic%.com") or
      string.match(url["host"], "cloudfront%.net") or
      string.match(url["host"], "twimg%.com") or
      string.match(url["host"], "amazonaws%.com") then
      
      io.stdout:write("\nServer returned "..http_stat.statcode.." for " .. url["url"] .. ". Sleeping.\n")
      io.stdout:flush()
      
      os.execute("sleep 10")
      
      tries = tries + 1
      
      if tries >= 5 then
        io.stdout:write("\nI give up...\n")
        io.stdout:flush()
        return wget.actions.NOTHING
      else
        return wget.actions.CONTINUE
      end
    else
      io.stdout:write("\nServer returned "..http_stat.statcode.." for " .. url["url"] .. ". Sleeping.\n")
      io.stdout:flush()
      
      os.execute("sleep 10")
      
      tries = tries + 1
      
      if tries >= 5 then
        io.stdout:write("\nI give up...\n")
        io.stdout:flush()
        return wget.actions.NOTHING
      else
        return wget.actions.CONTINUE
      end
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode.." for " .. url["url"] .. ". Sleeping.\n")
    io.stdout:flush()
    
    os.execute("sleep 10")
    
    tries = tries + 1
    
    if tries >= 5 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  -- local sleep_time = 0.1 * (math.random(1000, 2000) / 100.0)
  local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
