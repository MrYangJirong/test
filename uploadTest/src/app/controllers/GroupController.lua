local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local SoundMng = require "app.helpers.SoundMng"
local tools = require('app.helpers.tools')
local TranslateView = require('app.helpers.TranslateView')
local GroupController = class("GroupController", Controller):include(HasSignals)

function GroupController:initialize()
    Controller.initialize(self)
    HasSignals.initialize(self)
end

function GroupController:viewDidLoad()
  local app = require("app.App"):instance()
  local group = app.session.group
  self.group = group

  self.createRoomCtrl = nil

  self.view:layout()
  self.listener = {
    group:on('listGroup',function(groups)
        dump(groups)
        local groupsData = self.group:getListGroup()
        self.view:freshListGroups(groupsData)
        --根据牛友群列表是否为空去显示或隐藏成员,设置,消息按钮
        local groupCnt = self.view:getGroupsCnt()
        if #groupCnt==0 then
            self.view:freshAdminMsg(false)    
            self.view:freshSettingBtn(false)
            self.view:freshMemberBtn(false) 
            self.view:freshGroupNameAndID(false)
            self.view:freshNoRoomTips(false)
            self.view:freshCreateRoomBtn(false)
        else  
            self.view:freshSettingBtn(true)
            self.view:freshMemberBtn(true)
            self.view:freshCreateRoomBtn(true)                                    
        end
    end),

    --创建房间结果消息
    group:on('GroupMgr_creatResult',function(groups)
        dump(groups)
        tools.showRemind("牛友群创建成功")         
    end),

    -- 查询牛友群结果消息 0:查询失败 1:查询成功
    group:on('GroupMgr_getGroupResult',function(queryMessage)
        dump(queryMessage)
        if queryMessage.code == 1 and queryMessage.mode == 1 then
            local info = queryMessage.groupInfo.ownerInfo
            local groupName = queryMessage.groupInfo.name
            local adminName = info.nickname
            local avatar = info.avatar
            self.view:freshQueryResult(true, groupName, adminName, avatar)
            self.view:freshBtnState(false)
        elseif queryMessage.code == 1 and queryMessage.mode == 2 then
            self:updateCurGroupView()
        else
            tools.showRemind("俱乐部不存在")     
        end
    end),   

    -- 新牛友群信息
    group:on('groupInfo',function(msg)
        self:updateCurGroupView()
        local groupsData = self.group:getListGroup()
        self.view:freshListGroups(groupsData)
    end),

    -- 牛友群加入结果消息 -1:已被管理员屏蔽 -2:已在群里 -3:已经申请过了 1:申请成功等待管理员处理
    group:on('joinRequestResult',function(joinMessage)
        dump(joinMessage)
        if joinMessage.code==1 then
            tools.showRemind("已成功提交,请耐心等待管理批准")
        elseif joinMessage.code==-3 then
            tools.showRemind("您已提交了加入申请,请耐心等待管理员审核")
        end
    end),          

    -- 消息列表结果
    group:on('Group_adminMsgResult',function(msgMessage)
        dump(msgMessage)
        local msg = self.group:getCurAdminMsg()
        self.view:freshMessageList(msg)
    end),   

    -- 消息处理结果
    group:on('Group_acceptJoinResult',function(optResult)
        dump(optResult)
    end),  

    -- 设置改名处理结果
    group:on('onModifyInfoResult',function(modResult)
        dump(modResult)

    end), 

    -- 解散结果
    group:on('GroupMgr_dismissResult',function(disResult)
        dump(disResult)
        local groupInfo = self.group:getCurGroup()
        local groupName = groupInfo.name       
        tools.showRemind('您所在的俱乐部['..groupName..']已被管理解散')
        local groupsData = self.group:getListGroup()
        self.view:freshListGroups(groupsData) --刷新群列表        
    end), 

    group:on('groupDismiss',function(disResult)
        dump(disResult)
        local group = self.group
        local groupInfo = self.group:getCurGroup()
        local groupName = groupInfo.name     
        local myPlayerId = group:getPlayerRes("playerId") --自己id
        local ownerId = groupInfo.ownerInfo.playerId --ID   
        if  ownerId ~= myPlayerId then       
            tools.showRemind('您所在的俱乐部['..groupName..']已被管理解散')
            local groupsData = self.group:getListGroup()
            self.view:freshListGroups(groupsData) --刷新群列表    
        end    
    end), 

    -- 退出群结果
    group:on('Group_quitResult',function(msg)
        dump(msg)
        local groupsData = self.group:getListGroup()
        self.view:freshListGroups(groupsData)        
    end),

    -- 成员信息
    group:on('memberList',function(msg)
        self:updateCurGroupMemberList()
    end),

    -- 成员信息
    group:on('newDesk',function(msg)
        print('123123123')
    end),

    -- 成员信息
    group:on('groupRoomList',function(msg)
        local groupInfo = group:getCurGroup()
        local groupId = groupInfo.id
        local roomList = group:getRoomList(groupId)
        local myPlayerId = group:getPlayerRes("playerId") --自己id
        self.view:freshRoomList(roomList, myPlayerId)
        if roomList and table.nums(roomList)>0 then
            self.view:freshNoRoomTips(false)
        end
    end),


    -- 创建房间结果
    group:on('Group_creatRoomResult',function(msg)
        self:delCreateRoomController()
    end),

    -- 消息列表按钮操作结果
    self.view:on('messageListOperate',function(optApply)
        dump(optApply)
        local groupInfo = group:getCurGroup()
        local groupId = groupInfo.id
        local playerId = optApply[1]
        local operate = optApply[2]
        self.group:acceptJoin(groupId, playerId, operate)
    end), 

    -- 选择群
    self.view:on('selectGroup',function(groupId)
        self.group:getGroupById(groupId, 2)
    end),  

    -- admin设置改名操作
    self.view:on('settingOperateModify',function()
        local groupInfo = group:getCurGroup()
        local groupName = groupInfo.name       
        self.view:freshAdminSettingLayer(false)  
        self.view:freshNormalSettingLayer(false)         
        self.view:freshModifyGroupName(true, groupName)	         
    end),  

    -- admin设置解散操作
    self.view:on('settingOperateDismiss',function()
        local groupInfo = group:getCurGroup()
        local groupName = groupInfo.name       
        self.view:freshAdminSettingLayer(false)  
        self.view:freshNormalSettingLayer(false)         
        self.view:freshDismissGroup(true, groupName)	         
    end),      

    self.view:on('memberListDelMember',function(playerId)
        if not playerId then return end
        local groupInfo = self.group:getCurGroup()
        local groupId = groupInfo.id 
        group:delUser(groupId, playerId)
    end),  

    -- 点击房间
    self.view:on('touchRoomItem',function(roomId)
        print(roomId)
        group:enterRoom(roomId)
    end),

  }
    local scheduler = cc.Director:getInstance():getScheduler()
    self.schedulerID = scheduler:scheduleScriptFunc(function()
        group:groupList()
    end, 5, false)

    group:groupList()
