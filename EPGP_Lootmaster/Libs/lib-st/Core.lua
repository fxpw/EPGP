ScrollingTable = LibStub("AceAddon-3.0"):NewAddon("stlm", "AceConsole-3.0");

function ScrollingTable:OnInitialize()
    self:RegisterChatCommand("st", "ChatCommand");
end

function ScrollingTable:ChatCommand()
	if not self.st then 
		self.st = self:CreateST();
		local data = {}
		for row = 1, 20 do
			if not data[row] then 
				data[row] = {};
			end
			for col = 1, 3 do
				if not data[row].cols then 
					data[row].cols = {};
				end
				data[row].cols[col] = { ["value"] = math.random(50) };
				-- data[row].cols[col].color    (cell text color)
			end
			data[row].cols[1].onclick = function(self, event, ...)
				ScrollingTable:Print("click! row", row, "col 1 value", data[row].cols[1].value);
			end
			data[row].cols[2].onenter = function(...)
				ScrollingTable:Print("enter! row", row, "col 2 value", data[row].cols[2].value);
			end
			data[row].cols[2].onleave = function(...)
				ScrollingTable:Print("leave! row", row, "col 2 value", data[row].cols[2].value);
			end
			data[row].onclick = function(self, event, ...)
				ScrollingTable:Print("click! row", row);
			end
			-- data[row].color (row text color)
		end 
		data[5].cols[1].color = { ["r"] = 0.5, ["g"] = 1.0, ["b"] = 0.5, ["a"] = 1.0 };
		data[5].color = { ["r"] = 1.0, ["g"] = 0.5, ["b"] = 0.5, ["a"] = 1.0 };
		self.st:SetData(data);
		self.st:SetFilter(function(self, row)
			return row.cols[1].value > 10; 
		end);
	elseif self.st.showing then 
		self.st:Hide();
	else
		self.st:Show();
	end
end

