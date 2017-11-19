local SoundMng = require('app.helpers.SoundMng')

local CreateRoomView = {}
local LocalSettings = require('app.models.LocalSettings')
local roomType = {'szOption', 'gzOption', 'zqOption', 'mqOption', 'tbOption', 'fkOption'}
local typeOptions = {'base', 'round', 'roomPrice', 'multiply', 'special', 'advanced', "szPoint", 'qzMax'}

local setVersion = 6

function CreateRoomView:initialize()
    self.options = {}

    local setPath = cc.FileUtils:getInstance():getWritablePath() .. '.CreateRoomConfig'

    if io.exists(setPath) then
        local ver = LocalSettings:getRoomConfig('setVersion')
        if (not ver) or ver < setVersion then
            cc.FileUtils:getInstance():removeFile(setPath)
        end
    end

    print("111111111111111122222222222222222222222222")
    --if LocalSettings:getRoomConfig('szOptionbase')== nil  then
    if not io.exists(cc.FileUtils:getInstance():getWritablePath() .. '.CreateRoomConfig')  then

        print(LocalSettings:getRoomConfig('szOptionbase'))
        self.options['szOption'] = { msg = {
            ['gameplay'] = 1,  ['base'] = '2/4',   ['round'] = 10,
            ['roomPrice'] = 1, ['multiply'] = 2, ['special'] = { 1, 0, 0, 0, 0, 0, 0},
            ['advanced'] = { 1, 0, 0 },
            ['putmoney'] = 1,
        } }

        self.options['gzOption'] = { msg = {
            ['gameplay'] = 2,  ['base'] = '2/4',   ['round'] = 10,
            ['roomPrice'] = 1, ['multiply'] = 2, ['special'] = { 1, 0, 0, 0, 0, 0, 0},
            ['advanced'] = { 1, 0, 0 },
            ['szPoint'] = 0,
            ['putmoney'] = 1,
        } }

        self.options['zqOption'] = { msg = {
            ['gameplay'] = 3,  ['base'] = '2/4',   ['round'] = 10,
            ['roomPrice'] = 1, ['multiply'] = 2, ['special'] = { 1, 0, 0, 0, 0, 0, 0},
            ['advanced'] = { 1, 0, 0 },
            ['putmoney'] = 1,
        } }

        self.options['mqOption'] = { msg = {
            ['gameplay'] = 4,  ['base'] = '2/4',   ['round'] = 10,
            ['roomPrice'] = 1, ['multiply'] = 2, ['special'] = { 1, 0, 0, 0, 0, 0, 0},
            ['advanced'] = { 1, 0, 0 },
            ['qzMax'] = 1,
            ['putmoney'] = 1,
        } }

        self.options['tbOption'] = { msg = {
            ['gameplay'] = 5,  ['base'] = '1',     ['round'] = 10,
            ['roomPrice'] = 1, ['multiply'] = 2, ['special'] = { 1, 0, 0, 0, 0, 0, 0},
            ['advanced'] = { 1, 0 },
            ['putmoney'] = 1,
        } }

        self.options['xnOption'] = { msg = {
            ['gameplay'] = 6,  ['base'] = '1',  ['fixedBase'] = 1,
            ['pubBase'] = 5,   ['round'] = 6, ['multiply'] = 2,
            ['roomPrice'] = 1, ['advanced'] = { 1, 0, 0 },
        } }

        self.options['fkOption'] = { msg = {
            ['gameplay'] = 7,  ['base'] = '2/4',   ['round'] = 10,
            ['roomPrice'] = 1, ['multiply'] = 2, ['special'] = { 1, 0, 0, 0, 0, 0, 0},
            ['advanced'] = { 1, 0, 0 },
            ['qzMax'] = 1,
            ['putmoney'] = 1,
        } }

        --LocalSettings:setRoomConfig('szOption',self.options['szOption'])
        --local mySzOption = LocalSettings:getRoomConfig('szOption')

        for i,v in ipairs(roomType) do
            for j,n in ipairs(typeOptions) do
                LocalSettings:setRoomConfig(v..n, self.options[v]['msg'][n])
            end
        end

        LocalSettings:setRoomConfig('setVersion', setVersion)


    else
        print(" LocalSettings:getRoomConfig(v..n) is not == nil")
        local base
        local round
        local roomPrice
        local multiply
        local special
        local advanced
        local putmoney


        local MainPanel = self.ui:getChildByName('MainPanel')
        local bg = MainPanel:getChildByName('bg') 

        for i,v in ipairs(roomType) do
            print(i)
            for j,n in ipairs(typeOptions) do
                local view = bg:getChildByName(v)
                local opView = view:getChildByName(n)
                
                if(n == 'base') then
                    base =  LocalSettings:getRoomConfig(v..n)
                     if i <= 4 or i == 6 then
                        opView:getChildByName('2/4'):getChildByName('select'):hide()
                        opView:getChildByName('4/8'):getChildByName('select'):hide()
                        opView:getChildByName('5/10'):getChildByName('select'):hide()
                    else
                        opView:getChildByName('1'):getChildByName('select'):hide()
                        opView:getChildByName('2'):getChildByName('select'):hide()
                        opView:getChildByName('4'):getChildByName('select'):hide()
                    end
                    print(base)
                    opView:getChildByName(base):getChildByName('select'):show()
                   
                elseif(n == 'round') then
                    round =  LocalSettings:getRoomConfig(v..n)

                    opView:getChildByName('10'):getChildByName('select'):hide()
                    opView:getChildByName('20'):getChildByName('select'):hide()
                    opView:getChildByName(round):getChildByName('select'):show()
                    -- 点击局数为10时 房费设置为 房主支付(      3) 和 AA支付(每人      1) 
                    -- 点击局数为10时 房费设置为 房主支付(      6) 和 AA支付(每人      2) 
                    if opView:getChildByName(round):getName() == '10' then
                        view:getChildByName('roomPrice'):getChildByName('1'):getChildByName('Text'):setString('房主支付(      3)')
                        view:getChildByName('roomPrice'):getChildByName('2'):getChildByName('Text'):setString('AA支付(每人      1)')
                    end
                    if opView:getChildByName(round):getName() == '20' then
                        view:getChildByName('roomPrice'):getChildByName('1'):getChildByName('Text'):setString('房主支付(      6)')
                        view:getChildByName('roomPrice'):getChildByName('2'):getChildByName('Text'):setString('AA支付(每人      2)')
                    end
                    
                
                elseif(n == 'roomPrice') then
                    roomPrice =  LocalSettings:getRoomConfig(v..n)
                    opView:getChildByName('1'):getChildByName('select'):hide()
                    opView:getChildByName('2'):getChildByName('select'):hide()
                    opView:getChildByName(roomPrice):getChildByName('select'):show()

                elseif(n == 'multiply') then
                    multiply =  LocalSettings:getRoomConfig(v..n)
                    
                    opView:getChildByName('sel'):getChildByName('Text'):setString(
                        opView:getChildByName('opt'):getChildByName(tostring(multiply)):getChildByName("Text"):getString()
                    )
                    if multiply == '1' then
                        opView:getChildByName('opt'):getChildByName('1'):getChildByName('select'):show()
                        opView:getChildByName('opt'):getChildByName('2'):getChildByName('select'):hide()
                    else
                        opView:getChildByName('opt'):getChildByName('1'):getChildByName('select'):hide()
                        opView:getChildByName('opt'):getChildByName('2'):getChildByName('select'):show()
                    end
                elseif(n == 'special') then
                    special =  LocalSettings:getRoomConfig(v..n)
                    for i = 1, 7 do 
                        local idxStr = tostring(i)
                        if special[i] and special[i] > 0 then
                            opView:getChildByName(idxStr):getChildByName('select'):show()
                        else
                            opView:getChildByName(idxStr):getChildByName('select'):hide()
                        end
                    end 
                elseif(n == 'putmoney') then
                    putmoney =  LocalSettings:getRoomConfig(v..n)
                    for i = 1, 4 do 
                        local idxStr = tostring(i)
                        if putmoney and (tostring(putmoney) == idxStr or  putmoney == i) then
                            opView:getChildByName(idxStr):getChildByName('select'):show()
                        else
                            opView:getChildByName(idxStr):getChildByName('select'):hide()
                        end
                    end   

                elseif(n == 'advanced') then
                    advanced =  LocalSettings:getRoomConfig(v..n)

                    if i <= 4 then
                        opView:getChildByName('1'):getChildByName('select'):hide()
                        opView:getChildByName('2'):getChildByName('select'):hide()
                        opView:getChildByName('3'):getChildByName('select'):hide()
                        if advanced[1] == 1 then
                            opView:getChildByName("1"):getChildByName('select'):show()
                        end
                        if advanced[2] == 2 then
                            opView:getChildByName("2"):getChildByName('select'):show()
                        end
                        if advanced[3] == 3 then
                            opView:getChildByName("3"):getChildByName('select'):show()
                        end
                    else
                        opView:getChildByName('1'):getChildByName('select'):hide()
                        opView:getChildByName('2'):getChildByName('select'):hide()
                        if advanced[1] == 1 then
                            opView:getChildByName("1"):getChildByName('select'):show()
                        end
                        if advanced[2] == 2 then
                            opView:getChildByName("2"):getChildByName('select'):show()
                        end
                        
                    end
                  
                end
                if(i == 2) then
                    local szPoint = LocalSettings:getRoomConfig('gzOptionszPoint')
                    self.options[v] = { msg = {
                        ['gameplay'] = i, 
                        ['base'] = base,  
                        ['round'] = tonumber(round),
                        ['roomPrice'] = tonumber(roomPrice), 
                        ['multiply'] = tonumber(multiply), 
                        ['special'] = special,
                        ['advanced'] = advanced,
                        ['szPoint'] = tonumber(szPoint),
                        ['putmoney'] = tonumber(szPoint)
                    } }
                elseif(i == 4) or (i == 6) then
                    local qzMax = LocalSettings:getRoomConfig('mqOptionqzMax')
                    self.options[v] = { msg = {
                        ['gameplay'] = (i==6) and 7 or i, 
                        ['base'] = base,  
                        ['round'] = tonumber(round),
                        ['roomPrice'] = tonumber(roomPrice), 
                        ['multiply'] = tonumber(multiply), 
                        ['special'] = special,
                        ['advanced'] = advanced,
                        ['qzMax'] = tonumber(qzMax),
                        ['putmoney'] = tonumber(szPoint)
                    } }
                else
                    self.options[v] = { msg = {
                        ['gameplay'] = i, 
                        ['base'] = base,  
                        ['round'] = tonumber(round),
                        ['roomPrice'] = tonumber(roomPrice), 
                        ['multiply'] = tonumber(multiply), 
                        ['special'] = special,
                        ['advanced'] = advanced,
                        ['putmoney'] = tonumber(szPoint)
                     } }
                end
            end
        end

        
        local szPoint = LocalSettings:getRoomConfig('gzOptionszPoint')
        local view = bg:getChildByName('gzOption')
        local opView = view:getChildByName('szPoint')
        opView:getChildByName('0'):getChildByName('select'):hide()
        opView:getChildByName('100'):getChildByName('select'):hide()
        opView:getChildByName('150'):getChildByName('select'):hide()
        opView:getChildByName('200'):getChildByName('select'):hide()
        opView:getChildByName(szPoint):getChildByName('select'):show()

        local qzMax = LocalSettings:getRoomConfig('mqOptionqzMax')
        local view = bg:getChildByName('mqOption')
        local opView = view:getChildByName('qzMax')
        opView:getChildByName('1'):getChildByName('select'):hide()
        opView:getChildByName('2'):getChildByName('select'):hide()
        opView:getChildByName('3'):getChildByName('select'):hide()
        opView:getChildByName('4'):getChildByName('select'):hide()
        opView:getChildByName(qzMax):getChildByName('select'):show()

    end
    
