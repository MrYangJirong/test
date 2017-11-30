local Scheduler = require('app.helpers.Scheduler')
local cache = require('app.helpers.cache')
local Controller = require('mvc.Controller')
local TranslateView = require('app.helpers.TranslateView')
local SoundMng = require "app.helpers.SoundMng"
local tools = require('app.helpers.tools')
local app = require('app.App'):instance()
local GameLogic = require('app.helpers.NNGameLogic')
local cache = require('app.helpers.cache')
local GroupView = {}

function GroupView:initialize(group)
	self:enableNodeEvents()
end

function GroupView:layout()
	local app = require("app.App"):instance()
	local group = app.session.group
	self.group = group

	self.ui:setPosition(display.cx,display.cy)
	local MainPanel = self.ui:getChildByName('MainPanel')
	local bg = MainPanel:getChildByName('bg')
	self.bg = bg

	-- 编辑框
    local editHanlder = function(event,editbox)
        self:onEditEvent(event,editbox)
    end

	local input = self.bg:getChildByName('left_bg'):getChildByName('createGroup'):getChildByName('input')
    local editBoxOrg = input:getChildByName('editBox')
    self.createEditbox = tools.createEditBox(editBoxOrg, {
		-- holder
		defaultString = '请输入群名',
		holderSize = 25,
		holderColor = cc.c3b(155,130,89),

		-- text
		fontColor = cc.c3b(138,94,31),
		size = 25,
		fontType = 'views/font/fangzheng.ttf',	
        inputMode = cc.EDITBOX_INPUT_MODE_SINGLELINE,
		maxCout = 8
    })

	local input = self.bg:getChildByName('left_bg'):getChildByName('joinGroup'):getChildByName('input')
    local joinEditBoxOrg = input:getChildByName('editBox')
    self.joinEditbox = tools.createEditBox(joinEditBoxOrg, {
		-- holder
		defaultString = '请输入群ID',
		holderSize = 25,
		holderColor = cc.c3b(155,130,89),

		-- text
		fontColor = cc.c3b(138,94,31),
		size = 25,
		fontType = 'views/font/fangzheng.ttf',	
        inputMode = cc.EDITBOX_INPUT_MODE_NUMERIC,
    })

	-- groupList
	local groupList = self.bg:getChildByName('left_bg'):getChildByName('groupList')
	self.groupList = groupList
	groupList:setItemModel(groupList:getItem(0))
	groupList:removeAllItems()
	groupList:setScrollBarEnabled(false)
	
	-- messageList
	local messageList = self.bg:getChildByName('filterLayer'):getChildByName('messageLayer'):getChildByName('messageHandle')
	self.messageList = messageList
	messageList:setItemModel(messageList:getItem(0))
	messageList:removeAllItems()
	messageList:setScrollBarEnabled(false)

	-- adminMemberList
	local adminMemberList = self.bg:getChildByName('filterLayer')
		:getChildByName('adminMemberLayer')
		:getChildByName('adminMember')
		:getChildByName('memberList')
	self.adminMemberList = adminMemberList
	adminMemberList:setItemModel(adminMemberList:getItem(0))
	adminMemberList:removeAllItems()
	adminMemberList:setScrollBarEnabled(false)

	-- normalMemberList
	local normalMemberList = self.bg:getChildByName('filterLayer')
		:getChildByName('normalMemberLayer')
		:getChildByName('normalMember')
		:getChildByName('memberList')
	self.normalMemberList = normalMemberList
	normalMemberList:setItemModel(normalMemberList:getItem(0))
	normalMemberList:removeAllItems()
	normalMemberList:setScrollBarEnabled(false)

	-- ROOMLIST
	local roomList = self.bg:getChildByName('roomList')
	self.roomList = roomList
	self.roomListRow1 = roomList:getItem(0)
	self.roomListRow2 = roomList:getItem(1)
	self.roomListRow1:retain()
	self.roomListRow2:retain()
	self.roomList:removeAllItems()
	self.roomList:setScrollBarEnabled(false)

	-- self.roomInfo = self.bg:getChildByName('roomInfo')

