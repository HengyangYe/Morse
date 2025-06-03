-- input.lua - 输入处理模块
local input = {}

-- 依赖
local game = require("game")

-- 常量
local DOT_THRESHOLD = 0.25
local TAP_WINDOW = 0.40
local DOT_COST = 0.5
local DASH_COST = 1

-- 状态
local pressStart = nil
local tapTimes = {}
local dotBeep = nil
local dashBeep = nil

-- 初始化音效
function input.init()
  dotBeep = love.audio.newSource("beep.wav", "static")
  dashBeep = love.audio.newSource("beep.wav", "static")
  dashBeep:setPitch(0.6)
  dotBeep:setPitch(1.0)
end

-- 注册点击（用于三连点撤回）
local function registerDotRelease(now)
  table.insert(tapTimes, now)
  while tapTimes[1] and now - tapTimes[1] > TAP_WINDOW do
    table.remove(tapTimes, 1)
  end
  
  if #tapTimes >= 3 then
    if #game.inputMorse > 0 then
      game.inputMorse = game.inputMorse:sub(1, -2)
    end
    tapTimes = {}
    return true
  end
  return false
end

-- 按键按下
function input.keypressed(key)
  if game.state ~= "play" then
    if key == "return" or key == "space" then 
      love.event.quit("restart") 
    end
    return
  end
  
  if key == "space" then 
    pressStart = love.timer.getTime() 
  end
  
  if key == "backspace" and #game.inputMorse > 0 then
    game.inputMorse = game.inputMorse:sub(1, -2)
  end
end

-- 按键释放
function input.keyreleased(key)
  if game.state ~= "play" then return end
  
  if key == "space" and pressStart then
    local duration = love.timer.getTime() - pressStart
    pressStart = nil
    local now = love.timer.getTime()
    
    local symbol, snd, cost
    if duration < DOT_THRESHOLD then
      if registerDotRelease(now) then return end
      symbol, snd, cost = ".", dotBeep, DOT_COST
    else
      tapTimes = {}
      symbol, snd, cost = "-", dashBeep, DASH_COST
    end
    
    snd:stop()
    snd:play()
    
    game.handleInput(symbol, cost)
  end
end

-- 在game初始化后调用
game.init = (function()
  local originalInit = game.init
  return function()
    originalInit()
    input.init()
  end
end)()

return input