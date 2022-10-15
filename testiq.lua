script_name('CaptureTimer')
script_author('e2ernalybates')
script_description("AutoUpd")

require "lib.moonloader"
local distatus = require('moonloader').download_status
local inicfg = require 'inicfg'
local keys = require "vkeys"
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local ffi = require('ffi')
local neatjson = require('neatjson')

update_state = false

local script_vers = 1
local script_vers_text = "1.00"
local script_path = thisScript().path
local script_url = ""
local update_path = getWorkingDirectory() .. "/key-flooder.ini"
local update_url = "https://raw.githubusercontent.com/e2ernalybates/-/main/key-flooder.ini"

ffi.cdef[[
    typedef unsigned short WORD;

    typedef struct _SYSTEMTIME {
        WORD wYear;
        WORD wMonth;
        WORD wDayOfWeek;
        WORD wDay;
        WORD wHour;
        WORD wMinute;
        WORD wSecond;
        WORD wMilliseconds;
    } SYSTEMTIME, *PSYSTEMTIME;

    void GetLocalTime(
        PSYSTEMTIME lpSystemTime
    );
]]

local time = {
    hour = 0,
    min = 0,
    sec = 0,
    ms = 0
}
local state = false
local mode = 1

function main()
    repeat wait(0) until isSampAvailable()
	sampAddChatMessage("[CaptureTimer]: {FFFFFF}Скрипт успешно загружен!" , 0x9993fa)
	sampAddChatMessage("[CaptureTimer]: {FFFFFF}Автор скрипта: {ff0f0f}e2ernalybates {FFFFFF}| - Группа VK: {ff0f0f}@modslatterday" , 0x9993fa)
	sampAddChatMessage("[CaptureTimer]: {FFFFFF}Используйте команды: {a9d2de}/vTime {FFFFFF}- для выставления времени, {a9d2de}/cTime {FFFFFF}- для запуска флудера, " , 0x9993fa)
	sampAddChatMessage("[CaptureTimer]: {a9d2de}/mTime {FFFFFF}- смена команды {fffc4d}/capture {FFFFFF}или {fffc4d}/capture_biz" , 0x9993fa)
    loadSettings()
	
	sampRegisterChatCommand("update", update)
	
	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	nick = sampGetPlayerNickname(id)
	
	downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then
                sampAddChatMessage("[CaptureTimer]: {FFFFFF}Есть обновление! Версия:{fffc4d} " .. updateIni.info.vers_text, 0x9993fa)
                update_state = true
            end
            os.remove(update_path)
        end
    end)
	
    sampRegisterChatCommand('vtime', function(param) 
        local hour, min, sec, ms = param:match('(%d+) (%d+) (%d+) (%d+)')
        if hour ~= nil and min ~= nil and sec ~= nil and ms ~= nil then
            time.hour = tonumber(hour)
            time.min = tonumber(min)
            time.sec = tonumber(sec)
            time.ms = tonumber(ms)
            addMessage(string.format('Установлено: %d часов, %d минут, %d секунд, %d миллисекунд', time.hour, time.min, time.sec, time.ms))
        else
            addMessage('Используйте: /vtime [Часы] [Минуты] [Секунды] [Миллисекунды]')
        end
    end)
    sampRegisterChatCommand('ctime', function() 
        state = not state
        addMessage(state and 'Начал работу' or 'Завершил работу')
    end)
    sampRegisterChatCommand('mtime', function(param) 
        local cMode = param:match('(%d+)')
        if cMode ~= nil then
            cMode = tonumber(cMode)
            if cMode > 0 and cMode < 3 then
                mode = cMode
                addMessage(string.format('Установлен режим %d (%s)', mode, mode == 1 and '/capture' or '/capture_biz'))
            end
        else
            addMessage('Используйте: /mtime [Режим 1/2]')
        end
    end)
    while true do
        wait(0)
		if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage("Скрипт успешно обновлен!", 0x008000)
                    thisScript():reload()
                end
            end)
            break
        end
		
        if state then
            local cTime = getLocalTime()
            -- printStringNow(string.format('~g~„љeЇ ўpeЇ¬.~n~ЏekyЎee: %d:%d:%d:%d~n~Yc¦a®oўћe®o: %d:%d:%d:%d', cTime.wHour, cTime.wMinute, cTime.wSecond, cTime.wMilliseconds, time.hour, time.min, time.sec, time.ms))
            if cTime.wHour == time.hour and cTime.wMinute == time.min and cTime.wSecond == time.sec and math.abs(cTime.wMilliseconds - time.ms) < 100 then
                state = false
                for i = 1, 4 do
                    sampSendChat(mode == 1 and '/capture' or '/capture_biz')
                    wait(80)
                end
            end
        end
    end
end

function update(arg)
	sampShowDialog(1000, "Автообновление", "Текущая версия скрипта 1.0", "Закрыть", "", 0)
end


function loadSettings()
    local dir = getWorkingDirectory() .. '/config'
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    dir = dir .. '/captureTimer_mrc.json'
    if doesFileExist(dir) then
        local f = io.open(dir, 'r')
        local data = decodeJson(f:read('*a'))
        f:close()
        state = data.enabled
        time = data.time
        if data['mode'] ~= nil then
            mode = data.mode
        end
    else
        saveSettings()
    end
end

function saveSettings()
    local dir = getWorkingDirectory() .. '/config'
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    dir = dir .. '/captureTimer_mrc.json'
    local f = io.open(dir, 'w')
    f:write(neatjson({
        enabled = state,
        time = time,
        mode = mode
    }, {wrap = 40}))
    f:close()
end

function addMessage(msg)
    sampAddChatMessage(string.format('[CaptureTimer]: {FFFFFF}%s', msg), 0x9993fa)
end

function getLocalTime()
    local cTime = ffi.new("SYSTEMTIME")
    ffi.C.GetLocalTime(cTime)
    return cTime
end

function onScriptTerminate(script, quit)
    if script == thisScript() then
        saveSettings()
    end
end