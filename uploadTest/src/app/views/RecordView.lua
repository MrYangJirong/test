local Scheduler = require('app.helpers.Scheduler')
local cache = require('app.helpers.cache')
local Controller = require('mvc.Controller')
local TranslateView = require('app.helpers.TranslateView')
local SoundMng = require "app.helpers.SoundMng"
local app = require('app.App'):instance()
local GameLogic = require('app.helpers.NNGameLogic')
local RecordView = {}


function RecordView:initialize()
	self.updateF = Scheduler.new(function(dt)
		self:update(dt)
	end)
	
	self.delay = 0
	self:enableNodeEvents()
	
	self.suit_2_path = {
		['♠'] = 'h',
		['♣'] = 'm',
		['♥'] = 'z',
		['♦'] = 'f',
		['★'] = 'j1',
		['☆'] = 'j2',
	}
	
	self.CARDS = {
		['♠A'] = 1, ['♠2'] = 2, ['♠3'] = 3, ['♠4'] = 4, ['♠5'] = 5,
		['♠6'] = 6, ['♠7'] = 7, ['♠8'] = 8, ['♠9'] = 9,
		['♠T'] = 10, ['♠J'] = 10, ['♠Q'] = 10, ['♠K'] = 10,
		
		['♥A'] = 1, ['♥2'] = 2, ['♥3'] = 3, ['♥4'] = 4, ['♥5'] = 5,
		['♥6'] = 6, ['♥7'] = 7, ['♥8'] = 8, ['♥9'] = 9,
		['♥T'] = 10, ['♥J'] = 10, ['♥Q'] = 10, ['♥K'] = 10,
		
		['♣A'] = 1, ['♣2'] = 2, ['♣3'] = 3, ['♣4'] = 4, ['♣5'] = 5,
		['♣6'] = 6, ['♣7'] = 7, ['♣8'] = 8, ['♣9'] = 9,
		['♣T'] = 10, ['♣J'] = 10, ['♣Q'] = 10, ['♣K'] = 10,
		
		['♦A'] = 1, ['♦2'] = 2, ['♦3'] = 3, ['♦4'] = 4, ['♦5'] = 5,
		['♦6'] = 6, ['♦7'] = 7, ['♦8'] = 8, ['♦9'] = 9,
		['♦T'] = 10, ['♦J'] = 10, ['♦Q'] = 10, ['♦K'] = 10,
		['☆'] = 10, ['★'] = 10
	}
end 

function RecordView:getCardValue(var)
    return self.CARDS[var]
end

function RecordView:onExit()
    Scheduler.delete(self.updateF)
    self.updateF = nil
end

function RecordView:update(dt)
    self.delay = self.delay + dt
    if self.delay > 5.0 then
    self.delay = 0

    --self.emitter:emit('fresh')
    end
end

function RecordView:layout()
    local MainPanel = self.ui:getChildByName('MainPanel')
    MainPanel:setContentSize(cc.size(display.width,display.height))
    MainPanel:setPosition(display.cx,display.cy)
    self.MainPanel = MainPanel

    local bg = MainPanel:getChildByName('bg')
    bg:setPosition(display.cx, display.cy)
    self.bg = bg

    local list = bg:getChildByName('list')
    list:setItemModel(bg:getChildByName("row"))
    list:removeAllItems()
    self.list = list

	local app = require("app.App"):instance()
  	self.user = app.session.user


    local infobg=MainPanel:getChildByName('infoBg')
    infobg:setPosition(display.cx, display.cy)
    self.infobg=infobg

    local listView=infobg:getChildByName('Panel'):getChildByName('ListView')
    listView:setItemModel(listView:getItem(0))
    listView:removeAllItems()
    self.listView=listView

    local listTopView=infobg:getChildByName('ListTopView')
    listTopView:setItemModel(listTopView:getItem(0))
    listTopView:removeAllItems()
    self.listTopView=listTopView

    local ListBottomView=infobg:getChildByName('ListBottomView')
    ListBottomView:setItemModel(ListBottomView:getItem(0))
    ListBottomView:removeAllItems()
    self.ListBottomView=ListBottomView
   
end

function RecordView:getWinner(players)
    local result
    for k, v in ipairs(players) do
        if result == nil then
            result = v.result
        else
            if result < v.result then
                result = v.result
            end
        end
    end
    dump(result)
    return result
end

function RecordView:getloser(players)
    local result
    for k, v in ipairs(players) do
        if result == nil then
            result = v.result
        else
            if result >= v.result then
                result = v.result
            end
        end
    end
   dump(result)
    return result
end


