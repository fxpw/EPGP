--[[
]]

local LootMaster    = LibStub("AceAddon-3.0"):GetAddon("EPGPLootMaster")

local AceGUI = LibStub("AceGUI-3.0")

local LOOTBUTTON_MAXNUM = 10
local LOOTBUTTON_HEIGHT = 32
local LOOTBUTTON_PADDING = 6

-- Column for the scrollingTable
local gearBgColor   = {["r"] = 0.15, ["g"] = 0.15, ["b"] = 0.15, ["a"] = 1.0 }
local epgpColor     = {["r"] = 0.45, ["g"] = 0.45, ["b"] = 0.45, ["a"] = 1.0 }

local sstScrollCols = {
       { ["name"] = "К.",	        	  ["width"] = 20,  ["align"] = "CENTER" },
       { ["name"] = "Кандидат",		  ["width"] = 100, ["align"] = "LEFT" },
       { ["name"] = "Ранг",     		  ["width"] = 100, ["align"] = "LEFT" },
       { ["name"] = "Ответ",		    ["width"] = 210, ["align"] = "LEFT", 	  ["defaultsort"] = "desc", ["sort"] = "desc", ["color"] = {["r"] = 0.25, ["g"] = 1.00, ["b"] = 0.25, ["a"] = 1.0 }, ["sortnext"]=10 }, --,
       { ["name"] = "EP",		          ["width"] = 50,  ["align"] = "RIGHT",   ["color"] = epgpColor},
       { ["name"] = "GP",		          ["width"] = 50,  ["align"] = "RIGHT",   ["color"] = epgpColor},
       { ["name"] = "PR",		          ["width"] = 50,  ["align"] = "RIGHT",   ["defaultsort"] = "asc", ["sort"] = "asc", ["sortfirst"]=10, ["sortnext"]=8, ["ident"]="PR"},
       { ["name"] = "Ролл",		        ["width"] = 35,  ["align"] = "RIGHT",   ["defaultsort"] = "asc", ["sort"] = "asc", ["color"] = epgpColor},

       { ["name"] = "Заметка",		        ["width"] = 30,  ["align"] = "RIGHT"},

       { ["name"] = " ",		          ["width"] = 5,   ["align"] = "LEFT",    ["defaultsort"] = "asc", ["sort"] = "asc", ["sortnext"]=7},   -- Spacer, actually contains a check if someone matches MinEP, used for sorting purposes.

       { ["name"] = "iLvl",		        ["width"] = 60,  ["align"] = "CENTER",  ["bgcolor"] = gearBgColor },
       { ["name"] = "GP",		          ["width"] = 60,  ["align"] = "CENTER",  ["bgcolor"] = gearBgColor },
       { ["name"] = "s1",		          ["width"] = 20,  ["align"] = "CENTER",  ["bgcolor"] = gearBgColor },
       { ["name"] = "s2",		          ["width"] = 20,  ["align"] = "CENTER",  ["bgcolor"] = gearBgColor },
       { ["name"] = " ",		          ["width"] = 5,   ["align"] = "LEFT",    ["bgcolor"] = gearBgColor }
}

function LootMasterML:ShowInfoPopup( ... )
    GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
    for i=1,select("#", ...) do
        if i==1 then
		    GameTooltip:AddLine( tostring(select(i, ...)), 1, 1, 1 )
        else
            GameTooltip:AddLine( tostring(select(i, ...)), nil, nil, nil, true )
        end
	end
	GameTooltip:Show()
    GameTooltip:ClearAllPoints();
    if self.frame:IsShown() then
        GameTooltip:SetPoint("TOPLEFT", self.frame , "TOPRIGHT", 0, 0);
    else
        GameTooltip:SetPoint("TOPLEFT", self.frame.titleFrame , "BOTTOMLEFT", 0, 0);
    end
end

function LootMasterML:HideInfoPopup()
	GameTooltip:Hide()
end

