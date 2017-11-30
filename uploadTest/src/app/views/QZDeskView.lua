local SoundMng = require("app.helpers.SoundMng")
local XYDeskView = require('app.views.XYDeskView')
local app = require("app.App"):instance()
local QZDeskView = {}

local function mixin(self, script)
    for k, v in pairs(script) do
        -- added by hthuang: onExit can not be used
        -- assert(self[k] == nil, 'Your script "app/views/'..self.name..'.lua" should not have a member named: ' .. k)
        self[k] = v
    end
end

mixin(QZDeskView, XYDeskView)

function QZDeskView:initialize()
    XYDeskView.initialize(self)

    if self.ui then
        self.ui:removeFromParent()
        self.ui = nil
    end

    local View = require('mvc.View')
    self.ui = View.loadUI('views/XYDeskView.csb')
    self:addChild(self.ui)

    self.cardFlipKey = 160
end

function QZDeskView:layout(desk)
    XYDeskView.layout(self, desk)
end

function QZDeskView:freshQZBar(bool, qzMax)
    local qzbar = self.MainPanel:getChildByName('qzbar')
    if not bool then
        qzbar:setVisible(false)
        return
    end

    qzbar:setScrollBarEnabled(false)
    local noBtn = qzbar:getChildByName('no')
    noBtn:setVisible(true)
    qzbar:getChildByName('one'):setVisible(false)
    qzbar:getChildByName('double'):setVisible(false)
    qzbar:getChildByName('triple'):setVisible(false)
    qzbar:getChildByName('four'):setVisible(false)


    if qzMax >= 1 then
        qzbar:getChildByName('one'):setVisible(true)
    end
    if qzMax >= 2 then
        qzbar:getChildByName('double'):setVisible(true)
    end
    if qzMax >= 3 then
        qzbar:getChildByName('triple'):setVisible(true)
    end
    if qzMax >= 4 then
        qzbar:getChildByName('four'):setVisible(true)
    end

    local margin = qzbar:getItemsMargin()
    local cnt = qzMax + 1
    local itemWidth = noBtn:getContentSize().width * noBtn:getScaleX()
    local listWidth = (itemWidth*cnt) + (margin*(cnt-1))
    local posX = display.cx - (listWidth/2)

    qzbar:setPositionX(posX)
    qzbar:setVisible(true)
end

function QZDeskView:freshQZBar_bak(bool, qzMax)
	local qzbar = self.MainPanel:getChildByName('qzbar')
	
	local no = qzbar:getChildByName('no')
	local one = qzbar:getChildByName('one')
	local double = qzbar:getChildByName('double')
	local triple = qzbar:getChildByName('triple')
	local four = qzbar:getChildByName('four')
	
	local posY = no:getPositionY()
	local qzbarSz = qzbar:getContentSize()
	
	if qzMax == 1 then
		-- no:setPosition(cc.p(qzbarSz.width / 2 - 51, posY))
		-- one:setPosition(cc.p(qzbarSz.width / 2 + 51, posY))
		no:setPosition(cc.p(216, posY))
		one:setPosition(cc.p(326, posY))           
		
		no:setVisible(true)
		one:setVisible(true)
	elseif qzMax == 2 then
		-- no:setPosition(cc.p(qzbarSz.width / 2 - 101, posY))
		-- one:setPosition(cc.p(qzbarSz.width / 2, posY))
		-- double:setPosition(cc.p(qzbarSz.width / 2 + 101, posY))
		no:setPosition(cc.p(157, posY))
		one:setPosition(cc.p(264.00, posY))
		double:setPosition(cc.p(371, posY))           
		
		no:setVisible(true)
		one:setVisible(true)
		double:setVisible(true)
	elseif qzMax == 3 then
		-- no:setPosition(cc.p(qzbarSz.width / 2 - 151, posY))
		-- one:setPosition(cc.p(qzbarSz.width / 2 - 51, posY))
		-- double:setPosition(cc.p(qzbarSz.width / 2 + 51, posY))
		-- triple:setPosition(cc.p(qzbarSz.width / 2 + 151, posY))
		no:setPosition(cc.p(101.00, posY))
		one:setPosition(cc.p(210.00, posY))
		double:setPosition(cc.p(319.00, posY))
		triple:setPosition(cc.p(428.00, posY))        
		
		no:setVisible(true)
		one:setVisible(true)
		double:setVisible(true)
		triple:setVisible(true)
	elseif qzMax == 4 then
		-- no:setPosition(cc.p(qzbarSz.width / 2 - 202, posY))
		-- one:setPosition(cc.p(qzbarSz.width / 2 - 101, posY))
		-- double:setPosition(cc.p(qzbarSz.width / 2, posY))
		-- triple:setPosition(cc.p(qzbarSz.width / 2 + 101, posY))
		-- four:setPosition(cc.p(qzbarSz.width / 2 + 202, posY))
		no:setPosition(cc.p(54.87, posY))
		one:setPosition(cc.p(160.66, posY))
		double:setPosition(cc.p(266.44, posY))
		triple:setPosition(cc.p(372.23, posY))
		four:setPosition(cc.p(478.01, posY))          
		
		no:setVisible(true)
		one:setVisible(true)
		double:setVisible(true)
		triple:setVisible(true)
		four:setVisible(true)
	end
	
	if bool == false then
		no:setVisible(false)
		one:setVisible(false)
		double:setVisible(false)
		triple:setVisible(false)
		four:setVisible(false)
	end
	

	qzbar:setVisible(bool)
