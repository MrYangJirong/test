local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local ShareController = class('ShareController', Controller):include(HasSignals)

function ShareController:initialize()
	Controller.initialize(self)
  	HasSignals.initialize(self)
end

function ShareController:viewDidLoad()
	self.view:layout()
end

function ShareController:clickBack()
  self.emitter:emit('back')
end

function ShareController:setShare(flag)
	local SocialShare = require('app.helpers.SocialShare')

	local share_url = 'https://192.168.1.122/download'
	local image_url = 'http://192.168.1.122/icon2.png'

	SocialShare.share(flag, function(platform, stCode, errorMsg)
		print('platform, stCode, errorMsg', platform, stCode, errorMsg)
	end,
	share_url,
	image_url,
	'我在 俏游牛牛 玩嗨了，快来加入吧！',
	'俏游牛牛')
end

function ShareController:clickHaoYouQun()
	self:setShare(1)
end

function ShareController:clickPengYouQuan()
	self:setShare(2)
end

function ShareController:finalize()-- luacheck: ignore
end

return ShareController
