local addonName, Ven = ...

local GetMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local currentVersionStr = GetMeta(addonName, "Version") or "1.0.0"

local function ParseVersion(vStr)
	if not vStr then
		return 0
	end
	local v1, v2, v3 = string.match(tostring(vStr), "(%d+)%.?(%d*)%.?(%d*)")
	return (tonumber(v1) or 0) * 10000 + (tonumber(v2) or 0) * 100 + (tonumber(v3) or 0)
end

local currentVersionNum = ParseVersion(currentVersionStr)

local prefix = "VEN_VER"
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_CHANNEL")

local lastWarningTime = 0
local warningCooldown = 20 * 60

local function InitUpdateCheck()
	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		C_ChatInfo.RegisterAddonMessagePrefix(prefix)
	else
		RegisterAddonMessagePrefix(prefix)
	end
end

local function BroadcastVersion()
	local function Send(channel)
		if C_ChatInfo and C_ChatInfo.SendAddonMessage then
			C_ChatInfo.SendAddonMessage(prefix, currentVersionStr, channel)
		else
			SendAddonMessage(prefix, currentVersionStr, channel)
		end
	end

	if IsInGuild() then
		Send("GUILD")
	end

	if IsInRaid() then
		Send("RAID")
	elseif IsInGroup() then
		Send("PARTY")
	end
end

local lastChannelBroadcast = 0
function Ven.BroadcastVersionToChannel()
	local now = GetTime()
	if now - lastChannelBroadcast < 3600 then return end
	lastChannelBroadcast = now
	
	local id = GetChannelName("VenNetCom")
	if id and id > 0 then
		SendChatMessage(prefix .. "~" .. currentVersionStr, "CHANNEL", nil, id)
	end
end

f:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		InitUpdateCheck()
		C_Timer.After(60, BroadcastVersion)
		C_Timer.NewTicker(3600, BroadcastVersion)
	elseif event == "CHAT_MSG_ADDON" then
		local msgPrefix, msg, channel, sender = ...
		if msgPrefix == prefix then
			local sName = string.match(sender, "([^%-]+)")
			if sName == UnitName("player") then
				return
			end

			local receivedVerNum = ParseVersion(msg)

			if receivedVerNum > currentVersionNum then
				local now = GetTime()
				if (now - lastWarningTime) > warningCooldown then
					lastWarningTime = now
					print(
						"|cFFFF0000[Vendetta]|r |cFFFFFF00A new update is available (v"
							.. msg
							.. "). Please update your addon!|r"
					)
				end
			end
		end
	elseif event == "CHAT_MSG_CHANNEL" then
		local msg, sender = ...
		if string.find(msg, "^" .. prefix .. "~") then
			local _, ver = strsplit("~", msg)
			if ver then
				local sName = string.match(sender, "([^%-]+)")
				if sName == UnitName("player") then
					return
				end

				local receivedVerNum = ParseVersion(ver)

				if receivedVerNum > currentVersionNum then
					local now = GetTime()
					if (now - lastWarningTime) > warningCooldown then
						lastWarningTime = now
						print(
							"|cFFFF0000[Vendetta]|r |cFFFFFF00A new update is available (v"
								.. ver
								.. "). Please update your addon!|r"
						)
					end
				end
			end
		end
	end
end)
