--[[
	LootMaster, Master looter stuff
]]--

local debug	= false

LootMasterML	      = LibStub("AceAddon-3.0"):NewAddon("LootMasterML", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")
local LootMaster    = LibStub("AceAddon-3.0"):GetAddon("EPGPLootMaster")

local addon         = LootMasterML		-- Local instance of the addon

local MsgPrefix     = 'EPGPLootmaster: '

-- Cache some math function for faster access and preventing
-- other addons from screwing em up.
local mathRandomseed        = function() end
local mathRandom            = math.random
local mathFloor             = math.floor
local mathCachedRandomSeed  = math.random()*1000


StaticPopupDialogs["EPGPLOOTMASTER_ASK_TRACKING"] = {
	text = '- - - - EPGPLootmaster - - - -\r\n\r\nВы лут мастер, хотите ли распределять лут с помощью EPGPLootmaster?\r\n\r\n(Вас спросят опять в следущий раз. Используйте /lm config что бы это изменить)',
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		LootMasterML:EnableTracking()
        LootMaster:Print('Вы включили отслеживание лута для этого рейда')
	end,
	OnCancel = function()
	    LootMasterML:DisableTracking()
        LootMaster:Print('Вы выключили отслеживание лута для этого рейда')
	end,
	OnShow = function()
	end,
	OnHide = function()
	end,
	timeout = 0,
	hideOnEscape = 0,
	whileDead = 1,
    showAlert = 1
}

function LootMasterML:Debug( message, verbose )
    if not LootMaster or not LootMaster.debug then return end;
    if verbose and not LootMaster.verbose then return end;
    self:Print("Восстановление: " .. message)
end

function LootMasterML:OnInitialize()

    self.lootTable = {}			-- a table to store loot info

    -- Event Register
      -- Trap event when ML rightclicks master loot
    self:RegisterEvent("OPEN_MASTER_LOOT_LIST")

    -- Trap even when an items get looted
    self:RegisterEvent("CHAT_MSG_LOOT");

    -- Trap some important system messages here
    self:RegisterEvent("RAID_ROSTER_UPDATE",            "GROUP_UPDATE");
    self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED",     "GROUP_UPDATE");
    self:RegisterEvent("PARTY_MEMBERS_CHANGED",         "GROUP_UPDATE");
    self:RegisterEvent("PLAYER_ENTERING_WORLD",         "GROUP_UPDATE");

    -- Trap events when entering and leaving combat
    self:RegisterEvent("PLAYER_REGEN_DISABLED",     "EnterCombat");
    self:RegisterEvent("PLAYER_REGEN_ENABLED",      "LeaveCombat");

    self:RegisterEvent("GUILD_ROSTER_UPDATE",       "CacheGuildInfo")

    -- Register communications
    self:RegisterComm("EPGPLootMasterML", 		    "CommandReceived")

    -- Create table for the guildinfo cache.
    self.guildInfo = {}

    -- Disable 'automatic loot tracking' popup in EPGP - Let EPGPLootmaster handle all the GP stuff.
    if EPGP and CheckForGuildInfo and IsInGuild() then
        CheckForGuildInfo(EPGP);
        if EPGP.db then
            EPGP.db.profile.auto_loot = false
        end
    end

    -- Disable the GP Popup on the new EPGP versions
    if EPGP and EPGP.GetModule then
      local loot = EPGP:GetModule("loot")
      if loot and loot.Disable then
        loot:Disable()
      end
    end

    -- Warning if we're in a guild and we can edit officer notes but EPGP is not installed.
    if IsInGuild() and CanEditOfficerNote() and not EPGP then
        StaticPopupDialogs["EPGPLM_EPGP_NOTINSTALLED"] = {
            text = "EPGPLootmaster Заметка!\r\n\r\n|cFFFF8080ПРЕДУПРЕЖДЕНИЕ:|r У вас установлен EPGPLootmaster но EPGP не включен. \r\n\r\nПожалуйста убедитесь что EPGP установлен и включен. Если вы этого не зделаете, ГП не будут зачислятся за полученые вещи.\r\n\r\nВсе другие возможности EPGPLootmaster такие как оглашение и распределение лута будут продолжать работать но без ЕПГП.",
            button1 = OKAY,
            OnAccept = function() end,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 0,
            showAlert = 1
        };
        StaticPopup_Show("EPGPLM_EPGP_NOTINSTALLED")
    end

    -- Change the onClick script of the lootbuttons a little so we can trap alt+clicks
    -- NOTE: Only tested with normal wow lootframes, not using XLoot etc.
    for slot=1, LOOTFRAME_NUMBUTTONS do
        local btn = getglobal("LootButton"..slot);
        if btn and not btn.oldClickEventEPGPLM then
            btn.oldClickEventEPGPLM = btn:GetScript("OnClick");
            btn:SetScript("OnClick", function(btnObj, ...)
                if not IsAltKeyDown() then
                    return btnObj.oldClickEventEPGPLM(btnObj, ...)
                end
                return LootButton_OnClick(btnObj, ...);
            end);
        end
    end

    -- Just to be sure, enable the tracking.
    self:EnableTracking()
end

function LootMasterML:OnEnable()
    -- Postpone the chathooks to make sure we're the last hooking these.
    self:ScheduleTimer("PostEnable", 1)

    if EPGP and EPGP.RegisterCallback then
        EPGP.RegisterCallback(self, "StandingsChanged", "OnStandingsChanged")
    end
end

function LootMasterML:EnableTracking()
    self.trackingEnabled = true;
end

function LootMasterML:DisableTracking()
    self.trackingEnabled = false;
end

function LootMasterML:TrackingEnabled()
    return self.trackingEnabled;
end

function LootMasterML:PostEnable()
    -- Inbound Chat Hooking
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER",		LootMasterML.ChatFrameFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID",    	LootMasterML.ChatFrameFilter)
end

function LootMasterML:HandleEPGPCommand(command, message, sender, event)

    local preventMonitorUpdate = false;
    local preventMessageDisplay = false;

    if command=='STANDBY' then
        -- dont handle this message, let EPGP handle it.
        return false;
    end

    if command=='PAS' or command=='PASS' or command=='NEED' or command=='GREED' and message~='' then
        --Someone is trying to need/greed/pass a loot item.

        if command=='PAS' then
            command = 'PASS'
        end

        local itemID = self:GetLootID( message )
        if itemID then
            if self:IsCandidate( itemID, sender ) then
                if LootMaster.db.profile.ignoreResponseCorrections and tonumber(self:GetCandidateData( itemID, sender, 'response' )) >= LootMaster.RESPONSE.NEED then
                    self:SendWhisperResponse( format('Вы уже зделали выбор для %s. Изменения выключены мастерлутером.', message), sender );
                    return true;
                else
                    self:SetCandidateResponse( itemID, sender, LootMaster.RESPONSE[command] or LootMaster.RESPONSE.INIT, preventMonitorUpdate );
                    self:SetCandidateData( itemID, sender, 'enchantingSkill', 0, true );
                    self:ReloadMLTableForLoot( itemID )
                    self:SendWhisperResponse( format('Зарегестрировано %s для %s', command, message), sender );
                end
            else
                self:SendWhisperResponse( format('Вы не кандидат на %s. Наверно вы не участвовали в битве?', message), sender );
                return true;
            end
        else
            self:SendWhisperResponse( format('%s не найден в списке лута, возможно предмет уже отдан?', message), sender );
            return true;
        end

        return true;
    else
        self:SendWhisperResponse( format('"%s" не ясен. использование: /w %s !epgp need/greed/pass [линквещи]', command, UnitName('player')), sender );
        self:Print( format('%s отправил "%s %s"; не ясно, возвращен список использования.', sender or '', command or '', message or ''));
        return true;
    end

end

local lastMsgID = nil
local lastMsgFiltered = false

local commandPatterns = {
    '^%s*![eE][pP][gG][pP]%s+(%a+)%s*(.*)',
    '^%s*!([nN][eE][eE][dD])%s*(.*)',
    '^%s*!([gG][rR][eE][eE][dD])%s*(.*)',
    '^%s*!([pP][aA][sS][sS]?)%s*(.*)'
}
local numCommandPatterns = #commandPatterns

function LootMasterML:ChatFrameFilter(...)

    local event = select(1, ...)
    local sender = select(3, ...)
    local msg = select(2, ...)
    local msgID = select(12, ...)

    -- Do not process WIM History
    if not msgID or msgID<1 then return end

    -- See if we have already processed the message.
    if lastMsgID == msgID then
        return lastMsgFiltered
    end

    lastMsgID         = msgID
    lastMsgFiltered   = false

    -- find !epgp or any of the other command patterns in the chat message and try to handle the command.
    local command, params = nil, nil
    for i=1, numCommandPatterns do
        command, params = strmatch(msg, commandPatterns[i])
        if command then break end
    end

    if command then
        -- Safely try to handle the params. If it fails or returns false, just show the message and notify user.
        local cbOK, ret = pcall(LootMasterML.HandleEPGPCommand, LootMasterML, strupper(command or ''), strtrim(params or ''), sender, event)

        -- Error?!
        if not cbOK then
            LootMasterML:Print(format("Error while parsing message '%s' from %s: %s", tostring(params), tostring(sender), tostring(ret)))
        elseif cbOK and ret then
            -- no errors and handler func returned true: do not display the message.
            lastMsgFiltered = true
        end

        -- Do not filter the message from the chatframe if filters are disabled.
        if not LootMaster.db.profile.filterEPGPLootmasterMessages then
            lastMsgFiltered = false
        end

        return lastMsgFiltered
    end

