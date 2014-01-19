-- get modem peripheral
local modem

for side in pairs(peripheral.getSides()) do
  if peripheral.getType(side) == "modem" then
  	modem = peripheral.wrap(side)
  	break
  end
end

if modem == nil then
  print("no modem")
  return 1
end

-- send mail
local function send(msg)
  modem.transmit(25, 25, "hello")
  modem.open(25)
  -- event, modemSide, senderChannel, replyChannel, message, senderdistance
  local event = {os.pullEvent("modem_message")}
  if event[5] == "ok" then
    modem.transmit(25, 25, msg)
    event = {os.pullEvent("modem_message")}
    return (event[5] == "ok")
  else
    return false
  end
end

-- get mail
local function get(user, passhash)
  modem.transmit(25, 25, "")