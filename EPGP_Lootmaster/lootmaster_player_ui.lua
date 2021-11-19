local LM_LOOTFRAME_MAXNUM   = 4;
local LM_LOOTFRAME_HEIGHT   = 68;
local LM_LOOTFRAME_PADDING  = 15;

local audioPlayed = false


-- Show an update notice.    
function LootMaster:ShowUpdateFrame( sender, iVersion, sVersion )
    if self.iLastVersionResponse and self.iLastVersionResponse>=iVersion then
        -- Only show the update message once, unless theres even a newer version found.
        return;
    end;
    self.iLastVersionResponse = iVersion;
    message( string.format("Автонапоминалка от %s: пожалуйста обновите epgp_lootmaster с getaddon.com. Если вы этого не зделаете, можете не получить лут в рейде..", sender, sVersion ) )
end

function LootMaster:InitUI()
    self.lootSelectFrames = {};
    
    local frame = CreateFrame("Frame","LootMasterUIFrame",UIParent)
    --#region Setup main masterlooter frame
    frame:Hide();
    frame:SetWidth(530)
    --frame:SetHeight(500)
    frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    frame:SetPoint("TOP",UIParent,"CENTER",0,LM_LOOTFRAME_MAXNUM*(LM_LOOTFRAME_PADDING+LM_LOOTFRAME_HEIGHT)/2)
  	frame:EnableMouse()
    frame:SetScale(LootMaster.db.profile.popupUIScale or 1)
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
    titleFrame:EnableMouseWheel(true)
    titleFrame:SetResizable()    
    titleFrame:SetMovable(true)
    titleFrame:SetPoint("LEFT",frame,"TOPLEFT",20,0)
    titleFrame:SetPoint("RIGHT",frame,"TOPRIGHT",-20,0)
    
    titleFrame:SetScript("OnMouseDown", function() frame:StartMoving() end)
    titleFrame:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    titleFrame:SetScript("OnMouseWheel", function(s, delta) 
      self:SetUIScale( max(min(frame:GetScale(0.8) + delta/15,2.0),0.5) );
    end)
    
    local titletext = titleFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    titletext:SetPoint("CENTER",titleFrame,"CENTER",0,1)
    titletext:SetText( string.format("EPGPLootMaster %s by Bushmaster <Steel Alliance> - Twisting Nether EU, перевод http://getaddon.com", self:GetVersionString() ) )    
    frame.titleFrame = titleFrame
    --#endregion
    
    self.frame = frame;
    return self.frame
end

function LootMaster:SetUIScale( scale )
    LootMaster.db.profile.popupUIScale = scale;
    if not self.frame then return end;
    self.frame:SetScale( scale );
end

function LootMaster:EnterCombat()
    -- Should we hide when entering combat?
    if not LootMaster.db.profile.hideSelectionOnCombat then return end;
    
    self.inCombat = true;
    if self.frame and self.frame:IsShown() then
        self:Print("Вы вошли в бой, прячу интерфейс.");
        self.hiddenOnCombat = true;
        self:Hide();
    end
end

function LootMaster:LeaveCombat()
    self.inCombat = nil;
    self:UpdateLootUI();
end

function LootMaster:IsShown()
    if not self.frame then return false end;
    
    if self.inCombat and self.hiddenOnCombat then
        return true;
    end;
    
    return self.frame:IsShown();
end

function LootMaster:Show()
    if not self.frame then return false end;
    
    if LootMaster.db.profile.hideOnSelection and LootMasterML and LootMasterML.IsShown then
        if not self.mlshown then
            self.mlshown = LootMasterML.IsShown(LootMasterML)
        end
        LootMasterML.Hide(LootMasterML)
    end
    
    if self.inCombat then
        self.hiddenOnCombat = true;
        return self.frame:Hide();
    end
    
    return self.frame:Show();
end

