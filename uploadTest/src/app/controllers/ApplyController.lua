local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local ApplyController = class("ApplyController", Controller):include(HasSignals)

function ApplyController:initialize(ctrl)
  Controller.initialize(self)
  HasSignals.initialize(self)

  self.ctrl = ctrl
end

function ApplyController:viewDidLoad()
  self.view:layout()

  self.view:on('apply',function(type)
    self:apply(type)
  end)

  local app = require("app.App"):instance()
  self.listener = {
    app.session.room:on('somebodyapply',function()
      self:fresh()
    end)
  }

  self:fresh()
end

function ApplyController:apply(type)
  local answer = 2
  if type == 'agree' then
    answer = 1
  end

  local desk = self.ctrl.desk
  desk:answer(answer)
end

function ApplyController:fresh()
  self.view:loadData(self.ctrl.desk)
  -- 有一人拒绝解散就继续游戏
  for uid, status in pairs(self.ctrl.desk.info.apply.result) do
    if status ~= 0 and status ~= 1 then
      self:clickBack()
    end
  end
end

function ApplyController:clickBack()
  self.emitter:emit('back')

end

function ApplyController:finalize()-- luacheck: ignore
end

return ApplyController
