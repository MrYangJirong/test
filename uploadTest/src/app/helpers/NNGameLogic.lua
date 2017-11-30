local GameLogic = {}

GameLogic.SPECIAL_EMUN = {
    WUXIAO = 7,
    BOOM = 6,
    HULU = 5,
    WUHUA_J = 3,
    WUHUA_Y = -1,
    TONGHUA = 2,
    STRAIGHT = 1,
}

GameLogic.CLIENT_SETTING = {
    WUXIAO = 7,
    BOOM = 6,
    HULU = 5,
    WUHUA_J = 3,
    WUHUA_Y = -1,
    TONGHUA = 2,
    STRAIGHT = 1,
}

GameLogic.NIU_MULNUM = {
  [7] = {
      {[2]=2, [3]=3, [4]=5, [5]=5, [6]=6, [7]=7, [8]=8, [9]=9, [10]=10},
      {[2]=2, [3]=3, [4]=5, [5]=5, [6]=6, [7]=7, [8]=8, [9]=9, [10]=10},
  },
  default = {
      { [10] = 4, [9] = 3, [8] = 2, [7] = 2 },
      { [10] = 3, [9] = 2, [8] = 2 },
  }
}

GameLogic.SPECIAL_MULNUM = {
  [7] = {
      WUXIAO = 10,
      BOOM = 10,
      HULU = 10,
      WUHUA_J = 10,
      TONGHUA = 10,
      STRAIGHT = 10,
  },
  default = {
      WUXIAO = 8,
      BOOM = 7,
      HULU = 6,
      WUHUA_J = 5,
      TONGHUA = 5,
      STRAIGHT = 5,
  }
}

GameLogic.CARDS = {
    ['♠A'] = 1,   ['♠2'] = 2,  ['♠3'] = 3,  ['♠4'] = 4, ['♠5'] = 5,
    ['♠6'] = 6,   ['♠7'] = 7,  ['♠8'] = 8,  ['♠9'] = 9,
    ['♠T'] = 10, ['♠J'] = 10, ['♠Q'] = 10, ['♠K'] = 10,

    ['♥A'] = 1,   ['♥2'] = 2,  ['♥3'] = 3,  ['♥4'] = 4, ['♥5'] = 5,
    ['♥6'] = 6,   ['♥7'] = 7,  ['♥8'] = 8,  ['♥9'] = 9,
    ['♥T'] = 10, ['♥J'] = 10, ['♥Q'] = 10, ['♥K'] = 10,

    ['♣A'] = 1,   ['♣2'] = 2,  ['♣3'] = 3,  ['♣4'] = 4, ['♣5'] = 5,
    ['♣6'] = 6,   ['♣7'] = 7,  ['♣8'] = 8,  ['♣9'] = 9,
    ['♣T'] = 10, ['♣J'] = 10, ['♣Q'] = 10, ['♣K'] = 10,

    ['♦A'] = 1,   ['♦2'] = 2,  ['♦3'] = 3,  ['♦4'] = 4, ['♦5'] = 5,
    ['♦6'] = 6,   ['♦7'] = 7,  ['♦8'] = 8,  ['♦9'] = 9,
    ['♦T'] = 10, ['♦J'] = 10, ['♦Q'] = 10, ['♦K'] = 10,
    ['☆'] = 10,   ['★'] = 10
}


GameLogic.CARDS_LOGICE_VALUE = {
    ['A'] = 1,['2'] = 2,['3'] = 3,['4'] = 4,['5'] = 5,
    ['6'] = 6,['7'] = 7,['8'] = 8,['9'] = 9,
    ['T'] = 10,['J'] = 11,['Q'] = 12,['K'] = 13,
    ['☆'] = 14, ['★'] = 15
}

local SUIT_UTF8_LENGTH = 3

local function card_suit(c)
    if not c then print(debug.traceback()) end
    if c == '☆' or c == '★' then
        return c
    else
        return #c > SUIT_UTF8_LENGTH and c:sub(1, SUIT_UTF8_LENGTH) or nil
    end
end

local function card_rank(c)
    return #c > SUIT_UTF8_LENGTH and c:sub(SUIT_UTF8_LENGTH+1, #c) or nil
end


function GameLogic.getSpecialTypeByVal(spVal)
  if spVal and spVal > 0 then
    for key, val in pairs(GameLogic.SPECIAL_EMUN) do
      if val == spVal then
        return key
      end
    end
  end
end