function RecordView:freshRowInfo(rItem, data)
    dump(data)
    local rList = rItem:getChildByName('rlist')
    rList:setItemModel(self.bg:getChildByName("rItem"))
    rList:removeAllItems()



    dump(data.player)
    local players=data.player
    local winner = self:getWinner(players)
    local loser = self:getloser(players)

	if #players > 3 then
		local rList2 = rItem:getChildByName('rlist2')
		rList2:setItemModel(self.bg:getChildByName("rItem"))
		rList2:removeAllItems()
		rList2:setEnabled(false)

		for i, v in ipairs(players) do
          if i <= 3 then
		  	rList:pushBackDefaultItem()
           	local item = rList:getItem(i - 1)
           	self:freshRListItem(item, v,winner,loser, data.ownerName)
			rList:setEnabled(false) -- 禁止滑动
		  else
			rList2:pushBackDefaultItem()
           	local item = rList2:getItem(i - 4)
           	self:freshRListItem(item, v,winner,loser, data.ownerName)
			rList2:setEnabled(false) -- 禁止滑动
		  end
        end
	
	else
		for i, v in ipairs(players) do
			rList:pushBackDefaultItem()
			local item = rList:getItem(i - 1)
			self:freshRListItem(item, v,winner,loser, data.ownerName)
			rList:setEnabled(false) -- 禁止滑动
        end
	end
	
    
    local roomId = rItem:getChildByName('roomId')
    if data.deskId then
        roomId:setString( data['deskId'])
    end
    local round = rItem:getChildByName('round')
    if data.round then
        round:setString(data['round'])
    end

    local base = rItem:getChildByName('base')
    if data.base then
        base:setString(data['base'])  
    end

    local arr = { '牛牛上庄', '固定庄家', '自由抢庄', '明牌抢庄', '通比牛牛', '星星牛牛', '疯狂加倍'}
    local gameplay = rItem:getChildByName('gameplay')
    if data.gameplay then
        gameplay:setString(arr[data['gameplay']])
    end

    local date = rItem:getChildByName('date')
    date:setString(os.date("%Y/%m/%d %H:%M:%S", data['time']))
end

function RecordView:freshRListItem(item, player, win, lose, ownerName)
	dump(player)
	
	local bg1 = item:getChildByName('bg1')
	local bg2 = item:getChildByName('bg2')
	local bg3 = item:getChildByName('bg3')
	local bg4 = item:getChildByName('bg4')
	bg1:setVisible(false)
	bg2:setVisible(false)
	bg3:setVisible(false)
	bg4:setVisible(false)

	if self.user.playerId == player.playerId then
		if player.result == win or player.result == lose then
			bg2:setVisible(true)
		else
			bg3:setVisible(true)
		end
	else
		if player.result == win or player.result == lose then
			bg1:setVisible(true)
		else
			bg4:setVisible(true)
		end
	end

	local head = item:getChildByName('head')
	local name =(head:getChildByName('name')):getChildByName('value')
	if player.nickName then
		name:setString(player.nickName)
	end
	
	local id =(head:getChildByName('id')):getChildByName('value')
	if player.playerId then
		id:setString(player.playerId)
	end
	
	local img = head:getChildByName('img')
	if player.avatar then
		img:retain()
		cache.get(player.avatar, function(ok, path)
			if ok then
				img:loadTexture(path)
			end
			img:release()
		end)
	end
	
	local owner = item:getChildByName('owner')
	if player.nickName == ownerName then
		owner:setVisible(true)
	end
	local top = item:getChildByName('top')
	local path = 'views/record/loser.png'	
	if player.result == win then
		path = 'views/record/winner.png'
	elseif player.result == lose then
		path = 'views/record/loser.png'	
	else
		top:setVisible(false)
	end
	
    top:loadTexture(path)

	local total =(item:getChildByName('total')):getChildByName('value')
	if player.result then
		if(player.result>=0)then
			total:setColor(cc.c3b(255,69,0))--耐火砖
			total:setString("+"..player.result)
		else
			total:setColor(cc.c3b(94,174,255))--深绿色
			total:setString(player.result)
		end
	end
end 

