local class = require('middleclass')
local HasSignals = require('HasSignals')
local XYDesk = class("Desk"):include(HasSignals)
local ShowWaiting = require('app.helpers.ShowWaiting')
local cardHelper = require('app.helpers.card')
local tools = require('app.helpers.tools')
local EventCenter = require("EventCenter")


function XYDesk:initialize()
    HasSignals.initialize(self)

    self.gameIdx = 29
    self.DeskName = 'niumowang'

    self.players = {}
    self.qzPlayers={}
    self.qzBei={}
    self.estimate = {}
    self.estimate.operand1 = { value = 0, idx = 0 }
    self.estimate.operand2 = { value = 0, idx = 0 }
    self.estimate.operand3 = { value = 0, idx = 0 }
    self.estimate.result = 0
    self.estimate.flag = 0

    -- watcher
    self.isPlayer = false

    self.curState = ""

    self.readyTick = 10

    self.gameTick = 10

    self.gameStart = false

    self.isInMatch = false
    self.CARDS = {
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

    self.gameOver = false

    self:listen()
end

function XYDesk:clearPlayers()
    self.players = {}
end

function XYDesk:disposeListens()
    if self.listens then
        for i = 1, #self.listens do
            self.listens[i]:dispose()
        end

        self.listens = nil
    end

    -- 注销 切换事件监听
    EventCenter.clear("app")
end

function XYDesk:bindMsgHandles()
    local app = require("app.App"):instance()
    self:disposeListens()

    -- 注册 切换事件监听
    EventCenter.register("app", function(event)
        if event then 
            -- didEnterBackground   
            -- willEnterForeground
            print(event)
            self.emitter:emit(event)
        end
    end)

    self.listens = {
        app.conn:on(self.DeskName .. '.dropLine', function(msg)
            local key = self:getPlayerPosKey(msg.uid)
            local _, player = self:getPlayerPos(msg.uid)
            if player and player.actor then
                player.actor.isLeaved = true
            end

            self.emitter:emit('dropLine', key)
        end),

        app.conn:on(self.DeskName .. ".somebodyPrepare", function(msg)
            dump(msg)

            local pos = self:getPlayerPos(msg.uid)
            local player = self:getPlayerByPos(pos)
            if player then
                -- dump(player)
                player.actor.isPrepare = true
                self.emitter:emit('somebodyPrepare', msg.uid)
            end
        end),

        app.conn:on(self.DeskName .. ".canStart", function(msg)
            dump(msg)
            self.emitter:emit('startGame', msg.b)
        end),

        app.conn:on(self.DeskName .. ".waitOwnerStart", function(msg)
            dump(msg)
            self.emitter:emit('waitOwnerStart', msg.b)
        end),


        app.conn:on(self.DeskName .. ".somebodyLeave", function(msg)
            print("somebodyLeave!!!")
            if self.gameOver then return end
            if not self.gameStart then
                local pos = self:getPlayerPos(msg.uid)
                if pos then
                    local name = self:getPlayerPosKey(msg.uid)
                    print("========>", name)
                    self.players[pos] = nil
                    self.emitter:emit('somebodyLeave', name)
                end
            end
        end),

        app.conn:on(self.DeskName .. ".responseSitdown", function(msg)
            print(self.DeskName..".responseSitdown")
            dump(msg)
            self.emitter:emit('responseSitdown', msg)
        end),

        app.conn:on(self.DeskName .. ".somebodySitdown", function(msg)
            dump(msg)
            local pos = 0
            if self.players[1] then
                local dif = msg.userData.chairIdx - self.players[1].chairIdx
                pos = dif < 0 and dif + self.info.deskInfo.maxPeople + 1 or dif + 1
                self.players[pos] = self:initPlayer(msg.userData)
                print(pos, ' <- ***************************************')
            else
                self.players[1] = self:initPlayer(msg.userData)
                pos = 1
            end
   

            if msg.userData.hand then
                if msg.userData.hand.hand then
                    self.players[1].hand = msg.userData.hand.hand
                end

                self.players[pos].hand = msg.userData.hand
            end

            local _, player = self:getPlayerPos(msg.userData.actor.uid)
            if player and player.actor then
                player.actor.isLeaved = false
            end

            self.emitter:emit('somebodySitdown', { pos = pos, userInfo = self.players[pos] })
        end),

        -- 开始牌局
        app.conn:on(self.DeskName .. '.start', function(msg)
            self.curState = "Starting"
            self.emitter:emit('stateChange')

            dump(msg)
            self.isPlaying = true
            self.gameStart = true
            self.dealted = nil
            self.info.banker = msg.banker
            self.info.played = true
            self.isInMatch = (self.isPlayer)

            local emsg = {}
            emsg.arrUid = {}

            emsg.banker = self:getPlayerPosKey(msg.banker)

            --for i, v in ipairs(self.players) do
            for i = 1, self.info.deskInfo.maxPeople do
              local v = self.players[i]
              if v then
                local uid = v.actor.uid
                if uid then
                    emsg.arrUid[#emsg.arrUid+1] = uid
                end
              end
            end

            if self.info.number + 1 <= self.info.deskInfo.round then
              self.info.number = msg.curRound or self.info.number + 1
            end
            self.emitter:emit('start', emsg)
        end),

        -- 作弊信息
        app.conn:on(self.DeskName .. '.cheat', function(msg)
            self:onCheatInfo(msg.cheatInfo)
        end),


        -- ===== 状态信息 =====

        -- 开始押注
        app.conn:on(self.DeskName .. '.StartPuting', function()
            self.curState = "PutMoney"
            self.emitter:emit('stateChange')
        end),

        -- -- 开始抢庄
        -- app.conn:on(self.DeskName .. '.qiangZhuang', function()
        --     self.curState = "PutMoney"
        -- end),

        -- 开始看牌
        app.conn:on(self.DeskName .. '.chooseCard', function()
            self.curState = "Playing"
            self.emitter:emit('stateChange')
        end),


        -- 押注
        app.conn:on(self.DeskName .. '.putMoney', function(msg)
            dump(msg)
            self:onPutMoney(msg)
        end),

        -- 刷新押注
        app.conn:on(self.DeskName .. '.somebodyPut', function(msg)
            dump(msg)
            local event = {
                name = self:getPlayerPosKey(msg.uid),
                score = msg.score
            }
            self.emitter:emit('freshSomebodyPut', event)
        end),

        -- 发牌
        app.conn:on(self.DeskName .. '.dealt', function(msg)
            dump(msg)
            self:onDealt(msg)
            self.emitter:emit('dealtover')
        end),

        -- 判断手牌是否有牛
        app.conn:on(self.DeskName .. '.choosed', function(msg)
            dump(msg)
            if msg.errorCode == 2 then
                self.emitter:emit('chooseResult', "请再认真计算一下")
            else
                self.emitter:emit('chooseFinish', { name = 'bottom', info = 'chooseFinish' })
            end
        end),

        -- 判断有人已经完成选牌
        app.conn:on(self.DeskName .. '.someBodyChoosed', function(msg)
            dump(msg)
            local posKey = self:getPlayerPosKey(msg.uid)
            local id = msg.uid
            self.emitter:emit('somebodyChooseFinish', { name = posKey, info = 'somebodyChooseFinish', uid = id, cards = msg.cards, niuCnt = msg.niuCnt , specialType = msg.specialType})
        end),

        -- 单局结算/总结算
        app.conn:on(self.DeskName .. '.summary', function(msg)
            self.curState = "Ending"
            self.emitter:emit('stateChange')

            dump(msg)
            self.isPlaying = false
            local oneRound = {}
            for k, v in pairs(msg.data) do
                local player = self.players[self:getPlayerPos(k)]
                local name = self:getPlayerPosKey(k)
                --local name = msg.data[k]
                v.hand = self:hashCountsToArray(v.hand)
                v.playerInfo = player
                oneRound[name] = v
            end

            local allRound = {}
            if msg.fsummay then
                allRound.players = msg.fsummay
                allRound.records = msg.record
                self.gameOver = true
            end
            
            dump(oneRound)
            dump(allRound)
        
            self.emitter:emit('summaryOneRound', { info = 'summaryOneRound', one = oneRound, all = allRound })


            --存储战绩数据
            --app.localSettings:setDetailedRecordConfig(oneRound)

        end),

        app.conn:on('chatInGame', function(msg)
            self.emitter:emit('chatInGame', msg)
        end),

        app.conn:on(self.DeskName .. '.overgame', function(msg)
            print(" -> @@@@@@@@@@@@@@@@@@@@@@@@")
            self.emitter:emit('overgame', msg)
        end),

        app.conn:on(self.DeskName .. '.overgameResult', function(msg)
            print(" -> #############################")
            if msg and msg.over then self.gameOver = true end 
            self.emitter:emit('overgameResult', msg)
        end),

        app.conn:on(self.DeskName .. ".qiangZhuang", function(msg)
            dump(msg)
            
            self:onQiangZhuang()
            self.curState = "QiangZhuang"
            self.emitter:emit('stateChange')
        end),

        -- 比较抢庄结果，显示新庄家
        app.conn:on(self.DeskName .. ".newBanker", function(msg)
            dump(msg)
            self.emitter:emit('newBanker', msg)
            self.qzPlayers={}
            self.qzBei={}
        end),

        -- 有人完成抢庄
        app.conn:on(self.DeskName .. ".somebodyQiang", function(msg)
            dump(msg)
            print(' -- 有人完成抢庄')
           
            if msg.number~=0 then 
            local playerP = {}
            playerP.pos = self:getPlayerPosKey(msg.uid)
            playerP.number = msg.number
            table.insert(self.qzPlayers, playerP)
            table.insert(self.qzBei, msg.number)
            end
            
            self.emitter:emit('somebodyQiang', msg)
        end),
        
        -- 押注完成，发最后一张牌
        app.conn:on(self.DeskName .. ".putOver", function(msg)
            dump(msg)
            self.emitter:emit('putOver')
        end),

        -- 托管
        app.conn:on(self.DeskName .. ".somebodyCancelTrusteeship", function(msg)
            self.emitter:emit('somebodyCancelTrusteeship', msg)
        end),

        app.conn:on(self.DeskName .. ".somebodyTrusteeship", function(msg)
            self.emitter:emit('somebodyTrusteeship', msg)
        end),
    }
end

function XYDesk:initPlayer(data)
    local player = {}
    player.actor = data.actor
    player.chairIdx = data.chairIdx
    player.isInMatch = data.isInMatch
    return player
end

function XYDesk:listen()
    local app = require("app.App"):instance()

    if self.onSynDeskHandle then
        self.onSynDeskHandle:dispose()
        self.onSynDeskHandle = nil
    end

    self.onSynDeskHandle = app.conn:on(self.DeskName .. ".synDeskData", function(msg)
        dump(msg)
        ShowWaiting.delete()
        self.info = msg.info
        self.isOwner = msg.isOwner
        self.gameOver = false

        self.players = {}
        if self.info.state then
            self.curState = self.info.state
            print("===========>syn state", self.curState)
            if self.info.state ~= 'prepare' and 
                self.info.state ~= 'Ending' 
            then
                self.gameStart = true
                self.info.played = true
            end
        else
            self.gameStart = false
        end

        if msg.myData then
            self.isPlayer = true
            self.players[1] = self:initPlayer(msg.myData)
            if msg.myData.hand then
                self.players[1].hand = msg.myData.hand.hand
                self.players[1].putScore = msg.myData.putScore
                self.players[1].choosed = msg.myData.hand.choosed
                if msg.myData.hand and msg.myData.hand.hand then
                    self.players[1].mycards = self:hashCountsToArray(msg.myData.hand.hand)
                end
            end
            local delta = self.players[1].chairIdx - 1
            local maxPeople = self.info.deskInfo.maxPeople
            --dump(self.players[1])
            self.isInMatch = msg.myData.isInMatch
        else
            self.isPlayer = false
        end

        if msg.allUsers then
            for i, v in pairs(msg.allUsers) do
                local pos = 0
                if self.players[1] == nil and i == 1 then
                    pos = 1
                else
                    local dif = v.chairIdx - self.players[1].chairIdx
                    pos = dif < 0 and dif + self.info.deskInfo.maxPeople + 1 or dif + 1
                end
                self.players[pos] = self:initPlayer(v)
                self.players[pos].hand = v.hand
            end

            -- for _, v in pairs(msg.allUsers) do
            --     local pos = self:getPlayerPosition(v.chairIdx, maxPeople, delta)
            --     self.players[pos] = self:initPlayer(v)
            --     self.players[pos].hand = v.hand
            --     -- print(' -> [ pos : ' .. pos .. '  ]')
            --     -- dump(self.players[pos])
            -- end
        end

        if msg.reload then
            self.emitter:emit('reloadData')
        else
            if self.onSynDeskCall then
                self.onSynDeskCall()
            else
                self:synXYDeskData()
                self:onCustomSwitch()
            end
            self:bindMsgHandles()
        end
    end)
end

function XYDesk:onCustomSwitch()
    app:switch('XYDeskController', self.DeskName)
end

function XYDesk:onQiangZhuang()
    self.qzPlayers = {}
    self.emitter:emit('qiangZhuang')
end

function XYDesk:onPutMoney(msg)
    self.emitter:emit('freshBettingBar', msg)
end

function XYDesk:synXYDeskData()
    local info = self.info
    dump(info)

    for k, player in pairs(self.players) do
        print(' -> k : ', k)
        dump(player)
    end
end

function XYDesk:setOnSynDeskHandel(call)
    self.onSynDeskCall = call
end

function XYDesk:somebodyTrusteeship(msg)
    if self:isMe(msg.uid) then
        local me = self:getMe()
        me.hand.trusteeship = true

        self.emitter:emit('trusteeship')
    end
end

function XYDesk:isHorsePlayer(uid)
    if self.info.horse then
        if self.info.horse.uid == uid then
            return true
        end
    end
end

-- function XYDesk:getPlayerPosition(chairIdx, maxPeople, delta)
--     local pos
--     for _, v in pairs(msg.allUsers) do
--         local dif = v.chairIdx - self.players[1].chairIdx
--         local pos = dif < 0 and dif + self.info.deskInfo.maxPeople + 1 or dif + 1
--     end

--     return chairIdx - delta
-- end

function XYDesk:getPlayerPosKey(uid)
    local pos = self:getPlayerPos(uid)

    if pos == 1 then
        return 'bottom'
    elseif pos == 2 then
        return 'left'
    elseif pos == 3 then
        return 'lefttop'
    elseif pos == 4 then
        return  'top'
    elseif pos == 5 then
        return 'righttop'
    elseif pos == 6 then
        return 'right'
    end
end

function XYDesk:getPlayerPos(uid)
    for i = 1, self.info.deskInfo.maxPeople do
    local v = self.players[i]
        if v then
            if v.actor.uid == uid then
                return i, v
            end
        end
    end
end

function XYDesk:hashCountsToArray(hash)
    local a = {}
    for k, v in pairs(hash) do
        for _ = 1, v do
          a[#a + 1] = k
        end
    end

    return a
end

function XYDesk:getCardValue(var)
    return self.CARDS[var]
end

function XYDesk:estimateNiuniu(value, msg)
    local es = self.estimate

    local state = msg.cardState
    local sign = state == 'select' and 1 or -1
    if es.flag + sign > 3 then
        return
    end
    es.flag = es.flag + sign

    local setOperand = function()
        for i = 1, 3 do
            local v = es['operand' .. i]
            if state == 'select' and (v.value == 0 and v.idx == 0) then
                v.value, v.idx = value, msg.cardPos
                break
            elseif state == 'unselect' and (v.idx == msg.cardPos and v.value == value) then
                v.value, v.idx = 0, 0
            end
        end
    end

    setOperand(es)

    -- print(" -> operand1 : ", es.operand1.value, " operand2 : ", es.operand2.value, " operand3 : ", es.operand3.value)
    es.result = es.operand1.value + es.operand2.value + es.operand3.value
end

function XYDesk:getEstimateFlag()
    return self.estimate.flag
end

function XYDesk:getEstimation()
    return self.estimate
end

function XYDesk:zeroEstimation()
    for k, v in pairs(self.estimate) do
        if type(v) == 'table' then
            v.value, v.idx = 0, 0
        else
            self.estimate[k] = 0
        end
    end

    -- dump(self.estimate)
end

function XYDesk:isNiuniu(card)
    local value = 0
    for _, v in ipairs(card) do
        value = value + self:getCardValue(v)
    end

    return (value % 10 == 0)
end

-- 得到作弊信息
function XYDesk:onCheatInfo(tabCheatInfo)
    dump(tabCheatInfo)

    -- 椅子位置

    -- 牛牛信息

    self.emitter:emit('cheatInfo', tabCheatInfo)
end

function XYDesk:onDealt(msg)
    if self.dealted then return end

    self.dealted = true
    self.info.cardsCount = msg.cardsCount

    local me = self:getMe()
    if msg.hand then
        dump(msg.hand.hand)
        me.mycards = self:hashCountsToArray(msg.hand.hand)
    end
    -- dump(me)

    local emsg = {}
    emsg.others = {}
    for i, v in ipairs(msg.other) do
        emsg.others[i] = v.uid
    end
    emsg.mycards = me.mycards
    -- dump(emsg)
    -- 发送advanced数据给控制器
    emsg.advanced = msg.advancedOption
    --dump(msg.advancedOption,"bincuoPai11111111111111")

    self.emitter:emit('dealt', emsg)
end

function XYDesk:startGame() -- luacheck:ignore
    local app = require("app.App"):instance()
    local conn = app.conn
    local msg = {
        msgID = self.DeskName .. '.prepare',
    }

    conn:send(msg)
end

function XYDesk:sitDown(deskId, buyHorse) -- luacheck:ignore
    local app = require("app.App"):instance()
    local conn = app.conn
    local msg = {
        msgID = self.DeskName .. '.sitdown',
        gameIdx = self.gameIdx,
        deskId = deskId,
        buyHorse = buyHorse,
    }

    dump(msg)

    conn:send(msg)
end

function XYDesk:prepare() -- luacheck:ignore
    local app = require("app.App"):instance()
    local conn = app.conn
    local msg = {
        msgID = self.DeskName .. '.prepare'
    }

    conn:send(msg)
end

function XYDesk:quit() -- luacheck:ignore
    local app = require("app.App"):instance()
    local conn = app.conn
    local msg = {
        msgID = self.DeskName .. '.leaveRoom'
    }
    conn:send(msg)
end

function XYDesk:getPlayerByPos(pos)
    return self.players[pos]
end

function XYDesk:getMe()
    return self.players[1]
end

function XYDesk:findNiuniu(cards)
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

function XYDesk:findNiuniuByData(cards)
    local niuniusP = {}
    local cnt = #cards
    for i = 1, cnt - 2 do
        for j = i + 1, cnt - 1 do
            for x = j + 1, cnt do
                local value = self.CARDS[cards[i]] + self.CARDS[cards[j]] + self.CARDS[cards[x]]
                if (value % 10) == 0 then
                    table.insert(niuniusP, {i, j, x})
                end
            end
        end
    end

    if table.empty(niuniusP) then
        return nil
    else
        return niuniusP
    end
end

function XYDesk:findNiuniuCnt(cards)
    local niuCnt = 0

    if cards then
        local max = 0
        for _, v in ipairs(cards) do
            max = max + self.CARDS[v]
        end

        max = max % 10
        niuCnt = max

        if niuCnt == 0 then
            niuCnt = 10
        end
    end

    return niuCnt
end

function XYDesk:checkEstimateInput()
    local es = self.estimate
    for i = 1, 3 do
        local v = es['operand' .. i]
        if v.value == 0 and v.idx == 0 then
            return false
        end
    end

    return true
end

function XYDesk:getEstimationCards()
    local cards = {}
    local es = self.estimate
    local mycards = (self:getMe()).mycards

    for i = 1, 3 do
        local v = es['operand' .. i]
        cards[i] = mycards[v.idx]
    end

    return cards
end

function XYDesk:haveNiuniu()
    local cards = self:getEstimationCards()

    -- dump(cards)

    local app = require("app.App"):instance()
    local msg = {
        msgID = self.DeskName .. '.choosed',
        cards = cards
    }
    app.conn:send(msg)
    -- self:zeroEstimation()
end

function XYDesk:noNiuniu()
    local app = require("app.App"):instance()
    local msg = {
        msgID = self.DeskName .. '.choosed',
        cards = {}
    }
    app.conn:send(msg)
    -- self:zeroEstimation()
end

function XYDesk:isGamePlaying()
    return self.isPlaying
end

function XYDesk:setGamePlaying(bool)
    self.isPlaying = bool
end

function XYDesk:answer(answer)--luacheck:ignore
  local app = require("app.App"):instance()
  local conn = app.conn
  local msg = {
    msgID = self.deskName..'.overAction',
    result = answer
  }
  conn:send(msg)
end

function XYDesk:getPlayerCnt()
  local cnt = 0
  for i = 1, self.info.deskInfo.maxPeople do
    if self.players[i] then
      cnt = cnt + 1
    end
  end

  return cnt
end

function XYDesk:cancelTrusteeship()
  local app = require("app.App"):instance()
  local conn = app.conn
  local msg = {
    msgID = self.deskName..'.cancelTrusteeship',
  }
  conn:send(msg)
end

function XYDesk:requestTrusteeship()
  local app = require("app.App"):instance()
  local conn = app.conn
  local msg = {
    msgID = self.deskName..'.requestTrusteeship',
  }
  conn:send(msg)
end

return XYDesk
