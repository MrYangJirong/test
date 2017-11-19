local class = require('middleclass')
local Controller = require('mvc.Controller')
local HasSignals = require('HasSignals')
local XYDeskController = class("XYDeskController", Controller):include(HasSignals)
local SoundMng = require('app.helpers.SoundMng')
local tools = require('app.helpers.tools')
local TranslateView = require('app.helpers.TranslateView')
local Scheduler = require('app.helpers.Scheduler')

local app = require("app.App"):instance()

function XYDeskController:sendMsgOfBetting(_, value)
	local msg = {
		msgID = self.deskName .. '.puts',
		score = value
	}
	app.conn:send(msg)
	
	self:timerFinish()
	self.view:freshBettingBar(false)
end

function XYDeskController:initialize(deskName)
    Controller.initialize(self)
    HasSignals.initialize(self)

    self.deskName = deskName
    self.desk = app.session[self.deskName]
    self.desk.deskName = deskName
    -- print('self.deskName is ', self.deskName)

    local bgmFlag = SoundMng.getEftFlag(SoundMng.type[1])
    local EftFlag = SoundMng.getEftFlag(SoundMng.type[2])
    local bgmVol, sfxVol = SoundMng.getVol()
    SoundMng.setBgmVol(bgmVol)
    SoundMng.setSfxVol(sfxVol)
	SoundMng.setBgmFlag(bgmFlag)
    SoundMng.setEftFlag(EftFlag)
    SoundMng.setPlaying(false)
    if bgmFlag == nil then
       bgmFlag = true
    end
    if EftFlag == nil then
        EftFlag = true
    end
    SoundMng.playBgm('game_bg1.mp3')


    self.voiceQueue = {}
    self.isPlayingGame = false
    self.bCheatFlag = false                 -- 作弊标志

    self.bettingMsg = nil
end

function XYDeskController:finalize()
	for i = 1, #self.listener do
		self.listener[i]:dispose()
	end
	
	if self.timerUpt then
		Scheduler.delete(self.timerUpt)
		self.timerUpt = nil
	end
end

