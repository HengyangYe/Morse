-- game.lua - 游戏核心逻辑
local game = {}

-- 依赖
local morse = require("morse")

-- 常量
local DOT_THRESHOLD = 0.25
local START_TIME_PADDING = 5
local MESSAGE_BONUS_TIME = 3
local BATTERY_MAX = 100
local DOT_COST = 0.5
local DASH_COST = 1
local BATTERY_REGEN = 15

-- 游戏状态
game.state = "play"
game.loseReason = ""
game.countdown = 0
game.battery = BATTERY_MAX
game.messageCount = 0
game.successMessages = {}
game.inputMorse = ""
game.targetText = ""
game.targetMorse = ""
game.trimmed = ""
game.interference = 0
game.lastInterference = 0 
game.winShip = ""  -- 记录哪艘船到达了

-- 救援船（远离开始位置）
game.ships = {
  { name = "Carpathia",  eta0 = 120, x = -100, y = 400 },      -- 2分钟
  { name = "Californian",eta0 = 180, x = 1300, y = 450 },     -- 3分钟
  { name = "Olympic",    eta0 = 240, x = 600, y = 900 }       -- 4分钟
}

-- 泰坦尼克号
game.titanic = { x = 600, y = 600, angle = 0, sinking = 0 }  -- 调整到新的海洋中心

-- 冰山
game.icebergs = {}

-- 其他
game.rng = nil
game.viewRadius = 200
game.signalWaves = {}

-- 初始化
function game.init()
  love.window.setTitle("Titanic – Visual SOS Relay")
  love.window.setMode(1200, 800)  -- 更大的窗口
  love.graphics.setBackgroundColor(0,0,0)
  
  -- 初始化随机数生成器
  local seed = os.time() % 4294967296
  game.rng = function()
    seed = (1664525 * seed + 1013904223) % 4294967296
    return seed / 4294967296
  end
  
  -- 初始化船只
  for _,v in ipairs(game.ships) do
    v.eta = v.eta0
    v.trail = {}
  end
  
  -- 初始化冰山（两侧生成，静止）
  for i = 1, 10 do
    local side = (i % 2 == 0) and -1 or 1  -- 左右交替
    local xOffset = 250 + game.rng() * 150  -- 距离中心250-400像素
    local yOffset = -200 + i * 100  -- 垂直分布
    
    game.icebergs[i] = {
      x = game.titanic.x + side * xOffset,
      y = game.titanic.y + yOffset,
      size = 40 + game.rng() * 50,
      speed = 0.2 + game.rng() * 0.2,  -- 只向下漂移
      side = side  -- 记录是哪一侧
    }
  end
  
  -- 生成第一条消息
  game.generateNewMessage()
end