end

function GroupView:onExit()
	self.roomListRow1:release()
	self.roomListRow2:release()
end

function GroupView:freshListGroups(groups)
	dump(groups)

	-- 选中上一个
	local groupInfo = self.group:getCurGroup()
	local curGroupId
	if groupInfo then
		curGroupId = groupInfo.id 
	end

	local groupList = self.groupList
	groupList:removeAllItems()
	local index = 0
	for k, v in pairs(groups) do
		self.groupList:pushBackDefaultItem()
		local item = groupList:getItem(index)
		item:getChildByName('select'):hide()
		item:getChildByName('normal'):show()
		local headimg = item:getChildByName('txKuang'):getChildByName('avator') --头像     
		self:freshHeadImg(headimg, v.ownerInfo.avatar)

		local panel = item:getChildByName('groupName')
		local groupName = panel:getChildByName('value')
		groupName:setString(v.name)
		local positionX = groupName:getWorldPosition().x
		local panelSize = panel:getContentSize().width
		local groupNameSize = groupName:getAutoRenderSize().width
		local size = (groupNameSize >= panelSize) and panelSize or groupNameSize
		local memberNum = item:getChildByName('member_num')
		memberNum:setString('( '..v.memberCnt..' )')
		memberNum:setPositionX(positionX + size)

		local roomCnt = string.format("已开房间(%s)", v.roomCnt)
		item:getChildByName('room_num'):setString(roomCnt)

		local idx = index + 1
		item:getChildByName('touch'):addClickEventListener(function()			
			local groupId = v.id
			print("selectGroup", idx, groupId)
			self:freshGroupNameAndID(false)
			self:freshListGroupsSelect(idx)
			self.emitter:emit('selectGroup', groupId)
    	end)

		self:freshGroupInfoColor(item, false)
		if curGroupId and curGroupId == v.id then
			local groupName = v.name
			local groupId = v.id
			-- self:freshListGroupsSelect(index+1)
			self:freshGroupInfoColor(item, true)
			self:freshGroupNameAndID(true, groupName, groupId)
			self.emitter:emit('selectGroup', groupId)
		-- 默认选中第一个
		elseif (not curGroupId) and index==0 then
			local groupName = v.name
			local groupId = v.id
			-- self:freshListGroupsSelect(index+1)
			self:freshGroupInfoColor(item, true)
			self:freshGroupNameAndID(true, groupName, groupId)
			self.emitter:emit('selectGroup', groupId)
		end	
		index = index + 1	
	end
end

function GroupView:getGroupsCnt()
	local items = self.groupList:getItems()
	return items
end

function GroupView:freshHeadImg(headimg, headUrl)
	if headUrl == nil or headUrl == '' then return end		 
	cache.get(headUrl, function(ok, path)
		if ok then
			headimg:show()
			headimg:loadTexture(path)
		else
			headimg:loadTexture('views/public/tx.png')
		end
	end)
end

function GroupView:freshListGroupsSelect(index)
	local items = self.groupList:getItems()
	if items then
		for i, v in ipairs(items) do
			self:freshGroupInfoColor(v, i==index)
		end
	end
end

function GroupView:freshGroupInfoColor(node, bSelect)
	node:getChildByName('select'):setVisible(bSelect)
	node:getChildByName('normal'):setVisible(not bSelect)
	if bSelect then
		node:getChildByName('groupName'):getChildByName('value'):setColor(cc.c3b(175,99,13))
		node:getChildByName('room_num'):setColor(cc.c3b(175,99,13))
		node:getChildByName('member_num'):setColor(cc.c3b(175,99,13))			
	else
		node:getChildByName('groupName'):getChildByName('value'):setColor(cc.c3b(255,255,255))
		node:getChildByName('room_num'):setColor(cc.c3b(255,255,255))
		node:getChildByName('member_num'):setColor(cc.c3b(255,255,255))
	end 