end

-- 更新当前牛友群信息
function GroupController:updateCurGroupView()
    local group = self.group
    local myPlayerId = group:getPlayerRes("playerId") --自己id
    local groupInfo = group:getCurGroup()
    local ownerId = groupInfo.ownerInfo.playerId --ID
    local memberNum = groupInfo.memberCnt --组成员数
    local adminMsgCnt = groupInfo.adminMsgCnt --管理员消息数
    local roomNum = groupInfo.roomCnt --房间数
    local groupId = groupInfo.id --群ID
    local groupName = groupInfo.name --群名称

    self.view:freshGroupNameAndID(true, groupName, groupId)
    self.view:freshNoRoomTips(roomNum==0)
    if myPlayerId == ownerId then
        self.view:freshAdminMsg(true, adminMsgCnt)
    else
        self.view:freshAdminMsg(false)
    end
end

-- 更新当前牛友群成员列表
function GroupController:updateCurGroupMemberList()
    local group = self.group
    local myPlayerId = group:getPlayerRes("playerId") --自己id
    local groupInfo = group:getCurGroup()
    local groupId = groupInfo.id
    local memberInfo = group:getMemberInfo(groupId)
    local ownerInfo = groupInfo.ownerInfo
    self.view:freshMemberList(memberInfo, ownerInfo, myPlayerId)
