local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local PersonalPageController = class('PersonalPageController', Controller):include(HasSignals)

function PersonalPageController:initialize(data)
	Controller.initialize(self)
  	HasSignals.initialize(self)
      
    self.data = data
end

function PersonalPageController:viewDidLoad()
		self.view:layout(self.data)

		local app = require('app.App'):instance()
		self.view:on("choosed", function(msg)
        self.emitter:emit('back')

        local tmsg = {
            msgID = 'chatInGame',
            type = 3,
            msg = msg
        }
        app.conn:send(tmsg)
    end)
end

function PersonalPageController:clickBack()
  	self.emitter:emit('back')
end

function PersonalPageController:finalize()-- luacheck: ignore
end

return PersonalPageController
