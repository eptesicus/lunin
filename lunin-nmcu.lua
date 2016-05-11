#!/usr/bin/lua
-- munin thermometer using DS18B20 sensors on ESP8622
-- (c) 2016, Florian Heimgaertner

-- This software may be modified and distributed under the terms
-- of the MIT license.  See the LICENSE file for details.

ver  = '0.04n'
owpin = 2

require('ds18b20')
ds18b20.setup(owpin)

plugin = {}
action = {}

function lunin_init()
  local fwVer = ('NodeMCU %i.%i.%i'):format(node.info())
  local hostname = ('esp%06x'):format(node.chipid())
  local sensors = {}

  ow.setup(owpin)
  ow.reset_search(owpin)
  local nilcount = 0
  repeat
    local addr = ow.search(owpin)
    if (addr == nil) then
      nc = nc + 1
    elseif (addr:byte(1) == 0x28) then
      table.insert(sensors, addr)
    end
    tmr.wdclr()
  until (nc > 1)
  ow.reset_search(owpin)

  return hostname, fwVer, sensors
end

hostname, fwVer, sensors = lunin_init()



-- munin node actions

action['config'] = function(socket,p)
  if plugin[p] then
    plugin[p](socket,'conf')
  else
    socket:send('# Unknown service\n')
  end
  socket:send('.\n')
end

action['fetch'] = function(socket,p)
  if plugin[p] then
    plugin[p](socket)
  else
    socket:send('# Unknown service\n')
  end
  socket:send('.\n')
end

action['list'] = function(socket)
  for k,v in pairs(plugin) do
    socket:send(k..' ')
  end
  socket:send('\n')
end

action['version'] = function(socket)
  socket:send('munins node on '..hostname..' version: '..ver..' (lunin, '.._VERSION..'/'..fwVer..')\n')
end

action['nodes'] = function(socket)
  socket:send(hostname..'\n.\n')
end

action['help'] = function(socket)
  socket:send('# Unknown command. Try ')
  for k,v in pairs(action) do socket:send(k..' ') end
  socket:send('\n')
end

action['quit'] = function(socket)
  socket:close()
end

plugin['ds18b20'] = function(socket, x)
  if x == 'conf' then
    socket:send('graph_title DS18B20 Temperature Sensors\ngraph_vlabel degrees Celsius\ngraph_category sensors\n')
    for k,v in pairs(sensors) do 
      local saddr = ("%02x%02x%02x%02x%02x%02x"):format(v:byte(2,7))
      socket:send('temp'..saddr..'.label '..saddr..'\n')
    end
  else
    for k,v in pairs(sensors) do 
      local temp, temp2 = ds18b20.readNumber(v)
      if temp < 85 then
	local saddr = ("%02x%02x%02x%02x%02x%02x"):format(v:byte(2,7))
	socket:send('temp'..saddr..'.value '..temp..string.format(".%04u", temp2)..'\n')
      end
    end
  end
end


srv=net.createServer(net.TCP,10)
srv:listen(4949,function(socket)
  socket:send('# munin node at '..hostname..'\n')
  socket:on("receive",function(socket,payload)
    local cmd, arg = payload:match('^(%l+)%s?([%w_]*)\r?\n?$')
      if action[cmd] then
	action[cmd](socket, arg)
      else
	action['help'](socket)
      end
  end)
end)
