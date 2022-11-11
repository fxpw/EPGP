--
-- GetNumRecords(): Returns the number of log records.
--
-- GetLogRecord(i): Returns the ith log record starting 0.
--
-- ExportLog(): Returns a string with the data of the exported log for
-- import into the web application.
--
-- UndoLastAction(): Removes the last entry from the log and undoes
-- its action. The undone action is not logged.
--
-- This module also fires the following messages.
--
-- LogChanged(n): Fired when the log is changed. n is the new size of
-- the log.
--

local mod = EPGP:NewModule("log", "AceComm-3.0")

local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale("EPGP")
local GS = LibStub("LibGuildStorage-1.0")
local JSON = LibStub("LibJSON-1.0")
local deformat = AceLibrary("Deformat-2.0")

local CallbackHandler = LibStub("CallbackHandler-1.0")
if not mod.callbacks then
    mod.callbacks = CallbackHandler:New(mod)
end
local callbacks = mod.callbacks

local timestamp_t = {}
local function GetTimestamp(diff)
    return time()
end

local function CheckFilter(log, str)
    return string.find(string.lower(log[3]), string.lower(str))
end

local LOG_FORMAT = "LOG:%d\31%s\31%s\31%s\31%d"
local LOG_FORMAT_NEW = "LOG:%d\31%s\31%s\31%s\31%d\31%s"

local function log(...)
    -- print("EPGP_SYNC", ...)
end

