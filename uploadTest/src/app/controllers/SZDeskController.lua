local class = require('middleclass')
local XYDeskController = require('app.controllers.XYDeskController')
local SZDeskController = class('SZDeskController', XYDeskController)
local SoundMng = require('app.helpers.SoundMng')
local app = require('app.App'):instance()
local tools = require('app.helpers.tools')

function SZDeskController:initialize(deskName)
    XYDeskController.initialize(self, deskName)
end

function SZDeskController:postAppendListens()
    self.listener[#self.listener + 1] = self.desk:on('dealtover', 
        function()
          
          local callback = function()
            -- local player = self.desk:getMe()
            -- local nn = self.desk:findNiuniu(player.mycards)
            -- if nn then
            --     app.conn:send({
            --         msgID = self.desk.DeskName .. '.choosed',
            --         cards = nn[1]
            --     })
            --   else
            --     self.desk:noNiuniu()
            -- end
            -- self:clickFanPai()
            self:timerFinish()
          end
          self:timerStart('checkCards', 8, callback)
        end)

    self.listener[#self.listener + 1] =
        self.desk:on('qzTimerStart', function()
            local callback = function()
                -- self:clickSQZNo()
                self:timerFinish()
            end
            self:timerStart('chooseQZ', 6, callback)
        end)
end

function SZDeskController:viewDidLoad()
    XYDeskController.viewDidLoad(self)
end

function SZDeskController:onQiangZhuang(msg)
    self.view:freshSQZBar(true)
end

function SZDeskController:clickShowCards()
    --self.view:cardsBackToOrigin()
    self.view:showResultTip()

    local msg = {
        msgID = self.deskName .. '.choosed'
    }
    app.conn:send(msg)
    self:timerFinish()
end

function SZDeskController:clickTips()
    self.view:showResultTip()
end

function SZDeskController:clickCuoPai()
    local player = self.desk.players[1]
    local mycards = player.mycards

    self.view:freshCuoPaiDisplay(true, mycards)
end

function SZDeskController:clickFanPai()
    local player = self.desk.players[1]
    local mycards = player.mycards

    self.view:freshCardsDisplay('bottom', mycards)
    self.view:freshOpBtns(false, true)
    self.view:freshCuoPaiDisplay(false, nil)

    SoundMng.playEft('poker_deal.mp3')
end

function SZDeskController:clickCloseCuoPai()
    self.view:freshCuoPaiDisplay(false, nil)
end

function SZDeskController:sendMsgQiang(num)
    local msg = {
        msgID = self.deskName .. '.qiang',
        number = num
    }
    app.conn:send(msg)
    self:timerFinish()
end

function SZDeskController:clickSQZYes()
    self.view:freshSQZBar(false)
    self:sendMsgQiang(1)
    self:timerFinish()
end

function SZDeskController:clickSQZNo()
    self.view:freshSQZBar(false)
    self:sendMsgQiang(0)
    self:timerFinish()
end

return SZDeskController
