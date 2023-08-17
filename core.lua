-- CONFIG
---------------------------------------------
local level = 0
local addonList = 50
local font = 'Fonts\\FRIZQT__.ttf'
local fontSize = 12
local fontFlag = 'THINOUTLINE'
local textAlign = 'CENTER'
local position = { "CENTER", UIParent, "CENTER", 0, -15 }
local customColor = false
local useShadow = true
local showClock = true
local use12 = false -- ignored if showClock is false.
						

-- CODE ITSELF
---------------------------------------------
local LynStatsDB_local
local events = {}
function events:ADDON_LOADED(...)
	if select(1, ...) == "LynStats" then
		LynStatsDB_local = LynStatsDB
		if not LynStatsDB_local then -- addon loaded for first time
			LynStatsDB_local = {}
			print("LynStats load default")
			LynStatsDB_local["point"] = "CENTER"
			LynStatsDB_local["relativePoint"] = "CENTER"
			LynStatsDB_local["xOffset"] = 0
			LynStatsDB_local["yOffset"] = 0
		end

		-- safe check all saved variables are there (in case older version was loaded)
		if not LynStatsDB_local["point"] then LynStatsDB_local["point"] = "CENTER" end
		if not LynStatsDB_local["relativePoint"] then LynStatsDB_local["relativePoint"] = "CENTER" end
		if not LynStatsDB_local["xOffset"] then LynStatsDB_local["xOffset"] = 0 end
		if not LynStatsDB_local["yOffset"] then LynStatsDB_local["yOffset"] = 0 end

		addon:UnregisterEvent("ADDON_LOADED")
		print("LynStats Loaded")
	end
end

--- gets executed once all ui information is available (like honor etc)
function events:PLAYER_ENTERING_WORLD()
    addon:new()
    addon:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

--- save variables to SavedVariables
function events:PLAYER_LOGOUT()
	LynStatsDB = LynStatsDB_local
end

local StatsFrame = CreateFrame('Frame', 'LynStats', UIParent)

local color
if customColor then
	color = { r = 0, g = 1, b = 0.7 }
else
	local _, class = UnitClass("player")
	color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
end

local gradientColor = {
    0, 1, 0,
    1, 1, 0,
    1, 0, 0
}

local function memFormat(number)
	if number > 1024 then
		return string.format("%.2f mb", (number / 1024))
	else
		return string.format("%.1f kb", floor(number))
	end
end

local function numFormat(v)
	if v > 1E10 then
		return (floor(v/1E9)).."b"
	elseif v > 1E9 then
		return (floor((v/1E9)*10)/10).."b"
	elseif v > 1E7 then
		return (floor(v/1E6)).."m"
	elseif v > 1E6 then
		return (floor((v/1E6)*10)/10).."m"
	elseif v > 1E4 then
		return (floor(v/1E3)).."k"
	elseif v > 1E3 then
		return (floor((v/1E3)*10)/10).."k"
	else
		return v
	end
end

-- http://www.wowwiki.com/ColorGradient
local function ColorGradient(perc, ...)
    if (perc > 1) then
        local r, g, b = select(select('#', ...) - 2, ...) return r, g, b
    elseif (perc < 0) then
        local r, g, b = ... return r, g, b
    end

    local num = select('#', ...) / 3

    local segment, relperc = math.modf(perc*(num-1))
    local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

    return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function RGBGradient(num)
    local r, g, b = ColorGradient(num, unpack(gradientColor))
    return r, g, b
end

local function RGBToHex(r, g, b)
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    return string.format('|cff%02x%02x%02x', r*255, g*255, b*255)
end

local function addonCompare(a, b)
	return a.memory > b.memory
end

local function clearGarbage()
	UpdateAddOnMemoryUsage()
	local before = gcinfo()
	collectgarbage()
	UpdateAddOnMemoryUsage()
	local after = gcinfo()
	print("|c0000ddffCleaned:|r "..memFormat(before-after))
