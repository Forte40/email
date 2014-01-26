-- map of base64 characters to numbers
local base64 = {}
for i = 0, 25 do
  base64[i] = string.char(i + 65)
  base64[string.char(i + 65)] = i
  base64[i + 26] = string.char(i + 97)
  base64[string.char(i + 97)] = i + 26
  if i < 10 then
    base64[i + 52] = string.char(i + 48)
    base64[string.char(i + 48)] = i + 52
  end
end
base64[62] = "+"
base64["+"] = 62
base64[63] = "/"
base64["/"] = 63

-- encode a list of bytes into a base64 string
function enc(bytes)
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

-- encode a list of 48 bit numbers (6 bytes) into a base64 string
function enc48(nums)
  local result = ""
  for pos = 1, #nums do
    local bit1 = math.floor(nums[pos] / 16777216)
    local bit2 = nums[pos] % 16777216
    result = result .. base64[bit.rshift(bit1, 18)     ]
    result = result .. base64[bit.rshift(bit1, 12) % 64]
    result = result .. base64[bit.rshift(bit1, 6 ) % 64]
    result = result .. base64[           bit1      % 64]
    result = result .. base64[bit.rshift(bit2, 18)     ]
    result = result .. base64[bit.rshift(bit2, 12) % 64]
    result = result .. base64[bit.rshift(bit2, 6 ) % 64]
    result = result .. base64[           bit2      % 64]
  end
  return result
end

-- turn an ascii string into a list of bytes and encode
function encS(data)
  local bytes = {}
  for pos = 1, #data do
    bytes[pos] = data:sub(pos, pos):byte()
  end
  return base64enc(bytes)
end

-- decode a base64 string into a list of bytes
function dec(data)
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

-- decode a base64 string into a list of 48 bit numbers (6 bytes)
function dec48(data)
  local result = {}
  for pos = 1, #data, 8 do
    local bits = 0
    for p = 0, 7 do
      bits = bits * 64
      bits = bits + base64[data:sub(pos + p, pos + p)]
    end
    table.insert(result, bits)
  end
  return result
end

-- decode a base64 string into an ascii string
function decS(bytes)
  local new_bytes = base64dec(bytes)
  print(#new_bytes)
  local result = ""
  for pos = 1, #new_bytes do
    result = result .. string.char(new_bytes[pos])
  end
  return result
end
