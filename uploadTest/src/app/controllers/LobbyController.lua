local class = require('middleclass')
local Controller = require('mvc.Controller')
local LobbyController = class("LobbyController", Controller)
local TranslateView = require('app.helpers.TranslateView')
local SoundMng = require "app.helpers.SoundMng"
local tools = require('app.helpers.tools')
local EventCenter = require("EventCenter")
local app = require("app.App"):instance()
function LobbyController:initialize()
	Controller.initialize(self)
	local bgmFlag = SoundMng.getEftFlag(SoundMng.type[1])
    local EftFlag = SoundMng.getEftFlag(SoundMng.type[2])
    local bgmVol, sfxVol = SoundMng.getVol()
    SoundMng.setBgmVol(bgmVol)
    SoundMng.setSfxVol(sfxVol)
	SoundMng.setBgmFlag(bgmFlag)
    SoundMng.setEftFlag(EftFlag)
    SoundMng.setPlaying(false)
    if bgmFlag == nil then
       bgmFlag = true
    end
    if EftFlag == nil then
        EftFlag = true
    end

	SoundMng.playBgm('hall_bg1.mp3')
	
	app.session.user:queryListRooms()
	
	self.menuVisible = false

       self.wfName = {
        '牛牛上庄',
        '固定庄家',
        '自由抢庄',
        '明牌抢庄',
        '通比牛牛',
        '',
        '疯狂加倍',
    }
	
	
	-- 每隔两秒定时发送请求更新房间列表
	local scheduler = cc.Director:getInstance():getScheduler()
	self.schedulerID = scheduler:scheduleScriptFunc(function()
		app.session.user:queryListRooms()
	end, 10, false)
end 

function LobbyController:finalize()-- luacheck: ignore
    for i = 1,#self.listener do
        self.listener[i]:dispose()
    end

     -- 注销 切换事件监听
    EventCenter.clear("app")
end

function LobbyController:viewDidLoad()
    self.view:layout()
    local user = app.session.user


    EventCenter.register("app", function(event)
        if event then 
            -- didEnterBackground   
            -- willEnterForeground
           if event == 'didEnterBackground' then
                SoundMng.isPauseVol(true)
           elseif event == 'willEnterForeground'then
                SoundMng.isPauseVol(false)
           end
        end
    end)
    self.listener = {
    app.session.room:on('needEnterRoom',function()
        app:switch('GamesCityDeskController')
    end),
    app.conn:on('ping',function()
        self.view:onPing()
    end),
    user:on('freshInfo',function()
        self.view:freshInfo()
    end),
    user:on('updateRes',function()
        self.view:freshInfo()
    end),
    user:on('notify',function(msg)
        self.notifyController:notify(msg)
    end),

    user:on('listRooms',function(rooms)
      self.view:loadRooms(rooms)
    end),

    }

    
    self.view:on('inviteBtn',function(data)
        self:inviteFriend(data)
    end)

    self:loadNotifyController()
    app.session.room:doSync()

    self:clickFriendRoomList()
end

local function setWidgetAction(controller, self, args)
    SoundMng.playEft('btn_click.mp3')
    local ctrl = Controller:load(controller, args)
    self:add(ctrl)

    local app = require("app.App"):instance()
    app.layers.ui:addChild(ctrl.view)
    ctrl.view:setPositionX(display.width)

    --TranslateView.moveCtrl(ctrl.view, -1)
    TranslateView.fadeIn(ctrl.view, -1)
    ctrl:on('back', function()
        TranslateView.fadeOut(ctrl.view, 1, function()
            ctrl:delete()
        end)
    end)
end

function LobbyController:getSelf()
     return self
end

function LobbyController:finalize()
  for i = 1, #self.listener do
        self.listener[i]:dispose()
    end
end

function LobbyController:clickMenuVisible()
     self:hideMenu()
end
function LobbyController:clickWelfare()
    setWidgetAction('WelfareController', self)
    self:hideMenu()
end

function LobbyController:clickShare()
    local app = require("app.App"):instance()
    local group = app.session.group
    group:test()
    setWidgetAction('ShareController', self)
    self:hideMenu()
end
function LobbyController:buyDiamonds()
    -- setWidgetAction('BuyDiamondsController', self)
    setWidgetAction('H5ShopController', self)
    self:hideMenu()
end

function LobbyController:clickSpread()
    setWidgetAction('SpreadController', self)
    self:hideMenu()
end

function LobbyController:clickHead()
    local app = require("app.App"):instance()
    local user = app.session.user
    
    setWidgetAction('PersonalPageController', self, user)
    self:hideMenu()
end

function LobbyController:clickMyRoom()
    setWidgetAction('MyRoomController', self)
     self:hideMenu()
end

function LobbyController:clickRecord()

    setWidgetAction('RecordController', self)
    self:hideMenu()
end