end

local tabs = {
    'sz', -- 牛牛上庄
    'gz', -- 固定上庄
    'zq', -- 自由抢庄
    'mq', -- 名牌抢庄
    'tb', -- 通比牛牛
    'xn',
    'fk',
}

-- "牛牛上庄" 视图配置
local szOption = {
    base = {
        type = 'radio',
        options = { '2/4', '4/8' , '5/10' },
        call = function(opt, base)
            opt.msg.base = base
        end
    },

    round = {
        type = 'radio',
        options = { '10', '20' },
        call = function(opt, round)
            opt.msg.round = tonumber(round)
        end
    },

    roomPrice = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, roomPrice)
            opt.msg.roomPrice = tonumber(roomPrice)
        end
    },

    putmoney = {
        type = 'radio',
        options = { '1', '2', '3', '4'},
        call = function(opt, putmoney)
            opt.msg['putmoney'] = tonumber(putmoney)
        end
    },

    multiply = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, multiply)
            opt.msg.multiply = tonumber(multiply)
        end
    },

    special = {
        type = 'check',
        options = { '1', '2', '3', '4', '5', '6', '7' },
        call = function(opt, name, checked)
            if checked then
                opt.msg['special'][tonumber(name)] = tonumber(name)
            else
                opt.msg['special'][tonumber(name)] = 0
            end
        end
    },

    advanced = {
        type = 'check',
        --options = { '1', '2' },
         options = { '1', '2' ,"3"},
        call = function(opt, name, checked)
            if checked then
                opt.msg['advanced'][tonumber(name)] = tonumber(name)
            else
                opt.msg['advanced'][tonumber(name)] = 0
            end
        end
    },
}

