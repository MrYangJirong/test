local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local CreateRoomController = class("CreateRoomController", Controller):include(HasSignals)

function CreateRoomController:initialize(groupInfo)
    Controller.initialize(self)
    HasSignals.initialize(self)
    self.groupInfo = groupInfo -- group -> self.listGroupInfo element
    
end

function CreateRoomController:viewDidLoad()
    local app = require("app.App"):instance()
    self.view:layout()
    self.listener = {
    app.session.room:on('createRoom', function(msg)
            local tools = require "app.helpers.tools"
            tools.showRemind("创建房间成功，请到我的房间列表查看～")
            self.emitter:emit('back')
        end)
    }
end

function CreateRoomController:finalize()-- luacheck: ignore
    for i = 1, #self.listener do
        self.listener[i]:dispose()
    end
end

function CreateRoomController:clickCreate()
    local app = require("app.App"):instance()
    local options = self.view:getOptions()

    local gameIdx
    local gameplay = options.gameplay
    if gameplay == 4 or gameplay == 7 then
        gameIdx = app.session.niumowangqz.gameIdx
    else
        gameIdx = app.session.niumowang.gameIdx
    end
    app.session.room:createRoom(gameIdx, options, self.groupInfo)
end

function CreateRoomController:clickBack()
    self.emitter:emit('back')
end

function CreateRoomController:clickNotOpen()
    local tools = require('app.helpers.tools')
    tools.showRemind('暂未开放，敬请期待')
end

return CreateRoomController