end

function LootMasterML:GetVersionString()
    local lm = LibStub("AceAddon-3.0"):GetAddon("EPGPLootMaster")
    return (lm.GetVersionString(lm) or 'неизвесная версия')
end

function LootMasterML:SendWhisperResponse(message, target)
    SendChatMessage( MsgPrefix .. ( message or ''), 'WHISPER', nil, target );
    return false;
end

function LootMasterML:SendCommand(command, message, target)
	if not target then
		return self:Print("Немогу отправить команду, цель не выбрана")
	end;
    if target=='RAID' then
        self:SendCommMessage("EPGPLootMasterC", format("%s:%s", tostring(command), tostring(message)), "RAID", nil, "ALERT")
    elseif target=='PARTY' then
        self:SendCommMessage("EPGPLootMasterC", format("%s:%s", tostring(command), tostring(message)), "PARTY", nil, "ALERT")
    elseif target=='GUILD' then
        self:SendCommMessage("EPGPLootMasterC", format("%s:%s", tostring(command), tostring(message)), "GUILD", nil, "ALERT")
    else
        -- Don't use AceComm for messages to self, call function directly
        if target==UnitName('player') then
            LootMaster.CommandReceived(LootMaster, "EPGPLootMasterC", format("%s:%s", tostring(command), tostring(message)), 'WHISPER', target)
        else
            self:SendCommMessage("EPGPLootMasterC", format("%s:%s", tostring(command), tostring(message)), "WHISPER", target, "ALERT")
        end
    end
end

function LootMasterML:ParseMonitorMessage( message )
    local tpl = {}
    for v in string.gmatch(message, '(.-)(%^%*)') do
        if v=='nil' then v=nil end;
        tinsert(tpl, v)
    end
    for _,_,v in string.gmatch(message, '(.*)(%^%*)(.-)$') do
        if v=='nil' then v=nil end;
        tinsert(tpl, v)
    end
    if #tpl==0 then
        if message=='nil' then message=nil end;
        tinsert(tpl, message)
    end

    return tpl;
end

local MonitorMessagePriorities = {
    ["PRIORITY_HIGH"]       = "ALERT",
    ["PRIORITY_NORMAL"]     = "NORMAL",
    ["PRIORITY_LOW"]        = "BULK"
}
function LootMasterML:MonitorMessageRequired( loot )
    if not LootMaster.db.profile.monitorSend then return false end;
    loot = self:GetLoot( loot );
    if not loot then return false end;
    if not loot.mayDistribute then return false end;
    if loot.autoLootable then return false end;
    if loot.binding == 'pickup' then return true end;
    if loot.quality>=LootMaster.db.profile.monitorThreshold then return true end;
    return false;
end

function LootMasterML:SendMonitorMessage(...)

    if not LootMaster.db.profile.monitorSend then return end;

    local numArgs = select("#", ...)

    local prio = nil
    if numArgs>0 then
        prio = select(numArgs, ...)
        prio = MonitorMessagePriorities[prio];
    end

    if prio then
        numArgs = numArgs - 1
    else
        prio = "NORMAL"
    end

    local out = ""
    for i=1,numArgs do
      if i > 1 then
        out = out .. "^*"
      end
      out = out .. tostring(select(i, ...))
    end

    local msgType = tostring(select(1, ...))

    local num = GetNumRaidMembers()
    if num>0 then
        -- we're in raid
        if LootMaster.db.profile.monitorSendAssistantOnly and msgType=='ADDLOOT' then
          -- Only send to promoted players in raid, use whispers.
          for raidIndex=1, MAX_RAID_MEMBERS do
            local rName, rRank, _, _, _, _, _, rOnline, _, _, rIsML = GetRaidRosterInfo(raidIndex)
            if (rName and rOnline) and (rRank>0 or rIsML) and rName~=UnitName('player') then
              -- Player is online and not self and rank is assistant (1) or leader (2) or masterlooter
              self:Debug('SendMonitorMessage('..rName..'): ' .. out, true)
              self:SendCommMessage("EPGPLootMasterML", format("MONITOR:%s", out), "WHISPER", rName, prio)
            end
          end
        else
          -- Everybody is allowed to monitor, just use the raid channel
          self:SendCommMessage("EPGPLootMasterML", format("MONITOR:%s", out), "RAID", nil, prio)
          self:Debug('SendMonitorMessage(RAID): ' .. out, true)
        end
    else
        num = GetNumPartyMembers()
        if num>0 then
            --we're in party
            self:SendCommMessage("EPGPLootMasterML", format("MONITOR:%s", out), "PARTY", nil, prio)
            self:Debug('SendMonitorMessage(PARTY): ' .. out, true)
        else
            --we're not grouped, send message to self for debugging purposes.
            self:SendCommMessage("EPGPLootMasterML", format("MONITOR:%s", out), "WHISPER", UnitName('player'), prio)
            self:Debug('SendMonitorMessage(WHISPER->SELF): ' .. out, true)
        end
    end
end