end
local function OnDragStart(self)
    if( IsAltKeyDown() ) then
        self.isMoving = true
        self:StartMoving()
    end
end

local function OnDragStop(self)
    if( self.isMoving ) then
        self.isMoving = nil
        self:StopMovingOrSizing()
    end
	local point, _, relativePoint, xOfs, yOfs = self:GetPoint()


end

	StatsFrame:ClearAllPoints()
	StatsFrame:SetMovable(true)
	StatsFrame:EnableMouse(true)
	StatsFrame:SetClampedToScreen(true)
	StatsFrame:RegisterForDrag("LeftButton")
	StatsFrame:SetScript("OnDragStart", OnDragStart)
	StatsFrame:SetScript("OnDragStop", OnDragStop)
	
	
	

	
	StatsFrame:SetScript("OnUpdate", StatsFrame.update)
	StatsFrame:SetScript("OnEnter", StatsFrame.enter)
	StatsFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
StatsFrame:SetScript("OnMouseDown", function()
	clearGarbage()
end)
local function getFPS()
	return "|c00ffffff" .. floor(GetFramerate()) .. "|r fps"
end

local function getLatencyWorldRaw()
	return select(4, GetNetStats())
end

local function getLatencyWorld()
	return "|c00ffffff" .. getLatencyWorldRaw() .. "|r ms"
end

local function getLatencyRaw()
	return select(3, GetNetStats())
end

local function getLatency()
	return "|c00ffffff" .. getLatencyRaw() .. "|r ms"
end


local function getMail()
	hasmail = (HasNewMail() or 0);
		if hasmail > 0 then
			return "|c00ff00ffMail!|r"
		else
			return ""
		end
end

local function getTime()
	if use12 == true then
		local t = date("%I:%M")
		local ampm = date("%p")
		return "|c00ffffff"..t.."|r "..strlower(ampm)
	else
		local t = date("%H:%M")
		return "|c00ffffff"..t.."|r"
	end
end


local function getArenaPoint()
	if UnitLevel("player") < MAX_PLAYER_LEVEL then
		return ""
	else
		return "|c00ffffff" .. GetArenaCurrency() .. "|r Arena P."
	end
end


local function getVH()
	return "|c00ffffff" .. GetHonorCurrency() .. "|r Honor"
end

local function getXP()
	if UnitLevel("player") < MAX_PLAYER_LEVEL then
		local XP = UnitXP("player")
		local XPMax = UnitXPMax("player")
		return "|c00ffffff" .. floor(XPMax - XP).. "|r xp"
	else
		return ""
	end
end


local function getDURABILITY()
    local dFrame = CreateFrame("Frame", "durability", UIParent)
    dFrame:SetSize(12, 14)
    dFrame:SetPoint("LEFT", StatsFrame, "LEFT", -15, 0)
    dFrame.texture = dFrame:CreateTexture(nil, "OVERLAY")
    dFrame.texture:SetAllPoints(dFrame)
    dFrame.texture:SetTexture("Interface\\Icons\\Trade_BlackSmithing")
    dFrame:Show()

    local durability, percentage, currDurability, maxDurability
    local lowestCurr, lowestVal, totalCurr, totalValue, totalMax = 500, 0, 0, 0, 100
    for i = 1, 18 do
        currDurability, maxDurability  = GetInventoryItemDurability(i)
        if currDurability and maxDurability  then
            percentage = floor(100 * currDurability / maxDurability + 0.5)

            if (percentage < totalMax) then
                totalMax = percentage
            end
            if (currDurability < lowestCurr) then
                lowestCurr = currDurability
                lowestVal = maxDurability 
            end
            totalCurr = totalCurr + currDurability
            totalValue = totalValue + maxDurability
        end
    end
    
    if totalValue == 0 then durability = "N/A" else durability = floor(totalCurr * 100 / totalValue) end
    local text = ""
    if type(durability) == "number" then
        text = ("|c00ffffff" .. durability .. "|r %")
    end
    return text