end

function GroupView:freshGroupNameAndID(bShow, name, id)
	local gPanel = self.bg:getChildByName('gPanel')
	local groupName = gPanel:getChildByName('groupName')
	local groupID = self.bg:getChildByName('groupID')
	local pannelSize = gPanel:getContentSize()
	if bShow then
		groupName:setString(name)
		local positionX = groupName:getWorldPosition().x
		local gSize = groupName:getAutoRenderSize()
		local size = (gSize.width >= pannelSize.width) and pannelSize or gSize		
		groupID:setString('(ID:'..id..')')
		groupID:setPositionX(positionX + size.width)
	end
	groupName:setVisible(bShow)
	groupID:setVisible(bShow)
end

-- 管理员消息按钮
function GroupView:freshAdminMsg(bShow, msgCnt)
	msgCnt = msgCnt or 0
	self.bg:getChildByName('messageBtn'):setVisible(bShow)
	self.bg:getChildByName('messageBtn')
		:getChildByName('newMessage')
		:setVisible(msgCnt>0)
end
--设置按钮
function GroupView:freshSettingBtn(bShow)
	self.bg:getChildByName('settingBtn'):setVisible(bShow)
end
--成员按钮
function GroupView:freshMemberBtn(bShow)
	self.bg:getChildByName('memberBtn'):setVisible(bShow)
end

--没房间提示
function GroupView:freshNoRoomTips(bShow)
	self.bg:getChildByName('noRoomTips'):setVisible(bShow)
end

function GroupView:freshCreateRoomBtn(bShow)
	self.bg:getChildByName('createRoomBtn'):setVisible(bShow)
end

--消息处理界面
function GroupView:freshMessageLayer(bShow) 
	local filterLayer = self.bg:getChildByName('filterLayer'):setVisible(bShow) 
	local messageLayer = filterLayer:getChildByName('messageLayer'):setVisible(bShow) 
	local messageHandle = messageLayer:getChildByName('messageHandle'):setVisible(bShow)
end

--设置界面 
function GroupView:freshAdminSettingLayer(bShow)	
	--admin设置
	local filterLayer = self.bg:getChildByName('filterLayer'):setVisible(bShow) 
	local adminSettingLayer = filterLayer:getChildByName('adminSettingLayer'):setVisible(bShow) 
	local adminSetting = adminSettingLayer:getChildByName('adminSetting'):setVisible(bShow)		
	local alterNameBtn = adminSetting:getChildByName('alterName')
	alterNameBtn:addClickEventListener(function()
		self.emitter:emit('settingOperateModify')
	end)
	local dismissBtn = adminSetting:getChildByName('dismiss')
	dismissBtn:addClickEventListener(function()
		self.emitter:emit('settingOperateDismiss')
	end)	
end

function GroupView:freshNormalSettingLayer(bShow)	
	--普通设置
	local filterLayer = self.bg:getChildByName('filterLayer'):setVisible(bShow) 
	local normalSettingLayer = filterLayer:getChildByName('normalSettingLayer'):setVisible(bShow) 
	local normalSetting = normalSettingLayer:getChildByName('normalSetting'):setVisible(bShow)	
	local exitBtn = normalSetting:getChildByName('exitBtn')	
end

function GroupView:freshAdminMemberLayer(bShow)	
	local filterLayer = self.bg:getChildByName('filterLayer'):setVisible(bShow) 
	local adminMemberLayer = filterLayer:getChildByName('adminMemberLayer'):setVisible(bShow) 
	local adminMember = adminMemberLayer:getChildByName('adminMember'):setVisible(bShow)
	local delMember = adminMember:getChildByName('delMember')
	local delBtn = delMember:getChildByName('delBtn')		
end