function XYDeskController:viewDidLoad()
	
	self.listener = {
		app.conn:on('ping', function()
			self.view:onPing()
		end),
		
		self.desk:on('dropLine', function(name)
			self.view:freshDropLine(name, true)
		end),
		
		self.desk:on('somebodySitdown', function(msg)
			local data = msg.userInfo.actor
			local name = self.desk:getPlayerPosKey(data.uid)
			
			self.view:freshDropLine(name, false)
			self.view:freshHeadInfo(name, data)
			self.view:freshSeate(name, true)
			self.view:freshStatusText(true, 2)
		end),
		
		self.desk:on('somebodyPrepare', function(uid)
			local name = self.desk:getPlayerPosKey(uid)
			self.view:freshReadyState(name, true)
			if not self.desk.info.played then
				self.view:freshStatusText(true, 2)
			end
		end),

        self.desk:on('somebodyQiang', function(msg)
          local name = self.desk:getPlayerPosKey(msg.uid)
          -- 显示抢庄(不抢)---（自由抢庄模式）
          self.view:playEftQz(msg.number, msg.uid)
          print('44444444444444444qqzzzz')
          self.view:freshQZBet(name, msg.number, true)
      end),
		
		self.desk:on('waitOwnerStart', function(uid)
			self.view:freshStatusText(true, 1)
		end),
		
		self.desk:on('somebodyLeave', function(name)
			--print(name, '#################################')
			self.view:freshReadyState(name, false)
			self.view:freshHeadInfo(name, nil)
            self.view:hideHeadInfo(name)
			self.view:clearDesk(name)
			
			local playerCnt = self.desk:getPlayerCnt()
			local gameStart = self.desk.gameStart
			if not gameStart and playerCnt == 1 then
				self.view:freshGameStartBtn(false)
				self.view:freshInviteFriend(true)
			end
		end),
		
		self.desk:on('startGame', function(msg)
			self.view:freshGameStartBtn(msg)
			if msg == true then
				self.view:freshInviteFriend(false)
				self.view:freshStatusText(false)
				SoundMng.playEft('room_dingding.mp3')
			end
			self.view:freshControlView()
		end),
		
		self.desk:on('start', function(msg)
			dump(msg)
			print('999999999999999999999999')
			self.view:freshStatusText(false)
			self:onStart(msg)
			self.view:freshControlView()
            tools.hideMsgBox():onClickBlackLayer()
		end),
		
		self.desk:on('dealt', function(msg)
			-- print(" -> handle dealt @@@@@@ ... ")
			self:onDealt(msg)
			self.view:freshControlView()
		end),
		
		self.desk:on('cheatInfo', function(msg)
			-- print(" -> handle dealt @@@@@@ ... ")
			self:onCheatInfo(msg)
		end),
		
		self.desk:on('overgame', function(msg)
			dump(msg)
			self.desk.info.apply = msg.data
			self.desk.info.applyEx = msg.dataEx
			self:showApplyController()
			self.view:freshControlView()
			self.view:freshStatusText(false)
		end),
		
		self.desk:on('overgameResult', function(msg)
			local over = msg.over
			local played = self.desk.info.played
			if over then	
				if played then
                    if msg.record then
                        self:deleteApplyController()
                        self.emitter:emit('summaryAllRound', msg)
                    else
                        app:switch('LobbyController')
                    end
					--tools.showMsgBox("提示", "申请解散房间提议通过，房间立即解散。"):next(function(btn)
					--if btn == 'enter' then
					--app:switch('LobbyController')
					--end
                    --end)
				else
					tools.showMsgBox("提示", "房主已经解散房间，牌局未开始未扣钻石。"):next(function(btn)
                        app:switch('LobbyController')
					end)
				end
			else
				self:deleteApplyController()
				--tools.showRemind("同意人数未过半，解散失败")
				local players = self.desk.info.apply.result
				dump(players)
				local i = 0
				local uid
				for k, v in pairs(players) do
					if v == 2 then
						i = i + 1
						uid = k
						
					end
				end
				
				local pos = self.desk:getPlayerPos(uid)
				-- dump(self.desk.players[pos])
				local refusePlayer = self.desk.players[pos]
				local name = refusePlayer.actor.nickName
				if i > 1 then
					tools.showMsgBox("提示", "玩家" .. name .. "等拒绝解散，游戏继续",1,true,7,-25)
				else
					tools.showMsgBox("提示", "玩家" .. name .. "拒绝解散，游戏继续",1,true,7,-25)
				end
				self.view:freshStatusText(true,3)
			end
		end),
		
		self.desk:on('somebodyChooseFinish', function(msg)
			if msg.name == 'bottom' then
				--print(' -> @@@@ Choose Finish ... ')
				self.desk:zeroEstimation()
				self.view:clearInput()
			end
            -- 传递完成翻牌的玩家的性别
            local pos = self.desk:getPlayerPos(msg.uid)	
			local player = self.desk.players[pos]
            local actor = player.actor
            local sex = actor.sex
            msg['sex'] = sex
			self.view:freshCheckState(msg.name, msg, true)
			self.view:freshControlView()
		end),
		--[[
		self.desk:on('summaryOneRound', function(msg)
			local one = msg.one
			for k, v in pairs(one) do
				self:playEftNN(k, v)
				self.view:freshSummaryOneRound(k, v, true)
			end
			
			self.isPlayingGame = false
			
			local all = msg.all
			if all.records then
				self.emitter:emit('summaryAllRound', all)
			else
                self.view:clearInput()
            end
            self.view:freshCheckState(msg.name, msg, true)
            self.view:freshControlView()
        end),
        ]]
        self.desk:on('summaryOneRound', function(msg)
            local one = msg.one

            if one and one.bottom and one.bottom.score then
                self.view:playEftSummary(one.bottom.score >= 0)
            end

            local gameplay = self.desk.info.deskInfo.gameplay
            if gameplay == 5 then -- 通比牛牛
                local scoreMaps = {} 
                 for k, v in pairs(one) do
                    --self:playEftNN(k, v)
                    self.view:freshSummaryOneRound(k, v, true, true)
                    table.insert( scoreMaps,{k, v.score} )
                end

                local index = 1
                for i, v in ipairs(scoreMaps) do
                    index = i
                end
                -- 按分数排序(冒泡排序)
                local temp
                local tempName
                for i = 1, index - 1 do
                    for j = 1, index - i do
                        if scoreMaps[j][2] > scoreMaps[j + 1][2] then
                            temp = scoreMaps[j][2]
                            scoreMaps[j][2] = scoreMaps[j + 1][2]
                            scoreMaps[j + 1][2] = temp

                            -- 替换name
                            tempName = scoreMaps[j][1]
                            scoreMaps[j][1] = scoreMaps[j + 1][1]
                            scoreMaps[j + 1][1] = tempName
                        end
                    end
                end
                dump(scoreMaps)
                -- 通比牛牛执行金币飞动画逻辑
                --for i = 1, index - 1 do
                  --  for j = i + 1, index do
                   --     self.view:coinFlyAction(scoreMaps[i][1], scoreMaps[j][1], nil, (i - 1) * 0.2)
                  --  end
                --end    
                for k1, v1 in ipairs(scoreMaps) do 
                    for k2, v2 in ipairs(scoreMaps) do
                        if k1 < k2 then
                            self.view:coinFlyAction(v1[1], v2[1], nil, (k1 - 1) * 1.2)
                        end
                    end
                end
            else
                 for k, v in pairs(one) do
                    --self:playEftNN(k, v)
                    self.view:freshSummaryOneRound(k, v, true)
                end
            end
          

            self.isPlayingGame = false

            local all = msg.all
            if all.records then
                self.emitter:emit('summaryAllRound', all)
            else
                self.view:freshContinue(true)
                self.view:freshStatusText(true, 3)
                self.view:freshControlView()
            end
            self:timerFinish()
            
        end),

        self.desk:on('chooseResult', function(msg)
            -- 显示杝示文字
            tools.showRemind(msg)
        end),

        self.desk:on('chooseFinish', function(msg)          -- 弃用逻辑
            --print(' -＞　###### chooseFinish　###### ')
            self.desk:zeroEstimation()
            self.view:clearInput()
            self.view:freshCheckState(msg.name, msg, true)
            self.view:freshControlView()
        end),

        -- 刷新押注
        self.desk:on('stateChange', function()
            print("stateChange  <============")
            self.view:freshControlView()
        end),


        -- 刷新押注
        self.desk:on('freshSomebodyPut', function(evt)
            local event = evt
            if event.name == "bottom" then
                self.view:freshBettingBar(false)
            end
            self.view:freshBettingValue(event.name, event.score, true, true)
            self.view:freshControlView()
        end),

        -- 显示押注按钮
        self.desk:on('freshBettingBar', function(msg)
          dump(msg)
          
          local gameplay = self.desk.info.deskInfo.gameplay
          --print(' -> XYDeskController freshBettingBar ***********************')
          if gameplay == 5 then
              --self:sendMsgOfBetting(self, 1)
              self:sendMsgOfBetting(self, tonumber(self.desk.info.deskInfo.base))
          elseif gameplay == 4 or gameplay == 3 or gameplay == 7 then
              self.view:setBettingMsg(msg)
          else
              self.view:freshBettingBar(true, msg)
            --   if msg.putInfo then
            --     self.basebet = (msg['putInfo'])[1]
            --   end
            --   dump(self.basebet)
          end
          self.view:freshControlView()
        end),

        self.desk:on('bettingTimerStart', function()
            local callback = function()
                --self:sendMsgOfBetting(self, 1)
                --self:sendMsgOfBetting(self,  self.basebet)
                self:timerFinish()
            end
            self:timerStart('chooseBet', 9, callback)
            self.view:freshControlView()
        end),

        self.desk:on('responseSitdown', function(msg)
            local retCode = msg.errCode
            --[[
                0: 戝功
                1: 坝满
                2: 已绝坝下
                3: 房坡丝够
            ]]
            local textTab = {
                [1] = "没有足够的座位",
                [2] = "您已经坐下了",
                [3] = "本房间为AA模式, 您的房卡不足",
                [4] = "您暂时不能加入该牛友群的游戏, 详情请联系该群管理员",
            }
            if retCode and retCode ~= 0 then
                tools.showRemind(textTab[retCode])
            end
            self.view:freshWatcherBtn(false)
        end),

        self.desk:on('chatInGame', function(msg)
            dump(msg)
            local name = self.desk:getPlayerPosKey(msg.uid)
            self.view:freshChatMsg(name, msg)

            local pos = self.desk:getPlayerPos(msg.uid)	
			local player = self.desk.players[pos]
            local actor = player.actor
            local sex = actor.sex
            
            if msg.type == 0 then
                --SoundMng.playEft('woman/fix_msg_' .. msg.msg .. '.mp3')
                SoundMng.playEft('chat/voice_' .. msg.msg - 1 .. "_".. sex..'.mp3')
            end

            if msg.type == 3 then
              local info = msg.msg
              local start = self.desk:getPlayerPosKey(info.clickSender)
              local dest = self.desk:getPlayerPosKey(info.uid)
              self.view:kusoAction(start, dest, info.idx)
            end
        end),

        self.view:on('cardClick', function(msg)
            local me = self.desk:getMe()
            local mycards = me.mycards

            local pos = msg.cardPos
            local cardValue = self.desk:getCardValue(mycards[pos])

            self.desk:estimateNiuniu(cardValue, msg)
            local data = self.desk:getEstimation()
            self.view:freshEstimateResult(data)
            SoundMng.playEft('btn_click.mp3')
        end),

        self.view:on('stopTime',function()
            print('233333333333333333')
            self:timerFinish()
        end),

        self.view:on('clickHead', function(msg)
            self:handleClickHead(msg)
        end),

        self.view:on('showApplyCtrl', function(msg)
            if self.applyCtrl then
                self.applyCtrl:fresh()
            else
                local ctrl = Controller:load('ApplyController', self)
                self:add(ctrl)

                app.layers.ui:addChild(ctrl.view)
                ctrl.view:setPositionX(0)

                ctrl:on('back',function()
                    TranslateView.moveCtrl(ctrl.view, 1, function()
                        ctrl:delete()
                        self.applyCtrl = nil
                    end)
                end)

                self.applyCtrl = ctrl
            end
        end),

        self.view:on('clickBet', function(msg)
            --dump(msg)
            SoundMng.playEft('btn_click.mp3')
            self:sendMsgOfBetting(self, tonumber(msg))
            
        end),

        app.conn:on('playVoice',function(msg)
          if self.isPlayingVoice then
            self.voiceQueue[#self.voiceQueue+1] = msg
          else
            self:playVoice(msg.filename,msg.uid,msg.total)
          end
        end),

        self.view:on('pressVoice', function(_)
            self:pressVoice()
            self:pauseBGM()
        end),

        self.view:on('releaseVoice', function()
            self:releaseVoice()
            self:resumeBGM()
        end),

        self:on('summaryAllRound', function(msg)
            self:onSummaryAllRound(msg)
            -- local callback = function()
            --     -- 跳转到总结算
            --     msg.deskInfo = self.desk.info.deskInfo
            --     msg.deskId = self.desk.info.deskId
            --     msg.ownerName = self.desk.info.ownerName

            --     -- app:switch('XYSummaryController', msg)
            --     self.view:freshSummaryView(true, msg)
            -- end

            -- local delay = cc.DelayTime:create(6.6)
            -- local action = cc.Sequence:create(delay, cc.CallFunc:create(callback))
            -- app.layers.top:runAction(action)
        end),

        self.desk:on('qiangZhuang', function(msg)
            self:onQiangZhuang(msg)
            self.view:freshControlView()
        end),

        self.desk:on('newBanker', function(msg)
            -- dump(msg)
            self:onNewBanker(msg)
            self.view:freshControlView()
        end),

        self.desk:on('didEnterBackground', function(msg)
            -- dump(msg)
            SoundMng.isPauseVol(true)
        end),

        self.desk:on('willEnterForeground', function()
            -- dump(msg)
             SoundMng.isPauseVol(false)
            local msg = {
                msgID = self.deskName .. '.reloadData'
            }
            print("reloadData send ======>>>>")
            app.conn:send(msg)
        end),

        self.desk:on('reloadData', function()
            -- dump(msg)
            if not self.lockReload then
                self.lockReload = true
                print("reloadData <<<<<========")
                self.view:recoveryDesk(self.desk, true)
                self.view:freshControlView()
                self:timerSyn()
                self.lockReload = false

                local bgmFlag = SoundMng.getEftFlag(SoundMng.type[1])
                local EftFlag = SoundMng.getEftFlag(SoundMng.type[2])
                local bgmVol, sfxVol = SoundMng.getVol()
                if bgmFlag == nil then
                    bgmFlag = true
                end
                    if EftFlag == nil then
                    EftFlag = true
                end
                SoundMng.setBgmVol(bgmVol)
                SoundMng.setSfxVol(sfxVol)
                if bgmFlag == nil then
                    bgmFlag = true
                end
                 if EftFlag == nil then
                    EftFlag = true
                end
                SoundMng.setBgmFlag(bgmFlag)
                SoundMng.setEftFlag(EftFlag)
            end
        end),

        self.desk:on('somebodyCancelTrusteeship', function(msg)
            -- dump(msg)
            local name = self.desk:getPlayerPosKey(msg.uid)
            if self.desk.isPlayer then
                if name == "bottom" then
                    self.view:freshTrusteeshipLayer(false)
                end
            end
            self.view:freshTrusteeshipIcon(name, false)
        end),
        
        self.desk:on('somebodyTrusteeship', function(msg)
            -- dump(msg)
            local name = self.desk:getPlayerPosKey(msg.uid)
            if self.desk.isPlayer then
                if name == "bottom" then
                    self.view:freshTrusteeshipLayer(true)
                end
            end
            self.view:freshTrusteeshipIcon(name, true)
        end),
    }

    self:postAppendListens()

    self.view:layout(self.desk)

    local played = self.desk.info.isPlaying
    self.desk:setGamePlaying(played)
    if not played then

        --print(" -> !!!!! XYDeskController game enter 11111 !!!!! ...")
        for _, v in pairs(self.desk.players) do
            local name = self.desk:getPlayerPosKey(v.actor.uid)
            self.view:freshHeadInfo(name, v.actor)
            self.view:freshSeate(name, true)

            if v.actor.isPrepare and v.actor.isPrepare == true then
                self.view:freshReadyState(name, true)
            end
        end

        self.desk.info.number = 1
        self.view:freshInviteFriend(self.desk.isPlayer)
        self.view:freshPrepareBtn(self.desk.isPlayer)
        self.view:freshStatusText(true, 2)
    else
        --print(" -> @@@@@ XYDeskController -> recoveryDesk game enter 22222 @@@@@ ...")
        if not self.lockReload then
            self.lockReload = true
            self.view:recoveryDesk(self.desk)
            self.view:freshControlView()
            self.lockReload = false
        end
    end
    self.view:freshControlView()
    self:timerSyn()
    -- 点击坐下自动准备
    if self.desk.isPlayer and not played then
        self:clickPrepare()
    end
end


function XYDeskController:postAppendListens()
end

function XYDeskController:onQiangZhuang()
end

function XYDeskController:onNewBanker(msg)
    local name = self.desk:getPlayerPosKey(msg.uid)
    self.view:hideQZBet()
    self.view:freshBankerState(name, true, msg)
end

-- 显示作弊信息
function XYDeskController:onCheatInfo(msg)
    self.view:freshCheatView(msg)
end

function XYDeskController:onDealt(msg)
    --self.view:freshCardsDisplay('bottom', msg.mycards)
    if self.desk.isInMatch then
        self.view:freshCardsAction('bottom', msg.advanced)
    end

    local info = self.desk.info
    local gameplay = info.deskInfo.gameplay

    for _, v in ipairs(msg.others) do
        local name = self.desk:getPlayerPosKey(v)
        print('11111111111111111111')
        print(name)
        self.view:freshCardsAction(name)
        self.view:dispalyCuoPai(name)
    end
    SoundMng.playEft('poker_deal.mp3')
    
end

function XYDeskController:onStart(msg)
    self.view:freshInviteFriend(false)
    --print(" -> start onStart ***********************")
    local arr = msg.arrUid
    for _, v in ipairs(arr) do
        local name = self.desk:getPlayerPosKey(v)
        --print(' -> seat name : ', name)
        self.view:clearDesk(name)
        self.view:freshReadyState(name, false)
    end
    self.view:freshRoomInfo(self.desk.info, true)
    --print('9999999999999999999999999999999999')
    --print(' XYDeskController:onStart  tbBasebet = ' .. self.desk.info.deskInfo.base)
    --self.tbBasebet = self.desk.info.deskInfo.base
    local gameplay = self.desk.info.deskInfo.gameplay
    if gameplay ~= 5 and gameplay ~= 3 and gameplay ~= 4 and gameplay ~= 7 then
        self.view:freshBankerState(msg.banker, true)
    end
    SoundMng.playEft('room_dingding.mp3')
    --print(" -> end  onStart ***********************")
end

function XYDeskController:sendMsgRequestSitdown()
    local msg = {
        msgID = self.deskName .. '.requestSitdown'
    }
    app.conn:send(msg)
end

function XYDeskController:sendMsgPrepare()
    local msg = {
        msgID = self.deskName .. '.prepare'
    }
    app.conn:send(msg)

    self.isPlayingGame = true;
end

function XYDeskController:sendMsgStartGame()
    local msg = {
        msgID = self.deskName .. '.bankerStart'
    }
    app.conn:send(msg)
end

-- function XYDeskController:clickBettingOne()
--     SoundMng.playEft('btn_click.mp3')
--     self:sendMsgOfBetting(self, 1)
-- end

-- function XYDeskController:clickBettingDouble()
--     SoundMng.playEft('btn_click.mp3')
--     self:sendMsgOfBetting(self, 2)
-- end

-- function XYDeskController:clickBettingTriple()
--     SoundMng.playEft('btn_click.mp3')
--     self:sendMsgOfBetting(self, 3)
-- end

function XYDeskController:clickNoNiuniu()
    SoundMng.playEft('btn_click.mp3')
    local player = self.desk:getMe()
    local nn = self.desk:findNiuniu(player.mycards)
    if nn then
        self.desk.emitter:emit('chooseResult', "请再计算一下真的有牛哦 ...")
        return
    end
    self.desk:noNiuniu()
    self:timerFinish()
end

function XYDeskController:clickHaveNiuniu()
    SoundMng.playEft('btn_click.mp3')
    local bool = self.desk:checkEstimateInput()
    if not bool then
        self.desk.emitter:emit('chooseResult', "请选择合适的手牌 ...")
        return
    end
    self.desk:haveNiuniu()
    self:timerFinish()
end

function XYDeskController:clickContinue()
    SoundMng.playEft('btn_click.mp3')
    self.view:freshContinue(false)
    self.view:clearDesk('bottom')
    self:sendMsgPrepare()
end

function XYDeskController:playEftNN(name, msg)
    if name == 'bottom' and msg.niuCnt ~= -1 then
        local player = self.desk.players[1]
        local actor = player.actor
        local sex = actor.sex
        --local n = sex == 0 and 'man' or 'woman'
        local path = 'cscompare/' .. tostring('f'..sex.."_nn" .. msg.niuCnt .. '.mp3')
        SoundMng.playEftEx(path)
    end
end

local function widgetAction(self, controllerName, args)
    SoundMng.playEft('btn_click.mp3')
    local ctrl = Controller:load(controllerName, args)
    self:add(ctrl)
    

    app.layers.ui:addChild(ctrl.view)
    ctrl.view:setPositionX(display.width)

    --TranslateView.moveCtrl(ctrl.view, -1)
    TranslateView.fadeIn(ctrl.view, -1)
    ctrl:on('back', function()
        --[[TranslateView.moveCtrl(ctrl.view, 1, function()
            ctrl:delete()
        end)]]
        TranslateView.fadeOut(ctrl.view, 1, function()
            ctrl:delete()
        end)
    end)
end

function XYDeskController:handleClickHead(args)
    widgetAction(self, 'PersonalPageController', args)
end

function XYDeskController:clickMsg()
    widgetAction(self, 'XYChatController', self.desk)
end

function XYDeskController:clickSetting()
    -- self:timerFinish()
    widgetAction(self, 'SettingController')
end

function XYDeskController:clickGameSetting()
    -- self:timerFinish()
    widgetAction(self, 'SettingController')
end

function XYDeskController:clickWatcherList()
    widgetAction(self, 'XYWatcherListController', self.desk)
end

function XYDeskController:timerSyn()
    local info = self.desk.info 
    local desk = self.desk

    if desk.curState ~= "" and self.timerUpt and info.gameTick ~= 0 then
        self.time = math.floor(info.gameTick/1000)
    end

    if self.desk.info.played and not self.desk:isGamePlaying() then
        if info.readyTimerStart then
            self.view:freshStatusText(true, 3, math.floor(info.readyTick/1000))
        end
    end
end

function XYDeskController:timerStart(key, countdown, callback)
    if self.timerUpt then
        self:timerFinish()
    end

    self.view:freshCDHint(key)
    self.time = countdown
    local delay = 0
  
    self.timerUpt = Scheduler.new(function(dt)
        delay = delay + dt
        if delay > 1 then
            --delay, self.time = 0, self.time - 1
            delay = 0
            self.time = self.time - 1
        end

        self.view:freshTimer(self.time, true)

        if self.time == 0 then
            self:timerFinish()
            if callback then callback() end
        end
    end)


    self.view:freshStateViews()
end


function XYDeskController:timerFinish()
    if self.timerUpt then
        self.time = 0
        self.view:freshTimer(self.time, false)
        Scheduler.delete(self.timerUpt)
        self.timerUpt = nil
    end
end

local writable = cc.FileUtils:getInstance():getWritablePath()

function XYDeskController:handleVoice()
    local record = require('record.record')

    self.recording = true
    self.view:doVoiceAnimation()
    cc.FileUtils:getInstance():removeFile(writable..'record')
    cc.FileUtils:getInstance():removeFile(writable..'record.mp3')

    record.go(writable .. 'record')
    self:destroyRecordF()

    local delay = 0
    self.total = 0
    self.recordF = Scheduler.new(function(dt)
        delay = delay + dt
        if delay > 1 then
            delay = 0
            --print('getAmplitude',record.getAmplitude())
        end

        self.total = self.total + dt
        self.view:updateCountdownVoice(self.total)

        if self.total >= 20 then
            self:releaseVoice()
        end
    end)
end

function XYDeskController:destroyRecordF()
    if self.recordF then
        Scheduler.delete(self.recordF)
        self.recordF = nil
    end
end

function XYDeskController:pressVoice()
  self:handleVoice()
end

function XYDeskController:releaseVoice()
    if not self.recording then return end

    self.recording = nil
    self:destroyRecordF()
    self.view:removeVoiceAnimation(self.total < 1)

    local record = require('record.record')

    if self.total < 2 then
        tools.showRemind('录音时间不能少于2秒哦!')
        record.stopRecording(function()end)
        return
    end

    record.stopRecording(function()
        local delayA = cc.DelayTime:create(0.1)
        self.view:runAction(cc.Sequence:create(delayA, cc.CallFunc:create(function()
            local lame = require('lame')
            lame.convert(writable .. 'record',writable .. 'record.mp3', device.platform)
            self:uploadVoice(writable .. 'record.mp3', function(filename)
                self:notifyServer(filename,self.total)
            end)
        end)))
    end)

    self:destroyRecordF()
end

function XYDeskController:pauseBGM()
    if self.isPausedBGM then
        return
    end

    self.isPausedBGM = true

    self.lstBgmFlg = SoundMng.getEftFlag(SoundMng.type[1])
    self.lstSfxFlg = SoundMng.getEftFlag(SoundMng.type[2])

    self.lstBgmVol, self.lstSfxVol = SoundMng.getVol()
    if self.lstBgmFlg == nil then
        self.lstBgmFlg = true
    end
    if self.lstSfxFlg == nil then
        self.lstSfxFlg = true
    end

    SoundMng.setBgmFlag(false)
    SoundMng.setEftFlag(false)
end

function XYDeskController:resumeBGM()
    if self.isPausedBGM then
        SoundMng.setBgmFlag(self.lstBgmFlg)
        SoundMng.setEftFlag(self.lstSfxFlg)

        SoundMng.setBgmVol(self.lstBgmVol)
        SoundMng.setSfxVol(self.lstSfxVol)

        self.isPausedBGM = false
    end
end

function XYDeskController:playVoiceInQueue()
    if #self.voiceQueue == 0 then
        return false
    end

    local msg = self.voiceQueue[1]
    table.remove(self.voiceQueue,1)

    self:playVoice(msg.filename,msg.uid,msg.total)
    return true
end

local config = require('config')
local host = config.host..':1990'

function XYDeskController:playVoice(filename, uid, total, dontNotifyView) -- luacheck:ignore
    self.isPlayingVoice = true

    -- 获取原本音量
    local bgmVol,sfxVol = SoundMng.getVol()
    print('uid,total is ',uid,total)

    local cache = require('app.helpers.cache')
    cache.get('http://'..host..'/'..filename,function(ok,path)
        if not self.view then return end

        if ok then
            self:pauseBGM()
            -- 播放语音聊天时将音量设置为最大
            SoundMng.setBgmVol(1)
            SoundMng.setSfxVol(1)

            if device.platform == 'android' then
                --audio.playMusic(path,false)
                SoundMng.playVoice(path)
            else
                --audio.playSound(path)
                SoundMng.playVoice(path)
            end

            if not dontNotifyView then
                self.view:somebodyVoice(uid,total)
            end

            local delay = cc.DelayTime:create(total)
            self.view:runAction(cc.Sequence:create(delay,cc.CallFunc:create(function()
                self.isPlayingVoice = false

                local flg = self:playVoiceInQueue()
                if not flg then
                    self:resumeBGM()
                    -- 播放背景音乐时设置为用户设置的音量
                    SoundMng.setBgmVol(bgmVol)
                    SoundMng.setSfxVol(sfxVol)
                end
            end)))
        else
            self.isPlayingVoice = false
            self:playVoiceInQueue()
        end
    end, true, nil, nil, nil, '.mp3')
end


function XYDeskController:notifyServer(filename, total) --luacheck
    local msg = {
        msgID = 'playVoice',
        filename = filename,
        total = total
    }
    print('call notifyServer*****')

    app.conn:send(msg)
end

function XYDeskController:uploadVoice(uploadPath, callback) --luacheck:ignore
    local http = require('http')
    local data = cc.FileUtils:getInstance():getDataFromFile(uploadPath)
    print('#data is ',#data)
    local opt = {
        host = host,
        path = '',
        method = 'POST'
    }

    local req = http.request(opt, function(response)
        local cjson = require('cjson')
        local body = response.body
        body = cjson.decode(body)

        if body and body.success then
            local filename = body.filename
            callback(filename)
        end
    end)
    req:write(data)
    req:done()
end

function XYDeskController:clickSitdown()
    self.view:freshWatcherBtn(false)
    self:sendMsgRequestSitdown()
    self.view:freshBtnPos()
    
    --self:clickPrepare()
end

function XYDeskController:clickPrepare()
    self.view:freshPrepareBtn(false)
    self:sendMsgPrepare()
    self.view:freshBtnPos()
end

function XYDeskController:clickGameStart()
    self.view:freshGameStartBtn(false)
    self:sendMsgStartGame()
    self.view:freshBtnPos()
end

function XYDeskController:clickPlaybackBtn()
    widgetAction(self, 'PlaybackController', self.desk)
end

function XYDeskController:clickOut()
    self.view:gameSettingAction('Out')
end

function XYDeskController:clickIn()
    self.view:gameSettingAction('In')
    self.view:freshControlView()
end

function XYDeskController:clickInfoIn()
    self.desk:deskRecord()
    self.view:gameInfoAction('In')
end

function XYDeskController:clickInfoOut()
    self.view:gameInfoAction('Out')
end

function XYDeskController:clickLeave()
    

    repeat
        -- 观战者直接离开
        if not self.desk.isPlayer then break end

        -- 玩家游戏开始才能离开
        local played = self.desk.info.played
        if played then
            return
        end
    until true

    self:timerFinish()

    -- 离开房间
    local msg = {
        msgID = self.deskName .. '.leaveRoom'
    }
    app.conn:send(msg)
    app:switch('LobbyController')
end

function XYDeskController:clickDismiss()
	
	local players = self.desk.players
	dump(players)
	
	if self.desk:isGamePlaying() then
		tools.showRemind('牌局未结束不能解散房间...')
	else
		self:timerFinish()
		local msg = {
			msgID = self.deskName .. '.overgame'
		}
		app.conn:send(msg)
	end
end 

function XYDeskController:deleteApplyController()
    if self.applyCtrl then
        self.applyCtrl:delete()
        self.applyCtrl = nil
    end
end

function XYDeskController:showApplyController()
    if self.applyCtrl then
        self.applyCtrl:fresh()
    else
        local ctrl = Controller:load('ApplyController', self)
        self:add(ctrl)

        app.layers.ui:addChild(ctrl.view)
        ctrl.view:setPositionX(display.width)
        TranslateView.moveCtrl(ctrl.view, -1)

        ctrl:on('back', function()
            TranslateView.moveCtrl(ctrl.view, 1, function()
                ctrl:delete()
                self.applyCtrl = nil
            end)
        end)

        self.applyCtrl = ctrl
    end
end

function XYDeskController:clickInviteFriend()
    local invokefriend = require('app.helpers.invokefriend')
    local wfStr = self.view.wfName
    local gameplay = wfStr[self.desk.info.deskInfo.gameplay]
    invokefriend.invoke(self.desk.info, gameplay)
end

function XYDeskController:clickCopyRoomNum()
    local function getText(room,wanfa)
        local options = room.options
        if not options then
            options = room.deskInfo
        end
        local nnBei = {'牛牛5倍, ', '牛牛3倍, '}
        local specialText = ''
        local special = {"顺子牛(8倍),", '五花牛(8倍),',  
        "",
        "同花牛(8倍),", "葫芦牛(8倍),",'炸弹牛(8倍),', '五小牛(8倍),'}
        for i, v in ipairs(options.special) do
            if i == v then
                specialText = specialText .. special[v]
            end
        end
        local title = '【开心牛牛】房间号：'.. room.deskId
        local tabBaseStr = {
            ['2/4'] = '1, 2, 3',
            ['4/8'] = '4, 6, 8',
            ['5/10'] = '6, 8, 10',
        }
        local baseStr = tabBaseStr[options.base] or options.base
        local text = string.format('    底分：%s, %d局, 房主开, ', baseStr, options.round)
        text = title .. text ..wanfa..', '.. nnBei[options.multiply] ..', ' .. specialText ..' 速度加入'
        
        return text
    end
    
    local wfStr = self.view.wfName
    local gameplay = wfStr[self.desk.info.deskInfo.gameplay]
    local content = getText(self.desk.info, gameplay)
    
    if device.platform == 'android' then
        self.view:copyRoomNum(content)
    elseif device.platform == 'ios' then
        local luaoc = require('cocos.cocos2d.luaoc')
        local ok,ret = luaoc.callStaticMethod("AppController", "copyToClipboard",{ww=content})
        if ok then 
            tools.showRemind('已复制')
        end
    end
end



function XYDeskController:clickTrusteeship()
    if self.desk.isPlayer then
        self.desk:requestTrusteeship()
    end
end

function XYDeskController:clickCancelTrusteeship()
    if self.desk.isPlayer then
        self.desk:cancelTrusteeship()
    end
end


function XYDeskController:onSummaryAllRound(msg)
    self.view:freshOpBtns(false, false)
    self.view:freshInviteFriend(false)
    self.view:gameSettingAction('Out')
    self.view:freshContinue(false)
    
    msg.deskInfo = self.desk.info.deskInfo
    msg.deskId = self.desk.info.deskId
    msg.ownerName = self.desk.info.ownerName
    self.view:freshSummaryView(true, msg)
end

return XYDeskController