end


local function getHONORWIN()
    local Honor = Honor
    local HonorPerHourSession = floor(3600 * Honor / Time)
    local HonorPerHour = floor(3600 * GetHonorLastHour() / min(Time,3600))
    local TimeTotal = floor(Time / 60)
    local TimeHours = floor(TimeTotal / 60)
    local TimeElapsed = TimeHours .. "h" .. TimeTotal - TimeHours * 60 .. "m"
    
    return "|c00ffffff" .. floor(Honor) .. "|r Honor today"
end	


local function getLAYER()
    return "|c00ffffff" .. level .. "|r Layer"
end


local function addonTooltip(self)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	local blizz = collectgarbage("count")
	local addons = {}
	local enry, memory
	local total = 0
	local nr = 0
	UpdateAddOnMemoryUsage()
	GameTooltip:AddLine("AddOns", color.r, color.g, color.b)
	--GameTooltip:AddLine(" ")
	for i=1, GetNumAddOns(), 1 do
		if (GetAddOnMemoryUsage(i) > 0 ) then
			memory = GetAddOnMemoryUsage(i)
			entry = {name = GetAddOnInfo(i), memory = memory}
			table.insert(addons, entry)
			total = total + memory
		end
	end
	table.sort(addons, addonCompare)
	for _, entry in pairs(addons) do
		if nr < addonList then
			GameTooltip:AddDoubleLine(entry.name, memFormat(entry.memory), 1, 1, 1, RGBGradient(entry.memory / 800))
			nr = nr+1
		end
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Total", memFormat(total), 1, 1, 1, RGBGradient(total / (1024*10)))
	GameTooltip:AddDoubleLine("Total incl. Blizzard", memFormat(blizz), 1, 1, 1, RGBGradient(blizz / (1024*10)))
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Network", color.r, color.g, color.b)
	--GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Home", getLatencyRaw().." ms", 1, 1, 1, RGBGradient(getLatencyRaw()/ 100))
	GameTooltip:Show()
end

StatsFrame:SetScript("OnEnter", function()
	addonTooltip(StatsFrame)
end)
StatsFrame:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

StatsFrame:SetPoint(unpack(position))
StatsFrame:SetWidth(50)
StatsFrame:SetHeight(fontSize)

StatsFrame.text = StatsFrame:CreateFontString(nil, 'BACKGROUND')
StatsFrame.text:SetPoint(textAlign, StatsFrame)
StatsFrame.text:SetFont(font, fontSize, fontFlag)
if useShadow then
	StatsFrame.text:SetShadowOffset(1, -1)
	StatsFrame.text:SetShadowColor(0, 0, 0)
end
StatsFrame.text:SetTextColor(color.r, color.g, color.b)

local lastUpdate = 0

local function update(self,elapsed)
	lastUpdate = lastUpdate + elapsed
	if lastUpdate > 1 then
		lastUpdate = 0
		if showClock == true then
			StatsFrame.text:SetText(getDURABILITY().."   "..getFPS().."   "..getLatency().."   "..getMail().." "..getVH().."   "..getArenaPoint().."  "..getXP())-- .." "..getLAYER()--)
		else
			StatsFrame.text:SetText(getFPS().."  "..getLatency().."  "..getMail())
		end
		self:SetWidth(StatsFrame.text:GetStringWidth())
		self:SetHeight(StatsFrame.text:GetStringHeight())
	end
end



StatsFrame:SetScript("OnEvent", function(self, event)
    if(event=="PLAYER_LOGIN") then
        self:SetScript("OnUpdate", update)
    elseif (event == "PLAYER_TARGET_CHANGED") then
        if (UnitExists("target") and not UnitIsPlayer("target")) then
            level = select(5, strsplit("-", UnitGUID("target")))
        end
    end
end)
StatsFrame:RegisterEvent("PLAYER_LOGIN")
StatsFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

