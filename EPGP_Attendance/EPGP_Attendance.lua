----------------------------
--      Constants         --
----------------------------

local c_strMassEPAward = "mass_ep_award";
local c_strEPGPLibErrorMsg = "EPGP (dkp reloaded) is required to use EPGPAttendance";

local c_iCustomColumns = 4;

local c_iPage_ANY = -1;
local c_iPageMain = 1;
local c_iPageCharacter = 2;
local c_iPageHistory = 3;
local c_iPageChange = 4;

local c_iMainColPlayer = 1;
local c_iMainColEP = 2;
local c_iMainColGP = 3;
local c_iMainColPR = 4;
local c_iMainCol1 = 5;
local c_iMainCol2 = 6;
local c_iMainCol3 = 7;
local c_iMainCol4 = 8;

local c_iCharColDate = 1;
local c_iCharColEP = 2;
local c_iCharColChange = 3;

local c_iHistoryColDate = 1;
local c_iHistoryColChange = 2;

local c_iChangeColPlayer = 1;
local c_iChangeColEP = 2;

local c_colorHighPercent	= { r = 0.50, g = 1.00, b = 0.50, a = 1.00 }; -- Pastel green
local c_colorMedPercent		= { r = 1.00, g = 1.00, b = 0.50, a = 1.00 }; -- Pastel yellow
local c_colorLowPercent		= { r = 1.00, g = 0.50, b = 0.50, a = 1.00 }; -- Pastel red
local c_colorDefaultText	= { r = 1.00, g = 1.00, b = 1.00, a = 1.00 }; -- White
local c_colorDefaultBG		= { r = 0.00, g = 0.00, b = 0.00, a = 1.00 }; -- Black
local c_colorDefaultBG2		= { r = 0.05, g = 0.05, b = 0.05, a = 1.00 }; -- Dark gray
local c_colorHoverBG		= { r = 0.30, g = 0.30, b = 0.30, a = 0.30 }; -- Transparent gray
local c_colorAttendedRaid	= { r = 0.50, g = 1.00, b = 0.50, a = 1.00 }; -- Pastel green
local c_colorMissedRaid		= { r = 1.00, g = 0.50, b = 0.50, a = 1.00 }; -- Pastel red
local c_colorEPAdjustment	= { r = 0.50, g = 0.50, b = 0.50, a = 1.00 }; -- Gray
local c_colorNotInGuild		= { r = 0.50, g = 0.50, b = 0.50, a = 1.00 }; -- Gray
local c_colorExtraEP		= { r = 0.50, g = 0.50, b = 1.00, a = 1.00 }; -- Pastel blue
local c_colorInsufficientEP	= { r = 1.00, g = 0.50, b = 0.50, a = 1.00 }; -- Pastel red
local c_colorMassEPWithAdj	= { r = 1.00, g = 1.00, b = 0.50, a = 1.00 }; -- Pastel yellow
local c_colorDecayEP		= { r = 1.00, g = 0.50, b = 0.50, a = 1.00 }; -- Pastel red

local c_tmUnitsPerMinute = 60;
local c_iMinutesPerHour = 60;
local c_tmUnitsPerHour = c_iMinutesPerHour * c_tmUnitsPerMinute;
local c_tmUnitsPerDay = 24 * c_tmUnitsPerHour;

local c_tblSemiTransparentBackdrop =
{
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	tile = true, tileSize = 16, edgeSize = 16,
};
------------------------------
--     Global Functions     --
------------------------------

---------------------------------------------------------------------------------------------------
--	EPGPAttendance_TableCompareRows
--
--		Comparison function for the table.  Returns true if the left value should come
--		before the right value.
--
function EPGPAttendance_TableCompareRows(stTable, iRowLeft, iRowRight, iSortCol)

	local strDirection = stTable.cols[iSortCol].sort or stTable.cols[iSortCol].defaultsort or "asc";
	local tblLeftSortCell = stTable.data[iRowLeft].cols[iSortCol];
	local varLeftSortValue = tblLeftSortCell.sortValue or tblLeftSortCell.value;
	local tblRightSortCell = stTable.data[iRowRight].cols[iSortCol];
	local varRightSortValue = tblRightSortCell.sortValue or tblRightSortCell.value;

	--EPGPAttendance:PrintMessage(varLeftSortValue .. " vs " .. varRightSortValue); -- DEBUG

	if (varLeftSortValue == varRightSortValue and iSortCol ~= 1) then
		-- Try to break ties with the first column
		return EPGPAttendance_TableCompareRows(stTable, iRowLeft, iRowRight, 1);
	elseif (strDirection:lower() == "asc") then
		return varLeftSortValue < varRightSortValue;
	else
		return varLeftSortValue > varRightSortValue;
	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance_TableOnClickDoNavigate
--
--		OnClick handler for the tables.  Returns true if the click was handled.
--
function EPGPAttendance_TableOnClickDoNavigate(frmRow, frmCell, tblData, tblColumnDefs, iRowUI, iRow, iCol, stTable, ...)

	if (iRowUI and iRow) then

		-- Row clicked
		if (arg1 == "RightButton" or arg1 == "Button4") then
			-- Navigate back on right- or button4- click
			EPGPAttendance:NavigateBack();
		else
			-- Navigate into otherwise
			local varPageArg;
			local iPage;

			if (stTable == EPGPAttendance.stMainTable) then
				iPage = c_iPageCharacter;
				varPageArg = tblData[iRow].cols[c_iMainColPlayer].value;
			elseif (stTable == EPGPAttendance.stCharTable) then
				iPage = c_iPageChange;
				varPageArg = tblData[iRow].cols[c_iCharColDate].sortValue;
			elseif (stTable == EPGPAttendance.stHistoryTable) then
				iPage = c_iPageChange;
				varPageArg = tblData[iRow].cols[c_iHistoryColDate].sortValue;
			elseif (stTable == EPGPAttendance.stChangeTable) then
				iPage = c_iPageCharacter;
				varPageArg = tblData[iRow].cols[c_iChangeColPlayer].value;
			end

			EPGPAttendance:NavigatePage(iPage, varPageArg);
		end

		return true;

	else

		-- Column header clicked
		return false;

	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance_CloseSpecialWindows
--
--		Our override of CloseSpecialWindows.
--
function EPGPAttendance_CloseSpecialWindows(frmRow, frmCell, tblData, tblColumnDefs, iRowUI, iRow, iCol, stTable, ...)

	-- We use local variables because we don't want the short-circut behavior of the 'or' operator
	local fFoundOtherWindows = EPGPAttendance.fnOriginalCloseSpecialWindows();
	local fFoundMyWindow = EPGPAttendance:HideFrame();

	return fFoundOtherWindows or fFoundMyWindow;

end

------------------------------
--      Initialization      --
------------------------------

