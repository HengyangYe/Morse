-- visual.lua - 视觉渲染模块
local visual = {}

-- 依赖
local game = require("game")

-- 常量
local STATIC_INTENSITY = 0.03
local WAVE_SPEED = 0.5

-- 视觉元素
local staticNoise = {}
local waves = {}
local scanlineY = 0

-- 初始化（在game.init中调用）
function visual.init()
  -- 静态噪声
  for i = 1, 100 do
    staticNoise[i] = {
      x = game.rng() * 1200,
      y = game.rng() * 800,
      life = game.rng()
    }
  end
  
  -- 波浪
  for i = 1, 10 do
    waves[i] = {
      x = game.rng() * 1200,
      y = 400 + game.rng() * 400,
      phase = game.rng() * math.pi * 2,
      amplitude = 5 + game.rng() * 10
    }
  end
end

-- 绘制海洋视图
local function drawOceanView()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local oceanH = h / 2  -- 海洋占下半部分
  
  -- 海洋背景
  love.graphics.setColor(0.05, 0.05, 0.1)
  love.graphics.rectangle("fill", 0, h/2, w, oceanH)
  
  -- 波浪
  love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
  for _,wave in ipairs(waves) do
    local waveY = wave.y + math.sin(love.timer.getTime() * WAVE_SPEED + wave.phase) * wave.amplitude
    love.graphics.circle("line", wave.x, waveY, 20)
  end
  
  -- 雾气效果
  love.graphics.setStencilTest("greater", 0)
  love.graphics.stencil(function()
    love.graphics.circle("fill", game.titanic.x, game.titanic.y, game.viewRadius)
  end, "replace", 1)
  
  -- 信号波
  for _,w in ipairs(game.signalWaves) do
    love.graphics.setColor(1, 1, 1, w.life * 0.3)
    love.graphics.circle("line", w.x, w.y, w.radius)
  end
  
  -- 冰山
  love.graphics.setColor(1, 1, 1)  -- 纯白色
  for _,ice in ipairs(game.icebergs) do
    love.graphics.push()
    love.graphics.translate(ice.x, ice.y)
    -- 更大的冰山
    love.graphics.polygon("fill", 
      -ice.size, ice.size,
      -ice.size*0.7, -ice.size*0.5,
      0, -ice.size,
      ice.size*0.7, -ice.size*0.5,
      ice.size, ice.size
    )
    -- 冰山轮廓
    love.graphics.setColor(0.7, 0.7, 0.7)  -- 灰色轮廓
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", 
      -ice.size, ice.size,
      -ice.size*0.7, -ice.size*0.5,
      0, -ice.size,
      ice.size*0.7, -ice.size*0.5,
      ice.size, ice.size
    )
    love.graphics.setLineWidth(1)
    love.graphics.pop()
  end
  
  -- 救援船
  for _,s in ipairs(game.ships) do
    -- 轨迹
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    for i,t in ipairs(s.trail) do
      love.graphics.circle("fill", t.x, t.y, 3)
    end
    
    -- 船体（白色填充）
    love.graphics.setColor(0.8, 0.8, 0.8)  -- 浅灰色
    love.graphics.push()
    love.graphics.translate(s.x, s.y)
    love.graphics.polygon("fill", -15, 8, 15, 8, 20, 0, 15, -8, -15, -8, -20, 0)
    -- 船体轮廓
    love.graphics.setColor(1, 1, 1)  -- 白色轮廓
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", -15, 8, 15, 8, 20, 0, 15, -8, -15, -8, -20, 0)
    love.graphics.setLineWidth(1)
    love.graphics.pop()
    
    -- 船名
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(s.name, s.x - 50, s.y + 15)
  end
  
  -- 泰坦尼克号
  love.graphics.setColor(1, 1, 1)  -- 纯白色
  love.graphics.push()
  love.graphics.translate(game.titanic.x, game.titanic.y + game.titanic.sinking * 20)
  love.graphics.rotate(game.titanic.angle)
  -- 更大的船体
  love.graphics.polygon("fill", -30, 15, 30, 15, 35, 0, 30, -15, -30, -15, -35, 0)
  -- 船体轮廓
  love.graphics.setColor(0.3, 0.3, 0.3)  -- 深灰色轮廓
  love.graphics.setLineWidth(2)
  love.graphics.polygon("line", -30, 15, 30, 15, 35, 0, 30, -15, -30, -15, -35, 0)
  love.graphics.setLineWidth(1)
  -- 烟囱
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", -15, -12, 6, 10)
  love.graphics.rectangle("fill", -3, -12, 6, 10)
  love.graphics.rectangle("fill", 9, -12, 6, 10)
  love.graphics.pop()
  
  -- 标签
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("TITANIC", game.titanic.x - 30, game.titanic.y + 25)
  
  love.graphics.setStencilTest()
  
  -- 雾气边缘
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.setLineWidth(50)
  love.graphics.circle("line", game.titanic.x, game.titanic.y, game.viewRadius + 25)
  love.graphics.setLineWidth(1)