-- setting : rule.special
local function getSpecialStr(setting, mode)
	-- 特殊牌
	local tabRule = {
		WUXIAO = "五小牛",
		BOOM = "炸弹牛",
		HULU = "葫芦牛",
		WUHUA_J = "五花牛 ",
		TONGHUA = "同花牛",
		STRAIGHT = "顺子牛",
	}

	local tabRule1 = {
        WUXIAO = "五小牛(8倍) ",
        BOOM = "炸弹牛(7倍) ",
        HULU = "葫芦牛(6倍) ",
        WUHUA_J = "五花牛(5倍) ",
        TONGHUA = "同花牛(5倍) ",
        STRAIGHT = "顺子牛(5倍) ",
	}

	local ruleText = ""
	local addCnt = 0
	for i, v in pairs(setting) do 
		if v > 0 then
			local spName = GameLogic.getSetting(i)
			if spName then
				if mode == 'roomInfo' then
					addCnt = addCnt + 1
					local r = addCnt == 3 and "\r\n" or ""
					ruleText = ruleText .. tabRule1[spName] .. r
				else
					ruleText = ruleText .. tabRule[spName] .. " "
				end
			end
		end
	end
	return ruleText
end
--[[ 
function GroupView:freshRoomInfo(bShow, rule)
	if not bShow then
		self.roomInfo:setVisible(false)
		return
	end

	-- 玩法
	local tabWanFa = { '牛牛上庄', '固定庄家', '自由抢庄', '明牌抢庄', '通比牛牛' }
	self.roomInfo:getChildByName('wanfa'):setString(tabWanFa[rule.gameplay])

	-- 底分
	self.roomInfo:getChildByName('difen'):setString(rule.base)

	-- 翻倍
	local beiRuleString
	if rule.multiply == 1 then
		beiRuleString = "牛牛x4 牛九x3 牛八x2 牛七x2"
	else
		beiRuleString = "牛牛x3 牛九x2 牛八x2"
	end
	self.roomInfo:getChildByName('beiRule'):setString(beiRuleString)

	-- 房间规则
	local advancedString = ""
	local tabStr = {'闲家推注 ', '游戏开始后禁止加入 ', '禁止搓牌 '}
	for k,v in pairs(rule.advanced) do
		if v > 0 then 
			advancedString = advancedString .. tabStr[k]
		end
	end
	self.roomInfo:getChildByName('roomRule'):setString(advancedString)

	-- 特殊玩法
	local spStr = getSpecialStr(rule.special, 'roomInfo')
	self.roomInfo:getChildByName('Twanfa'):setString(spStr)

	self.roomInfo:setVisible(true)
end
 ]]

