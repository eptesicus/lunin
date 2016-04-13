local x = ...
local fields = { 
  ['Buffers'] = 'buffers', 
  ['Cached'] = 'cached', 
  ['PageTables'] = 'page_tables', 
  ['SwapCached'] = 'swap_cache',
  ['VmallocUsed'] = 'vmalloc_used', 
  ['Slab'] = 'slab',
  ['MemFree'] = 'free' }
local mem = {}
local f = io.open('/proc/meminfo')
for l in f:lines() do
  local k, v = l:match('^(%S+):%s+(%d+)')
  mem[k] = v
end
if x == 'conf' then
  graph_header('Memory usage', 'system', 'Bytes', '--base 1024 -l 0 --upper-limit '..mem.MemTotal*1024)
  print('graph_order apps page_tables swap_cache vmalloc_used slab cached buffers free swap')
  graph_field('apps', 'AREA')
  graph_field('swap', 'STACK')
  for k, v in pairs(fields) do
    if mem[k] then
      graph_field(v, 'STACK')
    end
  end
else
  local apps = mem.MemTotal 
  local swap = mem.SwapTotal - mem.SwapFree
  print('swap.value '..swap*1024)
  for k, v in pairs(fields) do
    if mem[k] then
      print(v..'.value '..mem[k]*1024)
      apps = apps - mem[k]
    end
  end
  print('apps.value '..apps*1024)
end
