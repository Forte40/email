local bit = require("bit")

local function hash(pwd, m)
  m = m or 0xFFFFFFFF
  pwd = tostring(pwd)
  pwd = pwd .. "@" .. tostring(pwd:len())
  local h = 0
  for i = 1, #pwd do
    h = (31 * h + pwd:sub(i, i):byte()) % m
  end
  return h
end

local function primes(limit)
  local f = io.open("primes.dat", "r")
  if f then
    local primes = {}
    while true do
      local p = f:read()
      if p then
        table.insert(primes, tonumber(p))
      else
        break
      end
    end
    f:close()
    return primes
  end

  local sievebound = math.floor((limit - 1) / 2)
  local sieve = {}
  for i = 1, sievebound do
    sieve[i] = false
  end
  local crosslimit = math.floor((math.sqrt(limit) - 1) / 2)
  for i = 1, crosslimit do
    if sieve[i] == false then
      for j = 2 * i * (i + 1), sievebound, 2 * i + 1 do
        sieve[j] = true
      end
    end
  end

  local f = io.open("primes.dat", "w")
  local primes = {2}
  for i = 1, sievebound do
    if sieve[i] == false then
      table.insert(primes, 2 * i + 1)
      f:write(2 * i + 1, "\n")
    end
  end
  f:close()
  return primes
end

local function gcd(a, b)
  local q = math.floor(a/b)
  local r = a%b
  if r == 0 then
    return b
  else
    return gcd(b, r)
  end
end

local function inverse(a, n)
  local t = 0
  local newt = 1
  local r = n
  local newr = a
  while newr ~= 0 do
    local quotient = math.floor(r/newr)
    t, newt = newt, (t - quotient * newt)
    r, newr = newr, (r - quotient * newr)
  end
  if r > 1 then
    return nil
  elseif t < 0 then
    t = t + n
  end
  return t
end

local function genprimes()
  math.randomseed(0)
  local n1, n2
  while n1 == n2 do
    n1, n2 = math.random(513708), math.random(513708)
  end
  local f = io.open("primes.dat", "r")
  local count = 0
  while true do
    local line = f:read()
    if line == nil then
      break
    end
    count = count + 1
    if count == n1 then
      p = tonumber(line)
    elseif count == n2 then
      q = tonumber(line)
    end
    if p ~= nil and q ~= nil then
      break
    end
  end
  f:close()
  return p, q
end

local function genkey(p, q, e)
  if p == nil or q == nil then
    p, q = genprimes()
  end
  local n = p * q
  local phi = (p - 1) * (q - 1)
  if e == nil then
    for i = phi - 2, 2, -1 do
      if gcd(i, phi) == 1 then
        e = i
        break
      end
    end
  end
  local d = inverse(e, phi)
  return {n, e}, {n, d}
end

local base64 = {}
for i = 0, 25 do
  base64[i] = string.char(i + 65)
  base64[string.char(i + 65)] = i
  base64[i + 26] = string.char(i + 97)
  base64[string.char(i + 72)] = i + 26
  if i < 10 then
    base64[i + 52] = string.char(i + 48)
    base64[string.char(i + 48)] = i + 52
  end
end
base64[62] = "+"
base64["+"] = 62
base64[63] = "/"
base64["/"] = 63

