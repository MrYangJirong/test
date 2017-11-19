local cache = require('app.helpers.cache')
local GameLogic = require('app.helpers.NNGameLogic')

local SUIT = {
    ['♠'] = 'h',
    ['♣'] = 'm',
    ['♥'] = 'z',
    ['♦'] = 'f',
    ['★'] = 'j1',
    ['☆'] = 'j2',
}

local CARD = {
    ['♠A'] = 1,   ['♠2'] = 2,  ['♠3'] = 3,  ['♠4'] = 4, ['♠5'] = 5,
    ['♠6'] = 6,   ['♠7'] = 7,  ['♠8'] = 8,  ['♠9'] = 9,
    ['♠T'] = 10, ['♠J'] = 10, ['♠Q'] = 10, ['♠K'] = 10,

    ['♥A'] = 1,   ['♥2'] = 2,  ['♥3'] = 3,  ['♥4'] = 4, ['♥5'] = 5,
    ['♥6'] = 6,   ['♥7'] = 7,  ['♥8'] = 8,  ['♥9'] = 9,
    ['♥T'] = 10, ['♥J'] = 10, ['♥Q'] = 10, ['♥K'] = 10,

    ['♣A'] = 1,   ['♣2'] = 2,  ['♣3'] = 3,  ['♣4'] = 4, ['♣5'] = 5,
    ['♣6'] = 6,   ['♣7'] = 7,  ['♣8'] = 8,  ['♣9'] = 9,
    ['♣T'] = 10, ['♣J'] = 10, ['♣Q'] = 10, ['♣K'] = 10,

    ['♦A'] = 1,   ['♦2'] = 2,  ['♦3'] = 3,  ['♦4'] = 4, ['♦5'] = 5,
    ['♦6'] = 6,   ['♦7'] = 7,  ['♦8'] = 8,  ['♦9'] = 9,
    ['♦T'] = 10, ['♦J'] = 10, ['♦Q'] = 10, ['♦K'] = 10,
    ['☆'] = 10,   ['★'] = 10
}


local PlaybackView = {}

function PlaybackView:initialize(data) 
    self.data = data
    self.curPage = 0 --当前局数
end

function PlaybackView:layout(desk)
    self.desk = desk
	self.ui:setPosition(display.cx, display.cy)
	local MainPanel = self.ui:getChildByName('MainPanel')
	local bg = MainPanel:getChildByName('bg')
	self.bg = bg

	local defaultItem = self.bg:getChildByName('item')
    defaultItem:setVisible(false)
    self.item = defaultItem
	local ListView1 = self.bg:getChildByName('ListView_1')
	self.ListView1 = ListView1
	ListView1:setItemModel(defaultItem)
	ListView1:removeAllItems()
	ListView1:setScrollBarEnabled(false)   

	local ListView2 = self.bg:getChildByName('ListView_2')
	self.ListView2 = ListView2
	ListView2:setItemModel(defaultItem)
	ListView2:removeAllItems()
	ListView2:setScrollBarEnabled(false)     

    local curRoomId = self.desk.info.deskId
    self:freshRoomId(curRoomId)
end

function PlaybackView:freshRoomId(roomId)
	local roomId = self.bg:getChildByName('roomId'):setString(roomId)
end

-- ================ list ================
function PlaybackView:sortData(oneRoundData)
    local data = clone(oneRoundData)
    local retTab = {}
    for k,v in pairs(data) do
        local idx = self.desk:getPlayerPos(k)
        v.uid = k
        v.idx = idx
        local player = self.desk:getPlayerByPos(idx)
        v.actor = player.actor
        table.insert( retTab, v)
    end
    table.sort( retTab, function(a, b)
        return a.idx < b.idx
    end)
    return retTab
end


