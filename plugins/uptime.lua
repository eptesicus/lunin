local x = ...
if x == 'conf' then
  graph_header('Uptime', 'system', 'uptime in days', nil, 'no')
  graph_field('uptime', 'AREA', 'uptime', 'uptime,86400,/')
else
  local f = io.open("/proc/uptime")
  local l = f:read("*line")
  f:close() 
  print('uptime.value '..l:match('^%S+'))
end 
