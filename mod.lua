function mult(a, b, m)
  local result = 0
  while a > 0 do
    if a % 2 == 1 then
      result = (result + b) % m
    end
    a = math.floor(a / 2)
    b = b * 2 % m
  end
  return result
end

function exp(a, e, m)
  local result = 1
  while e ~= 0 do
    if e % 2 == 1 then
      result = mult(result, a, m)
    end
    a = mult(a, a, m)
    e = math.floor(e / 2)
  end
  return result
end

return {
  mult = mult,
  exp = exp
}