function LootMasterML:GetFrame()

    if self.frame then
        return self.frame;
    end

    local mainframe = CreateFrame("Frame","LootMasterMLMainFrame",UIParent)
    mainframe:SetPoint("CENTER",UIParent,"CENTER",0,0)
    mainframe:Hide();
    mainframe:SetScale(LootMaster.db.profile.mainUIScale or 1)
    mainframe:SetMovable(true)
	mainframe:SetFrameStrata("DIALOG")
    self.mainframe = mainframe;


    local frame = CreateFrame("Frame","LootMasterMLFrame",mainframe)
    --#region Setup main masterlooter frame
    frame:Show();
    frame:SetPoint("TOPLEFT",mainframe,"TOPLEFT",0,0)
    frame:SetPoint("BOTTOMRIGHT",mainframe,"BOTTOMRIGHT",0,0)
	frame:SetWidth(700)
	frame:SetHeight(415)
	--frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
	frame:EnableMouse()
    frame:SetMovable(true)
	--frame:SetResizable()

    --frame:SetToplevel(true)
    frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 64, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
    frame:SetBackdropColor(1,0,0,1)

    local extralootframe = CreateFrame("Frame","LootMasterMLFrameExtraLoot",frame)
    extralootframe:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 64, edgeSize = 8,
		insets = { left = 2, right = 1, top = 2, bottom = 2 }
	})
    extralootframe:SetBackdropBorderColor(1,1,1,0.5)
    extralootframe:SetBackdropColor(1,0,0,1)
    extralootframe:Show();
    extralootframe:SetFrameStrata("HIGH")
    extralootframe:SetPoint("TOPRIGHT",frame,"TOPLEFT",4,-10)
	extralootframe:SetWidth(LOOTBUTTON_HEIGHT + 17 )
	--extralootframe:SetPoint("BOTTOM",frame,"BOTTOM",0,10)
    frame.extralootframe = extralootframe;
	--frame:SetResizable()

    --frame:SetScript("OnMouseDown", function() mainframe:StartMoving() end)
	--frame:SetScript("OnMouseUp", function() mainframe:StopMovingOrSizing() end)
	--frame:SetScript("OnHide",frameOnClose)
    --#endregion

    local titleFrame = CreateFrame("Frame", nil, mainframe)
    --#region Setup main frame title
    titleFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 64, edgeSize = 8,
		insets = { left = 2, right = 1, top = 2, bottom = 2 }
	})
    titleFrame:SetBackdropColor(0,0,0,1)
    titleFrame:SetHeight(22)
    titleFrame:EnableMouse()
    titleFrame:EnableMouseWheel(true)
    titleFrame:SetPoint("LEFT",mainframe,"TOPLEFT",20,0)
    titleFrame:SetPoint("RIGHT",mainframe,"TOPRIGHT",-20,0)
    titleFrame:SetToplevel(true)

    titleFrame:SetScript("OnMouseDown", function() mainframe:StartMoving() end)
    titleFrame:SetScript("OnMouseWheel", function(s, delta)
		self:SetUIScale( max(min(mainframe:GetScale(0.8) + delta/15,2.0),0.5) );
	end)
    titleFrame:SetScript("OnEnter", function() self:ShowInfoPopup("EPGPLootmaster", "Кликните и двигайте чтобы передвинуть окошко.", "Двойнойклик что бы свернуть/развернуть это окно.") end)
    titleFrame:SetScript("OnLeave", self.HideInfoPopup)
	titleFrame:SetScript("OnMouseUp", function()
        mainframe:StopMovingOrSizing()
        if mainframe.lastClick and GetTime()-mainframe.lastClick<=0.5 then
            if frame:IsShown() then
                frame:Hide();
                titleFrame:ClearAllPoints()
                titleFrame:SetPoint("CENTER",mainframe,"TOP",0,0)
                titleFrame:SetWidth( titleFrame.titletext:GetWidth() + 20 );
                self:HideInfoPopup()
            else
                frame:Show()
                titleFrame:ClearAllPoints()
                titleFrame:SetPoint("LEFT",mainframe,"TOPLEFT",20,0)
                titleFrame:SetPoint("RIGHT",mainframe,"TOPRIGHT",-20,0)
                self:HideInfoPopup()
            end
            mainframe.lastClick = nil;
        else
            mainframe.lastClick = GetTime();
        end
    end)

    local titletext = titleFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
	titletext:SetPoint("CENTER",titleFrame,"CENTER",0,1)
	titletext:SetText( string.format("EPGPLootMaster %s by Bushmaster <Steel Alliance> - Twisting Nether EU(перевод http://getaddon.com)", self:GetVersionString() ) )
    titleFrame.titletext = titletext
    frame.titleFrame = titleFrame
    --#endregion

    local icon = CreateFrame("Button", "EPGPLM_CURRENTITEMICON", frame, "AutoCastShineTemplate")
    --#region itemicon setup
    icon:EnableMouse()
    icon:SetNormalTexture("Interface/ICONS/INV_Misc_QuestionMark")
    icon:SetScript("OnEnter", function()
        if not frame.currentLoot then return end
        GameTooltip:SetOwner(frame, "ANCHOR_NONE")
        GameTooltip:SetHyperlink( frame.currentLoot.link )
        GameTooltip:ClearAllPoints();
        GameTooltip:SetPoint("TOPLEFT", frame , "TOPRIGHT", 0, -5);
	    GameTooltip:Show()
    end);
    icon:SetScript("OnLeave", function()
	    GameTooltip:Hide()
    end);
    icon:SetScript("OnClick", function()
        if not frame.currentLoot then return end
	    if ( IsModifiedClick() ) then
		    HandleModifiedItemClick(frame.currentLoot.link);
        end
    end);
    icon:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-20)
    icon:SetHeight(48)
    icon:SetWidth(48)
    frame.itemIcon = icon;
    --#endregion

    local lblItem = frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
	lblItem:SetPoint("TOPLEFT",icon,"TOPRIGHT",10,0)
    lblItem:SetVertexColor( 1, 1, 1 );
	lblItem:SetText( "Itemname" )
    frame.lblItem = lblItem;

    local lblInfo = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
	lblInfo:SetPoint("BOTTOMLEFT",lblItem,"BOTTOMRIGHT",5,0)
    lblInfo:SetVertexColor( 0.7, 0.7, 0.7 );
	lblInfo:SetText( "ItemInfo" )
    frame.lblInfo = lblInfo;

    local equipHeaderFrame = CreateFrame("Frame", nil, frame)
    --#region Setup the headerframe and text for the candidate equipment columns.
    equipHeaderFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, tileSize = 64, edgeSize = 8,
		insets = { left = 2, right = 1, top = 2, bottom = 2 }
	})
    equipHeaderFrame:SetBackdropColor(0.2,0.2,0.2,0.6)
    equipHeaderFrame:SetWidth(170)
    equipHeaderFrame:SetHeight(38)

    local titletext = equipHeaderFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    titletext:SetVertexColor( 0.9, 0.9, 0.9 );
	titletext:SetPoint("CENTER",equipHeaderFrame,"CENTER",0,0)
    titletext:SetPoint("TOP",equipHeaderFrame,"TOP",0,-5)
	titletext:SetText( string.format("Текущая вещи кандидата:", self:GetVersionString() ) )
    --#endregion

	local sstScroll = ScrollingTable:CreateST(sstScrollCols, 15, 20, nil, frame);
    --#region Setup the scrollingTable
	sstScroll.frame:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-95)
	--sstScroll.frame:SetPoint("RIGHT",frame,"RIGHT",-30,10)

    equipHeaderFrame:SetPoint("BOTTOMRIGHT",sstScroll.frame,"TOPRIGHT",-4,-5)

	frame:SetMinResize(frame:GetWidth(),130)
	frame:SetMaxResize(frame:GetWidth(), 60*15+85 )

    frame.sstScroll = sstScroll
    --#endregion

    local lblGPOverride = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    --lblGPOverride:SetVertexColor( 0.9, 0.9, 0.9 );
	lblGPOverride:SetPoint("TOPLEFT",lblItem,"BOTTOMLEFT",0,-15)
	lblGPOverride:SetText( "GP value:" );
    frame.lblGPOverride = lblGPOverride

    local lblNoDistribute = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    lblNoDistribute:SetVertexColor( 1, 0, 0 );
	lblNoDistribute:SetPoint("TOPLEFT",lblItem,"BOTTOMLEFT",0,-15)
	lblNoDistribute:SetText( "** MONITOR ONLY **" );
    frame.lblNoDistribute = lblNoDistribute

    local tbGPValueFrame = CreateFrame("Frame", nil, frame)
	tbGPValueFrame:SetHeight(20)
    tbGPValueFrame:SetWidth(50);
    tbGPValueFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 64, edgeSize = 8,
		insets = { left = 2, right = 1, top = 2, bottom = 2 }
	})
    tbGPValueFrame:SetBackdropColor(0.2, 0.2, 0.2, 1)
    tbGPValueFrame:SetBackdropBorderColor(1, 1, 1, 1)
    tbGPValueFrame:SetPoint("BOTTOMLEFT",lblGPOverride,"BOTTOMRIGHT",10,-5)

    local tbGPValue = CreateFrame("EditBox", nil, tbGPValueFrame)
    local iGPManual = 0
    tbGPValue:SetHistoryLines(1)
    tbGPValue:SetMaxLetters(5);
    tbGPValue:SetAutoFocus(false)
    tbGPValue:SetPoint("TOPLEFT",tbGPValueFrame,"TOPLEFT", 6, -1);
    tbGPValue:SetPoint("BOTTOMRIGHT",tbGPValueFrame,"BOTTOMRIGHT", -6, 1);
    tbGPValue:SetFontObject('GameFontHighlightSmall')
    tbGPValue:SetScript("OnEscapePressed", function() tbGPValue:ClearFocus() end)
    tbGPValue:SetScript("OnEnterPressed", function() tbGPValue:ClearFocus() end)
    tbGPValue:SetScript("OnEnter", function() self:ShowInfoPopup("GP значение", "Измените это значение, на значение ГП которое вы хотите дать этой вещи.") end)
    tbGPValue:SetScript("OnLeave", self.HideInfoPopup)

    tbGPValue:SetScript("OnEditFocusGained", function() tbGPValue:HighlightText(); CloseDropDownMenus(); end)
    tbGPValue:SetScript("OnEditFocusLost", function()
        tbGPValue:HighlightText(0,0)
        iGPManual = tonumber(tbGPValue:GetText()) or frame.currentLoot.gpvalue or 0;
        tbGPValue:SetText(iGPManual);
        frame.currentLoot.gpvalue_manual = iGPManual;
    end)
    tbGPValue:SetScript("OnTextChanged", function() CloseDropDownMenus(); end)
    frame.tbGPValue = tbGPValue;
    frame.tbGPValueFrame = tbGPValueFrame;

    local btnAnnounce = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	btnAnnounce:SetScript("OnClick", function()
            if not frame.currentLoot then return message('лут не выбран') end
            self:AnnounceLoot( frame.currentLoot.id )
            btnAnnounce:Hide();
    end)
    btnAnnounce:SetScript("OnEnter", function() self:ShowInfoPopup( "Анонсирование",
                                                                    "Нажмите что бы анонсировать эту вещь всем кандидатам",
                                                                    "Это откроет окно выбора на их клиентах.") end)
    btnAnnounce:SetScript("OnLeave", self.HideInfoPopup)
	btnAnnounce:SetPoint("LEFT",tbGPValueFrame,"RIGHT",10,0)
	btnAnnounce:SetHeight(25)
	btnAnnounce:SetWidth(120)
	btnAnnounce:SetText("Анонсирование лута")
    frame.btnAnnounce = btnAnnounce;

    local btnDiscard = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	btnDiscard:SetScript("OnClick", function()
            if frame.currentLoot then
                self:RemoveLoot( frame.currentLoot.id );
            end
            self:UpdateUI();
    end)
    btnDiscard:SetScript("OnEnter", function() self:ShowInfoPopup( "Отменить лут",
                                                                   "Кликните что бы убрать эту вещь и всех кандидатов с вашего списка.",
                                                                   "Используйте это когда вы не хотите лутить эту вещь.") end)
    btnDiscard:SetScript("OnLeave", self.HideInfoPopup)
	btnDiscard:SetPoint("TOP",btnAnnounce,"TOP",0,0)
    btnDiscard:SetPoint("RIGHT",equipHeaderFrame,"LEFT",-10,0)
	btnDiscard:SetHeight(25)
	btnDiscard:SetWidth(120)
	btnDiscard:SetText("Discard loot")
    frame.btnDiscard = btnDiscard;


    local drop = CreateFrame("Frame", "LootMasterMLCandidateDropDown", frame, "UIDropDownMenuTemplate");
    drop.addon = self;
    --#region Setup the popup menu for the candidate list
    drop:SetID(1)
    UIDropDownMenu_Initialize(drop, function(...) LootMasterML.CandidateDropDownInitialize(LootMasterML, ...) end, "MENU");
    self.CandidateDropDown = drop;
    --#endregion

    self.frame = frame;

    mainframe:SetHeight( frame:GetHeight() )
    self:UpdateWidth()

    return self.frame
