local Scheduler = require('app.helpers.Scheduler')
local SoundMng = require('app.helpers.SoundMng')
local tools = require('app.helpers.tools')
local HeartbeatCheck = require('app.helpers.HeartbeatCheck')
local app = require("app.App"):instance() 
local GameLogic = require('app.helpers.NNGameLogic')
local testluaj = nil
if device.platform == 'android' then
    testluaj = require('app.models.luajTest')--引入luajTest类
    print('android luaj 导入成功')
    
end


---------

local XYDeskView = {}


function XYDeskView:initialize() -- luacheck: ignore
    self.state = 'none'
    self:enableNodeEvents()
    self.num=0

    self.heartbeatCheck = HeartbeatCheck()

    self.updateF = Scheduler.new(function(dt)
        self:update(dt)
    end)

    self.suit_2_path = {
        ['♠'] = 'h',
        ['♣'] = 'm',
        ['♥'] = 'z',
        ['♦'] = 'f',
        ['★'] = 'j1',
        ['☆'] = 'j2',
    }

  self.wfName = {
        '牛牛上庄',
        '固定庄家',
        '自由抢庄',
        '明牌抢庄',
        '通比牛牛',
        '',
        '疯狂加倍',
    }

    self.kusoArr = {
        { path = 'views/xydesk/kuso/kuso1.plist',
          frame = 24, prefix = 'cjd_' },

        { path = 'views/xydesk/kuso/kuso2.plist',
          frame = 24, prefix = 'dg_' },

        { path = 'views/xydesk/kuso/kuso3.plist',
          frame = 24, prefix = 'fz_' },

        { path = 'views/xydesk/kuso/kuso4.plist',
          frame = 20, prefix = 'hpj_' },

        { path = 'views/xydesk/kuso/kuso5.plist',
          frame = 24, prefix = 'hqc_' },

        { path = 'views/xydesk/kuso/kuso6.plist',
          frame = 17, prefix = 'wen_' },

        { path = 'views/xydesk/kuso/kuso7.plist',
          frame = 20, prefix = 'zhd_' },

        { path = 'views/xydesk/kuso/kuso8.plist',
          frame = 22, prefix = 'zht_' },

        { path = 'views/xydesk/kuso/kuso9.plist',
          frame = 20, prefix = 'zj_' },
    }

    -- 作弊界面 相关状态
    self.cheatViewStatus = {
        startPos = nil, -- cc.p
        endPos = nil,   -- cc.p
        signalCount = 0,
        signalCheck = false,
    }

    self.bankerPlayedSound = false

    -- 显示庄家动画相关
    self.updateBankerFunc = nil
    self.bettingMsg = nil
end


function XYDeskView:onExit()
    if self.updateF then
        Scheduler.delete(self.updateF)
        self.updateF = nil
    end
end

function XYDeskView:update(dt)
    self:checkState()

    if self.state and self['update' .. self.state] then
        self['update' .. self.state](self, dt)
    end

    self:sendHeartbeatMsg(dt)
    self:onUpdateBanker(dt)
end

function XYDeskView:onPing()
    self.heartbeatCheck:onPing()
end

function XYDeskView:sendHeartbeatMsg(dt)
    if not self.pauseHeartbeat then
        self.heartbeatCheck:update(dt)
    end
end

function XYDeskView:setState(state)
    self.next = state
end


function XYDeskView:checkState()
    if self.next ~= self.state then
        if self['onOut' .. self.state] then
            self['onOut' .. self.state](self, self.state)
        end

        self.state = self.next

        if self.state and self['onEnter' .. self.state] then
            self['onEnter'..self.state](self, self.state)
        end
    end
end

function XYDeskView:layout(desk)
    self.desk = desk

    self.tabBtnPos = {
        left = cc.p(430.00, 181.4),
        right = cc.p(710.00, 181.4),
        middle = cc.p(565, 181.4),
    }

    local mainPanel = self.ui:getChildByName('MainPanel')
    mainPanel:setPosition(display.cx, display.cy)
    self.MainPanel = mainPanel

    self:freshRoomInfo(self.desk.info, true)

    local voice = self.MainPanel:getChildByName('voice')
    voice:addTouchEventListener(function(event, type)
        if type == 0 then
            self.emitter:emit('pressVoice')
        elseif type ~= 1 then
            self.emitter:emit('releaseVoice')
        end
    end)

    -- init cheat view
    local btn = ccui.Button:create("views/xydesk/setting.png")
    btn:setOpacity(0)
    btn:setContentSize(50, 50)
    btn:setPosition(cc.p(32,416))
    btn:setVisible(false)
    btn:setEnabled(false)
    btn:addTouchEventListener(function(sender, type)
        local checkCount = 1
        if type == 0 then
            -- begin
            self.cheatViewStatus.startPos = sender:getTouchBeganPosition()

            if self.cheatViewStatus.signalCount > checkCount then
                print("cheatview show")
                --self.emitter:emit('cheatview', true) 暂时不走contorller
                self:showCheatView(true)
            end

        elseif type == 1 then
            -- move
            local rPos = sender:getTouchMovePosition()
            local difY = self.cheatViewStatus.startPos.y - rPos.y
            if math.abs(difY) > 150 then
                self.cheatViewStatus.signalCheck = true
            end

        else
            -- end
            if self.cheatViewStatus.signalCount > checkCount then
                self.cheatViewStatus.signalCount = 0
                print("cheatview hide")
                --self.emitter:emit('cheatview', false) 暂时不走contorller
                self:showCheatView(false)
            end

            if self.cheatViewStatus.signalCheck then
                self.cheatViewStatus.signalCount = self.cheatViewStatus.signalCount + 1
                self.cheatViewStatus.signalCheck = false
                print(self.cheatViewStatus.signalCount)
            end
        end
    end)
    self.cheatBtn = btn
    self.MainPanel:addChild(self.cheatBtn, 999)


    self.tabCheatLabelPos = {
        bottom = cc.p(281,90),
        left = cc.p(400,237),
        lefttop = cc.p(471,299),
        top = cc.p(570,318),
        righttop = cc.p(668,294),
        right = cc.p(732,237),
    }
    self.tabCheatLable = {}
    for k, v in pairs(self.tabCheatLabelPos) do
        local label = cc.Label:createWithTTF("0",'views/font/fangzheng.ttf', 32)
        label:setPosition(v)
        label:setVisible(false)
        label:setColor(cc.c3b(255,255,255))
        label:setOpacity(99)
        self.tabCheatLable[k] = label
        self.MainPanel:addChild(label, 999)
    end

    -- init watcher view
    local watcherLayout = self.MainPanel:getChildByName('watcherLayout')
    self.watcherSitdownBtn = watcherLayout:getChildByName('sitdownBtn')
    self.watcherStatusSp = watcherLayout:getChildByName('statusSp')
    self.watcherLayout = watcherLayout


    -- init control view
    self.playerViews = {}
    self.playerViews.msg = self.MainPanel:getChildByName('msg')
    self.playerViews.voice = self.MainPanel:getChildByName('voice')
    --self.playerViews.prepare = self.MainPanel:getChildByName('prepare')
    --self.playerViews.gameStart = self.MainPanel:getChildByName('gameStart')
    --self.playerViews.invite = self.MainPanel:getChildByName('invite')
    self.playerViews.qzbar = self.MainPanel:getChildByName('qzbar')
    self.playerViews.sqzbar = self.MainPanel:getChildByName('sqzbar')
    
    local bottom = self.MainPanel:getChildByName('bottom')
    self.playerViews.opt = bottom:getChildByName('opt')
    self.playerViews.continue = bottom:getChildByName('continue')
    self.playerViews.input = bottom:getChildByName('input')
    self.playerViews.betting = bottom:getChildByName('betting')
    self.playerViews.qzbetting = bottom:getChildByName('qzbetting')
    self.playerViews.qzbanker = bottom:getChildByName('qzbanker')


    -- init status text
    self.statusTextBg = self.MainPanel:getChildByName('statusTextBg')
    self.statusText = self.MainPanel:getChildByName('statusText')

    -- gameSetting
	local gameSetting = self.MainPanel:getChildByName('gameSetting')
	local bg = gameSetting:getChildByName('bg')
	local leave = bg:getChildByName('leave')
    local dismiss = bg:getChildByName('dismiss')

    self.leaveBtn = leave
    self.dismissBtn = dismiss
    self.inviteBtn = self.MainPanel:getChildByName('invite')
    self.startBtn = self.MainPanel:getChildByName('gameStart')
    self.prepareBtn = self.MainPanel:getChildByName('prepare')

    if self.desk.isOwner then
        self.startBtn:setPosition(self.tabBtnPos.left)
        self.prepareBtn:setPosition(self.tabBtnPos.right)
        self.watcherSitdownBtn:setPosition(self.tabBtnPos.right)
    else
        self.startBtn:setPosition(self.tabBtnPos.left)
        self.prepareBtn:setPosition(self.tabBtnPos.middle)
        self.watcherSitdownBtn:setPosition(self.tabBtnPos.middle)
    end
    self.watcherLayout:setVisible(true)

    self.tabCardsPos = {}

    self.trusteeshipLayer = self.MainPanel:getChildByName('trusteeshipLayer')


    -- 记录所有扑克位置
    self.cardsOrgPos = {}
    local names = {'left', 'lefttop', 'top', 'righttop', 'right', "bottom"}    
    for key, val in pairs(names) do
        local seat = self.MainPanel:getChildByName(val)
        local cardsNode = seat:getChildByName('cards')
        self.cardsOrgPos[val] = {}
        for i = 1, 5 do
            local card = cardsNode:getChildByName('card' .. i)
            if val == "bottom" then
                local x, y = card:getPosition()
                self.cardsOrgPos[val][i] = cc.p(x, y)
            else
                local x, y = 65 + 60*(i - 1) , 88
                self.cardsOrgPos[val][i] = cc.p(x, y)
            end
        end
        if val == "bottom" then
            local cards_mini = bottom:getChildByName('cards_mini')
            self.cardsOrgPos['mini'] = {}
            for i = 1, 5 do
                local x, y = 65 + 60*(i - 1) , 88
                self.cardsOrgPos['mini'][i] = cc.p(x, y)
            end
        end
    end

end

-- 1:等待开始 2.等待准备
function XYDeskView:freshStatusText(bShow, textCode, cd)
    cd = cd or 9
    self.statusText:stopAllActions()

    if bShow and self.desk:isGamePlaying() then
        bShow = false
    end

    bShow = bShow or false
    self.statusTextBg:setVisible(bShow)
    self.statusText:setVisible(bShow)


    if textCode then
        local strTab =  {
            [1] = "等待房主开始游戏...",
            [2] = "等待其他玩家准备...",
            [3] = "下一盘游戏开始时间"
        }
        self.statusText:setString(strTab[textCode])
        if textCode == 3 then
            local delay = cc.DelayTime:create(1)
            local text = cc.CallFunc:create(function()
                self.statusText:setString(string.format("%s %ss", strTab[3], cd))
                cd = cd - 1
                if cd < 0 then
                    self.statusTextBg:setVisible(false)
                    self.statusText:setVisible(false)
                end
            end)
            local action = cc.Repeat:create(cc.Sequence:create(text, delay), cd)
            self.statusText:runAction(action)
        end
    end
end