-- "固定上庄" 视图配置
local gzOption = {
    base = {
        type = 'radio',
        options = { '2/4', '4/8' , '5/10' },
        call = function(opt, base)
            opt.msg.base = base
        end
    },

    round = {
        type = 'radio',
        options = { '10', '20' },
        call = function(opt, round)
            opt.msg.round = tonumber(round)
        end
    },

    roomPrice = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, roomPrice)
            opt.msg.roomPrice = tonumber(roomPrice)
        end
    },

    putmoney = {
        type = 'radio',
        options = { '1', '2', '3', '4'},
        call = function(opt, putmoney)
            opt.msg['putmoney'] = tonumber(putmoney)
        end
    },

    multiply = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, multiply)
            opt.msg.multiply = tonumber(multiply)
        end
    },

    szPoint = {
        type = 'radio',
        options = { '0', '100', '150', '200' },
        call = function(opt, szPoint)
            opt.msg.szPoint = tonumber(szPoint)
        end
    },

    special = {
        type = 'check',
        options = { '1', '2', '3', '4', '5', '6', '7' },
        call = function(opt, name, checked)
            if checked then
                opt.msg['special'][tonumber(name)] = tonumber(name)
            else
                opt.msg['special'][tonumber(name)] = 0
            end
        end
    },

    advanced = {
        type = 'check',
        --options = { '1', '2' },
        options = { '1', '2', "3"},
        call = function(opt, name, checked)
            if checked then
                opt.msg['advanced'][tonumber(name)] = tonumber(name)
            else
                opt.msg['advanced'][tonumber(name)] = 0
            end
        end
    },
}