end

function LootMasterML:SetUIScale( scale )
    LootMaster.db.profile.mainUIScale = scale;
    if not self.mainframe then return end;
    self.mainframe:SetScale( scale );
end

local extraWidthToggle = true;
function LootMasterML:UpdateWidth()
    if not self.frame or not self.mainframe or not self.frame.sstScroll then return nil end;

    if self.frame.sstScroll.data and #self.frame.sstScroll.data>15 then
        if not extraWidthToggle then
            self.frame:SetWidth( self.frame.sstScroll.frame:GetWidth() + 37 )
            extraWidthToggle = true;
        end
    else
        if extraWidthToggle then
            self.frame:SetWidth( self.frame.sstScroll.frame:GetWidth() + 19 )
            extraWidthToggle = false
        end
    end
    self.mainframe:SetWidth( self.frame:GetWidth() )
end

function LootMasterML:EnterCombat()
    -- Should we hide when entering combat?
    if not LootMaster.db.profile.hideMLOnCombat then return end;

    self.inCombat = true;
    if self:IsShown() then
        self:Hide();
        self.hiddenOnCombat = true;
    end
end

function LootMasterML:LeaveCombat()
    self.inCombat = nil;

    if not self.lootTable then return end;

    -- We left combat, see if theres still loot in the cache.
    for id, loot in pairs(self.lootTable) do
        if loot then
            self.hiddenOnCombat = nil;
            self:ReloadMLTableForLoot( id )
            break;
        end
    end
end

function LootMasterML:IsShown()
    if not self.mainframe then return false end;

    if self.inCombat and self.hiddenOnCombat then return true end

    return self.mainframe:IsShown();
end

function LootMasterML:Show()
    if not self.mainframe then return false end;

    -- Lootmaster ui is shown... do nothing.
    if LootMaster.db.profile.hideOnSelection and LootMaster and LootMaster.IsShown and LootMaster.IsShown(LootMaster) then
        return self.mainframe:Hide()
    end;

    -- Are we in combat?
    if self.inCombat then
        -- Show the ui after combat
        self.mainframe:Hide();
        self.hiddenOnCombat = true;
        return true;
    end

    local ret = self.mainframe:Show();

    if self.frame.currentLoot then
        self:UpdateUI(self.frame.currentLoot.link);
    else
        self:UpdateUI();
    end

    return ret;
end

function LootMasterML:Hide()
    if not self.mainframe then return end;
    return self.mainframe:Hide();
end

--[[
	Reload the scrollingtable if the current viewing item == link
]]
function LootMasterML:ReloadMLTableForLoot( itemName )

    -- LootMaster Loot UI visible? don't update
    if LootMaster.db.profile.hideOnSelection and LootMaster and LootMaster.IsShown and LootMaster.IsShown(LootMaster) then return end;

    local frame = self:GetFrame();
    if not self.mainframe:IsShown() then
        self.mainframe:Show();
    end

    local lootData = self:GetLoot( itemName )
    if not lootData then
        return self:Print( tostring(itemName) .. ' не найдено при обновлении Интерфейса');
    end;

    self:UpdateUI( lootData.link );

end

function LootMasterML:OnStandingsChanged(event)
    if not self.frame then return end

    if self.frame.currentLoot and self.frame.currentLoot.link then
      self:UpdateUI(self.frame.currentLoot.link)
    else
      self:UpdateUI()
    end
end

local numTotalLootButtons = 0;
function LootMasterML:CreateLootButton()

    numTotalLootButtons = numTotalLootButtons+1

    local icon = CreateFrame("Button", "EPGPMLLootButton"..numTotalLootButtons, self.frame, "AutoCastShineTemplate")
    --#region itemicon setup
    icon:EnableMouse()
    icon:SetNormalTexture("Interface/ICONS/INV_Misc_QuestionMark")
    icon:SetScript("OnEnter", function()
        if not icon.data then return end
        GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
        GameTooltip:SetHyperlink( icon.data.link )
	    GameTooltip:Show()
        GameTooltip:SetPoint("TOPLEFT", self.frame , "TOPRIGHT", 0, -5);
    end);
    icon:SetScript("OnLeave", function()
	    GameTooltip:Hide()
    end);
    icon:SetScript("OnClick", function()
        if not icon.data then return end
	    if ( IsModifiedClick() ) then
		    HandleModifiedItemClick(icon.data.link);
        else
            self:DisplayLoot(icon.data.link);
            self:UpdateUI();
        end
    end);
    icon:SetPoint("RIGHT",self.frame,"LEFT",-5,0)
    icon:SetHeight(LOOTBUTTON_HEIGHT)
    icon:SetWidth(LOOTBUTTON_HEIGHT);

    return icon;
end

