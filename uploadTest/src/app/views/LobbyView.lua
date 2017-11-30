local HeartbeatCheck = require('app.helpers.HeartbeatCheck')
local cache = require('app.helpers.cache')
local Scheduler = require('app.helpers.Scheduler')

local app = require("app.App"):instance()
local tools = require('app.helpers.tools')

local LobbyView = {}
function LobbyView:initialize()
	self.heartbeatCheck = HeartbeatCheck()
	
	self.updateF = Scheduler.new(function(dt)
		self:update(dt)
	end)
	
	self:enableNodeEvents()

 
	--安卓返回键监听
	local eventDispatcher = self:getEventDispatcher()
	local listenerKey = cc.EventListenerKeyboard:create()
	
	local function onKeyReleaseed(keycode, event)
		if keycode == cc.KeyCode.KEY_BACK then
			tools.showMsgBox("提示", "是否退出游戏?", 2):next(function(btn)
				if btn == 'enter' then
					cc.Director:getInstance():endToLua()
					-- 关闭定时器
					cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
				end
			end)
		end
	end
	
	listenerKey:registerScriptHandler(onKeyReleaseed, cc.Handler.EVENT_KEYBOARD_RELEASED)
	eventDispatcher:addEventListenerWithSceneGraphPriority(listenerKey, self)
end 

function LobbyView:layout()

  local MainPanel = self.ui:getChildByName('MainPanel')
  MainPanel:setContentSize(cc.size(display.width,display.height))
  MainPanel:setPosition(display.cx,display.cy)
  self.MainPanel = MainPanel

  local bg = MainPanel:getChildByName('bg')
  bg:setContentSize(cc.size(display.width,display.height))
  bg:setPosition(display.cx,display.cy)

  local TopBar = MainPanel:getChildByName('TopBar')
  TopBar:setPositionY(display.height)
  self.TopBar = TopBar

  local topSize = TopBar:getContentSize()
  topSize.height = topSize.height + 50

  local BottomBar = self.MainPanel:getChildByName('BottomBar')
  local bottomSize = BottomBar:getContentSize()
  local middleHeight = display.height - bottomSize.height - topSize.height
  local headNode = TopBar:getChildByName('head')
  self.TopBar.headNode = headNode

  --if device.platform == 'ios' then
  --  BottomBar:getChildByName('exit'):hide()
  --end

  local head = headNode:getChildByName('icon')
  head:retain()
  cache.get(app.session.user.avatar,function(ok,path)
    if ok then
      head:loadTexture(path)
    end
    head:release()
  end)
  self.head = head

  self:loadData()

  self.roomList = TopBar:getChildByName('roomList')
  local list = self.roomList:getChildByName('list')
  
  --list:setItemsMargin(5)
  list:setScrollBarEnabled(false)
end

function LobbyView:clickDownload()
  -- local spr = cc.Sprite:create('views/lobby/mmexport1488249280343.jpg')
  -- self:addChild(spr)
  -- spr:setPosition(display.cx,display.cy)
  -- local sprSize = spr:getContentSize()

  -- local label = cc.Label:createWithTTF('扫码下载','views/font/fangzheng.ttf',35, cc.size(620,0),cc.TEXT_ALIGNMENT_CENTER)
  -- spr:addChild(label)
  -- label:setPosition(sprSize.width/2,-40)

  -- self.black:addClickEventListener(function()
  --   spr:removeFromParent()
  --   self.black:hide()
  -- end)
end

function LobbyView:getHeadWorldPos()
  local pos = cc.p(self.head:getPosition())
  local world = self.head:getParent():convertToWorldSpace(pos)

  return world
end

function LobbyView:loadData()
  self:freshInfo()
end

function LobbyView:freshInfo()
  local app = require("app.App"):instance()
  local user = app.session.user
  self.TopBar.headNode:getChildByName('nickname'):setString(user.nickName)
  self.TopBar.headNode:getChildByName('id'):getChildByName('value'):setString(user.playerId)
  self.TopBar.headNode:getChildByName('frame'):getChildByName('number'):setString(user.diamond)
  local femal = self.TopBar.headNode:getChildByName('femal')
  local male = self.TopBar.headNode:getChildByName('male')
  femal:setVisible(false)
  male:setVisible(false)
  if user.sex == 1 then
    femal:setVisible(true)
  else
    male:setVisible(true)
  end
