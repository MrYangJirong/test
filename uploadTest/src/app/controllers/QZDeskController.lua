local class = require('middleclass')
local XYDeskController = require('app.controllers.XYDeskController')
local QZDeskController = class('QZDeskController', XYDeskController)
local transition = require('cocos.framework.transition')
local Scheduler = require('app.helpers.Scheduler')
local SoundMng = require('app.helpers.SoundMng')
local tools = require('app.helpers.tools')
local app = require('app.App'):instance()

function QZDeskController:initialize(deskName)
    XYDeskController.initialize(self, deskName)
end

function QZDeskController:postAppendListens()
    self.listener[#self.listener + 1] =
      self.desk:on('qzTimerStart', function()
          local callback = function()
            --   self.view:freshQZBar(false)
            --   self:sendMsgQiang(0)
            self:timerFinish()
          end
          self:timerStart('chooseQZ', 6, callback)
      end)

    self.listener[#self.listener + 1] =
      self.desk:on('somebodyQiang', function(msg)
            self.view:playEftQz(msg.number, msg.uid)
            local name = self.desk:getPlayerPosKey(msg.uid)
            if name == "bottom" then
                self.view:freshQZBar(false)
            end
            -- 显示抢庄
            self.view:freshQZBet(name, msg.number, true)
      end)

    self.listener[#self.listener + 1] =
    self.desk:on('putOver', function()
        local players = self.desk.players
        
        for i, v in pairs(players) do
            local actor = v.actor
            if actor.isPrepare and actor.isPrepare == true then
                local name = self.desk:getPlayerPosKey(actor.uid)
                self:onDealtCardsFive(name, 5, 5)
                
                self:onDelayAction(0.8, function()
                    if name == 'bottom' then
                        self.view:freshOpBtns(true, false)
                        self.view:freshStateViews()
                        self.emitter:emit('chooseTimerStart')
                    else
                        self.view:dispalyCuoPai(name)
                    end
                end)
            end
        end
    end) 

    self.listener[#self.listener + 1] =
      self.view:on('cpBack', function(msg)
          self:clickCloseCuoPai()
      end)

    self.listener[#self.listener + 1] =
      self:on('showLastCard', function(msg)
          local player = self.desk.players[1]
          local mycards = player.mycards

          self.view:freshCuoPaiDisplay(false, nil)
          self.view:setPlayerCardsDisplay('bottom', 'front', 5, 5, mycards)
          self.view:freshOpBtns(false, true)
      end)

    self.listener[#self.listener + 1] =
      self:on('chooseTimerStart', function()
          local callback = function()
            --   local player = self.desk:getMe()
            --   local nn = self.desk:findNiuniu(player.mycards)

            --   if nn then
            --       app.conn:send({
            --           msgID = self.desk.DeskName .. '.choosed',
            --           cards = nn[1]
            --       })
            --   else
            --       self.desk:noNiuniu()
            --   end
            --   self.emitter:emit('showLastCard')
            self:timerFinish()
          end
          self:timerStart('checkCards', 8, callback)
      end)
end

function QZDeskController:viewDidLoad()
    XYDeskController.viewDidLoad(self)
end

function QZDeskController:sendMsgQiang(num)
    local msg = {
        msgID = self.deskName .. '.qiang',
        number = num
    }
    app.conn:send(msg)
end

function QZDeskController:onNewBanker(msg)
    local name = self.desk:getPlayerPosKey(msg.uid)
    print(name, '<- new banker *************************************')
    self.view:freshBankerState(name, true, msg)
    self.view:hideQZBet()
    -- self.view:freshQZNum(name, msg.number, true)
end

function QZDeskController:onQiangZhuang(msg)
    local qzMax = self.desk.info.deskInfo.qzMax
    self.view:freshQZBar(true, qzMax)
end

function QZDeskController:onDealt(msg)
    self:onDealtCardsOneToFour('bottom', 1, 4, true)
    self.others = msg.others

    for _, v in ipairs(msg.others) do
        local name = self.desk:getPlayerPosKey(v)
        self:onDealtCardsOneToFour(name, 1, 4, true)
    end
    SoundMng.playEft('poker_deal.mp3')
end

function QZDeskController:onStart(msg)
    self.view:freshInviteFriend(false)
    local arr = msg.arrUid
    for _, v in ipairs(arr) do
        local name = self.desk:getPlayerPosKey(v)
        self.view:clearDesk(name)
        self.view:freshReadyState(name, false)
        self.view:freshQZNum(name, 0, false)

        if name == 'bottom' then
            self.view:setPlayerCardsDisplay(name, 'back', 1, 5)
        end
    end

    self.view:freshRoomInfo(self.desk.info, true)
end

function QZDeskController:clickQZBettingOne()
    self.view:freshQZBar(false)
    self:sendMsgQiang(1)
    self:timerFinish()
end

function QZDeskController:clickQZBettingDouble()
    self.view:freshQZBar(false)
    self:sendMsgQiang(2)
    self:timerFinish()
end

function QZDeskController:clickQZBettingTriple()
    self.view:freshQZBar(false)
    self:sendMsgQiang(3)
    self:timerFinish()
end

function QZDeskController:clickQZBettingFour()
    self.view:freshQZBar(false)
    self:sendMsgQiang(4)
    self:timerFinish()
end

function QZDeskController:clickQZBettingZero()
    self.view:freshQZBar(false)
    self:sendMsgQiang(0)
    self:timerFinish()
end

function QZDeskController:onDealtCardsOneToFour(name, head, tail)
    if name == 'bottom' then
        local mycards = self.desk.players[1].mycards
        self.view:setPlayerCardsDisplay(name, 'front', head, tail, mycards)
    end
    self.view:setCardsVisible(name, false)
    self.view:showCardsAction(name, head, tail, true)
end

function QZDeskController:onDealtCardsFive(name, head, tail)
    self.view:showCardsAction(name, head, tail, true)
    -- 显示搓牌中动画
    -- if self.others then
    --     for _, v in ipairs(self.others) do
    --         local name = self.desk:getPlayerPosKey(v)
    --         self.view:dispalyCuoPai(name)
    --     end
    -- end
end

function QZDeskController:onDelayAction(time, callback)
    local delay = cc.DelayTime:create(time)
    local Sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    self.view:runAction(Sequence)
end

function QZDeskController:clickShowCards()
    --self.view:cardsBackToOrigin()
    self.view:showResultTip()

    self:timerFinish()

    local msg = {
        msgID = self.deskName .. '.choosed'
    }
    app.conn:send(msg)
end

function QZDeskController:clickTips()
    self.view:showResultTip()
end

function QZDeskController:clickCuoPai()
    local player = self.desk.players[1]
    local mycards = player.mycards

    self.view:freshCuoPaiDisplay(true, mycards)
end

function QZDeskController:clickFanPai()
    local player = self.desk.players[1]
    local mycards = player.mycards

    self.view:setPlayerCardsDisplay('bottom', 'front', 5, 5, mycards)
    self.view:freshOpBtns(false, true)

    SoundMng.playEft('poker_deal.mp3')
    -- 搓牌时点击翻牌要把搓牌Layer关闭
    self.view:freshCuoPaiDisplay(false)
end

function QZDeskController:clickCloseCuoPai()
    self.view:freshCuoPaiDisplay(false, nil)

    self.emitter:emit('showLastCard')
end

return QZDeskController
