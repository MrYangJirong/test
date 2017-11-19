local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local H5ShopController = class("H5ShopController", Controller):include(HasSignals)
local tools = require('app.helpers.tools')
local app = require("app.App"):instance()
local SoundMng = require "app.helpers.SoundMng"

function H5ShopController:initialize()
	Controller.initialize(self)
	HasSignals.initialize(self)
end

function H5ShopController:viewDidLoad()
	self.view:layout()
	
	self.listener = {
		app.session.user:on('chargeResult',function(msg)
			self.view:freshResultInfo(msg)
		end)
	}

end

function H5ShopController:clickBack()
	SoundMng.playEft('btn_click.mp3')
	self.view:stopLoading()
	self.emitter:emit('back')
end

function H5ShopController:clickResult()
	SoundMng.playEft('btn_click.mp3')
	self.view:hideResultView()
end

function H5ShopController:clickWebLayer()
	SoundMng.playEft('btn_click.mp3')
	self.view:onClickWebLayer()
end

function H5ShopController:finalize()-- luacheck: ignore
	for i = 1,#self.listener do
    	self.listener[i]:dispose()
  	end
end

return H5ShopController
