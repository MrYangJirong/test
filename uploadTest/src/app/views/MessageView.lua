local MessageView = {}
function MessageView:initialize()
end

function MessageView:layout()
  self.ui:setPosition(display.cx,display.cy)
  local MainPanel = self.ui:getChildByName('MainPanel')
  MainPanel:setContentSize(cc.size(display.width,display.height))
 
end

function MessageView:getNotify(msg)
  --  self.ui:getChildByName("Content"):getChildByName("title"):setString(msg.title)
  --  self.ui:getChildByName("Content"):getChildByName("content"):setString(msg.content)
end

return MessageView
