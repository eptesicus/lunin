local x = ...
local fields = { 'system', 'user', 'nice', 'idle', 'iowait', 'irq', 'softirq', 'steal', 'guest' }
if x == 'conf'  then
  graph_header('CPU usage', 'system', '%', ' --base 1000 -r --lower-limit 0 --upper-limit 100', 'no')
  print('graph_order '..table.concat(fields, ' '))
  print('graph_period second')
  local draw = 'AREA'
  for k,v in pairs(fields) do
    graph_field(v, draw)
    print(v..'.type DERIVE')
    draw = 'STACK'
  end
else
  local f = io.open("/proc/stat")
  local l = f:read("*line")
  f:close() 
  local i = 0
  for n in l:gmatch('%S+') do
    if fields[i] then
      print(fields[i]..'.value '..n)
    end
    i = i + 1
  end
end

