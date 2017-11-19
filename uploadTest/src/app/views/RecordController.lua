local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local RecordController = class("RecordController", Controller):include(HasSignals)

function RecordController:initialize()
  Controller.initialize(self)
  HasSignals.initialize(self)
end

function RecordController:viewDidLoad()
  local app = require("app.App"):instance()
  local record = app.session.record
  self.view:layout()

  self.listener = {
    record:on('listRecords',function(records)
      -- dump(records)
      self.view:listRecords(records)
    end),
  }

  record:listRecords()
end

function RecordController:clickBack()
  self.emitter:emit('back')
end


function RecordController:finalize()
  for i = 1,#self.listener do
    self.listener[i]:dispose()
  end
end

return RecordController