-- "自由抢庄" 视图配置
local zqOption = {
    base = {
        type = 'radio',
        options = { '2/4', '4/8' , '5/10' },
        call = function(opt, base)
            opt.msg.base = base
        end
    },

    round = {
        type = 'radio',
        options = { '10', '20' },
        call = function(opt, round)
            opt.msg.round = tonumber(round)
        end
    },

    roomPrice = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, roomPrice)
            opt.msg.roomPrice = tonumber(roomPrice)
        end
    },

    putmoney = {
        type = 'radio',
        options = { '1', '2', '3', '4'},
        call = function(opt, putmoney)
            opt.msg['putmoney'] = tonumber(putmoney)
        end
    },

    multiply = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, multiply)
            opt.msg.multiply = tonumber(multiply)
        end
    },

    special = {
        type = 'check',
        options = { '1', '2', '3', '4', '5', '6', '7' },
        call = function(opt, name, checked)
            if checked then
                opt.msg['special'][tonumber(name)] = tonumber(name)
            else
                opt.msg['special'][tonumber(name)] = 0
            end
        end
    },

    advanced = {
        type = 'check',
        --options = { '1', '2' },
        options = { '1', '2', "3"},
        call = function(opt, name, checked)
            if checked then
                opt.msg['advanced'][tonumber(name)] = tonumber(name)
            else
                opt.msg['advanced'][tonumber(name)] = 0
            end
        end
    },
}

