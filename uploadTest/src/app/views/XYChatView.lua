local tools = require('app.helpers.tools')
local XYChatView = {}

function XYChatView:initialize()
end

local chatsTbl = {
    '大家好，很高兴见到各位！',
    '快点呀，等到花儿都谢了！',
    '我是庄家，谁敢挑战我',
    '风水轮流转，底裤都输光了',
    '大牛吃小牛，不要伤心哦',
    '一点小钱，那都不是事',
    '大家一起浪起来',
    '底牌亮出来，绝对吓死你',
    '你真是个天生的演员',
    '不要走，决战到天亮'   
}

local emojiTbl = {
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
}

function XYChatView.getChatsTbl()
    return chatsTbl
end

function XYChatView:getEmojiTbl()
    return emojiTbl
end

function XYChatView:layout(desk)
    self.desk = desk
    local black = self.ui:getChildByName('black')
    black:setContentSize(cc.size(display.width,display.height))
    self.ui:setPosition(display.cx,display.cy)
    local MainPanel = self.ui:getChildByName('MainPanel')
    self.MainPanel = MainPanel

	local emojiList = self.MainPanel:getChildByName('emoji'):getChildByName('emojiList')
    self.emojiList = emojiList
	emojiList:setItemModel(emojiList:getItem(0))
	emojiList:removeAllItems()
	emojiList:setScrollBarEnabled(false)    
    emojiList:setVisible(false)
	
	local shortcutList = self.MainPanel:getChildByName('shortcutList')
	self.shortcutList = shortcutList
	shortcutList:setItemModel(shortcutList:getItem(0))
	shortcutList:removeAllItems()
	shortcutList:setScrollBarEnabled(false)    
    shortcutList:setVisible(false)

	local chattingRecord = self.MainPanel:getChildByName('chattingRecord')
    local item1 = chattingRecord:getChildByName('item1')
    local item2 = chattingRecord:getChildByName('item2')   
    local item3 = chattingRecord:getChildByName('item3')   
    self.item1 = item1
    self.item2 = item2 
    self.item3 = item3
    item1:setVisible(false)    
    item2:setVisible(false) 
    item3:setVisible(false)
    local recordList = chattingRecord:getChildByName('recordList')
	self.recordList = recordList
	recordList:setItemModel(item1)
	recordList:removeAllItems()
	recordList:setScrollBarEnabled(false)    

	local chatEditBox = chattingRecord:getChildByName('Text_input')
    self.chatEditBox = tools.createEditBox(chatEditBox, {
		-- holder
		defaultString = '请输入发言',
		holderSize = 25,
		holderColor = cc.c3b(172,108,64),

		-- text
		fontColor = cc.c3b(172,108,64),
		size = 25,
        maxCout = 28,
		fontType = 'views/font/fangzheng.ttf',	
        inputMode = cc.EDITBOX_INPUT_MODE_SINGLELINE,
    })

    self:initShortcutList()
    self:initEmojiList()
    self:freshBtnState('shortcut')
    self:freshListState('shortcut')    
end

function XYChatView:initShortcutList()
	local function addRow(node, content, index)
        local item = node:getItem(index)
        item:getChildByName('content'):setString(content)
		item:getChildByName('touch'):addClickEventListener(function()
			self.emitter:emit('choosed', index+1)
    	end)
    end
	local shortcutList = self.shortcutList
    shortcutList:setVisible(true)    
	shortcutList:removeAllItems()
    local index = 0
	for i, v in pairs(chatsTbl) do
		shortcutList:pushBackDefaultItem()
        addRow(shortcutList, v, index)
        index = index + 1			
	end	
end

function XYChatView:freshBtnState(mode)
    local shortcutBtn = self.MainPanel:getChildByName('shortcutBtn'):getChildByName('active')
    local emojiBtn = self.MainPanel:getChildByName('emojiBtn'):getChildByName('active')
    local recordBtn = self.MainPanel:getChildByName('recordBtn'):getChildByName('active')
    local mode = mode or 'shortcut'
    if mode == 'shortcut' then
        shortcutBtn:setVisible(true)
        emojiBtn:setVisible(false)
        recordBtn:setVisible(false)
    elseif mode == 'emoji' then
        emojiBtn:setVisible(true)    
        shortcutBtn:setVisible(false)
        recordBtn:setVisible(false)
    elseif mode == 'record' then
        recordBtn:setVisible(true)
        emojiBtn:setVisible(false)    
        shortcutBtn:setVisible(false)
    end