function GroupView:freshRoomList(roomList, myPlayerId)
	self.roomList:removeAllItems()		

	local function addRow(roomId, idx, isOwner, data)
		if isOwner then 
			self.roomList:setItemModel(self.roomListRow1)
		else
			self.roomList:setItemModel(self.roomListRow2)
		end
		self.roomList:pushBackDefaultItem()	-- self
		local item = self.roomList:getItem(idx)		
		local userId = item:getChildByName('userID'):setVisible(false)
		local userName = item:getChildByName('userName'):setVisible(false)
		userName:setString(''..data.ownerInfo.nickname)
		local positionX = userName:getPositionX()
		local size = userName:getAutoRenderSize()
		userId:setString('(ID:'..data.ownerPlayerId..')')
		userId:setPositionX(positionX + size.width + 3)

		local headimg = item:getChildByName('txKuang'):getChildByName('avator')
		self:freshHeadImg(headimg, data.ownerInfo.avatar)


		item:getChildByName('roomID'):getChildByName('value'):setString(''..roomId)	
		item:getChildByName('renShu'):getChildByName('value'):setString(data.playerCnt..'/6')	
		-- 玩法
		local tabWanFa = { '牛牛上庄', '固定庄家', '自由抢庄', '明牌抢庄', '通比牛牛', '', '疯狂加倍' }
		item:getChildByName('wanFa'):setString(tabWanFa[data.rule.gameplay])
		-- 游戏状态

		-- 详情
		item:getChildByName('detail'):getChildByName('difen'):setString(data.rule.base)
		item:getChildByName('detail'):getChildByName('jushu'):setString(data.rule.round)
		local payMode = 'AA支付'
		if data.rule.roomPrice == 1 then payMode = '房主支付' end
		item:getChildByName('detail'):getChildByName('zhifu'):setString(payMode)
		local mulStr = data.rule.multiply == 1 and '牛牛x4' or '牛牛x3'
		item:getChildByName('detail'):getChildByName('rule'):setString(mulStr)
		-- 高级选项
		local advancedInfo = item:getChildByName('detail'):getChildByName('gou2')
		local content = ''
		for k, v in pairs(data.rule.advanced) do
			if k == 2 and v > 0 then
				content = '游戏开始后禁止加入'				
			end
			if k == 3 and v > 0 then
				content = content..' 禁止搓牌'
			end
		end		
		if data.rule.putmoney == 2 then
			content = content..' 闲家推注5倍'				
		end
		if data.rule.putmoney == 3 then
			content = content..' 闲家推注10倍'
		end
		if data.rule.putmoney == 4 then
			content = content..' 闲家推注15倍'
		end
		content = (content=='') and '无闲家推注' or content
		advancedInfo:getChildByName('text2'):setString(content)

		local ruleInfo = item:getChildByName('detail'):getChildByName('gou1'):getChildByName('text1')
		local ruleText = getSpecialStr(data.rule.special, 'roomlist')
		if ruleText == '' then 
			ruleInfo:setString('无特殊牌型')
		else
			ruleInfo:setString(ruleText)
		end		

		-- 最大抢庄
		local qMax = item:getChildByName('detail'):getChildByName('qMax')
		if data.rule.qzMax then
			qMax:setString('最大抢庄'..data.rule.qzMax..'倍')
		end

		-- 房间详情
		-- local infoBtn = item:getChildByName('descriptionBtn')
		-- infoBtn:addClickEventListener(function()
		-- 	self:freshRoomInfo(true, data.rule)
		-- end)

		-- touch事件
		local touch = item:getChildByName('touch')
		touch:addClickEventListener(function()
			self.emitter:emit('touchRoomItem', roomId)
		end)

	end

	local idx = 0
	for roomId, data in pairs(roomList) do
		addRow(roomId, idx, myPlayerId == data.ownerPlayerId, data)
		idx = idx + 1
	end

end

function GroupView:freshMemberList(memberInfo, adminInfo)

	local function addRow(node, idx, name, playerId, bMgr, headUrl)
		node:pushBackDefaultItem()
		local item = node:getItem(idx)
		-- 头像
		local headimg = item:getChildByName('txKuang'):getChildByName('avator')
		self:freshHeadImg(headimg, headUrl)
		-- 管理图标
		item:getChildByName('manager'):setVisible(bMgr)
		-- 名字
		item:getChildByName('userName'):setString(tostring(name))
		-- playerId
		item:getChildByName('userID'):setString(tostring(playerId))
		-- 按钮
		local btn = item:getChildByName('sureDelete')
		if btn then
			btn:setVisible(false)
			btn:addClickEventListener(function()
				self.emitter:emit('memberListDelMember', playerId)
    		end)
		end
	end

	self.adminMemberList:removeAllItems()
	self.normalMemberList:removeAllItems()
	if table.nums(memberInfo) == 0 then return end

	local tabM = clone(memberInfo)
	table.sort( tabM, function(a, b)
		if a.playerId == adminInfo.playerId then
			return true
		end
	end)
	
	local listIdx = 0
	for i,v in pairs(tabM) do
		local bMgr = (v.playerId == adminInfo.playerId)
		addRow(self.adminMemberList, listIdx, v.nickname, v.playerId, bMgr, v.avatar)
		addRow(self.normalMemberList, listIdx, v.nickname, v.playerId, bMgr, v.avatar)
		listIdx = listIdx + 1
	end