end 

function QZDeskView:setCardsVisible(name, bool)
    local component = self.MainPanel:getChildByName(name)
    if not component then return end

    local cards = component:getChildByName('cards')
    for i = 1, 5 do
        local card = cards:getChildByName('card' .. i)
        card:setVisible(bool)
    end
end

-- function QZDeskView:setFaceDisplay(card, flag, value)
--     if not card then return end

--     local path
--     if flag == 'front' then
--         local suit = self.suit_2_path[self:card_suit(value)]
--         local rnk = self:card_rank(value)

--         if suit == 'j1' or suit == 'j2' then
--             path = 'views/xydesk/cards/' .. suit .. '.png'
--             --print(" -> front [ suit : " .. suit .. " ]")
--         else
--             path = 'views/xydesk/cards/' .. suit .. rnk .. '.png'
--             --print(" -> front [ suit : " .. suit .. " ][ rnk : " .. rnk .." ]")
--         end
--     elseif flag == 'back' then
--         local app = require("app.App"):instance()
--         local idx = app.localSettings:get('cuoPai')
--         idx = idx or 1
--         path = 'views/xydesk/cards/xpaibei_' .. idx .. '.png'
--     end
--     card:loadTexture(path)
-- end

function QZDeskView:setPlayerCardsDisplay(name, flag, head, tail, mycards)
    local component = self.MainPanel:getChildByName(name)
    if not component then return end
    if head > tail then return end
    if not mycards or #mycards == 0 then return end

    local cards = component:getChildByName('cards')
    for i = head, tail do
        -- local card = cards:getChildByName('card' .. i)
        -- print(" -> [ #mycards : " .. #mycards .. " ] ")
        -- dump(mycards)
        -- if mycards and #mycards ~= 0 then
        --     self:setFaceDisplay(card, flag, mycards[i])
        -- else
        --     self:setFaceDisplay(card, flag)
        -- end
        local idx = self:getCurCuoPai()
        if mycards and #mycards ~= 0 then
            self:freshCardsTexture(name, i, mycards[i])
        else
            self:freshCardsTexture(name, i, nil, idx)
        end
    end
end

function QZDeskView:showCardsAtCuopai(data)
    local cards = self.cpLayer:getChildByName('cards')
    for i = 1, 4 do
        local card = cards:getChildByName('card' .. i)
        -- self:setFaceDisplay(card,'front',data[i])
        self:freshCardsTextureByNode(card, data[i])
        card:setVisible(true)
    end
end

function QZDeskView:showCardsStatic(name, head, tail, bool)
    local component = self.MainPanel:getChildByName(name)
    if not component then return end
    if head > tail then return end

    local cards = component:getChildByName('cards')
    cards:setVisible(bool)

    for i = head, tail do
        local card = cards:getChildByName('card' .. i)
        card:setVisible(bool)
    end
end

function QZDeskView:showCardsAction(name, head, tail, bool)
    local component = self.MainPanel:getChildByName(name)
    if not component then return end
    if head > tail then return end

    local delay, duration, offset = 0.3, 0.3, 0.15
    local cards = component:getChildByName('cards')
    cards:setVisible(bool)

    for i = head, tail do
        local card = cards:getChildByName('card' .. i)

        -- 使用原始坐标
        local oriPos = self.cardsOrgPos[name][i]

        local startPos = cards:convertToNodeSpace(cc.p(display.cx, display.cy))
        card:setPosition(startPos.x, startPos.y)

        delay = delay + offset
        local dtime = cc.DelayTime:create(delay)
        local move = cc.MoveTo:create(duration, oriPos)
        local show = cc.Show:create()
        local eft = cc.CallFunc:create(function()
            SoundMng.playEft('desk/fapai.mp3')
        end)
        local sequence = cc.Sequence:create(dtime, show, eft, move, 
            cc.CallFunc:create(function()
                if i == tail then
                    self:cardsBackToOriginSeat(name)
                    card:setVisible(true)
                    card:setScale(1)
                end
            end
        ))
        card:stopAllActions()
        
        card:runAction(sequence)

        local sc = cc.ScaleTo:create(duration, 1.0)
        local sq = cc.Sequence:create(dtime, sc)
        card:setScale(0.7)
        -- card:setVisible(true)
        card:runAction(sq)
        
    end
end

function QZDeskView:freshOpBtns(sv1, sv2)
    local component = self.MainPanel:getChildByName('bottom')
    local opt = component:getChildByName('opt')
    local step1 = opt:getChildByName('step1')
    step1:setVisible(sv1)

    local step2 = opt:getChildByName('step2')
    step2:setVisible(sv2)
end

function QZDeskView:dispalyCuoPai(name)

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

function QZDeskView:init3dLayer(cardValue)
    if not self.cpLayer then
        print("cuopai: nil cplayer")
        return
    end

    -- 层和摄像机
    local layer3D = cc.Layer:create()
    self.cpLayer:addChild(layer3D,999)
    layer3D:setCameraMask(cc.CameraFlag.USER1)
    self.layer3D = layer3D

    self.cpLayer._camera = cc.Camera:createPerspective(45, display.width / display.height, 1,3000)
    self.cpLayer._camera:setCameraFlag(cc.CameraFlag.USER1)
    self.cpLayer._camera:setDepth(2)
    layer3D:addChild(self.cpLayer._camera)

    self.cpLayer._camera:setPosition3D(cc.vec3(0, 0, 310))
    self.cpLayer._camera:lookAt(cc.vec3(0,0,0), cc.vec3(0, 0, -1))


    -- 3D精灵
    local path = '3d/wonder4.c3b'
    local path1 = '3d/wonder3.c3b'
    local card3d = cc.Sprite3D:create(path)
    local card3d1 = cc.Sprite3D:create(path1)
    self.animation = cc.Animation3D:create(path)
    self.animation1 = cc.Animation3D:create(path1)
    if not card3d or not card3d1 then
        print("cuopai: nil card3d")
        return
    end 
    layer3D:addChild(card3d)
    self.card3d = card3d
    layer3D:addChild(card3d1)
    self.card3d1 = card3d1

    local app = require("app.App"):instance()
    local idx = app.localSettings:get('cuoPai')
    idx = idx or 1

    card3d:setTexture('3d/0' .. cardValue .. '.png')
    card3d1:setTexture('3d/paibei/paibei_' .. idx .. '.png')
    card3d:setCameraMask(cc.CameraFlag.USER1)
    card3d:setPosition3D(cc.vec3(0,-1.2,300))
    card3d:setRotation3D(cc.vec3(90,0,0))
    card3d:setScale(0.12)

    card3d1:setCameraMask(cc.CameraFlag.USER1)
    card3d1:setPosition3D(cc.vec3(0,-1.2,300))
    card3d1:setRotation3D(cc.vec3(90,0,0))
    card3d1:setScale(0.12)

    self.updown = 0
    self.animationfirst = nil
    self.animationfirst1 = nil 
    self.start1 = nil   
    self.dest1 = nil 

    --牌的值
    local scardvalue = cc.Sprite:create('3d/1' .. cardValue .. '.png')
    local scardvalue1 = cc.Sprite:create('3d/1' .. cardValue .. '.png')

    if not scardvalue or not scardvalue1 then
        print("cuopai: nil scardvalue")
        return
    end 

    layer3D:addChild(scardvalue)
    self.scardvalue = scardvalue  
    layer3D:addChild(scardvalue1)
    self.scardvalue1 = scardvalue1

    scardvalue:setCameraMask(cc.CameraFlag.USER1)
    scardvalue:setPosition3D(cc.vec3(-90,-111,0))
    scardvalue:setRotation3D(cc.vec3(0,0,0))
    scardvalue:setScale(0.35)

    scardvalue1:setCameraMask(cc.CameraFlag.USER1)
    scardvalue1:setPosition3D(cc.vec3(92,35,0))
    scardvalue1:setRotation3D(cc.vec3(180,180,0))
    scardvalue1:setScale(0.35)

    scardvalue:setOpacity(0)
    scardvalue1:setOpacity(0)
end

function QZDeskView:init3dLayer_org(cardValue)
  if not self.cpLayer then
      print("cuopai: nil cplayer")
      return
  end

  local layer3D = cc.Layer:create()
  self.cpLayer:addChild(layer3D,999)
  layer3D:setCameraMask(cc.CameraFlag.USER1)
  self.layer3D = layer3D

  self.cpLayer._camera = cc.Camera:createPerspective(45, display.width / display.height, 1,3000)
  self.cpLayer._camera:setCameraFlag(cc.CameraFlag.USER1)
  layer3D:addChild(self.cpLayer._camera)
  self.cpLayer._camera:setDepth(1)

  local node1 = cc.Node:create()
  layer3D:addChild(node1)
  --node1:setRotation3D(cc.vec3(0,0,90))

  local node = cc.Node:create()
  node1:addChild(node)
  node:setRotation3D(cc.vec3(0,0,180))

  --local path = '3d/su.c3t'
  local path = '3d/su1.c3b'
  local bFileExist = cc.FileUtils:getInstance():isFileExist(path)
  print(string.format("bFileExist:%s", bFileExist))
  local card3d = cc.Sprite3D:create(path)
  print(string.format("card3d: %s", card3d))
  if not card3d then
    print("cuopai: nil card3d")
    return
  end
  node:addChild(card3d)
  local nodePos = cc.p(node:getPosition())
  node:setPosition(cc.p(nodePos.x, nodePos.y+100))
  card3d:setTexture('3d/0' .. cardValue .. '.jpg')
  card3d:setCameraMask(cc.CameraFlag.USER1)

  --local contentSize = card3d:getContentSize()
  local scale = 1.3

  card3d:setScale(scale)
  --card3d:setContentSize(cc.size(contentSize.width * scale, contentSize.height * scale))

  self.card3d = card3d

  self.cpLayer._camera:setPosition3D(cc.vec3(0, 0, -1400))
  self.cpLayer._camera:lookAt(cc.vec3(0,0,0), cc.vec3(0, 1, 0))

  self.animation = cc.Animation3D:create(path)

  --[[local call = cc.CallFunc:create(function()
        card3d:hide()

        path = '3d/sec.c3t'

        local card3d_flip = cc.Sprite3D:create(path)
        node:addChild(card3d_flip)
        card3d_flip:setTexture('3d/poker.jpg')
        card3d_flip:setCameraMask(cc.CameraFlag.USER1)

        animation = cc.Animation3D:create(path)
        if nil ~= animation then
          animate = cc.Animate3D:createWithFrames(animation,0,15)
          speed = 1.0
          animate:setSpeed(speed)

          card3d_flip:runAction(animate)
        end
        end)]]
end

function QZDeskView:freshCardFlipAction(cardValue)
    if nil ~= self.animation and not self.cardFlip then

        local app = require("app.App"):instance()
        local idx = app.localSettings:get('cuoPai')
        idx = idx or 1

        self.card3d:setTexture('3d/0'.. cardValue .. '.png')
        self.card3d1:setTexture('3d/paibei/paibei_' .. idx .. '.png')
        self.card3d:setCameraMask(cc.CameraFlag.USER1)
        self.card3d1:setCameraMask(cc.CameraFlag.USER1)

        local animate = cc.Animate3D:createWithFrames(self.animation, 51, 80)
        local animate1 = cc.Animate3D:createWithFrames(self.animation1, 51, 80)
        local speed = 1.0
        animate:setSpeed(speed)
        animate:setTag(110)
        animate1:setSpeed(speed)
        animate1:setTag(120)

        local callback = function()
            self.emitter:emit('cpBack')
        end

        local callback1 = function()
            local animate2 = cc.FadeIn:create(0.5)
            self.scardvalue:runAction(animate2)
        end

        local callback2 = function()
            local animate2 = cc.FadeIn:create(0.5)
            self.scardvalue1:runAction(animate2)
        end

        local delay = cc.DelayTime:create(1.5)
        local showcardvalue = cc.Spawn:create( cc.CallFunc:create(callback1), cc.CallFunc:create(callback2))
        local sequence = cc.Sequence:create(animate, showcardvalue,delay, cc.CallFunc:create(callback))
        local sequence1 = cc.Sequence:create(animate1, showcardvalue,delay, cc.CallFunc:create(callback))

        self.card3d:stopAllActions()
        self.card3d:runAction(sequence)
        self.card3d1:stopAllActions()
        self.card3d1:runAction(sequence1)

        self.cardFlip = true
        self.card:addTouchEventListener(function() end)
    end
end

function QZDeskView:freshCardMoveAction(derection, start, dest)
    if start < 0 or dest < 0 then
        return
    end

    if nil ~= self.animation then
        local animate = cc.Animate3D:createWithFrames(self.animation, start, dest)
        local speed = 1.0
        animate:setSpeed(speed)
        animate:setTag(110)

        if self.card3d == nil then
            return
        end
        local animate1 = cc.Animate3D:createWithFrames(self.animation1, start, dest)
        local speed = 1.0
        animate1:setSpeed(speed)
        animate1:setTag(120)

        self.card3d:stopAllActions()

        if derection == 'up' then
            self.card3d1:runAction(animate1) 
            self.card3d:runAction(animate) --(cc.Sequence:create(animate,call))--
        elseif derection == 'down' then
            self.card3d1:runAction(animate1:reverse())
            self.card3d:runAction(animate:reverse())
        elseif derection == "reset" then
            animate1:setSpeed(6.0)
            self.card3d1:runAction(
                cc.Sequence:create(animate1:reverse(),
                cc.CallFunc:create(function()
                    self.bBlockTouch = false
                    end)
                ))

            animate:setSpeed(6.0)
            self.card3d:runAction(
                cc.Sequence:create(animate:reverse(),
                cc.CallFunc:create(function()
                    self.bBlockTouch = false
                    end)
                ))
            self.animationfirst = nil
        end
    end
end

function QZDeskView:runAction1(derection, start,dest )
    --防止start<0但还没运行完动画的情况出现
    if start < 0  then
        if dest > 0 then 
            start = 0
        else return end
    end
    --调整速度 根据滑动的距离设置动画的播放速度
    local speed = nil 
    if self.difY < 0 then  
        speed = self.dify / (dest - start)
    elseif self.difY == 0 then 
        speed = 1
    else 
        speed = (self.maxdify - self.dify) / (dest - start)
    end
    if speed == 0 then 
        speed = 1 
    end
    speed = math.floor(speed + 0.5)
    self.animationfirst = cc.Animate3D:createWithFrames(self.animation,start,dest)
    self.animationfirst1 = cc.Animate3D:createWithFrames(self.animation1,start,dest)
    self.start1 = start 
    self.dest1 = dest 
    self.time1 = cc.Director:getInstance():getTimeInMilliseconds()
    self.animationfirst:setSpeed(speed)
    self.animationfirst1:setSpeed(speed)
    if derection == 'up' then
        self.card3d1:runAction(self.animationfirst1) 
        self.card3d:runAction(self.animationfirst) 
    elseif derection == 'down' then
        self.card3d1:runAction(self.animationfirst1:reverse())
        self.card3d:runAction(self.animationfirst:reverse())
    end
    if dest == 50 then 
        self:freshCardFlipAction(self.paimian)
    end
end

function QZDeskView:freshCardMoveAction1(derection,start,dest)
    --判断是否为空 是就添加第一段动画
    if self.animationfirst == nil then 
        self:runAction1(derection,start,dest)
        return
    end
    --判断上一段动画是否放完 如果没放完则调整要放的帧数
    self.time2 = cc.Director:getInstance():getTimeInMilliseconds()
    local timeadvance = (self.time2 - self.time1)
    local framesadvance = (self.dest1 - self.start1) * 1000 / 30 
    if start == 0 or framesadvance == 0 then 
        timeadvance = 0 
    end
    local frames = self.start1 + timeadvance * 30 / 1000
    local frames1 = math.ceil(frames - (dest - start))
    local frames2 = math.floor(self.dest1 - timeadvance * 30 / 1000)
    if frames1 < 0 then 
        frames1 = 0 
    end
    if self.card3d == nil or self.card3d1 == nil then
        return
    end
    --判断时间间隔 假如比牌所要的时间短就刷新start 长就直接继续播放动画
    if timeadvance > framesadvance then 
        if dest + 1 > 51 then 
            self:freshCardFlipAction(self.paimian)
        else 
            self:runAction1(derection,start,dest)
        end
    else 
        self.card3d:stopAllActions()
        self.card3d1:stopAllActions()
        if dest + 1 > 51 then
            self:runAction1(derection,math.ceil( frames ),50)
        else
            if derection == 'down' then
                if start > frames then 
                    self:runAction1(derection, frames1, math.floor(frames))      --防止回滚太快时跳过了部分动画导致不连贯
                else
                    self:runAction1(derection, start, frames2)
                end
            else
                self:runAction1(derection,math.ceil(frames + 1),dest)      --自动+1帧避免在滑动距离太短时造成重复
            end                                                                 --播放同一帧动画导致动画跳动
        end
    end
end

function QZDeskView:freshCuoPaiDisplay(bool, data)
    print("================ cuopai view ================")
    local cpLayer = self.MainPanel:getChildByName('cpLayer')
    self.cpLayer = cpLayer

    if self.cpLayer and not cpLayer:isVisible() and data then
        print("show cuopai")
        local suit = self.suit_2_path[self:card_suit(data[5])]
        local rnk = self:card_rank(data[5])
        self.paimian = suit .. rnk
        --print(' -> suit : ', suit, ' rnk : ', rnk)

        self:setCardsVisible('bottom',false)

        local card = cpLayer:getChildByName('card')
        card:setScale(1)
        self:showCardsAtCuopai(data)
        self:init3dLayer(suit .. rnk)

        self.preIdx = 0
        self.preDifY = 0
        self.cardFlip = false
        self.card = card
        self.bBlockTouch = false

        card:addTouchEventListener(function(sender, type)
            if self.bBlockTouch then
                return
            end
            
            if type == 0 then
                -- begin

                self.starpos = sender:getTouchBeganPosition()
                local beganposition = self.starpos.y
                self.beganposition = beganposition   
                local x, y = card:getPosition()
                self.orgPos = {x = x, y = y}

            elseif type == 1 then
                -- move
                --[[
                local pos = sender:getTouchMovePosition()
                local difX = self.starpos.x - pos.x
                local difY = self.starpos.y - pos.y

                local idx = math.ceil(math.abs(difY) / 8)
                local delta = idx - self.preIdx
                
                if delta ~= 0 then
                    if difY - self.preDifY > 0 then
                        if self.preIdx - 1 < 0 then return end

                        self:freshCardMoveAction('down', self.preIdx - 1, self.preIdx)
                        self.preIdx = self.preIdx - 1

                    elseif difY - self.preDifY < 0 then
                        if self.preIdx + 1 > 15 then
                            self:freshCardFlipAction(suit .. rnk)
                            return
                        end

                        self:freshCardMoveAction('up', self.preIdx, self.preIdx + 1)
                        self.preIdx = self.preIdx + 1
                    end
                    self.preDifY = difY
                end
                ]]
                local pos = sender:getTouchMovePosition()
                local difX = self.starpos.x - pos.x
                local difY = self.starpos.y - pos.y
                local dify = self.beganposition - pos.y
                local maxposition = self.beganposition
                --将鼠标点击初始位置的数值进行适当调整 避免动画播放速度过快(此处控制搓牌灵敏度)
                -- 旧版控制灵敏度(初始几帧会不灵敏 没效果)
                --[[if self.beganposition < 100 then
                    self.beganposition = self.beganposition + 100
                    dify = dify / 2
                elseif self.beganposition < 200 then
                    dify = dify / 2
                elseif self.beganposition > 400 then 
                    dify = dify * 2
                end
                if self.beganposition > 180 and self.beganposition < 200 then 
                    dify = dify * 2
                end]]
                --新版控制灵敏度
                maxposition = 640 - self.beganposition
                if self.beganposition < 100 then
                    dify = dify * 1.6
                elseif self.beganposition < 200 then 
                    dify = dify * 1.4
                elseif self.beganposition < 300 then 
                    dify = dify * 1.2
                end
                self.difY = difY
                self.dify = math.abs(dify)
                if dify > 0 then dify = 0 end 
                local getframes = math.abs(math.floor(dify * 50 / maxposition)) 
                print("difY", difY, math.abs(difY))
                print("getframes", getframes)
                if math.abs(difY) >= 1 then                              
                    if difY > 0 then
                        if self.preIdx - 1 < 0 then return  end
                        self:freshCardMoveAction1('down', getframes, self.preIdx)
                        self.preIdx = getframes
                    else
                        self.maxdify = math.abs(dify)
                        if self.preIdx >= getframes then return end
                        self:freshCardMoveAction1('up', self.preIdx, getframes)
                        self.preIdx = getframes
                    end
                    self.starpos.y = pos.y
                end
            else
                -- end
                if self.preIdx < 51 then
                    print("reset", self.preIdx)
                    self.bBlockTouch = true
                    self:freshCardMoveAction('reset', 0, self.preIdx)
                    self.preIdx = 0
                end
            end
        end)
        self.cpLayer:setVisible(true)
    elseif self.cpLayer and cpLayer:isVisible() and nil == data then
        print("hide cuopai")
        if self.layer3D then
            self.layer3D:removeFromParent(true)
            self.layer3D = nil
            self.card3d = nil
            self.card3d1 = nil
        end
        cpLayer:setVisible(false)
        self:setCardsVisible('bottom',true)
    end

    return flag
end

function QZDeskView:freshQZBet(name, num, bool)
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

function QZDeskView:freshQZNum(name, num, bool)
    local component = self.MainPanel:getChildByName(name)
    local avatar = component:getChildByName('avatar')
    local qzNum = avatar:getChildByName('qzNum')

    if num == 0 then
        qzNum:setVisible(false)
        return
    end

    local path = 'views/xydesk/result/bei/' .. num .. '.png'
    qzNum:loadTexture(path)
    qzNum:setVisible(bool)
end

function QZDeskView:hideQZBet()
    local players = self.desk.players
    for _, v in pairs(players) do
        local uid = v.actor.uid
        local name = self.desk:getPlayerPosKey(uid)
        self:freshQZBet(name, 0, false)
    end
end

return QZDeskView