do 
	local defaultcolor = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 };
	local defaulthighlight = { ["r"] = 1.0, ["g"] = 0.9, ["b"] = 0.0, ["a"] = 0.5 };
	local lrpadding = 2.5;
	
	local ScrollPaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	};
	
	local framecount = 1; 
	
	local SetHeight = function(self)
		self.frame:SetHeight( (self.displayRows * self.rowHeight) + 10);
		self:Refresh();
	end
	
	local SetWidth = function(self)
		local width = 13;
		for num, col in pairs(self.cols) do
			width = width + col.width;
		end
		self.frame:SetWidth(width);
		self:Refresh();
	end
	
	local SetHighLightColor = function(frame, color)
		if not frame.highlight then 
			frame.highlight = frame:CreateTexture(nil, "OVERLAY");
			frame.highlight:SetAllPoints(frame);
		end
		frame.highlight:SetTexture(color.r, color.g, color.b, color.a);
	end
	
	local SetBackgroundColor = function(frame, color)
		if not frame.background then 
			frame.background = frame:CreateTexture(nil, "BACKGROUND");
			frame.background:SetAllPoints(frame);
		end
		frame.background:SetTexture(color.r, color.g, color.b, color.a);
	end
	
	local FireHandlerWithArgs = function (handler, data, ...)
		-- returns false if no handler was found
		local ret = false;
		local fnHandler = data[handler];
		local args = data[handler.."args"];
		if fnHandler then 
			if args then 
				fnHandler(unpack(args));
			else 
				fnHandler(...);
			end
			ret = true;
		end
		return ret;
	end
	local SetDisplayRows = function(self, num, rowHeight)
		local table = self;  -- save for closure later
		
		-- should always set columns first
		self.displayRows = num;
		self.rowHeight = rowHeight;
		if not self.rows then 
			self.rows = {};
		end
		for i = 1, num do 
			local row = self.rows[i];
			if not row then 
				row = CreateFrame("Button", self.frame:GetName().."Row"..i, self.frame);
				self.rows[i] = row;
				if i > 1 then 
					row:SetPoint("TOPLEFT", self.rows[i-1], "BOTTOMLEFT", 0, 0);
					row:SetPoint("TOPRIGHT", self.rows[i-1], "BOTTOMRIGHT", 0, 0);
				else
					row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -5);
					row:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -4, -5);
				end
				row:SetHeight(rowHeight);
			end
			
			if not row.cols then 
				row.cols = {};
			end
			for j = 1, #self.cols do
				local col = row.cols[j];
				if not row.moo then 
					row.moo = {};
				end
				local moo = row.moo[j];
				if not col then 
					col = CreateFrame("Button", row:GetName().."col"..j, row);
                    col:RegisterForClicks("AnyUp");
					col.text = row:CreateFontString(col:GetName().."text", "OVERLAY", "GameFontHighlightSmall");
					row.cols[j] = col;
					local align = self.cols[j].align or "LEFT";
					col.text:SetJustifyH(align); 
				end
				col:EnableMouse(true);
				col:SetScript("OnClick", function(cellFrame, ...)
					local realindex = table.filtered[i+table.offset];
					local celldata = table.data[realindex].cols[j];
					if not FireHandlerWithArgs("onclick", celldata, cellFrame, ...) then 
						local rowdata = table.data[realindex];
						FireHandlerWithArgs("onclick", rowdata, row, ...)			
					end
				end);
				col:SetScript("OnEnter", function(cellFrame, ...)
					SetHighLightColor(row, table.highlight);
					local realindex = table.filtered[i+table.offset];
					local celldata = table.data[realindex].cols[j];
					FireHandlerWithArgs("onenter", celldata, cellFrame, ...);
				end);
				col:SetScript("OnLeave", function(cellFrame, ...)
					SetHighLightColor(row, { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.0 });
					local realindex = table.filtered[i+table.offset];
					if (table.data[realindex] == nil) then return end
					local celldata = table.data[realindex].cols[j];
					if (celldata == nil) then return false end;
					FireHandlerWithArgs("onleave", celldata, cellFrame, ...);
				end);

				if j > 1 then 
					col:SetPoint("LEFT", row.cols[j-1], "RIGHT", 0, 0);
				else
					col:SetPoint("LEFT", row, "LEFT", 2, 0);
				end
				col:SetHeight(rowHeight);
				col:SetWidth(self.cols[j].width);
				col.text:SetPoint("TOP", col, "TOP", 0, 0);
				col.text:SetPoint("BOTTOM", col, "BOTTOM", 0, 0);
				col.text:SetWidth(self.cols[j].width - 2*lrpadding);
			end
			j = #self.cols + 1;
			col = row.cols[j];
			while col do
				col:Hide();
				j = j + 1;
				col = row.cols[j];
			end
		end
		
		i = num + 1;
		row = self.rows[i];
		while row do
			row:Hide();
		end
		
		self:SetHeight();
	end
	
	local SetDisplayCols = function(self, cols)
		local table = self; -- reference saved for closure
		self.cols = cols;
		
		local row = CreateFrame("Frame", self.frame:GetName().."Head", self.frame);
		row:SetPoint("BOTTOMLEFT", self.frame, "TOPLEFT", 4, 0);
		row:SetPoint("BOTTOMRIGHT", self.frame, "TOPRIGHT", -4, 0);
		row:SetHeight(self.rowHeight);
		row.cols = {};
		for i = 1, #cols do 
			col = CreateFrame("Button", row:GetName().."Col"..i, row);			
			col:SetScript("OnClick", function (self)
				for j = 1, #table.cols do 
					if j ~= i then -- clear out all other sort marks
						table.cols[j].sort = nil;
					end
				end
				local sortorder = "asc";
				if not table.cols[i].sort and table.cols[i].defaultsort then
					sortorder = table.cols[i].defaultsort; -- sort by columns default sort first;
				elseif table.cols[i].sort and table.cols[i].sort:lower() == "asc" then 
					sortorder = "dsc";
				end
				table.cols[i].sort = sortorder;
				table:SortData();
			end);
			
			row.cols[i] = col;
			local fs = col:CreateFontString(col:GetName().."fs", "OVERLAY", "GameFontHighlightSmall");
			fs:SetAllPoints(col);
			fs:SetPoint("LEFT", col, "LEFT", lrpadding, 0);
			fs:SetPoint("RIGHT", col, "RIGHT", -lrpadding, 0);
			local align = cols[i].align or "LEFT";
			fs:SetJustifyH(align); 
			
			col:SetFontString(fs);
			fs:SetText(cols[i].name);
			fs:SetTextColor(1.0, 1.0, 1.0, 1.0);
			col:SetPushedTextOffset(0,0);
			
			if i > 1 then 
				col:SetPoint("LEFT", row.cols[i-1], "RIGHT", 0, 0);
			else
				col:SetPoint("LEFT", row, "LEFT", 2, 0);
			end
			col:SetHeight(self.rowHeight);
			col:SetWidth(cols[i].width);
			
			local color = cols[i].bgcolor;
			if (color) then 
				local colibg = "col"..i.."bg";
				local bg = self.frame[colibg]; 
				if not bg then 
					bg = self.frame:CreateTexture(nil, "OVERLAY");
					self.frame[colibg] = bg;
				end 
				bg:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 4);
				bg:SetPoint("TOPLEFT", col, "BOTTOMLEFT", 0, -4);
				bg:SetPoint("TOPRIGHT", col, "BOTTOMRIGHT", 0, -4);
				bg:SetTexture(color.r, color.g, color.b, color.a);
			end
		end
		
		self:SetWidth();
	end
	
	local Show = function(self)
		self.frame:Show();
		self.showing = true;
	end
	local Hide = function(self)
		self.frame:Hide();
		self.showing = false;
	end
	
	local SetData = function(self, data)
		self.data = data;
		self:SortData();
	end
		
	local SortData = function(self)
		-- sanity check
		if not(self.sorttable) or (#self.sorttable > #self.data)then 
			self.sorttable = {};
		end
		if #self.sorttable ~= #self.data then
			for i = 1, #self.data do 
				self.sorttable[i] = i;
			end
		end 
		
		-- go on sorting
		local i, sortby = 1, nil;
		while i <= #self.cols and not sortby do
			if self.cols[i].sort then 
				sortby = i;
			end
			i = i + 1;
		end
		if sortby then 
            if self.cols[sortby].sortfirst then
                table.sort(self.sorttable, function(a,b)
				    return self:CompareSort(a, b, self.cols[sortby].sortfirst);
			    end);
            else                
                table.sort(self.sorttable, function(a,b)
                    return self:CompareSort(a, b, sortby);
                end);
            end
		end
		self.filtered = self:DoFilter();
		self:Refresh();
	end
	
	local StringToNumber = function(str)
		if str == "" then 
			return 0;
		else
			return tonumber(str)
		end
	end
	
	local CompareSort = function (self, a, b, sortby)
		local cola, colb = self.data[a].cols[sortby], self.data[b].cols[sortby];
		local a1, b1 = cola.value, colb.value;
		if type(a1) == "function" then 
			a1 = a1(unpack(cola.args or {}));
		end
		if type(b1) == "function" then 
			b1 = b1(unpack(colb.args or {}));
		end
		
		if type(a1) ~= type(b1) then
			local typea, typeb = type(a1), type(b1);
			if typea == "number" and typeb == "string" then 
				if tonumber(typeb) then -- is it a number in a string?
					b1 = StringToNumber(b1); -- "" = 0
				else
					a1 = tostring(a1);
				end
			elseif typea == "string" and typeb == "number" then 
				if tonumber(typea) then -- is it a number in a string?
					a1 = StringToNumber(a1); -- "" = 0
				else
					b1 = tostring(b1);
				end
			end
		end
		
		if a1 == b1 and self.cols[sortby].sortnext then 
			return self:CompareSort(a, b, self.cols[sortby].sortnext);
		else
			local direction = self.cols[sortby].sort or self.cols[sortby].defaultsort or "asc";
			if direction:lower() == "asc" then 		
				return a1 > b1;
			else
				return a1 < b1;
			end
		end
	end
	
	local Filter = function(self, ...)
		return true;
	end
	
	local SetFilter = function(self, Filter)
		self.Filter = Filter;
		self:SortData();
	end
	
	local DoFilter = function(self)
		local result = {};
		for row = 1, #self.data do 
			if self:Filter(self.data[self.sorttable[row]]) then
				table.insert(result, self.sorttable[row]);
			end
		end
		return result;
	end
	
	function ScrollingTable:CreateST(cols, numRows, rowHeight, highlight, parent)
		local st = {};
		local f = CreateFrame("Frame", "ScrollTable"..framecount, parent or UIParent);
		framecount = framecount + 1;
		st.showing = true;
		st.frame = f;
		
		st.Show = Show;
		st.Hide = Hide;
		st.SetDisplayRows = SetDisplayRows;
		st.SetRowHeight = SetRowHeight;
		st.SetHeight = SetHeight;
		st.SetWidth = SetWidth;
		st.SetDisplayCols = SetDisplayCols;
		st.SetData = SetData;
		st.SortData = SortData;
		st.CompareSort = CompareSort;
		
		st.SetFilter = SetFilter;
		st.DoFilter = DoFilter;
		
		st.highlight = highlight or defaulthighlight;
		st.displayRows = numRows or 12;
		st.rowHeight = rowHeight or 15;
		st.cols = cols or {
			{
				["name"] = "Test 1",
			 	["width"] = 50,
			 	["color"] = { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 1.0, ["a"] = 1.0 },
			}, -- [1]
			{ 
				["name"] = "Test 2", 
				["width"] = 50, 
				["align"] = "CENTER",
				["bgcolor"] = { ["r"] = 1.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.2 },
			}, -- [2]
			{ 
				["name"] = "Test 3", 
				["width"] = 50, 
				["align"] = "RIGHT",
				["bgcolor"] = { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.5 },
			}, -- [3]
		};
		st.data = {};
	
		f:SetBackdrop(ScrollPaneBackdrop);
		f:SetBackdropColor(0.1,0.1,0.1);
		f:SetPoint("CENTER",UIParent,"CENTER",0,0);
		
		-- build scroll frame
		local scrollframe = CreateFrame("ScrollFrame", f:GetName().."ScrollFrame", f, "FauxScrollFrameTemplate");
		scrollframe:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0);
		scrollframe:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 0);
		
		st.Refresh = function(self)	
			FauxScrollFrame_Update(scrollframe, #st.filtered, st.displayRows, st.rowHeight);
			local o = FauxScrollFrame_GetOffset(scrollframe);
			st.offset = o;
			
			for i = 1, st.displayRows do
				local row = i + o;	
				if st.rows then
					for col = 1, #st.cols do
						local celldisplay = st.rows[i].cols[col].text;
						if st.data[st.filtered[row]] then
							st.rows[i]:Show();
							local celldata = st.data[st.filtered[row]].cols[col];
                            if type(celldata.userDraw) == "function" then
                                celldata.userDraw( nil, st.rows[i].cols[col], unpack(celldata.args or {celldata.value}) )
							elseif type(celldata.value) == "function" then 
								celldisplay:SetText(celldata.value(unpack(celldata.args or {})) );
							else
								celldisplay:SetText(celldata.value);
							end
							
							local color = celldata.color;
							local colorargs = nil;
							if not color then 
							 	color = st.cols[col].color;
							 	if not color then 
							 		color = st.data[st.filtered[row]].color
							 		if not color then 
							 			color = defaultcolor;
							 		else
							 			colorargs = st.data[st.filtered[row]].colorargs;
							 		end
							 	else
							 		colorargs = st.cols[col].colorargs;
							 	end
							else
								colorargs = celldata.colorargs;
							end	
							if type(color) == "function" then 
								color = color(unpack(colorargs or {}));
							end
							celldisplay:SetTextColor(color.r, color.g, color.b, color.a);						
						else
							st.rows[i]:Hide();
							celldisplay:SetText("");
						end
					end
				end
			end
		end
		
		scrollframe:SetScript("OnVerticalScroll", function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, st.rowHeight, st.Refresh);
		end);
	
		st:SetFilter(Filter);
		st:SetDisplayCols(st.cols);
		st:SetDisplayRows(st.displayRows, st.rowHeight);
		return st;
	end
end