end

function GroupView:freshAdminMemberListDelBtn(bShow, toggle)
	local items = self.adminMemberList:getItems()
	if items then
		for i, v in ipairs(items) do
			local btn = v:getChildByName('sureDelete')
			local visible = btn:isVisible()
			local mgr = v:getChildByName('manager'):isVisible()
			if toggle then
				btn:setVisible(not visible)
			else
				btn:setVisible(bShow)
			end
			if mgr then btn:setVisible(false) end
		end
	end
end

function GroupView:freshNormalMemberLayer(bShow)	
	local filterLayer = self.bg:getChildByName('filterLayer'):setVisible(bShow) 
	local normalMemberLayer = filterLayer:getChildByName('normalMemberLayer'):setVisible(bShow) 
	local normalMember = normalMemberLayer:getChildByName('normalMember'):setVisible(bShow)	
end

function GroupView:freshModifyGroupName(bShow, curName)	
	local modifyGroupName = self.bg:getChildByName('dialogs'):getChildByName('modifyGroupName'):setVisible(bShow) 
	local curGroupName = modifyGroupName:getChildByName('input'):getChildByName('editBox')
	if curName and curGroupName then
		curGroupName = tools.createEditBox(curGroupName, {
			-- holder
			defaultString = curName,
			holderSize = 30,
			holderColor = cc.c3b(155,130,89),

			-- text
			fontColor = cc.c3b(138,94,31),
			size = 30,
			fontType = 'views/font/fangzheng.ttf',	
			inputMode = cc.EDITBOX_INPUT_MODE_SINGLELINE,
			maxCout = 8
		})
		self.modifyGroupEditBox = curGroupName
	end		
end

function GroupView:freshDismissGroup(bShow, groupName)	
	local modifyGroupName = self.bg:getChildByName('dialogs'):getChildByName('dismissGroup'):setVisible(bShow) 
	local tipsContent = modifyGroupName:getChildByName('content')
	if groupName then 
		local content = '确认解散群"'..groupName..'"?解散后无法恢复'
		tipsContent:setString(content) 
	end
end

function GroupView:freshQuitGroup(bShow, groupName)	
	local quitGroupName = self.bg:getChildByName('dialogs'):getChildByName('quitGroup'):setVisible(bShow) 
	local tipsContent = quitGroupName:getChildByName('content')
	if groupName then 
		local content = '确认退出群"'..groupName..'"?'
		tipsContent:setString(content) 
	end
end

--[[ function GroupView:freshCreateGroupResult(bShow)	
	self.bg:getChildByName('dialogs'):getChildByName('createGroupResult'):setVisible(bShow) 
end ]]

--消息列表
function GroupView:freshMessageList(msg)
	local messageLayer = self.bg:getChildByName('filterLayer'):getChildByName('messageLayer')
	local messageHandle = messageLayer:getChildByName('messageHandle')
	local noRoomTips = messageLayer:getChildByName('tips')
	local cnt = 0
	for k, v in pairs(msg) do
		cnt = cnt + 1
	end
	if cnt==0 then
		noRoomTips:setVisible(true)
		messageHandle:setVisible(false)
		return
	else
		noRoomTips:setVisible(false)
		messageHandle:setVisible(true)		
	end

	local messageList = self.messageList
	messageList:removeAllItems()
	for i, v in pairs(msg) do
		self.messageList:pushBackDefaultItem()
		-- local item = messageList:getItem(i - 1)
		local item = messageHandle:getChildByName('messageItem')
		local headimg = item:getChildByName('txKuang'):getChildByName('avator')
		self:freshHeadImg(headimg, v.userInfo.avatar)	
		local playerId = v.userInfo.playerId
		item:getChildByName('userID')
		item:getChildByName('userName'):setString(v.userInfo.nickname)

		item:getChildByName('shield'):addClickEventListener(function()
			self.emitter:emit('messageListOperate', {playerId, "block"})
    	end)
		item:getChildByName('refuse'):addClickEventListener(function()
			self.emitter:emit('messageListOperate', {playerId, "reject"})
    	end)
		item:getChildByName('agree'):addClickEventListener(function()
			self.emitter:emit('messageListOperate', {playerId, "accept"})
    	end)			
	end	

	