end

-- 绘制高亮的摩斯码
local function drawHighlightedMorse(y)
  local w = love.graphics.getWidth()
  local font = love.graphics.getFont()
  local morseWithoutSpaces = game.trimmed  -- 没有空格的摩斯码
  local totalWidth = 0
  
  -- 计算总宽度
  for i = 1, #game.targetMorse do
    totalWidth = totalWidth + font:getWidth(game.targetMorse:sub(i,i))
  end
  
  local x = (w - totalWidth) / 2
  local inputIndex = 1
  
  -- 绘制每个字符
  for i = 1, #game.targetMorse do
    local ch = game.targetMorse:sub(i,i)
    
    if ch ~= " " then
      -- 这是一个摩斯码字符
      local color
      if inputIndex <= #game.inputMorse then
        -- 已输入的部分：检查是否正确
        if game.inputMorse:sub(inputIndex, inputIndex) == ch then
          color = {1, 1, 1}  -- 正确：白色
        else
          color = {0.3, 0.3, 0.3}  -- 错误：暗灰色
        end
      else
        -- 未输入的部分
        color = {0.7, 0.7, 0.7}  -- 浅灰色
      end
      
      love.graphics.setColor(color)
      love.graphics.print(ch, x, y)
      inputIndex = inputIndex + 1
    else
      -- 空格
      love.graphics.setColor(0.5, 0.5, 0.5)
      love.graphics.print(" ", x, y)
    end
    
    x = x + font:getWidth(ch)
  end
  
  love.graphics.setColor(1, 1, 1)  -- 重置颜色
end