-- "名牌抢庄" 视图配置
local mqOption = {
    base = {
        type = 'radio',
        options = { '2/4', '4/8' , '5/10' },
        call = function(opt, base)
            opt.msg.base = base
        end
    },

    round = {
        type = 'radio',
        options = { '10', '20' },
        call = function(opt, round)
            opt.msg.round = tonumber(round)
        end
    },

    roomPrice = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, roomPrice)
            opt.msg.roomPrice = tonumber(roomPrice)
        end
    },

    putmoney = {
        type = 'radio',
        options = { '1', '2', '3', '4'},
        call = function(opt, putmoney)
            opt.msg['putmoney'] = tonumber(putmoney)
        end
    },

    multiply = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, multiply)
            opt.msg.multiply = tonumber(multiply)
        end
    },

    qzMax = {
        type = 'radio',
        options = { '1', '2', '3', '4' },
        call = function(opt, qzMax)
            opt.msg.qzMax = tonumber(qzMax)
        end
    },

    special = {
        type = 'check',
        options = { '1', '2', '3', '4', '5', '6', '7' },
        call = function(opt, name, checked)
            if checked then
                opt.msg['special'][tonumber(name)] = tonumber(name)
            else
                opt.msg['special'][tonumber(name)] = 0
            end
        end
    },

    advanced = {
        type = 'check',
        --options = { '1', '2' },
        options = { '1', '2', "3"},
        call = function(opt, name, checked)
            if checked then
                opt.msg['advanced'][tonumber(name)] = tonumber(name)
            else
                opt.msg['advanced'][tonumber(name)] = 0
            end
        end
    },
}

-- "通比牛牛" 视图配置
local tbOption = {
    base = {
        type = 'radio',
        options = { '1', '2' , '4' },
        call = function(opt, base)
            opt.msg.base = base
        end
    },

    round = {
        type = 'radio',
        options = { '10', '20' },
        call = function(opt, round)
            opt.msg.round = tonumber(round)
        end
    },

    roomPrice = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, roomPrice)
            opt.msg.roomPrice = tonumber(roomPrice)
        end
    },

    putmoney = {
        type = 'radio',
        options = { '1', '2', '3', '4'},
        call = function(opt, putmoney)
            opt.msg['putmoney'] = tonumber(putmoney)
        end
    },
    
    multiply = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, multiply)
            opt.msg.multiply = tonumber(multiply)
        end
    },

    special = {
        type = 'check',
        options = { '1', '2', '3', '4', '5', '6', '7' },
        call = function(opt, name, checked)
            if checked then
                opt.msg['special'][tonumber(name)] = tonumber(name)
            else
                opt.msg['special'][tonumber(name)] = 0
            end
        end
    },

    advanced = {
        type = 'check',
        --options = { '1' },
        options = { '1', "2" },
        call = function(opt, name, checked)
            if checked then
                opt.msg['advanced'][tonumber(name)] = tonumber(name)
            else
                opt.msg['advanced'][tonumber(name)] = 0
            end
        end
    },
}

local xnOption = {
    base = {
        type = 'radio',
        options = { '1', '2' , '4' },
        call = function(opt, base)
            opt.msg.base = base
        end
    },

    fixedBase = {
        type = 'radio',
        options = { '1', '2', '3', '4' },
        call = function(opt, fixedBase)
            opt.msg.base = tonumber(fixedBase)
        end
    },

    pubBase = {
        type = 'radio',
        options = { '5', '10', '15', '20' },
        call = function(opt, pubBase)
            opt.msg.base = tonumber(pubBase)
        end
    },

    round = {
        type = 'radio',
        options = { '6', '10' },
        call = function(opt, round)
            opt.msg.round = tonumber(round)
        end
    },

    roomPrice = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, roomPrice)
            opt.msg.roomPrice = tonumber(roomPrice)
        end
    },

    multiply = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, multiply)
            opt.msg.multiply = tonumber(multiply)
        end
    },

    advanced = {
        type = 'check',
        options = { '1', '2' },
        call = function(opt, name, checked)
            if checked then
                opt.msg['advanced'][tonumber(name)] = tonumber(name)
            else
                opt.msg['advanced'][tonumber(name)] = 0
            end
        end
    },
}