function GameLogic.getSpecialType(cards, setting)
  local value = GameLogic.CARDS_LOGICE_VALUE

  local tabHandSort = {}
  local tabHandVal = {} -- 牌值数组
  local tabHandSuit = {}

  local sum = 0   -- 牌值和  
  local isWUXIAO = true
  local isWUHUA_J = true
  local isWUHUA_Y = true
  local isTONGHUA = true

  local prevCard = {-1,""}
  for k, v in pairs(cards) do
    local cardVal = value[card_rank(v)]
    local cardSuit = card_suit(v)
    --{ [1]=val, [2]=suit}
    table.insert(tabHandSort, {cardVal, cardSuit})
    sum = sum + cardVal
    if cardVal > 4 then
      isWUXIAO = false
    end
    if cardVal < 11 then
      isWUHUA_J = false
    end
    if cardVal < 10 then
      isWUHUA_Y = false
    end
    if prevCard[2] ~= "" and prevCard[2] ~= cardSuit then
      isTONGHUA = false
    end
    prevCard = {cardVal, cardSuit}
  end

  table.sort(tabHandSort, function(a, b)
    return a[1] > b[1]
  end)

  for k,v in pairs(tabHandSort) do
    table.insert( tabHandVal, v[1] )
    table.insert( tabHandSuit, v[2] )
  end

  local function isEnabled(type)
    if type > 0 then
      if setting[type] and setting[type] > 0 then
        return true
      end
    end
    return false
  end

  local set = GameLogic.CLIENT_SETTING
  local spEmun = GameLogic.SPECIAL_EMUN
  local type = 0
  repeat
    -- 五小牛
    if isWUXIAO and sum <= 10 and
      isEnabled(set.WUXIAO)
    then
      type = spEmun.WUXIAO
      break
    end

    -- 炸弹牛
    if (tabHandVal[1] == tabHandVal[4] or
       tabHandVal[2] == tabHandVal[5]) and
       isEnabled(set.BOOM)
    then
      type = spEmun.BOOM
      break
    end

    -- 葫芦牛
    if ((tabHandVal[1] == tabHandVal[3] and tabHandVal[4] == tabHandVal[5]) or
       (tabHandVal[1] == tabHandVal[2] and tabHandVal[3] == tabHandVal[5])) and
       isEnabled(set.HULU)
    then
      type = spEmun.HULU
      break
    end

    -- 五花牛 金牛
    if isWUHUA_J and 
      isEnabled(set.WUHUA_J)
    then
      type = spEmun.WUHUA_J
      break
    end

    -- 金牛
    if isWUHUA_Y and
      isEnabled(set.WUHUA_Y)
    then
      type = spEmun.WUHUA_Y
      break
    end

    -- 同花
    if isTONGHUA and
      isEnabled(set.TONGHUA)
    then
      type = spEmun.TONGHUA
      break
    end

    -- 顺子
    local t = tabHandVal
    if t[1] == t[2] + 1 and
      t[2] == t[3] + 1 and
      t[3] == t[4] + 1 and
      t[4] == t[5] + 1 and
      isEnabled(set.STRAIGHT)
    then
      type = spEmun.STRAIGHT
      break
    end
  until true

  return type, GameLogic.getSpecialTypeByVal(type)
end


function GameLogic.findNiuniuByData(cards)
    local niuniusP = {}
    local keyMap = {}
    local niuniusT = {}
    local cnt = #cards
    for i = 1, cnt - 2 do
        for j = i + 1, cnt - 1 do
            for x = j + 1, cnt do
                local val1 = GameLogic.CARDS[cards[i]]
                local val2 = GameLogic.CARDS[cards[j]]
                local val3 = GameLogic.CARDS[cards[x]]
                local sum = val1 + val2 + val3
                if (sum % 10) == 0 then
                    table.insert(niuniusP, {cards[i], cards[j], cards[x]})
                    keyMap[i] = i
                    keyMap[j] = j
                    keyMap[x] = x
                    local left = {}
                    for idx = 1 , cnt do
                      if not keyMap[idx] then
                        table.insert(left, idx)
                      end
                    end
                    table.insert(niuniusT, {
                      cards[left[1]],
                      cards[left[2]],
                      })
                end
            end
        end
    end

    if table.empty(niuniusP) then
        return nil
    else
        return niuniusP, niuniusT
    end
end

function GameLogic.groupingCardData(cards, specialType)
  local retGroup = {}

  table.sort(cards, function(a, b)
    local A = GameLogic.CARDS_LOGICE_VALUE[card_rank(a)]
    local B = GameLogic.CARDS_LOGICE_VALUE[card_rank(b)]
    return (A > B)
  end)
  
  local function getVal(card)
    return GameLogic.CARDS_LOGICE_VALUE[card_rank(card)]
  end
  local val1 = getVal(cards[1])
  local val3 = getVal(cards[3])
  local val4 = getVal(cards[4])

  retGroup = {cards, {}}
  if specialType and specialType > 0 then
    -- 特殊牌
    local tpyeName = GameLogic.getSpecialTypeByVal(specialType)
    if tpyeName == "BOOM" then
      if (val1 == val4) then
        retGroup = {{cards[1], cards[2], cards[3], cards[4]}, {cards[5]}}
      else
        retGroup = {{cards[2], cards[3], cards[4], cards[5]}, {cards[1]}}
      end
    end
    if tpyeName == "HULU" then
      if (val1 == val3) then
        retGroup = {{cards[1], cards[2], cards[3]}, {cards[4], cards[5]}}
      else
        retGroup = {{cards[3], cards[4], cards[5]}, {cards[1], cards[2]}}
      end
    end
    
  else
    -- 普通牛
    local niuniusP, niuniuT = GameLogic.findNiuniuByData(cards)
    if niuniusP then
      retGroup = {niuniusP[1], niuniuT[1]}
    end
  end

  local retCards = {}
  for groupIdx = 1 , 2 do
    if retGroup[groupIdx] then
      for i1 = 1, #retGroup[groupIdx] do
        table.insert( retCards, retGroup[groupIdx][i1])
      end
    end
  end  
  return retCards, retGroup
end

function GameLogic.getMul(gamePlay, setting, niuCnt, specialTpye)
  setting = setting or 1

  if specialTpye and specialTpye > 0 then
    local type = GameLogic.getSpecialTypeByVal(specialTpye)
    local mulTab = GameLogic.SPECIAL_MULNUM.default
    if GameLogic.SPECIAL_MULNUM[gamePlay] then
      mulTab = GameLogic.SPECIAL_MULNUM[gamePlay]
    end
    return mulTab[type]
  end

  if niuCnt then
    local mulTab = GameLogic.NIU_MULNUM.default
    if GameLogic.NIU_MULNUM[gamePlay] then
      mulTab = GameLogic.NIU_MULNUM[gamePlay]
    end
    return mulTab[setting][niuCnt]
  end

end

function GameLogic.getSetting(setNum)
  for name, v in pairs(GameLogic.CLIENT_SETTING) do
    if v > 0 and setNum and v == setNum then
      return name
    end
  end
end

return GameLogic