function LootMasterML:DisplayLoot( item )

    local data = self:GetLoot(item);

    if not data then
        self.frame.currentLoot = nil;
        return
    end;

    local isCurrentItem = false
    if self.frame.currentLoot and data.link==self.frame.currentLoot.link then
        isCurrentItem = true;
    end

    self.frame.currentLoot = data;

    if data.quantity>1 then
        self.frame.lblItem:SetText(format('%sx %s',data.quantity, data.link or 'nil'));
    else
        self.frame.lblItem:SetText(data.link or 'nil');
    end

    local color = ITEM_QUALITY_COLORS[data.quality];
    if not color then
        color = {['r']=1,['g']=1,['b']=1}
    end
    self.frame.lblItem:SetVertexColor(color.r, color.g, color.b);

    local binding = '';
    if data.binding=='use' then
        binding = ', BoU'
    elseif data.binding=='pickup' then
        binding = ', BoP'
    elseif data.binding=='equip' then
        binding = ', BoE'
    end

    local gp2 = '';
    if data.gpvalue2 and data.gpvalue2~='' then
        gp2 = format(' or %s', data.gpvalue2)
    end

    self.frame.lblInfo:SetText(format("ilevel: %s, GP: %s%s%s", data.ilevel or -1, data.gpvalue or -1, gp2, binding or ''));
    self.frame.itemIcon:SetNormalTexture(data.texture);

    self.frame.tbGPValue:SetText( data.gpvalue_manual )

    if not data.announced then
        self.frame.btnAnnounce:Show();
    else
        self.frame.btnAnnounce:Hide();
    end

    if data.mayDistribute then
        self.frame.tbGPValueFrame:Show();
        self.frame.lblGPOverride:Show();
        self.frame.lblNoDistribute:Hide();
    else
        self.frame.tbGPValueFrame:Hide();
        self.frame.lblGPOverride:Hide();
        self.frame.lblNoDistribute:Show();
        self.frame.lblNoDistribute:SetText( format("** Мониторинг ** Только %s может отдать эту вещь **", tostring(data.lootmaster)) )
    end

    --[[if data.hideResponses and data.announced then
      print('hiding responses for', data.link, data.announced)
    else
      print('showing responses for', data.link, data.announced)
    end]]

    if not isCurrentItem then
        self.frame.sstScroll:SetData( data.rowdata )

        -- Restore the default sorting when we're displaying a new item.
        local cols = self.frame.sstScroll.cols
        for i=1, #cols do
          self.frame.sstScroll.cols[i].sort = cols[i].defaultsort
        end
    end
    self.frame.sstScroll:SortData()
    self.frame.sstScroll:DoFilter()
end

function LootMasterML:UpdateUI( updateItemLink )

    if not self:IsShown() then return self:Debug('UpdateUI: not shown') end;

    local visibleLootButtons = 0;
    local totalLoot = 0;

    if LootMaster.db.profile.hideOnSelection and LootMaster and LootMaster.IsShown and LootMaster.IsShown(LootMaster) then return false end;

    -- Are we in combat?
    if self.inCombat then
        -- Show the ui after combat
        self.mainframe:Hide();
        self.hiddenOnCombat = true;
        return true;
    end

    if updateItemLink and self.frame.currentLoot and self.frame.currentLoot.link==updateItemLink then
        -- We got a message to update the current displayed item, refresh the celldata.
        --self.frame.sstScroll:SetData( self.frame.currentLoot.rowdata )
        --self.frame.sstScroll:SortData();
        --self.frame.sstScroll:DoFilter();
    end

    local breakMe = false

    for item, data in pairs(self.lootTable) do repeat
        if item and data then
            -- If monitoring is disabled just don't display items we're not allowed to distribute.
            if not LootMaster.db.profile.monitor and not data.mayDistribute then
                -- also just remove the loot
                self:RemoveLoot(item)
                break
            end

            -- If item quantity<1, just remove the loot.
            if data.quantity<1 then
                self:RemoveLoot(item)
                break
            end

            totalLoot = totalLoot + 1;

            if self.frame.currentLoot and data.link==self.frame.currentLoot.link then
                -- If already displaying, do nothing.
                self:DisplayLoot(item)
                breakMe = true
                break
            elseif not self.frame.currentLoot then
                -- Nothing is onscreen, display the first item
                self:DisplayLoot(item)
                breakMe = true
                break
            end

            if visibleLootButtons>=LOOTBUTTON_MAXNUM then breakMe = true; break end
            visibleLootButtons = visibleLootButtons + 1

            if not self.lootButtons then self.lootButtons = {} end

            local lootButton = self.lootButtons[visibleLootButtons]
            if not lootButton then
                lootButton = self:CreateLootButton()
                self.lootButtons[visibleLootButtons] = lootButton
            end

            lootButton.data = data
            lootButton:SetNormalTexture(data.texture);
            --lootButton:GetNormalTexture():SetVertexColor(1,0,0,0.5)

            local numData = (#(data.rowdata))
            if data.numResponses >= numData and numData>0 then
                AutoCastShine_AutoCastStart(lootButton)
            else
                AutoCastShine_AutoCastStop(lootButton)
            end

            lootButton:Show()

            lootButton:SetPoint( "TOP", self.frame, "TOP", 0, -20 - ((LOOTBUTTON_HEIGHT+LOOTBUTTON_PADDING) * (visibleLootButtons-1)) )
        end
    until true
        if breakMe then
            breakMe = false
        end
    end

    if breakMe then
        self:Print("Break doesn't work as expected, contact Author!")
    end

    if self.lootButtons then
        for i = visibleLootButtons+1, LOOTBUTTON_MAXNUM do
            local lootButton = self.lootButtons[i];
            if lootButton then
                AutoCastShine_AutoCastStop(lootButton)
                lootButton.data = nil;
                lootButton:Hide()
            end
        end
    end;

    if visibleLootButtons>0 then
        self.frame.extralootframe:Show();
        self.frame.extralootframe:SetHeight( (LOOTBUTTON_HEIGHT+LOOTBUTTON_PADDING)*visibleLootButtons + 15 )
    else
        self.frame.extralootframe:Hide();
    end

    if totalLoot==0 and self:IsShown() then
        self.frame.currentLoot = nil;
        self:Hide();
    else
        self:UpdateWidth()
    end

end

function LootMasterML:CandidateDropDownInitialize( frame, level, menuList )

    if not LootMasterML.CandidateDropDown then return end;

    local loot = LootMasterML.GetLoot( LootMasterML, LootMasterML.CandidateDropDown.selectedLink );

    if not loot then
        LootMasterML:Print(LootMasterML, 'немогу показать выпадающее меню лута; лут не в таблице');
        return frame:Hide();
    end

    if self.frame then
        self.frame.tbGPValue:ClearFocus();
    end

    local info = UIDropDownMenu_CreateInfo();

    if UIDROPDOWNMENU_MENU_LEVEL == 1 then

        if LootMasterML and LootMasterML.CandidateDropDown and LootMasterML.CandidateDropDown.selectedCandidate then
            info.notCheckable = 1;
            info.isTitle = true;
            info.disabled = false;
            info.text = LootMasterML.CandidateDropDown.selectedCandidate;
            info.tooltipTitle = nil
            info.tooltipText = nil
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
            info=UIDropDownMenu_CreateInfo();
            info.notCheckable = 1;
        end

        info.notCheckable = 1;
        info.disabled = false;
        info.text = 'Шепот';
        info.tooltipTitle = 'Шепот'
        info.tooltipText = 'Отправить сообщение выбраному кандидату.'
        info.func = function() ChatFrame_SendTell(LootMasterML.CandidateDropDown.selectedCandidate) end;
        UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);

        if loot.mayDistribute then

            info.isTitle = true;
            info.text = '';
            info.disabled = false;
            info.tooltipTitle = nil
            info.tooltipText = nil
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
            info=UIDropDownMenu_CreateInfo();
            info.notCheckable = 1;

            if not loot.manual then

                info.isTitle = false;
                info.disabled = not CanEditOfficerNote();
                info.text = format( 'Отдать лут и прибавить %s GP', loot.gpvalue_manual or 0 );
                info.tooltipTitle = info.text;
                info.tooltipText = format('Пробует отправить лут кандидату и добавить кандидату %s GP', loot.gpvalue_manual or 0);
                info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.GP, loot.gpvalue_manual or 0) end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);

                if loot.gpvalue2 and loot.gpvalue2~=0 then
                    info.isTitle = false;
                    info.disabled = not CanEditOfficerNote();
                    info.text = format( 'Отдать лут и добавить %s GP (100%%)', loot.gpvalue2 or 0 );
                    info.tooltipTitle = info.text;
                    info.tooltipText = format('Пробует отправить лут кандидату и добавить кандидату %s GP', loot.gpvalue2 or 0);
                    info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.GP, loot.gpvalue2 or 0) end;
                    UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
                end

                for i=1, loot.numButtons do
                    local btn = loot.buttons[i]
                    if btn.gpValue then
                      local v = btn.gpValue
                      local p = btn.gpValueIsPercentage
                      local vs = v
                      local gp = tonumber(loot.gpvalue) or 0
                      if p then
                          gp = ceil(gp /100 * v)
                          vs = v .. '% of ' .. (tonumber(loot.gpvalue) or 0)
                      else
                          gp = ceil(v)
                      end

                      info.isTitle = false;
                      info.disabled = not CanEditOfficerNote();
                      info.text = format( 'Отдать лут и добавить %s GP за %s (%s)', gp, btn.text, vs );
                      info.tooltipTitle = info.text;
                      info.tooltipText = format('Пробует отправить лут кандидату и добавить кандидату %s GP за %s', gp, btn.text);
                      info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.GP, gp) end;
                      UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
                    end
                end

                info.isTitle = false;
                info.disabled = false;
                info.text = 'Отдать лут бесплатно';
                info.tooltipTitle = 'Отдать лут бесплатно';
                info.tooltipText = "Пробует отослать лут кандидату и не начислять ему GP.";
                info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.GP, 0 ) end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);

                info.isTitle = false;
                info.disabled = false;
                info.text = 'Отдать лут на распыление';
                info.tooltipTitle = 'Отдать лут на распыление';
                info.tooltipText = 'Отдает лут кандидату на распыление.';
                info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.DISENCHANT ) end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);

                info.isTitle = false;
                info.disabled = false;
                info.text = 'Отдать лут для банка';
                info.tooltipTitle = 'Отдать лут для банка';
                info.tooltipText = 'Отправляет лут кандидату для збережения в банке.';
                info.func = function() LootMasterML.GiveLootToCandidate(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.LOOTTYPE.BANK ) end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);

            else
                info.isTitle = false;
                info.disabled = false;
                info.text = '- Немогу распределить лут -';
                info.tooltipTitle = info.text;
                info.tooltipText = "Вы вручную добавили этот лут в список, вы должны будете отдать лут вручную когда закончите распределение."
                info.func = function() end;
                UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
            end

            info.isTitle = true;
            info.disabled = false;
            info.text = '';
            info.tooltipTitle = nil
            info.tooltipText = nil
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
            info=UIDropDownMenu_CreateInfo();
            info.notCheckable = 1;

            info.isTitle = false;
            info.disabled = false;
            info.text = '(Пере)Анонсировать лут кандидату';
            info.tooltipTitle = '(Пере)Анонсировать лут кандидату';
            info.tooltipText = 'Открывает заново всплывающее окошко у кандидата, это дает возможность проголосовать ему еще раз в случае обрыва или ошибки.';
            info.func = function() LootMasterML.AskCandidateIfNeeded(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate) end;
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);

            info.isTitle = false;
            info.disabled = false;
            info.hasArrow = 1;
            info.text = 'Установить ответ вручную';
            info.tooltipTitle = 'Установить ответ вручную';
            info.tooltipText = 'Позволяет вам вручную устанавливать ответ для данного кандидата';
            info.func = function() end;
            info.value = 'RESPONSE_OVERRIDE';
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);

        end

    elseif UIDROPDOWNMENU_MENU_LEVEL==2 then

        if UIDROPDOWNMENU_MENU_VALUE == 'RESPONSE_OVERRIDE' then

            for i=1, loot.numButtons do
              local btn = loot.buttons[i]
              info.isTitle = false
              info.disabled = false
              info.text = btn.text
              info.tooltipTitle = btn.text
              info.tooltipText = 'Вручную устанавливает ответ данного кандидата на '..btn.text..'. Кандидат получит об этом уведомление шепотом.'
              info.func = function()
                LootMasterML.SetManualResponse(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, btn.response )
                CloseDropDownMenus()
              end
              local ddBtn = UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL)
            end

            info.isTitle = false
            info.disabled = false
            info.text = 'Пропустить'
            info.tooltipTitle = 'Пропустить'
            info.tooltipText = 'Вручную устанавливает ответ данного кандидата на Пропуск лута. Кандидат получит об этом уведомление шепотом.'
            info.func = function()
              LootMasterML.SetManualResponse(LootMasterML, LootMasterML.CandidateDropDown.selectedLink, LootMasterML.CandidateDropDown.selectedCandidate, LootMaster.RESPONSE.PASS )
              CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL)

        end

    end

    --[[info.isTitle = true;
    info.disabled = false;
    info.text = '';
    info.tooltipTitle = nil
    info.tooltipText = nil
    UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
    info=UIDropDownMenu_CreateInfo();
    info.notCheckable = 1;

    info.isTitle = false;
    info.disabled = false;
    info.text = '-DEBUG- Discard loot';
    info.tooltipTitle = nil;
    info.tooltipText = nil;
	info.func = function()
        LootMasterML.RemoveLoot(LootMasterML, LootMasterML.CandidateDropDown.selectedLink);
        LootMasterML.Show(LootMasterML);
    end;
	UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);]]--

