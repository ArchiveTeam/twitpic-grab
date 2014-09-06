local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')
dofile("urlcode.lua")
dofile("table_show.lua")
dofile("failure_report.lua")
JSON = (loadfile "JSON.lua")()

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

local admit_failure = function(status_code, url)
  io.stdout:write("Giving up on "..url.."\n")
  io.stdout:flush()
  log_failure(status_code, url, os.getenv('downloader'), item_type, item_value)
end

wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  
  if item_type == "image" then
    
    local twitpicurl = "twitpic%.com/"..item_value
    
    if string.match(url, item_value) then
      html = read_file(file)
      local itemid = string.match(url, "twitpic%.com/([^/]+)/")
      
      for commentid in string.gmatch(html, '<div class="comment clear" data%-id="([0-9]+)">') do
        table.insert(urls, { url=("http://twitpic.com/comments/show.json?media_id="..itemid.."&last_seen="..commentid) })
      end
      
      for videourl in string.gmatch(html, '<meta name="twitter:player:stream" value="(http[^"]+)"') do
        table.insert(urls, { url=videourl })
      end
      
      for videosource in string.gmatch(html, '<source src="(http[^"]+)"') do
        table.insert(urls, { url=videosource })
      end
      
      for imageurl in string.gmatch(html, '<meta name="twitter:image" value="(http[^"]+)"') do
        table.insert(urls, { url=imageurl })
      end
    end
    
    if string.match(url, "http://api.twitpic.com/2/comments/show.json%?media_id=[^&]+&page=[0-9]+") then
      html = read_file(file)
      
      if not string.match(html, '{"total_comments":"[0-9]+","total_pages":[0-9]+}') then
        local page = string.match(url, "http://api.twitpic.com/2/comments/show.json%?media_id=[^&]+&page=([0-9]+)")
        local newpage = page + 1
        local media_id = string.match(url, "http://api.twitpic.com/2/comments/show.json%?media_id=([^&]+)&page=[0-9]+")
        table.insert(urls, { url=("http://api.twitpic.com/2/comments/show.json%?media_id="..media_id.."+&page="..newpage) })
      end
      
    end
    
  elseif item_type == "tag" then
    
    local twitpicurl = "twitpic%.com/tag/"..item_value
    
    if string.match(url, twitpicurl) then
      html = read_file(file)
      
      for nextpage in string.gmatch(html, '<div class="right">[^<]+<a href="(%?[^"]+)">[^<]+</a>[^<]+</div>') do
        table.insert(urls, { url=(twitpicurl.."/"..nextpage) })
      end
      
      for prevpage in string.gmatch(html, '<div class="left">[^<]+<a href="(%?[^"]+)">[^<]+</a>[^<]+</div>') do
        table.insert(urls, { url=(twitpicurl.."/"..prevpage) })
      end
    end
  end
  
    
  return urls
end

local downloaded = {}

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local ishtml = urlpos["link_expect_html"]
  local parenturl = parent["url"]
  local wgetreason = reason

  if downloaded[url] == true then
    return false
  end

  -- Chfoo - Can I use "local html = nil" in "wget.callbacks.download_child_p"?
  local html = nil

  if item_type == "image" then
    if string.match(url, "/%%5C%%22") or
      string.match(url, '/[^"]+"') then
      return false
    elseif string.match(url, "cloudfront%.net") or
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
    if string.match(url, "/%%5C%%22") or
      string.match(url, '/[^"]+"') then
      return false
    elseif string.match(url, "cloudfront%.net") or
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
    if string.match(url, "/%%5C%%22") or
      string.match(url, '/[^"]+"') then
      return false
    elseif string.match(url, "cloudfront%.net") or
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
  else
    return verdict
  end
end

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()

  if status_code >= 200 and status_code <= 399 then
    downloaded[url.url] = true
  end

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
        admit_failure(status_code, url.url)
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
        admit_failure(status_code, url.url)
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
      admit_failure(status_code, url.url)
      return wget.actions.NOTHING
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
