local class = require('middleclass')
local HasSignals = require('HasSignals')
local Group = class('Group'):include(HasSignals)


function Group:initialize()
	HasSignals.initialize(self)
	local app = require("app.App"):instance()

	self.listGroupInfo = {}	-- k:groupId v: packageInfo()
	self.listAdminMsg = {}	-- k:groupId v: packageAdminMsg()
	self.listGroupMemberInfo = {} -- k:groupId v: packageMemberInfo()
	self.listGroupRoom = {} -- k:groupId v:{k:deskId  v:{ ownerPlayerId = int, playerCnt = int, rule = {}}}

	self.requestJoinData = nil

	self.curGroupId =  nil

	-- 服务器返回 信息
	app.conn:on('listGroup', function(msg)
		self:onListGroup(msg)
		self.emitter:emit('listGroup', msg)
	end)
	
	-- app.conn:on('listRequest', function(msg)
	-- 	self:onAdminMsg(msg)
	-- 	self.emitter:emit('listRequest', msg)
	-- end)

	app.conn:on('groupInfo', function(msg)
		self:onGroupInfo(msg)
		self.emitter:emit('groupInfo', msg)
	end)


	app.conn:on('memberList', function(msg)
		self:onMemberList(msg)
		self.emitter:emit('memberList', msg)
	end)

	app.conn:on('groupDismiss', function(msg)
		self.emitter:emit('groupDismiss', msg)
	end)

	app.conn:on('newDesk', function(msg)
		self:roomList(self.curGroupId)
		self.emitter:emit('newDesk', msg)
	end)

	app.conn:on('groupRoomList', function(msg)
		self:onGroupRoomList(msg)
		self.emitter:emit('groupRoomList', msg)
	end)

	app.conn:on('delDesk', function(msg)
		if msg.groupId and self.curGroupId == msg.groupId then
			self:roomList(self.curGroupId)
		end
	end)

	-- 服务器返回 结果
	app.conn:on('GroupMgr_creatResult', function(msg)
		self.emitter:emit('GroupMgr_creatResult', msg)
	end)

	app.conn:on('GroupMgr_dismissResult', function(msg)
		self.emitter:emit('GroupMgr_dismissResult', msg)
	end)

	app.conn:on('GroupMgr_getGroupResult', function(msg)
		if not msg then return end
		if msg.code ~= 1 then return end
		local groupInfo = msg.groupInfo
		if msg.mode == 1 then -- 查询群信息
			self.requestJoinData = groupInfo
		elseif msg.mode == 2 then  -- 设置当前操作的群
			self.listGroupInfo[groupInfo.id] = groupInfo
			self:setCurGroupId(groupInfo.id)
			self:roomList(groupInfo.id)
		end
		self.emitter:emit('GroupMgr_getGroupResult', msg)
	end)

	app.conn:on('Group_creatRoomResult', function(msg)
		self.emitter:emit('Group_creatRoomResult', msg)
	end)

	app.conn:on('onModifyInfoResult', function(msg)
		self.emitter:emit('onModifyInfoResult', msg)
	end)

	app.conn:on('onDismissResult', function(msg)
		self.emitter:emit('onDismissResult', msg)
	end)
	
	app.conn:on('joinRequestResult', function(msg)
		self.emitter:emit('joinRequestResult', msg)
	end)

	app.conn:on('Group_adminMsgResult', function(msg)
		self:onAdminMsg(msg)
		self.emitter:emit('Group_adminMsgResult', msg)
	end)

	app.conn:on('Group_acceptJoinResult', function(msg)
		self.emitter:emit('Group_acceptJoinResult', msg)
	end)

	app.conn:on('Group_quitResult', function(msg)
		self.emitter:emit('Group_quitResult', msg)
	end)

end

function Group:test()
	-- self:creatGroup("666")
	-- self:groupList("666")
	self:adminMsgList()
end

function Group:test1()
	self:requestJoin(636296)
end

function Group:onListGroup(msg)
	self.listGroupInfo = {}
	if msg and msg.list then
		for k,v in pairs(msg.list) do
			self.listGroupInfo[v.id] = v
		end
	end
end

function Group:onAdminMsg(msg)
	dump(msg)
	if not msg then return end
	local groupId = msg.groupId
	if groupId then
		self.listAdminMsg[groupId] = msg.data
	end
end

