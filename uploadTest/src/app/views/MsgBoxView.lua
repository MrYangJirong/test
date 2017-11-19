local MsgBoxView = {}
local winSize = cc.Director:getInstance():getWinSize()

function MsgBoxView:initialize()
  self.ui:setPosition(cc.p(winSize.width / 2,winSize.height / 2))

  local blackLayer = self.ui:getChildByName('blackLayer')
  blackLayer:setContentSize(winSize)
end

function MsgBoxView:layout(parms)
	local bg = self.ui:getChildByName('bg')
	local bgSize = bg:getContentSize()
	
	local title = bg:getChildByName('title')
	title:setString(parms.title)
	
	local content = bg:getChildByName('content')
	content:setString(parms.content)
	
	--if parms.isChangeContentColor==1 then
		--local text = string.sub(parms.content, 1,12)
    --local pos=cc.p(text:getPosition()) 
		--local label = cc.Label:createWithTTF(text, 'views/font/fangzheng.ttf', 30)
	--	label:setColor(cc.c3b(0, 0, 255))
		--label:setPosition(cc.p(500,300))
		--bg:addChild(label)
--	end
	
	if not parms.btnCount or parms.btnCount == 1 then
		local cancel = bg:getChildByName('cancel')
		cancel:setVisible(false)
		
		local enter = bg:getChildByName('enter')
		enter:setPositionX(bgSize.width / 2)
	end
end 

return MsgBoxView