-- 游戏重连，场景恢复
function XYDeskView:recoveryDesk(desk, reload)
    local info = desk.info
    local state = info.state
    local players = desk.players
    
    local played = info.played
    if not played  then return end
    
    self:freshRoomInfo(info, true)

    local banker = info.banker
    local gameplay = info.deskInfo.gameplay


    -- 刷头像信息
    for _, player in pairs(players) do
        local actor = player.actor
        local name = desk:getPlayerPosKey(actor.uid)

        if actor then
            self:freshHeadInfo(name, actor)
            self:freshSeate(name, true)
            self:freshBankerState(name, false)
            if banker and gameplay ~= 5 then
                repeat
                    if state == 'QiangZhuang' then break end
                    if gameplay == 3 or gameplay == 4 or gameplay == 7 then
                        if state == 'Starting' then break end
                        if state == 'Delay' then break end
                        if state == 'Dealing' then break end
                    end
                    -- 刷新庄家
                    local sname = desk:getPlayerPosKey(banker)
                    self:freshBankerState(sname, true)
                until true
            end
        end
    end

    -- 解散信息
    if info.overSuggest then
       self.emitter:emit('showApplyCtrl', info.overSuggest)
    end

    -- 游戏准备阶段，还没开始玩游戏
    if not state then
        for k, player in pairs(players) do
            local actor = player.actor

            if actor then
                if actor.isPrepare then
                    local name = desk:getPlayerPosKey(actor.uid)
                    self:freshReadyState(name, true)
                end
            end
        end
    end

    -- 正在玩游戏
    if state and state == 'Playing' then
        for _, player in pairs(players) do
            local actor = player.actor
            local name = desk:getPlayerPosKey(actor.uid)
            local hand = player.hand
            
            if name == "bottom" and player.isInMatch then
                -- hideOtherViews
                
                -- 自己视图
                if player.choosed then
                    if #player.choosed == 0 then
                        self:setCardsDisplay(name, true, false)
                    elseif #player.choosed == 3 then
                        self:setCardsDisplay(name, true, true)
                    end
                    if player.mycards and not table.empty(player.mycards) then
                        self:freshCardsDisplay(name, player.mycards)
                        self:showResultTip(true)
                    end
                    local score = player.putScore
                    if score then
                        self:freshBettingValue(name, score, true)
                    end
                else
                    local component = self.MainPanel:getChildByName(name)
                    local opt = component:getChildByName('opt')
                    
                    if player.mycards and not table.empty(player.mycards) then
                        if self.desk.isPlayer then
                            if reload then
                                if opt then
                                    
                                    local step1 = opt:getChildByName('step1')
                                    local step2 = opt:getChildByName('step2')
                                    if step2 and step2:isVisible() then
                                        print("================> reload show card")
                                        self:freshCardsDisplay(name, player.mycards)
                                        step1:setVisible(false)
                                    else
                                        print("================> reload  card back")
                                        step1:setVisible(true)
                                        step2:setVisible(false)
                                    end
                                end
                            else
                                print("================> step2")
                                self:freshCardsDisplay(name, player.mycards)
                                if opt then
                                    local step1 = opt:getChildByName('step1')
                                    local step2 = opt:getChildByName('step2')
                                    step1:setVisible(false)
                                    step2:setVisible(true)
                                end
                            end
                        end
                    else
                        print("================> step1")
                        if opt then
                            local step1 = opt:getChildByName('step1')
                            local step2 = opt:getChildByName('step2')
                            step1:setVisible(true)
                            step2:setVisible(false)
                        end
                    end
                end
            else
                if player.isInMatch then
                    self:setCardsDisplay(name, true, false)
                    if player.putScore then
                        self:freshBettingValue(name, player.putScore, true)
                    end
                end
            end
            --[[
            if hand then
                local choosed = hand.choosed
                if choosed then
                    print("choosedInfo", name, choosed)
                    if #choosed == 0 then
                        self:setCardsDisplay(name, true, false)
                    elseif #choosed == 3 then
                        self:setCardsDisplay(name, true, true)
                    end

                    local score = hand.putScore
                    if score then
                        self:freshBettingValue(name, score, true)
                    end
                else
                    local component = self.MainPanel:getChildByName(name)
                    local opt = component:getChildByName('opt')

                    if player.mycards and not table.empty(player.mycards) then
                        self:freshCardsDisplay(name, player.mycards)
                        if opt then
                            local step2 = opt:getChildByName('step2')
                            step2:setVisible(true)
                        end
                    else
                        if opt then
                            local step1 = opt:getChildByName('step1')
                            step1:setVisible(true)
                        end
                    end

                    local cards = component:getChildByName('cards')
                    cards:setVisible(true)

                    if player.putScore then
                        self:freshBettingValue(name, player.putScore, true)
                    end
                end
            end
            ]]
        end
    end

    local mycards = desk.players[1].mycards

    -- 正在下注
    if state and state == 'PutMoney' then
        for _, player in pairs(players) do
            local actor, hand = player.actor, player.hand
            local name = desk:getPlayerPosKey(actor.uid)

            if player.isInMatch then
                if gameplay == 4 or gameplay == 7 then
                    self:setCardsVisible(name, false)

                    if name == 'bottom' then
                        self:setPlayerCardsDisplay(name, 'front', 1, 4, mycards)
                    else
                        self:setPlayerCardsDisplay(name, 'back', 1, 4)
                    end

                    self:showCardsStatic(name, 1, 4, true)
                -- else
                --     if name == 'bottom' then
                --         self:freshCardsDisplay(name, player.mycards)
                --     end
                --     self:setCardsDisplay(name, true, false)
                end

                if hand and hand.putScore then
                    self:freshBettingValue(name, hand.putScore, true)
                end

                if name == 'bottom' and not hand.putScore then
                    --hideOtherViews

                    local cacheMsg = actor.cacheMsg
                    if cacheMsg then
                        desk.emitter:emit('freshBettingBar', cacheMsg)
                    end

                    if gameplay == 4 or gameplay == 7 then
                        desk.emitter:emit('bettingTimerStart')
                    end
                end
            end
        end
    end

    -- 正在抢庄
    if state and state == 'QiangZhuang' then
        for _, player in pairs(players) do
            if player.isInMatch then
                local actor = player.actor
                local name = desk:getPlayerPosKey(actor.uid)

                if name == 'bottom' then
                    --hideOtherViews
                end

                if gameplay == 3 then
                    if name == 'bottom' then
                        desk.emitter:emit('qiangZhuang')
                        desk.emitter:emit('qzTimerStart')
                    end
                elseif gameplay == 4 or gameplay == 7 then
                    if name == 'bottom' then
                        desk.emitter:emit('qiangZhuang')
                        desk.emitter:emit('qzTimerStart')
                        self:setPlayerCardsDisplay(name, 'front', 1, 4, mycards)
                    end

                    self:setCardsVisible(name, false)
                    self:showCardsStatic(name, 1, 4, true)
                end
            end
        end
    end

    self:freshStateViews()
end

function XYDeskView:freshStateViews(state)
    if not state then
        state = self.desk.curState
    end

    -- self:freshBettingBar(false)
    -- if self.freshQZBet then self:freshQZBet(false) end
    -- if self.freshQZBar then self:freshQZBar(false) end
    -- if self.freshSQZBar then self:freshSQZBar(false) end

    if state == 'Starting' or 
        state == 'Delay' or
        state == 'Dealing'
    then
        self:freshOpBtns(false, false)
    end
    if state == "QiangZhuang" then
        print("freshStateViews =========> QiangZhuang")
        self:freshBettingBar(false)
        --if self.freshQZBet then self:freshQZBet(false) end
        self:freshOpBtns(false, false)
    elseif state == "PutMoney" then
        print("freshStateViews =========> PutMoney")
        if self.freshQZBar then self:freshQZBar(false) end
        if self.freshSQZBar then self:freshSQZBar(false) end
        self:freshOpBtns(false, false)
    elseif state == "Playing" then
        print("freshStateViews =========> Playing")
        self:freshBettingBar(false)
        --if self.freshQZBet then self:freshQZBet(false) end
        if self.freshQZBar then self:freshQZBar(false) end
        if self.freshSQZBar then self:freshSQZBar(false) end
    elseif state == "Starting" then
        print("freshStateViews =========> Starting")
        if self.desk.info.deskInfo.gameplay ~= 4 and self.desk.info.deskInfo.gameplay ~= 7 then
            self:cardsBackToOrigin()
        end
    elseif state == "Ending" then
        print("freshStateViews =========> Ending")
        
        local player = self.desk.players[1]
        if player then
            local mycards = player.mycards
            if mycards then
                local specialOption = self.desk.info.deskInfo.special
                local specialTpye = GameLogic.getSpecialType(mycards, specialOption)
                mycards = self:groupCards('bottom', mycards, specialTpye)
                self:freshCardsDisplay('bottom', mycards)
            end
        end
        
        self.emitter:emit('stopTime')
        self:freshOpBtns(false, false)
        self:freshCuoPaiDisplay(false, nil)
    end
end

function XYDeskView:freshOpBtns(sv1, sv2)
    local component = self.MainPanel:getChildByName('bottom')
    local opt = component:getChildByName('opt')
    local step1 = opt:getChildByName('step1')
    step1:setVisible(sv1)
    local step2 = opt:getChildByName('step2')
    step2:setVisible(sv2)
end


function XYDeskView:load()
    -- body
end

function XYDeskView:freshBtnPos()
    local btnTab = {
        self.prepareBtn,
        self.startBtn,
        self.watcherSitdownBtn
    }
    local showCnt = 0
    for i, v in pairs(btnTab) do
        if v:isVisible() then
            showCnt = showCnt + 1
        end
    end
    if showCnt == 1 then
        self.startBtn:setPosition(self.tabBtnPos.middle)
        self.watcherSitdownBtn:setPosition(self.tabBtnPos.middle)
        self.prepareBtn:setPosition(self.tabBtnPos.middle)
    elseif showCnt == 2 then
        self.startBtn:setPosition(self.tabBtnPos.left)
        self.watcherSitdownBtn:setPosition(self.tabBtnPos.right)
        self.prepareBtn:setPosition(self.tabBtnPos.right)
    end
end

-- 刷新玩家交互界面
function XYDeskView:freshControlView()

    if not self.desk.isPlayer then  
        -- 旁观者
        for i, v in pairs(self.playerViews) do
            if v and v:isVisible() == true then
                v:setVisible(false)
            end
        end
        --self.watcherLayout:setVisible(true)
        
        local isFull =  self.desk:getPlayerCnt() == self.desk.info.deskInfo.maxPeople
        self:freshWatcherBtn(not isFull)

        self.inviteBtn:setVisible(true)

        self:freshWatcherSp(false)


        if self.desk.isOwner then
            self.startBtn:setVisible(true)
        else
            self.startBtn:setVisible(false)
        end

        if self.desk:isGamePlaying() then
            --self:freshWatcherBtn(false)
            self:freshWatcherSp(true)
            self.inviteBtn:setVisible(false)
            self:freshContinue(false)
        end

        self.leaveBtn:setEnabled(true)

        if self.desk.isOwner and  not self.desk.info.played then
            self.dismissBtn:setEnabled(true)
        else
            self.dismissBtn:setEnabled(false)
        end

    else
        -- 玩家        
        if self.desk.isOwner then
            self.startBtn:setVisible(true)
        else
            self.startBtn:setVisible(false)
        end

        if self.desk:isGamePlaying() then
            self.startBtn:setVisible(false)
            self.prepareBtn:setVisible(false)
            self:freshContinue(false)
        end
        
        self:freshWatcherBtn(false)
        self:freshWatcherSp(false)
    end

    if self.desk.info.played then
        self.startBtn:setVisible(false)
    end

    self:freshBtnPos()
    self:freshStateViews()
end

function XYDeskView:freshWatcherSp(bShow)
    bShow = bShow or false
    self.watcherStatusSp:setVisible(bShow)
end

function XYDeskView:freshWatcherBtn(bShow)
    bShow = bShow or false
    self.watcherSitdownBtn:setVisible(bShow)
end