function LootMaster:Hide()
    if not self.frame then return end;
    
    local ret = self.frame:Hide();
    
    if not self.inCombat and self.mlshown and LootMasterML and LootMasterML.Show then
        LootMasterML.Show(LootMasterML)
        self.mlshown = false;
    end
        
    return ret;
end

function LootMaster:SaveNote( frame, keepVisibility )
    frame.data.note = gsub(frame.tbNote:GetText() or '', '%^', '');
    if frame.data.note and frame.data.note~='' then
        frame.lblNote:SetText(format('Моя заметка: %s', frame.data.note or ''))
    else
        frame.lblNote:SetText('')
    end
    if not keepVisibility then
        frame.tbNote:Hide();
        frame.data.isEditingNote = false;
    end
end

function LootMaster:CreateLootSelectFrame()
    if not self.frame then self:InitUI() end;
    
    local frame = CreateFrame("Frame", nil, self.frame)
    --#region Setup main masterlooter frame
    frame:Show()
    frame:SetHeight(LM_LOOTFRAME_HEIGHT)
    frame:SetBackdrop({
      bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 64, edgeSize = 12,
      insets = { left = 2, right = 1, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0,0.2,0,0.8)
    frame:SetPoint("LEFT",self.frame,"LEFT",20,0)
    frame:SetPoint("RIGHT",self.frame,"RIGHT",-20,0)
    
    local icon = CreateFrame("Button", nil, frame)
    icon:EnableMouse()
    icon:SetScript("OnEnter", function()
        GameTooltip:SetOwner(icon, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink( frame.data.link )
        GameTooltip:Show()
    end);
    icon:SetScript("OnLeave", function()
	    GameTooltip:Hide()	
    end);
    icon:SetScript("OnClick", function()
	    if ( IsModifiedClick() ) then
		    HandleModifiedItemClick(frame.data.link);
        end
    end);
    icon:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-10)
    icon:SetHeight(LM_LOOTFRAME_HEIGHT-20)
    icon:SetWidth(LM_LOOTFRAME_HEIGHT-20)
    frame.itemIcon = icon;
    
    local lblItem = frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    lblItem:SetPoint("TOPLEFT",icon,"TOPRIGHT",10,0)
    lblItem:SetVertexColor( 1, 1, 1 );
    lblItem:SetText( "Itemname" )    
    frame.lblItem = lblItem;
    
    local lblInfo = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lblInfo:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-10,-9)
    lblInfo:SetVertexColor( 0.9, 0.9, 0.9 );
    lblInfo:SetText( "ItemInfo" )
    frame.lblInfo = lblInfo;
    
    local lblLooter = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    lblLooter:SetPoint("TOPRIGHT",lblInfo,"TOPLEFT",-10,2)
    lblLooter:SetText( "Master Looter: -" )
    frame.lblLooter = lblLooter;
    
    local lblNote = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lblNote:SetPoint("TOPRIGHT",lblInfo,"BOTTOMRIGHT",0,-2)
    lblNote:SetVertexColor( 0.9, 0.9, 0.9 );
    lblNote:SetText( "ItemNote" )
    frame.lblNote = lblNote;
    
    frame.buttons = {}
      
    local btnPass = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnPass:SetScript("OnClick", function()
              self:SaveNote(frame)
              self:SendItemWanted( frame.data.lootmaster, frame.data.id, self.RESPONSE.PASS, frame.data.note )
              self:RemoveLoot( frame.data.id );
              self:UpdateLootUI();
    end)
    btnPass:SetPoint("BOTTOMLEFT",btnGreed,"BOTTOMRIGHT",5,0)
    btnPass:SetText("Отказ")
    btnPass:SetHeight(25)
    btnPass:SetWidth(btnPass:GetFontString():GetStringWidth() + 20)
    frame.btnPass = btnPass
    
    
    local timerFrame = CreateFrame("Frame", nil, frame)    
    timerFrame:SetHeight(20)  
      timerFrame:SetWidth(115);
      timerFrame:SetBackdrop({
      bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      --edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 64, edgeSize = 12,
      insets = { left = 2, right = 1, top = 2, bottom = 2 }
    })
    timerFrame:SetBackdropColor(1, 0, 0, 0.4)
    timerFrame:SetBackdropBorderColor(1, 0.6980392, 0, 0)
    timerFrame:SetPoint("LEFT",btnPass,"RIGHT", 10, 0);
    frame.timerFrame = timerFrame;
    
    local b=CreateFrame("STATUSBAR",nil,timerFrame,"TextStatusBar");
    local bCount = 0;
    local bElapse = 0;
    b:SetPoint("TOPLEFT",timerFrame,"TOPLEFT", 3, -3);
    b:SetPoint("BOTTOMRIGHT",timerFrame,"BOTTOMRIGHT", -2, 3);
    b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    b:SetStatusBarColor(0.4, 0.8, 0.4, 0.8);
    b:SetMinMaxValues(0,100)
    b:SetScript("OnUpdate", function( o, elapsed )
        if not frame or not frame.data or not frame.data.timeoutLeft then 
            b:SetMinMaxValues(0,100); b:SetValue(100);
            frame.lblTimeout:SetText( 'No timeout' )
            return;
        end
        frame.data.timeoutLeft = frame.data.timeoutLeft - elapsed;
        if frame.data.timeoutLeft<0 then
            frame.data.timeoutLeft = 0;
            b:SetValue(0);
            frame.lblTimeout:SetText( 'Не осталось времени' )
            
            self:SaveNote(frame)
            self:SendItemWanted( frame.data.lootmaster, frame.data.id, self.RESPONSE.TIMEOUT, frame.data.note )
            self:RemoveLoot( frame.data.id );
            self:UpdateLootUI();
            
            return;
        end 
        
        frame.lblTimeout:SetText( format("%s секунд до пропуска", ceil(frame.data.timeoutLeft)) )
        b:SetValue(frame.data.timeoutLeft)        
    end)
    frame.progressBar = b;
    
    local timerBorderFrame = CreateFrame("Frame", nil, timerFrame)    
    timerBorderFrame:SetHeight(20) 
      timerBorderFrame:SetToplevel(true)
      timerBorderFrame:SetWidth(135);
      timerBorderFrame:SetBackdrop({
      --bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 64, edgeSize = 12,
      insets = { left = 2, right = 1, top = 2, bottom = 2 }
    })
    timerBorderFrame:SetBackdropColor(1, 0, 0, 0.0)
    timerBorderFrame:SetBackdropBorderColor(1, 0.6980392, 0, 1)
    timerBorderFrame:SetPoint("TOPLEFT",timerFrame,"TOPLEFT", 0, 0);
    timerBorderFrame:SetPoint("BOTTOMRIGHT",timerFrame,"BOTTOMRIGHT", 0, 0);
    
    local lblTimeout = timerBorderFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lblTimeout:SetPoint("CENTER",timerBorderFrame,"CENTER",0,0)
    lblTimeout:SetVertexColor( 1, 1, 1 );
    lblTimeout:SetText( "Itemname" )    
    frame.lblTimeout = lblTimeout;
    
    timerFrame:Show()
    
    --[[ NOTE EDITBOX ]]--
    local tbNote = CreateFrame("EditBox", nil, frame)
    tbNote:SetPoint("TOPLEFT", lblItem, "TOPLEFT", 0, 3)
    tbNote:SetPoint("BOTTOM", lblItem, "BOTTOM", 0, -6)
    tbNote:SetPoint("RIGHT", lblInfo, "RIGHT", -45, 0)
    tbNote:SetFontObject(GameFontNormal)
    tbNote:SetTextColor(.8,.8,.8)
    tbNote:SetTextInsets(8,8,8,8)
    tbNote:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    tbNote:SetBackdropColor(.1,.1,.1,1)
    tbNote:SetBackdropBorderColor(.5,.5,.5)
    tbNote:SetMultiLine(false)
    tbNote:SetAutoFocus(false)
    tbNote:SetText('');
    tbNote:SetScript("OnTextChanged", function()
        self:SaveNote(frame, true)
    end)
    tbNote:SetScript("OnEscapePressed", function()
        tbNote:ClearFocus();
        tbNote:Hide();
        tbNote:SetText(frame.data.note or '')
        frame.data.isEditingNote = false;
    end)
    tbNote:SetScript("OnEnterPressed", function()
        self:SaveNote(frame)
    end)
    tbNote:SetScript("OnShow", function()
        frame.data.isEditingNote = true;
    end)
    tbNote:SetMaxBytes(150);
    
    local btnNoteSave = CreateFrame("Button", nil, tbNote, "UIPanelButtonTemplate")
    btnNoteSave:SetScript("OnClick", function()
              self:SaveNote(frame)
      end)
    btnNoteSave:SetPoint("LEFT",tbNote,"RIGHT",-5,0)
    btnNoteSave:SetHeight(25)
    btnNoteSave:SetWidth(50)
    btnNoteSave:SetText("Save")
    
    frame.tbNote = tbNote;
    
    
    --[[ NOTE BUTTON ]]--    
    local btnNote = CreateFrame("Button", nil, frame)
    btnNote:SetWidth(25)
    btnNote:SetHeight(25)
    btnNote:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    btnNote:SetPoint("LEFT", timerFrame, "RIGHT", 10, 0)
    
    local btnNoteIcon = btnNote:CreateTexture(nil, "BACKGROUND")
    btnNoteIcon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    btnNoteIcon:SetPoint("CENTER", btnNote, "CENTER", 0, 1)
    btnNoteIcon:SetHeight(14)
    btnNoteIcon:SetWidth(12)
    
    local btnNoteOverlay = btnNote:CreateTexture(nil, "OVERLAY")
    btnNoteOverlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btnNoteOverlay:SetWidth(42)
    btnNoteOverlay:SetHeight(42)
    btnNoteOverlay:SetPoint("TOPLEFT")
    
    btnNote:RegisterForClicks("AnyUp")
    
    btnNote:SetScript("OnClick", function()
        tbNote:Show();
        tbNote:SetFocus();
    end)
    
    btnNote:SetScript("OnMouseDown", function(self)
        btnNoteIcon:SetTexCoord(.1,.9,.1,.9)
    end)
    btnNote:SetScript("OnMouseUp", function(self)
        btnNoteIcon:SetTexCoord(0,1,0,1)
    end)
    
    btnNote:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "BOTTOMRIGHT")
        GameTooltip:AddLine("Добавить заметку")
        GameTooltip:AddLine("Нажмите сюда что бы добавить заметку, для того что бы отправить ее лут мастеру.",.8,.8,.8,1, true)
        GameTooltip:Show()
    end)
    btnNote:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)    
    btnNote:EnableMouse(true)
    frame.btnNote = btnNote;
    
    return frame;