-- "名牌抢庄" 视图配置
local fkOption = {
    base = {
        type = 'radio',
        options = { '2/4', '4/8' , '5/10' },
        call = function(opt, base)
            opt.msg.base = base
        end
    },

    round = {
        type = 'radio',
        options = { '10', '20' },
        call = function(opt, round)
            opt.msg.round = tonumber(round)
        end
    },

    roomPrice = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, roomPrice)
            opt.msg.roomPrice = tonumber(roomPrice)
        end
    },

    putmoney = {
        type = 'radio',
        options = { '1', '2', '3', '4'},
        call = function(opt, putmoney)
            opt.msg['putmoney'] = tonumber(putmoney)
        end
    },
    
    multiply = {
        type = 'radio',
        options = { '1', '2' },
        call = function(opt, multiply)
            opt.msg.multiply = tonumber(multiply)
        end
    },

    qzMax = {
        type = 'radio',
        options = { '1', '2', '3', '4' },
        call = function(opt, qzMax)
            opt.msg.qzMax = tonumber(qzMax)
        end
    },

    special = {
        type = 'check',
        options = { '1', '2', '3', '4', '5', '6', '7' },
        call = function(opt, name, checked)
            if checked then
                opt.msg['special'][tonumber(name)] = tonumber(name)
            else
                opt.msg['special'][tonumber(name)] = 0
            end
        end
    },

    advanced = {
        type = 'check',
        --options = { '1', '2' },
        options = { '1', '2', "3"},
        call = function(opt, name, checked)
            if checked then
                opt.msg['advanced'][tonumber(name)] = tonumber(name)
            else
                opt.msg['advanced'][tonumber(name)] = 0
            end
        end
    },
}

function CreateRoomView:layout(isMJ)
    local MainPanel = self.ui:getChildByName('MainPanel')
    MainPanel:setContentSize(cc.size(display.width, display.height))
    MainPanel:setPosition(display.cx, display.cy)
    self.MainPanel = MainPanel

    local bg = MainPanel:getChildByName('bg')
    bg:setPosition(display.cx, display.cy)
    self.bg = bg

    if LocalSettings:getRoomConfig("gameplay") then
        self.focus = LocalSettings:getRoomConfig("gameplay")
    else
        self.focus = 'sz'
    end
    self:freshTab()

    self:bindEvent(szOption, 'szOption')
    self:bindEvent(gzOption, 'gzOption')
    self:bindEvent(zqOption, 'zqOption')
    self:bindEvent(mqOption, 'mqOption')
    self:bindEvent(tbOption, 'tbOption')
    self:bindEvent(xnOption, 'xnOption')
    self:bindEvent(fkOption, 'fkOption')
end

