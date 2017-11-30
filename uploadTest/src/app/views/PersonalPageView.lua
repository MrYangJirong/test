local PersonalPageView = {}

function PersonalPageView:initialize()
end

function PersonalPageView:layout(data)
	local MainPanel = self.ui:getChildByName('MainPanel')
	MainPanel:setContentSize(cc.size(display.width,display.height))
	MainPanel:setPosition(display.cx,display.cy)

	--MainPanel:setScale(0)
	--MainPanel:setAnchorPoint(cc.p(0.5,0.5))
	MainPanel:setAnchorPoint(0.5,0.5)
	--MainPanel:setVisible(false)
	print("setPositionX:",display.cx)
	print("setPositionY:",display.cy)
    print("setContentSizeX:",display.width)
	print("setContentSizeY:",display.height)

	--MainPanel->runAction(ScaleTo::create(0.2,1.0));
	self.MainPanel = MainPanel

	local middle = MainPanel:getChildByName('middle')
	middle:setPosition(display.cx,display.cy)

	local name = middle:getChildByName('name')
	name:setString(data.nickName)

	local id = middle:getChildByName('id')
	id:setString( data.playerId)

	local ip = middle:getChildByName('ip')
	if data.ip then
		ip:setString(data.ip)
	end
    dump(data)

	local round=middle:getChildByName('round')

	round:setString('局：--')
	if data.win and data.lose then
		round:setString(data.win+data.lose)
	end

	local male = middle:getChildByName('img_nan')
	local femal = middle:getChildByName('img_nv')
	male:setVisible(false)
	femal:setVisible(false)
	if data.sex and data.sex == 1 then
		femal:setVisible(true)
	else
		male:setVisible(true)
	end

	local registerTime=middle:getChildByName('registerTime')
	registerTime:setString(os.date("%Y/%m/%d", data.secondsFrom1970))

	local cache = require('app.helpers.cache')
	local app = require("app.App"):instance()

	local avatar = middle:getChildByName('avatar')
	if data.avatar then
		avatar:retain()
		cache.get(data.avatar,function(ok,path)
		    if ok then
		      avatar:loadTexture(path)
		    end
		    avatar:release()
		end)
	end

	local userId = app.session.user.uid
	local kusoListPanel = middle:getChildByName('kusoListPanel')
	local kusoList = kusoListPanel:getChildByName('kusoList')
	local Panel_1 = middle:getChildByName('Panel_1')
	local bg = middle:getChildByName('bg')
	local bg1 = middle:getChildByName('bg1')
	bg:setVisible(false)
	bg1:setVisible(false)
	if userId ~= data.uid then
		bg:setVisible(true)
		kusoListPanel:setVisible(true)
		kusoList:setVisible(true)
		Panel_1:setVisible(true)

		kusoList:setItemModel(kusoList:getItem(0))
    	kusoList:removeAllItems()
		kusoList:setScrollBarEnabled(false)

		for i = 1, 8 do
			kusoList:pushBackDefaultItem()
			local item = kusoList:getItem(i-1)
			local img = item:getChildByName('img')
			img:loadTexture('views/xydesk/kuso/icon/'.. i .. '.png')
			-- img:setScale(2)
			item:addClickEventListener(function()
				local msg = { uid = data.uid, clickSender = data.clickSender, idx = i }
				self.emitter:emit('choosed', msg)
				self.emitter:emit('back')
			end)
		end
	else
		middle:setPosition(display.cx,display.cy-50)
		bg1:setVisible(true)
		kusoListPanel:setVisible(false)
		kusoList:setVisible(false)
		Panel_1:setVisible(false)
	end

end

return PersonalPageView
