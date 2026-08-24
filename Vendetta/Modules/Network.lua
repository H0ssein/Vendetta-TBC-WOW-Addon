local addonName, Ven = ...

local prefix = "VEN_NET"
local chanName = "VenNetCom"
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD"); f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_CHANNEL"); f:RegisterEvent("CHAT_MSG_SYSTEM"); f:RegisterEvent("CHAT_MSG_WHISPER") 

Ven.recentSystemWhispers = {}; Ven.SyncQueue = {} 

local C_MAP = {WARRIOR=1, PALADIN=2, HUNTER=3, ROGUE=4, PRIEST=5, SHAMAN=6, MAGE=7, WARLOCK=8, DRUID=9}
local C_REV = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}
local R_MAP = {Human=1, Dwarf=2, NightElf=3, Gnome=4, Draenei=5, Orc=6, Scourge=7, Tauren=8, Troll=9, BloodElf=10}
local R_REV = {"Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Orc", "Scourge", "Tauren", "Troll", "BloodElf"}
local F_MAP = {Alliance=1, Horde=2}; local F_REV = {"Alliance", "Horde"}

local function PackPlayer(name, data, isBountyType)
    local fac, lvl, cls, rce = F_MAP[data.faction] or 0, tonumber(data.level) or 0, C_MAP[data.classFile] or 0, R_MAP[data.race] or 0
    local noteToSend = isBountyType and data.bountyNote or data.note or ""
    local note = string.sub(string.gsub(noteToSend, "[%^:~]", ""), 1, 15)
    return string.format("%s:%d:%d:%d:%d:%s", name, fac, lvl, cls, rce, note)
end

local function UnpackPlayer(str)
    local name, fac, lvl, cls, rce, note = strsplit(":", str)
    fac = tonumber(fac) or 0; lvl = tonumber(lvl) or 0; cls = tonumber(cls) or 0; rce = tonumber(rce) or 0
    return name, F_REV[fac] or "?", (lvl > 0 and lvl) or "?", C_REV[cls] or "?", R_REV[rce] or "?", note or ""
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg)
    local now = GetTime()
    for target, timeSent in pairs(Ven.recentSystemWhispers) do
        if now - timeSent < 5 then if string.find(string.lower(msg), target) then return true end else Ven.recentSystemWhispers[target] = nil end
    end
    return false
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg) if string.find(msg, "VEN_SYS_MSG") then return true end; return false end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(self, event, msg) if string.find(msg, "VEN_SYS_MSG") then return true end; return false end)

local function HideAutoReplies(self, event, msg, sender)
    if not sender then return false end
    local s = string.lower(string.match(sender, "([^%-]+)") or sender)
    if Ven.recentSystemWhispers[s] and (GetTime() - Ven.recentSystemWhispers[s] < 5) then return true end; return false
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_AFK", HideAutoReplies); ChatFrame_AddMessageEventFilter("CHAT_MSG_DND", HideAutoReplies)

function Ven.ProcessPendingBounties()
    if not Ven.PendingBounties or #Ven.PendingBounties == 0 then return end
    local _, myClass = UnitClass("player")
    for i, data in ipairs(Ven.PendingBounties) do
        local count = data.count or 1
        local msg = "VEN_SYS_MSG~KILL_REPORT~" .. data.target .. "~" .. (data.timestamp or time()) .. "~" .. (data.loc or "Unknown") .. "~" .. tostring(myClass) .. "~" .. tostring(count)
        Ven.recentSystemWhispers[string.lower(data.owner)] = GetTime()
        SendChatMessage(msg, "WHISPER", nil, data.owner)
    end
end

local function CleanupBounties()
    local now, db, wl = time(), Ven.InitHeroDB(), string.lower(Ven.InitHeroDB().whitelist or "")
    local function CleanBoard(board, checkWhitelist)
        if not board then return end
        for enemy, owners in pairs(board) do
            for owner, data in pairs(owners) do
                local isWhitelisted = false
                if checkWhitelist then
                    for wName in string.gmatch(wl, "([^,%s]+)") do if wName == string.lower(owner) then isWhitelisted = true; break end end
                else
                    isWhitelisted = true 
                end
                local ts = type(data) == "table" and data.time or tonumber(data) or 0
                if not isWhitelisted and (now - ts > 86400) then owners[owner] = nil end
            end
            if not next(owners) then board[enemy] = nil; if Ven.netCache then Ven.netCache[enemy] = nil end end
        end
    end
    CleanBoard(Ven.BountyBoard, false); CleanBoard(Ven.WantedBoard, true)