end

function LootMasterML:OnCandidateRowRightClick( candidate, link, row )
    self.CandidateDropDown.selectedCandidate = candidate;
    self.CandidateDropDown.selectedLink = link;
    self.CandidateDropDown.selectedRow = row;

    ToggleDropDownMenu(1, nil, self.CandidateDropDown, "cursor", 0, 0);
end

function LootMasterML:SetCellEPGPNumberFormatted( cell, self, candidate, func )
    local value = func(self, candidate)
    if not value or value == -1 then return cell.text:SetText('?'); end;
    value = tonumber(value) or 0;
    if value>99999 then return cell.text:SetText(format("%d", ceil(value))) end
    cell.text:SetText(format("%.5g", value));
end

function LootMasterML:EmptyCellOwnerDraw(cell)
    if not cell then return end;
    cell.text:SetText('')
end

function LootMasterML:SetNoteCellOwnerDraw(cell, itemData)

    cell.text:SetText('');

    if not itemData or itemData=='' then
        cell.EPGPLMModTexture = false
        return cell:SetNormalTexture(nil);
    end

    cell:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")

    -- Center the texture if not done already.
    if not cell.EPGPLMModTexture then
        local t = cell:GetNormalTexture();
        t:ClearAllPoints()
        t:SetPoint("CENTER",t:GetParent(),"CENTER")
        cell.EPGPLMModTexture = true;
    end

end

function LootMasterML:SetGearCellOwnerDraw(cell, itemData)

    if not itemData or itemData=='' then
        cell.text:SetText('');
        cell:SetNormalTexture(nil)
        return;
    end

    local link, gpvalue, ilevel, gpvalue2, itemTexture = strsplit("^", itemData)

    cell.text:SetText('');
    cell:SetNormalTexture(itemTexture)
end

function LootMasterML:SetClassIconCellOwnerDraw(cell, itemData)

    cell.text:SetText('');

    if not itemData or itemData=='' or not CLASS_ICON_TCOORDS[itemData] then
        cell:SetNormalTexture(nil)
        return;
    end

    local coords = CLASS_ICON_TCOORDS[itemData];
    cell:SetNormalTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes");
    cell:GetNormalTexture():SetTexCoord(coords[1],coords[2],coords[3],coords[4]);
end

function LootMasterML:ShowGearInspectPopup( candidate, item )
    local foundGear = self:GetCandidateData(item, candidate, "foundGear") or false;
    if not foundGear then
        self:ShowInfoPopup( candidate, 'Клик что бы получить данную вещь.' );
    end
end