local function AppendToLog(kind, event_type, name, reason, amount, mass, undo)
    -- Clear the redo table
    if not undo then
        for k, _ in ipairs(mod.db.profile.redo) do
            mod.db.profile.redo[k] = nil
        end
    end

    local entry = { GetTimestamp(), kind, name, reason, amount, UnitName("player")}
    table.insert(mod.db.profile.log, entry)
    exists_logs[string.format(LOG_FORMAT_NEW, unpack(entry))] = true

    if CheckFilter(entry, mod.db.profile.filter) then
        table.insert(mod.db.profile.filtred_logs, entry)
    end

    mod:SendCommMessage("EPGP", string.format(LOG_FORMAT_NEW, unpack(entry)), "GUILD", nil, "BULK")
    callbacks:Fire("LogChanged", #mod.db.profile.log)
end

function mod:LogSync(prefix, msg, distribution, sender)
    if prefix == "EPGP" and sender ~= UnitName("player") then
        local timestamp, kind, name, reason, amount, officer = deformat(msg, LOG_FORMAT_NEW)
        if not timestamp then
            timestamp, kind, name, reason, amount = deformat(msg, LOG_FORMAT)
            officer = sender
        end

        if timestamp then
            local entry = { tonumber(timestamp), kind, name, reason, tonumber(amount), officer }
            table.insert(mod.db.profile.log, entry)
            if CheckFilter(entry, mod.db.profile.filter) then
                table.insert(mod.db.profile.filtred_logs, entry)
            end
            exists_logs[string.format(LOG_FORMAT_NEW, unpack(entry))] = true
            callbacks:Fire("LogChanged", #self.db.profile.log)
        end
    end
end

local function LogRecordToString(record)
    local timestamp, kind, name, reason, amount, officer = unpack(record)

    if kind == "EP" then
        return string.format(L["%s: %+d EP (%s) to %s from $s"],
            date("%Y-%m-%d %H:%M", timestamp), amount, reason, name, officer)
    elseif kind == "GP" then
        return string.format(L["%s: %+d GP (%s) to %s from $s"],
            date("%Y-%m-%d %H:%M", timestamp), amount, reason, name, officer)
    elseif kind == "BI" then
        return string.format(L["%s: %s to %s from $s"],
            date("%Y-%m-%d %H:%M", timestamp), reason, name, officer)
    else
        assert(false, "Unknown record in the log")
    end
end

function mod:SetFilter(search)
    self.db.profile.filter = search
    table.wipe(self.db.profile.filtred_logs)
    for _, log in pairs(self.db.profile.log) do
        if CheckFilter(log, search) then
            table.insert(self.db.profile.filtred_logs, log)
        end
    end

    callbacks:Fire("LogChanged", #self.db.profile.filtred_logs)
end

function mod:GetNumRecords()
    if self.db.profile.filter == "" then
        return #self.db.profile.log
    end
    return #self.db.profile.filtred_logs
end

function mod:GetLogRecord(i)
    local logs = self.db.profile.filtred_logs
    if self.db.profile.filter == "" then
        logs = self.db.profile.log
    end

    local logsize = #logs
    assert(i >= 0 and i < logsize, "Index " .. i .. " is out of bounds")

    return LogRecordToString(logs[logsize - i])
end

function mod:CanUndo()
    if not CanEditOfficerNote() or not GS:IsCurrentState() then
        return false
    end
    return #self.db.profile.log ~= 0
end

function mod:GetLastActionForUndo()
    local skip_count = 0

    for i = #self.db.profile.log, 1, -1 do
        local log = self.db.profile.log[i]

        local is_undo = string.starts(log[4], L["Undo"])
        if not is_undo and skip_count == 0 then
            return log
        end

        if is_undo then
            skip_count = skip_count + 1
        else
            skip_count = skip_count - 1
        end
    end

    return nil
end

function mod:UndoLastAction()
    assert(#self.db.profile.log ~= 0)

    local record = mod:GetLastActionForUndo()
    table.insert(self.db.profile.redo, record)

    local timestamp, kind, name, reason, amount, officer = unpack(record)

    local ep, gp, main = EPGP:GetEPGP(name)

    if kind == "EP" then
        EPGP:IncEPBy(name, L["Undo"] .. " " .. reason, -amount, false, true)
    elseif kind == "GP" then
        EPGP:IncGPBy(name, L["Undo"] .. " " .. reason, -amount, false, true)
    elseif kind == "BI" then
        EPGP:BankItem(L["Undo"] .. " " .. reason, true)
    else
        assert(false, "Unknown record in the log")
    end

    callbacks:Fire("LogChanged", #self.db.profile.log)
    return true
end

function mod:CanRedo()
    if not CanEditOfficerNote() or not GS:IsCurrentState() then
        return false
    end

    return #self.db.profile.redo ~= 0
end

function mod:RedoLastUndo()
    assert(#self.db.profile.redo ~= 0)

    local record = next(self.db.profile.redo)
    local timestamp, kind, name, reason, amount, officer = unpack(record)

    local ep, gp, main = EPGP:GetEPGP(name)
    if kind == "EP" then
        EPGP:IncEPBy(name, L["Redo"] .. " " .. reason, amount, false, true)
        table.insert(self.db.profile.log, record)
        exists_logs[string.format(LOG_FORMAT_NEW, unpack(record))] = true
    elseif kind == "GP" then
        EPGP:IncGPBy(name, L["Redo"] .. " " .. reason, amount, false, true)
        table.insert(self.db.profile.log, record)
        exists_logs[string.format(LOG_FORMAT_NEW, unpack(record))] = true
    else
        assert(false, "Unknown record in the log")
    end

    callbacks:Fire("LogChanged", #self.db.profile.log)
    return true
end

-- This is kept for historical reasons: see
-- http://code.google.com/p/epgp/issues/detail?id=350.
function mod:Snapshot()
    local t = self.db.profile.snapshot
    if not t then
        t = {}
        self.db.profile.snapshot = t
    end
    t.time = GetTimestamp()
    GS:Snapshot(t)
end

local function swap(t, i, j)
    t[i], t[j] = t[j], t[i]
end

local function reverse(t)
    for i = 1, math.floor(#t / 2) do
        swap(t, i, #t - i + 1)
    end
end

string.starts = string.starts or function(str, start)
    return string.sub(str, 1, string.len(start)) == start
end
local timeReuse = 60 * 60 * 24 * 30
function mod:TrimToOneMonth()
    -- The log is sorted in reverse timestamp. We do not want to remove
    -- one item at a time since this will result in O(n^2) time. So we
    -- build it anew.
    local new_log = {}
    local last_timestamp = GetTimestamp() - timeReuse

    -- Go through the log in reverse order and stop when we reach an
    -- entry older than one month.
    for i = #self.db.profile.log, 1, -1 do
        local record = self.db.profile.log[i]
        if record[1] < last_timestamp then
            break
        end
        table.insert(new_log, record)
    end

    -- The new log is in reverse order now so reverse it.
    reverse(new_log)

    self.db.profile.log = new_log

    callbacks:Fire("LogChanged", #self.db.profile.log)
end

function mod:Export()
    local d = {}
    d.region = GetCVar("portal")
    d.guild = select(1, GetGuildInfo("player"))
    d.realm = GetRealmName()
    d.base_gp = EPGP:GetBaseGP()
    d.min_ep = EPGP:GetMinEP()
    d.decay_p = EPGP:GetDecayPercent()
    d.extras_p = EPGP:GetExtrasPercent()
    d.timestamp = GetTimestamp()

    d.roster = EPGP:ExportRoster()

    d.loot = {}
    for i, record in ipairs(self.db.profile.log) do
        local timestamp, kind, name, reason, amount, officer = unpack(record)
        if kind == "GP" or kind == "BI" then
            local id = tonumber(reason:match("item:(%d+)"))
            if id then
                table.insert(d.loot, { timestamp, name, id, amount })
            end
        end
    end

    return JSON.Serialize(d):gsub("\124", "\124\124")
end

function mod:Import(jsonStr)
    local success, d = pcall(JSON.Deserialize, jsonStr)
    if not success then
        EPGP:Print(L["The imported data is invalid"])
        return
    end

    if d.region and d.region ~= GetCVar("portal") then
        EPGP:Print(L["The imported data is invalid"])
        return
    end

    if d.guild ~= select(1, GetGuildInfo("player")) or
        d.realm ~= GetRealmName() then
        EPGP:Print(L["The imported data is invalid"])
        return
    end

    local types = {
        timestamp = "number",
        roster = "table",
        decay_p = "number",
        extras_p = "number",
        min_ep = "number",
        base_gp = "number",
    }
    for k, t in pairs(types) do
        if type(d[k]) ~= t then
            EPGP:Print(L["The imported data is invalid"])
            return
        end
    end

    for _, entry in pairs(d.roster) do
        if type(entry) ~= "table" then
            EPGP:Print(L["The imported data is invalid"])
            return
        else
            local types = {
                [1] = "string",
                [2] = "number",
                [3] = "number",
            }
            for k, t in pairs(types) do
                if type(entry[k]) ~= t then
                    EPGP:Print(L["The imported data is invalid"])
                    return
                end
            end
        end
    end

    EPGP:Print(L["Importing data snapshot taken at: %s"]:format(
        date("%Y-%m-%d %H:%M", d.timestamp)))
    EPGP:SetGlobalConfiguration(d.decay_p, d.extras_p, d.base_gp, d.min_ep)
    EPGP:ImportRoster(d.roster, d.base_gp)

    -- Trim the log if necessary.
    local timestamp = d.timestamp
    while true do
        local records = #self.db.profile.log
        if records == 0 then
            break
        end

        if self.db.profile.log[records][1] > timestamp then
            table.remove(self.db.profile.log)
        else
            break
        end
    end
    -- Add the redos back to the log if necessary.
    while #self.db.profile.redo ~= 0 do
        local record = table.remove(self.db.profile.redo)
        if record[1] < timestamp then
            table.insert(self.db.profile.log, record)
            exists_logs[string.format(LOG_FORMAT_NEW, unpack(record))] = true
        end
    end

    callbacks:Fire("LogChanged", #self.db.profile.log)
end

mod.dbDefaults = {
    profile = {
        enabled = true,
        log = {},
        redo = {},
    }
}

local sync_logs = {}
local sync_players_in_progress = {}
local self_player_name = UnitName("player")
exists_logs = {}
function mod:EPGP_SYNC_REQUEST(tag, msg, channel, sender)
    if channel ~= "GUILD" then
        return
    end

    if sender == self_player_name then
        return
    end

    local from_timestamp = tonumber(msg)
    local logs = self.db.profile.log
    local logs_for_sync = {}

    for i = #logs, 1, -1 do
        local log = logs[i]

        if log[1] > from_timestamp then
            table.insert(logs_for_sync, 1, log)
        end
    end

    log("Получили запрос на синхронизацию логов от " .. sender .. ". Отправляем", #logs_for_sync, "логов")

    for _, log in ipairs(logs_for_sync) do
        mod:SendCommMessage("EPGP_SYNC_LOG", string.format(LOG_FORMAT_NEW, unpack(log)), "WHISPER", sender)
    end

    mod:SendCommMessage("EPGP_SYNC_LOG", "END:" .. tostring(#logs_for_sync), "WHISPER", sender)
end

function mod:EPGP_SYNC_LOG(tag, msg, channel, sender)
    if channel ~= "WHISPER" then
        return
    end

    if sender == self_player_name then
        return
    end

    if not GS:GetRank(sender) then
        log(sender, "не находится в гильдии, но предлагает синхронизовать его логи!? wtf")
        return
    end

    if string.starts(msg, "END") then
        return self:EPGP_SYNC_RESPONSE(tag, msg, channel, sender)
    end

    if exists_logs[msg] then
        return
    end

    local members_with_logs = sync_logs[msg] or {}
    local member_exists = false
    for _, member in pairs(members_with_logs) do
        if member == sender then
            member_exists = true
        end
    end
    if not member_exists then
        table.insert(members_with_logs, sender)
    end
    sync_logs[msg] = members_with_logs

    if #members_with_logs == 2 then
        local timestamp, kind, name, reason, amount, officer = deformat(msg, LOG_FORMAT_NEW)
        if not timestamp then
            timestamp, kind, name, reason, amount = deformat(msg, LOG_FORMAT)
            officer = "Unknown"
        end

        if timestamp then
            local entry = { tonumber(timestamp), kind, name, reason, tonumber(amount), officer }
            table.insert(mod.db.profile.log, entry)
            exists_logs[msg] = true

            if CheckFilter(entry, mod.db.profile.filter) then
                table.insert(mod.db.profile.filtred_logs, entry)
            end
            callbacks:Fire("LogChanged", #self.db.profile.log)
        end
    end

    if #members_with_logs >= 2 then
        return
    end

    sync_players_in_progress[sender] = GetTime()
end

function mod:EPGP_SYNC_RESPONSE(tag, msg, channel, sender)
    if channel ~= "WHISPER" then
        return
    end

    if sender == self_player_name then
        return
    end

    if not GS:GetRank(sender) then
        log(sender, "не находится в гильдии, но предлагает синхронизовать его логи!? wtf")
        return
    end

    local splitted = { string.split(':', msg) }
    local msg = splitted[2]
    log("Логи от " .. sender .. " прошли синхронизацию успешно, Синхронизированно:", msg)

    local cur_time = GetTime()
    sync_players_in_progress[sender] = nil
    for name, time in pairs(sync_players_in_progress) do
        if cur_time - time < 10 then
            return
        end
    end

    table.sort(self.db.profile.log, function (a, b)
        return a[1] < b[1]
    end)

    log("Синхранизация логов завершена")
end
local calcLatestTime = 60 * 60 * 24 * 7
function mod:OnEnable()
    EPGP.RegisterCallback(mod, "EPAward", AppendToLog, "EP")
    EPGP.RegisterCallback(mod, "GPAward", AppendToLog, "GP")
    EPGP.RegisterCallback(mod, "BankedItem", AppendToLog, "BI")
    mod:RegisterComm("EPGP", "LogSync")
    mod:RegisterComm("EPGP_SYNC_REQUEST", "EPGP_SYNC_REQUEST")
    mod:RegisterComm("EPGP_SYNC_LOG", "EPGP_SYNC_LOG")

    -- Upgrade the logs from older dbs
    if EPGP.db.profile.log then
        self.db.profile.log = EPGP.db.profile.log
        EPGP.db.profile.log = nil
    end
    if EPGP.db.profile.redo then
        self.db.profile.redo = EPGP.db.profile.redo
        EPGP.db.profile.redo = nil
    end

    self.db.profile.filter = ""
    self.db.profile.filtred_logs = {}

    table.sort(self.db.profile.log, function (a, b)
        return a[1] < b[1]
    end)

    local latest_time = GetTimestamp() - calcLatestTime
    local logs = self.db.profile.log
    if logs and #logs > 0 then
        local latest_log = logs[#logs]
        latest_time = latest_log[1]
    end
    mod:SendCommMessage("EPGP_SYNC_REQUEST", tostring(latest_time), "GUILD", "BULK")
    log("Запросили логи начиная с", tostring(latest_time))

    for _, log in pairs(logs) do
        log[6] = log[6] or "Unknown"
        exists_logs[string.format(LOG_FORMAT_NEW, unpack(log))] = true
    end

    -- This is kept for historical reasons. See:
    -- http://code.google.com/p/epgp/issues/detail?id=350.
    EPGP.db.RegisterCallback(self, "OnDatabaseShutdown", "Snapshot")
end