end

function Ven.QueueSyncMessages(destType)
    local db = Ven.InitHeroDB(); if not db.enableNetwork or UnitLevel("player") < 20 then return end
    local msgsB, msgsW = {}, {}; table.insert(msgsB, "VEN~CLEAR_BOUNTY"); table.insert(msgsW, "VEN~CLEAR_WANTED")
    local curB, curW = "", ""; local _, myClass = UnitClass("player")
    
    for name, data in pairs(db) do
        if type(data) == "table" then
            if data.isBounty then
                local packed = PackPlayer(name, data, true)
                if string.len(curB) + string.len(packed) + 1 > 200 then table.insert(msgsB, "VEN~W_SYNC_B~" .. (myClass or "?") .. "~" .. curB); curB = packed
                else curB = curB == "" and packed or curB .. "^" .. packed end
            end
            if data.isWanted then
                local packed = PackPlayer(name, data, false)
                if string.len(curW) + string.len(packed) + 1 > 200 then table.insert(msgsW, "VEN~W_SYNC_W~" .. (myClass or "?") .. "~" .. curW); curW = packed
                else curW = curW == "" and packed or curW .. "^" .. packed end
            end
        end
    end
    if curB ~= "" then table.insert(msgsB, "VEN~W_SYNC_B~" .. (myClass or "?") .. "~" .. curB) end
    if curW ~= "" then table.insert(msgsW, "VEN~W_SYNC_W~" .. (myClass or "?") .. "~" .. curW) end
    
    Ven.SyncQueue = Ven.SyncQueue or {}
    if destType == "CHANNEL" then
        local id = GetChannelName(chanName)
        if id > 0 then for _, m in ipairs(msgsB) do SendChatMessage(m, "CHANNEL", nil, id) end end
    else
        for _, m in ipairs(msgsB) do table.insert(Ven.SyncQueue, {dest = destType, msg = m}) end
    end
    
    local wl = string.lower(db.whitelist or "")
    for wName in string.gmatch(wl, "([^,%s]+)") do
        for _, m in ipairs(msgsW) do table.insert(Ven.SyncQueue, {dest = "WHISPER", target = wName, msg = m}) end
    end
end