function LootMasterML:ShowNoteCellPopup( candidate, item )
    local itemData = self:GetCandidateData(item, candidate, 'note');
    if not itemData or itemData=='' then return end;

    self:ShowInfoPopup('Заметка добавлена ' .. candidate .. ':', itemData or '');
end

function LootMasterML:ShowGearCellPopup( candidate, item, dataName )

    local itemData = self:GetCandidateData(item, candidate, dataName);
    if not itemData or itemData=='' then return end;

    local link, gpvalue, ilevel, gpvalue2, itemTexture = strsplit("^", itemData);

    GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
    GameTooltip:SetHyperlink( link )
	GameTooltip:Show()
    GameTooltip:SetPoint("TOPLEFT", self.frame , "TOPRIGHT", 0, -5);

end

function LootMasterML:ShowCandidateCellPopup( candidate, item )
    if not candidate then return nil end
    GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
    GameTooltip:SetUnit(candidate)
	GameTooltip:Show()
    GameTooltip:SetPoint("TOPLEFT", self.frame , "TOPRIGHT", 0, -5);
end

function LootMasterML:ShowRollCellPopup( candidate, item )

    local roll = self:GetCandidateData(item, candidate, 'roll');
    if not roll then return end;

    self:ShowInfoPopup( 'Случайное распределение',
                        'Это значение нужно только тогда когда два кандидата имеют одинаковое значение PR.',
                        'Это обычное случайное распределение лута',
                        format('%s получил %s.', candidate, roll)
    );
end

function LootMasterML:SetGearCelliLVL( cell, self, candidate, item )

    local foundGear = self:GetCandidateData(item, candidate, "foundGear") or false;
    if not foundGear then
        cell.text:SetText( '- осмотреть -' );
        return;
    end

    local s = {};
    local itemData = self:GetCandidateData(item, candidate, "currentitem");
    local _, _, ilevel, _, _ = strsplit("^", itemData or '');
    if ilevel then tinsert(s, ilevel) end


    itemData = self:GetCandidateData(item, candidate, "currentitem2");
    _, _, ilevel, _, _ = strsplit("^", itemData or '');
    if ilevel then tinsert(s, ilevel) end

    cell.text:SetText( strjoin(', ', unpack(s)))
end

function LootMasterML:SetGearCellGP( cell, self, candidate, item )
    local s = {};
    local itemData = self:GetCandidateData(item, candidate, "currentitem");
    local _, gpvalue, _, _, _ = strsplit("^", itemData or '');
    if gpvalue then tinsert(s, gpvalue) end

    itemData = self:GetCandidateData(item, candidate, "currentitem2");
    _, gpvalue, _, _, _ = strsplit("^", itemData or '');
    if gpvalue then tinsert(s, gpvalue) end

    cell.text:SetText( strjoin(', ', unpack(s)))
end

function LootMasterML:SetCandidateEPGPCellUserDraw( cell, self, candidate, item )
    if not EPGP or not EPGP.GetEPGP then
        return cell.text:SetText( '?' );
    end
    local ok, ep, gp, main = pcall(EPGP.GetEPGP, EPGP, candidate)
    if not ok then
        return cell.text:SetText( '?' );
    end
    cell.text:SetText( format('%s/%s', tostring(ep), tostring(gp)) );
end

function LootMasterML:GetCandidateCellColor( candidate, item, dataName, defaultColor )
    --local itemData = self:GetCandidateData( item, candidate, "version" );

    local r, g, b = self:GetCandidateResponseColor( candidate, item, nil );
    return {["r"] = r or 1, ["g"] = g or 0, ["b"] = b or 1, ["a"] = 1.0 };
end

function LootMasterML:GetCandidateClassCellColor( candidate, item, dataName, defaultColor )
    local color = RAID_CLASS_COLORS[self:GetCandidateData(item, candidate, "unitclass")];
    if not color then
        -- if class not found display epic color.
        color = {["r"] = 0.63921568627451, ["g"] = 0.2078431372549, ["b"] = 0.93333333333333, ["a"] = 1.0 }
    else
        color.a = 1.0;
    end
    return color;
end

function LootMasterML:GetCandidateResponseColor( candidate, item, response )
    if not response then
        response = tonumber(self:GetCandidateData(item, candidate, "response"));
    end

    local data = self:GetLoot(item)
    if data.hideResponses and data.announced and response > LootMaster.RESPONSE.TIMEOUT then
      return 0.5,0.5,0.5
    end

    if not response or not LootMaster.RESPONSE[response] then
        return 1,0,1
    end

    local override = data.buttonsByResponse[response]
    if override then
      return unpack(override.colorRGB)
    end

    return unpack( LootMaster.RESPONSE[response].COLOR or {1,0,1} )
end

function LootMasterML:SetCandidateResponseCellUserDraw( cell, self, candidate, item )

    local response = tonumber(self:GetCandidateData(item, candidate, "response"));
    local autoPass = self:GetCandidateData(item, candidate, "autoPass");

    local data = self:GetLoot(item)
    if data.hideResponses and data.announced and response > LootMaster.RESPONSE.TIMEOUT then
      return cell.text:SetText('Выбранное (временно спрятано)')
    end

    local text = nil;

    local override = data.buttonsByResponse[response]

    if response == LootMaster.RESPONSE.DISENCHANT then
        if autoPass then
            text = format('Авто пропуск; Зачарователь (%s)',self:GetCandidateData(item, candidate, "enchantingSkill") or 0);
        else
            text = format('Пропуск; Зачарователь (%s)',self:GetCandidateData(item, candidate, "enchantingSkill") or 0);
        end

    elseif override then
        text = override.text

    elseif LootMaster.RESPONSE[response] then
        text = LootMaster.RESPONSE[response].TEXT

    else
        text = 'ответ: ' .. self:GetCandidateData(item, candidate, "response");
    end

    -- Add looted status message when candidate has looted the item.
    if self:GetCandidateData(item, candidate, "looted") then
        return cell.text:SetText( (text or '')  .. '; отдан' )
    end

    return cell.text:SetText( text or '' )
end

function LootMasterML:SetCandidateRollCellUserDraw( cell, self, candidate, item )
    local roll = self:GetCandidateData(item, candidate, "roll");

    if roll then
        cell.text:SetText( floor(roll) );
    else
        cell.text:SetText( '?' );
    end
end

function LootMasterML:HideGearCellPopup( candidate, item, dataName )
    GameTooltip:Hide()
end

function LootMasterML:OnGearInspectClick( candidate, item )
    if self:InspectCandidate( item, candidate ) then
        self.frame.sstScroll:SortData();
        self.frame.sstScroll:DoFilter();
    else
        self:Print( format('%s вышел из игры, не в зоне досягаемости или не в группе, немогу осмотреть.', candidate or 'Unknown') )
    end
end

function LootMasterML:OnGearCellClick( candidate, item, dataName )
    if ( IsModifiedClick() ) then
        local link, _, _, _, _ = strsplit("^", self:GetCandidateData(item, candidate, dataName) or '');
		HandleModifiedItemClick(link);
    end
end

