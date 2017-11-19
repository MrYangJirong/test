local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local GameSettingController = class("GameSettingController", Controller):include(HasSignals)
local SoundMng = require('app.helpers.SoundMng')

function GameSettingController:initialize()
  Controller.initialize(self)
  HasSignals.initialize(self)
end

function GameSettingController:viewDidLoad()
  self.view:layout()
  self.view:changeMusic(SoundMng.getEftFlag(SoundMng.type[1]))
  self.view:changeSound(SoundMng.getEftFlag(SoundMng.type[2]))
end

function GameSettingController:clickBack()
  SoundMng.playEft('btn_click.mp3')
  self.emitter:emit('back')
end

function GameSettingController:clickChange()
  SoundMng.playEft('btn_click.mp3')
  self.emitter:emit('loginSuccess')
end

function GameSettingController:clickSound()
	local b = not SoundMng.getEftFlag(SoundMng.type[2])
	
	SoundMng.setEftFlag(b)
	self.view:changeSound(b)
end

function GameSettingController:clickMusic()
	local b = not SoundMng.getEftFlag(SoundMng.type[1])
	
	SoundMng.setBgmFlag(b)
	self.view:changeMusic(b)
end 



function GameSettingController:finalize()-- luacheck: ignore
end

function GameSettingController:clickButton()
  SoundMng.playEft('btn_click.mp3')
  self.emitter:emit('clickBtn')
end

function GameSettingController:clickHide()
  SoundMng.playEft('btn_click.mp3')
  self.emitter:emit('back')
end

function GameSettingController:clickChange()
  SoundMng.playEft('btn_click.mp3')
  if device.platform == 'android' or device.platform == 'ios' then
    local social_umeng = require('social')
    social_umeng.deauthorize('wechat', function()end)
  end

  local app = require("app.App"):instance()
  app.localSettings:set('uid', nil)
  app.session.net:setHookClose(function()
    app.session.net:setHookClose(nil)
    app:switch('LoginController')
  end)
  app.conn:close()
end

function GameSettingController:clickConfirm()
  self:delete()
end

return GameSettingController
