local bit = require("bit")
local mod = require("mod")
local base64 = require("base64")

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
  local f = io.open("primes_"..tostring(limit)..".dat", "r")
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

  local f = io.open("primes_"..tostring(limit)..".dat", "w")
  local primes = {2}
  f:write("2\n")
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
  math.randomseed(os.time())
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

local function crypt(msg, key)
  local n, e = unpack(key)
  return mod.exp(msg, e, n)
end

local function encrypt(data, key)
  local nums = {}
  for i = 1, #data, 5 do
    local m = 0
    for j = 0, 3 do
      m = m + (data:sub(i + j):byte() or 0)
      m = m * 256
    end
    m = m + (data:sub(i + 4):byte() or 0)
    local c = crypt(m, key)
    table.insert(nums, c)
  end
  return base64.enc48(nums)
end

local function decrypt(data, key)
  local bytes = base64.dec(data)
  local result = ""
  for i = 1, #bytes, 6 do
    local c = 0
    for j = 0, 4 do
      c = c + bytes[i + j]
      c = c * 256
    end
    c = c + bytes[i + 5]
    local m = crypt(c, key)
    result = result .. string.char(math.floor(m / 4294967296 % 256))
    result = result .. string.char(math.floor(m / 16777216 % 256))
    result = result .. string.char(math.floor(m / 65536 % 256))
    result = result .. string.char(math.floor(m / 256 % 256))
    result = result .. string.char(m % 256)
  end
  return result
end

local function sign(m, key)
  local h = hash(m, key[0])
  return crypt(h, key)
end

local tArgs = { ... }

local function test()
  local pub, pri = genkey()
  print(string.format("%.0f : %.0f", unpack(pub)))
  print(base64.enc48(pub))
  local decpub = base64.dec48(base64.enc48(pub))
  print(string.format("%.0f : %.0f", unpack(decpub)))
  print(string.format("%.0f : %.0f", unpack(pri)))
  print(base64.enc48(pri))
  local msg = 65

  local enc = encrypt(tArgs[1], pub)
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

local function dh()
  --[[
  local ps = primes(2^24)
  for n = #ps, 3, -1 do
    --print(ps[n])
    local ps2 = (ps[n] - 1) / 2
    --print("prime: ", ps[n], ps2)
    local isprime = true
    for i = 1, #ps do
      if ps2 == ps[i] then
        break
      elseif ps2 % ps[i] == 0 then
        isprime = false
        break
      end
    end
    if isprime then
      print(ps2, ps2*2+1)
    end
  end
  --]]
  math.randomseed(os.time())
  local p = 16776899
  local g = 5
  local a = math.random(2, 1000)
  local A = crypt(g, {p, a})

  local b = math.random(2, 1000)
  local B = crypt(g, {p, b})

  local s = crypt(B, {p, a})
  local S = crypt(A, {p, b})

  print(s, S)
end

dh()

return {
  hash = hash,
  genkey = genkey,
  gcd = gcd,
  inverse = inverse,
  crypt = crypt
}