function XYDeskView:freshRoomInfo(data, bool)
    local topbar = self.MainPanel:getChildByName('topbar')
    local info = topbar:getChildByName('info')
    dump(data)
    local roomid = info:getChildByName('roomid')
    roomid:setString("房号:" .. data.deskId)

    local gameplay = info:getChildByName('gameplay')
    gameplay:setString("庄位:" .. self.wfName[data.deskInfo.gameplay])

    local base = info:getChildByName('base')
    local tabBaseStr = {
        ['2/4'] = '1, 2, 3',
        ['4/8'] = '4, 6, 8',
        ['5/10'] = '6, 8, 10',
    }
    local baseStr = tabBaseStr[data.deskInfo.base] or data.deskInfo.base
    base:setString("底分:" .. baseStr)

    local round = info:getChildByName('round')
    round:setString("局数:" .. data.number .. "/" .. data.deskInfo.round)
    if self.desk.curState and self.desk.curState == "Ending" then
        round:setString("局数:" .. tostring(data.number-1) .. "/" .. data.deskInfo.round)
    end

    self.outerFrameBool=false

    info:setVisible(bool)

    if self.wfName[data.deskInfo.gameplay] == '通比牛牛' then 
        if data.deskInfo.advanced[2] == 2 then
            -- 隐藏禁止搓牌
            self.MainPanel:getChildByName('bottom'):getChildByName('opt'):getChildByName('step1'):getChildByName('cuo'):setVisible(false)
        end

    else
        dump(data.deskInfo.advanced[3],'date.deskInfo.advanced[3] 3333333333')
        if data.deskInfo.advanced[3] == 3 then
            -- 隐藏禁止搓牌
            self.MainPanel:getChildByName('bottom'):getChildByName('opt'):getChildByName('step1'):getChildByName('cuo'):setVisible(false)
        end
    end

    local net = topbar:getChildByName('net')
    local battery_B = topbar:getChildByName('battery_B')
    local battery_F = topbar:getChildByName('battery_F')
    local time = topbar:getChildByName('time')
    local getTime = os.date('%X');
    print("当前时间为  " .. getTime)
    time:setString(string.sub(getTime,1,string.len(getTime)-3))
    if testluaj then
        print('android 1111111111111111111111111111111111111111111111111111111111') 
        -- "getNetInfo"
        --local ok netInfo = self.luaj.callStaticMethod(javaClassName, javaMethodName, args, javaMethodSig)
        --在这里尝试调用android static代码
        local testluajobj = testluaj.new(self)
        local ok, ret1 = testluajobj.callandroidWifiState(self);
        if ok then
            print("android 网络信号强度为  " .. ret1)
        end
        if ret1 == 21 then
            net:loadTexture("views/lobby/Wifi2.png" )
        elseif ret1 == 22 then
            net:loadTexture("views/lobby/Wifi3.png" )
        elseif ret1 == 23 then
            net:loadTexture("views/lobby/Wifi4.png" )
        elseif ret1 == 24 then
            net:loadTexture("views/lobby/Wifi4.png" )
        elseif ret1 == 25 then
            net:loadTexture("views/lobby/Wifi4.png" )
        elseif ret1 == 11 then
            net:loadTexture("views/lobby/4g2.png" )
        elseif ret1 == 12 then
            net:loadTexture("views/lobby/4g3.png" )
        elseif ret1 == 13 then
            net:loadTexture("views/lobby/4g4.png" )
        elseif ret1 == 14 then
            net:loadTexture("views/lobby/4g4.png" )
        elseif ret1 == 15 then
            net:loadTexture("views/lobby/4g4.png" )
        end
        local ok, ret2 = testluajobj.callandroidBatteryLevel(self);
        if ok then
            print("android 电量为  " .. ret2)
            local w = battery_F:getContentSize().width * ret2 / 100
            local h = battery_F:getContentSize().height
            battery_B:setContentSize(w,h)
        end
    
    elseif device.platform == 'ios' then
        local luaoc = nil
        luaoc = require('cocos.cocos2d.luaoc')
        if luaoc then
            local ok, battery = luaoc.callStaticMethod("AppController", "getBattery",{ww='dyyx777777'})
            if ok then
                print("ios 电量为  " .. battery)
                local w = battery_F:getContentSize().width * battery / 100
                local h = battery_F:getContentSize().height
                battery_B:setContentSize(w,h)
            end
            -- 1，2，3，5 分别对应的网络状态是2G、3G、4G及WIFI

            local ok, netType = luaoc.callStaticMethod("AppController", "getNetworkType",{ww='dyyx777777'})
            if ok then
                print("ios 信号类型为  " .. netType)
                if netType == 1 or netType == 2 or netType == 3 then
                    net:loadTexture("views/lobby/4g4.png" )
                elseif netType == 5 then
                    net:loadTexture("views/lobby/Wifi4.png" )
                end
            end
        end
    end

end

-- ====== cheatView ======

function XYDeskView:freshCheatView(msg)
    if self.cheatBtn then
        self.cheatBtn:setVisible(true)
        self.cheatBtn:setEnabled(true)
        
        local spTab = {
            WUXIAO = '五小',
            BOOM = '炸弹',
            HULU = '葫芦',
            WUHUA_J = '五花',
            WUHUA_Y = -1,
            TONGHUA = '同花',
            STRAIGHT = '顺子',
        }
        local specialOption = self.desk.info.deskInfo.special


        for k, v in pairs(msg) do
            local posKey = self.desk:getPlayerPosKey(k)
            local cards = v.tabCards
            -- 特殊牌
            local specialType, name = GameLogic.getSpecialType(cards, specialOption)
            -- 牛牛
            local cnt = 0
            local niuniuP = self.desk:findNiuniu(cards)
            if niuniuP then
                cnt = self.desk:findNiuniuCnt(cards)
            end
            
            -- local result = self.desk:findNiuniu(cards)
            local cheatStr = "--"
            if specialType > 0 then
                cheatStr = spTab[name] or '特殊牌'
            elseif niuniuP then
                cheatStr = string.format( "%s", cnt)
            end
            if self.tabCheatLable[posKey] then
                self.tabCheatLable[posKey]:setString(cheatStr)
            end
        end
    end
end

function XYDeskView:showCheatView(bShow, key)
    bShow = bShow or false
    key = key or false
    if key then
        self.tabCheatLable[key]:setVisible(true)
    else
        for k, v in pairs(self.tabCheatLable) do
            v:setVisible(bShow)
        end
    end
end


--显示庄家
function XYDeskView:freshBankerState(name, bool, msg)
    local component = self.MainPanel:getChildByName(name)
    if not component then
        return
    end

    local component = self.MainPanel:getChildByName(name)
    if not component then
        return
    end
    self.banker = name

    -- dump(self.desk.qzPlayers)
    -- dump(self.desk.qzBei)

    local gameplay = self.desk.info.deskInfo.gameplay
    if (gameplay == 3 or gameplay == 4 or gameplay == 7) and bool and msg then

        if not self.updateBankerFunc then
            self.updateBankerFunc = self:setBankerAnimation(name, msg)
        elseif not self.updateBankerFunc() then
            self.updateBankerFunc = self:setBankerAnimation(name, msg)
        end
    else
        local avatar = component:getChildByName('avatar')
        local banker = avatar:getChildByName('banker')
        banker:setVisible(bool)
        local frame = avatar:getChildByName('frame')
        local outerFrame = frame:getChildByName('outerFrame')    
        outerFrame:setVisible(bool)
    end

end 


function XYDeskView:freshReadyState(name, bool)
    local component = self.MainPanel:getChildByName(name)
    if not component then
        return
    end

    local avatar = component:getChildByName('avatar')
    local ready = avatar:getChildByName('ready')
    ready:setVisible(bool)
end

function XYDeskView:freshDropLine(name, bool)
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')
    local dropLine = avatar:getChildByName('dropLine')
    dropLine:setVisible(bool)
end

function XYDeskView:hideHeadInfo(name)
    local component = self.MainPanel:getChildByName(name)
    if not component then return end
    local avatar = component:getChildByName('avatar')

    local frame = avatar:getChildByName('frame')
    local headimg = frame:getChildByName('headimg')
    headimg:setVisible(false)
    frame:setVisible(false)

    local point = avatar:getChildByName('point')
    local value = point:getChildByName('value')
    value:setString('')

    local playername = avatar:getChildByName('playername')
    local value = playername:getChildByName('value')
    value:setString('')

    avatar.data = nil
    frame:addClickEventListener(function() end)
end

function XYDeskView:freshSeate(name, bool)
    local component = self.MainPanel:getChildByName(name)
    component:setVisible(bool)
end

function XYDeskView:freshHeadInfo(name, data)
    local component = self.MainPanel:getChildByName(name)
    if not component then
        return
    end


    local avatar = component:getChildByName('avatar')

    local frame = avatar:getChildByName('frame')
    frame:setVisible(true)
    local headimg = frame:getChildByName('headimg')

    if data then
        headimg:retain()
        local cache = require('app.helpers.cache')
        cache.get(data.avatar, function(ok, path)
            if ok then
                headimg:show()
                headimg:loadTexture(path)
            end
            headimg:release()
        end)
    else
        headimg:loadTexture('views/public/tx.png')
    end

    local point = avatar:getChildByName('point')
    local value = point:getChildByName('value')
    if data then
        value:setString(tostring(data.money))
    else
        value:setString('')
    end

    local playername = avatar:getChildByName('playername')
    value = playername:getChildByName('value')
    if data then
        value:setString(data.nickName)
    else
        value:setString('')
    end

    avatar.data = data
    if data then
        avatar.data.clickSender = self.desk.players[1].actor.uid
        frame:addClickEventListener(function()
            self.emitter:emit('clickHead', avatar.data)
        end)
    else
       frame:addClickEventListener(function() end)
    end
end



function XYDeskView:freshCardsAction(name, advanced)
    local component = self.MainPanel:getChildByName(name)
    if not component then
        return
    end

    local delay, duration, offset = 0.3, 0.3, 0.15
    local cards = component:getChildByName('cards')
    cards:setVisible(true)

    for i = 1, 5 do
        local card = cards:getChildByName('card' .. i)
        
        -- 使用原始坐标
        local orgPos = self.cardsOrgPos[name][i]

        local pos = cards:convertToNodeSpace(cc.p(display.cx, display.cy))
        card:setPosition(pos.x, pos.y)

        delay = delay + offset
        local dtime = cc.DelayTime:create(delay)
        local move = cc.MoveTo:create(duration, orgPos)
        local show = cc.Show:create()
        local eft = cc.CallFunc:create(function()
            SoundMng.playEft('desk/fapai.mp3')
        end)
        local callBack = cc.CallFunc:create(function()
            if i == 5 then
                self:cardsBackToOriginSeat(name)
            end
            card:setScale(1)
            card:setVisible(true)
        end)
        if name == 'bottom' then
            callBack = cc.CallFunc:create(function()
                if i == 5 then
                    self:cardsBackToOriginSeat(name)
                    local opt = component:getChildByName('opt')
                    local step1 = opt:getChildByName('step1')
                    step1:setVisible(true)
                    self:freshStateViews()
                end
                card:setScale(1)
                card:setVisible(true)
            end)
        end
        local sequence = cc.Sequence:create(dtime, show, eft, move, callBack)
        card:stopAllActions()
        
        card:setVisible(false)
        card:runAction(sequence)

        local sc = cc.ScaleTo:create(duration, 1.0)
        local sq = cc.Sequence:create(dtime, sc)
        card:setScale(0.7)
        card:runAction(sq)
        -- if name == 'bottom' then
        --     local callback = function()
        --         local opt = component:getChildByName('opt')
        --         local step1 = opt:getChildByName('step1')
        --         step1:setVisible(true)
        --         self:freshStateViews()
        --         if i == 5 then
        --             self:cardsBackToOrigin()
        --         end
        --     end

        --     local dt = cc.DelayTime:create(0.3)
        --     local sc = cc.ScaleTo:create(delay, 1.0)
        --     local sq = cc.Sequence:create(sc, dt, cc.CallFunc:create(callback))
        --     card:setScale(0.7)
        --     card:runAction(sq)
        -- end
    end
