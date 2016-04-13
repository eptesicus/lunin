
local x = ...
if x == 'conf' then
  graph_header('Load average', 'system', 'load', nil, 'no')
  graph_field('load')
else
  local f = io.open("/proc/loadavg")
  local l = f:read("*line")
  f:close() 
  print('load.value '..l:match('^%S+ (%S+) '))
end