end

--刷新admin成员列表
-- function GroupView:adminMemberList(memberInfo)
-- 	local adminMemberList = self.adminMemberList
-- 	adminMemberList:removeAllItems()
-- 	for i, v in pairs(memberInfo) do
-- 		self.adminMemberList:pushBackDefaultItem()
-- 		local item = adminMemberList:getItem(i - 1)	
-- 		-- local playerId = 
-- 		-- local nickname =
-- 		item:getChildByName('userID')
-- 		item:getChildByName('userName'):setString(nickname)		
-- 	end		
-- end

function GroupView:freshAddLayer(bShow) 
	local filterLayer = self.bg:getChildByName('filterLayer'):setVisible(bShow) 
	local addLayer = filterLayer:getChildByName('addLayer'):setVisible(bShow) 
	local addDetail = addLayer:getChildByName('addDetail'):setVisible(bShow)
end

-- 显示&隐藏创建牛友群界面
function GroupView:freshGroupCreateLayer(bShow) 
	self.bg:getChildByName('left_bg'):getChildByName('createGroup'):setVisible(bShow) 
end

function GroupView:freshGroupJoinLayer(bShow) 
	local left_bg = self.bg:getChildByName('left_bg'):getChildByName('joinGroup'):setVisible(bShow) 
	if bShow then
		self:freshBtnState(true)
		self:freshQueryResult(false)
	end
end

function GroupView:getModifyEditBoxInfo() 
    local text = self.modifyGroupEditBox:getText()
    return text 	
end

function GroupView:getCreateEditBoxInfo() 
    local text = self.createEditbox:getText()
    return text 	
end

function GroupView:freshCreateEditBox(content, enable)
    enable = enable or false
    self.createEditbox:setText(content)
    self.createEditbox:setEnabled(enable)
end

function GroupView:getJoinEditBoxInfo() 
    local text = self.joinEditbox:getText()
	local num = tonumber(text)
    return num 	
end

function GroupView:freshJoinEditBox(content, enable)
    enable = enable or false
    self.joinEditbox:setText(content)
    self.joinEditbox:setEnabled(enable)
end

function GroupView:freshGroupListVisible(bShow)
	self.groupList:setVisible(bShow)
end

function GroupView:getCurSelectedGroup()
	return self.groupList:getCurSelectedIndex()
end

function GroupView:freshQueryResult(bShow, groupName, adminName, avatar)
	local input = self.bg:getChildByName('left_bg')
		:getChildByName('joinGroup')
		:getChildByName('queryResult')

	if not bShow then 
		input:setVisible(false)
		return
	end
	local headimg = input:getChildByName('txKuang'):getChildByName('avator')
	self:freshHeadImg(headimg, avatar)	
	local gName = input:getChildByName('groupName')
	gName:setString(groupName)
	local aName = input:getChildByName('adminName')
	aName:setString(adminName)
	input:setVisible(bShow)
end

function GroupView:freshBtnState(bShow)
	local sureBtn = self.bg:getChildByName('left_bg')
		:getChildByName('joinGroup')
		:getChildByName('sureBtn')
		:setVisible(bShow)

	local input = self.bg:getChildByName('left_bg')
		:getChildByName('joinGroup')
		:getChildByName('backBtn')
		:setVisible(bShow)		
end

return GroupView