function RecordView:listRecords(records)
--
    dump(records)
    --local DetailedRecordTable=app.localSettings:getDetailedRecordConfigTable()
   -- dump(DetailedRecordTable[1].records[1].bottom.hand)

    local tips = self.bg:getChildByName('tips')
    if #records==0 then
        self.list:setVisible(false)
        tips:setVisible(true)
        return
    end
    
    self.list:setVisible(true)
    tips:setVisible(false)

	-- records 排序 将自己放在第一位
	-- for _, v in ipairs(records) do
	-- 	for j, w in ipairs(v.player) do
	-- 		if w.playerId == self.user.playerId and j ~= 1 then
	-- 			local temp = v.player[1]
	-- 			v.player[1] = v.player[j]
	-- 			v.player[j] = temp
	-- 		end
	-- 	end
	-- end

    local items = self.list:getItems()
    local diff = #records - #items
  
    if diff > 0 then
      for i = 1,diff do

	  	if #records[i].player > 3 then
			self.list:setItemModel(self.bg:getChildByName("row"))
		else
			self.list:setItemModel(self.bg:getChildByName("row_custom"))
		end

		self.list:pushBackDefaultItem()
      end
    else
      for _ = 1, math.abs(diff) do
        self.list:removeLastItem()
      end
    end

    for i, v in pairs(records) do
        local item = self.list:getItem(i - 1)
        self:freshRowInfo(item, v)

        local btn_info=item:getChildByName('info')
        btn_info:setTouchEnabled(true)
        btn_info:addClickEventListener(function ()
        --每一轮的数据
        self:listOnceRecords(v)
    	end)

		local btn_info=item:getChildByName('share')
        btn_info:setTouchEnabled(true)
        btn_info:addClickEventListener(function ()
        --每一轮的数据
        self:gotoSummaryShareRecord(v)
    	end)
     
    end
end

function RecordView:listOnceRecords(data)
	dump(data)

	-- 通比牛牛模式隐藏庄家
	if data.gameplay == 5 then
		self.isTBGame = true
		self.TBbase = data.base
	else
		self.isTBGame = false
	end
	self.infobg:setVisible(true)
	self.bg:setVisible(false)
	
	local rounds = data.gameRecord
	local players = data.player
	
	
	self.listView:setItemModel(self.listView:getItem(0))
	self.listView:removeAllItems()
	
	
	for i = 1, #rounds+3 do
		self.listView:pushBackDefaultItem()
	end

	for i=#rounds,#rounds+2 do
		local item = self.listView:getItem(i)
		item:setVisible(false)
	end
	
	self.listTopView:setItemModel(self.listTopView:getItem(0))
	self.listTopView:removeAllItems()
	self.ListBottomView:setItemModel(self.ListBottomView:getItem(0))
	self.ListBottomView:removeAllItems()
	
	for _ = 1, #players do	
		self.listTopView:pushBackDefaultItem()
		self.ListBottomView:pushBackDefaultItem()
	end
	
	for i, v in pairs(players) do
		local item1 = self.listTopView:getItem(i - 1)
		local item2 = self.ListBottomView:getItem(i - 1)
		self:freshNameAndResultInfo(item1, item2, v)
	end
	

	--遍历每一轮的战绩
	for i, v in pairs(data.gameRecord) do
		local item = self.listView:getItem(i - 1)
		self:freshOnceRecordRowInfo(item, v, i, players)
		local btn_moveDown = item:getChildByName('MoveDown')
		local btn_moveUp = item:getChildByName('MoveUp')
		btn_moveUp:setTouchEnabled(true)
		btn_moveDown:setTouchEnabled(true)
	
		btn_moveUp:addClickEventListener(function()
			self:adjustmentRowSize(i, data.gameRecord, v, true, players)
		end)
		
		btn_moveDown:addClickEventListener(function()
			btn_moveDown:setVisible(false)
			btn_moveUp:setVisible(true)
			self:adjustmentRowSize(i, data.gameRecord, v, true, players)
		end)
		
	end
	
	local close = self.infobg:getChildByName('close')
	close:addClickEventListener(function()
		
		self.infobg:setVisible(false)
		self.bg:setVisible(true)
		self:recoveryState(data.gameRecord)
		
	end)
end 