--[[
	Event gets triggered when ML receives a message from a candidate
]]
function LootMasterML:CommandReceived(prefix, message, distribution, sender)

	local _,_,command, message = string.find(message, "^([%a_]-):(.*)$")
	command = strupper(command or '');
	message = message or '';

  local sendMonitorUpdate = (distribution == 'WHISPER')
  local preventMonitorUpdate = not sendMonitorUpdate;

	if command == 'WANT' then

		-- A candidate just told us he wants the item
        local itemID, response, enchantingSkill, note = strsplit('^', message);
        enchantingSkill = tonumber(enchantingSkill) or 0;
        response = tonumber(response)
        note = note or ''
        local autoPass = false;

        if (response == LootMaster.RESPONSE.PASS or response == LootMaster.RESPONSE.AUTOPASS) and enchantingSkill~=0 then
            autoPass = (response == LootMaster.RESPONSE.AUTOPASS)
            response = LootMaster.RESPONSE.DISENCHANT;
        end

        local loot = self:GetLoot( itemID )
        if loot and ((loot.mayDistribute and self:IsCandidate(itemID, sender)) or not loot.mayDistribute) then

            if not loot.mayDistribute and loot.candidatesReceived and not self:IsCandidate(itemID, sender) then
                -- we're monitoring, candidatelist has been received but the responding player is not
                -- on the candidatelist, ignore
                return
            end

            if LootMaster.db.profile.ignoreResponseCorrections and tonumber(self:GetCandidateData( itemID, sender, 'response' ) or 0) >= LootMaster.RESPONSE.NEED then
                self:Debug( format("%s ответил WANT(нужно) на %s но от него уже был ответ, а команда ИгнорироватьИсправления включена.", sender or 'nil', itemID or 'nil'))
            else
                self:SetCandidateResponse( loot.id, sender, response, preventMonitorUpdate );
            end
            self:SetCandidateData( loot.id, sender, 'enchantingSkill', enchantingSkill, preventMonitorUpdate );
            self:SetCandidateData( loot.id, sender, 'autoPass', autoPass, preventMonitorUpdate );
            self:SetCandidateData( loot.id, sender, 'note', note, preventMonitorUpdate );
            self:ReloadMLTableForLoot( loot.id )
        else
            self:Debug( format("%s ответил WANT(нужно) на %s но лут не найден (Уже отдан?)", sender or 'nil', itemID or 'nil'))
        end

        -- Fallback monitor updates for old clients - relay through the ml
        if sendMonitorUpdate and self:MonitorMessageRequired(loot.id) then
            self:SendMonitorMessage( 'SETCANDIDATEDATA', loot.id, sender, 'enchantingSkill', enchantingSkill )
            self:SendMonitorMessage( 'SETCANDIDATEDATA', loot.id, sender, 'response', response )
        end

	elseif command == 'GEAR' then

		-- A candidate just sent us his current gear. update the cache
        local _,_,itemID, iVersion, gear = string.find(message, "^([^\^]-)\^([^\^]-)\^(.*)$");
        local item1, item2 = strsplit('$', gear)

        local loot = self:GetLoot( itemID )

        if loot and ((loot.mayDistribute and self:IsCandidate(itemID, sender)) or not loot.mayDistribute) then

            if not loot.mayDistribute and loot.candidatesReceived and not self:IsCandidate(itemID, sender) then
                -- we're monitoring, candidatelist has been received but the responding player is not
                -- on the candidatelist, ignore
                return
            end

            self:SetCandidateData( loot.id, sender, 'currentitem', item1, true );
            self:SetCandidateData( loot.id, sender, 'currentitem2', item2, true );
            self:SetCandidateData( loot.id, sender, 'foundGear', true, true );
            self:SetCandidateData( loot.id, sender, 'version', iVersion, true );
            self:SetCandidateResponse( loot.id, sender, LootMaster.RESPONSE.WAIT, preventMonitorUpdate );
            self:ReloadMLTableForLoot( loot.id )

            -- Fallback monitor updates for old clients - relay through the ml
            if sendMonitorUpdate and self:MonitorMessageRequired(itemID) then
                self:SendMonitorMessage( 'CANDIDATEGEAR', loot.id, sender, item1, item2 )
            end
        else
            self:Debug( format("%s ответил GEAR(одежда) для %s но лут или кандидат не были найдены (Уже отдан?)", sender or 'nil', itemID or 'nil'))
        end

  elseif command == 'RAIDINFO' then

        self:RaidInfoLookupResponse(sender, message)

  elseif command == 'MONITOR' then

        -- Only handle monitor messages if we enabled them in the options screen.
        if not LootMaster.db.profile.monitor then return end

        -- ignore our own monitor messages!
        if sender == UnitName('player') then return end

        local monArgs = self:ParseMonitorMessage(message)
        local monCmd = tremove(monArgs, 1)

        if monCmd == 'ADDLOOT' then

            local itemLink, itemName, itemID, gpvalue, ilevel, itemBind, itemRarity, itemTexture, itemEquipLoc, gpvalue2, quantity, classAutoPassList, hideResponses, numButtons, buttons = unpack(monArgs)

            if not self.lootTable then self.lootTable={} end;

            if self.lootTable[itemID] then
                -- Is someone tinkering? the loot already exists. Return
                return;
            end

            itemRarity = tonumber(itemRarity) or 0

            hideResponses = tonumber(hideResponses) or 0
            hideResponses = (hideResponses==1)

            -- Check if the loot < monitorIncomingThreshold; cancel
            if itemRarity < LootMaster.db.profile.monitorIncomingThreshold then
                -- Do not show monitor window for this item.
                return;
            end

            -- Unserialize the class string.
            classAutoPassList = tonumber(classAutoPassList) or 0;

            -- Parse the buttons sent by the master looter
            numButtons = tonumber(numButtons or 0)
            local buttonsOK = false
            local buttonsTranslate = {}
            local buttonsByResponse = {}
            if numButtons >= 1 and buttons and buttons~='' then
                buttons = {strsplit("*", buttons)}
                if #buttons == numButtons then
                  for i=1,numButtons do
                    local bResponse, bText, bIsPercentage, bGPValue, bColor, bFallback = strsplit(';', buttons[i])
                    local button = {
                      response                = tonumber(bResponse) or 0,
                      text                    = bText or '[empty]',
                      gpValueIsPercentage     = (tonumber(bIsPercentage)==1),
                      gpValue                 = tonumber(bGPValue),
                      fallback                = bFallback,
                      color                   = bColor or 'ffffff'
                    }
                    button.colorRGB = {LootMaster:ColorHexToRGB(button.color)}
                    buttons[i] = button
                    buttonsByResponse[button.response] = button
                  end
                  buttonsOK = true
                end
            end

            -- If the master looter didn't send any buttons (prolly old version),
            -- create an empty table.
            if not buttonsOK then
                -- Create the default buttons
                numButtons = 0
                buttons = {}
            end

            self.lootTable[itemID] = {
                ['link']	                      = itemLink,
                ['name']	                      = itemName,

                ['lootmaster']                  = sender,

                ['announced']                   = true,
                ['mayDistribute']               = false,
                ['hideResponses']               = hideResponses,

                ['id']                          = itemID,
                ['itemID']                      = itemID,
                ['itemid']                      = itemID,

                ['gpvalue']	                    = tonumber(gpvalue) or 0,
                ['gpvalue2']	                  = tonumber(gpvalue2),
                ['gpvalue_manual']	            = tonumber(gpvalue) or 0,
                ['ilevel']	                    = tonumber(ilevel) or 0,
                ['binding']	                    = itemBind,
                ['quality']                     = itemRarity,
                ['quantity']                    = tonumber(quantity) or 1,
                ['classes']                     = LootMaster:DecodeUnlocalizedClasses(classAutoPassList),
                ['classesEncoded']              = classAutoPassList,

                ['texture']                     = itemTexture or '',

                ['equipLoc']	                  = itemEquipLoc or '',

                ['started']	                    = nil,

                ['numButtons']                  = numButtons,
                ['buttonTranslate']             = buttonsTranslate,
                ['buttons']                     = buttons,
                ['buttonsByResponse']           = buttonsByResponse,

                ['rowdata']	                    = {},
                ['candidates']	                = {},
                ['numResponses']                = 0
            }

            self:ReloadMLTableForLoot( itemID )

        elseif monCmd == 'ADDCANDIDATE' then

            local itemID, candidate, roll = unpack(monArgs)
            local loot = self:GetLoot(itemID);

            if not loot or loot.mayDistribute or loot.lootmaster~=sender then
                -- Is someone tinkering? the loot doesnt exist or player is lootmaster. Return
                return;
            end

            self:SetCandidateData( itemID, candidate, 'roll', tonumber(roll) )

            self:ReloadMLTableForLoot( itemID )

        elseif monCmd == 'CANDIDATELIST' or monCmd == 'CANDIDATELIST2' then

            -- in an attempt to speed the monitors up, lets just receive all candidate data for new loot in big chunk
            -- not candidate by candidate, updates hereafter are still one by one.

            local mlCandidates = {}
            local itemID, fieldCount, candidates

            if monCmd == 'CANDIDATELIST2' then

                itemID, fieldCount, candidates = unpack(monArgs)
                fieldCount = tonumber(fieldCount) or 1

            elseif monCmd == 'CANDIDATELIST' then

                -- Old version
                itemID, candidates = unpack(monArgs)
                fieldCount = 3

            end

            local loot = self:GetLoot(itemID);

            if not loot or loot.mayDistribute or loot.lootmaster~=sender then
                -- Is someone tinkering? the loot doesnt exist or player is lootmaster. Return
                return;
            end

            -- Don't allow players to be added unless they are already on the list.
            loot.candidatesReceived = true;

            -- Loop through the ml's candidatelist
            if candidates then
                local cdata = {strsplit(' ', candidates)}
                for i=1, #cdata, fieldCount do
                    -- Store the candidate's name for a later check.
                    mlCandidates[cdata[i]] = true;
                    -- Set the candidate roll value
                    self:SetCandidateData( itemID, cdata[i], 'roll', tonumber(cdata[i+1]) or 0 )
                end
            end

            local localCandidatesDeleted = false;

            -- Loop through all the local candidates that responded and try to filter out those who are not eligible
            for rowID, data in ipairs(loot['rowdata']) do
                local localCandidate = self:GetCandidateDataByRowID( loot.id, rowID, 'name' )
                if localCandidate then
                    if not mlCandidates[localCandidate] then
                        -- localCandidate has not been found in the candidatelist we have received from the ML
                        -- DELETE! :P
                        localCandidatesDeleted = true;
                        self.lootTable[loot.id]['candidates'][localCandidate] = nil;
                        tremove(self.lootTable[loot.id]['rowdata'], rowID);
                    end
                end
            end

            -- Loop through all the local candidates again and rebuild the candidate index
            if localCandidatesDeleted then
                for rowID, data in ipairs(loot['rowdata']) do
                    local localCandidate = self:GetCandidateDataByRowID( loot.id, rowID, 'name' )
                    if localCandidate then
                        self.lootTable[loot.id]['candidates'][localCandidate] = rowID;
                    end
                end
            end

            -- Reload the UI
            self:ReloadMLTableForLoot( itemID )

        elseif monCmd == 'SETCANDIDATEDATA' then

            local itemID, candidate, name, value = unpack(monArgs)
            local loot = self:GetLoot(itemID);

            if not loot or loot.mayDistribute or loot.lootmaster~=sender  then
                -- Is someone tinkering? the loot doesnt exist or player is lootmaster. Return
                return;
            end

            if not self:IsCandidate( itemID, candidate ) then return end;
            self:SetCandidateData( itemID, candidate, name, value )

            self:ReloadMLTableForLoot( itemID )

        elseif monCmd == 'CANDIDATEGEAR' then

            local itemID, candidate, item1, item2 = unpack(monArgs)
            local loot = self:GetLoot(itemID);

            if not loot or loot.mayDistribute or loot.lootmaster~=sender  then
                -- Is someone tinkering? the loot doesnt exist or player is lootmaster. Return
                return;
            end

            if not self:IsCandidate( itemID, candidate ) then return end;

            if item1 then
                self:SetCandidateData( itemID, candidate, 'currentitem', item1 );
            end
            if item2 then
                self:SetCandidateData( itemID, candidate, 'currentitem2', item2 );
            end

            self:SetCandidateData( itemID, candidate, 'foundGear', true, true );

            self:ReloadMLTableForLoot( itemID )

        elseif monCmd == 'REMOVELOOT' or monCmd == 'DECREASELOOT' then

            local itemID = unpack(monArgs)
            local loot = self:GetLoot(itemID);

            if not loot or loot.mayDistribute or loot.lootmaster~=sender then
                -- Is someone tinkering? the loot doesnt exist or player is lootmaster. Return
                return;
            end

            self:RemoveLoot(itemID);
            self:UpdateUI();

        end
    end