end

function LootMaster:UpdateLootUI()
    
    local hasLoot = false;
    local visibleLoot = 0;
    local totalLoot = 0;
    
    if self.inCombat then
        self.hiddenOnCombat = true;
        self:Hide();
        return true;
    end
    
    if not self.frame then
        self:InitUI()
    end;
    
    totalLoot = #self.lootList;
    hasLoot = totalLoot>0;
    
    for i, data in ipairs(self.lootList) do repeat
        
        -- If the item is empty try the next item.
        if not data then break end;        
        
        -- Do not show more loot items than LM_LOOTFRAME_MAXNUM
        if visibleLoot>=LM_LOOTFRAME_MAXNUM then break end;
        
        visibleLoot = visibleLoot + 1;
        
        local lootFrame = self.lootSelectFrames[visibleLoot];
        if not lootFrame then
            lootFrame = self:CreateLootSelectFrame();
            self.lootSelectFrames[visibleLoot] = lootFrame;
        end
        
        -- show the current item on the monitor
        if visibleLoot==1 and not self.db.profile.hideOnSelection and LootMasterML and LootMasterML.GetLootID(LootMasterML,data.link) then
            -- Not already visible?
            if not LootMasterML.frame or not LootMasterML.frame.currentLoot or (not LootMasterML.frame.currentLoot.mayDistribute and LootMasterML.frame.currentLoot.id~=data.id) then 
                -- show the item.
                LootMasterML.DisplayLoot(LootMasterML, data.id)
            end
        end
        
        lootFrame.data = data;
        
        lootFrame.lblItem:SetText(format('%s',data.link));
        
        local color = ITEM_QUALITY_COLORS[data.quality];
        if not color then
            color = {['r']=1,['g']=1,['b']=1}
        end
        lootFrame.lblItem:SetVertexColor(color.r, color.g, color.b);
        
        local gp = data.gpvalue or 0;
        if data.gpvalue2 and data.gpvalue2~='' then
            gp = gp .. format(' or %s', data.gpvalue2)
        end
        --if data.gpvalue_greed and data.gpvalue_greed~='' then
        --    gp = gp .. format(' (greed GP: %s)', data.gpvalue_greed)
        --end
        
        if not data.notesAllowed then
            lootFrame.btnNote:Hide();
            lootFrame.tbNote:Hide();
            lootFrame.lblNote:SetText('');
        else
            lootFrame.btnNote:Show();
            lootFrame.tbNote:SetText( data.note or '' );
            self:SaveNote( lootFrame, true )
            if data.isEditingNote then
                lootFrame.tbNote:Show();
            else
                lootFrame.tbNote:Hide();
            end
        end
        
        -- Create / Display the buttons
        local lastButton = lootFrame.itemIcon
        local totalButtonWidth = 0
        for i=1, data.numButtons do
          local buttonData = data.buttons[i]
          local button = lootFrame.buttons[i]
          
          if not button then
            -- Create the button
            button = CreateFrame("Button", nil, lootFrame, "UIPanelButtonTemplate")
            button:SetScript("OnClick", function(btn)
                      self:SaveNote(lootFrame)
                      self:SendItemWanted(lootFrame.data.lootmaster, lootFrame.data.id, btn.response, lootFrame.data.note)
                      self:RemoveLoot(lootFrame.data.id);
                      self:UpdateLootUI();
            end)
            button:SetPoint("BOTTOMLEFT", btnOffspec, "BOTTOMRIGHT", 5, 0)
            button:SetHeight(25)
            lootFrame.buttons[i] = button
          end
          
          button:Show()
          button.response = buttonData.response
          button:ClearAllPoints()
          button:SetPoint("BOTTOMLEFT", lastButton, "BOTTOMRIGHT", 5, 0)
          button:SetText(buttonData.text)
          local width = button:GetFontString():GetStringWidth() + 20
          button:SetWidth(width)
          totalButtonWidth = totalButtonWidth + width + 5
          
          lastButton = button
        end
        
        local frameWidth =  max(320 + totalButtonWidth, 700)
        if self.frame:GetWidth() < frameWidth then
          self.frame:SetWidth(frameWidth)
        end
        
        -- Position the pass button
        lootFrame.btnPass:ClearAllPoints()
        lootFrame.btnPass:SetPoint("BOTTOMLEFT", lastButton, "BOTTOMRIGHT", 5, 0)
        
        -- Hide unused buttons
        for i=data.numButtons + 1, #(lootFrame.buttons) do
          local button = lootFrame.buttons[i]
          button:Hide()
        end
        
        lootFrame.lblInfo:SetText(format("ilevel: %s, GP: %s", data.ilevel or -1, gp))
        lootFrame.lblLooter:SetText(format("looter: %s", data.lootmaster or 'unknown'))
        
        lootFrame.itemIcon:SetNormalTexture(data.texture);        
        lootFrame:SetPoint("TOP",self.frame,"TOP",0, -30 - ((LM_LOOTFRAME_PADDING+LM_LOOTFRAME_HEIGHT) * (visibleLoot-1)))
        
        if data.timeout and data.timeout>0 then
            lootFrame.progressBar:SetMinMaxValues(0,data.timeout)
            lootFrame.progressBar:SetValue(data.timeoutLeft)
            lootFrame.lblTimeout:SetText('')
            lootFrame.timerFrame:Show();
        else
            lootFrame.timerFrame:Hide();
        end
        
        lootFrame:Show();
                
    until true end
    
    -- Hide the unused lootframes...
    for i = LM_LOOTFRAME_MAXNUM, visibleLoot+1, -1 do
        if self.lootSelectFrames[i] then
            self.lootSelectFrames[i]:Hide()
        end;
    end
    
    if hasLoot then
        self:Show();
        self.frame:SetHeight( 40 + ((LM_LOOTFRAME_PADDING+LM_LOOTFRAME_HEIGHT) * visibleLoot))
        if (not audioPlayed) and LootMaster.db.profile.audioWarningOnSelection then
            PlaySoundFile("Sound\\interface\\AuctionWindowClose.wav")
            audioPlayed = true
        end
    else
        audioPlayed = false
        self:Hide();
        self.frame:SetWidth(530);
        self.frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
        self.frame:SetPoint("TOP",UIParent,"CENTER",0,LM_LOOTFRAME_MAXNUM*(LM_LOOTFRAME_PADDING+LM_LOOTFRAME_HEIGHT)/2)
    end
    