end

function LobbyView:onExit()
  if self.updateF then
    Scheduler.delete(self.updateF)
    self.updateF = nil
  end
end

function LobbyView:update(dt)
  self:sendHeartbeatMsg(dt)
end

function LobbyView:onPing()
  self.heartbeatCheck:onPing()
end

function LobbyView:sendHeartbeatMsg(dt)
  self.heartbeatCheck:update(dt)
end

function LobbyView:freshImageTitle(mode)
  local roomList = self.roomList
  local img_haoyou = roomList:getChildByName('img_haoyou')
  local img_niuyou = roomList:getChildByName('img_niuyou')
  img_haoyou:setVisible(false)
  img_niuyou:setVisible(false)

  if mode == 'friend' then
    img_haoyou:setVisible(true)
  else
    img_niuyou:setVisible(true)
  end
end

function LobbyView:freshRoomListView(btnName)
  local roomList = self.roomList
  local list = roomList:getChildByName('list')
  local list1 = roomList:getChildByName('list1')
  list:setVisible(false)
  list1:setVisible(false)

  if btnName == 'friend' then
    list:setVisible(true)
  else
    list1:setVisible(true)
  end
end

function LobbyView:loadRooms(rooms)
  local function freshListView(rooms, mode)
    local roomList = self.roomList
    local list = roomList:getChildByName('list')
    if mode == 2 then
      list = roomList:getChildByName('list1')
    end
    local Image_noRoom = self.roomList:getChildByName('Image_noRoom')
    local Text_noRoom = self.roomList:getChildByName('Text_noRoom')
  
    if not rooms or nil == rooms.rooms then
      -- list:setVisible(false)
      Image_noRoom:setVisible(true)
      Text_noRoom:setVisible(true)
      list:removeAllItems()
      return
    else
      -- list:setVisible(true)
      Image_noRoom:setVisible(false)
      Text_noRoom:setVisible(false)
    end
  
    list:setItemModel(list:getItem(0))
    list:removeAllItems()
    local data = rooms.rooms
    local arr = { '牛牛上庄', '固定庄家', '自由抢庄', '明牌抢庄', '通比牛牛', '', '疯狂加倍'}
  
    for i, v in ipairs(data) do
      list:pushBackDefaultItem()
      local item = list:getItem(i - 1)
      local roomId = item:getChildByName('roomId')
      roomId:setString(v.deskId)
  
      local gameplay = item:getChildByName('game')
      gameplay:setString(arr[v.options.gameplay])
  
      local base = item:getChildByName('base')
      base:setString(v.options.base)
  
      local round = item:getChildByName('round')
      round:setString(v.options.round)
  
      local pay = item:getChildByName('pay')
      local payText = "房主"
      if v.options.roomPrice == 1 then
        payText = "房主"
      else
        payText = "AA"
      end
      pay:setString(payText)
  
      local maxPeople = item:getChildByName('maxPeople')
      maxPeople:setString(v.actors)
  
      local inviteBtn=item:getChildByName('invite')
      inviteBtn:addClickEventListener(function()
          self.emitter:emit('inviteBtn',v) --邀请
      end)
      
      item:addClickEventListener(function()
        local rId = v.deskId
        app.session.room:enterRoom(rId, false)
      end)
    end
  end
  
  local data1 = {}
  local data2 = {}
  
  if rooms.rooms and #rooms.rooms > 0 then
    for i,v in pairs(rooms.rooms) do
      if v.groupInfo then
        if not data2.rooms then data2.rooms = {} end
        table.insert( data2.rooms, v)
      else
        if not data1.rooms then data1.rooms = {} end
        table.insert( data1.rooms, v)
      end
    end
  end

  freshListView(data1, 1)
  freshListView(data2, 2)
end

function LobbyView:displayMenu(bool)
    local BottomBar = self.MainPanel:getChildByName('BottomBar')
    local menu=BottomBar:getChildByName('menuBG')
    menu:setVisible(bool)
  
end

return LobbyView