end

--[[
	Send a request to the specified player if he/she is interested in the given loot
    candidate could also be RAID or PARTY
]]
function LootMasterML:AskCandidateIfNeeded( link, candidate )

	local loot = self:GetLoot( link );
	if not loot then
		return self:Print( format("Немогу спросить игрока нужно ли потому как %s не кеширован", link) )
	end

    -- Hardcoded time in secs until autopass
    self.timeout = LootMaster.db.profile.loot_timeout;

	if candidate == 'RAID' or candidate == 'PARTY' then

        SendChatMessage( format('%sпожалуйста шепни мне !epgp need/greed/pass %s  (или спользуйте всплывающее окно если установлен EPGPLootmaster)', MsgPrefix or '', loot.link or ''), candidate );

        -- Sending to raid channel? Update all candidate statuses.
        for c, index in pairs(loot.candidates) do
            if (UnitInRaid(c) or (UnitInParty(c) and GetNumPartyMembers()>0)) then
                self:SetCandidateResponse( loot.id, c, LootMaster.RESPONSE.INIT, true );
            end
        end

    elseif candidate ~= UnitName('player') then

        SendChatMessage( format('%sпожалуйста шепни мне !epgp need/greed/pass %s  (или спользуйте всплывающее окно если установлен EPGPLootmaster)', MsgPrefix or '', loot.link or ''), 'WHISPER', nil, candidate );
        self:SetCandidateResponse( loot.id, candidate, LootMaster.RESPONSE.INIT );

    end

    local gpGreed = tonumber(loot.gpvalue) or 0
    if LootMaster.db.profile.defaultOffspecGPValue then
        local v = tonumber(LootMaster.db.profile.defaultOffspecGPValue) or 0
        local p = LootMaster.db.profile.defaultOffspecGPPercentage
        if p then
            gpGreed = ceil(gpGreed /100 * v)
        else
            gpGreed = ceil(v)
        end
    end

    local notesAllowed = 0
    if LootMaster.db.profile.allowCandidateNotes then
        notesAllowed = 1
    end

    self:SendCommand( "DO_YOU_WANT", format('%s^%s^%s^%s^%s^%s^%s^%s^%s^%s^%s^%s^%s^%d^%s',
                                            loot.id or '',
                                            loot.gpvalue or -1,
                                            loot.ilevel or -1,
                                            loot.gpvalue2 or -1,
                                            loot.binding or '',
                                            loot.equipLoc or 0,
                                            loot.quality or 0,
                                            self.timeout or 60,
                                            loot.link,
                                            loot.texture or '',
                                            gpGreed or -1,
                                            notesAllowed,
                                            loot.classesEncoded or 0,
                                            loot.numButtons or 0,
                                            loot.buttonString or ''
                                            ), candidate )

	-- Update the ui
	self:ReloadMLTableForLoot( loot.id )
end

--[[
	Add loot to masterloot cache. This is where candidate responses are stored, plus the rows for the scrollingtable
]]
function LootMasterML:AddLoot( link, mayDistribute, quantity )
	if not link then return end
	if not self.lootTable then self.lootTable={} end

  -- Cache a new randomseed for later use.
  -- math.random always has same values for seeds > 2^31, so lets modulate.
  mathCachedRandomSeed = floor((mathRandom()+1)*(GetTime()*1000)) % 2^31

  if self.lootTable[link] then return link end

	local itemName, itemLink, _, _, itemMinLevel, itemType, itemSubType, itemStackCount, _, itemTexture = GetItemInfo(link)

  local _,_,itemID = strfind(itemLink, 'Hitem:(%d+)');
  if not itemID or not itemName then return end

  -- Fix patterns bug by removing the ':' from the itemname
  --itemLink = itemLink:gsub('%[.*%]', itemLink:match('%[.*%]'):gsub(':', ','))
  --itemName = itemName:gsub(':', ',')

	if self.lootTable[itemID] then return itemID end

  local db = LootMaster.db.profile

	-- Calc the EPGP values for this item
	local gpvalue, gpvalue2, ilevel = GetGPValue(itemLink);

  -- Get the itemEquipLocation, rarity and level, and keep Tier Tokens in consideration.
  local itemEquipLoc, itemRarity, itemLevel = GetCustomSlotInfo(link)

	-- See if the item is BoP, BoE or BoU
	local itemBind = LootMaster:GetItemBinding(itemLink)

  -- Find what classes are eligible for the loot
  local itemClasses = LootMaster:GetItemAutoPassClasses(itemLink)
  local itemClassesEncoded = LootMaster:EncodeUnlocalizedClasses(itemClasses) or 0

  local hideResponses = false
  if db.hideResponses then
      hideResponses = true
  end

	self.lootTable[itemID] = {
    ['link']	          = itemLink,
    ['name']	          = itemName,

    ['announced']       = true,
    ['mayDistribute']   = mayDistribute,

    ['id']              = itemID,
    ['itemID']          = itemID,
    ['itemid']          = itemID,
    ['hideResponses']   = hideResponses,

    ['gpvalue']	        = gpvalue or 0,
    ['gpvalue2']	      = gpvalue2,
    ['gpvalue_manual']	= gpvalue or 0,
    ['ilevel']	        = ilevel or 0,
    ['binding']	        = itemBind or '',
    ['quality']         = itemRarity or 0,
    ['quantity']        = quantity or 1,
    ['classes']         = itemClasses,
    ['classesEncoded']  = itemClassesEncoded,

    ['texture']         = itemTexture or '',

    ['equipLoc']	      = itemEquipLoc or '',

    ['started']	        = nil,

    ['rowdata']	        = {},
    ['candidates']	    = {},

    ['numButtons']          = 0,
    ['buttonTranslate']     = {},
    ['buttons']             = {},
    ['buttonsByResponse']   = {},

    ['numResponses']        = 0
	}
  local loot = self.lootTable[itemID]

  -- Add some backward compatibility for the new button system
  -- by using the fallback values used in the configuration panel

  -- Also, since the master looter could change some configuration settings while the
  -- monitor is open, we should cache the button values here.
  loot.numButtons = db.buttonNum
  local buttonString = {}
  for i=1, db.buttonNum do
    local key = 'button' .. i

    -- Store the fallback translation
    local fallback = db[key..'_fallback']
    if fallback and fallback~='' then
      loot.buttonTranslate[LootMaster.RESPONSE[fallback]] = LootMaster.RESPONSE[key]
    end

    -- Cache the button
    local button = {
      response                = LootMaster.RESPONSE[key] or 0,
      text                    = db[key] or '',
      gpValueIsPercentage     = db[key .. '_gpIsPercentage'],
      gpValue                 = db[key .. '_gpValue'],
      fallback                = fallback,
      color                   = db[key .. '_color'],
      colorRGB                = {LootMaster:ColorHexToRGB(db[key .. '_color'])}
    }
    loot.buttons[i] = button
    loot.buttonsByResponse[button.response] = button

    -- Create the buttonstring we need for communications:
    tinsert(buttonString,
            format('%d;%s;%d;%s;%s;%s',
                   button.response,
                   button.text,
                   button.gpValueIsPercentage and 1 or 0,
                   button.gpValue or '',
                   button.color or 'ffffff',
                   fallback or ''))
  end
  buttonString = strjoin('*', unpack(buttonString))
  loot.buttonString = buttonString

  -- See if this item should be autolooted
  if db.AutoLootThreshold~=0 and db.AutoLooter~='' then
      if (not itemBind or itemBind=='use' or itemBind=='equip') and itemRarity<=db.AutoLootThreshold then
          loot.autoLootable = true
      end
  end

  -- Are we lootmaster for this loot? Lets send out a monitor message about the added loot
  if loot.mayDistribute and self:MonitorMessageRequired(itemID) then
      local hideResponsesInt = hideResponses and 1 or 0
      self:SendMonitorMessage('ADDLOOT', itemLink, itemName, itemID, gpvalue or 0, ilevel or 0, itemBind or '', itemRarity or 0, itemTexture or '', itemEquipLoc or '', gpvalue2 or '', quantity or 1, itemClassesEncoded, hideResponsesInt, loot.numButtons or 0, buttonString or '', "PRIORITY_HIGH" )
  end

	return itemID
end

function LootMasterML:AnnounceLoot( loot )
    loot = self:GetLoot( loot )
    if not loot then return end;

    if loot.announced == true then return end;

    loot.announced = true;

    -- Also send a text message and an addon message to the raid/party chat.
    if UnitInRaid('player') then
        -- we're in raid with master looter
        self:AskCandidateIfNeeded( loot.id, 'RAID' )
    elseif UnitInParty('player') and GetNumPartyMembers()>0 then
        --we're in party with master looter
        self:AskCandidateIfNeeded( loot.id, 'PARTY' )
    end

    -- Traverse the candidate list, see if there is anyone eligible for the loot, but not grouped anymore...
    for candidate, index in pairs(loot.candidates) do
        if not UnitInRaid(candidate) and not (UnitInParty(candidate) and GetNumPartyMembers()>0) and tonumber(self:GetCandidateData( loot.id, candidate, 'response')) == LootMaster.RESPONSE.NOTANNOUNCED then
            self:AskCandidateIfNeeded( loot.id, candidate )
        end
    end
