local SoundMng = require "app.helpers.SoundMng"
local EnterRoomView = {}
function EnterRoomView:initialize()
end

function EnterRoomView:layout()
  local MainPanel = self.ui:getChildByName('MainPanel')
  MainPanel:setContentSize(cc.size(3 * display.width,display.height))
  self.ui:setPosition(display.cx,display.cy)

  self.roomNo = ''

  local bg = self.ui:getChildByName('bg')

  for i = 0,9 do
    local btn = bg:getChildByName('bt'..i)
    btn:addClickEventListener(function()
      self:clickNumber(i)
    end)
  end
end

function EnterRoomView:clickNumber(i)
  if #self.roomNo == 6 then return end
  SoundMng.playEft('btn_click.mp3')
  self.roomNo = self.roomNo..tostring(i)
  self:freshNumber()

  if #self.roomNo == 6 then
    self.emitter:emit('clickEnterGame')
  end
end

function EnterRoomView:clear()
  self.roomNo = ''
  self:freshNumber()
end

function EnterRoomView:clickDelete()
  self.roomNo = string.sub(self.roomNo,1,#self.roomNo-1)
  self:freshNumber()
end

function EnterRoomView:clickReenter()
  self:clear()
end

function EnterRoomView:clickJoin()
   if #self.roomNo == 6 then
    self.emitter:emit('clickEnterGame')
  end
end

function EnterRoomView:freshNumber()
  local bg = self.ui:getChildByName('bg')
  local numberFrame = bg:getChildByName('numberFrame')
  local list = numberFrame:getChildByName('list')

  for n = 1,6 do
    list:getChildByName('n'..n):getChildByName('number'):setString('')
  end

  local cnt = #self.roomNo
  for i = 1,cnt do
    local numUi = list:getChildByName('n'..i)
    --local idx = cnt - i + 1
    local n = string.sub(self.roomNo,i,i)
    numUi:getChildByName('number'):setString(n)
  end
end

return EnterRoomView