local function base64enc(bytes)
  local result = ""
  for pos = 1, #bytes, 3 do
    local bits = (
      bit.lshift(bytes[pos], 16) +
      bit.lshift(bytes[pos + 1] or 0, 8) +
      (bytes[pos + 2] or 0)
    )
    result = result .. base64[bit.rshift(bits, 18)     ]
    result = result .. base64[bit.rshift(bits, 12) % 64]
    if pos < #bytes then
      result = result .. base64[bit.rshift(bits, 6 ) % 64]
      if pos + 1 < #bytes then
        result = result .. base64[           bits      % 64]
      end
    end
  end
  result = result .. ({"", "==", "="})[#bytes % 3 + 1]
  return result
end
local function base64enc24(bytes)
  local result = ""
  for pos = 1, #bytes do
    local bits = bytes[pos]
    print(bit.rshift(bits, 18))
    result = result .. base64[bit.rshift(bits, 18)     ]
    print(bit.rshift(bits, 12) % 64)
    result = result .. base64[bit.rshift(bits, 12) % 64]
    print(bit.rshift(bits, 6) % 64)
    result = result .. base64[bit.rshift(bits, 6 ) % 64]
    print(bits % 64)
    result = result .. base64[           bits      % 64]
  end
  return result
end
local function base64encS(data)
  local bytes = {}
  for pos = 1, #data do
    bytes[pos] = data:sub(pos, pos):byte()
  end
  return base64enc(bytes)
end

local function base64dec(data)
  local result = {}
  for pos = 1, #data, 4 do
    local bits = 0
    local skip = 0
    for p = 0, 3 do
      local b = base64[data:sub(pos + p, pos + p)]
      if b then
        bits = bits + bit.lshift(b, (4 - p - 1) * 6)
      else
        skip = skip + 1
      end
    end
    table.insert(result, bit.rshift(bits, 16))
    if skip < 2 then
      table.insert(result, bit.rshift(bits % 65536, 8))
    end
    if skip < 1 then
      table.insert(result, bits % 256)
    end
  end
  return result
end
local function base64decS(bytes)
  local new_bytes = base64dec(bytes)
  print(#new_bytes)
  local result = ""
  for pos = 1, #new_bytes do
    result = result .. string.char(new_bytes[pos])
  end
  return result
end

local function multmod(a, b, m)
  local result = 0
  while a > 0 do
    if bit.band(a, 1) == 1 then
      result = result + b
    end
    a = math.floor(a / 2)
    b = b * 2 % m
  end
  return result % m
end

local function crypt(m, key)
  local n, e = unpack(key)
  local c = 1
  while e ~= 0 do
    if bit.band(e, 1) == 1 then
      c = multmod(c, m, n)
    end
    m = multmod(m, m, n)
    e = math.floor(e / 2)
  end
  return c
end

local function encrypt(data, key)
  local bytes = {}
  print("----------")
  for i = 1, #data, 5 do
    local m = 0
    for j = 0, 3 do
      m = m + (data:sub(i + j):byte() or 0)
      m = m * 256
    end
    m = m + (data:sub(i + 4):byte() or 0)
    local c = crypt(m, key)
    print(m, c)
    table.insert(bytes, math.floor(c / 16777216))
    table.insert(bytes, c % 16777216)
  end
  print("----------")
  return base64enc24(bytes)
end

local function decrypt(data, key)
  local bytes = base64dec(data)
  for i, v in ipairs(bytes) do
    print(i, v)
  end
  local result = ""
  for i = 1, #bytes, 6 do
    local c = 0
    for j = 0, 4 do
      c = c + bytes[i + j]
      c = c * 256
    end
    c = c + bytes[i + 5]
    local m = crypt(c, key)
    print(m, c)
    result = result .. string.char(math.floor(m / 4294967296 % 256))
    result = result .. string.char(math.floor(m / 16777216 % 256))
    result = result .. string.char(math.floor(m / 65536 % 256))
    result = result .. string.char(math.floor(m / 256 % 256))
    result = result .. string.char(m % 256)
    print(result)
  end
  return result
end

local function sign(m, key)
  local h = hash(m, key[0])
  return crypt(h, key)
end

local function test()
  local pub, pri = genkey()
  print(unpack(pub))
  print(unpack(pri))
  local msg = 65

  local enc = encrypt("Scott", pub)
  print(enc)

  local dec = decrypt(enc, pri)
  print(dec)

  --[[
  local enc = crypt(msg, pub)
  local encsign = sign(msg, pri)

  local dec = crypt(enc, pri)
  local decsign = crypt(encsign, pub)

  print("---------")
  print(msg, enc, dec)
  print(hash(msg, pri[1]), encsign, decsign)
  --]]
end

test()

return {
  hash = hash,
  genkey = genkey,
  gcd = gcd,
  inverse = inverse,
  crypt = crypt
}