end

function GroupController:clickSetting()
    SoundMng.playEft('btn_click.mp3')
    local myPlayerId = self.group:getPlayerRes("playerId") 
    local groupInfo = self.group:getCurGroup()
    local ownerId = groupInfo.ownerInfo.playerId
    if myPlayerId==ownerId then
        self.view:freshAdminSettingLayer(true)  
    else
        self.view:freshNormalSettingLayer(true) 
    end 
end

function GroupController:clickSureModify()  
    local groupInfo = self.group:getCurGroup()
    local groupId = groupInfo.id  
	local input = self.view:getModifyEditBoxInfo()
    local inputLength = string.match(input, "%S+")
	if input and inputLength then
		print("getModifyEditBoxInfo", input)
		self.group:modifyGroupName(groupId,input) 
        self.view:freshModifyGroupName(false)         
    elseif not inputLength then
        tools.showRemind("俱乐部名字为空")               
	end      
end

function GroupController:clickCancelModify()
    self.view:freshModifyGroupName(false)    
end

-- 确认解散群
function GroupController:clickSureDismiss()  
    local groupInfo = self.group:getCurGroup()
    local groupId = groupInfo.id 
    self.group:dismissGroup(groupId)
    self.view:freshDismissGroup(false)   
end

function GroupController:clickCancelDismiss()
    self.view:freshDismissGroup(false)    
end

--退出群
function GroupController:clickQuitBtn()
    local groupInfo = self.group:getCurGroup()
    local groupName = groupInfo.name   
    self.view:freshNormalSettingLayer(false)   
    self.view:freshQuitGroup(true, groupName)    
end

function GroupController:clickCancelQuit()    
    self.view:freshQuitGroup(false)    
end

function GroupController:clickSureQuit()  
    local groupInfo = self.group:getCurGroup()
    local groupId = groupInfo.id 
    self.group:quitGroup(groupId)
    self.view:freshQuitGroup(false)    
end

function GroupController:clickMemberBtn()
    SoundMng.playEft('btn_click.mp3')
    local myPlayerId = self.group:getPlayerRes("playerId") 
    local groupInfo = self.group:getCurGroup()
    local ownerId = groupInfo.ownerInfo.playerId
    local groupId = groupInfo.id

    if myPlayerId == ownerId then
        self.view:freshAdminMemberLayer(true)  
    else
        self.view:freshNormalMemberLayer(true) 
    end 

    self.group:memberList(groupId)
end

--删除成员
function GroupController:clickDelMember()
    self.view:freshAdminMemberListDelBtn(nil, true)
end

--创建牛友群
function GroupController:clickCreateGroup()
    print("creating group...")
    self.view:freshGroupCreateLayer(true)
    self.view:freshAddLayer(false)  
    self.view:freshGroupListVisible(false) 
    
    self.view:freshCreateEditBox("", true)
    self.view:freshGroupJoinLayer(false)
end

--加入牛友群
function GroupController:clickJoinGroup()
    print("joining group...")
    self.view:freshGroupJoinLayer(true)
    self.view:freshAddLayer(false)  
    self.view:freshGroupListVisible(false) 

    self.view:freshJoinEditBox("", true) --------------
    self.view:freshGroupCreateLayer(false)

end

-- 加入房间 
local function setWidgetAction(controller, self, args)
    SoundMng.playEft('btn_click.mp3')
    local ctrl = Controller:load(controller, args)
    self:add(ctrl)

    local app = require("app.App"):instance()
    app.layers.ui:addChild(ctrl.view)
    ctrl.view:setPositionX(display.width)

    --TranslateView.moveCtrl(ctrl.view, -1)
    TranslateView.fadeIn(ctrl.view, -1)
    ctrl:on('back', function()
        TranslateView.fadeOut(ctrl.view, 1, function()
            if controller == 'CreateRoomController' then
                self:delCreateRoomController()
            else
                ctrl:delete()
            end
        end)
    end)
    return ctrl
