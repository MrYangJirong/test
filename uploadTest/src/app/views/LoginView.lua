local tools = require('app.helpers.tools')

local LoginView = {}
function LoginView:initialize()
end

function LoginView:layout(version)
  local MainPanel = self.ui:getChildByName('MainPanel')
  MainPanel:setContentSize(cc.size(display.width,display.height))
  MainPanel:setPosition(display.cx,display.cy)

  -- 取消logo掉落动画
  -- local logo = MainPanel:getChildByName("logo")
  -- local x = logo:getPositionX()
  -- logo:runAction(transition.sequence {
  --       cc.DelayTime:create(0.3),
  --       transition.newEasing(cc.MoveTo:create(0.9, cc.p(x, 450)), "BOUNCEOUT"),
  --     })
  local login = MainPanel:getChildByName('login')
  login:setPositionX(display.cx)

  MainPanel:getChildByName('version'):setString(tostring(version))

  --self:init3dLayer()
end

function LoginView:init3dLayer()

  local layer3D = cc.Layer:create()
  self:addChild(layer3D,999)
  layer3D:setCameraMask(cc.CameraFlag.USER1)

  self._camera = cc.Camera:createPerspective(45, display.width / display.height, 1,3000)
  self._camera:setCameraFlag(cc.CameraFlag.USER1)
  layer3D:addChild(self._camera)
  self._camera:setDepth(1)

  local node1 = cc.Node:create()
  layer3D:addChild(node1)
  --node1:setRotation3D(cc.vec3(0,0,90))

  local node = cc.Node:create()
  node1:addChild(node)
  node:setRotation3D(cc.vec3(0,0,180))

  local path = '3d/su.c3t'

  local card3d = cc.Sprite3D:create(path)
  node:addChild(card3d)
  card3d:setScale(1.3)
  card3d:setTexture('3d/test05.jpg')
  card3d:setCameraMask(cc.CameraFlag.USER1)

  

  self._camera:setPosition3D(cc.vec3(0, 0, -1400))
  self._camera:lookAt(cc.vec3(0,0,0), cc.vec3(0, 1, 0))

  local animation = cc.Animation3D:create(path)
  if nil ~= animation then
      local animate = cc.Animate3D:createWithFrames(animation,0,0)
      animate:setQuality(3)
      local speed = 0.6
      animate:setSpeed(speed)
      animate:setTag(110)

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

      card3d:runAction(animate)--(cc.Sequence:create(animate,call))--
  end
end

return LoginView
