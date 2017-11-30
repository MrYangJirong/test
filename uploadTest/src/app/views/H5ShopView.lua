local tools = require('app.helpers.tools')
local app = require("app.App"):instance()
local SoundMng = require "app.helpers.SoundMng"
local ShowWaiting = require('app.helpers.ShowWaiting')

local H5ShopView = {}
function H5ShopView:initialize()
	
end

function H5ShopView:layout()
	local MainPanel = self.ui:getChildByName('MainPanel')
	MainPanel:setContentSize(cc.size(display.width, display.height))
	MainPanel:setPosition(display.cx, display.cy)
	self.MainPanel = MainPanel

    local content = self.MainPanel:getChildByName('Content')
    local closeBtn = content:getChildByName('close')
    local bg = content:getChildByName('bg')
    local Panel = content:getChildByName('Panel_1')

    local type = 0
    if device.platform == 'android' then type = 1 end
    if device.platform == 'ios' then  type = 2 end
    local playerId = app.session.user.playerId

    self.webLayer = self.MainPanel:getChildByName('webLayer')

    -- self.baseUrl = string.format("http://pay.rongxin020.com/pay/a/test.php?playerId=%s&type=%s&isTiao=1&num=%s",playerId, type, "%s")
    self.baseUrl = string.format("http://192.168.1.122/qianyifu/index.php?playerId=%s&type=%s&num=%s", playerId, type, "%s")

    if device.platform == 'ios' or device.platform == 'android' then
        -- 添加网页
        -- local sizePanel = self.webLayer:getChildByName('Panel1')
        -- self.webView = ccexp.WebView:create()
        -- self.webView:setPosition(sizePanel:getPosition())
        -- self.webView:setContentSize(sizePanel:getContentSize())
        -- self.webView:setScalesPageToFit(true)
        -- -- local url = string.format( "http://pay.rongxin020.com/pay/a/test.php?playerId=%s", playerId)
        -- -- self.webView:loadURL(url)
        -- self.webLayer:addChild(self.webView)
        -- sizePanel:setVisible(false)
    else
        -- windows 测试大小
        -- local tmpSp = cc.Sprite:create("res/views/contactus/c.png")
        -- tmpSp:setPosition(Panel:getPosition())
        -- tmpSp:setContentSize(Panel:getContentSize())
        -- content:addChild(tmpSp)
        
    end

    Panel:setVisible(false)
    --closeBtn:setLocalZOrder(99)

    local touchFunc = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)            
        end
    end
    self.itemList = {}
    for i = 1, 6 do
        self.itemList[i] = content:getChildByName(string.format('Button_%s', i))
        self.itemList[i]:setTag(i)
        self.itemList[i]:setPressedActionEnabled(true)
        self.itemList[i]:addTouchEventListener(touchFunc)
    end

    self.resultView = content:getChildByName("result")
    self.resultView:setVisible(false)

end

function H5ShopView:onClickWebLayer()
    self:freshPayWebView(false)
end

function H5ShopView:freshPayWebView(bShow, link)
    if not bShow then
        local sizePanel = self.webLayer:getChildByName('Panel2')
        if self.webView then
            -- self.webView:setPosition(sizePanel:getPosition())
            self:stopLoading()
            self.webView:removeFromParent()
            self.webView = nil
        end
        self.webLayer:setVisible(false)
        return
    end

    if self.webView then
        self:stopLoading()
        self.webView:removeFromParent()
        self.webView = nil
    end
    local sizePanel = self.webLayer:getChildByName('Panel1')

    self.webView = ccexp.WebView:create()
    self.webView:setPosition(sizePanel:getPosition())
    self.webView:setContentSize(sizePanel:getContentSize())
    self.webView:setScalesPageToFit(true)
    self.webLayer:addChild(self.webView)

    self.webView:loadURL(link)
    self.webLayer:setVisible(true)
end

function H5ShopView:hideResultView()
    self.resultView:setVisible(false)
end

function H5ShopView:freshResultInfo(result)
    if not result then return end
    local diamond = self.resultView:getChildByName("diamond")
    local reward = self.resultView:getChildByName("reward")
    diamond:setString(string.format("%s", result.diamond))
    local song = (result.invite == -1) and "--" or result.song
    reward:setString(string.format("%s", song))
    self.resultView:setVisible(true)
end

function H5ShopView:onButtonClickedEvent(tag, ref)
    SoundMng.playEft('btn_click.mp3')
    
    ShowWaiting.show()
    local scheduler = cc.Director:getInstance():getScheduler()
	self.schedulerID = scheduler:scheduleScriptFunc(function()
		ShowWaiting.delete()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
	end, 3, false)

    local link = string.format(self.baseUrl, tag)
    print(tag, link)
    if device.platform == 'ios' or device.platform == 'android' then
        self:stopLoading()
        -- self.webView:loadURL(link)
        self:freshPayWebView(true, link)
        
    end

end

function H5ShopView:stopLoading()
    if device.platform == 'ios' or device.platform == 'android' then
        if self.webView then
            self.webView:stopLoading()
        end
    end
end

return H5ShopView