local instanceInfo = {
    ['5-man normal'] = {
        ['Utgarde Keep']                            = '^0^5',
        ['The Nexus']                               = '^0^5',
        ['Azjol-Nerub']                             = '^0^5',
        ['Ahn\'kahet: The Old Kingdom']             = '^0^5',
        ['Drak\'Tharon Keep']                       = '^0^5',
        ['The Violet Hold']                         = '^0^5',
        ['Gundrak']                                 = '^0^5',
        ['Halls of Stone']                          = '^0^5',
        ['Halls of Lightning']                      = '^0^5',
        ['The Oculus']                              = '^0^5',
        ['Caverns of Time: Culling of Stratholme']  = '^0^5',
        ['Utgarde Pinnacle']                        = '^0^5',
        ['Trial of the Champion']                   = '^0^5',
    },
    ['5-man heroic'] = {
        ['Utgarde Keep']                            = '^2^5',
        ['The Nexus']                               = '^2^5',
        ['Azjol-Nerub']                             = '^2^5',
        ['Ahn\'kahet: The Old Kingdom']             = '^2^5',
        ['Drak\'Tharon Keep']                       = '^2^5',
        ['The Violet Hold']                         = '^2^5',
        ['Gundrak']                                 = '^2^5',
        ['Halls of Stone']                          = '^2^5',
        ['Halls of Lightning']                      = '^2^5',
        ['The Oculus']                              = '^2^5',
        ['Caverns of Time: Culling of Stratholme']  = '^2^5',
        ['Utgarde Pinnacle']                        = '^2^5',
        ['Trial of the Champion']                   = '^2^5',
    },
    ['10-man instances'] = {
        ['Naxxramas']                               = '^1^10',
        ['Obsidian Sanctum']                        = '^1^10',
        ['Vault of Archavon']                       = '^1^10',
        ['The Eye of Eternity']                     = '^1^10',
        ['Ulduar']                                  = '^1^10',
        ['Trial of the Crusader']                   = '^1^10',
        ['Trial of the Crusader (Heroic)']          = '^2^10',
        ['Onyxia\'s Lair']                          = '^1^10',
    },
    ['25-man instances'] = {
        ['Naxxramas']                               = '^2^25',
        ['Obsidian Sanctum']                        = '^2^25',
        ['Vault of Archavon']                       = '^2^25',
        ['The Eye of Eternity']                     = '^2^25',
        ['Ulduar']                                  = '^2^25',
        ['Trial of the Crusader']                   = '^2^25',
        ['Trial of the Crusader (Heroic)']          = '^3^25',
        ['Onyxia\'s Lair']                          = '^2^25',
    }
}

function LootMasterML:RaidInfoLookupPrintUserDraw(cell, value)
    if not value or type(value)~='number' then return cell.text:SetText('') end;
    cell.text:SetText(format('%s ms', ceil(value*1000)))
end

function LootMasterML:RaidInfoLookupActionUserDraw(cell, value)
    if not value or value==0 then
        return cell.text:SetText('[Отправляю данные установки]')
    end;
    cell.text:SetText('')
end

function LootMasterML:RaidInfoLookupActionClick(name)
    if not self.raidinfoframe then return end;
    local rowID = self.raidinfoframe.members[name];
    if not rowID then return end;
    if self.raidinfoframe.rows[rowID].cols[3].value == 0 then
        SendChatMessage("Авто сообщение: пожалуйста установите EPGPLootmaster с сайта getaddon.com", "WHISPER", nil, name);
    end
end

function LootMasterML:RaidInfoLookupResponse(name, response)
    if not self.raidinfoframe then return end
    local frame = self.raidinfoframe
    local rowID = frame.members[name]
    if not rowID then return end

    local iName, iDifficulty, iSize, iFound, iID, iResets, iLocked, iIsExtended, iIDMostSig, iIsRaid = strsplit('^', response)
    iResets = tonumber(iResets) or 0
    iFound = tonumber(iFound) or 0
    iID = tonumber(iID) or 0

    local row = frame.rows[rowID]

    if iFound == 0 then
        -- Instance couldn't be found on the player's raidinfo, assume not saved
        row.cols[2].value = 'Не сохранено, доступно';
        row.color = {r=0,g=1,b=0,a=1}
    else
        -- Instance was found on the player's list
        if iResets <= 0 then
            row.cols[2].value = 'Блокировка рейда прошла, доступно';
            row.color = {r=0,g=1,b=0,a=1}
        else
            if frame.localInstanceID and iID == frame.localInstanceID then
              row.cols[2].value = 'Сохранен для вашего подземелья';
              row.color = {r=0,g=1,b=0,a=1}
            else
              if iLocked == 'true' then
                  row.cols[2].value = 'Сохранен '..iID..', блокировано';
                  row.color = {r=1,g=0,b=0,a=1}
              else
                  row.color = {r=1,g=0.5,b=0,a=1}
                  row.cols[2].value = 'Сохранен '..iID..', не еще не заблокировано';
              end
            end
        end
    end

    frame.sstScroll:SortData()
    frame.sstScroll:DoFilter()
end

function LootMasterML:RaidInfoLookupPrintColor(name)
    if not self.raidinfoframe then return end
    local rowID = self.raidinfoframe.members[name]
    if not rowID then return end
    return self.raidinfoframe.rows[rowID].color
end

function LootMasterML:AddRaidInfoLookupMember(name)

    if not name then return end

    tinsert( self.raidinfoframe.rows, {
        ["cols"] = {
            {["value"]          = name},

            {["value"]          = 'Нет ответа; не установлено?'},

            {["value"]          = '',
             ["userDraw"]       = self.RaidInfoLookupPrintUserDraw,
             ["color"]          = self.RaidInfoLookupPrintColor,
             ["colorargs"]      = {self, name}}
        },
        ["start"] = GetTime(),
        ["color"] = {r=0.5,g=0.5,b=0.5,a=1}
    })

    self.raidinfoframe.members[name] = #(self.raidinfoframe.rows);
    return self.raidinfoframe.members[name];
end

local function pairsByKeys(t, f)
   local a = {}
   for n in pairs(t) do table.insert(a, n) end
   table.sort(a, f)
   local i = 0      -- iterator variable
   local iter = function ()   -- iterator function
      i = i + 1
      if a[i] == nil then return nil
      else return a[i], t[a[i]]
      end
   end
   return iter
end

local function FindUndetectedInstances()
	lookupTable = {}

	-- Build a lookuptable, so we can see which instances already are on the list
	for groupName, groupData in pairs(instanceInfo) do
	   for instance, lookup in pairs(groupData) do
		  if strsub(lookup,1,1) == '^' then
			 lookup = instance .. lookup
		  end
		  lookupTable[lookup] = lookup
	   end
	end

	-- Create a storage table in the saved variables
	if LootMaster.db.profile.detectedRaidLookups == nil then
	   LootMaster.db.profile.detectedRaidLookups = {}
	end
	local dbLookups = LootMaster.db.profile.detectedRaidLookups

	RequestRaidInfo()
	local n = GetNumSavedInstances()
	for i=1, n do
	   local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(i)
	   local lookup = format("%s^%s^%s", instanceName, instanceDifficulty, maxPlayers)
	   if lookupTable[lookup] == nil then
		  -- instance not already on the list
		  local playerTableName = 'Unknown type'
		  if maxPlayers == 5 then
			 if (instanceDifficulty > 0) then
				playerTableName = '5-man heroic'
			 else
				playerTableName = '5-man normal'
			 end
		  elseif maxPlayers == 10 then
			 playerTableName = '10-man instances'
		  elseif maxPlayers == 25 then
			 playerTableName = '25-man instances'
		  end

		  if dbLookups[playerTableName] == nil then
			 dbLookups[playerTableName] = {}
		  end

		  local sInstanceName = instanceName
		  if difficultyName ~= nil then
			 sInstanceName = format("%s (%s)", instanceName, difficultyName)
		  end

		  dbLookups[playerTableName][sInstanceName] = lookup
	   end
	end

	for groupName, group in pairs(dbLookups) do
	   for instanceName, lookup in pairs(group) do
		  if not lookupTable[lookup] then
			 -- Only merge if the instance lookup string is not already on the list.
			 if not instanceInfo[groupName] then
				instanceInfo[groupName] = {}
			 end
			 instanceInfo[groupName][instanceName] = lookup
			 lookupTable[lookup] = lookup
		  end
	   end
	end