function LobbyController:clickMenu()
    SoundMng.playEft('btn_click.mp3')
    self.menuVisible=not self.menuVisible
    self.view:displayMenu(self.menuVisible)
end

function LobbyController:hideMenu()
    if self.menuVisible then
      self.menuVisible=not self.menuVisible
      self.view:displayMenu(self.menuVisible)
     else
     --SoundMng.playEft('btn_click.mp3')
    end
end

-- 点击进入牛牛
function LobbyController:clickEntryNN()
    setWidgetAction('CreateRoomController', self)
     self:hideMenu()
end

function LobbyController:clickEntryMJ()
    setWidgetAction('CreateRoomController', self, true)
     self:hideMenu()
end

function LobbyController:clickEnterRoom()
    setWidgetAction('EnterRoomController', self)
    self:hideMenu()
end

function LobbyController:clickGroup()
    setWidgetAction('GroupController', self)
    self:hideMenu()
end

function LobbyController:clickContact()
    setWidgetAction('ContactUsController', self)
    self:hideMenu()
end

function LobbyController:clickHelp()
    setWidgetAction('HelpController', self)
    self:hideMenu()
end

function LobbyController:clickRule()
    setWidgetAction('WanFaController', self)
    self:hideMenu()
end

function LobbyController:clickFeedback()
    setWidgetAction('FeedbackController', self)
    self:hideMenu()
end

function LobbyController:clickMessage()
    local group = app.session.group
    group:test1()
    setWidgetAction('MessageController', self)
    self:hideMenu()
end

function LobbyController:clickSetting()
    setWidgetAction('SettingController', self)
     self:hideMenu()
end

function LobbyController:inviteFriend(data)
    local invokefriend = require('app.helpers.invokefriend')
    local wfStr = self.wfName
    local gameplay = wfStr[data.options.gameplay]
    invokefriend.invoke(data, gameplay)
end

function LobbyController:clickExchange()
    setWidgetAction('ExchangeController', self)
end

function LobbyController:loadNotifyController()
  local ctrl = Controller:load('NotifyController')
  self:add(ctrl)
  local MainPanel = self.view.ui:getChildByName('MainPanel')
  local TopBar = MainPanel:getChildByName('TopBar')

  TopBar:getChildByName('notify'):getChildByName('node'):addChild(ctrl.view)
  self.notifyController = ctrl
end

function LobbyController:clickCoinRoom()
  tools.showRemind("金币场暂未开放")
end

function LobbyController:clickGem()
  SoundMng.playEft('common/audio_button_click.mp3')

  tools.showMsgBox("提示", "购买钻石请联系xxxx")
end

function LobbyController:clickGroup()
    setWidgetAction('GroupController', self)
    self:hideMenu()
end

function LobbyController:clickKefu()
  SoundMng.playEft('btn_click.mp3')
  local app = require("app.App"):instance()
  local ctrl = Controller:load('KefuController')
  self:add(ctrl)
  app.layers.ui:addChild(ctrl.view)
  ctrl:on('back',function()
    ctrl:delete()
  end)
end

function LobbyController:clickFriendRoomList()
    SoundMng.playEft('btn_click.mp3')
    self.view:freshRoomListView('friend')
    self.view:freshImageTitle('friend')
end

function LobbyController:clickGroupRoomList()
    SoundMng.playEft('btn_click.mp3')
    self.view:freshRoomListView('group')
    self.view:freshImageTitle('group')
end

function LobbyController:clickExit()
  SoundMng.playEft('btn_click.mp3')
  tools.showMsgBox("提示", "是否退出游戏?",2):next(function(btn)
    if btn == 'enter' then
        -- 关闭定时器
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
        if device.platform == 'ios' then
            local luaoc = nil
            luaoc = require('cocos.cocos2d.luaoc')
            if luaoc then
                luaoc.callStaticMethod("AppController", "clickExit",{ww='ADFZ88888'})
            end
        else
            cc.Director:getInstance():endToLua()
        end
    end
  end)
  self:hideMenu()
end

function LobbyController:share()
    local SocialShare = require('app.helpers.SocialShare')
    local share_url = 'http://www.zmdaj.com/'
    local image_url = 'https://mmbiz.qlogo.cn/mmbiz_png/cjGIMFD8QBib8ic7NZ91HaAk2tnY3At7tbBKibobsX1pJ8YLW5qqERicWSWLQcEaRDZLzcsDNGoezrp2ecPy22DpEw/0?wx_fmt=png'
    local text = '众人乐棋牌重磅推出正宗的曲靖小鸡麻将，随时随地想玩就玩，独乐乐不如众人乐，快分享给朋友吧！'
    SocialShare.share(1,function(platform,stCode,errorMsg)
    print('platform,stCode,errorMsg',platform,stCode,errorMsg)
    end,
    share_url,
    image_url,
    text,
    '众人乐棋牌')
end

-- function LobbyController:clickDownload()
--   self.view:clickDownload()
-- end

return LobbyController