end

function XYDeskView:dispalyCuoPai(name)

    local component = self.MainPanel:getChildByName(name)
    if name ~= 'bottom' then
        local avatar = component:getChildByName('avatar')
        local cuoPai = avatar:getChildByName('cuoPai')
        cuoPai:setVisible(true)

        -- 创建动画  
        local animation = cc.Animation:create()  
        for i = 1, 6 do    
            local name = "views/xydesk/result/cuo"..i..".png"  
            -- 用图片名称加一个精灵帧到动画中  
            animation:addSpriteFrameWithFile(name)  
        end  
        -- 在1秒内持续4帧  
        animation:setDelayPerUnit(1 /4)  
        -- 设置"当动画结束时,是否要存储这些原始帧"，true为存储  
        animation:setRestoreOriginalFrame(true)  
        
        -- 创建序列帧动画  
        local action = cc.Animate:create(animation)  

        cuoPai:runAction(cc.RepeatForever:create( action ))
    end

end

local SUIT_UTF8_LENGTH = 3

function XYDeskView:card_suit(c)
    if not c then print(debug.traceback()) end
    if c == '☆' or c == '★' then
        return c
    else
        return #c > SUIT_UTF8_LENGTH and c:sub(1, SUIT_UTF8_LENGTH) or nil
    end
end

function XYDeskView:card_rank(c)
    return #c > SUIT_UTF8_LENGTH and c:sub(SUIT_UTF8_LENGTH+1, #c) or nil
end

function XYDeskView:setCardsDisplay(name, visible, isFinish)
    local component = self.MainPanel:getChildByName(name)
    if not component then return end

    local cards = component:getChildByName('cards')
    if name == 'bottom' and isFinish then 
        cards:setVisible(false)
    else
        cards:setVisible(visible)
    end
    
    self:freshCheckState(name, { info = 'chooseFinish' }, isFinish)
end

function XYDeskView:getCardTexturePath(value)
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

function XYDeskView:freshCardsDisplay(name, data)
    local component = self.MainPanel:getChildByName(name)
    if not component or not data then
        return
    end

    local cards = component:getChildByName('cards')
    local mycards = data
    for i, v in ipairs(mycards) do
        local card = cards:getChildByName('card' .. i)
        local suit = self.suit_2_path[self:card_suit(v)]
        local rnk = self:card_rank(v)

        local path
        if suit == 'j1' or suit == 'j2' then
            path = 'views/xydesk/cards/' .. suit .. '.png'
            --print(" -> [" .. i .. "] suit : ", suit)
        else
            --print(" -> [" .. i .. "] suit : ", suit, "rnk : ", rnk)
            path = 'views/xydesk/cards/' .. suit .. rnk .. '.png'
        end
        --print(" -> card display : ", path)
        card:loadTexture(path)
        -- print(" -> freshCardsDisplay path : ", path)
    end
end

function XYDeskView:freshMiniCards(bool, data)
    local component = self.MainPanel:getChildByName('bottom')
    local cards = component:getChildByName('cards_mini')
    if not bool then
        cards:setVisible(false)
        return
    end

    if not component or not data then
        return
    end

    local mycards = data
    for i, v in ipairs(mycards) do
        local card = cards:getChildByName('card' .. i)
        local suit = self.suit_2_path[self:card_suit(v)]
        local rnk = self:card_rank(v)

        local path
        if suit == 'j1' or suit == 'j2' then
            path = 'views/xydesk/cards/' .. suit .. '.png'
            --print(" -> [" .. i .. "] suit : ", suit)
        else
            --print(" -> [" .. i .. "] suit : ", suit, "rnk : ", rnk)
            path = 'views/xydesk/cards/' .. suit .. rnk .. '.png'
        end
        --print(" -> card display : ", path)
        card:loadTexture(path)
        -- print(" -> freshCardsDisplay path : ", path)
    end
    cards:setVisible(true)
end

function XYDeskView:freshEstimateResult(data)
    local component = self.MainPanel:getChildByName('bottom')
    local input = component:getChildByName('input')
    local result = input:getChildByName('result')
    result:setString(data.result == 0 and "" or tostring(data.result))

    for i = 1, 3 do
        local op = input:getChildByName('op' .. i)
        local operand = data['operand' .. i]
        op:setString(operand.value == 0 and "" or tostring(operand.value))
    end
end

function XYDeskView:clearInput()
    local component = self.MainPanel:getChildByName('bottom')
    local opt = component:getChildByName('opt')
    local step1 = opt:getChildByName('step1')
    local step2 = opt:getChildByName('step2')

    step1:setVisible(false)
    step2:setVisible(false)

    local data = {
        operand1 = { value = 0, idx = 0 },
        operand2 = { value = 0, idx = 0 },
        operand3 = { value = 0, idx = 0 },
        result = 0
    }
    self:freshEstimateResult(data)
end

local mulArr = {
    { ['10'] = '4', ['9'] = '3', ['8'] = '2', ['7'] = '2' },

    { ['10'] = '3', ['9'] = '2', ['8'] = '2' }
}

function XYDeskView:freshCheckState(name, msg, bool)
    local component = self.MainPanel:getChildByName(name)

    -- 停止并隐藏搓牌动画
    if name ~= 'bottom' then
        local avatar = component:getChildByName('avatar')
        local cuoPai = avatar:getChildByName('cuoPai')
        cuoPai:stopAllActions()
        cuoPai:setVisible(false)
    end

    local check = component:getChildByName('check')
    local valueSp = check:getChildByName('value')
    local num = check:getChildByName('num')
    if msg.info ~= 'somebodyChooseFinish' then
        num:setVisible(false)
    end

    local wc = check:getChildByName('wc')
    wc:setVisible(false)

    local fmt = 'views/xydesk/result/%s.png'
    local path
    --if msg.info == 'chooseFinish' or msg.info == 'somebodyChooseFinish' then
    if msg.info == 'somebodyChooseFinish' then
        --path = 'views/xydesk/result/wc1.png'
        print(1212121212)
        dump(msg)
        if msg.cards then
            local isSpecial = (msg.specialType and msg.specialType > 0)
            msg.cards = self:groupCards(name, msg.cards, msg.specialType)

            self:freshCardsDisplay(name, msg.cards)

            path = 'views/xydesk/result/' ..msg.niuCnt .. '.png'
            if isSpecial then
                path = 'views/xydesk/result/' .. GameLogic.getSpecialTypeByVal(msg.specialType) .. '.png'
            end

            self:freshMulNum(name, true, msg.niuCnt, msg.specialType)
            self:freshFireworks(name, true, msg.niuCnt, msg.specialType)

            -- 播放牛几声音
            --local n = sex == 0 and 'man' or 'woman'
            local soundPath = 'cscompare/' .. tostring('f'..msg.sex.."_nn" .. msg.niuCnt .. '.mp3')
            if isSpecial then
                soundPath = 'cscompare/' .. tostring('f'..msg.sex.."_nn" .. GameLogic.getSpecialTypeByVal(msg.specialType) .. '.mp3')
            end
            SoundMng.playEftEx(soundPath)
        else
            path = 'views/xydesk/result/wc1.png'
            -- 旁观者逻辑
            if not self.desk.isPlayer then
                path = 'views/xydesk/result/wc1.png'
                valueSp:loadTexture(path)
                check:setVisible(true)
                num:setVisible(false)
                return
            end

            if name == 'bottom' and self.banker == 'bottom' then
                check:setVisible(bool)
                self:freshFireworks(name, false)
                return
            else
                check:setVisible(bool)
                num:setVisible(false)
                valueSp:setVisible(false)
                wc:setVisible(true)
                return
            end
        end
        
    elseif msg.info == 'chooseFinish' then
        path = 'views/xydesk/result/wc1.png'

    elseif msg.info == 'summaryOneRound' or msg.info == 'resultTip' then
        local isSpecial = (msg.specialType and msg.specialType > 0)
        path = 'views/xydesk/result/' .. msg.niuCnt .. '.png'
        if isSpecial then
            path = 'views/xydesk/result/' .. GameLogic.getSpecialTypeByVal(msg.specialType) .. '.png'
        end
        
        self:freshMulNum(name, true, msg.niuCnt, msg.specialType)
        self:freshFireworks(name, true, msg.niuCnt, msg.specialType)

        local sex = nil
        local niuCnt = nil
        local soundPath = nil
        local playEft = false

        if msg.info == 'resultTip' and 
            msg.bIsBanker and not msg.reload 
            then
            sex = msg.sex
            niuCnt = msg.niuCnt
            self.bankerPlayedSound = true
            playEft = true

        elseif msg.info == 'summaryOneRound' and 
            self.desk.info.deskInfo.gameplay ~= 5 and 
            msg.bIsBanker
            then
            if not self.bankerPlayedSound then 
                sex = msg.playerInfo.actor.sex
                niuCnt = msg.niuCnt
                playEft = true
            end
            self.bankerPlayedSound = false
        end

        if isSpecial then
            niuCnt = GameLogic.getSpecialTypeByVal(msg.specialType)
        end

        if playEft then
            soundPath = 'cscompare/' .. tostring('f'..sex.."_nn" .. niuCnt .. '.mp3')
            SoundMng.playEftEx(soundPath)
        end
    end
    print(" -> niuCnt : ", path)
    valueSp:loadTexture(path)
    valueSp:setVisible(bool)
    check:setVisible(bool)
end

function XYDeskView:freshFireworks(name, bool, niu, special)
    local component = self.MainPanel:getChildByName(name)
    local check = component:getChildByName('check')
    local yellow = check:getChildByName('teshupaiYellow')
    local red = check:getChildByName('teshupaiRed')
    local xingxing = check:getChildByName('xingxing')

    yellow:stopAllActions()
    red:stopAllActions()
    yellow:setVisible(false)
    red:setVisible(false)
    xingxing:setVisible(false)
    xingxing:stopAllActions()

    if not bool then return end
    if niu == 0 and special == 0 then return end

    local node = yellow 
    local action = cc.CSLoader:createTimeline("views/animation/Teshupai.csb")
    if special > 0 then
        node = red
        action = cc.CSLoader:createTimeline("views/animation/Teshupai1.csb")
    end

    local xxAction = cc.CSLoader:createTimeline("views/animation/xingxing.csb")
    xxAction:gotoFrameAndPlay(0, true)
    xingxing:setVisible(true)
    xingxing:runAction(xxAction)

    action:gotoFrameAndPlay(0, false)
    action:setTimeSpeed(0.8)
    
    node:runAction(action)
    node:setVisible(true)
end

-- 在用户头像显示抢（不抢）
function XYDeskView:freshQZBet(name, num, bool)
	local component = self.MainPanel:getChildByName(name)
	local avatar = component:getChildByName('avatar')
	
	local qzBet = avatar:getChildByName('qzBet')
	local qz = qzBet:getChildByName('qz')
    local bq = qzBet:getChildByName('bq')
	local path = 'views/xydesk/result/qiang/'

    bq:setVisible(false)
    qz:setVisible(false)	
	if num == 0 then
		bq:setVisible(true)
    else
        qz:loadTexture(path..num..'.png')
        qz:setVisible(true)
	end

	qzBet:setVisible(bool)
end 

function XYDeskView:hideQZBet()
    local players = self.desk.players
    for _, v in pairs(players) do
        local uid = v.actor.uid
        local name = self.desk:getPlayerPosKey(uid)
        self:freshQZBet(name, 0, false)
    end