end


--[[
	Get the lootdata from masterloot cache. This is where candidate responses are stored, plus the rows for the scrollingtable. Returns nil if not found
]]
function LootMasterML:GetLoot( link )
	if not link then self:Debug('getloot: !link'); return nil end;
	if not self.lootTable then self:Debug('getloot: !lootTable'); return nil end;

    if self.lootTable[link] then return self.lootTable[link] end;

    local _,_,itemID = strfind(link, 'Hitem:(%d+)');
    if not itemID then self:Debug('getloot: !itemID: ' .. tostring(itemID)); return end;
    if not self.lootTable[itemID] then self:Debug('getloot: !lootTable[itemID]: ' .. tostring(itemID)); return end;

	return self.lootTable[itemID];
end

--[[
	Get the lootdata from masterloot cache. This is where candidate responses are stored, plus the rows for the scrollingtable. Returns nil if not found
]]
function LootMasterML:GetLootID( link )
	if not link then self:Debug('getlootid: !link'); return nil end;
	if not self.lootTable then self:Debug('getlootid: !lootTable'); return nil end;

    if self.lootTable[link] then return link end;

    local _,_,itemID = strfind(link, 'Hitem:(%d+)');
    if not itemID then self:Debug('getlootid: !itemID: ' .. tostring(itemID)); return end;
    if not self.lootTable[itemID] then self:Debug('getloot: !lootTable[itemID]: ' .. tostring(itemID)); return end;

	return itemID;
end

function LootMasterML:GetItemIDFromLink( link )
    if not link then return nil end;
    local _,_,itemID = strfind(link, 'Hitem:(%d+)');
    if not itemID then return nil end;
    return tonumber(itemID);
end

--[[
	Removes the given loot from the masterloot cache
]]
function LootMasterML:RemoveLoot( link )
	if not link then return end;
	if not self.lootTable then return end;

    local loot = self:GetLoot(link);
    local itemID = loot.id;

    if not itemID or not self.lootTable[itemID] then
        return self:Debug(format('УбранЛут: не найден %s %s(%s)', link or 'nil', itemID or 'nil', type(itemID)))
    end;

    -- we have more than one of this item, decrease counter and return.
    if loot.quantity>1 then
        loot.quantity = loot.quantity - 1;

        -- Are we lootmaster for this loot? Lets send out a monitor message about the quantity decrease
        if self.lootTable[itemID].mayDistribute and self:MonitorMessageRequired(itemID) then
            self:SendMonitorMessage( 'DECREASELOOT', itemID, "PRIORITY_HIGH" )
        end

        return true;
    end

    if self.frame and self.frame.currentLoot and self.frame.currentLoot.itemID == itemID then
        self.frame.currentLoot = nil;
    end

    self:Debug('RemoveLoot: '..link)

    -- Are we lootmaster for this loot? Lets send out a monitor message about the removed loot
    if self.lootTable[itemID].mayDistribute and self:MonitorMessageRequired(itemID) then
        self:SendMonitorMessage( 'REMOVELOOT', itemID, "PRIORITY_HIGH" )
    end

	self.lootTable[itemID] = nil;
	return true;
end

function LootMasterML:GetEPGP( player )
    if not EPGP or not EPGP.GetEPGP then return nil, nil, nil, nil end;
    local ret, ep, gp, alt = pcall(EPGP.GetEPGP, EPGP, player)
    if not ret then return nil, nil, nil, nil end;

    local ret, minEP = pcall(EPGP.GetMinEP, EPGP)
    if not ret or not minEP then minEP=0 end;

    return ep, gp, alt, minEP;
end

function LootMasterML:GetEP( player )
    local ep, gp = self:GetEPGP( player );
    if not ep then return -1 end;
    return ep or 0
end

function LootMasterML:GetMinEPMatch( player )
    local ep, gp, alt, minEP = self:GetEPGP( player );
    if not ep or not minEP then return 'n' end;

    if ep>=minEP then return 'y' end
    return 'n';
end

function LootMasterML:GetGP( player )
    local ep, gp = self:GetEPGP( player );
    if not gp then return -1 end;
    return gp or 1
end

function LootMasterML:GetPR( player )
    local ep, gp = self:GetEPGP( player );
    if not gp or not ep then return -1 end;
    if gp~=0 then return ep/gp end;
    return 0;
end

function LootMasterML:ResponseSortValue(candidate, itemID)
    local data = self:GetLoot(itemID)
    local response = tonumber(self:GetCandidateData(itemID, candidate, "response"))
    if data.hideResponses and data.announced and response > LootMaster.RESPONSE.TIMEOUT then
      return 1000
    end
    return self:GetCandidateData( itemID, candidate, 'responsesort')
end

--[[
    Create a safe randomizer function that returns a float between 1 and 99
]]--
local randomtable
local randomFloat = function()
   -- I know it's best to only seed the randomizer only so now and then,
   -- but some other addon might have twisted the randomseed so reset it
   -- to our cached seed again
   mathRandomseed( mathCachedRandomSeed ); mathRandom();
   -- Init the randomizerCache if needed
   if randomtable == nil then
      randomtable = {}
      for i = 1, 97 do
         randomtable[i] = mathRandom()
      end
   end
   local x = mathRandom()
   local i = 1 + mathFloor(97*x)
   x, randomtable[i] = randomtable[i] or x, x
   return mathFloor((x*99+1)*100000)/100000;
end

