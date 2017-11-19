local MessageView = {}
function MessageView:initialize()
end
local text = "        开心牛牛正式上线！热烈庆祝开心牛牛正式上线运营。开心牛牛游戏团队倾力打造又一斗牛精品，原汁原味地道斗牛经验。各种特色玩法，够麻辣够吃惊！新品上线，诚邀各路伙伴合作共赢，有兴趣的朋友可以联系我们。\n       官方代理咨询及技术问题反馈官方微信号: "

function MessageView:layout()
  self.ui:setPosition(display.cx,display.cy)
  local MainPanel = self.ui:getChildByName('MainPanel')
  MainPanel:setContentSize(cc.size(display.width,display.height))
  self.MainPanel = MainPanel
  self.Content = self.MainPanel:getChildByName("Content")
  self.text = self.Content:getChildByName("content")
  self.text:setString(text)
end

function MessageView:getNotify(msg)
  -- self.ui:getChildByName("Content"):getChildByName("title"):setString(msg.title)
  -- self.ui:getChildByName("Content"):getChildByName("content"):setString(msg.content)
end

return MessageView
