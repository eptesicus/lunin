local x = ...
local ifaces = { ['wlan0'] = 'wlan', ['wlan0-1'] = 'guest' }
if x == 'conf' then
  graph_header('WiFi clients', 'network', '#', nil, 'no')
  for k, v in pairs(ifaces) do
    graph_field(k:gsub('%W','_'), nil, v)
  end
else
  for k, v in pairs(ifaces) do
    local n = 0
    local f = io.popen('iw dev '..k..' station dump')
    for l in f:lines() do
      if l:match('^Station') then
	n = n+1
      end
    end
    f:close()
    print(k:gsub('%W','_')..'.value '..n)
  end
end