--[[
	Adds a candidate (player eligible to receive loot) to the masterloot cache
	for the given loot
]]
function LootMasterML:AddCandidate( loot, candidate )
	local itemID = self:AddLoot( loot )
	if not itemID then return end
	if not candidate then return end
	if not self.lootTable[itemID] then return end

  local lootTbl = self.lootTable[itemID]

	-- Just return the itemname if the candidate already exists
	if self.lootTable[itemID]['candidates'][candidate] then return itemID end;

    --floor((math.random()*99+1)*10000)/10000;
    local randomRoll = randomFloat();
    if not self.lootTable[itemID].mayDistribute then
        randomRoll = 0
    end

    -- Find the guildRank and unlocalized classname from the guildCache
    local guildRankName = '';
    local candidateClass = nil;
    local candidateClassLocalized = nil;
    if self.guildInfo and self.guildInfo[candidate] then
        guildRankName = self.guildInfo[candidate].rank or '';
        candidateClass = self.guildInfo[candidate].class;
        candidateClassLocalized = self.guildInfo[candidate].classLocalized;
    end

    -- No class found, try looking it up another way.
    if not candidateClass then
        candidateClassLocalized, candidateClass = UnitClass(candidate);
        -- Update the reverse class lookup table
        if candidateClassLocalized and candidateClass then
            LootMaster:UpdateClassLocalizer(candidateClassLocalized, candidateClass)
        end
    end

    local classes = self.lootTable[itemID].classes
    local initResponse = LootMaster.RESPONSE.NOTANNOUNCED;
    -- Autopass BoP items that cannot be used by this class
    if self.lootTable[itemID].binding=='pickup' and classes and candidateClassLocalized and classes[candidateClass] then
        initResponse = LootMaster.RESPONSE.AUTOPASS

        -- show the responses again if the player autopasses
        if UnitName('player') == candidate then
            lootTbl.hideResponses = false
        end
    end
    local initResponseSort = LootMaster.RESPONSE[initResponse].SORT

    tinsert( self.lootTable[itemID]['rowdata'],
    {   ["unitclass"]       = candidateClass,
        ["response"]        = initResponse,
        ["responsesort"]    = initResponseSort,
        ["onclick"]         = function(arg1, button, down) if button=='RightButton' then self:OnCandidateRowRightClick(candidate, loot, arg1) end end,
        ["cols"] = {
          {["name"]       = 'class',
          ["value"]      = candidateClass or '',
          ["onenter"]    = addon.ShowCandidateCellPopup,
          ["onleave"]    = addon.HideGearCellPopup,
          ["userDraw"]   = addon.SetClassIconCellOwnerDraw,
          ["onenterargs"]= { self, candidate, itemID },
          ["onleaveargs"]= { self, candidate, itemID }
          },

          {["name"]       = 'name',
          ["value"]      = candidate,
          ["onenter"]    = addon.ShowCandidateCellPopup,
          ["onleave"]    = addon.HideGearCellPopup,
          ["color"]      = self.GetCandidateClassCellColor,
          ["colorargs"]  = { self, candidate, itemID},
          ["onenterargs"]= { self, candidate, itemID },
          ["onleaveargs"]= { self, candidate, itemID }
          },

          {["name"]       = 'guildrank',
          ["value"]      = guildRankName,
          ["color"]      = self.GetCandidateCellColor,
          ["colorargs"]  = {self, candidate, itemID}},

          {["name"]       = 'responsesortFunc',
          ["value"]      = self.ResponseSortValue,
          ["args"]       = {self, candidate, itemID},
          ["userDraw"]   = addon.SetCandidateResponseCellUserDraw,
          ["color"]      = self.GetCandidateCellColor,
          ["colorargs"]  = {self, candidate, itemID}},

          {["name"]       = 'EP',
          ["value"]      = self.GetEP,
          ["userDraw"]   = addon.SetCellEPGPNumberFormatted,
          ["args"]       = {self, candidate, self.GetEP}},

          {["name"]       = 'GP',
          ["value"]      = self.GetGP,
          ["userDraw"]   = addon.SetCellEPGPNumberFormatted,
          ["args"]       = {self, candidate, self.GetGP}},

          {["name"]       = 'PR',
          ["value"]      = self.GetPR,
          ["userDraw"]   = addon.SetCellEPGPNumberFormatted,
          ["args"]       = {self, candidate, self.GetPR}},

          {["name"]       = 'roll',
          ["value"]      = randomRoll,
          ["userDraw"]   = addon.SetCandidateRollCellUserDraw,
          ["onenter"]    = addon.ShowRollCellPopup,
          ["onleave"]    = addon.HideGearCellPopup,
          ["onenterargs"]= { self,candidate,itemID },
          ["onleaveargs"]= { self,candidate,itemID },
          ["args"]       = {self, candidate, itemID}},


          {["name"]       = 'note',
          ["value"]      = '',
          ["userDraw"]   = addon.SetNoteCellOwnerDraw,
          ["onenter"]    = addon.ShowNoteCellPopup,
          ["onleave"]    = addon.HideInfoPopup,
          ["onenterargs"]= { self,candidate,itemID,'currentitem' },
          ["onleaveargs"]= { self,candidate,itemID,'currentitem' }
          },

          {["name"]       = ' ',
          ["value"]      = self.GetMinEPMatch,
          ["userDraw"]   = self.EmptyCellOwnerDraw,
          ["args"]       = {self, candidate}},     -- spacer, actually used for sorting the minEP matches first.

          {["name"]       = 'currentilevel',
          ["value"]      = '',
          ["args"]       = {self, candidate, itemID},
          ["onclick"]    = addon.OnGearInspectClick,
          ["onenter"]    = addon.ShowGearInspectPopup,
          ["onleave"]    = addon.HideGearCellPopup,
          ["userDraw"]   = addon.SetGearCelliLVL,
          ["onenterargs"]= { self,candidate,itemID },
          ["onleaveargs"]= { self,candidate,itemID },
          ["onclickargs"]= { self,candidate,itemID }
          },

          {["name"]       = 'currentgp',
          ["value"]      = '',
          ["args"]       = {self, candidate, itemID},
          ["onclick"]    = addon.OnGearInspectClick,
          ["onenter"]    = addon.ShowGearInspectPopup,
          ["onleave"]    = addon.HideGearCellPopup,
          ["userDraw"]   = addon.SetGearCellGP,
          ["onenterargs"]= { self,candidate,itemID },
          ["onleaveargs"]= { self,candidate,itemID },
          ["onclickargs"]= { self,candidate,itemID }
          },

          {["name"]       = 'currentitem',
          ["value"]      = '',
          ["userDraw"]   = addon.SetGearCellOwnerDraw,
          ["onenter"]    = addon.ShowGearCellPopup,
          ["onleave"]    = addon.HideGearCellPopup,
          ["onclick"]    = addon.OnGearCellClick,
          ["onenterargs"]= { self,candidate,itemID,'currentitem' },
          ["onleaveargs"]= { self,candidate,itemID,'currentitem' },
          ["onclickargs"]= { self,candidate,itemID,'currentitem' }
          },

          {["name"]       = 'currentitem2',
          ["value"]      = '',
          ["userDraw"]   = addon.SetGearCellOwnerDraw,
          ["onenter"]    = addon.ShowGearCellPopup,
          ["onleave"]    = addon.HideGearCellPopup,
          ["onclick"]    = addon.OnGearCellClick,
          ["onenterargs"]= { self,candidate,itemID,'currentitem2' },
          ["onleaveargs"]= { self,candidate,itemID,'currentitem2' },
          ["onclickargs"]= { self,candidate,itemID,'currentitem2' }
          },

          {["value"]      = ' '},     -- spacer
      }
    })

    self.lootTable[itemID]['candidates'][candidate] = #(self.lootTable[itemID]['rowdata']);

    -- Are we lootmaster for this loot? Lets send out a monitor message about the added candidate
    if self.lootTable[itemID].mayDistribute and self.lootTable[itemID].candidatesSent and self:MonitorMessageRequired(itemID) then
        self:SendMonitorMessage( 'ADDCANDIDATE', itemID, candidate, randomRoll )
    end

    self:InspectCandidate( itemID, candidate );

    return itemID;
end

function LootMasterML:SendCandidateListToMonitors( itemID )
    local loot = self:GetLoot( itemID )
    if not loot then return nil end;

    local candidata = {}

    for candidate, cIndex in pairs(loot.candidates) do
        local roll = self:GetCandidateData( itemID, candidate, 'roll' ) or 0
        --local response = tonumber(self:GetCandidateData( itemID, candidate, 'response' )) or LootMaster.RESPONSE.NOTANNOUNCED
        tinsert( candidata, candidate );
        tinsert( candidata, roll );
        --tinsert( candidata, response );
    end

    loot.candidatesSent = true;

    if self:MonitorMessageRequired(itemID) then
        self:SendMonitorMessage( 'CANDIDATELIST2', itemID, 2, strjoin(' ', unpack(candidata)) ) --, 'PRIORITY_HIGH' )
    end
end

--[[
	Returns true if the candidate already has been cached for the given loot
]]
function LootMasterML:IsCandidate( loot, candidate )

    if not loot then return false end;

    loot = self:GetLoot(loot);
    if not loot or not loot.id then return false end;

	if not loot
		or not self.lootTable
		or not self.lootTable[loot.id]
		or not self.lootTable[loot.id]['candidates'] then return false end;

	local rowID = self.lootTable[loot.id]['candidates'][candidate];
	if not rowID then return false end;

	return true;
end

--[[
	Stores some data in the candidate cache for the given loot
]]
function LootMasterML:SetCandidateData( loot, candidate, name, value, preventMonitorUpdate )

    --self:Debug(format('SetCandidateData(loot(%s), candidate(%s), name(%s), value(%s), preventMonitorUpdate(%s))', tostring(loot), tostring(candidate), tostring(name), tostring(value), tostring(preventMonitorUpdate)), true);

	local itemID = self:AddCandidate( loot, candidate );
	if not itemID then return end;

	local rowID = self.lootTable[itemID]['candidates'][candidate];
	if not rowID then return end;

  if name == 'response' then
    value = tonumber(value) or 1

    local responseData = LootMaster.RESPONSE[value]
    if responseData then
      self:SetCandidateData( loot, candidate, 'responsesort', responseData.SORT, true )
    end

    -- After the user has made their selections, show the responses again.
    if UnitName('player') == candidate and value > LootMaster.RESPONSE.TIMEOUT then
      self.lootTable[itemID].hideResponses = false
    end
  end

	for index,data in pairs( self.lootTable[itemID]['rowdata'][rowID]['cols'] ) do
		if data and data['name'] == name then
			self.lootTable[itemID]['rowdata'][rowID]['cols'][index]['value'] = value;

      -- Are we lootmaster for this loot? Lets send out a monitor message about the data change
      --if self.lootTable[itemID].mayDistribute and self:MonitorMessageRequired(itemID) then
      --    self:SendMonitorMessage( 'SETCANDIDATEDATA', itemID, candidate, name, value )
      --end

			return value
		end
	end

	self.lootTable[itemID]['rowdata'][rowID][name] = value;

    -- Are we lootmaster for this loot? Lets send out a monitor message about the data change
    --[[if self.lootTable[itemID].mayDistribute and (not preventMonitorUpdate) and self:MonitorMessageRequired(itemID) then

        -- Default priority
        local prio = "PRIORITY_NORMAL"

        -- High priority on response changes
        if name == 'response' then
            prio = "PRIORITY_HIGH"
        end

        -- Dont need the following changes
        if name=='roll' or name=='version' or name=='currentitem' or name=='currentitem2' then
            prio = nil
        end

        -- Do not send status updates before candidate list has been sent.
        if not self.lootTable[itemID].candidatesSent and name=='response' then
            prio = nil
        end

        if prio then
            self:SendMonitorMessage( 'SETCANDIDATEDATA', itemID, candidate, name, value, prio )
        end
    end]]--

	return value;
end

function LootMasterML:SetCandidateResponse( link, candidate, response, preventMonitorUpdate )
    response = tonumber(response) or 0;
    local old = tonumber(self:GetCandidateData( link, candidate, 'response' ) or 0) or 0

    local loot = self:GetLoot(link)
    if not loot then return end

    local response = loot.buttonTranslate[response] or response

    if old<LootMaster.RESPONSE.TIMEOUT and response >= LootMaster.RESPONSE.TIMEOUT then
        -- Increate response count
        loot.numResponses = loot.numResponses + 1
    elseif old>=LootMaster.RESPONSE.TIMEOUT and response < LootMaster.RESPONSE.TIMEOUT then
        -- decreate response count
        loot.numResponses = loot.numResponses - 1
    end

    return self:SetCandidateData( link, candidate, 'response', response, preventMonitorUpdate )