-- 生成新消息
function game.generateNewMessage()
  game.targetText = morse.generateMessage(game.rng, game.messageCount)
  game.targetMorse = morse.textToMorse(game.targetText)
  game.trimmed = game.targetMorse:gsub(" ","")
  game.inputMorse = ""
  
  if game.messageCount > 0 then
    local timeMultiplier = math.max(0.7, 1 - game.messageCount * 0.05)
    game.countdown = game.countdown + (#game.targetMorse * DOT_THRESHOLD * 3 * timeMultiplier) + MESSAGE_BONUS_TIME
    game.battery = math.min(BATTERY_MAX, game.battery + BATTERY_REGEN)
    
    -- 添加信号波
    table.insert(game.signalWaves, {
      x = game.titanic.x,
      y = game.titanic.y,
      radius = 0,
      life = 1
    })
  else
    game.countdown = #game.targetMorse * DOT_THRESHOLD * 3 + START_TIME_PADDING
  end
  
  game.messageCount = game.messageCount + 1
end

-- 计算信号强度
function game.signalStrength()
  local correct = 0
  for i = 1, #game.inputMorse do
    if game.inputMorse:sub(i,i) == game.trimmed:sub(i,i) then
      correct = correct + 1
    else break end
  end
  return correct / #game.trimmed
end

-- 更新游戏
function game.update(dt)
  if game.state ~= "play" then return end
  
  -- 倒计时
  game.countdown = game.countdown - dt
  if game.countdown <= 0 then
    game.state = "lose"
    game.loseReason = "TIME OUT"
  end
  
  -- 更新信号强度和视野
  local strength = game.signalStrength()
  -- 增加视野扩大速度：基础值更大，信号强度影响更大，消息数量奖励更多
  game.viewRadius = 150 + strength * 300 + game.messageCount * 30
  
  -- 更新救援船
  local speedBonus = game.messageCount * 0.1
  local closestShip = nil
  local closestDist = math.huge
  
  for _,s in ipairs(game.ships) do
    local v = 0.5 + strength * 1.5 + speedBonus
    s.eta = math.max(0, s.eta - dt * v)
    
    -- 计算基于ETA的位置
    local progress = 1 - (s.eta / s.eta0)  -- 0到1的进度
    
    -- 起始位置到泰坦尼克号的向量
    local startX, startY = s.x, s.y
    if not s.startX then
      s.startX, s.startY = s.x, s.y  -- 保存起始位置
    end
    
    local dx = game.titanic.x - s.startX
    local dy = game.titanic.y - s.startY
    
    -- 根据进度移动船只
    s.x = s.startX + dx * progress
    s.y = s.startY + dy * progress
    
    -- 轨迹
    if #s.trail == 0 or math.sqrt((s.x - s.trail[#s.trail].x)^2 + (s.y - s.trail[#s.trail].y)^2) > 5 then
      table.insert(s.trail, {x = s.x, y = s.y})
      if #s.trail > 30 then table.remove(s.trail, 1) end
    end
    
    -- 计算距离
    local dist = math.sqrt((s.x - game.titanic.x)^2 + (s.y - game.titanic.y)^2)
    if dist < closestDist then
      closestDist = dist
      closestShip = s
    end
    
    -- 检查胜利条件：ETA为0且距离足够近
    if s.eta <= 0 and dist < 60 then
      game.state = "win"
      game.winShip = s.name
      return
    end
  end
  
  -- 更新冰山（只向下漂移，保持在两侧）
  for _,ice in ipairs(game.icebergs) do
    -- 缓慢向下漂移
    ice.y = ice.y + ice.speed * dt * 10
    
    -- 如果超出屏幕底部，重置到顶部
    if ice.y > game.titanic.y + 400 then
      ice.y = game.titanic.y - 400 - game.rng() * 200
      -- 保持在同一侧，但随机调整水平位置
      local xOffset = 250 + game.rng() * 150
      ice.x = game.titanic.x + ice.side * xOffset
    end
  end
  
  -- 冰山现在不会碰撞，只是视觉元素
  -- 游戏目标是坚持到救援船到达
  
  -- 电量检查
  if game.battery <= 0 then
    game.battery = 0
    game.state = "lose"
    game.loseReason = "BATTERY DEAD"
  end
  
  -- 更新信号波
  for i = #game.signalWaves, 1, -1 do
    local w = game.signalWaves[i]
    w.radius = w.radius + dt * 200
    w.life = w.life - dt * 0.5
    if w.life <= 0 then
      table.remove(game.signalWaves, i)
    end
  end
  
  -- 更新干扰
  if love.timer.getTime() - game.lastInterference > 10 + game.rng() * 20 then
    game.interference = 0.3 + game.rng() * 0.7
    game.lastInterference = love.timer.getTime()
  end
  game.interference = math.max(0, game.interference - dt * 0.5)
  
  -- 失败动画
  if game.state == "lose" then
    game.titanic.angle = game.titanic.angle + dt * 0.3
    game.titanic.sinking = game.titanic.sinking + dt * 0.5
  end
end

-- 处理输入结果
function game.handleInput(symbol, cost)
  game.battery = game.battery - cost
  game.inputMorse = game.inputMorse .. symbol
  
  if #game.inputMorse >= #game.trimmed then
    if game.inputMorse == game.trimmed then
      table.insert(game.successMessages, game.targetText)
      game.generateNewMessage()
    else
      game.state = "lose"
      game.loseReason = "WRONG CODE"
    end
  end
end

return game