-- 绘制摩斯界面
local function drawMorseInterface()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local interfaceH = h / 2
  
  -- 分隔线
  love.graphics.setColor(1, 1, 1)
  love.graphics.setLineWidth(2)
  love.graphics.line(0, h/2, w, h/2)
  love.graphics.setLineWidth(1)
  
  -- 更新和绘制静态噪声
  love.graphics.setColor(1, 1, 1, STATIC_INTENSITY)
  for _,p in ipairs(staticNoise) do
    p.life = p.life - love.timer.getDelta() * 2
    if p.life <= 0 then
      p.x = game.rng() * w
      p.y = game.rng() * h
      p.life = game.rng()
    end
    if p.life > 0.5 and p.y < h/2 then
      love.graphics.points(p.x, p.y)
    end
  end
  
  -- 扫描线
  scanlineY = (scanlineY + 50 * love.timer.getDelta()) % h
  if scanlineY < h/2 then
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.rectangle("fill", 0, scanlineY - 10, w, 20)
  end
  
  -- 干扰
  if game.interference > 0 then
    love.graphics.setColor(1, 1, 1, game.interference * 0.3)
    love.graphics.rectangle("fill", 0, 0, w, h/2)
  end
  
  love.graphics.setColor(1, 1, 1)
  
  -- 消息计数
  love.graphics.printf("MESSAGES: "..game.messageCount, 10, 10, w-20, "left")
  
  -- 文本显示
  local alpha = game.interference > 0.5 and (0.5 + math.sin(love.timer.getTime() * 20) * 0.5) or 1
  love.graphics.setColor(1, 1, 1, alpha)
  
  love.graphics.printf("TARGET: "..game.targetText, 0, 40, w, "center")
  love.graphics.print("MORSE: ", w/2 - 200, 60)  -- 标签
  
  -- 使用高亮函数绘制摩斯码
  drawHighlightedMorse(60)
  
  love.graphics.printf("INPUT: "..game.inputMorse, 0, 100, w, "center")
  
  love.graphics.setColor(1, 1, 1)
  
  -- 时间条
  local maxTime = 40
  local barW = math.max(0, math.min(1, game.countdown/maxTime)) * 600
  local timeBarX = (w - 600) / 2  -- 居中
  love.graphics.rectangle("line", timeBarX, 140, 600, 10)
  love.graphics.rectangle("fill", timeBarX, 140, barW, 10)
  love.graphics.printf(string.format("TIME %.1f", math.max(0, game.countdown)), 0, 155, w, "center")
  
  -- 电池条
  local batPct = game.battery / 100
  love.graphics.setColor(batPct < 0.3 and {1,1,1} or {0.8,0.8,0.8})  -- 低电量时白色闪烁
  love.graphics.rectangle("line", timeBarX, 180, 600, 10)
  love.graphics.setColor(1, 1, 1)  -- 白色填充
  love.graphics.rectangle("fill", timeBarX, 180, 600 * batPct, 10)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(string.format("BATTERY %.0f%%", batPct * 100), 0, 195, w, "center")
  
  -- 救援船ETA和进度条
  love.graphics.printf("RESCUE SHIPS:", 0, 230, w, "center")
  local etaY = 250
  for _,s in ipairs(game.ships) do
    -- 船名和ETA
    local etaText = string.format("%s - ETA: %d:%02d", 
      s.name, 
      math.floor(s.eta / 60), 
      math.floor(s.eta % 60)
    )
    love.graphics.printf(etaText, 150, etaY, w-300, "left")
    
    -- 进度条
    local progress = 1 - (s.eta / s.eta0)
    love.graphics.setColor(0.5, 0.5, 0.5)  -- 灰色边框
    love.graphics.rectangle("line", 400, etaY + 2, 400, 14)
    love.graphics.setColor(0.8, 0.8, 0.8)  -- 浅灰色填充
    love.graphics.rectangle("fill", 400, etaY + 2, 400 * progress, 14)
    love.graphics.setColor(1, 1, 1)
    
    etaY = etaY + 20
  end
  
  -- 干扰警告
  if game.interference > 0.5 then
    love.graphics.setColor(1, 1, 1, math.sin(love.timer.getTime() * 10) * 0.5 + 0.5)  -- 白色闪烁
    love.graphics.printf("!!! INTERFERENCE !!!", 0, 20, w, "center")
    love.graphics.setColor(1, 1, 1)
  end
end

-- 主绘制函数
function visual.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  love.graphics.clear(0, 0, 0)
  
  drawOceanView()
  drawMorseInterface()
  
  -- 游戏状态覆盖
  if game.state == "win" then
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("RESCUE SUCCESSFUL!\n\nThe "..game.winShip.." has arrived!\nYou sent "..(game.messageCount-1).." distress calls\n\n<Enter or Space to Restart>", 0, h/2-50, w, "center")
  elseif game.state == "lose" then
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("TRAGEDY STRIKES\n\n"..game.loseReason.."\nMessages sent: "..(game.messageCount-1).."\n\n<Enter or Space to Restart>", 0, h/2-50, w, "center")
  end
end

-- 在game初始化后调用
game.init = (function()
  local originalInit = game.init
  return function()
    originalInit()
    visual.init()
  end
end)()

return visual