end

function GroupController:clickJoinRoom()
    setWidgetAction('EnterRoomController', self)
end

-- 创建房间 
function GroupController:clickCreateRoom()
    self:addCreateRoomController()
end

function GroupController:addCreateRoomController()
    local groupInfo = self.group:getCurGroup()
    self.createRoomCtrl = setWidgetAction('CreateRoomController', self, groupInfo)
end

function GroupController:delCreateRoomController()
    if self.createRoomCtrl then
        self.createRoomCtrl:delete()
    end
    self.createRoomCtrl = nil
end

-- 点击成员显示头像
function GroupController:clickMemberInfo()
    setWidgetAction('PersonalPageController', self, nil)
end

--牛友群----------------------创建 确定
function GroupController:clickSureCreate()
	local input = self.view:getCreateEditBoxInfo()
    local inputLength = string.match(input, "%S+")
    if input and inputLength then
		print("clickSureCreate", input)
		self.group:creatGroup(input)
    elseif not inputLength then
        tools.showRemind("俱乐部名字为空")
	end    
end

----------------------创建 取消
function GroupController:clickCancelCreate()
    self.view:freshGroupCreateLayer(false) 
    self.view:freshCreateEditBox("", true)
    self.view:freshGroupListVisible(true) 
end

----------------------创建 结果
function GroupController:clickCreateResult()
    self:clickCancelCreate()
    -- self.view:freshCreateGroupResult(false)
end

----------------------加入 查询
function GroupController:clickQueryJoin()
	local input = self.view:getJoinEditBoxInfo()
	if input and input~="" then
		print("clickQueryJoin", input)
		self.group:getGroupById(input, 1)
	end    
end

-----------------------加入 取消
function GroupController:clickCancelJoin()
    self.view:freshGroupJoinLayer(false) 
    self.view:freshJoinEditBox("", true)
    self.view:freshGroupListVisible(true) 
end

-----------------------加入       确定
function GroupController:clickJoinBtn()
    self.group:requestJoin()
end

-----------------------加入       放弃
function GroupController:clickBackBtn()
    self.view:freshQueryResult(false)
    self.view:freshBtnState(true) 
end

function GroupController:clickAdd()
    SoundMng.playEft('btn_click.mp3')
    self.view:freshAddLayer(true)        
end

function GroupController:clickMessage()
    SoundMng.playEft('btn_click.mp3')
    local groupInfo = self.group:getCurGroup()
    local groupId = groupInfo.id
    self.group:adminMsgList(groupId) 
    self.view:freshMessageLayer(true)        
end

-- 触摸隐藏 
function GroupController:clickAddLayer()
    self.view:freshAddLayer(false) 
end

function GroupController:clickMessageLayer()
    self.view:freshMessageLayer(false)  
end

function GroupController:clickAdminSettingLayer()
    self.view:freshAdminSettingLayer(false) 
end

function GroupController:clickNormalSettingLayer()
    self.view:freshNormalSettingLayer(false) 
end

function GroupController:clickNormalMemberLayer()
    self.view:freshNormalMemberLayer(false) 
end

function GroupController:clickAdminMemberLayer()
    self.view:freshAdminMemberLayer(false) 
end

function GroupController:clickCloseWan()
    -- self.view:freshRoomInfo(false) 
end

function GroupController:clickBack()
    SoundMng.playEft('btn_click.mp3')
    local app = require('app.App'):instance()
    app:switch('LobbyController')
end

function GroupController:clickNoRoomTips()
    -- self.view:freshNoRoomTips(false)
end

function GroupController:finalize()
  for i = 1,#self.listener do
    self.listener[i]:dispose()
  end
  if self.schedulerID then
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
    self.schedulerID = nil
  end
end


return GroupController