function Group:onGroupInfo(msg)
	dump(msg)
	if not msg then return end
	local groupId = msg.groupId
	if groupId then
		if not self.listGroupInfo[groupId] then self.listGroupInfo[groupId] = {} end
		self.listGroupInfo[groupId] = msg.data
	end
end

function Group:setCurGroupId(id)
	self.curGroupId = id
end

function Group:onMemberList(msg)
	if not msg then return end
	local groupId = msg.groupId
	if groupId then
		if not self.listGroupMemberInfo[groupId] then self.listGroupMemberInfo[groupId] = {} end
		local tabMember = {}
		for i, v in pairs(msg.data) do
			table.insert( tabMember, v)
		end		
		self.listGroupMemberInfo[groupId] = tabMember
	end
end

function Group:onGroupRoomList(msg)
	if not msg then return end
	local groupId = msg.groupId
	if groupId then
		self.listGroupRoom[groupId] = {}
		local tabDesk = msg.data
		for i, v in pairs(tabDesk) do
			local deskId = tonumber(i)
			if deskId then
				self.listGroupRoom[groupId][deskId] = v
			end
		end
	end
end

-- =============== C, V getData =======================

function Group:getPlayerRes(res)
	-- nickName 
	-- avatar 
	-- sex
	-- diamond
	-- playerId
	-- uid
	local app = require("app.App"):instance()
	return app.session.user[res]
end

function Group:getCurGroup()
	if self.listGroupInfo[self.curGroupId] then
		return self.listGroupInfo[self.curGroupId]
	end
end

function Group:getGroupInfo(groupId)
	return self.listGroupInfo[groupId]
end

function Group:getListGroup()
	return self.listGroupInfo
end

function Group:getCurAdminMsg()
	if self.curGroupId then
		local gId = self.curGroupId
		if gId and self.listAdminMsg[gId] then
			return self.listAdminMsg[gId]
		end
	end
end

function Group:getMemberInfo(groupId)
	return self.listGroupMemberInfo[groupId]
end

function Group:getRoomList(groupId)
	return self.listGroupRoom[groupId]
end

-- =============== send 2 groupmgr =======================

-- 创建牛友群
function Group:creatGroup(name)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'GroupMgr_creat',
		name = name,
	}
	app.conn:send(msg)
end

function Group:groupList()
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'GroupMgr_list', 
	}
	app.conn:send(msg)
end

function Group:getGroupById(groupId, mode)
	assert(type(groupId) == 'number')
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'GroupMgr_getGroup', 
		groupId = groupId,
		mode = mode, -- 1:查询加入 2:刷新界面
	}
	app.conn:send(msg)
end

function Group:dismissGroup(groupId)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'GroupMgr_dismiss',
		groupId = groupId,
	}
	app.conn:send(msg)
end

-- =============== send 2 group =======================
-- 必须指定 groupId

function Group:requestJoin()
	if self.requestJoinData then
		local groupId = self.requestJoinData.id
		local app = require("app.App"):instance()
		local msg = {
			msgID = 'Group_requestJoin',
			groupId = groupId,
		}
		app.conn:send(msg)
	end 
end

function Group:adminMsgList(groupId)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'Group_adminMsg',
		groupId = groupId,
	}
	app.conn:send(msg)
end

-- operate: 'accept', 'reject' 'block'
function Group:acceptJoin(groupId, playerId, operate)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'Group_acceptJoin',
		groupId = groupId,
		playerId = playerId,
		operate = operate,
	}
	app.conn:send(msg)
end

function Group:delUser(groupId, playerId)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'Group_delUser',
		groupId = groupId,
		playerId = playerId,
	}
	app.conn:send(msg)
end

function Group:memberList(groupId)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'Group_memberList',
		groupId = groupId,
	}
	app.conn:send(msg)
end

function Group:modifyGroupName(groupId, name)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'Group_modifyInfo',
		groupId = groupId,
		name = name
	}
	app.conn:send(msg)
end

function Group:quitGroup(groupId)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'Group_quit',
		groupId = groupId,
	}
	app.conn:send(msg)
end

function Group:roomList(groupId)
	local app = require("app.App"):instance()
	local msg = {
		msgID = 'Group_roomList',
		groupId = groupId,
	}
	app.conn:send(msg)
end

-- ===================================================

function Group:enterRoom(deskId)
	local app = require("app.App"):instance()
	if deskId then
		deskId = tostring(deskId)
		app.session.room:enterRoom(deskId)
	end
end

return Group