end

function LootMasterML:SetManualResponse(loot, candidate, response)

    loot = self:GetLoot(loot)
    if not loot then return end

    response = loot.buttonTranslate[response] or response

    local sResponse;
    local override = loot.buttonsByResponse[response]
    if override then
        sResponse = override.text
    elseif LootMaster.RESPONSE[response] then
        sResponse = LootMaster.RESPONSE[response].CODE
    end

    self:SetCandidateResponse(loot.id, candidate, response);
    self:SendWhisperResponse(format('Your selection for %s has been manually set to %s.', loot.link or 'unknown item', sResponse or 'unknown'), candidate);

    if self:MonitorMessageRequired(loot.id) then
        self:SendMonitorMessage( 'SETCANDIDATEDATA', loot.id, candidate, 'response', response )
    end

    self:ReloadMLTableForLoot( loot.id )

end

--[[
    Looks up the candidates equipment for the slot by inspecting.
]]--
function LootMasterML:InspectCandidate( loot, candidate )

    -- retrieve loot or return
    loot = self:GetLoot(loot);
    if not loot then return end;

    -- See if candidate if human controlled... you never know ;)
    if not UnitPlayerControlled(candidate) then return end;
    -- See if player is in inspection range.
    if not CheckInteractDistance(candidate,1) then return end;

    -- inspect the candidate
    NotifyInspect(candidate)

    -- Retrieve the itemlink, levels and gp value for the equipSlot.
    local gear = LootMaster:GetGearByINVTYPE(loot.equipLoc, candidate);

    local item1, item2 = strsplit('$', gear)
    self:SetCandidateData( loot.id, candidate, 'currentitem', item1, true );
    self:SetCandidateData( loot.id, candidate, 'currentitem2', item2, true );
    self:SetCandidateData( loot.id, candidate, 'foundGear', true, true );

    return true;
end

--[[
	Retrieves some data in the candidate cache for the given loot
]]
function LootMasterML:GetCandidateData( loot, candidate, name )

    if not loot then return end;
	loot = self:GetLoot(loot)

	if not loot or not loot.id
		or not self.lootTable
		or not self.lootTable[loot.id]
		or not self.lootTable[loot.id]['candidates'] then return end;

	local rowID = self.lootTable[loot.id]['candidates'][candidate];
	if not rowID then return end;

	for index,value in pairs( self.lootTable[loot.id]['rowdata'][rowID]['cols'] ) do
		if value and value['name'] == name then
			return self.lootTable[loot.id]['rowdata'][rowID]['cols'][index]['value']
		end
	end

	return self.lootTable[loot.id]['rowdata'][rowID][name];
end

--[[
	Retrieves some data in the candidate cache for the given loot
]]
function LootMasterML:GetCandidateDataByRowID( loot, rowID, name )

    if not loot then return end;
	loot = self:GetLoot(loot)

	if not loot or not loot.id then return end;
	if not rowID then return end;

	for index,value in pairs( self.lootTable[loot.id]['rowdata'][rowID]['cols'] ) do
		if value and value['name'] == name then
			return self.lootTable[loot.id]['rowdata'][rowID]['cols'][index]['value']
		end
	end

	return self.lootTable[loot.id]['rowdata'][rowID][name];
end

--[[
	Tries to give the loot to the given candidate
]]
function LootMasterML:GiveLootToCandidate( link, candidate, lootType, gp )

	local candidateID = nil;
	local slotID = nil;
	local loot = self:GetLoot(link)

    if not loot or not loot.id then
        return self:Print( format("Немогу отправить %s игроку %s, лут не найден в кеше", tostring(link), tostring(candidate) ) )
    end

	-- Look for the candidateID
	for cID = 1, 40 do
		local cName = GetMasterLootCandidate(cID)
		if cName and cName==candidate then
			candidateID = cID;
			break
		end;
	end;

	-- Look for the lootslotID
	for sID = 1, GetNumLootItems() do
		local _, sName = GetLootSlotInfo(sID);
		if sName and sName==loot.name then
			slotID = sID;
			break
		end;
	end;

	if not slotID then
		return self:Print( format("Немогу отправить %s игроку %s, Лут не найден (Уже отдан или окнолута закрыто?) ", tostring(loot.link), tostring(candidate) ) )
	end
	if not candidateID then
		return self:Print( format("Немогу отправить %s игроку %s, кандидат не найден (вышел с игры, вышел из группы?)", tostring(loot.link), tostring(candidate) ) )
	end

    -- [[ lootType == self.LOOTTYPE.BANK, self.LOOTTYPE.DISENCHANT, self.LOOTTYPE.GP ]]--
    -- [[ gp = amount of gp awarded to this item ]] --

    if lootType ~= LootMaster.LOOTTYPE.GP then
        gp = 0;
    end

    self:SetCandidateData( loot.id, candidate, 'lootType', lootType or 0 );
    self:SetCandidateData( loot.id, candidate, 'lootGP', tonumber(gp) or 0 );

	GiveMasterLoot( slotID, candidateID )

end

function LootMasterML:OnMasterLooterChange(masterlooter)
    -- if master looter is nil, return
    if not masterlooter then return end;

    -- Is there really a new master looter?
    if self.current_ml and self.current_ml==masterlooter then return end;

    -- cache the new ml
    self.current_ml = masterlooter;

    -- if player is not the current master looter, then just return.
    if masterlooter~=UnitName('player') then return end;

    -- Show a message here, based on the current settings
    if LootMaster.db.profile.use_epgplootmaster == 'enabled' then
        -- Always enable without asking
        LootMaster:Print('вы лут мастер, остлеживание лута включено');
        self:EnableTracking();
    elseif LootMaster.db.profile.use_epgplootmaster == 'disabled' then
        -- Disabled from the config panel
        LootMaster:Print('вы лут мастер, отслеживание выключено вручную (настройка: /lm config)');
        self:DisableTracking();
    else
        StaticPopup_Show("EPGPLOOTMASTER_ASK_TRACKING")
    end
end

function LootMasterML:CacheGuildInfo( event )
    local num = GetNumGuildMembers(false);
    for i=1, num do repeat
        local name, rank, rankIndex, _, classLocalized, _, _, _, _, _, classFileName = GetGuildRosterInfo(i)
        if name then
            if not self.guildInfo[name] then
                self.guildInfo[name] = {}
            end
            self.guildInfo[name].rank = rank;
            self.guildInfo[name].rankIndex = rankIndex;
            self.guildInfo[name].class = classFileName;
            self.guildInfo[name].classLocalized = classLocalized;

            -- Update the reverse class lookup table
            LootMaster:UpdateClassLocalizer(classLocalized, classFileName)
        end
    until true end
end



--[[ Deformat helps the parsing of the loot messages by creating a pattern from the
     original string and caching this ]]--
local deformat_cache = {}
function LootMasterML:Deformat(str, format)
  local pat = deformat_cache[format]
  if not pat then
    -- Escape special characters
    pat = format:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]",
                          function(c) return "%"..c end)
    pat = pat:gsub("%%%%([sd])", {
                             ["s"] = "(.-)",
                             ["d"] = "(%d+)",
                           })
    deformat_cache[format] = pat
  end
  return str:match(pat)
end

function LootMasterML:DeformatC(format)
    return deformat_cache[format];
end


--[[ Used in FilterLootMessage(), just try each function and see if the 2nd return value is set
]]--
local LootMessageFilters = {
        function( lootMessage ) local l,c = LootMasterML:Deformat( lootMessage, LOOT_ITEM_SELF_MULTIPLE ); return UnitName("player"),l,c end,
        function( lootMessage ) local l,c = LootMasterML:Deformat( lootMessage, LOOT_ITEM_PUSHED_SELF_MULTIPLE ); return UnitName("player"),l,c end,
        function( lootMessage ) return LootMasterML:Deformat( lootMessage, LOOT_ITEM_MULTIPLE ) end,
        function( lootMessage ) return UnitName("player"), LootMasterML:Deformat( lootMessage, LOOT_ITEM_PUSHED_SELF ), 1 end,
        function( lootMessage ) return UnitName("player"), LootMasterML:Deformat( lootMessage, LOOT_ITEM_SELF ), 1 end,
        function( lootMessage ) local p,l = LootMasterML:Deformat( lootMessage, LOOT_ITEM ); return p,l,1 end
};

--[[ Filters a lootmessage by reformatting the localised strings
    Returns playername, itemlink and itemcount.
]]--
function LootMasterML:FilterLootMessage( lootMessage )
    local player, link, count;
    for i, func in pairs(LootMessageFilters) do
        player, link, count = func(lootMessage);
        if player and link and count then
            return player, link, count;
        end
    end
    return false;
end