function PlaybackView:freshRecordView(mode, freshMode)
    local deskRecord = self.desk:getDeskRecord()
    if #deskRecord == 0 then 
        self:freshCurPage('--', '--') 
        return 
    end
    freshMode = freshMode or 1
    if freshMode == 2 and self.curPage ~= 0 then
        self:freshCurPage(self.curPage, #deskRecord, true)        
        return
    end

    if mode == 'firstPage' then
        self.curPage = 1
    elseif mode == 'frontPage' then
        self.curPage = self.curPage - 1
    elseif mode == 'nextPage' then
        self.curPage = self.curPage + 1
    elseif mode == 'lastPage' then
        self.curPage = #deskRecord
    end
    if self.curPage > #deskRecord then
        self.curPage = #deskRecord
    elseif self.curPage < 1 then
        self.curPage = 1
    end

    self:freshCurPage(self.curPage, #deskRecord)
    local one = self:sortData(deskRecord[self.curPage])

    self.ListView1:removeAllItems()
    self.ListView2:removeAllItems()
    for i, v in ipairs(one) do
        local j = math.ceil(i/3)
        local k = i % 3
        -- k = (k == 0) and 3 or k
        self:freshListItem(j, k, v)
    end
end

function PlaybackView:freshCurPage(idx, total, mode)    
    local curPage = self.bg:getChildByName('operation'):getChildByName('curPage'):setString(idx..'/')
    local totalPage = self.bg:getChildByName('operation'):getChildByName('totalPage'):setString(total..'')
    if mode then
        totalPage:setColor(cc.c3b(255,0,0))
        totalPage:setFontSize(28)
    else
        totalPage:setColor(cc.c3b(255,255,255))
        totalPage:setFontSize(25)        
    end
end

function PlaybackView:freshListItem(row, column, data)
    local listView = (row == 1) and self.ListView1 or self.ListView2
    self.item:setVisible(true)
    listView:pushBackDefaultItem()
    local tabItem = listView:getItems()
    local item = tabItem[#tabItem]

    local actor = data.actor

    -- 头像
    self:freshHeadImg(item, actor.avatar)
    -- 名字
    self:freshUserInfo(item, actor.nickName, actor.playerId)
    -- 庄家 押注
    self:freshBankerAndPutmoney(item, data.bIsBanker, data.nPutScore)
    -- 牌
    self:freshCards(item, data.hand, data.niuCnt, data.specialType)
    -- 分数
    self:freshScore(item, data.score)
end

-- ================ item  views ================
function PlaybackView:freshHeadImg(item, headUrl)
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

function PlaybackView:freshUserInfo(item, name, id)
    local node = item:getChildByName('userInfo')
    node:getChildByName('userName'):setString(name)
    node:getChildByName('userId'):setString(id)
end

function PlaybackView:freshScore(item, score)
    local score = score or 0
    local scoreNode = item:getChildByName('score')
    scoreNode:setString(score..'')
    if score >= 0 then
        scoreNode:setColor(cc.c3b(214,70,43))
    else
        scoreNode:setColor(cc.c3b(136,142,72))
    end
end

function PlaybackView:freshBankerAndPutmoney(item, banker, putmoney)
    local bankerImg = item:getChildByName('banker')
    local coin = item:getChildByName('coin')
    local coinStr = coin:getChildByName('coinCnt')

    bankerImg:setVisible(false)
    coin:setVisible(false)

    if banker then
        bankerImg:setVisible(true)
        return
    else
        coin:setVisible(true)
        coinStr:setString(tostring(putmoney))
        return
    end
end

function PlaybackView:freshCards(item, cards, niuCnt, specialType)

    local cardNode = item:getChildByName('cards')
    local typeImg = item:getChildByName('cardType')
    local specialTypeImg = item:getChildByName('specialType')

    local SUIT_UTF8_LENGTH = 3
    local function card_suit(c)
        if not c then print(debug.traceback()) end
        if c == '☆' or c == '★' then
            return c
        else
            return #c > SUIT_UTF8_LENGTH and c:sub(1, SUIT_UTF8_LENGTH) or nil
        end
    end
    
    local function card_rank(c)
        return #c > SUIT_UTF8_LENGTH and c:sub(SUIT_UTF8_LENGTH+1, #c) or nil
    end
    
    local j = 1
    for i, v in pairs(cards) do
        local card = cardNode:getChildByName('card' .. j)
        local suit = SUIT[card_suit(i)]
        local rnk = card_rank(i)

        local path
        if suit == 'j1' or suit == 'j2' then
            path = 'views/xydesk/cards/' .. suit .. '.png'
        else
            path = 'views/xydesk/cards/' .. suit .. rnk .. '.png'
        end
        card:loadTexture(path)
        j = j + 1
    end

    local path = ''
    specialTypeImg:setVisible(false)
    typeImg:setVisible(false)
    if specialType > 0 then
        path = 'views/xydesk/result/' .. GameLogic.getSpecialTypeByVal(specialType) .. '.png'
        specialTypeImg:loadTexture(path)
        specialTypeImg:setVisible(true)
    else
        path = 'views/xydesk/result/' .. niuCnt .. '.png'
        typeImg:loadTexture(path)   
        typeImg:setVisible(true)     
    end
    
end

return PlaybackView