function RecordView:adjustmentRowSize(key, data, onceData, bool, players)
	--dump(data)
	local rowSize=self.listView:getItem(0):getContentSize()

	for i, v in ipairs(data) do
		
		local item = self.listView:getItem(i - 1)
		local listCol = item:getChildByName('ListCol')
		local image = item:getChildByName('Image')
		local pos = cc.p(item:getPosition())
		local listColSize=listCol:getContentSize()
	
		local btn_moveDown = item:getChildByName('MoveDown')
		local btn_moveUp = item:getChildByName('MoveUp')
		
		if bool then
			if i == key then	
				listCol:setVisible(true)
				listCol:setItemModel(listCol:getItem(0))
				listCol:removeAllItems()
				image:setVisible(true)
				
				btn_moveDown:setVisible(true)
				btn_moveUp:setVisible(false)
				
				local n = 1
				for k, v in pairs(players) do
					listCol:pushBackDefaultItem()
					local itemCol = listCol:getItem(n - 1)
					if onceData[v.uid] then
						self:freshOnceRecordColInfo(itemCol, onceData[v.uid])
						itemCol:setVisible(true)
					else
						itemCol:setVisible(false)
					end
					n = n + 1
				end
			else
				listCol:setVisible(false)
				image:setVisible(false)
				btn_moveDown:setVisible(false)
				btn_moveUp:setVisible(true)
			end
			
			
			if i < key then	
				self.listView:getItem(i):setPosition(0, pos.y - rowSize.height)
				
			end
			
			if i > key then
				local po = cc.p(self.listView:getItem(i - 2):getPosition())
				if i - 1 == key then
					item:setPosition(cc.p(0, po.y - listColSize.height - rowSize.height))
				else
					item:setPosition(cc.p(0, po.y - rowSize.height))
				end
			end
			
		else	
			
			self.listView:getItem(key - 1):getChildByName('ListCol'):setVisible(false)
			self.listView:getItem(key - 1):getChildByName('Image'):setVisible(false)
			
			if i > key then
				item:setPosition(cc.p(0, pos.y + listColSize.height))
			end
			
		end
		
	end
	
end 

function RecordView:recoveryState(data)

	for i, v in ipairs(data) do
        
		local item = self.listView:getItem(i - 1)

		local listCol = item:getChildByName('ListCol')
		listCol:setItemModel(listCol:getItem(0))
		listCol:removeAllItems()
		listCol:setVisible(false)

		local btn_moveDown = item:getChildByName('MoveDown')
		local btn_moveUp = item:getChildByName('MoveUp')
		btn_moveDown:setVisible(false)
		btn_moveUp:setVisible(true)

		local image = item:getChildByName('Image')
		image:setVisible(false)
	end
	
end 

function RecordView:freshNameAndResultInfo(item1,item2,playersData)
    dump(playersData)
	local textName = item1:getChildByName('Text')
	local textScore = item2:getChildByName('Text')
	
	textName:setString(playersData.nickName)
	if playersData.result>=0 then
    textScore:setString("+"..playersData.result)
	textScore:setColor(cc.c3b(255,69,0))--橙红色
	else
    textScore:setString(playersData.result)
	textScore:setColor(cc.c3b(0,128,128))--水鸭色
	end
   
end


function RecordView:freshOnceRecordRowInfo(item, data, key, players)
	
	dump(data)
	
    local listScore=item:getChildByName('ListScore')
    listScore:setItemModel(listScore:getItem(0))
    listScore:removeAllItems()

	
	local no = item:getChildByName('No')
	local noText = no:getChildByName('Text')
	noText:setString('第' .. key .. '局')
	local i = 1
	for k, v in pairs(players) do
		listScore:pushBackDefaultItem()
		local itemScore = listScore:getItem(i - 1)
		self:freshOnceRoundScore(itemScore, data[v.uid])
		i = i + 1
	end
	
end 

function RecordView:freshOnceRoundScore(item, v)
	dump(v)
	local score = item:getChildByName('Text')
	if v and v.score >= 0 then
		score:setString("+" .. v.score)
		score:setColor(cc.c3b(255,0,0))--纯红
	elseif v and v.score < 0 then
		score:setString("" ..v.score)
		score:setColor(cc.c3b(0,255,0))--酸橙色
	else
		score:setString('-')
		score:setColor(cc.c3b(255,0,0))--纯红
	end
	
end

function RecordView:getCards(cards)
	local cardsT = {}
	local i = 1
	for k, v in pairs(cards) do
		table.insert(cardsT, i, k)
		i = i + 1
	end	
	
	return cardsT
end

