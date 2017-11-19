local ContactUsView = {}
function ContactUsView:initialize()
end

function ContactUsView:layout()
  self.ui:setPosition(display.cx,display.cy)
  local MainPanel = self.ui:getChildByName('MainPanel')
  MainPanel:setContentSize(cc.size(display.width,display.height))
  self.MainPanel = MainPanel
end

function ContactUsView:getNotify(msg)
  self.ui:getChildByName("Content"):getChildByName("title"):setString(msg.title)
 -- self.ui:getChildByName("Content"):getChildByName("content"):setString(msg.content)
end

return ContactUsView