local function InitNet()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(prefix) else RegisterAddonMessagePrefix(prefix) end
    local rName = GetRealmName() or "Unknown"; VendettaDB[rName] = VendettaDB[rName] or {}
    VendettaDB[rName].NetworkBounties = VendettaDB[rName].NetworkBounties or {}; Ven.BountyBoard = VendettaDB[rName].NetworkBounties
    VendettaDB[rName].NetworkWanteds = VendettaDB[rName].NetworkWanteds or {}; Ven.WantedBoard = VendettaDB[rName].NetworkWanteds
    VendettaDB[rName].NetworkCache = VendettaDB[rName].NetworkCache or {}; Ven.netCache = VendettaDB[rName].NetworkCache
    VendettaDB[rName].SenderClasses = VendettaDB[rName].SenderClasses or {}; Ven.SenderClasses = VendettaDB[rName].SenderClasses
    VendettaDB[rName].PendingBounties = VendettaDB[rName].PendingBounties or {}; Ven.PendingBounties = VendettaDB[rName].PendingBounties
    Ven.playerCache = Ven.playerCache or {}; for k, v in pairs(Ven.netCache) do Ven.playerCache[k] = v end

    local db = Ven.InitHeroDB()
    if not db.enableNetwork then return end
    local id = GetChannelName(chanName)
    if id == 0 then JoinChannelByName(chanName); C_Timer.After(2, function() RemoveChatWindowChannel(1, chanName) end) end
    
    C_Timer.NewTicker(3600, CleanupBounties); C_Timer.NewTicker(1800, Ven.ProcessPendingBounties) 
    C_Timer.NewTicker(0.8, function()
        if Ven.SyncQueue and #Ven.SyncQueue > 0 then
            local q = table.remove(Ven.SyncQueue, 1)
            if q.dest == "WHISPER" and q.target then
                local func = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
                func(prefix, q.msg, "WHISPER", q.target)
            elseif q.dest == "ADDON" then
                local func = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
                if IsInGuild() then func(prefix, q.msg, "GUILD") end
                if IsInRaid() then func(prefix, q.msg, "RAID") elseif IsInGroup() then func(prefix, q.msg, "PARTY") end
            end
        end
    end)
    CleanupBounties()
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then C_Timer.After(5, InitNet); C_Timer.After(10, Ven.ProcessPendingBounties)
    elseif event == "CHAT_MSG_SYSTEM" then
        local msg = ...
        if string.find(msg, "has come online") then
            if Ven.PendingBounties and #Ven.PendingBounties > 0 then C_Timer.After(30, function() if Ven.ProcessPendingBounties then Ven.ProcessPendingBounties() end end) end
        end
    elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        if string.find(msg, "VEN_SYS_MSG") then
            local sName = string.match(sender, "([^%-]+)") or sender
            local parts = {strsplit("~", msg)}
            if parts[2] == "SEEN_WHISPER" then
                local p1, p2, hunterClass = parts[3], parts[4], parts[5]
                local db = Ven.InitHeroDB()
                if db[p1] and (db[p1].isWanted or db[p1].isBounty) then
                    db[p1].lastSeenLoc = p2; db[p1].lastSeenTime = time()
                    
                    Ven.seenAlertCD = Ven.seenAlertCD or {}; Ven.seenZoneRecord = Ven.seenZoneRecord or {}
                    local t = GetTime()
                    local timeSinceAlert = t - (Ven.seenAlertCD[p1] or 0)
                    local pureZone = string.gsub(p2, " %(Layer [^%)]+%)$", "")
                    local lastZone = Ven.seenZoneRecord[p1] or ""
                    
                    if timeSinceAlert > 300 or pureZone ~= lastZone then
                        Ven.seenAlertCD[p1] = t
                        Ven.seenZoneRecord[p1] = pureZone
                        
                        local cColor = Ven.GetClassColor(hunterClass) or "|cFF00FF00"
                        local hunterLink = "|Hplayer:"..sName.."|h" .. cColor .. "[" .. sName .. "]|r|h"
                        if db[p1].isBounty then
                            print("|cFFFFFF00[Vendetta]|r Bounty Hunter " .. hunterLink .. " has spotted your BOUNTY target: |cFFFF0000" .. p1 .. "|r at " .. p2 .. ".")
                            local sIdx = db.bountySpottedSoundIdx or 4
                            if Ven.soundList[sIdx] then Ven.AlertPlaySound(Ven.soundList[sIdx].id, db.bountySpottedForceBG) end
                        else
                            print("|cFFFFFF00[Vendetta]|r Ally " .. hunterLink .. " has spotted your WANTED target: |cFFFF0000" .. p1 .. "|r at " .. p2 .. ".")
                            local sIdx = db.wantedSoundIdx or 3
                            if Ven.soundList[sIdx] then Ven.AlertPlaySound(Ven.soundList[sIdx].id, db.wantedForceBG) end
                        end
                    end
                    if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
                end
            elseif parts[2] == "KILL_REPORT" then
                local target, kTimestamp, loc, hunterClass, killCount = parts[3], tonumber(parts[4]) or time(), parts[5], parts[6], tonumber(parts[7]) or 1
                local db = Ven.InitHeroDB(); local ackMsg = "VEN_SYS_MSG~ACK_KILL~" .. target
                Ven.recentSystemWhispers[string.lower(sName)] = GetTime(); SendChatMessage(ackMsg, "WHISPER", nil, sName)
                
                local timeStr = Ven.FormatTimeStr(kTimestamp, "relative")
                local suffixStr = timeStr ~= "" and " (Killed" .. timeStr .. ")" or ""
                local cColor = Ven.GetClassColor(hunterClass) or "|cFF00FF00"
                local hunterLink = "|Hplayer:"..sName.."|h" .. cColor .. "[" .. sName .. "]|r|h"
                local targetType = (db[target] and db[target].isBounty) and "BOUNTY" or "WANTED"
                
                if killCount > 1 then print("|cFF00FFFF[Vendetta]|r Hunter " .. hunterLink .. " has executed your " .. targetType .. " target: |cFFFF0000" .. target .. "|r |cFFFF0000" .. killCount .. " times|r! at " .. (loc or "Unknown") .. suffixStr .. ".")
                else print("|cFF00FFFF[Vendetta]|r Hunter " .. hunterLink .. " has executed your " .. targetType .. " target: |cFFFF0000" .. target .. "|r at " .. (loc or "Unknown") .. suffixStr .. ".") end
                
                local kIdx = (db[target] and db[target].isBounty) and (db.bountyKillSoundIdx or 3) or (db.wantedKillSoundIdx or 3)
                local kForce = (db[target] and db[target].isBounty) and (db.bountyKillForceBG or false) or (db.wantedKillForceBG or false)
                if kIdx == 2 then local rIdx = math.random(3, #Ven.killSoundList); Ven.AlertPlaySound(Ven.killSoundList[rIdx].id, kForce)
                elseif kIdx > 2 then Ven.AlertPlaySound(Ven.killSoundList[kIdx] and Ven.killSoundList[kIdx].id, kForce) end
            elseif parts[2] == "ACK_KILL" then
                local target = parts[3]
                if Ven.PendingBounties then
                    for i = #Ven.PendingBounties, 1, -1 do
                        if string.lower(Ven.PendingBounties[i].owner) == string.lower(sName) and Ven.PendingBounties[i].target == target then
                            local pData = Ven.PendingBounties[i]; local kCount = pData.count or 1
                            local timeStr = Ven.FormatTimeStr(pData.timestamp or time(), "relative")
                            local oColor = Ven.GetClassColor(Ven.SenderClasses and Ven.SenderClasses[sName]) or "|cFF00FF00"
                            local ownerLink = "|Hplayer:"..sName.."|h" .. oColor .. "[" .. sName .. "]|r|h"
                            if kCount > 1 then print("|cFF00FFFF[Vendetta]|r Delivery Confirmed! Execution report for |cFFFF0000" .. target .. "|r (|cFFFF0000" .. kCount .. " kills|r)" .. timeStr .. " was successfully received by " .. ownerLink .. ".")
                            else print("|cFF00FFFF[Vendetta]|r Delivery Confirmed! Execution report for |cFFFF0000" .. target .. "|r" .. timeStr .. " was successfully received by " .. ownerLink .. ".") end
                            table.remove(Ven.PendingBounties, i)
                        end
                    end
                end
            end
        end
    elseif event == "CHAT_MSG_ADDON" then
        local msgPrefix, msg, channel, sender = ...
        if msgPrefix == prefix then
            local sName = string.match(sender, "([^%-]+)"); if sName == UnitName("player") then return end
            local parts = {strsplit("~", msg)}; if parts[1] == "VEN" then Ven.HandleNetworkMessage(parts[2], sName, parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]) end
        end
    elseif event == "CHAT_MSG_CHANNEL" then
        local msg, sender, _, _, _, _, _, _, channelBaseName = ...
        if channelBaseName and string.lower(channelBaseName) == string.lower(chanName) then
            local sName = string.match(sender, "([^%-]+)"); if sName == UnitName("player") then return end
            local parts = {strsplit("~", msg)}; if parts[1] == "VEN" then Ven.HandleNetworkMessage(parts[2], sName, parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]) end
        end
    end