function RecordView:freshOnceRecordColInfo(item, data)
	dump(data)
	local cards = item:getChildByName('cards')
	local niuCnt = item:getChildByName('niuCnt')
	local banker = item:getChildByName('banker')
	local putScore = item:getChildByName('putScore')
	
	local isSpecial = (data.specialType and data.specialType > 0)

	local path = string.format('views/xydesk/result/%s.png', data.niuCnt)
	if isSpecial then
		path = string.format('views/xydesk/result/%s.png', GameLogic.getSpecialTypeByVal(data.specialType))
	end

	niuCnt:loadTexture(path)
	
	local mycards = self:getCards(data.hand)
	local result = self:findNiuniu(mycards)
	local n = 1
    local cardPos=cc.p(cards:getChildByName('card1'):getPosition()) 
	
	if result and not isSpecial then	
		for _, v in ipairs(result[1]) do
			for i, cv in ipairs(mycards) do
				if v == cv then		
					local card = cards:getChildByName('card' .. n)
					local p = self:getCardTexturePath(cv)
					card:loadTexture(p)
					n = n + 1
					table.remove(mycards, i)	
				end
			end
		end
		
		local m = 4
		for _, mv in ipairs(mycards) do	
			local card = cards:getChildByName('card' .. m)
			local nowCardPos=cc.p(card:getPosition())
			card:setPosition(cc.p(nowCardPos.x,cardPos.y+8))
			local p = self:getCardTexturePath(mv)
			card:loadTexture(p)
			m = m + 1
		end

	else
		for i, v in ipairs(mycards) do
			local card = cards:getChildByName('card' .. n)
			local p = self:getCardTexturePath(v)
			local nowCardPos=cc.p(card:getPosition())
			card:setPosition(cc.p(nowCardPos.x,cardPos.y))
			card:loadTexture(p)
			n = n + 1
		end
	end
	
	local mPath = string.format('views/xydesk/3x.png')
	local bPath = string.format('views/xydesk/i1.png')
	local gold = putScore:getChildByName('gold')
	local goldNum = putScore:getChildByName('Text')
	
	if data.nPutScore > 0 then
		goldNum:setString(data.nPutScore)
		gold:loadTexture(mPath)
		putScore:setVisible(true)
	else
		putScore:setVisible(false)
	end
	
	
	banker:loadTexture(bPath)
	if self.isTBGame then
		banker:setVisible(false)
		goldNum:setString(self.TBbase)
		gold:loadTexture(mPath)
		putScore:setVisible(true)
	else
		banker:setVisible(data.bIsBanker)
	end
	
end 

function RecordView:findNiuniu(cards)
    local niunius = {}
    local cnt = #cards
    for i = 1, cnt - 2 do
        for j = i + 1, cnt - 1 do
            for x = j + 1, cnt do
                local value = self:getCardValue(cards[i]) + self:getCardValue(cards[j]) + self:getCardValue(cards[x])
                if (value % 10) == 0 then
                    table.insert(niunius, {cards[i], cards[j], cards[x]})
                end
            end
        end
    end

    if table.empty(niunius) then
        return nil
    else
        return niunius
    end
end

function RecordView:getCardTexturePath(value)
    local suit = self.suit_2_path[self:card_suit(value)]
    local rnk = self:card_rank(value)

    local path
    if suit == 'j1' or suit == 'j2' then
         path = 'views/xydesk/cards/' .. suit .. '.png'
    else
       path = 'views/xydesk/cards/' .. suit .. rnk .. '.png'
    end

    return path
end

local SUIT_UTF8_LENGTH = 3
function RecordView:card_suit(c)
    if not c then print(debug.traceback()) end
    if c == '☆' or c == '★' then
        return c
    else
        return #c > SUIT_UTF8_LENGTH and c:sub(1, SUIT_UTF8_LENGTH) or nil
    end
end

function RecordView:card_rank(c)
    return #c > SUIT_UTF8_LENGTH and c:sub(SUIT_UTF8_LENGTH+1, #c) or nil
end

function RecordView:getCardType(type)
	if type == "♠" then
		return "h"
	elseif type == "♣" then
		return "m"
	elseif type == "♥" then
		return "z"
	elseif type == "♦" then
		return "f"
	elseif type == "★" then
		return "j1"
	elseif type == "☆" then
		return "j2"
	end
end 

function RecordView:gotoSummaryShareRecord(msg)


	print('6666666')
	dump(msg)
	-- 配record
	local gameRecord = msg['gameRecord']
	local result = {}
	local record = {}
	local numberOfGames = 1
	for i, v in ipairs(gameRecord) do
		numberOfGames = i
	end
	local winC = numberOfGames
	print(888888888)
	print(winC)

	local index = 1
	for k, v in pairs(msg['player']) do
		print(1111111111111)
		print(k)
		record[v.uid] = {winCnt = winC, loseCnt = 0, score = v['result']}
		index = index + 1
	end
	result['record'] = record
	result['over'] = true
	result['deskInfo'] = {base = msg['base'], gameplay = msg['gameplay']}
	result['ownerName'] = msg['ownerName']
	result['fsummay'] = msg['player']
	result['deskId'] = msg['deskId']
	result['autoShare'] = true
	
	print('777777')
	dump(result)

	--app:switch('XYSummaryController', result)
	--local lobbyController = require('app.controllers.LobbyController')
	--self:setWidgetAction('XYSummaryController', result)
	self.emitter:emit('shareRecord', result)
end

return RecordView