--[[ Find out if we're using master looting and find out who it is ]]--
function LootMasterML:GROUP_UPDATE()
    lootmethod, mlPartyID, mlRaidID = GetLootMethod();
    if lootmethod ~= 'master' then
        self.current_ml = nil;
        return
    end;
    if mlRaidID then
        -- we're in raid
        self:OnMasterLooterChange(GetRaidRosterInfo(mlRaidID))
    elseif mlPartyID==0 then
        -- player is ml
        self:OnMasterLooterChange(UnitName('player'))
    elseif mlPartyID then
        -- someone else in party is ml
        self:OnMasterLooterChange(UnitName('party'..mlPartyID))
    end
end

--[[ Someone received loot, lets see if it's in our cache. Send all candidates
     a message about this, so they can update their UI and register the lootdrop
     in a raidtracker for example ]]--
function LootMasterML:CHAT_MSG_LOOT( event, message )

    self:Debug("CHAT_MSG_LOOT");

    local sPlayer, sLink, iCount = self:FilterLootMessage(message)

    self:Debug(format("%s looted %sx%s", sPlayer or 'nil', sLink or 'nil', iCount or 'nil' ));

    if not sPlayer or sPlayer=='' or not sLink or sLink=='' or not iCount or tonumber(iCount)>1 then
        self:Debug("!player or !link or !iCount or iCount>1");
        return
    end;

    -- ok, someone looted something... lets see if we can find it in our cache
    local loot = self:GetLoot( sLink )

    -- Did we find anything?
    if not loot or not loot.candidates then return self:Debug('loot not found') end;

    -- Did we own this loot or are we just monitoring it?
    if not loot.mayDistribute then return self:Debug('only monitor loot, return') end;

    -- We did, now get some info about the loot adressee
    local lootType = self:GetCandidateData( sLink, sPlayer, 'lootType' ) or LootMaster.LOOTTYPE.UNKNOWN;
    local lootGP = tonumber(self:GetCandidateData( sLink, sPlayer, 'lootGP' )) or -1;

    if lootType==LootMaster.LOOTTYPE.GP and lootGP~=0 then
        if CanEditOfficerNote() and EPGP and EPGP.IncGPBy then
            EPGP.IncGPBy(EPGP, tostring(sPlayer) or 'nil', tostring(sLink) or 'nil', lootGP)
        else
            self:Print( format("<ОШИБКА> Немогу добавить GP в заметках офицеров для %s %s (EPGP не установлен или нет прав?!)", sPlayer or 'unknown player', sLink or 'unknown loot') )
        end
    end;

    -- now send everyone in raid/party/candidates some info about the drop so they can update their ui
    if GetNumRaidMembers()>0 then
        self:Debug("send to raid");
        self:SendCommand( 'LOOTED', format('%s^%s^%s^%s', sPlayer, sLink, lootType, lootGP ), 'RAID' );
    elseif GetNumPartyMembers()>0 then
        self:Debug("send to party");
        self:SendCommand( 'LOOTED', format('%s^%s^%s^%s', sPlayer, sLink, lootType, lootGP ), 'PARTY' );
    else
        self:Debug("send to candidates");
        for candidate, id in pairs(loot.candidates) do
            self:SendCommand( 'LOOTED', format('%s^%s^%s^%s', sPlayer, sLink, lootType, lootGP ), candidate );
        end
    end

    -- Update the candidates status to LOOTED when we have more than 1 item
    if loot.quantity>1 then
        self:SetCandidateData( sLink, sPlayer, 'looted', true );
    end

    -- Since it's looted, remove it from the cache and update the UI
    self:RemoveLoot(sLink);
    self:UpdateUI();

    self:Debug("CHAT_MSG_LOOT end");

end

--[[
	Event triggers when the master looter opens the popup on the loot screen
	In here we try to see what loot got selected and find the candidates for the
	loot. Ask the candidates if they want the loot. Tho, cache everything and make sure
	we don't ask the candidates more than one time (this could happen when the lootwindow
	gets opened more than one time)
]]
function LootMasterML:OPEN_MASTER_LOOT_LIST()

    -- Check if EPGPLM needs to track the loot.
    if not self:TrackingEnabled() then return end;

	-- Close the default confirm window
	StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION");

	--[[
	-- Some values we probably need
	LootFrame.selectedLootButton
	LootFrame.selectedSlot
	LootFrame.selectedQuality
	LootFrame.selectedItemName
	]]

	-- local lootIcon, lootName, lootQuantity, rarity = GetLootSlotInfo(LootFrame.selectedSlot);
	local _, lootName, lootQuantity, rarity = GetLootSlotInfo(LootFrame.selectedSlot);
	local link = GetLootSlotLink(LootFrame.selectedSlot)
    local itemID = self:GetItemIDFromLink(link)

    -- Traverse all lootslots and see how many of this item we have in total.
    local totalQuantity = 0
    local numLootSlots = GetNumLootItems();
    for slot=1, numLootSlots do
        local slotLink = GetLootSlotLink(slot);
        local slotItemID = self:GetItemIDFromLink(slotLink)
        if slotItemID and slotItemID==itemID then

            local _, _, slotQ, _ = GetLootSlotInfo(slot);

            -- A little sanity check; lets see if slotQuantity == 1
            if slotQ~=1 then
                self:Print( format("Немогу перераспределить %s  потому как число != 1 (%s). Пожалуйста зделайте это вручную.", link, slotQ) )
                return;
            end

            totalQuantity = totalQuantity + 1
        end

        self:Debug( format( 'OPEN_MASTER_LOOT_LIST: clicked %sx%s; slotCount %s; slotID %s; slotitem: %s', tostring(link), tostring(totalQuantity), tostring(numLootSlots), tostring(slot), tostring(slotLink) ) )
    end

    -- Fallback
    if not itemID then
        self:Print( format('Немогу получить количество с %s (не найдена вещь)', tostring(link)) );
        totalQuantity = 1
    end

    -- Another sanity check... Check total quantity > 1
    if totalQuantity<1 then
        self:Print( format("Немогу перераспределить %s потому что общее число < 1 (%s). Пожалуйста зделайте это вручную.", link, totalQuantity) )
		return;
    end

    -- Lootmaster is handling the loot, so lets close the default popup, unless alt is pressed
    if not IsAltKeyDown() then
        CloseDropDownMenus();
    end

    -- Send some debugging info to Bushmaster if the fecker is grouped.
    --if UnitName('Bushmaster') and totalQuantity>1 then
    --    self:SendWhisperResponse( format( '%sx%s, quantity counter works!', tostring(link), tostring(totalQuantity) ), 'Bushmaster' )
    --end

	-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
	-- local _,_,_, itemLevel, itemMinLevel, itemType, itemSubType,_, itemEquipLoc, itemTexture = GetItemInfo(link)

    -- Check to see if we already have the loot registered
    if self:GetLootID(link) then
        -- loot is already registered, just update the ui and do nothing.
        local loot = self:GetLoot(link);
        loot.quantity = totalQuantity or 1
        self:ReloadMLTableForLoot( link );
        self:Debug( format('Обновил %s количество до %s', tostring(link), tostring(tonumber(totalQuantity)) ), true )
        return;
    end

	-- Register the loot in the loottable
	local lootID = self:AddLoot(link, true, totalQuantity);
    if not lootID then return self:Print('Немогу зарегестрировать лут') end;

    -- Auto announce?
    local autoAnnounce = rarity >= (LootMaster.db.profile.auto_announce_threshold or 4);
    if LootMaster.db.profile.auto_announce_threshold == 0 then autoAnnounce=false end;

	-- Ok Lets see. Who are the candidates for this slot?
	for candidateID = 1, 40 do repeat
		local candidate = GetMasterLootCandidate(candidateID)
		if not candidate then break end;

		if not self:IsCandidate( lootID, candidate ) then

			-- Create the candidate for link;
			self:AddCandidate( lootID, candidate );
		end
	until true end

    -- Set the loot status to not announced.
    self.lootTable[lootID].announced = false;

    -- Lets see if we have to autoloot
    local isAutoLooted = false
    if LootMaster.db.profile.AutoLootThreshold~=0 and LootMaster.db.profile.AutoLooter~='' and self.lootTable[lootID].autoLootable then
        -- loot is below or equal to AutoLootThreshold and matches the autoLooter requirements
        -- try to give the loot.

        autoAnnounce = false

        if IsAltKeyDown() then
            self:Print('Не авто лут (alt+click использовано)')
        else
            isAutoLooted = true
            if self:IsCandidate( lootID, LootMaster.db.profile.AutoLooter or '' ) then
                self:Print(format('Авто лут %s игроку %s', link or 'nil', LootMaster.db.profile.AutoLooter or 'nil'))
                -- dont know if it will ever happen, but send all matching items to the autolooter
                for i=1, totalQuantity do
                    self:GiveLootToCandidate( lootID, LootMaster.db.profile.AutoLooter or '', LootMaster.LOOTTYPE.BANK )
                end
            else
                self:Print(format('Авто лут %s игроку %s провален. Не кандидат для этого лута.', link or 'nil', LootMaster.db.profile.AutoLooter or 'nil'))
            end
        end
    end

    -- See if we have to auto announce
    if autoAnnounce then
        if IsAltKeyDown() then
            self:Print('Не авто анонсирование(alt+click использовано)')
        else
            self:AnnounceLoot( lootID )
        end
    end

    -- Update the UI
    self:ReloadMLTableForLoot( lootID )

    -- Send candidate list to monitors
    if self:MonitorMessageRequired( lootID ) then
        self:SendCandidateListToMonitors( lootID )
    end;

end