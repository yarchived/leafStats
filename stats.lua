-- pStats by p3lim

local filterNum = 25
local r, g, b = 0, 1, 1
local sorted = true
local filter = true

local function formats(value)
	if(value > 1024) then
		return format('%.1f MiB', value / 1024)
	else
		return format('%.1f KiB', value)
	end
end

local dataobj = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject('leafStats', {
	type = 'data source',
	text = '0 fps 0 ms 0 MiB',
	icon = [[Interface\Icons\inv_misc_rune_01]],
})

function dataobj.OnLeave()
	GameTooltip:SetClampedToScreen(true)
	GameTooltip:Hide()
end

function dataobj.OnEnter(self)
	local down, up, latency = GetNetStats()
	local fps = format('%d fps', floor(GetFramerate()))
	local net = format('%d ms', latency)
	local bandwidthIn, bandwidthOut = down * 1024, up * 1024

	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT', 0, self:GetHeight())
	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine(fps, net, r, g, b, r, g, b)
	GameTooltip:AddLine('\n')

	local addons, entry, total = {}, {}, 0
	UpdateAddOnMemoryUsage()

	for i = 1, GetNumAddOns() do
		if(IsAddOnLoaded(i)) then
			entry = {GetAddOnInfo(i), GetAddOnMemoryUsage(i)}
			total = total + entry[2]
			table.insert(addons, entry)
		end
	end
	
	if sorted then
		table.sort(addons, (function(a, b) return a[2] > b[2] end))
	end

	GameTooltip:AddDoubleLine('Bandwidth in', format('%d B/s', bandwidthIn), r, g, b, r, g, b)
	GameTooltip:AddDoubleLine('Bandwidth out', format('%d B/s', bandwidthOut), r, g, b, r, g, b)
	GameTooltip:AddLine('\n')

	GameTooltip:AddDoubleLine('User Addon Memory Usage:', formats(total), r, g, b, r, g, b)
	GameTooltip:AddDoubleLine('Default UI Memory Usage:', formats(gcinfo() - total), r, g, b, r, g, b)
	GameTooltip:AddDoubleLine('Total Memory Usage:', formats(gcinfo()), r, g, b, r, g, b)
	GameTooltip:AddLine('\n')
	
	if filter then
		for i = 1, filterNum do
			local entry = addons[i]
			if entry then
				GameTooltip:AddDoubleLine(entry[1], formats(entry[2]), 1, 1, 1)
			else
				break
			end
		end
	else
		for i,entry in pairs(addons) do
			GameTooltip:AddDoubleLine(entry[1], formats(entry[2]), 1, 1, 1)
		end
	end
	
	GameTooltip:AddLine('\n')
	GameTooltip:AddDoubleLine('Left-Click', 'Force garbage collection', r, g, b, r, g, b)
	GameTooltip:AddDoubleLine('Right-Click', 'Toggle sorting by memory', r, g, b, r, g, b)
	GameTooltip:AddDoubleLine('Shift + Right-Click', 'Toggle filter (sorting mod only)', r, g, b, r, g, b)
	
	GameTooltip:Show()
end

function dataobj.OnClick(self, button)
	if button=='LeftButton' then
		local collected = collectgarbage('count')
		collectgarbage('collect')
		dataobj.OnEnter(self)
		GameTooltip:AddLine('\n')
		GameTooltip:AddDoubleLine('Garbage Collected:', formats(collected - collectgarbage('count')))
		GameTooltip:Show()
		return
	elseif IsModifierKeyDown() then
		filter = not filter
	else
		sorted = not sorted
	end
	OnEnter(self)
end

local elapsed = 0.8
CreateFrame('Frame'):SetScript('OnUpdate', function(self, al)
	elapsed = elapsed + al
	if elapsed < 1 then return end
	dataobj.text = format('%.0f fps %d ms %s', GetFramerate(),select(3,GetNetStats()), formats(gcinfo()))
	elapsed = 0
end)
