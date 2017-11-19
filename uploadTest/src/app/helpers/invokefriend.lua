local SocialShare = require('app.helpers.SocialShare')
local invokefriend = {}

function invokefriend.invoke(room,wanfa)
  local options = room.options
  if not options then
    options = room.deskInfo
  end

  dump(options)

  local nnBei1 = {'牛牛5倍, ', '牛牛3倍, '}
  local nnBei2 = {'1-10倍', '1-10倍'}
  
  local specialText = ''
  local special2 = {"顺子牛(8倍),", '五花牛(8倍),',  
  "",
  "同花牛(8倍),", "葫芦牛(8倍),",'炸弹牛(8倍),', '五小牛(8倍),'}

  local special1 = {"顺子牛(10倍),", '五花牛(10倍),',  
  "",
  "同花牛(10倍),", "葫芦牛(10倍),",'炸弹牛(10倍),', '五小牛(10倍),'}

  local special = special2
  local nnBei = nnBei1

  if wanfa == '疯狂加倍' then
    special = special1
    nnBei = nnBei2
  end

  for i, v in ipairs(options.special) do
    if i == v then
      specialText = specialText .. special[v]
    end
  end
  local title = '开心牛牛【房间号：'.. room.deskId ..'】'

  --local share_url = string.format('http://118.31.64.212/download.php?UserID=%s&RoomID=%s','111' ,room.deskId)
  local share_url = 'http://101.37.150.242/download'
  local image_url = 'http://101.37.150.242/icon.png'
  local tabBaseStr = {
    ['2/4'] = '1, 2, 3',
    ['4/8'] = '4, 6, 8',
    ['5/10'] = '6, 8, 10',
  }
  local baseStr = tabBaseStr[options.base] or options.base
  local text = string.format(' 底分：%s, %d局, 房主开, ', baseStr, options.round)

  text = text ..wanfa..', '.. nnBei[options.multiply] ..', ' .. specialText ..' 速度加入'
  SocialShare.share(1,function(platform,stCode,errorMsg)
    print('platform,stCode,errorMsg',platform,stCode,errorMsg)
  end,
  share_url,
  image_url,
  text,
  title)
end

return invokefriend