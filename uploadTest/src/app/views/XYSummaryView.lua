local cache = require('app.helpers.cache')
local app = require('app.App'):instance()

local XYSummaryView = {}

function XYSummaryView:layout(data)
    local mainPanel = self.ui:getChildByName('MainPanel')
    mainPanel:setPosition(display.cx, display.cy)
    self.MainPanel = mainPanel
    --self.MainPanel:setScale(1.15)
    local panel = mainPanel:getChildByName('Panel')
    self.panel = panel

    -- local list = panel:getChildByName('list')
    -- list:setItemModel(list:getItem(0))
    -- list:removeAllItems()
    -- self.list = list
    if data.records then
    self.records = data.records
    else
    self.records = data.record
    end
    self.ownerName = data.ownerName

    local rounds
    for _,v in pairs(self.records) do
       rounds=v.loseCnt+v.winCnt
    end

    local app = require("app.App"):instance()
  	self.user = app.session.user

    dump(data)
    self.item = panel:getChildByName('item')
    self:loadSummaryList(data)

    local deskInfo = data.deskInfo
    local roomId = panel:getChildByName('roomId')
    roomId:setString("" .. data.deskId)

    local round = panel:getChildByName('round')
    round:setString("" .. rounds)

    local base = panel:getChildByName('base')
    base:setString("" .. deskInfo.base)

    local arr = { '牛牛上庄', '固定庄家', '自由抢庄', '明牌抢庄', '通比牛牛', '星星牛牛', "疯狂加倍"}
    local gameplay = panel:getChildByName('gameplay')
    gameplay:setString("" .. arr[deskInfo.gameplay])

    local date = panel:getChildByName('date')
    date:setString(os.date("%Y/%m/%d %H:%M:%S", os.time()))
end

function XYSummaryView:getWinner(tbl)
    local score, key
    for k, v in pairs(tbl) do
        if score == nil and key == nil then
            score, key = v.score, k
        else
            if score < v.score then
                score, key = v.score, k
            end
        end
    end

    return key
end

function XYSummaryView:getloser(tbl) -- 获取土豪（输最多的人）
    local score, key
    for k, v in pairs(tbl) do
        if score == nil and key == nil then
            score, key = v.score, k
        else
            if score >= v.score then
                score, key = v.score, k
            end
        end
    end

    return key
end

function XYSummaryView:loadSummaryList(data)
    
    --local list = self.list
    
    local players
    if data.players then
    players = data.players
    else
    players = data.fsummay
    end

    local winner = self:getWinner(self.records)
    local loser = self:getloser(self.records)
    --print(" -> winner : ", winner)

    local w = 0
    for i, v in ipairs(players) do
        --list:pushBackDefaultItem()
        local item = self.item:clone()
        self.panel:addChild(item)
        self:freshItem(item, v, self.records[v.uid], winner,loser)

        local grid = self.panel:getChildByName(tostring(i))
        local gsz = grid:getContentSize()
        local gx, gy = grid:getPosition()
        item:setPosition(cc.p(gx - gsz.width / 2, gy - gsz.height / 2))
    end
end

function XYSummaryView:freshItem(item, player, record, win, lose)
	local head = item:getChildByName('head')
	local name =(head:getChildByName('namePanel')):getChildByName('name')
	name:setString(player.nickName)
	
	local id =(head:getChildByName('IDPanel')):getChildByName('id')
	id:setString(player.playerId)
	
	local img = head:getChildByName('img')
	img:retain()
	cache.get(player.avatar, function(ok, path)
		if ok then
			img:loadTexture(path)
		end
		img:release()
	end)

    local bg1 = item:getChildByName('bg1')
	local bg2 = item:getChildByName('bg2')
	local bg3 = item:getChildByName('bg3')
	local bg4 = item:getChildByName('bg4')
	bg1:setVisible(false)
	bg2:setVisible(false)
	bg3:setVisible(false)
	bg4:setVisible(false)

	if self.user.playerId == player.playerId then
		if player.uid == win or player.uid == lose then
			bg2:setVisible(true)
		else
			bg3:setVisible(true)
		end
	else
		if player.uid == win or player.uid == lose then
			bg1:setVisible(true)
		else
			bg4:setVisible(true)
		end
	end

    local owner = item:getChildByName('owner')
	if player.nickName == self.ownerName then
		owner:setVisible(true)
	end
	
	local path = 'views/record/winner.png'
	local top = item:getChildByName('top')
	if player.uid == win then
		path = 'views/record/winner.png'
	elseif player.uid == lose then
		path = 'views/record/loser.png'
	else
		top:setVisible(false)
	end
	top:loadTexture(path)
	
	local total = (item:getChildByName('total')):getChildByName('cnt')
    if record and record.score >= 0 then
        total:setColor(cc.c3b(255,69,0))
        total:setString("+"..record.score)
    elseif record and record.score < 0 then
        total:setColor(cc.c3b(94,174,255))
	    total:setString(record.score)
    else 
        item:setVisible(false)
        total:setColor(cc.c3b(178,34,34))
        total:setString("--")
    end
end


return XYSummaryView