end 

function XYDeskView:freshSummaryOneRound(name, data, bool, tobi)
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')


    if (not self.desk.isPlayer) and name == "bottom" then
        local cards, idx = {}, 1
        for _, v in ipairs(data.hand) do
            cards[idx] = v
            idx = idx + 1
        end
    
        local specialOption = self.desk.info.deskInfo.special
        local specialTpye = GameLogic.getSpecialType(cards, specialOption)
        cards = self:groupCards(name, cards, specialTpye)
        self:freshCardsDisplay(name, cards)
    end

    if name then
        -- 显示手牌
        local cards, idx = {}, 1
        for _, v in ipairs(data.hand) do
            cards[idx] = v
            idx = idx + 1
        end
        local specialOption = self.desk.info.deskInfo.special
        local specialTpye = GameLogic.getSpecialType(cards, specialOption)
        cards = self:groupCards(name, cards, specialTpye)
        self:freshCardsDisplay(name, cards)
    end

    local bankerSeat = self.desk:getPlayerPosKey(self.desk.info.banker)


    local function freshScore()
        if self.desk.curState and self.desk.curState == 'Ending' then
            self:freshOneRoundScore(name, bool, data.score)
        end
        self:freshAllRoundScore(name, data.money)
    end

    -- 不是通比牛牛模式下执行金币飞动画 
    if not tobi then
        if  self.banker ~= name then
            if data.score > 0 then
                --print(' *** -> [ ', bankerSeat .. ' TO ' .. name .. ' ]')
                self:coinFlyAction(self.banker, name, self.banker, 1.2, freshScore)
            else
                --print(' *** -> [ ', name .. ' TO ' .. bankerSeat .. ' ]')
                self:coinFlyAction(name, self.banker, self.banker, 0, freshScore)
            end
        else
            local delay = cc.DelayTime:create(1.2)
            local Sequence = cc.Sequence:create(delay, cc.CallFunc:create(freshScore))
            self:runAction(Sequence)
        end
    else
        self:freshAllRoundScore(name, data.money)
        self:freshOneRoundScore(name, bool, data.score)
    end

    -- 显示牛牛
    local msg = { 
        info = 'summaryOneRound', 
        niuCnt = data.niuCnt , 
        specialType = data.specialType,
        bIsBanker = data.bIsBanker,
        playerInfo = data.playerInfo
        }
    self:freshCheckState(name, msg, bool)

  
end

-- 总得分
function XYDeskView:freshAllRoundScore(name, score)
    score = score or 0
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')

    local point = avatar:getChildByName('point')
    local value = point:getChildByName('value')
    value:setString(score)
end

-- 当局得分
function XYDeskView:freshOneRoundScore(name, bool, score)
    score = score or 0
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')
    local result = avatar:getChildByName('result')

    if not bool then
        result:setVisible(false)
        return
    end

    local zheng = result:getChildByName('zheng')
    local fu = result:getChildByName('fu')
    zheng:setVisible(false)
    fu:setVisible(false)

    if score > 0 then
        zheng:getChildByName('value'):setString(math.abs(score))
        zheng:getChildByName('sign'):setVisible(true)
        zheng:setVisible(true)
    else
        fu:getChildByName('sign'):setVisible(score ~= 0)
        fu:getChildByName('value'):setString(math.abs(score))
        fu:setVisible(true)
    end

    result:setVisible(true)
end

-- 当局得分
function XYDeskView:freshOneRoundScore_bak(name, bool, score)
    score = score or 0
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')

    -- 显示本局得分
    local result = avatar:getChildByName('result')
    local bg = result:getChildByName('bg')
    local path
    if score > 0 then
        path = 'views/xydesk/numbers/H/hg.png'
    else
        path = 'views/xydesk/numbers/L/lg.png'
    end
    bg:loadTexture(path)

    local imgPath
    if score > 0 then
        imgPath = 'views/xydesk/numbers/H/hj.png'
    else
        imgPath = 'views/xydesk/numbers/L/ljn.png'
    end
    local img = result:getChildByName('img')
    img:loadTexture(imgPath)

    local svalue = result:getChildByName('value')
    if score > 0 then
        svalue:setProperty('0123456789', 'views/xydesk/numbers/a1.png', 20, 27, '0')
    else
        svalue:setProperty('0123456789', 'views/xydesk/numbers/a2.png', 20, 27, '0')
    end
    svalue:setString(math.abs(score))
    result:setVisible(bool)
end

function XYDeskView:freshContinue(bool)
    local component = self.MainPanel:getChildByName('bottom')
    local continue = component:getChildByName('continue')
    continue:setVisible(bool)
end

function XYDeskView:freshBettingBar(bool, msg)
    local component = self.MainPanel:getChildByName('bottom')
    local betting = component:getChildByName('betting')
    betting:setScrollBarEnabled(false)

    local function hideAllBtn()
        for i = 1, 4 do
            local btn = betting:getChildByName(tostring(i))
            btn:setVisible(false)
        end
    end

    hideAllBtn()

    if bool then
        if msg and msg.putInfo then
            local len = #msg.putInfo
            

            for k, v in pairs(msg.putInfo) do
                local btn = betting:getChildByName(tostring(k))
                btn:setVisible(true)
                local val = btn:getChildByName('val')
                val:setString(v)

                btn:addClickEventListener(function()
                    self.emitter:emit('clickBet', v)
                end)
            end
            
            local item = betting:getChildByName(tostring(1))
            local margin = betting:getItemsMargin()
            local cnt = len
            local itemWidth = item:getContentSize().width * item:getScaleX()
            local listWidth = (itemWidth*cnt) + (margin*(cnt-1))
            local posX = display.cx - (listWidth/2)
            betting:setPositionX(posX)

        end
    end

    betting:setVisible(bool)
end

function XYDeskView:freshBettingBar_bak(bool, msg)
    local component = self.MainPanel:getChildByName('bottom')
    local betting = component:getChildByName('betting')
    local btSz = betting:getContentSize()
    print(" -> XYDeskView:freshBettingBar ********************")
    if bool then
        if msg and msg.putInfo then
            local len = #msg.putInfo
            local posArr
            if len == 2 then
                posArr = { 61, 226 }
            elseif len == 3 then
                posArr = { -26, 143.5, 308 }
            end

            for k, v in pairs(msg.putInfo) do
                local btn = betting:getChildByName(tostring(k))
                local posY = btn:getPositionY()
                btn:setPosition(cc.p(posArr[k], posY))
                btn:setVisible(true)
                local val = btn:getChildByName('val')
                val:setString(v)

                btn:addClickEventListener(function()
                    self.emitter:emit('clickBet', v)
                end)
            end
        end
    else
        betting:getChildByName('1'):setVisible(false)
        betting:getChildByName('2'):setVisible(false)
        betting:getChildByName('3'):setVisible(false)
    end

    betting:setVisible(bool)
end

function XYDeskView:clearDesk(name)
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')
    local result = avatar:getChildByName('result')
    result:setVisible(false)

    local multiple = avatar:getChildByName('multiple')
    multiple:setVisible(false)

    local check = component:getChildByName('check')
    check:setVisible(false)

    local banker = avatar:getChildByName('banker')
    banker:setVisible(false)

    local frame=avatar:getChildByName('frame')
    local outerFrame = frame:getChildByName('outerFrame')
    outerFrame:setVisible(false)

    local cards = component:getChildByName('cards')
    cards:setVisible(false)
    local path = 'views/xydesk/cards/xx.png'
    for i = 1, 5 do
        local card = cards:getChildByName('card' .. i)
        card:loadTexture(path)
    end
    if name == 'bottom' then
        self:freshMiniCards(false)
    end
end


function XYDeskView:freshBettingValue_bak(name, value, bool)
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')
    local multiple = avatar:getChildByName('multiple')
    multiple:setVisible(bool)

    local num = multiple:getChildByName('num')
    --local path = string.format("views/xydesk/numbers/cu_%s.png", value)
    --value:loadTexture(path)
    num:setString(value)
end

function XYDeskView:freshBettingValue(name, value, bool, animation)
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')
    local multiple = avatar:getChildByName('multiple')
    local num = multiple:getChildByName('num')

    if not bool then
        multiple:setVisible(false)
        return
    end

    if not animation then
        num:setString(tostring(value))
        multiple:setVisible(true)
        return
    end

    multiple:setVisible(false)

    local function getStartPos(name)
        local frame = avatar:getChildByName('frame')
        local headimg = frame:getChildByName('headimg')
        local pos = frame:convertToWorldSpace(cc.p(headimg:getPosition()))
        return pos
    end

    local function getDestPos(name)
        local coin = multiple:getChildByName('value')
        local pos = multiple:convertToWorldSpace(cc.p(coin:getPosition()))
        return pos
    end

    local dest = getDestPos(name)
    local start = getStartPos(name)

    math.randomseed(os.time())

    for i = 1, 3 do
        local sprite = cc.Sprite:create('views/xydesk/3x.png')
        sprite:setVisible(false)
        sprite:setScale(1)
        self:addChild(sprite)

        sprite:setPosition(start)

        local delay = cc.DelayTime:create(0.05 * i) 
        local moveTo = cc.MoveTo:create(0.4, dest)
        local show = cc.Show:create()

        local eft = cc.CallFunc:create(function()
            if i == 2 then
                self:playEftBet()
            end
        end)
        local callBack = cc.CallFunc:create(function()
            if i == 3 then
                multiple:setVisible(true)
                num:setString(tostring(value))
            end
        end)

        local rmvSelf = cc.RemoveSelf:create()
        local retainTime = cc.DelayTime:create(1) 
        local sequence = cc.Sequence:create(
            delay, 
            show, 
            moveTo, 
            eft, 
            callBack,
            retainTime, 
            rmvSelf
        )   

        sprite:runAction(sequence)
    end
end

local pathArr = {
    ['checkCards'] = 'views/xydesk/countdown/4.png', -- 查看手牌
    ['chooseBet'] = 'views/xydesk/countdown/2.png', -- 选择下注分数
    ['chooseQZ'] = 'views/xydesk/countdown/5.png', -- 操作抢庄
    -- ['waitBet'] = 'views/xydesk/countdown/5.png', -- 请等待闲家下注
    -- ['waitShowCards'] = 'views/xydesk/countdown/5.png', -- 等待其他玩家亮牌
}

function XYDeskView:freshCDHint(pkey)
    local component = self.MainPanel:getChildByName('bottom')
    local avatar = component:getChildByName('avatar')
    local countdown = avatar:getChildByName('countdown')
    local hint = countdown:getChildByName('hint')
    hint:loadTexture(pathArr[pkey])

    local num = hint:getChildByName('num')
    local sz = hint:getContentSize()
    local _, y = num:getPosition()
    num:setPosition(sz.width + 20, y)
end

function XYDeskView:freshTimer(value, bool)
    local component = self.MainPanel:getChildByName('bottom')
    local avatar = component:getChildByName('avatar')
    local countdown = avatar:getChildByName('countdown')
    local hint = countdown:getChildByName('hint')
    local num = hint:getChildByName('num')

    num:setString(value)
    countdown:setVisible(bool)
end