end

local function GetLocalInstanceID(instanceLookup)
  local searchName, searchDifficulty, searchSize = strsplit("^", instanceLookup)
  searchDifficulty = tonumber(searchDifficulty)
  searchSize = tonumber(searchSize)

  RequestRaidInfo()
  local n = GetNumSavedInstances()
  for i=1, n do
     local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(i)
     if instanceName == searchName and searchDifficulty == instanceDifficulty and searchSize == maxPlayers then
        instanceReset = tonumber(instanceReset) or 0
        if instanceReset > 0 and locked then
          return instanceID
        end
     end
  end
end

-- Pretty obvious ;)
function LootMasterML:ShowRaidInfoLookup()

    local frame = self.raidinfoframe

    if not frame then

        frame = CreateFrame("Frame","LootMasterUIFrame",UIParent)
        --#region Setup main masterlooter frame
        frame:Hide();
        frame:SetWidth(700)
        frame:SetHeight(400)
        frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
        frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
        frame:EnableMouse()
        frame:SetResizable()
        frame:SetMovable(true)
        frame:SetFrameStrata("DIALOG")
        frame:SetToplevel(true)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 64, edgeSize = 12,
            insets = { left = 2, right = 1, top = 2, bottom = 2 }
        })
        frame:SetBackdropColor(1,1,0,1)
        frame:SetBackdropBorderColor(1,1,1,0.2)

        frame:SetScript("OnMouseDown", function() frame:StartMoving() end)
        frame:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
        --frame:SetScript("OnHide",frameOnClose)
        --#endregion

        local titleFrame = CreateFrame("Frame", nil, frame)
        --#region Setup main frame title
        titleFrame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 64, edgeSize = 12,
            insets = { left = 2, right = 1, top = 2, bottom = 2 }
        })
        titleFrame:SetBackdropColor(0,0,0,1)
        titleFrame:SetHeight(22)
        titleFrame:EnableMouse()
        titleFrame:SetResizable()
        titleFrame:SetMovable(true)
        titleFrame:SetPoint("LEFT",frame,"TOPLEFT",20,0)
        titleFrame:SetPoint("RIGHT",frame,"TOPRIGHT",-20,0)

        titleFrame:SetScript("OnMouseDown", function() frame:StartMoving() end)
        titleFrame:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

        local titletext = titleFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        titletext:SetPoint("CENTER",titleFrame,"CENTER",0,1)
        titletext:SetText( string.format("EPGPLootMaster %s by Bushmaster <Steel Alliance> - Twisting Nether EU(перевод http://getaddon.com)", LootMaster:GetVersionString() ) )
        frame.titleFrame = titleFrame
        --#endregion

        local sstScroll = ScrollingTable:CreateST({
                { ["name"] = "член",		["width"] = 250, ["align"] = "LEFT" },
                { ["name"] = "рейд блок",		["width"] = 300, ["align"] = "LEFT", 	["defaultsort"] = "desc", ["sort"] = "desc"}

            }, 15, 20, nil, frame);
        --#region Setup the scrollingTable
        sstScroll.frame:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-75)
        sstScroll.frame:SetPoint("RIGHT",frame,"RIGHT",-30,10)
        frame:SetWidth( sstScroll.frame:GetWidth(width) + 37 )
        frame.sstScroll = sstScroll

        local dropdown = AceGUI:Create('Dropdown')
        dropdown.frame:SetParent(frame)
        dropdown.frame:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-25)
        dropdown.frame:Show()
        dropdown:SetWidth(300)
        dropdown:SetText('--==[    SELECT AN INSTANCE    ]==--        ')

        local header = AceGUI:Create("Dropdown-Item-Header")
        header:SetText("Подземелья:")
        header.SetValue = function() end
        dropdown.pullout:AddItem(header)

		FindUndetectedInstances()

        for groupName, instanceItems in pairsByKeys(instanceInfo) do
          local submenu = AceGUI:Create("Dropdown-Pullout")

          for instanceName, lookup in pairsByKeys(instanceItems) do
            local btn1 = AceGUI:Create("Dropdown-Item-Execute")
            btn1:SetText(instanceName)
            btn1:SetCallback("OnClick", function()
              dropdown:SetText(groupName .. ' > ' .. instanceName)
              dropdown.pullout:Close()
              if strsub(lookup,1,1) == '^' then
                frame.lookup = instanceName .. lookup
              else
                frame.lookup = instanceName .. lookup
              end
            end)
            submenu:AddItem(btn1)
          end

          local menuItem = AceGUI:Create("Dropdown-Item-Menu")
          menuItem:SetText(groupName)
          menuItem:SetMenu(submenu)
          menuItem.SetValue = function() end
          dropdown.pullout:AddItem(menuItem)
        end

        local btnGuild = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btnGuild:SetScript("OnClick", function()

            if not frame.lookup then
              return print('Поиск рейд инфо: Пожалуйста выбирите подземелье')
            end

            frame.members = {}
            frame.rows = {}
            GuildRoster()
            local num = GetNumGuildMembers()
            for i=1, num do repeat
                local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
                if online then
                    local memberID = self:AddRaidInfoLookupMember(name)
                end
            until true end
            sstScroll:SetData( frame.rows )
            sstScroll:SortData()
            sstScroll:DoFilter()

            frame.localInstanceID = GetLocalInstanceID(frame.lookup)
            self:SendCommand('GETRAIDINFO', frame.lookup, 'GUILD')

        end)
        btnGuild:SetPoint("TOPLEFT",dropdown.frame,"TOPRIGHT",10,0)
        btnGuild:SetHeight(25)
        btnGuild:SetWidth(60)
        btnGuild:SetText("Guild")

        local btnRaid= CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btnRaid:SetScript("OnClick", function()

            if not frame.lookup then
              return print('Поиск Рейдинфо: Пожалуйста выбирите подземелье')
            end

            frame.members = {}
            frame.rows = {}

            frame.localInstanceID = GetLocalInstanceID(frame.lookup)

            local num = GetNumRaidMembers()
            if num>0 then
                -- we're in raid
                for i=1, num do
                    self:AddRaidInfoLookupMember(GetRaidRosterInfo(i))
                end
                sstScroll:SetData( frame.rows )
                self:SendCommand('GETRAIDINFO', frame.lookup, 'RAID')
            else
                num = GetNumPartyMembers()
                for i=1, num do
                    self:AddRaidInfoLookupMember(UnitName('party'..i))
                end
                self:AddRaidInfoLookupMember(UnitName('player'))
                sstScroll:SetData( frame.rows )
                if num > 0 then
                  self:SendCommand('GETRAIDINFO', frame.lookup, 'PARTY')
                else
                  self:SendCommand('GETRAIDINFO', frame.lookup, UnitName('player'))
                end
            end

            sstScroll:SortData();
            sstScroll:DoFilter();
        end)
        btnRaid:SetPoint("TOPLEFT",btnGuild,"TOPRIGHT",10,0)
        btnRaid:SetHeight(25)
        btnRaid:SetWidth(100)
        btnRaid:SetText("Raid/Party")

        local btnClose= CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btnClose:SetScript("OnClick", function()
            frame:Hide();
        end)
        btnClose:SetPoint("RIGHT",frame,"RIGHT",-10,0)
        btnClose:SetPoint("TOP",btnRaid,"TOP",0,0)
        btnClose:SetHeight(25)
        btnClose:SetWidth(70)
        btnClose:SetText("Закрыть")

        self.raidinfoframe = frame;
    end

    frame.members = {}
    frame.rows = {}

    frame.sstScroll:SetData( frame.rows )

    frame:Show();

end
