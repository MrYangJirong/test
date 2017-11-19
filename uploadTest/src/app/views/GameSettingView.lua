local tools = require('app.helpers.tools')
local SoundMng = require('app.helpers.SoundMng')

local GameSettingController = {}

function GameSettingController:initialize()
end

function GameSettingController:layout()
  self.ui:setPosition(display.cx, display.cy)
  local MainPanel = self.ui:getChildByName('MainPanel')
  MainPanel:setContentSize(cc.size(display.width, display.height))
  self.MainPanel = MainPanel

  local bg = MainPanel:getChildByName('bg')
  self.bg = bg

  local bgm, sfx = SoundMng.getVol()

  local sound = bg:getChildByName('sound')
  local progress = sound:getChildByName('progress')
  progress:addEventListener(function(_, eventType)
    if eventType == 2 then
        local per = progress:getPercent()
        SoundMng.setSfxVol(per / 100)

        if per == 0 then
          SoundMng.setEftFlag(false)
        else
          SoundMng.setEftFlag(true)
        end
    end
  end)
  progress:setPercent(sfx * 100)

  local music = bg:getChildByName('music')
  local bgmprogress = music:getChildByName('progress')
  bgmprogress:addEventListener(function(_, eventType)
    if eventType == 2 then
        local per = bgmprogress:getPercent()
        SoundMng.setBgmVol(per / 100)

        if per == 0 then
          SoundMng.setBgmFlag(false)
        else
          SoundMng.setBgmFlag(true)
        end
    end
  end)
  bgmprogress:setPercent(bgm * 100)
end

function GameSettingController:changeMusic(b)
	local music = self.bg:getChildByName("music")
	
	music:getChildByName("on"):setVisible(not b)
	music:getChildByName("off"):setVisible(b)
end

function GameSettingController:changeSound(b)
	local sound = self.bg:getChildByName("sound")
	sound:getChildByName("on"):setVisible(not b)
	sound:getChildByName("off"):setVisible(b)
end


return GameSettingController
