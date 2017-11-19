local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local ContactUsController = class("ContactUsController", Controller):include(HasSignals)

function ContactUsController:initialize()
  Controller.initialize(self)
  HasSignals.initialize(self)
end

function ContactUsController:viewDidLoad()
  local app = require("app.App"):instance()
  local user = app.session.user
  self.view:layout()

  
end

function ContactUsController:clickBack()
  self.emitter:emit('back')
end

function ContactUsController:finalize()-- luacheck: ignore
 
end

return ContactUsController
