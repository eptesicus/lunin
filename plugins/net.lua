local x = ...
local ifaces = { ['eth0'] = 'eth0', ['eth1'] = 'eth1', ['wlan0'] = 'wlan'}
if x == 'conf' then
  graph_header('network traffic', 'network', 'bits in (-) / out (+) per ${graph_period}', '--base 1000')
  for k,v in pairs(ifaces) do
    k = k:gsub('%W','_')
    print(k.."_down.label received")
    print(k..'_down.type DERIVE')
    print(k..'_down.min 0')
    print(k..'_down.graph no')
    print(k..'_down.cdef '..k..'_down,8,*')
    print(k..'_up.type DERIVE')
    print(k..'_up.min 0')
    print(k..'_up.negative '..k..'_down')
    print(k..'_up.cdef '..k..'_up,8,*')
    print(k..'_up.label '..v)
  end
else
  local f = io.open("/proc/net/dev")
  for l in f:lines() do
    local i, rx, tx = l:match('^ *(%S+): +(%d+) +%d+ +%d+ +%d+ +%d+ +%d+ +%d+ +%d+ +(%d+)')
    if ifaces[i] then
      i = i:gsub('%W','_')
      print(i..'_down.value '..rx..'\n'..i..'_up.value '..tx)
    end
  end
  f:close() 
end
