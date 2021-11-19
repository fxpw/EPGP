local AceGUI = LibStub("AceGUI-3.0")

EPGPLM_MAX_BUTTONS = 7

------------------------------------
-- EPGPLMButtonConfigWidget		    --
------------------------------------
--[[
	Adds a config tool for the epgplm buttons.
]]

do
	local Type = "EPGPLMButtonConfigWidget"
	local Version = 1
  
  local buttonNames = {
    button1 = 'Кнопка 1',
    button2 = 'Кнопка 2',
    button3 = 'Кнопка 3',
    button4 = 'Кнопка 4',
    button5 = 'Кнопка 5',
    button6 = 'Кнопка 6',
    button7 = 'Кнопка 7'
  }

  local fallbackValues = {
    ['']          = 'Нет выбора',
    NEED          = 'Главная спец.',
    OFFSPEC       = 'Офф спец.',
    GREED         = 'На продажу',
    MINORUPGRADE  = 'Легкое обновл.'
  }
  
  local function OnMouseOverTooltip(anchorObject, name, desc, usage)
    GameTooltip:SetOwner(anchorObject, "ANCHOR_TOPRIGHT")    
    GameTooltip:SetText(name, 1, .82, 0, 1)
    if type(desc) == "string" then
      GameTooltip:AddLine(desc, 1, 1, 1, 1)
    end
    if type(usage) == "string" then
      GameTooltip:AddLine("Использование: "..usage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
    end
    GameTooltip:Show()
  end
  
  local function OnFallbackDropdownTooltip(self, event)
    OnMouseOverTooltip( self.frame,
                        'Резервная работа со старым клиентом',
                        'If you have people in your raid who are using old clients, you can use this to specify where their selection should go in your button setup. You may use each value only once.',
                        'If you set this to Mainspec, for example, old clients that select mainspec on their popups will have their selection go in this selection button category.')
  end
  
  local function OnGPEditTooltip(self, event)
    OnMouseOverTooltip( self.frame,
                        'GP value override',
                        'Fill this field to override the GP value when players select this button. This only adds an entry to the master looter distribution popup, so the master looter always has the final choice.',
                        "\r\nEmpty: use normal GP value"..
                        "\r\n50%: use 50% of normal GP value"..
                        "\r\n25: all items are worth 25 GP")
  end
  
  local function OnEditCaptionTooltip(self, event)
    OnMouseOverTooltip( self.frame,
                        'Button caption',
                        'This field specifies the text on the button, this will be shown on the selection popups and monitor windows.')
  end
  
  local function OnEditCaptionTooltip(self, event)
    OnMouseOverTooltip( self.frame,
                        'Button caption',
                        'This field specifies the text on the button, this will be shown on the selection popups and monitor windows.',
                        'You can use upto 18 characters (^ ; * excluded)')
  end
  
  local function OnColorTooltip(self, event)
    OnMouseOverTooltip( self.frame,
                        'Monitor text color',
                        'This field specifies the color of the selection text in the monitor windows.')
  end

  local function OnMouseLeaveTooltip()
    GameTooltip:Hide()
  end

	local function LayoutFinished(self, width, height)
		if self.noAutoHeight then return end
		self.content:SetHeight(height or 0)
	end
	
	local function OnWidthSet(self, width)
		self.content:SetWidth(width)
		self.content.width = width
	end

	local function OnHeightSet(self, height)
		self.content:SetHeight(height)
		self.content.height = height
	end
  
  local function OnSetLabel(self, label)
    -- this is a slight hack, but the label function defines the key in the
    -- configuration array, in this case.    
    self.label = label
    self.ebEditCaption:SetLabel((buttonNames[label] or 'Unknown') .. ' text:')    
    
    self.cpColor:SetColor(LootMaster:ColorHexToRGB(self.db[label .. '_color']))
    
    self.ebGPEdit:SetText(self.db[label .. '_gp'])
    
    self.ddFallback:SetList(fallbackValues)
    local value = self.db[label .. '_fallback']
    if not fallbackValues[value] then
      value = ''
    end
    self.ddFallback:SetValue(value)
  end
  
  local function OnSetCallback(self, callback, ...)
    self._SetCallback(self, callback, ...)
  end
  
  local function OnSetText(self, text)
    self.ebEditCaption:SetText(text)
  end
  
  local function OnCaptionEditEnterPressed(ebEditCaption, event, value, ...)    
    value = gsub(value,'[%^%;%*]','')
    ebEditCaption.obj:Fire('OnEnterPressed', value, ...)
  end
  
  local function OnColorValueConfirmed(cpColor, event, r, g, b, ...)
    local self = cpColor.obj
    local db = self.db
    db[self.label .. '_color'] = LootMaster:ColorRGBToHex(r,g,b)
    self:Fire('OnEnterPressed', self.db[self.label])
  end
  
  local function OnGPEditEnterPressed(ebGPEdit, event, value, ...)
    local self = ebGPEdit.obj    
    value = gsub(value, '[^0-9%%]', '')
    
    if value == '' or not value then
        value = ''
        self.db[self.label .. '_gpIsPercentage'] = false
        self.db[self.label .. '_gpValue'] = nil
    else
        local v, perc = strmatch(value, '^%s*(%d+)%s-(%%?)%s*$')
        self.db[self.label .. '_gpIsPercentage'] = (perc~=nil and perc~='')
        self.db[self.label .. '_gpValue'] = tonumber(v) or 0
    end
    
    ebGPEdit:SetText(value)    
    self.db[self.label .. '_gp'] = value
    
    ebGPEdit.editbox:ClearFocus()
    AceGUI:ClearFocus()
  end
  
  local function OnFallbackValueChanged(ddFallback, event, value, ...)
    local self = ddFallback.obj
    if value ~= '' then
      for i=1, EPGPLM_MAX_BUTTONS do
        local key = format('button%d_fallback', i)
        if self.db[key] == value then
          self.db[key] = ''
        end
      end
      self.db[self.label .. '_fallback'] = value
      self:Fire('OnEnterPressed', self.db[self.label], ...)
    else
      self.db[self.label .. '_fallback'] = value
    end
  end
  
  local function OnAcquire(self)
    self.db = LootMaster.db.profile
    
    self:SetLayout("flow")
    self.width = "fill"
    
    local grp = AceGUI:Create("SimpleGroup")
    grp.width = "fill"
    grp:SetLayout("flow")
    self:AddChild(grp)
    
    -- Create the caption editing box
    local ebEditCaption = AceGUI:Create("EditBox")
    ebEditCaption:SetWidth(130)
    ebEditCaption.obj = self
    ebEditCaption.editbox:SetMaxLetters(18)
    ebEditCaption:SetLabel("Button text:")
    ebEditCaption:SetCallback("OnLeave", OnMouseLeaveTooltip)
    ebEditCaption:SetCallback("OnEnter", OnEditCaptionTooltip)   
    ebEditCaption:SetCallback("OnEnterPressed", OnCaptionEditEnterPressed)
    self.ebEditCaption = ebEditCaption
    grp:AddChild(ebEditCaption)
    
    --Create the color picker widget
    local cpColor = AceGUI:Create("ColorPicker")
    cpColor:SetWidth(20)
    cpColor.obj = self
    cpColor:SetCallback("OnLeave", OnMouseLeaveTooltip)
    cpColor:SetCallback("OnEnter", OnColorTooltip)
    cpColor:SetCallback("OnValueConfirmed", OnColorValueConfirmed)    
    self.cpColor = cpColor
    grp:AddChild(cpColor)
    
    -- Create the GP editing box
    local ebGPEdit = AceGUI:Create("EditBox")
    ebGPEdit:SetWidth(70)
    ebGPEdit.obj = self
    ebGPEdit:SetText("GP")
    ebGPEdit.editbox:SetMaxLetters(8)
    ebGPEdit:SetLabel("default GP:")
    ebGPEdit:SetCallback("OnLeave", OnMouseLeaveTooltip)
    ebGPEdit:SetCallback("OnEnter", OnGPEditTooltip)  
    ebGPEdit:SetCallback("OnEnterPressed", OnGPEditEnterPressed)
    self.ebGPEdit = ebGPEdit
    grp:AddChild(ebGPEdit)
    
    -- Create the dropdown for the fallback data
    local ddFallback = AceGUI:Create("Dropdown")
    ddFallback:SetWidth(120)
    ddFallback.obj = self
    ddFallback:SetLabel("fallback:")    
		ddFallback:SetCallback("OnValueChanged", OnFallbackValueChanged)
    ddFallback:SetCallback("OnLeave", OnMouseLeaveTooltip)
    ddFallback:SetCallback("OnEnter", OnFallbackDropdownTooltip)
    self.ddFallback = ddFallback
    grp:AddChild(ddFallback)
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type
    
    self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.frame = frame
		self.LayoutFinished = LayoutFinished
		self.OnWidthSet = OnWidthSet
		self.OnHeightSet = OnHeightSet
    self.SetLabel = OnSetLabel
    self.SetText = OnSetText
    
    frame.obj = self
		frame:SetHeight(45)
		frame:SetWidth(500)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
    
    --Container Support
		local content = CreateFrame("Frame",nil,frame)
		self.content = content
		content.obj = self
    content.epid = 'content'
		content:SetPoint("LEFT",frame,"LEFT",0,0)
    content:SetPoint("TOP",frame,"TOP",0,10)
		content:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",50,0)
    
    AceGUI:RegisterAsContainer(self)
		
    self._SetCallback = self.SetCallback
    self.SetCallback = OnSetCallback
    
    self._GetUserDataTable = self.GetUserDataTable
    self.GetUserDataTable = OnGetUserDataTable
    
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
 
end