end

function LootMaster:VersionPrintUserDraw(cell, value)
    if not value or type(value)~='number' then return cell.text:SetText('') end;
    cell.text:SetText(format('%s ms', ceil(value*1000)))
end

function LootMaster:VersionActionUserDraw(cell, value)
    if not value or value==0 then
        return cell.text:SetText('[Отправил инфу о установке]')
    end;
    cell.text:SetText('')
end

function LootMaster:VersionActionClick(name)
    if not self.versioncheckframe then return end;
    local rowID = self.versioncheckframe.members[name];
    if not rowID then return end;
    if self.versioncheckframe.rows[rowID].cols[3].value == 0 then
        SendChatMessage("Автосообщение: пожалуйста установите ЕPGPLootmaster с getaddon.com", "WHISPER", nil, name);
    end
end

function LootMaster:AddVersionCheckMember(name)
    
    if not name then return end
    
    tinsert( self.versioncheckframe.rows, {
        ["cols"] = {
				{["value"]          = name},
                
                {["value"]          = 'No response; not installed?'},
                
                {["value"]          = 0,
                 ["userDraw"]       = self.VersionActionUserDraw,
                 ["onclick"]        = self.VersionActionClick,
                 ["onclickargs"]    = {self, name}},
                 
                {["value"]          = '',
                 ["userDraw"]       = self.VersionPrintUserDraw }
		},
        ["start"] = GetTime()
	})
    
    self.versioncheckframe.members[name] = #(self.versioncheckframe.rows);
    return self.versioncheckframe.members[name];