function XYDeskView:freshChatMsg(name, msg)
    if not name or not msg then
        return
    end

    local chatView = require('app.views.XYChatView')
    local component = self.MainPanel:getChildByName(name)
    local chatFrame = component:getChildByName('chatFrame')
    local txtPnl = chatFrame:getChildByName('txtPnl')
    local szTxTPnl = txtPnl:getContentSize()
    local txt = txtPnl:getChildByName('txt')
    local txtPnl1 = chatFrame:getChildByName('txtPnl1')
    local txt1 = txtPnl1:getChildByName('txt1')    
    local emoji = chatFrame:getChildByName('emoji')
    chatFrame:stopAllActions()
    chatFrame:setVisible(true)

    local msgType = msg.type
    if msgType == 0 or msgType == 2 then
      local chatsTbl = chatView.getChatsTbl()

      local str
      if msgType == 0 then
          str = chatsTbl[msg.msg]
      else
          str = msg.msg
      end

      txtPnl:setVisible(false)
      txtPnl1:setVisible(false)
    --   local len = string.utf8len(str)
      local len = string.len(str)
      if len <= 42 then
        txt:setString(str)
        txtPnl:setVisible(true)
      elseif len > 42 then
        txt1:setString(str)
        txtPnl1:setVisible(true)        
      end
    elseif msgType == 1 then
        -- local path = "views/xychat/".. msg.msg ..".png"
        -- emoji:loadTexture(path)
        -- emoji:setVisible(true)
        self:freshEmojiAction(name, msg.msg)
    end

    local callback = function()
        chatFrame:setVisible(false)
        txtPnl:setVisible(false)
        txtPnl1:setVisible(false)
        emoji:setVisible(false)
        txt:setString('')
        txt1:setString('')
    end

    local delay = cc.DelayTime:create(2.5)
    chatFrame:runAction(cc.Sequence:create(delay, cc.CallFunc:create(callback)))
end

function XYDeskView:freshEmojiAction(name, idx)
    local csbPath = {
        'views/animation/se.csb',
        'views/animation/bishi.csb',
        'views/animation/jianxiao.csb',
        'views/animation/woyun.csb',
        'views/animation/shy.csb',
        'views/animation/kelian.csb',
        'views/animation/zhouma.csb',
        'views/animation/win.csb',
        'views/animation/jiayou.csb',
        'views/animation/cry.csb',
        'views/animation/angry.csb',
        'views/animation/koushui.csb',                
    }

    local getPos = function(name)
        local seat = self.MainPanel:getChildByName(name)
        local avatar = seat:getChildByName('avatar')
        local frame = avatar:getChildByName('frame')
        local headimg = frame:getChildByName('headimg')

        local pos = frame:convertToWorldSpace(cc.p(headimg:getPosition()))

        return pos
    end
    
    local str = csbPath[idx]
    local node = cc.CSLoader:createNode(str) 
    node:setPosition(cc.p(getPos(name)))
    self:addChild(node)
    node:setVisible(true)

    local callback = function()
        local action = cc.CSLoader:createTimeline(str)   
        action:gotoFrameAndPlay(0, false)
        action:setFrameEventCallFunc(function(frame)
            local event = frame:getEvent();
            print("=========",event)
            if event == 'end' then
                node:removeSelf()
            end
        end)      
        node:runAction(action)
    end
 
    local delay = cc.DelayTime:create(0.2)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    node:runAction(sequence)
end

function XYDeskView:freshPrepareBtn(bool)
	local btn = self.MainPanel:getChildByName('prepare')
    self.outerFrameBool = false
	btn:setVisible(bool)
end

function XYDeskView:freshGameStartBtn(bool)
	local btn = self.MainPanel:getChildByName('gameStart')
    btn:setEnabled(bool)
	btn:setVisible(bool)
end

function XYDeskView:gameSettingAction(derection)
	local gameSetting = self.MainPanel:getChildByName('gameSetting')
	local topbar = self.MainPanel:getChildByName('topbar')
	local setting = topbar:getChildByName('setting')
	
	local bg = gameSetting:getChildByName('bg')
	local cl = gameSetting:getChildByName('close')
	local sz = bg:getContentSize()
	local pos = cc.p(bg:getPosition())
	local leave = bg:getChildByName('leave')
	
	
	
	local dest, moveTo
	if derection == 'In' then
		cl:setVisible(true)
		setting:setVisible(false)
		gameSetting:setVisible(true)
		bg:setVisible(true)
		

		local played = self.desk.info.played
		if played then
			leave:setEnabled(false)
		else
			leave:setEnabled(true)
		end
		
        -- dest = cc.p(pos.x - sz.width, pos.y)
        -- moveTo = cc.MoveTo:create(0.2, dest)
        -- bg:runAction(moveTo)
	elseif derection == 'Out' then
		cl:setVisible(false)
		setting:setVisible(true)
		gameSetting:setVisible(false)
		bg:setVisible(false)
		
		-- dest = cc.p(pos.x + sz.width, pos.y)
		-- moveTo = cc.MoveTo:create(0.2, dest)
		-- local sequence = cc.Sequence:create(moveTo, cc.CallFunc:create(function()
		-- end))
		-- bg:runAction(sequence)
	end
end 

function XYDeskView:gameInfoAction(derection)
	local infoPanel = self.MainPanel:getChildByName('roomInfo')
	local info = infoPanel:getChildByName('info')
	local close = infoPanel:getChildByName('close')
	
	local text_wanfa = info:getChildByName('text_wanfa')
	local text_difen = info:getChildByName('text_difen')
	local text_beiRule = info:getChildByName('text_beiRule')
	local text_roomRule = info:getChildByName('text_roomRule')
	local text_Twanfa = info:getChildByName('text_Twanfa')

	local desk = self.desk.info;
	
	text_wanfa:setString(self.wfName[desk.deskInfo.gameplay])

    local tabBaseStr = {
        ['2/4'] = '1, 2, 3',
        ['4/8'] = '4, 6, 8',
        ['5/10'] = '6, 8, 10',
    }
    local baseStr = tabBaseStr[desk.deskInfo.base] or data.deskInfo.base    
	text_difen:setString(baseStr)

	local multiply = desk.deskInfo.multiply
	local roomPrice=desk.deskInfo.roomPrice
    local advanced=desk.deskInfo.advanced
    local special=desk.deskInfo.special
	local beiRuleString
	local roomRuleString
    local advancedString
    local specialString
	local specialStringType1
    local specialStringType2
    local specialStringType3
    local specialStringType4


    if self.desk.info.deskInfo.gameplay == 7 then
        beiRuleString = "牛1~牛牛    1倍~10倍"
	elseif(multiply == 1) then
		beiRuleString = "牛牛x5 牛九x4 牛八x3 牛七x2"
	else
		beiRuleString = "牛牛x3 牛九x2 牛八x2"
	end
	
	if(roomPrice == 1) then
	roomRuleString = "房主支付"
	else
	roomRuleString = "AA支付"
	end

    if(advanced[1]==1 and advanced[2]==0 and advanced[3] == 0) then
	advancedString = "闲家推注" 
    elseif (advanced[1]==1 and advanced[2]==2 and advanced[3] == 0) then
	advancedString = "闲家推注 游戏开始后禁止加入"
     elseif (advanced[1]==1 and advanced[2]==2 and advanced[3] == 3) then
	advancedString = "闲家推注 游戏开始后禁止加入 禁止搓牌"
    elseif (advanced[1]==1 and advanced[2]==0 and advanced[3] == 3) then
	advancedString = "闲家推注 禁止搓牌"
    elseif (advanced[1]==0 and advanced[2]==2 and advanced[3] == 0) then
	advancedString = "游戏开始后禁止加入"
    elseif (advanced[1]==0 and advanced[2]==2 and advanced[3] == 3) then
	advancedString = "游戏开始后禁止加入 禁止搓牌"
    elseif (advanced[1]==0 and advanced[2]==0 and advanced[3] == 3) then
	advancedString = "禁止搓牌"
    elseif (advanced[1]==0 and advanced[2]==2 and advanced[3] == 3) then
	advancedString = "游戏开始后禁止加入 禁止搓牌"
    elseif advanced[1]==1 and advanced[2]==2 then
        advancedString = "闲家推注 禁止搓牌"
    elseif advanced[1]==1 and advanced[2]==0 then
        advancedString = "闲家推注"
    elseif advanced[1]==0 and advanced[2]==2 then
        advancedString = "禁止搓牌"
    elseif advanced[1]==0 and advanced[2]==0 then
        advancedString = ""
	end

    if(special[1] == 1) then
    specialStringType1="五花牛(5倍) "
    else
    specialStringType1=""
    end
    if(special[2] == 2) then
    specialStringType2="炸弹牛(6倍) "
    else
    specialStringType2=""
    end
    if(special[3] == 3) then
    specialStringType3="五小牛(8倍)"
    else
    specialStringType3=""
    end
    if(special[4] == 4) then
    specialStringType4="十点关机"
    else
    specialStringType4=""
    end
	

    local tabRule2 = {
        WUXIAO = "五小牛(8倍) ",
        BOOM = "炸弹牛(8倍) ",
        HULU = "葫芦牛(8倍) ",
        WUHUA_J = "五花牛(8倍) ",
        TONGHUA = "同花牛(8倍) ",
        STRAIGHT = "顺子牛(8倍) ",
    }

    local tabRule1 = {
        WUXIAO = "五小牛(10倍) ",
        BOOM = "炸弹牛(10倍) ",
        HULU = "葫芦牛(10倍) ",
        WUHUA_J = "五花牛(10倍) ",
        TONGHUA = "同花牛(10倍) ",
        STRAIGHT = "顺子牛(10倍) ",
    }

    
    local tabRule = tabRule2
    if self.desk.info.deskInfo.gameplay == 7 then
        tabRule = tabRule1
    end

    local ruleText = ""
    local addCnt = 0
    for i, v in pairs(special) do 
        if v > 0 then
            local spName = GameLogic.getSetting(i)
            if spName then
                addCnt = addCnt + 1
                local r = addCnt == 3 and "\r\n" or ""
                ruleText = ruleText .. tabRule[spName] .. r
            end
        end
    end

    specialString=specialStringType1..specialStringType2..specialStringType3..specialStringType4
	text_beiRule:setString(beiRuleString)
	text_roomRule:setString(roomRuleString.." "..advancedString)
    if(text_roomRule:getContentSize().width>500) then 
    text_roomRule:setFontSize(20)
    end
	text_Twanfa:setString(ruleText)
	
	if derection == 'Out' then
		info:setVisible(false)
		close:setVisible(false)
	elseif derection == 'In' then
		info:setVisible(true)
		close:setVisible(true)
	end

     
  
	
end 


function XYDeskView:table_max(t)
    local mn = 0
    for k, v in pairs(t) do
        if mn < k then
            mn = k
        end
    end
    return t[mn]
end 

--[[
function XYDeskView:outerFrameBlink(bankerName, bool)
	
	if self.desk.info.deskInfo.gameplay == 3 or self.desk.info.deskInfo.gameplay == 4 then
		local outerFrameNum = {}
		if self.desk.qzPlayers[2] ~= nil then
			local max = self:table_max(self.desk.qzBei)
			dump(max)
			for i, v in pairs(self.desk.qzBei) do
				if v == max then
					table.insert(outerFrameNum, i)
				end
			end
			
			if outerFrameNum[2] ~= nil then
				for _, n in pairs(outerFrameNum) do
					
					local component = self.MainPanel:getChildByName(self.desk.qzPlayers[n])
					local avatar = component:getChildByName('avatar')
					local frame = avatar:getChildByName('frame')
					local outerFrame = frame:getChildByName('outerFrame')
					local blink = cc.Blink:create(0.5, 5)
					local sequence = cc.Sequence:create(blink, cc.CallFunc:create(function()
						self.outerFrameBool = true
						self:freshBankerState(bankerName, bool)
					end))
					outerFrame:runAction(sequence)
				end
			else
				self.outerFrameBool = true
				self:freshBankerState(bankerName, bool)
			end
			
		else
			self.outerFrameBool = true
			self:freshBankerState(bankerName, bool)
		end
		
	else
		self.outerFrameBool = true
		self:freshBankerState(bankerName, bool)
		
	end
	
end 
]]

