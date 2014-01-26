local composite = tonumber(...)
  
local f = io.open("primes.dat", "r")
while true do
  local line = f:read()
  if line == nil then
    break
  end
  local prime = tonumber(line)
  if composite % prime == 0 then
    print(composite, prime, composite / prime)
    break
  end
end
f:close()