EPGPAttendance = AceLibrary("AceAddon-3.0"):NewAddon("EPGPAttendance", "AceConsole-3.0", "AceTimer-3.0")

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:OnInitialize
--
--		Called on boot.
--
function EPGPAttendance:OnInitialize()

	EPGPAttendance.LibGuildStorage = LibStub("LibGuildStorage-1.0");

	if (not EPGPAttendance.LibGuildStorage) then
		EPGPAttendance:PrintMessage(c_strEPGPLibErrorMsg);
		EPGPAttendance:RegisterChatCommand("epgpa", function() EPGPAttendance:PrintMessage(c_strEPGPLibErrorMsg); end);
		return;
	end

	local c_tblDefaultSettings = {
		profile = {
			fShowFormerRaiders = false,
			fShowEPAdjustments = true,
			iHighAttendancePercent = 80,
			iMedAttendancePercent = 50,
			iDecayQuorum = 10,
			iRaidQuorum = 10,
			tmRaidStartTime = 19.5 * c_tmUnitsPerHour, -- 5 PM
			iDataRetentionDays = 1000,

			tblColumns = {
				[1] = {
					strName = "7-дней",
					fLifetime = false,
					iAttendanceSpanDays = 7,
					fNormalizeWeightByDay = false,
					fWeightByEP = true,
				},
				[2] = {
					strName = "14-дней",
					fLifetime = false,
					iAttendanceSpanDays = 14,
					fNormalizeWeightByDay = false,
					fWeightByEP = true,
				},
				[3] = {
					strName = "21-дней",
					fLifetime = false,
					iAttendanceSpanDays = 21,
					fNormalizeWeightByDay = false,
					fWeightByEP = true,
				},
				[4] = {
					strName = "30-дней",
					fLifetime = false,
					iAttendanceSpanDays = 30,
					fNormalizeWeightByDay = false,
					fWeightByEP = true,
				},
			},
		}
	};

	local tblOptionsLayout = {
		type = "group",
		name = "EPGPAttendance",
		get = function(info) return EPGPAttendance.db.profile[ info[#info] ] end,
		set = function(info, value) EPGPAttendance.db.profile[ info[#info] ] = value end,
		args = {
			General = {
				order = 1,
				type = "group",
				name = "General Settings",
				desc = "General Settings",
				args = {
					lblIntro = {
						order = 1,
						type = "description",
						name = "EPGPAttendance is a mod that monitors changes in EP while you are logged in and deduces attendance.",
					},
					DisplayOpts = {
						type = "group",
						name = "Display",
						guiInline = true,
						order = 2,
						args = {
							fShowFormerRaiders = {
								type = "toggle",
								name = "Show former raiders",
								desc = "In the main page, displays attendance data for characters with no EP.",
								order = 1,
								set = function(info, value) EPGPAttendance:SetOptionAndInvalidatePage(info, value, c_iPageMain); end,
							},
							fShowEPAdjustments = {
								type = "toggle",
								name = "Show EP adjustments",
								desc = "In the character info page, shows EP adjustments that have no bearing on attendance.",
								order = 2,
								set = function(info, value) EPGPAttendance:SetOptionAndInvalidatePage(info, value, c_iPageCharacter); end,
							},
							iHighAttendancePercent = {
								type = "range",
								name = "Green attendance %",
								desc = "The minimum attendance percent to be displayed in green",
								order = 4,
								width = "double",
								min = 0,
								max = 100,
								step = 1,
								bigStep = 5,
								set = function(info, value) EPGPAttendance:SetOptionAndInvalidatePage(info, value, c_iPageMain); end,
							},
							iMedAttendancePercent = {
								type = "range",
								name = "Yellow attendance %",
								desc = "The minimum attendance percent to be displayed in yellow",
								order = 5,
								width = "double",
								min = 0,
								max = 100,
								step = 1,
								bigStep = 5,
								set = function(info, value) EPGPAttendance:SetOptionAndInvalidatePage(info, value, c_iPageMain); end,
							},
							btnResetFrameLocation = {
								type = "execute",
								name = "Reset frame",
								desc = "Recenters the EPGPAttendance frame.",
								order = 6,
								func = function() EPGPAttendance:ResetFrameLocation() end,
							};
						},
					},
					DataOptions = {
						type = "group",
						name = "Дата",
						guiInline = true,
						order = 3,
						args = {
							iRaidQuorum = {
								type = "range",
								name = "Raid quorum",
								desc = "At least this many guildmates must gain the *same* amount of EP for a change to be labelled a raid.",
								order = 1,
								width = "double",
								min = 1,
								max = 40,
								step = 1,
								set = function(info, value) EPGPAttendance.db.profile.iRaidQuorum = value; EPGPAttendance:ResetMassEPAwardCache(true); end,
							},
							iDecayQuorum = {
								type = "range",
								name = "Decay quorum",
								desc = "At least this many guildmates must lose EP for a change to be labelled an 'EP Decay'.",
								order = 2,
								width = "double",
								min = 1,
								max = 40,
								step = 1,
								set = function(info, value) EPGPAttendance:SetOptionAndInvalidatePage(info, value, c_iPageHistory); end,
							},
							tmRaidStartTime = {
								type = "input",
								name = "Начало рейда",
								desc = "The start time of a raid (in the server's time zone). Mass EP awards prior to this time will be considered a raid on the previous day.  This has subtle effects on attendance calculations.",
								order = 3,
								validate = function(info, value) if (not EPGPAttendance:TmParseTimeOfDay(value)) then return "Please format the time like '4:30 PM'." else return true end end,
								get = function(info) return date("!%I:%M %p", EPGPAttendance.db.profile.tmRaidStartTime) end,
								set = function(info, value) EPGPAttendance:SetOptionAndInvalidatePage(info, EPGPAttendance:TmParseTimeOfDay(value), c_iPageMain); end,
							},
							iDataRetentionDays = {
								type = "range",
								name = "Data retention",
								desc = "The amount of data to keep (in days).  Reducing this value will improve performance but will also result in permanent data loss.",
								order = 4,
								width = "double",
								min = 30,
								max = 1000,
								step = 10,
							},
						},
					},
				},
			},
		},
	};

	-- Initialize the page navigation history
	EPGPAttendance.tblNavStack = { { iPage = c_iPageMain } };

	-- Initialize the database
	EPGPAttendance.db = LibStub("AceDB-3.0"):New("EPGPAttendanceDB", c_tblDefaultSettings, "Default");

	-- Ensure the guilds table
	if (not EPGPAttendance.db.realm.tblGuilds) then
		EPGPAttendance.db.realm.tblGuilds = {};
	end

	-- Fill in options tree subnodes
	for iCustomCol = 1, c_iCustomColumns do
		tblOptionsLayout.args["Column" .. iCustomCol] = EPGPAttendance:TblCreateColumnOptionGroup(iCustomCol, 10 + iCustomCol);
	end
	tblOptionsLayout.args.Profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(EPGPAttendance.db);

	LibStub("AceConfig-3.0"):RegisterOptionsTable("EPGPAttendance", tblOptionsLayout);
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("EPGPAttendance", 640, 480);
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("EPGPAttendance", nil, nil, "General");
	-- Register options tree subnodes
	for iCustomCol = 1, c_iCustomColumns do
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("EPGPAttendance", tblOptionsLayout.args["Column" .. iCustomCol].name, "EPGPAttendance", "Column" .. iCustomCol);
	end
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("EPGPAttendance", "Profile", "EPGPAttendance", "Profile");

	-- Listen to the command line
	EPGPAttendance:RegisterChatCommand("epgpa", "ChatCommand");

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:OnEnable
--
--		Called when Ace enables this addon.
--
function EPGPAttendance:OnEnable()

	if (EPGPAttendance.LibGuildStorage) then
		-- Compute the difference between server time and local time
		local iUtcMinuteInDay = tonumber(date("!%H")) * c_iMinutesPerHour + tonumber(date("!%M"));
		local iServerHourInDay, iServerMinuteInHour = GetGameTime();
		local iServerMinuteInDay = iServerHourInDay * c_iMinutesPerHour + iServerMinuteInHour;

		local iUtcToServerOffsetMins = 30 * floor((iServerMinuteInDay - iUtcMinuteInDay + 15) / 30);
		if (iUtcToServerOffsetMins >= 12 * c_iMinutesPerHour) then
			iUtcToServerOffsetMins = iUtcToServerOffsetMins - 24 * c_iMinutesPerHour;
		end
		--EPGPAttendance:PrintMessage("iUtcToServerOffsetMins = " .. iUtcToServerOffsetMins); -- DEBUG
		EPGPAttendance.tmUtcToServerOffset = iUtcToServerOffsetMins * c_tmUnitsPerMinute;

		-- Monitor guild notes
		EPGPAttendance.LibGuildStorage.RegisterCallback(self, "GuildNoteChanged", "OnGuildNoteChange");
		EPGPAttendance.LibGuildStorage.RegisterCallback(self, "GuildNoteDeleted", "OnGuildNoteDeleted");
	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:OnDisable
--
--		Called when Ace disables this addon.
--
function EPGPAttendance:OnDisable()

	if (EPGPAttendance.LibGuildStorage) then
		-- Stop monitoring guild notes
		EPGPAttendance.LibGuildStorage.UnregisterAllCallbacks(self);
	end

end

------------------------------
--        Functions         --
------------------------------

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:PrintMessage
--
--		Prints a message to the default chat frame.
--
function EPGPAttendance:PrintMessage(strMsg)

	DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7fEPGPAttendance|r: " .. strMsg);

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:FIsSpecialPlayerName
--
--		Returns true if the given player name is a fake name used by our data structures.
--
function EPGPAttendance:FIsSpecialPlayerName(strPlayer)

	return not strPlayer or strPlayer == c_strMassEPAward;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TmParseTimeOfDay
--
--		Parses a time of day.  Returns nil on error.
--
function EPGPAttendance:TmParseTimeOfDay(strTime)

	if (not strTime) then
		return nil;
	end

	local strHour, strMinute, strAMPM = string.match(strTime, "^(%d+):(%d+)(.*)$");

	if (not strHour or not strMinute or not strAMPM) then
		return nil;
	end

	local iMinute = tonumber(strMinute);

	if (iMinute < 0 or iMinute > 59) then
		return nil;
	end

	local fPM = string.find(strAMPM, "^[^%w]*[pP][^%w]*[mM][^%w]*$") or string.find(strAMPM, "^[^%w]*[pP][^%w]*$");
	local fAM = string.find(strAMPM, "^[^%w]*[aA][^%w]*[mM][^%w]*$") or string.find(strAMPM, "^[^%w]*[aA][^%w]*$");
	local iHour = tonumber(strHour);

	if (fPM or fAM) then

		assert(not fPM or not fAM);

		-- AM/PM format means only 1-12 are legal
		if (iHour < 1 or iHour > 12) then
			return nil;
		end

		-- Convert to 0-23 format
		if (iHour == 12) then
			iHour = 0;
		end
		if (fPM) then
			iHour = iHour + 12;
		end

	else

		-- If there are any non-trivial characters then I don't know how to parse it
		if (string.find(strAMPM, "%w")) then
			return nil;
		end
	
		-- Non-AM/PM format means 0-23 are legal
		if (iHour < 0 or iHour > 23) then
			return nil;
		end

	end

	assert(iHour >= 0 and iHour <= 23);

	return iHour * c_tmUnitsPerHour + iMinute * c_tmUnitsPerMinute;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblGetColumnProfile
--
--		Returns the profile option table for the appropriate column given the info argument
--		for the AceConfig get/set functions.
--
function EPGPAttendance:TblGetColumnProfile(info)
	local iCol = tonumber(string.match(info[#info - 1], "^Column(%d+)$")); 
	return EPGPAttendance.db.profile.tblColumns[iCol];
end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblCreateColumnOptionGroup
--
--		Creates a table for a column's option group.
--
function EPGPAttendance:TblCreateColumnOptionGroup(iCol, iOrder)
	return 
	{
		type = "group",
		name = "Customize Column " .. iCol,
		--guiInline = true,
		order = iOrder,
		get = function(info) return EPGPAttendance:TblGetColumnProfile(info)[ info[#info] ]; end,
		set = function(info, value) EPGPAttendance:TblGetColumnProfile(info)[ info[#info] ] = value; EPGPAttendance:InvalidatePage(c_iPageMain); end,
		args = {
			strName = {
				type = "input",
				name = "Column name",
				desc = "The name of the column.",
				order = 1,
				width = "double",
				set = function(info, value)
						EPGPAttendance:TblGetColumnProfile(info)[ info[#info] ] = value;
						-- Refresh the columns on the main table
						if (EPGPAttendance.stMainTable) then
							EPGPAttendance.stMainTable.SetDisplayCols(EPGPAttendance.stMainTable, EPGPAttendance:TblCreateMainTableColumnDefinition());
						end
					end,
			},
			fLifetime = {
				type = "toggle",
				name = "Lifetime attendance",
				desc = "Start counting attendance from the player's first EP gain.",
				order = 2,
			},
			iAttendanceSpanDays = {
				type = "range",
				name = "Attendance span",
				desc = "Start counting attendance from this many days ago.",
				order = 3,
				width = "double",
				min = 0,
				max = 1000,
				step = 1,
				bigStep = 10,
				disabled = function(info) return EPGPAttendance:TblGetColumnProfile(info).fLifetime; end,
			},
			fNormalizeWeightByDay = {
				type = "toggle",
				name = "Normalize weight by day",
				desc = "For attendance calculations, make sure that each day carries the same weight.",
				order = 4,
				width = "double",
			},
			fWeightByEP = {
				type = "toggle",
				name = "Weight by EP",
				desc = "For attendance calculations, weight individual raids proportionally by EP.\n\n"
						.. "If normalizing weight by day, weight individual raids occuring on the same day by EP.",
				order = 5,
				width = "double",
			},
			fIgnoreDoW0 = {
				type = "toggle",
				name = "Ignore Sundays",
				desc = "For attendance calculations, ignore Sundays.",
				order = 10,
			},
			fIgnoreDoW1 = {
				type = "toggle",
				name = "Ignore Mondays",
				desc = "For attendance calculations, ignore Mondays.",
				order = 11,
			},
			fIgnoreDoW2 = {
				type = "toggle",
				name = "Ignore Tuesdays",
				desc = "For attendance calculations, ignore Tuesdays.",
				order = 12,
			},
			fIgnoreDoW3 = {
				type = "toggle",
				name = "Ignore Wednesdays",
				desc = "For attendance calculations, ignore Wednesdays.",
				order = 13,
			},
			fIgnoreDoW4 = {
				type = "toggle",
				name = "Ignore Thursdays",
				desc = "For attendance calculations, ignore Thursdays.",
				order = 14,
			},
			fIgnoreDoW5 = {
				type = "toggle",
				name = "Ignore Fridays",
				desc = "For attendance calculations, ignore Fridays.",
				order = 15,
			},
			fIgnoreDoW6 = {
				type = "toggle",
				name = "Ignore Saturdays",
				desc = "For attendance calculations, ignore Saturdays.",
				order = 16,
			},
		},
	};
end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblCreateMainTableColumnDefinition
--
--		Creates the column definition for the Main table (the last 4 columns have customizeable
--		text).
--
function EPGPAttendance:TblCreateMainTableColumnDefinition()
	return {
		[c_iMainColPlayer] = {
			name = "Имя",
			width = 100,
			align = "LEFT",
			color = c_colorDefaultText,
			bgcolor = c_colorDefaultBG,
			defaultsort = "dsc",			
			comparesort = EPGPAttendance_TableCompareRows,
		},
		[c_iMainColEP] = {
			name = "EP",
			width = 50,
			align = "RIGHT",
			color = c_colorDefaultText,
			bgcolor = c_colorDefaultBG2,
			defaultsort = "dsc",
			comparesort = EPGPAttendance_TableCompareRows,
		},
		[c_iMainColGP] = {
			name = "GP",
			width = 50,
			align = "RIGHT",
			color = c_colorDefaultText,
			bgcolor = c_colorDefaultBG2,
			defaultsort = "dsc",
			comparesort = EPGPAttendance_TableCompareRows,
		},
		[c_iMainColPR] = {
			name = "PR",
			width = 50,
			align = "RIGHT",
			color = c_colorDefaultText,
			bgcolor = c_colorDefaultBG2,
			defaultsort = "dsc",
			comparesort = EPGPAttendance_TableCompareRows,
		},
		[c_iMainCol1] = {
			name = EPGPAttendance.db.profile.tblColumns[1].strName,
			width = 50,
			align = "RIGHT",
			color = c_colorDefaultText,
			bgcolor = c_colorDefaultBG,
			defaultsort = "dsc",
			comparesort = EPGPAttendance_TableCompareRows,
		},
		[c_iMainCol2] = {
			name = EPGPAttendance.db.profile.tblColumns[2].strName,
			width = 50,
			align = "RIGHT",
			color = c_colorDefaultText,
			bgcolor = c_colorDefaultBG,
			defaultsort = "dsc",
			comparesort = EPGPAttendance_TableCompareRows,
		},
		[c_iMainCol3] = {
			name = EPGPAttendance.db.profile.tblColumns[3].strName,
			width = 50,
			align = "RIGHT",
			color = c_colorDefaultText,
			bgcolor = c_colorDefaultBG,
			defaultsort = "dsc",
			comparesort = EPGPAttendance_TableCompareRows,
		},
		[c_iMainCol4] = {
			name = EPGPAttendance.db.profile.tblColumns[4].strName,
			width = 50,
			align = "RIGHT",
			color = c_colorDefaultText,
			bgcolor = c_colorDefaultBG,
			defaultsort = "dsc",
			sort = "dsc",
			comparesort = EPGPAttendance_TableCompareRows,
		},
	};
end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TmGetChangeNum
--
--		Returns the change number for a change occurring now.  If a tblPersistGuild is passed,
--		this function will return the same exact change number for all calls in a certain
--		window of time (currently, 5 minutes).
--
function EPGPAttendance:TmGetChangeNum(tblPersistGuild)

	local tmCurrentChangeNum = time() + EPGPAttendance.tmUtcToServerOffset;

	if (not tblPersistGuild) then
		return tmCurrentChangeNum;
	end

	-- Start a new change number if we don't have one or if more than 5 minutes have elapsed
	-- since our last change number.
	if (not tblPersistGuild.tmLastChangeNum or tmCurrentChangeNum - tblPersistGuild.tmLastChangeNum > 5 * c_tmUnitsPerMinute) then
		tblPersistGuild.tmLastChangeNum = tmCurrentChangeNum;
	end

	return tblPersistGuild.tmLastChangeNum;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TmGetRaidDay
--
--		Returns the effective raid day for a given change (in the same units as time()).
--
function EPGPAttendance:TmGetRaidDay(tmChangeNum)

	if (not tmChangeNum) then
		tmChangeNum = EPGPAttendance:TmGetChangeNum();
	end
	
	return c_tmUnitsPerDay * floor((tmChangeNum - EPGPAttendance.db.profile.tmRaidStartTime) / c_tmUnitsPerDay);

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:IGetRaidDayOfWeek
--
--		Returns the raid day of the week for a given change (0=Sunday, 1=Monday, ..., 6=Saturday).
--
function EPGPAttendance:IGetRaidDayOfWeek(tmChangeNum)

	local tmRaidDay = EPGPAttendance:TmGetRaidDay(tmChangeNum);
	--EPGPAttendance:PrintMessage(date("!%a %m/%d %I:%M %p", tmChangeNum) .. " -> " .. date("!%a %m/%d %I:%M %p", tmRaidDay));
	
	return tonumber(date("!%w", tmRaidDay)), tmRaidDay;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblGetPersistedGuildTable
--
--		Returns the table for the current guild.
--
function EPGPAttendance:TblGetPersistedGuildTable()

	-- Ensure guild name
	local strGuild = GetGuildInfo("player");
	if (not strGuild) then
		return;
	end

	-- Ensure guild table
	local tblPersistGuild = EPGPAttendance.db.realm.tblGuilds[strGuild];
	if (not tblPersistGuild) then
		tblPersistGuild = { tblLastEP = {}, tblChanges = {} };
		EPGPAttendance.db.realm.tblGuilds[strGuild] = tblPersistGuild;
	end

	-- Because this is a potential data loss issue, be extra suspicious about iDataRetentionDays
	if (EPGPAttendance.db.profile.iDataRetentionDays and EPGPAttendance.db.profile.iDataRetentionDays >= 30) then
		-- Prune every 24 hours
		local tmNow = EPGPAttendance:TmGetChangeNum();
		if (not tblPersistGuild.iLastPruneCheck or tmNow - tblPersistGuild.iLastPruneCheck > c_tmUnitsPerDay) then

			--EPGPAttendance:PrintMessage("Pruning old attendance data..."); -- DEBUG
			tblPersistGuild.iLastPruneCheck = tmNow;

			local tmPruneThreshold = EPGPAttendance:TmGetRaidDay() - EPGPAttendance.db.profile.iDataRetentionDays * c_tmUnitsPerDay;
			for tmChangeNum, tblPersistChange in pairs(tblPersistGuild.tblChanges) do
				if (tmChangeNum < tmPruneThreshold) then
					tblPersistGuild.tblChanges[tmChangeNum] = nil;
				end
			end

		end
	end

	return tblPersistGuild;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:OnGuildNoteChange
--
--		Handles a change (or initialization) of a guild note.
--
function EPGPAttendance:OnGuildNoteChange(callback, strPlayer, strNote)

	-- Dirty the main page
	EPGPAttendance:InvalidatePage(c_iPageMain);

	-- Ignore non-EPGP updates
	local strEP, _ = string.match(strNote, "^(%d+),(%d+)$");
	if (not strEP) then
		return;
	end
	local iEP = tonumber(strEP);

	-- Get the guild table
	local tblPersistGuild = EPGPAttendance:TblGetPersistedGuildTable();
	if (not tblPersistGuild) then
		EPGPAttendance:PrintMessage("Error: received EPGP update for " .. strPlayer .. " but failed to get guild name");
		return;
	end

	-- Ensure the history entry for this guildmate
	if (not tblPersistGuild.tblLastEP[strPlayer]) then
		-- The first time we see a guildmate, just create an entry with his current EP
		tblPersistGuild.tblLastEP[strPlayer] = iEP;
	elseif (iEP ~= tblPersistGuild.tblLastEP[strPlayer]) then
		-- Subsequent changes to EP should be recorded
		local iEPChange = iEP - tblPersistGuild.tblLastEP[strPlayer];
		local tmChangeNum = EPGPAttendance:TmGetChangeNum(tblPersistGuild);

		-- Ensure the change table exists
		if (not tblPersistGuild.tblChanges[tmChangeNum]) then
			tblPersistGuild.tblChanges[tmChangeNum] = {};
		end
		local tblPersistChange = tblPersistGuild.tblChanges[tmChangeNum];

		-- Add the change to our entry
		if (tblPersistChange[strPlayer]) then
			tblPersistChange[strPlayer] = tblPersistChange[strPlayer] + iEPChange;
		else
			tblPersistChange[strPlayer] = iEPChange;
		end

		-- Any mass EP award computed for this change is now invalid
		tblPersistChange[c_strMassEPAward] = nil;

		-- If there's first change info, ensure this player has it
		if (tblPersistGuild.tblLifetimeStart and not tblPersistGuild.tblLifetimeStart[strPlayer]) then
			tblPersistGuild.tblLifetimeStart[strPlayer] = tmChangeNum;
		end

		--EPGPAttendance:PrintMessage(strPlayer .. " => " .. iEP .. " (delta:" .. iEPChange .. ")"); -- DEBUG

		tblPersistGuild.tblLastEP[strPlayer] = iEP;

		-- Dirty the all pages
		EPGPAttendance:InvalidatePage();
	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:OnGuildNoteDeleted
--
--		Handles a removal of a guild note (i.e. gkick/gquit).
--
function EPGPAttendance:OnGuildNoteDeleted(callback, strPlayer)

	-- Dirty the main page
	EPGPAttendance:InvalidatePage(c_iPageMain);

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:IGetMassEPAward
--
--		Computes and returns the mass EP award in this change.  0 means this change is not a
--		mass EP award.
--
function EPGPAttendance:IGetMassEPAward(tblPersistChange)

	if (nil ~= tblPersistChange[c_strMassEPAward]) then
		return tblPersistChange[c_strMassEPAward];
	end

	local tblFreq = {};
	local iBestEPDelta = 0;
	local iBestFreq = 0;

	for strPlayer, iEPDelta in pairs(tblPersistChange) do
		-- Only look at positive changes
		if (iEPDelta > 0) then
			-- Tally up the changes
			if (not tblFreq[iEPDelta]) then
				tblFreq[iEPDelta] = 1;
			else
				tblFreq[iEPDelta] = tblFreq[iEPDelta] + 1;
			end

			-- Look for the most frequent delta (if there's a tie, go for the smaller EP delta)
			if (iBestFreq < tblFreq[iEPDelta] or iBestFreq == tblFreq[iEPDelta] and iEPDelta < iBestEPDelta) then
				iBestFreq = tblFreq[iEPDelta];
				iBestEPDelta = iEPDelta;
			end
		end
	end

	--EPGPAttendance:PrintMessage("Analyzing change: iBestFreq=" .. iBestFreq .. " iBestEPDelta=" .. iBestEPDelta); -- DEBUG

	-- Save the analysis
	if (iBestFreq >= EPGPAttendance.db.profile.iRaidQuorum) then
		tblPersistChange[c_strMassEPAward] = iBestEPDelta;
	else
		tblPersistChange[c_strMassEPAward] = 0;
	end

	return tblPersistChange[c_strMassEPAward];

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:ResetMassEPAwardCache
--
--		Deletes any cached information used by EPGPAttendance:IGetMassEPAward().
--
function EPGPAttendance:ResetMassEPAwardCache(fRefreshUI)

	-- Get the guild table
	local tblPersistGuild = EPGPAttendance:TblGetPersistedGuildTable();
	if (not tblPersistGuild) then
		return;
	end

	-- Iterate through all the changes and reset the cached value for the mass EP award
	for tmChangeNum, tblPersistChange in pairs(tblPersistGuild.tblChanges) do
		tblPersistChange[c_strMassEPAward] = nil;
	end

	if (fRefreshUI and EPGPAttendance.frmTitleBar:IsShown()) then
		EPGPAttendance:NavigatePage();
	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:EnsureTblLifetimeStart
--
--		Ensures that tblLifetimeStart exists and is calculated for the given tblPersistGuild.
--
function EPGPAttendance:EnsureTblLifetimeStart(tblPersistGuild)

	if (not tblPersistGuild.tblLifetimeStart) then

		local tblLifetimeStart = {};

		-- Go through all the changes and build up a table of each player's minimum tmChangeNum
		for tmChangeNum, tblPersistChange in pairs(tblPersistGuild.tblChanges) do
			for strPlayer, iEPDelta in pairs(tblPersistChange) do
				if (iEPDelta > 0
						and not EPGPAttendance:FIsSpecialPlayerName(strPlayer)
						and (not tblLifetimeStart[strPlayer] or tmChangeNum < tblLifetimeStart[strPlayer])) then
					tblLifetimeStart[strPlayer] = tmChangeNum;
				end
			end
		end

		tblPersistGuild.tblLifetimeStart = tblLifetimeStart;

	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblCreateColoredPercentCell
--
--		Computes a percent from a numerator and denominator and makes a cell for display.
--		0/0 is treated as 0%.
--
function EPGPAttendance:TblCreateColoredPercentCell(iNum, iDen)

	local iPercent = 0;
	local dSortablePercent = 0.0;
	local tblColor = c_colorLowPercent;

	if (iNum and iDen and iDen > 0) then
		dSortablePercent = iNum / iDen;
		iPercent = floor((iNum * 100 + 0.5) / iDen);
	end

	if (iPercent >= EPGPAttendance.db.profile.iHighAttendancePercent) then
		tblColor = c_colorHighPercent;
	elseif (iPercent >= EPGPAttendance.db.profile.iMedAttendancePercent) then
		tblColor = c_colorMedPercent;
	end

	return { value = iPercent .. "%", sortValue = dSortablePercent, color = tblColor };

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblCreateColoredPercentCell
--
--		Computes a percent from a numerator and denominator and makes a cell for display.
--		0/0 is treated as 0%.
--
function EPGPAttendance:TblCreateColoredDateTimeCell(tmChangeNum)

	local strFormatted = date("!%a %m/%d %I:%M %p", tmChangeNum);
	--strFormatted = EPGPAttendance:IGetRaidDayOfWeek(tmChangeNum) .. strFormatted; -- DEBUG
	return { value = strFormatted, sortValue = tmChangeNum };

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblComputeMainTableData
--
--		Computes and returns the contents of the main table.
--
function EPGPAttendance:TblComputeMainTableData()

	-- Get the guild table
	local tblPersistGuild = EPGPAttendance:TblGetPersistedGuildTable();
	if (not tblPersistGuild) then
		return {};
	end

	local tblWeightsPerDay = {{}, {}, {}, {}};
	local tblPerPlayerNum = {};
	local tblPerPlayerDen = {};
	local tblNonLifetimeStart = {0, 0, 0, 0};
	local tblNonLifetimeDen = {0, 0, 0, 0};
	local tblColumnOptions = EPGPAttendance.db.profile.tblColumns;
	local fHasLifetimeCol = false;
	local fHasNormalizeWeightByDayCol = false;

	assert(#tblWeightsPerDay == c_iCustomColumns);
	assert(#tblNonLifetimeStart == c_iCustomColumns);
	assert(#tblNonLifetimeDen == c_iCustomColumns);

	-- Analyze the custom columns
	for iCustomCol = 1, c_iCustomColumns do
		if (tblColumnOptions[iCustomCol].fLifetime) then
			fHasLifetimeCol = true;
		else
			local iSpan = c_tmUnitsPerDay * tblColumnOptions[iCustomCol].iAttendanceSpanDays;
			tblNonLifetimeStart[iCustomCol] = EPGPAttendance:TmGetRaidDay() - iSpan;
		end

		if (tblColumnOptions[iCustomCol].fNormalizeWeightByDay) then
			fHasNormalizeWeightByDayCol = true;
		end
	end

	-- Build up per-day weights, if necessary
	if (fHasNormalizeWeightByDayCol) then
		for tmChangeNum, tblPersistChange in pairs(tblPersistGuild.tblChanges) do
			local iMassEPAward = EPGPAttendance:IGetMassEPAward(tblPersistChange);
			-- Ignore changes that aren't mass EP awards
			if (iMassEPAward > 0) then
				for iCustomCol = 1, c_iCustomColumns do
					if (tblColumnOptions[iCustomCol].fNormalizeWeightByDay) then
						-- Sum up the total weight for each day
						local tmRaidDay = EPGPAttendance:TmGetRaidDay(tmChangeNum);
						local iWeight = 1;
						if (tblColumnOptions[iCustomCol].fWeightByEP) then
							iWeight = iMassEPAward;
						end
						tblWeightsPerDay[iCustomCol][tmRaidDay] = (tblWeightsPerDay[iCustomCol][tmRaidDay] or 0) + 1;
					end
				end
			end
		end
	end

	--EPGPAttendance:PrintMessage("TblComputeMainTableData is iterating"); -- DEBUG

	-- Create entries for everyone with lifetime data
	EPGPAttendance:EnsureTblLifetimeStart(tblPersistGuild);
	for strPlayer, _ in pairs(tblPersistGuild.tblLifetimeStart) do
		tblPerPlayerNum[strPlayer] = {0, 0, 0, 0};
		tblPerPlayerDen[strPlayer] = {0, 0, 0, 0};
		assert(c_iCustomColumns == #tblPerPlayerNum[strPlayer]);
		assert(c_iCustomColumns == #tblPerPlayerDen[strPlayer]);
	end

	-- Create entries for everyone in the guild with EPGP
	local iCtr;
	local tblGuildSnapshot = {};
	EPGPAttendance.LibGuildStorage:Snapshot(tblGuildSnapshot);
	for iCtr = 1, #tblGuildSnapshot.roster_info do
		-- Does this player have an entry already?
		local strPlayer = tblGuildSnapshot.roster_info[iCtr][1];
		if (not tblPerPlayerNum[strPlayer]) then
			-- Does this player have a guild note?
			local strNote = tblGuildSnapshot.roster_info[iCtr][3];
			if (strNote) then
				-- Is this an EPGP guild note?
				local strEP, strGP = string.match(strNote, "^(%d+),(%d+)$");
				if (strEP and strGP) then
					tblPerPlayerNum[strPlayer] = {0, 0, 0, 0};
					tblPerPlayerDen[strPlayer] = {0, 0, 0, 0};
					assert(c_iCustomColumns == #tblPerPlayerNum[strPlayer]);
					assert(c_iCustomColumns == #tblPerPlayerDen[strPlayer]);
				end
			end
		end
	end

	-- Iterate through all the changes and build up fractional attendance values
	for tmChangeNum, tblPersistChange in pairs(tblPersistGuild.tblChanges) do
		local iMassEPAward = EPGPAttendance:IGetMassEPAward(tblPersistChange);
		--EPGPAttendance:PrintMessage("Analyzing change " .. tmChangeNum .. " (MassEP=" .. iMassEPAward .. ")"); -- DEBUG

		-- Ignore changes that aren't mass EP awards
		if (iMassEPAward > 0) then

			local iRaidDayOfWeek, tmRaidDay = EPGPAttendance:IGetRaidDayOfWeek(tmChangeNum);
			local tblWeights = {1, 1, 1, 1};

			for iCustomCol = 1, c_iCustomColumns do
				-- Compute weights
				if (tblColumnOptions[iCustomCol]["fIgnoreDoW" .. iRaidDayOfWeek]) then
					-- If we're ignoring this day of the week, then our weight is 0
					tblWeights[iCustomCol] = 0;
				else
					-- Weight is the EP award or 1 (depending on the user's choice)
					if (tblColumnOptions[iCustomCol].fWeightByEP) then
						tblWeights[iCustomCol] = iMassEPAward;
					else
						tblWeights[iCustomCol] = 1;
					end

					-- Normalize the weight for each day (if the user prefers)
					if (tblColumnOptions[iCustomCol].fNormalizeWeightByDay) then
						tblWeights[iCustomCol] = tblWeights[iCustomCol] / tblWeightsPerDay[iCustomCol][tmRaidDay];
					end
				end

				-- Increment static denominators
				if (not tblColumnOptions[iCustomCol].fLifetime and tmChangeNum >= tblNonLifetimeStart[iCustomCol]) then
					tblNonLifetimeDen[iCustomCol] = tblNonLifetimeDen[iCustomCol] + tblWeights[iCustomCol];
				end
			end

			-- Increment lifetime denominators
			if (fHasLifetimeCol) then
				for strPlayer, iLifetimeStart in pairs(tblPersistGuild.tblLifetimeStart) do
					if (tmChangeNum >= iLifetimeStart and tblPerPlayerDen[strPlayer]) then
						for iCustomCol = 1, c_iCustomColumns do
							if (tblColumnOptions[iCustomCol].fLifetime and tmChangeNum >= iLifetimeStart) then
								tblPerPlayerDen[strPlayer][iCustomCol] = tblPerPlayerDen[strPlayer][iCustomCol] + tblWeights[iCustomCol];
							end
						end
					end
				end
			end

			-- Increment numerators
			for strPlayer, iEPDelta in pairs(tblPersistChange) do
				-- Ignore players that did not receive the mass EP award
				if (iEPDelta >= iMassEPAward and tblPerPlayerNum[strPlayer]) then
					for iCustomCol = 1, c_iCustomColumns do
						if (tblColumnOptions[iCustomCol].fLifetime and tmChangeNum >= tblPersistGuild.tblLifetimeStart[strPlayer]
								or not tblColumnOptions[iCustomCol].fLifetime and tmChangeNum >= tblNonLifetimeStart[iCustomCol]) then
							tblPerPlayerNum[strPlayer][iCustomCol] = tblPerPlayerNum[strPlayer][iCustomCol] + tblWeights[iCustomCol];
						end
					end
				end
			end

		end
	end

	-- Build a displayable table with percentage values
	local tblData = {};
	local iRows = 0;
	local iBaseGP = 100;

	if (EPGP) then
		iBaseGP = EPGP:GetBaseGP();
	else
		EPGPAttendance:PrintMessage("Warning: EPGP (dkp reloaded) not installed, assuming a base GP of " .. iBaseGP);
	end

	for strPlayer,tblNum in pairs(tblPerPlayerNum) do

		local strNote = EPGPAttendance.LibGuildStorage:GetNote(strPlayer);
		local fIsRaider = false;
		local iEP = 0;
		local iGP = 0;
		local dPR = 0.0;

		if (strNote) then
			local strEP, strGP = string.match(strNote, "^(%d+),(%d+)$");
			if (strEP and strGP) then
				iEP = tonumber(strEP);
				iGP = tonumber(strGP) + iBaseGP;
				dPR = floor(iEP * 100 / iGP) / 100;
				fIsRaider = true;
			end
		end

		-- Filter out people with 0 EP
		if (fIsRaider or EPGPAttendance.db.profile.fShowFormerRaiders) then

			local colorName = c_colorNotInGuild;
			local strClass = EPGPAttendance.LibGuildStorage:GetClass(strPlayer);
			if (fIsRaider and strClass) then
				colorName = RAID_CLASS_COLORS[strClass];
			end

			iRows = iRows + 1;
			tblData[iRows] =
			{
				cols =
				{
					[c_iMainColPlayer] = { value = strPlayer, color = colorName },
					[c_iMainColEP] = { value = iEP },
					[c_iMainColGP] = { value = iGP },
					[c_iMainColPR] = { value = string.format("%.2f", dPR), sortValue = dPR },
					-- Custom columns added later
				},
			};

			-- Add custom columns
			for iCustomCol = 1, c_iCustomColumns do
				local iDen;
				if (tblColumnOptions[iCustomCol].fLifetime) then
					iDen = tblPerPlayerDen[strPlayer][iCustomCol];
				else
					iDen = tblNonLifetimeDen[iCustomCol];
				end
				tblData[iRows].cols[c_iMainCol1 + iCustomCol - 1] =
						EPGPAttendance:TblCreateColoredPercentCell(tblNum[iCustomCol], iDen);
			end
		end
	end

	return tblData;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblComputeCharTableData
--
--		Computes and returns the contents of the character table.
--
function EPGPAttendance:TblComputeCharTableData(strPlayer)

	-- Validate argument
	if (not strPlayer) then
		return {};
	end

	-- Get the guild table
	local tblPersistGuild = EPGPAttendance:TblGetPersistedGuildTable();
	if (not tblPersistGuild) then
		return {};
	end

	-- Ensure lifetime start table
	EPGPAttendance:EnsureTblLifetimeStart(tblPersistGuild);
	local iLifetimeStart = tblPersistGuild.tblLifetimeStart[strPlayer];
	if (not iLifetimeStart) then
		return {};
	end

	local tblData = {};
	local iRows = 0;

	-- Iterate through all the changes and build up fractional attendance values
	for tmChangeNum, tblPersistChange in pairs(tblPersistGuild.tblChanges) do

		-- Skip over changes that are too old
		if (tmChangeNum >= iLifetimeStart) then

			local iMassEPAward = EPGPAttendance:IGetMassEPAward(tblPersistChange);
			local iEPDelta = tblPersistChange[strPlayer] or 0;

			if (iMassEPAward > 0) then

				local strChange;
				local colorChange;

				if (iEPDelta >= iMassEPAward) then
					strChange = "Был в рейде";
					colorChange = c_colorAttendedRaid;
				else
					strChange = "Отсутствовал";
					colorChange = c_colorMissedRaid;
				end

				iRows = iRows + 1;
				tblData[iRows] =
				{
					cols =
					{
						[c_iCharColDate] = EPGPAttendance:TblCreateColoredDateTimeCell(tmChangeNum),
						[c_iCharColEP] = { value = iMassEPAward, color = colorChange },
						[c_iCharColChange] = { value = strChange, color = colorChange },
					},
				};

			end

			-- If we're showing adjustments, output a row (possibly in addition to the mass award
			-- outputted earlier)
			if (EPGPAttendance.db.profile.fShowEPAdjustments and iEPDelta ~= 0 and iEPDelta ~= iMassEPAward) then

				local iEPAdjustment;

				if (iMassEPAward == 0) then
					-- Normal adjustment
					iEPAdjustment = iEPDelta;
				elseif (iEPDelta >= iMassEPAward) then
					-- Extra EP on top of an attended raid
					iEPAdjustment = iEPDelta - iMassEPAward;
				else
					-- Missed raid, but EP changed somehow
					iEPAdjustment = iEPDelta;
				end

				iRows = iRows + 1;
				tblData[iRows] =
				{
					cols =
					{
						[c_iCharColDate] = EPGPAttendance:TblCreateColoredDateTimeCell(tmChangeNum),
						[c_iCharColEP] = { value = iEPAdjustment, color = c_colorEPAdjustment },
						[c_iCharColChange] = { value = "Изменение/Срез", color = c_colorEPAdjustment },
					},
				};

			end
		end

	end

	return tblData;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblComputeHistoryTableData
--
--		Computes and returns the contents of the history table.
--
function EPGPAttendance:TblComputeHistoryTableData()

	-- Get the guild table
	local tblPersistGuild = EPGPAttendance:TblGetPersistedGuildTable();
	if (not tblPersistGuild) then
		return {};
	end

	local tblData = {};
	local iRows = 0;

	-- Iterate through all the changes and build up fractional attendance values
	for tmChangeNum, tblPersistChange in pairs(tblPersistGuild.tblChanges) do

		local iMassEPAward = EPGPAttendance:IGetMassEPAward(tblPersistChange);
		local colorChange;
		local strChange;

		if (iMassEPAward > 0) then

			local iAttendedCount = 0;
			local iAdjustmentCount = 0;

			-- Count the number of attendees and the number of adjustments (not mutually exclusive)
			for strPlayer, iEPDelta in pairs(tblPersistChange) do
				if (not EPGPAttendance:FIsSpecialPlayerName(strPlayer)) then
					if (iEPDelta ~= iMassEPAward) then
						iAdjustmentCount = iAdjustmentCount + 1;
					end
					if (iEPDelta >= iMassEPAward) then
						iAttendedCount = iAttendedCount + 1;
					end
				end
			end

			-- Determine color and text
			if (iAdjustmentCount > 0) then
				strChange = string.format("Массовое EP: %d EP, Начислений %d, Изменений %d",
								iMassEPAward, iAttendedCount, iAdjustmentCount);
				colorChange = c_colorMassEPWithAdj;
			else
				strChange = string.format("Массовое EP: %d EP, Начислений %d", iMassEPAward, iAttendedCount);
			end

		else

			local fNoPositiveDeltas = true;
			local iNegativeCount = 0;
			local iAdjustmentCount = 0;
			local strLastPlayer;

			-- Count the number of adjustments (and see if this looks like a decay)
			for strPlayer, iEPDelta in pairs(tblPersistChange) do
				if (not EPGPAttendance:FIsSpecialPlayerName(strPlayer)) then
					if (iEPDelta > 0) then
						fNoPositiveDeltas = false;
					elseif (iEPDelta < 0) then
						iNegativeCount = iNegativeCount + 1;
					end
					iAdjustmentCount = iAdjustmentCount + 1;
					strLastPlayer = strPlayer;
				end
			end

			-- Determine color and text
			if (fNoPositiveDeltas and iNegativeCount >= EPGPAttendance.db.profile.iDecayQuorum) then
				strChange = string.format("Срез EP: Изменений %d", iAdjustmentCount);
				colorChange = c_colorDecayEP;
			elseif (iAdjustmentCount == 1) then
				strChange = string.format("Изменение EP: %s (%d EP)", strLastPlayer, tblPersistChange[strLastPlayer]);
				colorChange = c_colorEPAdjustment;
			else
				strChange = string.format("Изменение EP: Изменений %d", iAdjustmentCount);
				colorChange = c_colorEPAdjustment;
			end

		end

		-- Insert the row
		iRows = iRows + 1;
		tblData[iRows] =
		{
			cols =
			{
				[c_iHistoryColDate] = EPGPAttendance:TblCreateColoredDateTimeCell(tmChangeNum),
				[c_iHistoryColChange] = { value = strChange, color = colorChange },
			},
		};

	end

	return tblData;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:TblComputeChangeTableData
--
--		Computes and returns the contents of the change table.
--
function EPGPAttendance:TblComputeChangeTableData(tmChangeNum)

	-- Validate argument
	if (not tmChangeNum) then
		return {};
	end

	-- Get the guild table
	local tblPersistGuild = EPGPAttendance:TblGetPersistedGuildTable();
	if (not tblPersistGuild) then
		return {};
	end

	-- Get the change table
	local tblPersistChange = tblPersistGuild.tblChanges[tmChangeNum];
	if (not tblPersistChange) then
		return {};
	end

	local iMassEPAward = EPGPAttendance:IGetMassEPAward(tblPersistChange);

	local tblData = {};
	local iRows = 0;

	-- Iterate through all the changes and build up fractional attendance values
	for strPlayer, iEPDelta in pairs(tblPersistChange) do

		if (not EPGPAttendance:FIsSpecialPlayerName(strPlayer)) then
			local colorName = c_colorNotInGuild;
			local colorEP = nil;
			local strClass = EPGPAttendance.LibGuildStorage:GetClass(strPlayer);

			if (strClass) then
				colorName = RAID_CLASS_COLORS[strClass];
			end

			if (iMassEPAward == 0) then
				colorEP = c_colorEPAdjustment;
			elseif (iEPDelta > iMassEPAward) then
				colorEP = c_colorExtraEP;
			elseif (iEPDelta < iMassEPAward) then
				colorEP = c_colorInsufficientEP;
			end

			iRows = iRows + 1;
			tblData[iRows] =
			{
				cols =
				{
					[c_iChangeColPlayer] = { value = strPlayer, color = colorName },
					[c_iChangeColEP] = { value = iEPDelta, color = colorEP },
				},
			};
		end

	end

	return tblData;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:ShowFrameAndCurrentPage
--
--		Creates the frame and UI table, if necessary.
--
function EPGPAttendance:ShowFrameAndCurrentPage()

	local LibScrollingTable = LibStub("ScrollingTable");
	local c_iTitleHeight = 18;
	local c_iButtonWidth = 40;
	local c_iButtonSpacing = 4;
	local c_iTableLines = 24;
	local c_iTableLineHeight = 15;
	local c_iTableXOffset = (c_iButtonWidth + c_iButtonSpacing) / 2;
	local c_iTableYOffset = -16;

	-- Hook into the global CloseSpecialWindow function (so the escape key works)
	if (not EPGPAttendance.fnOriginalCloseSpecialWindows) then
		EPGPAttendance.fnOriginalCloseSpecialWindows = CloseSpecialWindows;
		CloseSpecialWindows = EPGPAttendance_CloseSpecialWindows;
	end

	-- Create the frame
	if (not EPGPAttendance.frmTitleBar) then
		EPGPAttendance.frmTitleBar = CreateFrame("Frame", "EPGPAttendanceFrameTB", UIParent);
		EPGPAttendance.frmTitleBar:SetFrameStrata("DIALOG");

		if (EPGPAttendance.db.profile.tblFrameLocation) then
			EPGPAttendance.frmTitleBar:SetPoint(
				EPGPAttendance.db.profile.tblFrameLocation.strAnchor,
				UIParent,
				EPGPAttendance.db.profile.tblFrameLocation.strParentAnchor,
				EPGPAttendance.db.profile.tblFrameLocation.iOffsetX,
				EPGPAttendance.db.profile.tblFrameLocation.iOffsetY
				);		
		else
			EPGPAttendance.frmTitleBar:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		end

		EPGPAttendance.frmTitleBar:SetHeight(c_iTitleHeight);
		EPGPAttendance.frmTitleBar:SetWidth(480 - 3 * c_iButtonWidth - 3 * c_iButtonSpacing);
		EPGPAttendance.frmTitleBar:SetMovable(true);
		EPGPAttendance.frmTitleBar:SetToplevel(true);
		EPGPAttendance.frmTitleBar:EnableMouse(true);
		--EPGPAttendance.frmTitleBar:EnableKeyboard(true);
		EPGPAttendance.frmTitleBar:SetScript("OnMouseDown", function() EPGPAttendance.frmTitleBar:StartMoving(); end);
		EPGPAttendance.frmTitleBar:SetScript("OnMouseUp", function() EPGPAttendance.frmTitleBar:StopMovingOrSizing(); EPGPAttendance:PersistFrameLocation(); end);
		--EPGPAttendance.frmTitleBar:SetScript("OnKeyDown", function(self, strKeybind) if ("ESCAPE" == strKeybind) then EPGPAttendance:PrintMessage(strKeybind); end end);

		EPGPAttendance.frmTitleBar:SetBackdrop(c_tblSemiTransparentBackdrop);
		EPGPAttendance.frmTitleBar:SetBackdropColor(0, 0, 0, 0.9);
		EPGPAttendance.frmTitleBar:SetBackdropBorderColor(1, 1, 1, 1);
	end

	-- Create the title text
	if (not EPGPAttendance.frmTitleBarText) then
		EPGPAttendance.frmTitleBarText = EPGPAttendance.frmTitleBar:CreateFontString(nil, nil, "GameFontNormal");
		EPGPAttendance.frmTitleBarText:SetPoint("LEFT", EPGPAttendance.frmTitleBar, "LEFT", 3, 0);
		EPGPAttendance.frmTitleBarText:SetJustifyH("LEFT");
		EPGPAttendance.frmTitleBarText:SetTextColor(1, 1, 1, 1);
		EPGPAttendance.frmTitleBarText:SetText("Посещение");
	end

	-- Create the History button
	if (not EPGPAttendance.frmHistoryButton) then
		EPGPAttendance.frmHistoryButton = CreateFrame("Button", "EPGPAttendanceFrameHB", EPGPAttendance.frmTitleBar);

		EPGPAttendance.frmHistoryButton:SetPoint("RIGHT", EPGPAttendance.frmTitleBar, "LEFT", -c_iButtonSpacing, 0);
		EPGPAttendance.frmHistoryButton:SetHeight(c_iTitleHeight);
		EPGPAttendance.frmHistoryButton:SetWidth(c_iButtonWidth);
		EPGPAttendance.frmHistoryButton:SetScript("OnClick", function() EPGPAttendance:NavigatePage(c_iPageHistory); end);
		EPGPAttendance.frmHistoryButton:SetScript("OnEnter", function(self) self:SetBackdropColor(0.8, 0.8, 0.5, 0.7); end);
		EPGPAttendance.frmHistoryButton:SetScript("OnLeave", function(self) self:SetBackdropColor(0.3, 0.3, 0.0, 0.7); end);
		EPGPAttendance.frmHistoryButton:RegisterForClicks("AnyUp");

		EPGPAttendance.frmHistoryButton:SetBackdrop(c_tblSemiTransparentBackdrop);
		EPGPAttendance.frmHistoryButton:SetBackdropColor(0.3, 0.3, 0.0, 0.7);
		EPGPAttendance.frmHistoryButton:SetBackdropBorderColor(1, 1, 1, 1);
	end

	-- Create the History button text
	if (not EPGPAttendance.frmHistoryButtonText) then
		EPGPAttendance.frmHistoryButtonText = EPGPAttendance.frmHistoryButton:CreateFontString(nil, nil, "GameFontNormalSmall");
		EPGPAttendance.frmHistoryButtonText:SetPoint("CENTER", EPGPAttendance.frmHistoryButton, "CENTER", 0, 0);
		EPGPAttendance.frmHistoryButtonText:SetJustifyH("CENTER");
		EPGPAttendance.frmHistoryButtonText:SetTextColor(1, 1, 1, 1);
		EPGPAttendance.frmHistoryButtonText:SetText("H");
	end

	-- Create the Back button
	if (not EPGPAttendance.frmBackButton) then
		EPGPAttendance.frmBackButton = CreateFrame("Button", "EPGPAttendanceFrameBB", EPGPAttendance.frmTitleBar);

		EPGPAttendance.frmBackButton:SetPoint("RIGHT", EPGPAttendance.frmTitleBar, "LEFT", -c_iButtonSpacing, 0);
		EPGPAttendance.frmBackButton:SetHeight(c_iTitleHeight);
		EPGPAttendance.frmBackButton:SetWidth(c_iButtonWidth);
		EPGPAttendance.frmBackButton:SetScript("OnClick", function() EPGPAttendance:NavigateBack(); end);
		EPGPAttendance.frmBackButton:SetScript("OnEnter", function(self) self:SetBackdropColor(0.5, 1.0, 0.5, 0.7); end);
		EPGPAttendance.frmBackButton:SetScript("OnLeave", function(self) self:SetBackdropColor(0.0, 0.5, 0.0, 0.7); end);
		EPGPAttendance.frmBackButton:RegisterForClicks("AnyUp");

		EPGPAttendance.frmBackButton:SetBackdrop(c_tblSemiTransparentBackdrop);
		EPGPAttendance.frmBackButton:SetBackdropColor(0.0, 0.5, 0.0, 0.7);
		EPGPAttendance.frmBackButton:SetBackdropBorderColor(1, 1, 1, 1);
	end

	-- Create the Back button text
	if (not EPGPAttendance.frmBackButtonText) then
		EPGPAttendance.frmBackButtonText = EPGPAttendance.frmBackButton:CreateFontString(nil, nil, "GameFontNormalSmall");
		EPGPAttendance.frmBackButtonText:SetPoint("CENTER", EPGPAttendance.frmBackButton, "CENTER", 0, 0);
		EPGPAttendance.frmBackButtonText:SetJustifyH("CENTER");
		EPGPAttendance.frmBackButtonText:SetTextColor(1, 1, 1, 1);
		EPGPAttendance.frmBackButtonText:SetText("<");
	end

	-- Create the Config button
	if (not EPGPAttendance.frmConfigButton) then
		EPGPAttendance.frmConfigButton = CreateFrame("Button", "EPGPAttendanceFrameCB", EPGPAttendance.frmTitleBar);

		EPGPAttendance.frmConfigButton:SetPoint("LEFT", EPGPAttendance.frmTitleBar, "RIGHT", c_iButtonSpacing, 0);
		EPGPAttendance.frmConfigButton:SetHeight(c_iTitleHeight);
		EPGPAttendance.frmConfigButton:SetWidth(c_iButtonWidth);
		EPGPAttendance.frmConfigButton:SetScript("OnClick", function() LibStub("AceConfigDialog-3.0"):Open("EPGPAttendance"); end);
		EPGPAttendance.frmConfigButton:SetScript("OnEnter", function(self) self:SetBackdropColor(0.5, 0.9, 1.0, 0.7); end);
		EPGPAttendance.frmConfigButton:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0.4, 0.5, 0.7); end);
		EPGPAttendance.frmConfigButton:RegisterForClicks("AnyUp");

		EPGPAttendance.frmConfigButton:SetBackdrop(c_tblSemiTransparentBackdrop);
		EPGPAttendance.frmConfigButton:SetBackdropColor(0, 0.4, 0.5, 0.7);
		EPGPAttendance.frmConfigButton:SetBackdropBorderColor(1, 1, 1, 1);
	end

	-- Create the Config button text
	if (not EPGPAttendance.frmConfigButtonText) then
		EPGPAttendance.frmConfigButtonText = EPGPAttendance.frmConfigButton:CreateFontString(nil, nil, "GameFontNormalSmall");
		EPGPAttendance.frmConfigButtonText:SetPoint("CENTER", EPGPAttendance.frmConfigButton, "CENTER", 0, 0);
		EPGPAttendance.frmConfigButtonText:SetJustifyH("CENTER");
		EPGPAttendance.frmConfigButtonText:SetTextColor(1, 1, 1, 1);
		EPGPAttendance.frmConfigButtonText:SetText("C");
	end

	-- Create the Close button
	if (not EPGPAttendance.frmCloseButton) then
		EPGPAttendance.frmCloseButton = CreateFrame("Button", "EPGPAttendanceFrameCLB", EPGPAttendance.frmTitleBar);

		EPGPAttendance.frmCloseButton:SetPoint("LEFT", EPGPAttendance.frmTitleBar, "RIGHT", c_iButtonWidth + 2 * c_iButtonSpacing, 0);
		EPGPAttendance.frmCloseButton:SetHeight(c_iTitleHeight);
		EPGPAttendance.frmCloseButton:SetWidth(c_iButtonWidth);
		EPGPAttendance.frmCloseButton:SetScript("OnClick", function() EPGPAttendance:HideFrame(); end);
		EPGPAttendance.frmCloseButton:SetScript("OnEnter", function(self) self:SetBackdropColor(1.0, 0.5, 0.5, 0.7); end);
		EPGPAttendance.frmCloseButton:SetScript("OnLeave", function(self) self:SetBackdropColor(0.5, 0.0, 0.0, 0.7); end);
		EPGPAttendance.frmCloseButton:RegisterForClicks("AnyUp");

		EPGPAttendance.frmCloseButton:SetBackdrop(c_tblSemiTransparentBackdrop);
		EPGPAttendance.frmCloseButton:SetBackdropColor(0.5, 0.0, 0.0, 0.7);
		EPGPAttendance.frmCloseButton:SetBackdropBorderColor(1, 1, 1, 1);
	end

	-- Create the Close button text
	if (not EPGPAttendance.frmCloseButtonText) then
		EPGPAttendance.frmCloseButtonText = EPGPAttendance.frmCloseButton:CreateFontString(nil, nil, "GameFontNormalSmall");
		EPGPAttendance.frmCloseButtonText:SetPoint("CENTER", EPGPAttendance.frmCloseButton, "CENTER", 0, 0);
		EPGPAttendance.frmCloseButtonText:SetJustifyH("CENTER");
		EPGPAttendance.frmCloseButtonText:SetTextColor(1, 1, 1, 1);
		EPGPAttendance.frmCloseButtonText:SetText("X");
	end

	-- Create the main table
	if (not EPGPAttendance.stMainTable) then
		local tblColumnSet = EPGPAttendance:TblCreateMainTableColumnDefinition();

		EPGPAttendance.stMainTable = LibScrollingTable:CreateST(tblColumnSet, c_iTableLines, c_iTableLineHeight, c_colorHoverBG, EPGPAttendance.frmTitleBar);
		EPGPAttendance.stMainTable.frame:SetPoint("TOP", EPGPAttendance.frmTitleBar, "BOTTOM", c_iTableXOffset, c_iTableYOffset);

		EPGPAttendance.stMainTable:RegisterEvents({ OnClick = EPGPAttendance_TableOnClickDoNavigate });
	end

	-- Create the character table
	if (not EPGPAttendance.stCharTable) then
		local tblColumnSet =
		{
			[c_iCharColDate] = {
				name = "Дата",
				width = 120,
				align = "LEFT",
				color = c_colorDefaultText,
				bgcolor = c_colorDefaultBG,
				defaultsort = "dsc",
				sort = "dsc",
				comparesort = EPGPAttendance_TableCompareRows,
			},
			[c_iCharColEP] = {
				name = "EP",
				width = 50,
				align = "LEFT",
				color = c_colorDefaultText,
				bgcolor = c_colorDefaultBG2,
				defaultsort = "asc",
				comparesort = EPGPAttendance_TableCompareRows,
			},
			[c_iCharColChange] = {
				name = "Изменение",
				width = 280,
				align = "LEFT",
				color = c_colorDefaultText,
				bgcolor = c_colorDefaultBG,
				defaultsort = "asc",
				comparesort = EPGPAttendance_TableCompareRows,
			},
		};
		
		EPGPAttendance.stCharTable = LibScrollingTable:CreateST(tblColumnSet, c_iTableLines, c_iTableLineHeight, c_colorHoverBG, EPGPAttendance.frmTitleBar);
		EPGPAttendance.stCharTable.frame:SetPoint("TOP", EPGPAttendance.frmTitleBar, "BOTTOM", c_iTableXOffset, c_iTableYOffset);

		EPGPAttendance.stCharTable:RegisterEvents({ OnClick = EPGPAttendance_TableOnClickDoNavigate });
	end

	-- Create the change history table
	if (not EPGPAttendance.stHistoryTable) then
		local tblColumnSet =
		{
			[c_iHistoryColDate] = {
				name = "Дата",
				width = 120,
				align = "LEFT",
				color = c_colorDefaultText,
				bgcolor = c_colorDefaultBG2,
				defaultsort = "dsc",
				sort = "dsc",
				comparesort = EPGPAttendance_TableCompareRows,
			},
			[c_iHistoryColChange] = {
				name = "Изменение",
				width = 330,
				align = "LEFT",
				color = c_colorDefaultText,
				bgcolor = c_colorDefaultBG,
				defaultsort = "asc",
				comparesort = EPGPAttendance_TableCompareRows,
			},
		};

		EPGPAttendance.stHistoryTable = LibScrollingTable:CreateST(tblColumnSet, c_iTableLines, c_iTableLineHeight, c_colorHoverBG, EPGPAttendance.frmTitleBar);
		EPGPAttendance.stHistoryTable.frame:SetPoint("TOP", EPGPAttendance.frmTitleBar, "BOTTOM", c_iTableXOffset, c_iTableYOffset);

		EPGPAttendance.stHistoryTable:RegisterEvents({ OnClick = EPGPAttendance_TableOnClickDoNavigate });
	end

	-- Create the change table
	if (not EPGPAttendance.stChangeTable) then
		local tblColumnSet =
		{
			[c_iChangeColPlayer] = {
				name = "Игрок",
				width = 100,
				align = "LEFT",
				color = c_colorDefaultText,
				bgcolor = c_colorDefaultBG2,
				defaultsort = "asc",
				sort = "asc",
				comparesort = EPGPAttendance_TableCompareRows,
			},
			[c_iChangeColEP] = {
				name = "EP",
				width = 350,
				align = "LEFT",
				color = c_colorDefaultText,
				bgcolor = c_colorDefaultBG,
				defaultsort = "dsc",
				comparesort = EPGPAttendance_TableCompareRows,
			},
		};
		
		EPGPAttendance.stChangeTable = LibScrollingTable:CreateST(tblColumnSet, c_iTableLines, c_iTableLineHeight, c_colorHoverBG, EPGPAttendance.frmTitleBar);
		EPGPAttendance.stChangeTable.frame:SetPoint("TOP", EPGPAttendance.frmTitleBar, "BOTTOM", c_iTableXOffset, c_iTableYOffset);

		EPGPAttendance.stChangeTable:RegisterEvents({ OnClick = EPGPAttendance_TableOnClickDoNavigate });
	end

	-- Show the right page
	if (EPGPAttendance.tblNavStack[1].iPage == c_iPageMain) then
		EPGPAttendance.stMainTable.Show(EPGPAttendance.stMainTable);
	else
		EPGPAttendance.stMainTable.Hide(EPGPAttendance.stMainTable);
	end

	if (EPGPAttendance.tblNavStack[1].iPage == c_iPageCharacter) then
		EPGPAttendance.stCharTable.Show(EPGPAttendance.stCharTable);
	else
		EPGPAttendance.stCharTable.Hide(EPGPAttendance.stCharTable);
	end

	if (EPGPAttendance.tblNavStack[1].iPage == c_iPageHistory) then
		EPGPAttendance.stHistoryTable.Show(EPGPAttendance.stHistoryTable);
	else
		EPGPAttendance.stHistoryTable.Hide(EPGPAttendance.stHistoryTable);
	end

	if (EPGPAttendance.tblNavStack[1].iPage == c_iPageChange) then
		EPGPAttendance.stChangeTable.Show(EPGPAttendance.stChangeTable);
	else
		EPGPAttendance.stChangeTable.Hide(EPGPAttendance.stChangeTable);
	end

	-- Show the right Back/History button based on the navigation history
	if (#EPGPAttendance.tblNavStack > 1) then
		EPGPAttendance.frmBackButton:Show();
		EPGPAttendance.frmHistoryButton:Hide();
	else
		EPGPAttendance.frmBackButton:Hide();
		EPGPAttendance.frmHistoryButton:Show();
	end

	EPGPAttendance.frmTitleBar:Show();

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:HideFrame
--
--		Hides the frame, returns true if we actually had a visible frame to hide.
--
function EPGPAttendance:HideFrame()

	if (EPGPAttendance.frmTitleBar and EPGPAttendance.frmTitleBar:IsShown()) then
		EPGPAttendance.frmTitleBar:Hide();
		return true;
	else
		return false;
	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:NavigateBack
--
--		Refreshes the data in the UI table.
--
function EPGPAttendance:NavigateBack()

	if (#EPGPAttendance.tblNavStack > 1) then
		table.remove(EPGPAttendance.tblNavStack, 1);
	end

	EPGPAttendance:NavigatePage();

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:NavigatePage
--
--		Navigates to the specified page.  If no args are specified, refreshes the current page.
--
function EPGPAttendance:NavigatePage(iPage, varPageArg)

	if (not EPGPAttendance.LibGuildStorage:IsCurrentState()) then
		EPGPAttendance:PrintMessage("Warning: EPGP data is still being loaded, so results may be inaccurate.  Please refresh later.");
	end

	-- Did the caller specify a new page to show?
	if (iPage) then
		table.insert(EPGPAttendance.tblNavStack, 1, {iPage = iPage, varPageArg = varPageArg});
	end

	-- Make sure the page is showing
	EPGPAttendance:ShowFrameAndCurrentPage();

	if (EPGPAttendance.tblNavStack[1].iPage == c_iPageMain) then

		local tblData = EPGPAttendance:TblComputeMainTableData();
		EPGPAttendance.stMainTable:SetData(tblData);
		EPGPAttendance.frmTitleBarText:SetText("Посещение");

	elseif (EPGPAttendance.tblNavStack[1].iPage == c_iPageCharacter) then

		local tblData = EPGPAttendance:TblComputeCharTableData(EPGPAttendance.tblNavStack[1].varPageArg);
		EPGPAttendance.stCharTable:SetData(tblData);
		EPGPAttendance.frmTitleBarText:SetText("Посещение - " .. EPGPAttendance.tblNavStack[1].varPageArg);

	elseif (EPGPAttendance.tblNavStack[1].iPage == c_iPageHistory) then

		local tblData = EPGPAttendance:TblComputeHistoryTableData();
		EPGPAttendance.stHistoryTable:SetData(tblData);
		EPGPAttendance.frmTitleBarText:SetText("История");

	elseif (EPGPAttendance.tblNavStack[1].iPage == c_iPageChange) then

		local tblData = EPGPAttendance:TblComputeChangeTableData(EPGPAttendance.tblNavStack[1].varPageArg);
		EPGPAttendance.stChangeTable:SetData(tblData);
		EPGPAttendance.frmTitleBarText:SetText("Посещение - " .. date("!%a %m/%d %I:%M %p", EPGPAttendance.tblNavStack[1].varPageArg));

	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:SetOptionAndInvalidatePage
--
--		Sets the given option and invalidates the given page.
--
function EPGPAttendance:SetOptionAndInvalidatePage(tblOptionInfo, varValue, iPage)

	EPGPAttendance.db.profile[ tblOptionInfo[#tblOptionInfo] ] = varValue;

	EPGPAttendance:InvalidatePage(iPage);

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:OnDelayedInvalidatePage
--
--		Event handler for the InvalidatePage() timer.
--
function EPGPAttendance:OnDelayedInvalidatePage()

	EPGPAttendance:InvalidatePage(EPGPAttendance.iDelayedInvalidatePage, true);
	EPGPAttendance.iDelayedInvalidatePage = nil;

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:InvalidatePage
--
--		If currently displaying the given page, reloads the data.
--
function EPGPAttendance:InvalidatePage(iPage, fNoDelay)

	-- nil means any page
	if (not iPage) then
		iPage = c_iPage_ANY;
	end

	if (fNoDelay) then
		-- Invalidate now
		if ((iPage == c_iPage_ANY or EPGPAttendance.tblNavStack[1].iPage == iPage)
				and EPGPAttendance.frmTitleBar
				and EPGPAttendance.frmTitleBar:IsShown()) then
			EPGPAttendance:NavigatePage();
		end
	else
		-- Invalidate later
		if (EPGPAttendance.iDelayedInvalidatePage) then
			-- Invalidate already scheduled.  Merge EPGPAttendance.iDelayedInvalidatePage with iPage.
			if (iPage ~= EPGPAttendance.iDelayedInvalidatePage) then
				EPGPAttendance.iDelayedInvalidatePage = c_iPage_ANY;
			end
		else
			-- Schedule an invalidate in 1 second
			EPGPAttendance.iDelayedInvalidatePage = iPage;
			EPGPAttendance:ScheduleTimer("OnDelayedInvalidatePage", 1);
		end
	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:ResetFrameLocation
--
--		Resets the frame location (and persists it).
--
function EPGPAttendance:ResetFrameLocation()

	EPGPAttendance.db.profile.tblFrameLocation = nil;

	if (EPGPAttendance.frmTitleBar) then
		EPGPAttendance.frmTitleBar:ClearAllPoints();
		EPGPAttendance.frmTitleBar:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:PersistFrameLocation
--
--		Prints a message, only if the options permit it.
--
function EPGPAttendance:PersistFrameLocation()

	if (EPGPAttendance.frmTitleBar) then
		local strAnchor, _, strParentAnchor, iOffsetX, iOffsetY = EPGPAttendance.frmTitleBar:GetPoint();

		EPGPAttendance.db.profile.tblFrameLocation =
			{
			strAnchor = strAnchor,
			strParentAnchor = strParentAnchor,
			iOffsetX = iOffsetX,
			iOffsetY = iOffsetY,
			};
	end

end

---------------------------------------------------------------------------------------------------
--	EPGPAttendance:CheckActiveState
--
--		Activates/deactivates the mod based on zone and enabled state
--
function EPGPAttendance:ChatCommand(strInput)

	if (not strInput) then
		strInput = "";
	else
		strInput = strInput:trim();
	end

	if ("recenter" == strInput) then
	
		EPGPAttendance:ResetFrameLocation();

	elseif ("debug" == strInput) then

		local tblData = EPGPAttendance:TblComputeMainTableData();

		for iRow, tblRow in ipairs(tblData) do
			EPGPAttendance:PrintMessage(tblRow.cols[c_iMainColPlayer].value .. " => "
					.. tblRow.cols[c_iMainCol1].value);
		end

	else

		local strOffset = string.match(strInput, "^dbgoffset (%-?%d+)$");

		if (strOffset) then
			local iOffset = tonumber(strOffset);
			EPGPAttendance:PrintMessage("Adjusting all times by " .. iOffset .. " hours...");

			local tblPersistGuild = EPGPAttendance:TblGetPersistedGuildTable();
			local tblNewChanges = {};
			for tmChangeNum, tblPersistChange in pairs(tblPersistGuild.tblChanges) do
				tblPersistGuild.tblChanges[tmChangeNum][c_strMassEPAward] = nil;
				tblNewChanges[tmChangeNum + iOffset * c_tmUnitsPerHour] = tblPersistGuild.tblChanges[tmChangeNum];
			end

			tblPersistGuild.tblChanges = tblNewChanges;
			tblPersistGuild.tblLifetimeStart = nil;
		end

		EPGPAttendance:NavigatePage();

	end

end