end

function XYChatView:freshListState(mode)
    local chattingRecord = self.MainPanel:getChildByName('chattingRecord')
    local mode = mode or 'shortcut'
    if mode == 'shortcut' then
        self.shortcutList:setVisible(true)
        self.emojiList:setVisible(false)
        chattingRecord:setVisible(false)
    elseif mode == 'emoji' then
        self.emojiList:setVisible(true)    
        self.shortcutList:setVisible(false)
        chattingRecord:setVisible(false)
    elseif mode == 'record' then
        chattingRecord:setVisible(true)
        self.emojiList:setVisible(false)    
        self.shortcutList:setVisible(false)
    end    
end

function XYChatView:freshRecordList(msg)
    if msg == nil then return end
    
    local avatarTab = {}
    local players = self.desk.players
    for k, v in pairs(players) do
        avatarTab[v.actor.uid] = v.actor.avatar
    end

	local function addRow(content, idx, uid, mode, emojiIdx)  
        local size = nil
        if content then size = string.len(content) end    --42
        if mode == 'text' and size <= 42 then
            self.recordList:setItemModel(self.item1)
        elseif  mode == 'text' and size > 42 then 
            self.recordList:setItemModel(self.item2)
        elseif mode == 'emoji' and emojiIdx then
            self.recordList:setItemModel(self.item3)            
        end

        self.recordList:pushBackDefaultItem()
        local item = self.recordList:getItem(idx)    
        item:setVisible(true)
        if mode == 'text' then
            local contentNode = item:getChildByName('contentPanel')
                :getChildByName('img_content')
                :getChildByName('content')                       
            contentNode:setString(content)
        elseif mode == 'emoji' then
            local contentNode = item:getChildByName('contentPanel')
                :getChildByName('img_emoji')
            local path = 'views/xychat/'..emojiIdx..'.png'
            contentNode:loadTexture(path)
        end   
        self:freshHeadImg(item, avatarTab[uid])
    end

    local recordList = self.recordList  
    recordList:removeAllItems()  
    local idx = 0
    local mode = nil
    local content = nil
    local emojiIdx = nil
    for k, v in pairs(msg) do
        if v.type == 0 and v.msg then --快捷语
            content = chatsTbl[v.msg]
            mode = 'text'
        elseif v.type == 1 and v.msg then --表情
            emojiIdx = v.msg
            mode = 'emoji'
        elseif v.type == 2 and v.msg then --自定义文字
            content = v.msg
            mode = 'text'
        end        
       
        addRow(content, idx, v.uid, mode, emojiIdx) 
        idx = idx + 1
    end
    recordList:jumpToBottom()
end

function XYChatView:freshHeadImg(item, headUrl)
    local node = item:getChildByName('avatar')
    if headUrl == nil or headUrl == '' then return end
    local cache = require('app.helpers.cache')		 
	cache.get(headUrl, function(ok, path)
		if ok then
			node:show()
			node:loadTexture(path)
		else
			node:loadTexture('views/public/tx.png')
		end
	end)
end

function XYChatView:getChatEditBoxInfo() 
    local text = self.chatEditBox:getText()
    return text 	
end

function XYChatView:freshChatEditBox(content, enable)
    enable = enable or false
    self.chatEditBox:setText(content)
    self.chatEditBox:setEnabled(enable)
end

function XYChatView:initEmojiList()
    local emojiList = self.emojiList    
    emojiList:setVisible(true)
    emojiList:removeAllItems()

    local line = #emojiTbl / 3
    if line == 0 then
        line = 1
    end

    for i = 1, line do
        emojiList:pushBackDefaultItem()
        local item = emojiList:getItem(i - 1)
        self:setBtnClickEvent(item, i - 1, 3)
    end
end

function XYChatView:setBtnClickEvent(item, line, col)
    for i = 1, col do
        local touch = item:getChildByName('touch_'..i)
        local id = 3 * line + i
        local path = "views/xychat/"..id..".png"
        touch:getChildByName('imoji_img'):loadTexture(path)

        touch:addClickEventListener(function()
            self.emitter:emit('back')
            local app = require("app.App"):instance()
            local tmsg = {
                msgID = 'chatInGame',
                type = 1,
                msg = id
            }
            app.conn:send(tmsg)
        end)
    end
end

return XYChatView
