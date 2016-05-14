-- munin thermometer using DS18B20 sensors on ESP8622
-- (c) 2016, Florian Heimgaertner

-- This software may be modified and distributed under the terms
-- of the MIT license.  See the LICENSE file for details.

local modname = ...
local M = {}
_G[modname] = M


local plugin = {}
local action = {}
local hostname = ('esp%06x'):format(node.chipid())
local ver = '0.04n'
local pin = nil
local sensors = nil

local table = table
local string = string
local ow = ow
local tmr = tmr
local node = node
local file = file
local net = net
local pairs = pairs

setfenv(1,M)


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
  socket:send(('munins node on %s version: %s (lunin, %s/NodeMCU %i.%i.%i)\n'):format(hostname, ver, _VERSION, node.info()))
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
  if sensors == nil then -- find sensors
    sensors = {}
    ow.setup(pin)
    ow.reset_search(pin)
    local nc = 0
    repeat
      local addr = ow.search(pin)
      if (addr == nil) then
	nc = nc + 1
      elseif (addr:byte(1) == 0x28 and addr:byte(8) == ow.crc8(string.sub(addr,1,7))) then
	table.insert(sensors, addr)
      end
      tmr.wdclr()
    until (nc > 1)
    ow.reset_search(pin)
  end

  if x == 'conf' then
    socket:send('graph_title DS18B20 Temperature Sensors\ngraph_vlabel degrees Celsius\ngraph_category sensors\n')
    for _,addr in pairs(sensors) do 
      local saddr = ("%02x%02x%02x%02x%02x%02x"):format(addr:byte(2,7))
      socket:send('temp'..saddr..'.label '..saddr..'\n')
    end
  else
    for _,addr in pairs(sensors) do
      local s = ''
      local t = 850001
      ow.setup(pin)
      ow.reset(pin)
      ow.select(pin, addr)
      ow.write(pin, 0x44, 1)
      ow.reset(pin)
      ow.select(pin, addr)
      ow.write(pin, 0xBE, 1)
      local data = ow.read_bytes(pin, 9)
      if (data:byte(9) == ow.crc8(string.sub(data,1,8))) then
        t = (data:byte(1) + data:byte(2) * 256) 
	if (t > 0x7fff) then
          t = t - 0x10000
	  s = '-'
        end
	t = t * 625
      end
      tmr.wdclr()

      if t < 850000 then
        local saddr = ("%02x%02x%02x%02x%02x%02x"):format(addr:byte(2,7))
	socket:send(('temp%s.value %s%i.%04u\n'):format(saddr, s, t/10000,t %10000))
      end
    end
  end
end

plugin['heap'] = function(socket, x)
  if x == 'conf' then
    socket:send('graph_title Heap remaining\ngraph_vlabel Bytes\ngraph_category system\ngraph_args --base 1024\nheap.label heap\n')
  else
    socket:send('heap.value '..node.heap()..'\n')
  end
end

plugin['fsinfo'] = function(socket, x)
  local remaining, used, total = file.fsinfo()
  if x == 'conf' then
    socket:send('graph_title Flash usage\ngraph_vlabel Bytes\ngraph_category system\ngraph_args --base 1024 -l 0 --upper-limit '..total..'\nusage.label usage\n')
  else
    socket:send('usage.value '..used..'\n')
  end
end

function start(owpin)
  pin = owpin
  ow.setup(pin)
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
end


return M