end)

function Ven.HandleNetworkMessage(cmd, sender, p1, p2, p3, p4, p5, p6, p7, p8)
    local db = Ven.InitHeroDB(); if not db.enableNetwork then return end
    local isWhitelisted = false; local wl = string.lower(db.whitelist or "")
    for wName in string.gmatch(wl, "([^,%s]+)") do if wName == string.lower(sender) then isWhitelisted = true; break end end

    if cmd == "CLEAR_BOUNTY" then
        if Ven.BountyBoard then
            for enemy, owners in pairs(Ven.BountyBoard) do
                owners[sender] = nil; if not next(owners) then Ven.BountyBoard[enemy] = nil; if Ven.netCache then Ven.netCache[enemy] = nil end end
            end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
    elseif cmd == "CLEAR_WANTED" and isWhitelisted then
        if Ven.WantedBoard then
            for enemy, owners in pairs(Ven.WantedBoard) do
                owners[sender] = nil; if not next(owners) then Ven.WantedBoard[enemy] = nil; if Ven.netCache then Ven.netCache[enemy] = nil end end
            end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
    elseif cmd == "W_SYNC_B" and db.huntMode then
        local senderClass = p1; local packedData = p2; if not packedData then return end
        Ven.SenderClasses = Ven.SenderClasses or {}; if senderClass and senderClass ~= "?" then Ven.SenderClasses[sender] = senderClass end
        local players = {strsplit("^", packedData)}; local myFac = UnitFactionGroup("player")
        for _, pStr in ipairs(players) do
            local tName, tFac, tLvl, tCls, tRce, tNote = UnpackPlayer(pStr)
            if tName and tName ~= "" and tFac ~= myFac then
                Ven.BountyBoard[tName] = Ven.BountyBoard[tName] or {}; Ven.BountyBoard[tName][sender] = {time=time(), note=tNote}
                Ven.playerCache[tName] = Ven.playerCache[tName] or {}
                if tFac ~= "?" then Ven.playerCache[tName].faction = tFac end; if tLvl ~= "?" then Ven.playerCache[tName].level = tLvl end
                if tCls ~= "?" then Ven.playerCache[tName].classFile = tCls end; if tRce ~= "?" then Ven.playerCache[tName].race = tRce end
                if Ven.netCache then Ven.netCache[tName] = Ven.playerCache[tName] end
            end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
    elseif cmd == "W_SYNC_W" and isWhitelisted then
        local senderClass = p1; local packedData = p2; if not packedData then return end
        Ven.SenderClasses = Ven.SenderClasses or {}; if senderClass and senderClass ~= "?" then Ven.SenderClasses[sender] = senderClass end
        local players = {strsplit("^", packedData)}; local myFac = UnitFactionGroup("player")
        for _, pStr in ipairs(players) do
            local tName, tFac, tLvl, tCls, tRce, tNote = UnpackPlayer(pStr)
            if tName and tName ~= "" and tFac ~= myFac then
                Ven.WantedBoard[tName] = Ven.WantedBoard[tName] or {}; Ven.WantedBoard[tName][sender] = {time=time(), note=tNote}
                Ven.playerCache[tName] = Ven.playerCache[tName] or {}
                if tFac ~= "?" then Ven.playerCache[tName].faction = tFac end; if tLvl ~= "?" then Ven.playerCache[tName].level = tLvl end
                if tCls ~= "?" then Ven.playerCache[tName].classFile = tCls end; if tRce ~= "?" then Ven.playerCache[tName].race = tRce end
                if Ven.netCache then Ven.netCache[tName] = Ven.playerCache[tName] end
            end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
    elseif cmd == "UNWANTED" then
        if Ven.WantedBoard and Ven.WantedBoard[p1] then 
            Ven.WantedBoard[p1][sender] = nil; if not next(Ven.WantedBoard[p1]) then Ven.WantedBoard[p1] = nil; if Ven.netCache then Ven.netCache[p1] = nil end end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
    elseif cmd == "UNBOUNTY" then
        if Ven.BountyBoard and Ven.BountyBoard[p1] then 
            Ven.BountyBoard[p1][sender] = nil; if not next(Ven.BountyBoard[p1]) then Ven.BountyBoard[p1] = nil; if Ven.netCache then Ven.netCache[p1] = nil end end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
    elseif cmd == "BOUNTY" and db.huntMode then
        local myFac = UnitFactionGroup("player"); if p2 ~= myFac then 
            Ven.BountyBoard[p1] = Ven.BountyBoard[p1] or {}; Ven.BountyBoard[p1][sender] = {time=time(), note=p6}
            Ven.playerCache[p1] = Ven.playerCache[p1] or {}
            if p2 and p2 ~= "?" then Ven.playerCache[p1].faction = p2 end; if p3 and p3 ~= "?" then Ven.playerCache[p1].level = tonumber(p3) or p3 end
            if p4 and p4 ~= "?" then Ven.playerCache[p1].classFile = p4 end; if p5 and p5 ~= "?" then Ven.playerCache[p1].race = p5 end
            if Ven.netCache then Ven.netCache[p1] = Ven.playerCache[p1] end
            Ven.SenderClasses = Ven.SenderClasses or {}; if p7 and p7 ~= "?" then Ven.SenderClasses[sender] = p7 end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
    elseif cmd == "WANTED" and isWhitelisted then
        local myFac = UnitFactionGroup("player"); if p2 ~= myFac then 
            Ven.WantedBoard[p1] = Ven.WantedBoard[p1] or {}; Ven.WantedBoard[p1][sender] = {time=time(), note=p6}
            Ven.playerCache[p1] = Ven.playerCache[p1] or {}
            if p2 and p2 ~= "?" then Ven.playerCache[p1].faction = p2 end; if p3 and p3 ~= "?" then Ven.playerCache[p1].level = tonumber(p3) or p3 end
            if p4 and p4 ~= "?" then Ven.playerCache[p1].classFile = p4 end; if p5 and p5 ~= "?" then Ven.playerCache[p1].race = p5 end
            if Ven.netCache then Ven.netCache[p1] = Ven.playerCache[p1] end
            Ven.SenderClasses = Ven.SenderClasses or {}; if p7 and p7 ~= "?" then Ven.SenderClasses[sender] = p7 end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
    elseif cmd == "SEEN" then
        if db[p1] and (db[p1].isWanted or db[p1].isBounty) then
            local loc = p2; if p3 and p3 ~= "" and p3 ~= p2 then loc = loc .. " - " .. p3 end
            if p4 and p4 ~= "" and p4 ~= "0" then loc = loc .. " (Layer " .. p4 .. ")" end
            db[p1].lastSeenLoc = loc; db[p1].lastSeenTime = time()
            if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
        end
    end
