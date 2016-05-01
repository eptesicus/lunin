#!/usr/bin/lua
-- Lunin: Lua implementation of a munin-node
-- (c) 2016, Florian Heimgaertner

-- This software may be modified and distributed under the terms
-- of the MIT license.  See the LICENSE file for details.


require('ds18b20')
ds18b20.setup(2)

ver  = '0.04n'

plugin = {}
action = {}

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
  socket:send('munins node on nodemcu version: '..ver..' (lunin, '.._VERSION..')\n')
end

action['nodes'] = function(socket)
  socket:send('nodemcu\n.\n')
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
    socket:send('graph_title DS18B20 Temperature Sensor\ngraph_vlabel degrees Celsius\ngraph_category sensors\ntemp.label temperature\n')
  else
    local temp = ds18b20.read()
    if temp < 85 then
      socket:send('temp.value '..temp..'\n')
    end
  end
end


srv=net.createServer(net.TCP,10)
srv:listen(4949,function(socket)
  socket:send('# munin node at nodemcu\n')
  socket:on("receive",function(socket,payload)
    local cmd, arg = payload:match('^(%l+)%s?([%w_]*)\r?\n?$')
      if action[cmd] then
	action[cmd](socket, arg)
      else
	action['help'](socket)
      end
  end)
end)
