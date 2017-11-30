local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local TranslateView = require('app.helpers.TranslateView')
local XYChatController = class("XYChatController", Controller):include(HasSignals)

local app = require("app.App"):instance()

function XYChatController:initialize()
    Controller.initialize(self)
    HasSignals.initialize(self)
end

function XYChatController:viewDidLoad()
    self.view:layout()
    self.view:on("choosed", function(i)
        self.emitter:emit('back')

        local tmsg = {
            msgID = 'chatInGame',
            type = 0,
            msg = i
        }
        app.conn:send(tmsg)
    end)

    self.view:on("back", function()
        TranslateView.moveCtrl(self.view, 1, function()
            self:delete()
        end)
    end)
end

function XYChatController:clickSend()
    local text = self.view:getSendText()
    if #text == 0 then
        return
    end

    local tmsg = {
        msgID = 'chatInGame',
        type = 2,
        msg = text
    }
    app.conn:send(tmsg)

    self:clickBack()
end

function XYChatController:clickBack()
    self.emitter:emit('back')
end

function XYChatController:sendText()
end

function XYChatController:finalize()-- luacheck: ignore
end

return XYChatController