end

function Ven.Broadcast(cmd, p1, p2, p3, p4, p5, p6, p7, p8)
    local db = Ven.InitHeroDB(); if not db.enableNetwork then return end
    local msg = "VEN~"..cmd
    if p1 then msg = msg .. "~" .. tostring(p1) end; if p2 then msg = msg .. "~" .. tostring(p2) end
    if p3 then msg = msg .. "~" .. tostring(p3) end; if p4 then msg = msg .. "~" .. tostring(p4) end
    if p5 then msg = msg .. "~" .. tostring(p5) end; if p6 then msg = msg .. "~" .. tostring(p6) end
    if p7 then msg = msg .. "~" .. tostring(p7) end; if p8 then msg = msg .. "~" .. tostring(p8) end
    
    if cmd == "WANTED" or cmd == "UNWANTED" then
        local wl = string.lower(db.whitelist or "")
        for wName in string.gmatch(wl, "([^,%s]+)") do
            if C_ChatInfo and C_ChatInfo.SendAddonMessage then C_ChatInfo.SendAddonMessage(prefix, msg, "WHISPER", wName) else SendAddonMessage(prefix, msg, "WHISPER", wName) end
        end
    else
        local function Send(channel) if C_ChatInfo and C_ChatInfo.SendAddonMessage then C_ChatInfo.SendAddonMessage(prefix, msg, channel) else SendAddonMessage(prefix, msg, channel) end end
        if IsInGuild() then Send("GUILD") end; if IsInRaid() then Send("RAID") elseif IsInGroup() then Send("PARTY") end
    end
end

function Ven.ManualChannelSync()
    local db = Ven.InitHeroDB(); if not db.enableNetwork or UnitLevel("player") < 20 then return end
    Ven.lastChannelSync = Ven.lastChannelSync or 0; if GetTime() - Ven.lastChannelSync < 3 then return end
    Ven.lastChannelSync = GetTime()
    Ven.QueueSyncMessages("CHANNEL"); Ven.QueueSyncMessages("ADDON")
end

C_Timer.After(2, function()
    if Ven.DBFrame then Ven.DBFrame:HookScript("OnShow", Ven.ManualChannelSync); Ven.DBFrame:HookScript("OnHide", Ven.ManualChannelSync) end
end)