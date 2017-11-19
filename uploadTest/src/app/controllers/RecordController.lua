local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local TranslateView = require('app.helpers.TranslateView')
local SoundMng = require "app.helpers.SoundMng"
local RecordController = class("RecordController", Controller):include(HasSignals)

function RecordController:initialize()
  Controller.initialize(self)
  HasSignals.initialize(self)
end

function RecordController:viewDidLoad()--
  local app = require("app.App"):instance()
  local record = app.session.record
  self.view:layout()
  --self.view:listRecords()
  self.listener = {
    record:on('listRecords',function(records)
      --dump(records)
      self.view:listRecords(records)
    end),

    self.view:on('shareRecord',function(result)
      --dump(records)
      self:setWidgetAction("XYSummaryController", result)
    end),
  }

  record:listRecords()
end


function RecordController:clickBack()
  self.emitter:emit('back')
end

function RecordController:clickShare()
	local CaptureScreen = require('app.helpers.capturescreen')
	local SocialShare = require('app.helpers.SocialShare')
	CaptureScreen.capture('record.jpg', function(ok, path)
		if ok then
			if device.platform == 'ios' then
				path = cc.FileUtils:getInstance():getWritablePath() .. path
			end
			
			SocialShare.share(1, function(stcode)
				print('stcode is ', stcode)
			end,
			nil,
			path,
			'我们在开心牛牛玩嗨了，快来加入我们',
			'开心牛牛', true)
		end
	end, self.view, 0.8)
end 

function RecordController:finalize()
  for i = 1,#self.listener do
    self.listener[i]:dispose()
  end
end

function RecordController:setWidgetAction(controller, args)
	--SoundMng.playEft('btn_click.mp3')
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

return RecordController
