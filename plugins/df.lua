local x = ...
if x == 'conf' then
  graph_header('Disk usage in percent', 'disk', '%', '--upper-limit 100 -l 0', 'no')
  local f = io.popen('df -P')
  for l in f:lines() do
      local dev, mtp = l:match('^(/%S+) +%S+ +%S+ +%S+ +%S+%% +(/%S+)$')
      if dev then graph_field(dev:gsub('%W','_'), nil, mtp) end
  end
  f:close()
else
  local f = io.popen('df -P')
  for l in f:lines() do
      local dev, pct = l:match('^(/%S+) +%S+ +%S+ +%S+ +(%S+)%%')
      if dev then print(dev:gsub('%W','_')..'.value '..pct) end
  end
  f:close()
end