end

-- Pretty obvious ;)
function LootMaster:ShowVersionCheckFrame()
    
    local frame = self.versioncheckframe;
    
    if not frame then    
        frame = CreateFrame("Frame","LootMasterUIFrame",UIParent)
        --#region Setup main masterlooter frame
        frame:Hide();
        frame:SetWidth(700)
        frame:SetHeight(400)
        frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
        frame:SetPoint("TOP",UIParent,"CENTER",0,LM_LOOTFRAME_MAXNUM*(LM_LOOTFRAME_PADDING+LM_LOOTFRAME_HEIGHT)/2)
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
        titletext:SetText( string.format("EPGPLootMaster %s by Bushmaster <Steel Alliance> - Twisting Nether EU", self:GetVersionString() ) )    
        frame.titleFrame = titleFrame
        --#endregion

        local sstScroll = ScrollingTable:CreateST({
                { ["name"] = "member",		["width"] = 150, ["align"] = "LEFT" },	   
                { ["name"] = "version",		["width"] = 150, ["align"] = "LEFT", 	["defaultsort"] = "desc", ["sort"] = "desc"},
                { ["name"] = "actions",		["width"] = 130, ["align"] = "LEFT" },
                { ["name"] = "ping",		["width"] = 80,  ["align"] = "RIGHT", 	["defaultsort"] = "desc", ["sort"] = "desc"}, 
            }, 15, 20, nil, frame);
        --#region Setup the scrollingTable
        sstScroll.frame:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-75)	
        sstScroll.frame:SetPoint("RIGHT",frame,"RIGHT",-30,10)    
        frame:SetWidth( sstScroll.frame:GetWidth(width) + 37 )        
        frame.sstScroll = sstScroll
        
        local lblVersionCheck = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        lblVersionCheck:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-25)
        lblVersionCheck:SetVertexColor( 1, 1, 1 );
        lblVersionCheck:SetText( "Request version for: " )
        
        local btnGuild = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	    btnGuild:SetScript("OnClick", function()
            
            frame.members = {}
            frame.rows = {}
            GuildRoster();
            local num = GetNumGuildMembers();
            for i=1, num do repeat
                local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i);
                if online then
                    local memberID = self:AddVersionCheckMember(name)
                end
            until true end     
            sstScroll:SetData( frame.rows )    
            sstScroll:SortData();
            sstScroll:DoFilter();
            
            self:SendCommMessage("EPGPLMVChk", "0_versioncheck", "GUILD")
        
        end)
        btnGuild:SetPoint("LEFT",lblVersionCheck,"RIGHT",10,0)
        btnGuild:SetHeight(25)
        btnGuild:SetWidth(100)
        btnGuild:SetText("Guild")
        
        local btnRaid= CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	    btnRaid:SetScript("OnClick", function()
            
            self.versioncheckframe.members = {}
            self.versioncheckframe.rows = {}
            
            local num = GetNumRaidMembers()
            if num>0 then
                -- we're in raid
                for i=1, num do                    
                    self:AddVersionCheckMember(GetRaidRosterInfo(i))
                end
                sstScroll:SetData( frame.rows )                
                self:SendCommMessage("EPGPLMVChk", "0_versioncheck", "RAID")
            else
                num = GetNumPartyMembers()
                for i=1, num do                    
                    self:AddVersionCheckMember(UnitName('party'..i))
                end
                self:AddVersionCheckMember(UnitName('player'))
                sstScroll:SetData( frame.rows )
                self:SendCommMessage("EPGPLMVChk", "0_versioncheck", "PARTY")
            end
            
            sstScroll:SortData();
            sstScroll:DoFilter();
        end)
        btnRaid:SetPoint("TOPLEFT",btnGuild,"TOPRIGHT",10,0)
        btnRaid:SetHeight(25)
        btnRaid:SetWidth(120)
        btnRaid:SetText("Raid/Party")
        
        local btnClose= CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	    btnClose:SetScript("OnClick", function()
            frame:Hide();
        end)
        btnClose:SetPoint("RIGHT",frame,"RIGHT",-10,0)
        btnClose:SetPoint("TOP",btnRaid,"TOP",0,0)
        btnClose:SetHeight(25)
        btnClose:SetWidth(100)
        btnClose:SetText("Close")        
        
        self.versioncheckframe = frame;
    end
    
    frame.members = {}
    frame.rows = {}
    
    frame.sstScroll:SetData( frame.rows )
    
    frame:Show();
    
end