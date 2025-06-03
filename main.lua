-- Titanic SOS Relay - 主文件

local game = require("game")
local visual = require("visual") 
local morse = require("morse")
local input = require("input")

function love.load()
  game.init()
end

function love.update(dt)
  game.update(dt)
end

function love.draw()
  visual.draw()
end

function love.keypressed(key)
  input.keypressed(key)
end

function love.keyreleased(key)
  input.keyreleased(key)
end