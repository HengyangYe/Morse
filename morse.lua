-- morse.lua - 摩斯密码相关功能
local morse = {}

-- 摩斯密码字典
morse.DICT = {
  A=".-", B="-...", C="-.-.", D="-..", E=".",   F="..-.", G="--.", H="....",
  I="..", J=".---", K="-.-",  L=".-..", M="--",  N="-.",   O="---", P=".--.",
  Q="--.-",R=".-.", S="...",  T="-",   U="..-", V="...-", W=".--", X="-..-",
  Y="-.--",Z="--..",
  ["1"]=".----",["2"]="..---",["3"]="...--",["4"]="....-",["5"]=".....",
  ["6"]="-....",["7"]="--...",["8"]="---..",["9"]="----.",["0"]="-----",
  [" "]=" "
}

-- 生成求救信息
function morse.generateMessage(rng, messageCount)
  local distressMessages = {
    -- 初期信息
    { weight = 10, msgs = {"SOS", "CQD", "SOS CQD", "CQD SOS"} },
    -- 中期信息
    { weight = 5, msgs = {"SOS TITANIC", "CQD HELP", "SINKING FAST", "NEED HELP"} },
    -- 后期信息
    { weight = 2, msgs = {"WOMEN CHILDREN FIRST", "ENGINE ROOM FLOODING", "COME QUICKLY"} }
  }
  
  local urgency = math.min(3, math.floor(messageCount / 3) + 1)
  local msgSet = distressMessages[urgency].msgs
  local msg = msgSet[math.floor(rng() * #msgSet) + 1]
  
  -- 添加位置信息
  if rng() < 0.6 then
    local latDeg = 41
    local latMin = 46
    local lonDeg = 50
    local lonMin = 14
    latMin = latMin + math.floor(rng() * 10 - 5)
    lonMin = lonMin + math.floor(rng() * 10 - 5)
    local coords = string.format("%d %d N %d %d W", latDeg, latMin, lonDeg, lonMin)
    msg = msg .. " " .. coords
  end
  
  return msg
end

-- 文本转摩斯密码
function morse.textToMorse(txt)
  local t = {}
  for c in txt:upper():gmatch(".") do 
    table.insert(t, morse.DICT[c] or "") 
  end
  return table.concat(t)
end

return morse