function XYDeskView:setBettingMsg(msg)
    self.bettingMsg = msg
end

function XYDeskView:setBankerAnimation(bankerName, msg)
    local rank = {
        ['bottom'] = 6,
        ['left'] = 5,
        ['lefttop'] = 4,
        ['top'] = 3,
        ['righttop'] = 2,
        ['right'] = 1,
    }
    local gameplay = self.desk.info.deskInfo.gameplay
    local data =  {}
    local this = self
    local mulNum = msg.number or 0
    local function resetData()
        data = {
            run = false,    -- 运行标志
            players = {},   -- 所有的抢庄者 {"left", "bottom"}
            time = 2,    -- 动画时间    
            time1 = 2,
            interval = 0.08,  -- 切换间隔
            tick1 = 0,      -- 切换tick
            tick2 = 0,      -- 总时间tick
            tick3 = 0,
            idx = 1,        -- 切换IDX    
            bankerSeat = "",    -- 庄家位置
            pervIdx = 1,
            mulNum = mulNum,
            gameplay = gameplay,
            status = 1,
            cnt = 1,
        }
        return data
    end

    local function getOutFrame(name)
        local component = this.MainPanel:getChildByName(name)
        local avatar = component:getChildByName('avatar')
        local frame = avatar:getChildByName('frame')
        local outerFrame = frame:getChildByName('outerFrame')
        return outerFrame
    end

    local function getBankerIcon(name)
        local component = this.MainPanel:getChildByName(name)
        local avatar = component:getChildByName('avatar')
        local banker = avatar:getChildByName('banker')
        return banker
    end

    local function freshBlinkAction(name, show)
        local component = this.MainPanel:getChildByName(name)
        local avatar = component:getChildByName('avatar')
        local node = avatar:getChildByName('bankAnimation')
        node:setVisible(show)
        if show then
            local action = cc.CSLoader:createTimeline("views/animation/Zhuangjia1.csb")
            action:gotoFrameAndPlay(0, false)
            node:stopAllActions()
            node:runAction(action)
        end
    end

    local function freshBankerAction(name, show)
        local component = this.MainPanel:getChildByName(name)
        local avatar = component:getChildByName('avatar')
        local node = avatar:getChildByName('qzAnimation')
        node:setVisible(show)
        if show then
            local action = cc.CSLoader:createTimeline("views/animation/Zhuangjia.csb")
            action:gotoFrameAndPlay(0, false)
            node:stopAllActions()
            node:runAction(action)
        end


    end

    local function freshIconAction(name, show)
        local component = this.MainPanel:getChildByName(name)
        local avatar = component:getChildByName('avatar')
        local node = avatar:getChildByName('bankAnimation1')
        node:setVisible(show)
        if show then
            local action = cc.CSLoader:createTimeline("views/animation/Zhuangjia2.csb")
            action:gotoFrameAndPlay(0, false)
            node:stopAllActions()
            node:runAction(action)
        end
    end

    data = resetData()
    data.players = this.desk.qzPlayers
    data.idx = 1
    data.bankerSeat = bankerName
    data.run = true

    local interval2 = data.interval * 3

    if data.players and #data.players == 0 then
        -- 没人抢庄
        data.players = {}
        local players = this.desk.players
        for _, player in pairs(players) do
            local actor = player.actor
            local name = this.desk:getPlayerPosKey(actor.uid)
            local player = {}
            player.pos = name
            player.number = 1
            table.insert(data.players, player)
        end

        table.sort(data.players, function(a,b)
            if rank[a.pos] and rank[b.pos] then
                return rank[a.pos] > rank[b.pos]
            end
        end)
    elseif data.players and #data.players == 1 then
        -- 一人抢庄
        data.time = 0.1
    elseif data.players and #data.players > 1  then
        -- 多人抢庄 排序
        table.sort(data.players, function(a,b)
            if a.number and b.number then
                return a.number > b.number
            end
        end)

        local max = data.players[1].number
        for i = #data.players, 1, -1 do
            if max ~= data.players[i].number then
                table.remove( data.players, i)
            end
        end

        table.sort(data.players, function(a,b)
            if rank[a.pos] and rank[b.pos] then
                return rank[a.pos] > rank[b.pos]
            end
        end)

        if #data.players == 1 then
            data.time = 0.1
        end
    end

    return function(this, dt)
        -- 更新函数
        if data.run then
            if dt then
                data.tick1 = data.tick1 + dt
                data.tick2 = data.tick2 + dt
            end
            -- p1
            if data.status == 1 and data.tick1 > data.interval then
                -- 轮换
                local cur = data.players[data.idx].pos
                local perv = data.players[data.pervIdx].pos
                if perv then
                    getOutFrame(perv):setVisible(false)
                    getBankerIcon(perv):setVisible(false)
                    freshBlinkAction(perv, false)
                end
                if cur then
                    data.pervIdx = data.idx
                    getOutFrame(cur):setVisible(false)
                    getBankerIcon(cur):setVisible(false)
                    freshBlinkAction(cur, true)
                    SoundMng.playEft('desk/random_banker.mp3')
                end
                local idx = data.idx + 1
                data.idx = (idx > #data.players) and 1 or idx
                data.tick1 = 0
                
                -- 时间到
                if data.tick2 > data.time then
                    data.interval = interval2
                    if cur and cur == data.bankerSeat then
                        getOutFrame(cur):setVisible(false)
                        getBankerIcon(cur):setVisible(false)
                        freshBankerAction(cur,true)
                        data.status = 2
                    end
                end
            end
            -- p2
            if data.status == 2 then
                data.tick3 = data.tick3 + dt
                if data.tick1 > data.interval then
                    data.cnt = data.cnt + 1
                    local bShow = data.cnt%2 == 1
                    -- getOutFrame(data.bankerSeat):setVisible(bShow)
                    -- getBankerIcon(data.bankerSeat):setVisible(bShow)
                    data.tick1 = 0
                end
                if data.tick3 > data.time1 then
                    freshIconAction(data.bankerSeat, true)
                    getOutFrame(data.bankerSeat):setVisible(true)
                    getBankerIcon(data.bankerSeat):setVisible(true)
                    if data.gameplay == 4 or gameplay == 7 then
                        self:freshQZNum(data.bankerSeat, data.mulNum, true)
                    end
                    if self.desk.curState and self.desk.curState == "PutMoney" then
                        if self.banker and self.banker ~= 'bottom' then
                            this:freshBettingBar(true, this.bettingMsg)
                        end
                    end
                    resetData()
                end
            end
        end
        return data.run
    end
end

function XYDeskView:onUpdateBanker(dt)
    if self.updateBankerFunc then
        self.updateBankerFunc(self, dt)
    end
end


function XYDeskView:focusCard(i, bool)
    local bottom = self.MainPanel:getChildByName('bottom')
    local cards = bottom:getChildByName('cards')

    local card = cards:getChildByName('card' .. i)
    local x, y = card:getPosition()
    if bool and not card.focus then
        card.focus = 'focus'
        card:setPosition(cc.p(x, y + 30))
    end
end

function XYDeskView:cardsBackToOrigin()
    local bottom = self.MainPanel:getChildByName('bottom')
    local cards = bottom:getChildByName('cards')

    for i = 1, 5 do
        local card = cards:getChildByName('card' .. i)
        if card.focus == 'focus' then
            local x, y = card:getPosition()
            card:setPosition(cc.p(x, y - 30))
            card.focus = nil
        end
    end

    -- 将不是bottom的最后两张牌强制还原
    local names = {'left', 'lefttop', 'top', 'righttop', 'right', "bottom"}
    for k, v in ipairs(names) do 
        local positionName = self.MainPanel:getChildByName(v)
        local cardView = positionName:getChildByName('cards')

        -- -- 防止重复竖起来
        -- local card1 = cardView:getChildByName('card' .. 1)
        -- local card4 = cardView:getChildByName('card' .. 4)
        -- local card5 = cardView:getChildByName('card' .. 5)
        -- local x1, y1 = card1:getPosition()
        -- local x4, y4 = card4:getPosition()
        -- local x5, y5 = card5:getPosition()
        -- if math.abs(y1 - y4) > 5 then
        --     card4:setPosition(cc.p(x4, y1))
        --     card5:setPosition(cc.p(x5, y1))
        -- end
        for i = 1, 5 do
            local card = cardView:getChildByName('card' .. i)
            local p = self.cardsOrgPos[v][i]
            card:setPosition(p)
        end
    end
end

function XYDeskView:cardsBackToOriginSeat(name)
    local positionName = self.MainPanel:getChildByName(name)
    local cardView = positionName:getChildByName('cards')
    for i = 1, 5 do
        local card = cardView:getChildByName('card' .. i)
        local p = self.cardsOrgPos[name][i]
        card:setPosition(p)
    end
end

function XYDeskView:miniCardsBackToOrigin()
    local positionName = self.MainPanel:getChildByName('bottom')
    local cardView = positionName:getChildByName('cards_mini')
    for i = 1, 5 do
        local card = cardView:getChildByName('card' .. i)
        local p = self.cardsOrgPos['mini'][i]
        card:setPosition(p)
    end
end

function XYDeskView:showResultTip(reload)
    reload = reload or false
    local mycards = self.desk.players[1].mycards
    local specialOption = self.desk.info.deskInfo.special
    local specialType, name = GameLogic.getSpecialType(mycards, specialOption)

    mycards = self:groupCards('bottom', mycards, specialType)
    self:freshCardsDisplay('bottom',mycards)

    local cnt = 0
    local niuniuP = self.desk:findNiuniuByData(mycards)
    if niuniuP then
        cnt = self.desk:findNiuniuCnt(mycards)
    end

    local msg = { 
        info = 'resultTip', 
        niuCnt = cnt,
        specialType = specialType,
        cards = mycards,
        sex = self.desk.players[1].actor.sex,
        bIsBanker = (self.banker == 'bottom'),
        reload = reload
        }
    self:freshCheckState('bottom', msg, true)
end

function XYDeskView:doVoiceAnimation()
  self:removeVoiceAnimation()

  local yyCountdown = self.MainPanel:getChildByName('yyCountdown')
  local pwr = yyCountdown:getChildByName('power')
  self.tvoice = yyCountdown
  self.tvoice.pwr = pwr

  if not self.tvoice.prg then
    local spr = cc.Sprite:create('views/xydesk/yuyin/prtframe.png')
    local img = yyCountdown:getChildByName('img')
    local imgSz = img:getContentSize()
    local progress = cc.ProgressTimer:create(spr)
    progress:setPercentage(100)
    progress:setPosition(imgSz.width / 2, imgSz.height / 2)
    progress:setName('progress')
    img:addChild(progress)
    self.tvoice.prg = progress
  end

  for i = 0, 8 do
    local delay1 = cc.DelayTime:create(0.1 * i)
    local fIn = cc.FadeIn:create(0.1)
    local delay2 = cc.DelayTime:create(0.1 * (8 - i))
    local fOut = cc.FadeOut:create(0.1)
    local sequence = cc.Sequence:create(delay1, fIn, delay2, fOut)
    local action = cc.RepeatForever:create(sequence)

    local rect = pwr:getChildByName(tostring(i))
    rect:runAction(action)
  end

  pwr:setVisible(true)

  yyCountdown:setVisible(true)
end

function XYDeskView:updateCountdownVoice(delay)
  self.tvoice.prg:setPercentage((20 - delay) / 20  * 100)
end

function XYDeskView:removeVoiceAnimation()
  if self.tvoice then
    local pwr = self.tvoice.pwr
    for i = 0, 8 do
        local rect = pwr:getChildByName(tostring(i))
        rect:stopAllActions()
        rect:setOpacity(0)
    end
    pwr:stopAllActions()
    pwr:setVisible(false)

    self.tvoice.prg:setPercentage(100)
    self.tvoice:setVisible(false)
  end
end

function XYDeskView:freshInviteFriend(bool)
    local invite = self.MainPanel:getChildByName('invite')
    invite:setVisible(bool)
end

function XYDeskView:copyRoomNum(content)
     if testluaj then
        local testluajobj = testluaj.new(self)
        local ok, ret1 = testluajobj.callandroidCopy(self,content)
        if ok then 
            tools.showRemind('已复制')
        end
    else
        tools.showRemind('未复制')
    end
end

function XYDeskView:freshTrusteeshipLayer(bool)
    self.trusteeshipLayer:setVisible(bool)
end

function XYDeskView:freshTrusteeshipIcon(seat, bool)
    bool = bool or false
    local component = self.MainPanel:getChildByName(seat)
    local avatar = component:getChildByName('avatar')
    local trusteeship = avatar:getChildByName('trusteeship')
    trusteeship:setVisible(bool)
end

-- 扑克分组
function XYDeskView:groupCards(name, cards, specialTpye)
    local gCard, groupInfo = GameLogic.groupingCardData(cards, specialTpye)
    local seat = self.MainPanel:getChildByName(name)
    local cards = seat:getChildByName('cards')

    local function arrangeCard(cards, groupInfo)
        -- 将最后两张牌竖起来
        local card3 = cards:getChildByName('card' .. 3)
        local card4 = cards:getChildByName('card' .. 4)
        local card5 = cards:getChildByName('card' .. 5)
        
        local rX = 36
        if groupInfo[2] and #groupInfo[2] == 1 then
            self:cardsBackToOriginSeat(name)
            local x5, y5 = card5:getPosition()
            card5:setPosition(cc.p(x5 + rX, y5))
        elseif groupInfo[2] and #groupInfo[2] == 2 then
            self:cardsBackToOriginSeat(name)
            local x4, y4 = card4:getPosition()
            local x5, y5 = card5:getPosition()
            card4:setPosition(cc.p(x4 + rX, y4))
            card5:setPosition(cc.p(x5 + rX , y5))
        end
    end
    
    if name == 'bottom' then 
        if groupInfo[2] and #groupInfo[2] > 0 then
            cards:setVisible(false)
            cards = seat:getChildByName('cards_mini')
            self:miniCardsBackToOrigin()
            arrangeCard(cards, groupInfo)
            self:freshMiniCards(true, gCard)
        else
            cards:setVisible(true)
            self:freshMiniCards(false)
        end
    else
        arrangeCard(cards, groupInfo)
    end

    return gCard
end

-- 倍数图片
function XYDeskView:freshMulNum(name, show, niuCnt, specialTpye)
    
    local function getNumNode(name)
        local component = self.MainPanel:getChildByName(name)
        local check = component:getChildByName('check')
        local valueSp = check:getChildByName('value')
        local num = check:getChildByName('num')
        return num
    end

    local node = getNumNode(name)
    if node and not show then
        node:setVisible(false)
        return
    end

    local set = self.desk.info.deskInfo.multiply
    local gamePlay = self.desk.info.deskInfo.gameplay
    local mul = GameLogic.getMul(gamePlay, set, niuCnt, specialTpye)

    if mul and node then
        local path =  string.format("views/xydesk/numbers/yellow/%s.png", mul)
        if specialTpye > 0 or niuCnt == 10 then
            path =  string.format("views/xydesk/numbers/red/%s.png", mul)
        end
        node:loadTexture(path)
        node:setVisible(true)
    else
        node:setVisible(false)
    end
end

function XYDeskView:somebodyVoice(uid, total)
    local name = self.desk:getPlayerPosKey(uid)
    local component = self.MainPanel:getChildByName(name)
    local yyIcon = component:getChildByName('yyIcon')
    local yyExt = yyIcon:getChildByName('yyExt')

    for i = 0, 2 do
        local delay1 = cc.DelayTime:create(0.1 * i)
        local fIn = cc.FadeIn:create(0.1)
        local delay2 = cc.DelayTime:create(0.1 * (2 - i))
        local fOut = cc.FadeOut:create(0.1)
        local sequence = cc.Sequence:create(delay1, fIn, delay2, fOut)
        local action = cc.RepeatForever:create(sequence)

        local rect = yyExt:getChildByName(tostring(i))
        rect:runAction(action)
    end

    yyIcon:setVisible(true)

    local delay = cc.DelayTime:create(total)
    local callback = function()
        yyIcon:setVisible(false)

        for i = 0, 2 do
            local rect = yyExt:getChildByName(tostring(i))
            rect:stopAllActions()
            rect:setOpacity(0)
        end
    end

    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    yyIcon:runAction(sequence)
end

function XYDeskView:coinFlyAction(start, dest, bankerSeat, delay2, callback)
    local coinCnt = 15
    delay2 = delay2 or 0
    local getPos = function(name)
        local seat = self.MainPanel:getChildByName(name)
        local avatar = seat:getChildByName('avatar')
        local frame = avatar:getChildByName('frame')
        local headimg = frame:getChildByName('headimg')

        local pos = frame:convertToWorldSpace(cc.p(headimg:getPosition()))

        return pos
    end

    math.randomseed(os.time())

    for i = 1, coinCnt do
        local sprite = cc.Sprite:create('views/xydesk/3x.png')
        sprite:setVisible(false)
        sprite:setScale(1.2)
        self:addChild(sprite)

        local posStart = getPos(start)
        sprite:setPosition(cc.p(posStart.x + math.random(-30, 30), posStart.y + math.random(-20, 20)))
        
        local d = 0
        if bankerSeat and start == bankerSeat then 
            d = 1
        end 
        
        local destPos = cc.p(getPos(dest))
        destPos = cc.p(destPos.x + math.random(-20, 20), destPos.y + math.random(-20, 20))
        local time = cc.pGetDistance(posStart, destPos)/1500

        local delay = cc.DelayTime:create(0.05 * i + d + delay2) 
        local moveTo = cc.MoveTo:create(time, destPos)
        local show = cc.Show:create()
        -- local vol = cc.CallFunc:create(function()
        --     SoundMng.playEftEx('desk/jinbi.mp3')
        -- end)

        local bezier ={
            cc.p(getPos(start)),
            {display.cx, display.cy},
            cc.p(getPos(dest))
        }

        --local bezierTo = cc.BezierTo:create(0.8, bezier)
        local eft = cc.CallFunc:create(function()
            if i == 1 then
                SoundMng.playEft('desk/coins_fly.mp3')
                self:winAction(dest)
            end
        end)
        local call = function()
           
        end
        if callback then
            call = callback
        end
        local rmvSelf = cc.RemoveSelf:create()
        local retainTime = cc.DelayTime:create(1) 
        local sequence = cc.Sequence:create(delay, show, moveTo, eft, cc.CallFunc:create(call), retainTime, rmvSelf)
        sprite:runAction(sequence)
    end
end

function XYDeskView:winAction(name)
    local seat = self.MainPanel:getChildByName(name)
    local avatar = seat:getChildByName('avatar')
    local node = avatar:getChildByName('jiaqianAnimation')

    local action = cc.CSLoader:createTimeline("views/animation/Jiaqian.csb")
    action:gotoFrameAndPlay(0, false)
    action:setTimeSpeed(1.3)
    node:stopAllActions()
    node:runAction(action)
end

function XYDeskView:kusoAction_bak(start, dest, idx)
    local FrameAction = require('app.helpers.FrameAction')
    local kuso = self.kusoArr[idx]
    SoundMng.playEft('sfx/' .. kuso.prefix .. 'sfx.mp3')

    local getPos = function(name)
        local seat = self.MainPanel:getChildByName(name)
        local avatar = seat:getChildByName('avatar')
        local frame = avatar:getChildByName('frame')
        local headimg = frame:getChildByName('headimg')

        local pos = frame:convertToWorldSpace(cc.p(headimg:getPosition()))

        return pos
    end
    --print(idx, "<- #####################################")
    cc.SpriteFrameCache:getInstance():addSpriteFrames(kuso.path)

    local sprite = cc.Sprite:createWithSpriteFrameName(kuso.prefix .. '1.png')
    sprite:setPosition(cc.p(getPos(start)))
    self:addChild(sprite)
    
    local ani = FrameAction.create(kuso.prefix .. '%d.png', kuso.frame, 1, 0.05, 1)
    local delay = cc.DelayTime:create(0.2)
    local moveTo = cc.MoveTo:create(0.8, cc.p(getPos(dest)))
    local rmvSelf = cc.RemoveSelf:create()
    local sequence = cc.Sequence:create(delay, moveTo, ani, rmvSelf)
    sprite:runAction(sequence)
end

function XYDeskView:kusoAction(start, dest, idx)
    local getPos = function(name)
        local seat = self.MainPanel:getChildByName(name)
        local avatar = seat:getChildByName('avatar')
        local frame = avatar:getChildByName('frame')
        local headimg = frame:getChildByName('headimg')

        local pos = frame:convertToWorldSpace(cc.p(headimg:getPosition()))

        return pos
    end
    
    local str = 'item'..idx
    local node = cc.CSLoader:createNode("views/animation/"..str..".csb") 
    node:setPosition(cc.p(getPos(start)))
    self:addChild(node)
    node:setVisible(true)

    local action = cc.CSLoader:createTimeline("views/animation/"..str..".csb")  
    action:gotoFrameAndPlay(0, 0, false)
    node:runAction(action)
    local callback = function()
        local action = cc.CSLoader:createTimeline("views/animation/"..str..".csb")   
        action:gotoFrameAndPlay(0, false)
        action:setFrameEventCallFunc(function(frame)
            local event = frame:getEvent();
            print("=========",event);
            if event == 'end' then
                node:removeSelf()
            elseif event == 'playSound' then
                SoundMng.playEft('sfx/' .. str .. '.mp3')
            end
        end)      
        node:runAction(action)

    end
 
    local delay = cc.DelayTime:create(0.2)
    local moveTo = cc.MoveTo:create(0.3, cc.p(getPos(dest)))

    local sequence = cc.Sequence:create(delay, moveTo, cc.CallFunc:create(callback))
    node:runAction(sequence)
end

function XYDeskView:playEftQz(qzNum, uid)
    local _, player = self.desk:getPlayerPos(uid)
    if player and player.actor then
        local sex = player.actor.sex
        
        
        local qiangStr = 'buqiang_'
        if qzNum and qzNum > 0 then
            qiangStr = 'qiangzhuang_'
        end
        local sexStr = '0'
        if sex and sex ~= 0 then
            sexStr = '1'
        end
        
        local soundPath = 'desk/' .. tostring(qiangStr .. sexStr .. '.mp3')
        SoundMng.playEftEx(soundPath)
    end
end

function XYDeskView:playEftSummary(win)
    local soundPath = 'desk/lose.mp3'
    if win then
        soundPath = 'desk/win.mp3'
    end
    SoundMng.playEftEx(soundPath)
end

function XYDeskView:playEftBet()
    local soundPath = 'desk/coin_big.mp3'
    SoundMng.playEftEx(soundPath)
end

function XYDeskView:freshSummaryView(show, msg)
    local view = self.MainPanel:getChildByName('summary')
    if not show then
        view:setVisible(false)
        return
    end

    view:setVisible(true)

    local quit = view:getChildByName('quit')
    local summary = view:getChildByName('summary')

    local function onClickQuit()
        app:switch('LobbyController')
    end

    local function onClickSummary()
        app:switch('XYSummaryController', msg)
    end

    quit:addClickEventListener(onClickQuit)
    summary:addClickEventListener(onClickSummary)
end

return XYDeskView
