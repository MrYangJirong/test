local class = require('middleclass')
local HasSignals = require('HasSignals')
local User = class('User'):include(HasSignals)
local tools = require('app.helpers.tools')

function User:initialize()
  HasSignals.initialize(self)
  local app = require("app.App"):instance()
  app.conn:on("updateMoney",function(msg)
    self.money = msg.money
    self.emitter:emit('updateMoney', self.money)
  end)

  app.conn:on('updateRes',function(msg)
    self[msg.key] = msg.value
    self.emitter:emit('updateRes')
  end)

  app.conn:on('getNotify',function(msg)
    self.emitter:emit('getNotify', msg)
  end)

  app.conn:on('notify',function(msg)
    self.emitter:emit('notify',msg)
  end)

  app.conn:on('queryContact',function(msg)
    self.emitter:emit('queryContact',msg)
  end)

  app.conn:on('somebodyGive',function(msg)
    self[msg.resName] = msg.now
    self.emitter:emit('updateRes')

    tools.showRemind(msg.nickName..'赠送了你'..msg.inc..'颗钻石')
  end)

  app.conn:on('buyDiamondCntUpdate',function(msg)
    self.buyDiamondCnt = msg.buyDiamondCnt
    self.emitter:emit('updateRes')
  end)

  app.conn:on('queryPayOrder',function(msg)
    self.emitter:emit('queryPayOrder',msg.order)
  end)

  app.conn:on('listRooms', function(msg)
    self.emitter:emit('listRooms', msg)
  end)

  app.conn:on('inputInvitePlayerId', function(msg)
    self.emitter:emit('inputInvitePlayerId', msg)
    self.emitter:emit('updateRes')
  end)

  app.conn:on('chargeResult', function(msg)
    self.emitter:emit('chargeResult', msg)
  end)
  
  local errorCodeMsg = {
    [1] = '资源不足',
    [2] = '玩家ID不存在',
    [3] = '超过今日赠送的最大配额',
    [4] = '提高你的VIP等级可提升数额'
  }
  app.conn:on('giveRes',function(msg)
    if msg.errorCode then
      tools.showRemind(errorCodeMsg[msg.errorCode])
    else
      tools.showRemind('赠送成功')
    end
  end)

  --[[app.conn:on('updateInfo',function(msg)
    self.sex = msg.sex
    self.nickName = msg.nickName
    self.avatar = msg.avatar
    self.modifyedName = true
    self.diamond = msg.diamond
    self.emitter:emit('updateMoney')
    self.emitter:emit('updateInfo')
  end)]]
end

function User:getNotify()--luacheck:ignore
  local app = require("app.App"):instance()
  local msg = {
    msgID = 'getNotify',
  }
  app.conn:send(msg)
end

function User:exchange()--luacheck:ignore
  local app = require("app.App"):instance()
  local msg = {
    msgID = 'exchange',
    number = 1
  }
  app.conn:send(msg)
end

function User:initFromNet(info)
	dump(info)
  for i, v in pairs(info) do
    self[i] = v
  end

  self.emitter:emit('userinfo',info)
  self:synGPS()
end

function User:synGPS()--luacheck:ignore
  local app = require("app.App"):instance()
  local location = require('location')
  local x,y = location.getGPS()

  if self.x ~= x or self.y ~= y then
    self.x = x
    self.y = y

    local msg = {
      msgID = 'synGPS',
      x = x,
      y = y
    }

    app.conn:send(msg)
  end
end

local vip_map = {
  {0,0},              -- vip0
  {1000,0.02},        -- vip1
  {2000,0.05},        -- vip2
  {5000,0.1},         -- vip3
  {10000,0.15},       -- vip4
  {20000,0.2},        -- vip5
  {50000,0.3},        -- vip6
}

function User.getVipMap()
  return vip_map
end

function User:calcVIP()
  local buyDiamondCnt = self.buyDiamondCnt

  for i = #vip_map,1,-1 do
    local data = vip_map[i]

    if buyDiamondCnt >= data[1] then
      local mod = 0
      local distance = 0
      if i < #vip_map then
        local next = vip_map[i+1]
        mod = 1 - (next[1] - buyDiamondCnt) / (next[1]-data[1])
        distance = next[1] - buyDiamondCnt
      end

      return i,mod,distance
    end
  end

  return 1,0
end

function User:paySuccess(gem,rmb)--luacheck:ignore
  local app = require("app.App"):instance()
  local msg = {
    msgID = 'paySuccess',
    gem = gem,
    rmb = rmb
  }
  app.conn:send(msg)
end

function User:giveRes(id,diamond)--luacheck:ignore
  local app = require("app.App"):instance()
  local msg = {
    msgID = 'giveRes',
    resName = 'diamond',
    playerId = id,
    value = diamond,
  }
  app.conn:send(msg)
end

function User:queryPayOrder()--luacheck:ignore
  local app = require("app.App"):instance()
  local msg = {
    msgID = 'queryPayOrder',
  }
  app.conn:send(msg)
end

function User:queryContact()
  local app = require("app.App"):instance()
  local msg = {
    msgID = 'queryContact',
  }
  app.conn:send(msg)
end

function User:queryListRooms()
  local app = require("app.App"):instance()
  local msg = {
    msgID = 'listRooms',
  }
  app.conn:send(msg)
end


return User