function CreateRoomView:bindEvent(gameplay, optname)
    local view = self.bg:getChildByName(optname)

    for key, v in pairs(gameplay) do
        local opView = view:getChildByName(key)
        local options = v.options

        local function clear()
            for i = 1, #options do
                local name = options[i]
                local button = opView:getChildByName(name)
                button:getChildByName('select'):hide()
            end
        end

        for i = 1, #options do
            local name = options[i]
            --print('optname : ', optname, ' [ key : ', key, ']  name is ', name)

            if key == 'multiply' then
                local sel = opView:getChildByName('sel')
                local txt = sel:getChildByName('Text')
                local opt = opView:getChildByName('opt')

                local button = opt:getChildByName(name)
                button:addClickEventListener(function()
                    SoundMng.playEft('btn_click.mp3')

                    local select = button:getChildByName('select')
                    local btnTxt = button:getChildByName('Text')

                    v.call(self.options[optname], name)

                    for i = 1, #options do
                        local name = options[i]
                        local btn = opt:getChildByName(name)
                        btn:getChildByName('select'):hide()
                        view:getChildByName('multiply'):getChildByName('opt'):setVisible(false)
                        end


                    select:show()
                    txt:setString(btnTxt:getString())
                    LocalSettings:setRoomConfig(optname..opView:getName(), name)
                end)

                sel:addClickEventListener(function()
                    SoundMng.playEft('btn_click.mp3')
                    local focus = sel:getChildByName('bg'):getChildByName('focus')

                    local flag = opt:isVisible()
                    opt:setVisible(not flag)

                    if flag then
                        focus:loadTexture('res/views/createroom/aup.png')
                    else
                        focus:loadTexture('res/views/createroom/adown.png')
                    end
                end)
            else
                local button = opView:getChildByName(name)
                button:addClickEventListener(function()
                    SoundMng.playEft('btn_click.mp3')
                    local select = button:getChildByName('select')
                    print("0000000000000000000000000002222222222222222")
                    print(optname..opView:getName())

                    if v.type == 'radio' then
                        v.call(self.options[optname], name)
                        clear()
                        select:show()

                        LocalSettings:setRoomConfig(optname..opView:getName(), name)
                    else
                        local flag = select:isVisible()
                        v.call(self.options[optname], name, not flag)
                        select:setVisible(not flag)

                        local check = LocalSettings:getRoomConfig(optname..opView:getName())
                        if not flag then
                            check[tonumber(name)] = tonumber(name)
                        else
                            check[tonumber(name)] = 0
                        end
                        print(check)
                        LocalSettings:setRoomConfig(optname..opView:getName(), check)
                    end

                -- 点击局数为10时 房费设置为 房主支付(      3) 和 AA支付(每人      1) 
                -- 点击局数为10时 房费设置为 房主支付(      6) 和 AA支付(每人      2) 

                if opView:getName() == 'round' then
                    if button:getName() == '10' then
                        view:getChildByName('roomPrice'):getChildByName('1'):getChildByName('Text'):setString('房主支付(      3)')
                        view:getChildByName('roomPrice'):getChildByName('2'):getChildByName('Text'):setString('AA支付(每人      1)')
                    end
                    if button:getName() == '20' then
                        view:getChildByName('roomPrice'):getChildByName('1'):getChildByName('Text'):setString('房主支付(      6)')
                        view:getChildByName('roomPrice'):getChildByName('2'):getChildByName('Text'):setString('AA支付(每人      2)')
                    end
                end

                end)
            end
        end
    end
end

function CreateRoomView:freshTab()
    for i = 1, #tabs do
        local current = tabs[i]
        local currentItem = self.bg:getChildByName(current)
        local currentOpt = self.bg:getChildByName(current .. 'Option')

        if self.focus == current then
            currentItem:getChildByName('active'):show()
            currentOpt:show()
        else
            currentItem:getChildByName('active'):hide()
            currentOpt:hide()
        end

        currentItem:addClickEventListener(function()
            SoundMng.playEft('btn_click.mp3')
            self.focus = current
            LocalSettings:setRoomConfig("gameplay", self.focus)
            self:freshTab()
        end)
    end
end

function CreateRoomView:getOptions() -- luacheck:ignore
    SoundMng.playEft('room_dingding.mp3')
    local key = self.focus .. 'Option'
    local msg = self.options[key].msg

    -- demo
    -- msg = { ['gameplay'] = 1, ['round'] = 5, ['maxPeople'] = 3, ['point'] = 40, ['5flower5'] = 1 }

    msg.enter = {}
    msg.robot = 1
    msg.maxPeople = 6
    msg.enter.buyHorse = 0
    msg.enter.enterOnCreate = 1

    dump(msg)

    return msg
end

function CreateRoomView:freshPriceLayer(bShow) 
    self.bg:getChildByName('priceLayer'):setVisible(bShow)
end

function CreateRoomView:freshTuiZhuLayer(bShow) 
    self.bg:getChildByName('tuizhuLayer'):setVisible(bShow)
end

return CreateRoomView
