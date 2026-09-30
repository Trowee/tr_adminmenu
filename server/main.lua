lib.locale()
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `admin_bans` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `name` VARCHAR(255) DEFAULT 'Unknown',
            `banner` VARCHAR(255) NOT NULL,
            `banner_name` VARCHAR(255) DEFAULT 'Console',
            `reason` TEXT NOT NULL,
            `expire` BIGINT NOT NULL DEFAULT 0,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `admin_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `admin` VARCHAR(255) NOT NULL,
            `admin_name` VARCHAR(255) DEFAULT 'Unknown',
            `action` VARCHAR(100) NOT NULL,
            `category` VARCHAR(50) NOT NULL,
            `details` TEXT,
            `target` VARCHAR(255) DEFAULT NULL,
            `target_name` VARCHAR(255) DEFAULT NULL,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `admin_warnings` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `target_identifier` VARCHAR(50) NOT NULL,
            `target_name` VARCHAR(255) DEFAULT NULL,
            `admin_name` VARCHAR(255) DEFAULT NULL,
            `reason` TEXT NOT NULL,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    MySQL.Async.execute("ALTER TABLE `admin_bans` ADD COLUMN IF NOT EXISTS `unbanned_by` VARCHAR(255) DEFAULT NULL")
    MySQL.Async.execute("ALTER TABLE `admin_bans` ADD COLUMN IF NOT EXISTS `unban_date` BIGINT DEFAULT NULL")
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `admin_duty_sessions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `admin_name` VARCHAR(255) DEFAULT 'Unknown',
            `admin_group` VARCHAR(50) DEFAULT 'admin',
            `start_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `end_time` TIMESTAMP NULL DEFAULT NULL,
            `duration_minutes` INT DEFAULT 0
        )
    ]])
    print('[tr_adminmenu] ' .. locale('db_tables_verified'))
end)
local function IsAdmin(source)
    local group = Framework.GetGroup(source)
    return Config.AdminGroups[group] == true
end
local function HasPermission(source, perm)
    local group = Framework.GetGroup(source)
    local identifiers = GetPlayerIdentifiers(source)
    if Config.HexPermissions then
        for _, id in ipairs(identifiers) do
            if Config.HexPermissions[id] and Config.HexPermissions[id][perm] ~= nil then
                return Config.HexPermissions[id][perm] == true
            end
        end
    end
    if not Config.Permissions[group] then return false end
    return Config.Permissions[group][perm] == true
end
local function GetFormattedName(source)
    local steamName = GetPlayerName(source) or 'Unknown'
    local charName = Framework.GetCharacterName(source)
    return steamName .. ' (' .. charName .. ')'
end
local function GetTargetIdentifiersString(targetId)
    local ids = GetPlayerIdentifiers(targetId)
    if not ids or #ids == 0 then return '' end
    local parts = {}
    for _, id in ipairs(ids) do
        if not string.find(id, '^ip:') then
            table.insert(parts, id)
        end
    end
    return table.concat(parts, ', ')
end
local function SendWebhook(category, adminName, action, details, targetName, adminIdentifiers, targetIdentifiers)
    local webhookUrl = ''
    if Webhooks and Webhooks.CategoryWebhooks and Webhooks.CategoryWebhooks[category] and Webhooks.CategoryWebhooks[category] ~= '' then
        webhookUrl = Webhooks.CategoryWebhooks[category]
    elseif Webhooks and Webhooks.MainWebhook and Webhooks.MainWebhook ~= '' then
        webhookUrl = Webhooks.MainWebhook
    end
    if webhookUrl == '' then return end
    local fields = {
        { name = 'Admin', value = adminName or 'Unknown', inline = true },
        { name = 'Action', value = action or 'Unknown', inline = true },
        { name = 'Category', value = category or 'Unknown', inline = true },
    }
    if targetName and targetName ~= '' then
        table.insert(fields, { name = 'Target', value = targetName, inline = true })
    end
    if details and details ~= '' then
        table.insert(fields, { name = 'Details', value = details, inline = false })
    end
    if Webhooks.IncludeIdentifiers and adminIdentifiers and adminIdentifiers ~= '' then
        table.insert(fields, { name = 'Admin Identifiers', value = '```' .. adminIdentifiers .. '```', inline = false })
    end
    if Webhooks.IncludeIdentifiers and targetIdentifiers and targetIdentifiers ~= '' then
        table.insert(fields, { name = 'Target Identifiers', value = '```' .. targetIdentifiers .. '```', inline = false })
    end
    local embed = {
        title = (Webhooks.ServerName or 'Server') .. ' - Admin Log',
        color = Webhooks.EmbedColor or 3447003,
        fields = fields,
        footer = { text = Webhooks.ServerName or 'Admin Log', icon_url = Webhooks.ServerIcon or '' },
    }
    if Webhooks.IncludeTimestamp then
        embed.timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    end
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({
        username = Webhooks.ServerName or 'Admin Log',
        avatar_url = Webhooks.ServerIcon or '',
        embeds = { embed }
    }), { ['Content-Type'] = 'application/json' })
end
local function LogAction(admin, adminName, action, category, details, target, targetName, adminSource, targetSource)
    MySQL.Async.execute('INSERT INTO admin_logs (admin, admin_name, action, category, details, target, target_name) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        admin, adminName, action, category, details, target or '', targetName or ''
    })
    local adminIds = ''
    local targetIds = ''
    if adminSource then
        adminIds = GetTargetIdentifiersString(adminSource)
    end
    if targetSource then
        targetIds = GetTargetIdentifiersString(targetSource)
    elseif target and target ~= '' then
        targetIds = target
    end
    SendWebhook(category, adminName, action, details, targetName, adminIds, targetIds)
end
local function SendNotification(source, type, text)
    if Config.NotificationSystem == 'nui' then
        TriggerClientEvent('tr_adminmenu:notification', source, type, text)
    elseif Config.NotificationSystem == 'esx' then
        if Framework.Name == 'esx' then
            TriggerClientEvent('esx:showNotification', source, text)
        else
            TriggerClientEvent('QBCore:Notify', source, text, type)
        end
    elseif Config.NotificationSystem == 'ox_lib' then
        TriggerClientEvent('ox_lib:notify', source, { type = type, description = text })
    end
end
local SteamAvatars = {}
local function GetSteamAvatar(source, cb)
    local identifiers = GetPlayerIdentifiers(source)
    local steamid = nil
    local steamHex = nil
    for _, id in ipairs(identifiers) do
        if string.find(id, "steam:") then
            steamHex = id
            steamid = tonumber(string.sub(id, 7), 16)
            break
        end
    end
    if not steamid or not Config.SteamWebApiKey then
        if cb then cb(nil) end
        return nil
    end
    if SteamAvatars[steamHex] then
        if cb then cb(SteamAvatars[steamHex]) end
        return SteamAvatars[steamHex]
    end
    PerformHttpRequest("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=" .. Config.SteamWebApiKey .. "&steamids=" .. steamid, function(err, text, headers)
        local avatar = nil
        if err == 200 then
            local data = json.decode(text)
            if data and data.response and data.response.players and data.response.players[1] then
                avatar = data.response.players[1].avatarfull
                SteamAvatars[steamHex] = avatar
            end
        end
        if cb then cb(avatar) end
    end, "GET", "")
    return nil
end
lib.callback.register('tr_adminmenu:getMyGroup', function(source)
    return Framework.GetGroup(source)
end)
lib.callback.register('tr_adminmenu:getPlayers', function(source)
    if not IsAdmin(source) then return {} end
    local players = Framework.GetAllPlayers()
    local list = {}
    for _, playerObj in pairs(players) do
        local src = Framework.GetPlayerSource(playerObj)
        local avatar = GetSteamAvatar(src)
        local ped = GetPlayerPed(src)
        local money, bank = Framework.GetPlayerMoney(src)
        local jobName = Framework.GetPlayerJob(src)
        local job2Name = nil
        if Config.PlayerInfoFields.job2 then
            job2Name = Framework.GetPlayerJob2(src)
        end
        table.insert(list, {
            id = src,
            name = Framework.GetCharacterName(src),
            playerName = GetPlayerName(src),
            job = jobName,
            job2 = job2Name,
            group = Framework.GetGroup(src),
            money = money,
            bank = bank,
            avatar = avatar,
            health = GetEntityHealth(ped),
            armor = GetPedArmour(ped)
        })
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end)
lib.callback.register('tr_adminmenu:getPlayerData', function(source, targetId)
    if not IsAdmin(source) then return nil end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return nil end
    local rawIdentifiers = GetPlayerIdentifiers(targetId)
    local identifiers = {}
    local canViewIp = HasPermission(source, 'view_ip')
    for _, id in ipairs(rawIdentifiers) do
        if canViewIp or not string.find(id, "^ip:") then
            table.insert(identifiers, id)
        end
    end
    local avatar = GetSteamAvatar(targetId)
    local money, bank, blackMoney = Framework.GetPlayerMoney(targetId)
    local inVehicle = false
    local ped = GetPlayerPed(targetId)
    if ped and ped ~= 0 then
        inVehicle = (GetVehiclePedIsIn(ped, false) ~= 0)
    end
    local job2Name, job2Label, job2Grade, job2GradeLabel = nil, nil, nil, nil
    if Config.PlayerInfoFields.job2 then
        job2Name, job2Label, job2Grade, job2GradeLabel = Framework.GetPlayerJob2(targetId)
    end
    local identifier = Framework.GetIdentifier(targetId)
    local uuid = Config.GetPlayerUUID(targetId)
    local phoneNumber = 'N/A'
    local vehiclesCount = 0
    local tasks = 0
    local resultData = nil
    local phoneEnabled = Config.PlayerInfoFields.phone and Config.PhoneNumberTable and Config.PhoneNumberTable ~= '' and Config.PhoneNumberColumn and Config.PhoneNumberColumn ~= ''
    local vehiclesEnabled = Config.PlayerInfoFields.vehiclesOwned
    if phoneEnabled then tasks = tasks + 1 end
    if vehiclesEnabled then tasks = tasks + 1 end
    local function finishData()
        tasks = tasks - 1
        if tasks <= 0 then
            local jobName, jobLabel, jobGrade, jobGradeLabel = Framework.GetPlayerJob(targetId)
            resultData = {
                id = targetId,
                uuid = uuid,
                name = Framework.GetCharacterName(targetId),
                playerName = GetPlayerName(targetId),
                job = jobName,
                jobLabel = jobLabel,
                jobGrade = jobGrade,
                jobGradeLabel = jobGradeLabel,
                job2 = job2Name,
                job2Label = job2Label,
                job2Grade = job2Grade,
                job2GradeLabel = job2GradeLabel,
                group = Framework.GetGroup(targetId),
                money = money,
                bank = bank,
                blackMoney = blackMoney,
                identifiers = identifiers,
                avatar = avatar,
                coords = Framework.GetPlayerCoords(targetId),
                ping = GetPlayerPing(targetId) or 0,
                inVehicle = inVehicle,
                phoneNumber = phoneNumber,
                vehiclesCount = vehiclesCount,
                playerInfoFields = Config.PlayerInfoFields,
            }
        end
    end
    if phoneEnabled then
        local phoneCol = Config.PhoneNumberColumn
        local phoneTable = Config.PhoneNumberTable
        MySQL.Async.fetchAll('SELECT ' .. phoneCol .. ' FROM ' .. phoneTable .. ' WHERE ' .. Framework.GetIdentifierColumn() .. ' = ?', {identifier}, function(result)
            if result and result[1] and result[1][phoneCol] then
                phoneNumber = result[1][phoneCol]
            end
            finishData()
        end)
    end
    if vehiclesEnabled then
        local vehTable = Framework.GetVehiclesTable()
        local vehOwnerCol = Framework.GetVehicleOwnerColumn()
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM ' .. vehTable .. ' WHERE ' .. vehOwnerCol .. ' = ?', {identifier}, function(count)
            vehiclesCount = count or 0
            finishData()
        end)
    end
    if tasks == 0 then
        finishData()
    end
    while resultData == nil do Wait(50) end
    return resultData
end)
lib.callback.register('tr_adminmenu:getMyPermissions', function(source)
    local group = Framework.GetGroup(source)
    local perms = {}
    if Config.Permissions[group] then
        for k, v in pairs(Config.Permissions[group]) do
            perms[k] = v
        end
    end
    local identifiers = GetPlayerIdentifiers(source)
    if Config.HexPermissions then
        for _, id in ipairs(identifiers) do
            if Config.HexPermissions[id] then
                for k, v in pairs(Config.HexPermissions[id]) do
                    perms[k] = v
                end
            end
        end
    end
    return perms
end)
lib.callback.register('tr_adminmenu:getMyAvatar', function(source)
    if not IsAdmin(source) then return nil end
    local p = promise.new()
    GetSteamAvatar(source, function(avatar)
        p:resolve(avatar)
    end)
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getLogs', function(source)
    if not IsAdmin(source) then return {} end
    local p = promise.new()
    MySQL.Async.fetchAll('SELECT * FROM admin_logs ORDER BY id DESC LIMIT 200', {}, function(logs)
        p:resolve(logs)
    end)
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getBans', function(source)
    if not IsAdmin(source) then return {} end
    local p = promise.new()
    MySQL.Async.fetchAll('SELECT * FROM admin_bans ORDER BY id DESC', {}, function(bans)
        p:resolve(bans)
    end)
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getOnlineAdmins', function(source)
    local admins = {}
    local players = Framework.GetAllPlayers()
    for _, playerObj in pairs(players) do
        local src = Framework.GetPlayerSource(playerObj)
        local group = Framework.GetGroup(src)
        if Config.AdminGroups[group] then
            local duty = true
            if Config.AdminDutyCheck then
                duty = Config.AdminDutyCheck(src)
            end
            table.insert(admins, {
                id = src,
                name = GetPlayerName(src),
                group = group,
                duty = duty,
                avatar = GetSteamAvatar(src)
            })
        end
    end
    return admins
end)
lib.callback.register('tr_adminmenu:getAvailableGroups', function(source)
    if not IsAdmin(source) then return {} end
    local groups = {}
    for group, rank in pairs(Config.GroupRanks) do
        table.insert(groups, { label = group, name = group, rank = rank })
    end
    table.sort(groups, function(a, b) return a.rank < b.rank end)
    return groups
end)
lib.callback.register('tr_adminmenu:getAllJobs', function(source)
    if not IsAdmin(source) then return {} end
    local jobs = {}
    local allJobs = Framework.GetAllJobs()
    for name, data in pairs(allJobs) do
        if Framework.Name == 'esx' then
            table.insert(jobs, { name = name, label = data.label, grades = data.grades })
        else
            local grades = {}
            if data.grades then
                for gradeLevel, gradeData in pairs(data.grades) do
                    grades[tostring(gradeLevel)] = { grade = tonumber(gradeLevel), label = gradeData.name or tostring(gradeLevel) }
                end
            end
            table.insert(jobs, { name = name, label = data.label, grades = grades })
        end
    end
    table.sort(jobs, function(a, b) return a.label < b.label end)
    return jobs
end)
lib.callback.register('tr_adminmenu:getCoords', function(source, targetId)
    if not IsAdmin(source) then return nil end
    local coords = Framework.GetPlayerCoords(targetId)
    if coords then
        local bucket = GetPlayerRoutingBucket(targetId)
        return { coords = coords, bucket = bucket }
    end
    return nil
end)
RegisterNetEvent('tr_adminmenu:setPlayerBucket')
AddEventHandler('tr_adminmenu:setPlayerBucket', function(bucket)
    local source = source
    if not IsAdmin(source) then return end
    SetPlayerRoutingBucket(source, bucket)
end)
lib.callback.register('tr_adminmenu:getMyBucket', function(source)
    return GetPlayerRoutingBucket(source)
end)
local peakPlayers = 0
local lastPeakReset = os.time()
local adminDutySessions = {}
CreateThread(function()
    while true do
        Wait(10000)
        local count = #GetPlayers()
        if count > peakPlayers then
            peakPlayers = count
        end
        if os.time() - lastPeakReset > 86400 then
            peakPlayers = count
            lastPeakReset = os.time()
        end
    end
end)
lib.callback.register('tr_adminmenu:checkDuty', function(source)
    if not IsAdmin(source) then return false end
    if Config.AdminDutyCheck then
        return Config.AdminDutyCheck(source) == true
    end
    return true
end)
RegisterNetEvent('tr_adminmenu:startDuty')
AddEventHandler('tr_adminmenu:startDuty', function()
    local source = source
    if not IsAdmin(source) then return end
    if adminDutySessions[source] then return end
    local identifier = Framework.GetIdentifier(source)
    local name = GetPlayerName(source)
    local group = Framework.GetGroup(source)
    MySQL.Async.insert('INSERT INTO admin_duty_sessions (identifier, admin_name, admin_group) VALUES (?, ?, ?)', {
        identifier, name, group
    }, function(insertId)
        adminDutySessions[source] = {
            identifier = identifier,
            name = name,
            group = group,
            startTime = os.time(),
            sessionId = insertId,
        }
    end)
end)
RegisterNetEvent('tr_adminmenu:endDuty')
AddEventHandler('tr_adminmenu:endDuty', function()
    local source = source
    local session = adminDutySessions[source]
    if not session then return end
    local duration = math.floor((os.time() - session.startTime) / 60)
    MySQL.Async.execute('UPDATE admin_duty_sessions SET end_time = NOW(), duration_minutes = ? WHERE id = ?', {
        duration, session.sessionId
    })
    adminDutySessions[source] = nil
end)
AddEventHandler('playerDropped', function()
    local source = source
    local session = adminDutySessions[source]
    if session then
        local duration = math.floor((os.time() - session.startTime) / 60)
        MySQL.Async.execute('UPDATE admin_duty_sessions SET end_time = NOW(), duration_minutes = ? WHERE id = ?', {
            duration, session.sessionId
        })
        adminDutySessions[source] = nil
    end
end)
lib.callback.register('tr_adminmenu:getAnalytics', function(source)
    if not IsAdmin(source) then return {} end
    local currentOnline = #GetPlayers()
    if currentOnline > peakPlayers then peakPlayers = currentOnline end
    local analytics = {
        currentPlayers = currentOnline,
        peakPlayers = peakPlayers,
        totalBans = 0, activeBans = 0, totalKicks = 0, totalWarnings = 0,
        actionsToday = 0, actions7d = 0,
        categoryBreakdown = {}, dailyCounts = {}, adminLeaderboard = {},
        adminGroups = {}, mostTargeted = {},
    }
    local pending = 9
    local p = promise.new()
    local function done()
        pending = pending - 1
        if pending == 0 then p:resolve(analytics) end
    end
    MySQL.Async.fetchAll('SELECT COUNT(*) as total, SUM(CASE WHEN unbanned_by IS NULL AND (expire IS NULL OR expire = "0" OR expire = 0 OR (expire > 0 AND expire > UNIX_TIMESTAMP()) OR (expire > NOW())) THEN 1 ELSE 0 END) as active FROM admin_bans', {}, function(result)
        if result and result[1] then
            analytics.totalBans = result[1].total or 0
            analytics.activeBans = result[1].active or 0
        end
        done()
    end)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_logs WHERE action = ? AND timestamp > DATE_SUB(NOW(), INTERVAL 30 DAY)', {'kick'}, function(count)
        analytics.totalKicks = count or 0
        done()
    end)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_warnings', {}, function(count)
        analytics.totalWarnings = count or 0
        done()
    end)
    MySQL.Async.fetchAll('SELECT COUNT(*) as cnt, CASE WHEN timestamp > DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 1 ELSE 0 END as isToday FROM admin_logs WHERE timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY) GROUP BY isToday', {}, function(results)
        for _, row in ipairs(results or {}) do
            if row.isToday == 1 then analytics.actionsToday = row.cnt end
            analytics.actions7d = analytics.actions7d + row.cnt
        end
        done()
    end)
    MySQL.Async.fetchAll('SELECT category, COUNT(*) as cnt FROM admin_logs WHERE timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY) GROUP BY category ORDER BY cnt DESC LIMIT 10', {}, function(results)
        analytics.categoryBreakdown = results or {}
        done()
    end)
    MySQL.Async.fetchAll('SELECT DATE_FORMAT(timestamp, "%m-%d") as day, COUNT(*) as cnt FROM admin_logs WHERE timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY) GROUP BY DATE_FORMAT(timestamp, "%m-%d") ORDER BY MIN(timestamp) ASC', {}, function(results)
        analytics.dailyCounts = results or {}
        done()
    end)
    MySQL.Async.fetchAll([[
        SELECT l.admin_name as name, COUNT(*) as actions,
            COALESCE((SELECT SUM(duration_minutes) FROM admin_duty_sessions s WHERE s.identifier = l.admin AND s.start_time > DATE_SUB(NOW(), INTERVAL 7 DAY)), 0) as duty_minutes
        FROM admin_logs l
        WHERE l.timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY l.admin, l.admin_name
        ORDER BY actions DESC
        LIMIT 10
    ]], {}, function(results)
        analytics.adminLeaderboard = results or {}
        done()
    end)
    local groups = {}
    local players = Framework.GetAllPlayers()
    for _, playerObj in pairs(players) do
        local src = Framework.GetPlayerSource(playerObj)
        local g = Framework.GetGroup(src)
        if Config.AdminGroups[g] then
            groups[g] = (groups[g] or 0) + 1
        end
    end
    local groupList = {}
    for g, cnt in pairs(groups) do
        table.insert(groupList, { group = g, count = cnt })
    end
    analytics.adminGroups = groupList
    done()
    MySQL.Async.fetchAll([[
        SELECT target_name as name, COUNT(*) as interactions
        FROM admin_logs
        WHERE timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY) AND target_name IS NOT NULL AND target_name != ''
        GROUP BY target_name
        ORDER BY interactions DESC
        LIMIT 8
    ]], {}, function(results)
        analytics.mostTargeted = results or {}
        done()
    end)
    return Citizen.Await(p)
end)
RegisterNetEvent('tr_adminmenu:ban')
AddEventHandler('tr_adminmenu:ban', function(targetId, duration, reason)
    local source = source
    if not HasPermission(source, 'ban') then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    local expire = nil
    if duration > 0 then
        expire = os.date('%Y-%m-%d %H:%M:%S', os.time() + duration)
    end
    local targetName = GetFormattedName(targetId)
    local adminIdentifier = Framework.GetIdentifier(source)
    local adminName = GetFormattedName(source)
    local tokens = {}
    for i = 0, GetNumPlayerTokens(targetId) - 1 do
        table.insert(tokens, GetPlayerToken(targetId, i))
    end
    local ip = GetPlayerEndpoint(targetId)
    local identifiers = GetPlayerIdentifiers(targetId)
    local identifier = identifiers[1]
    MySQL.Async.execute('INSERT INTO admin_bans (identifier, name, banner, banner_name, reason, expire, tokens, ip, hwid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        identifier, targetName, adminIdentifier, adminName, reason, expire, json.encode(tokens), ip, tokens[1]
    }, function()
        DropPlayer(targetId, locale('banned_reason', reason))
        LogAction(adminIdentifier, adminName, 'ban', 'moderation', reason, Framework.GetIdentifier(targetId), targetName, source, targetId)
        SendNotification(source, 'success', locale('player_banned'))
        MySQL.Async.fetchAll('SELECT * FROM admin_bans ORDER BY id DESC', {}, function(bans)
            local allPlayers = Framework.GetAllPlayers()
            for _, playerObj in pairs(allPlayers) do
                local src = Framework.GetPlayerSource(playerObj)
                if Config.AdminGroups[Framework.GetGroup(src)] then
                    TriggerClientEvent('tr_adminmenu:updateBans', src, bans)
                end
            end
        end)
    end)
end)
RegisterNetEvent('tr_adminmenu:unban')
AddEventHandler('tr_adminmenu:unban', function(banId)
    local source = source
    if not HasPermission(source, 'ban') then return end
    local adminName = GetFormattedName(source)
    local nowStr = os.date('%Y-%m-%d %H:%M:%S')
    local expiredStr = os.date('%Y-%m-%d %H:%M:%S', os.time() - 1)
    MySQL.Async.execute('UPDATE admin_bans SET expire = ?, unbanned_by = ?, unban_date = ? WHERE id = ?', {
        expiredStr, adminName, nowStr, banId
    })
    LogAction(Framework.GetIdentifier(source), adminName, 'unban', 'moderation', 'Unbanned ban ID: ' .. banId, '', '', source, nil)
    SendNotification(source, 'success', locale('player_unbanned'))
    MySQL.Async.fetchAll('SELECT * FROM admin_bans ORDER BY id DESC', {}, function(bans)
        local allPlayers = Framework.GetAllPlayers()
        for _, playerObj in pairs(allPlayers) do
            local src = Framework.GetPlayerSource(playerObj)
            if Config.AdminGroups[Framework.GetGroup(src)] then
                TriggerClientEvent('tr_adminmenu:updateBans', src, bans)
            end
        end
    end)
end)
RegisterNetEvent('tr_adminmenu:warn')
AddEventHandler('tr_adminmenu:warn', function(targetId, reason)
    local source = source
    if not HasPermission(source, 'warn') then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    MySQL.Async.execute('INSERT INTO admin_warnings (target_identifier, target_name, admin_name, reason) VALUES (?, ?, ?, ?)', {
        Framework.GetIdentifier(targetId), Framework.GetCharacterName(targetId), adminName, reason
    })
    LogAction(Framework.GetIdentifier(source), adminName, 'warn', 'moderation', reason, Framework.GetIdentifier(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('warned_player', Framework.GetCharacterName(targetId)))
    TriggerClientEvent('tr_adminmenu:receiveWarn', targetId, reason, adminName)
end)
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local identifiers = GetPlayerIdentifiers(source)
    local playerTokens = {}
    for i = 0, GetNumPlayerTokens(source) - 1 do
        table.insert(playerTokens, GetPlayerToken(source, i))
    end
    local playerIp = GetPlayerEndpoint(source)
    GetSteamAvatar(source)
    deferrals.defer()
    Citizen.Wait(0)
    deferrals.update(locale('deferral_init', Config.ServerName or 'Server'))
    Citizen.Wait(1000)
    deferrals.update(locale('deferral_checking_bans', Config.ServerName or 'Server'))
    Citizen.Wait(1000)
    deferrals.update(locale('deferral_verifying', Config.ServerName or 'Server'))
    Citizen.Wait(1000)
    if not identifiers or #identifiers == 0 then
        deferrals.done()
        return
    end
    MySQL.Async.fetchAll('SELECT * FROM admin_bans', {}, function(allBans)
        local status, err = pcall(function()
            if not allBans then allBans = {} end
            local activeBan = nil
            local currentTime = os.date('%Y-%m-%d %H:%M:%S')
            for _, ban in ipairs(allBans) do
                local isActive = false
                if not ban.unbanned_by then
                    if not ban.expire or ban.expire == 0 then
                        isActive = true
                    elseif type(ban.expire) == 'number' then
                        isActive = ban.expire > os.time()
                    else
                        isActive = tostring(ban.expire) > currentTime
                    end
                end
                if isActive then
                    if ban.identifier then
                        for _, id in ipairs(identifiers) do
                            if id == ban.identifier then activeBan = ban break end
                        end
                    end
                    if not activeBan and ban.tokens then
                        local ok, banTokens = pcall(json.decode, ban.tokens)
                        if ok and banTokens then
                            for _, t in ipairs(playerTokens) do
                                for _, bt in ipairs(banTokens) do
                                    if t == bt then activeBan = ban break end
                                end
                                if activeBan then break end
                            end
                        end
                    end
                    if not activeBan and Config.BanIP and ban.ip and playerIp then
                        if ban.ip == playerIp then activeBan = ban end
                    end
                    if activeBan then break end
                end
            end
            if activeBan then
                local expireStr = "PERMANENT"
                if activeBan.expire then
                    if type(activeBan.expire) == 'number' then
                        if activeBan.expire == 0 then
                            expireStr = "PERMANENT"
                        elseif activeBan.expire > 4102444800 then
                            expireStr = os.date('%d/%m/%Y %H:%M:%S', math.floor(activeBan.expire / 1000))
                        else
                            expireStr = os.date('%d/%m/%Y %H:%M:%S', activeBan.expire)
                        end
                    else
                        local s = tostring(activeBan.expire)
                        if s == '' or s == '0' then
                            expireStr = "PERMANENT"
                        else
                            local y, m, d, h, min, sec = s:match("^(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)$")
                            if y then
                                expireStr = string.format("%02d/%02d/%s %02d:%02d:%02d", d, m, y, h, min, sec)
                            else
                                local n = tonumber(s)
                                if n and n > 0 then
                                    if n > 4102444800 then n = math.floor(n/1000) end
                                    expireStr = os.date('%d/%m/%Y %H:%M:%S', n)
                                else
                                    expireStr = s
                                end
                            end
                        end
                    end
                end
                local banId = activeBan.id or "Unknown"
                local bannedBy = activeBan.admin_name or activeBan.banner_name or "Console"
                local reason = activeBan.reason or "No reason provided."
                local serverName = Config.ServerName or 'Server'
                local banCard = {
                    type = "AdaptiveCard",
                    body = {
                        { type = "TextBlock", text = locale('ban_card_title', serverName), size = "Medium", weight = "Bolder", horizontalAlignment = "Center", color = "Light" },
                        { type = "Container", items = {
                            { type = "TextBlock", text = locale('ban_card_banned_by', tostring(bannedBy)), color = "Light", size = "Default", wrap = true, horizontalAlignment = "Center" },
                            { type = "TextBlock", text = locale('ban_card_reason', tostring(reason)), color = "Light", size = "Default", wrap = true, spacing = "Small", horizontalAlignment = "Center" },
                            { type = "TextBlock", text = (expireStr == "PERMANENT") and locale('ban_card_expires_never') or locale('ban_card_expires', expireStr), color = "Light", size = "Default", spacing = "Small", horizontalAlignment = "Center" },
                            { type = "TextBlock", text = locale('ban_card_id', tostring(banId)), color = "Light", size = "Default", spacing = "Small", weight = "Bolder", horizontalAlignment = "Center" }
                        }, style = "default", spacing = "Large" },
                        { type = "TextBlock", text = locale('ban_card_appeal'), color = "Warning", wrap = true, horizontalAlignment = "Center", size = "Small", spacing = "Large" },
                        { type = "ActionSet", actions = { { type = "Action.OpenUrl", title = locale('ban_card_discord'), url = Config.DiscordUrl or "https://discord.gg/" } }, spacing = "Medium", horizontalAlignment = "Center" }
                    },
                    ["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json",
                    version = "1.3"
                }
                banCard.actions = {}
                deferrals.presentCard(banCard, function(data, rawData) end)
            else
                deferrals.done()
            end
        end)
        if not status then
            deferrals.done(locale('ban_technical_error', tostring(err)))
        end
    end)
end)
RegisterNetEvent('tr_adminmenu:kick')
AddEventHandler('tr_adminmenu:kick', function(targetId, reason)
    local source = source
    if not HasPermission(source, 'kick') then return end
    DropPlayer(targetId, locale('kicked_reason', reason))
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'kick', 'moderation', reason, Framework.GetIdentifier(targetId), targetName, source, nil)
    SendNotification(source, 'success', locale('player_kicked'))
end)
RegisterNetEvent('tr_adminmenu:goto')
AddEventHandler('tr_adminmenu:goto', function(targetId)
    local source = source
    if not HasPermission(source, 'goto_player') then return end
    local coords = Framework.GetPlayerCoords(targetId)
    if not coords then return end
    TriggerClientEvent('tr_adminmenu:teleportTo', source, coords)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'goto', 'playerstate', 'Teleported to player', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('teleported_to', Framework.GetCharacterName(targetId)))
    SendNotification(targetId, 'info', locale('admin_teleported_to_you', Framework.GetCharacterName(source)))
end)
RegisterNetEvent('tr_adminmenu:bring')
AddEventHandler('tr_adminmenu:bring', function(targetId)
    local source = source
    if not HasPermission(source, 'bring') then return end
    local coords = Framework.GetPlayerCoords(source)
    if not coords then return end
    TriggerClientEvent('tr_adminmenu:teleportTo', targetId, coords)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'bring', 'playerstate', 'Brought player', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('brought_player', Framework.GetCharacterName(targetId) or targetId))
    SendNotification(targetId, 'info', locale('you_were_brought', Framework.GetCharacterName(source)))
end)
RegisterNetEvent('tr_adminmenu:heal')
AddEventHandler('tr_adminmenu:heal', function(targetId)
    local source = source
    if not HasPermission(source, 'heal') then return end
    TriggerClientEvent('tr_adminmenu:heal', targetId)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'heal', 'playerstate', 'Healed player', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('healed_player'))
    SendNotification(targetId, 'success', locale('you_were_healed', Framework.GetCharacterName(source)))
end)
RegisterNetEvent('tr_adminmenu:revive')
AddEventHandler('tr_adminmenu:revive', function(targetId)
    local source = source
    if not HasPermission(source, 'revive') then return end
    TriggerClientEvent('tr_adminmenu:revive', targetId)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'revive', 'playerstate', 'Revived player', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('revived_player'))
    SendNotification(targetId, 'success', locale('you_were_revived', Framework.GetCharacterName(source)))
end)
RegisterNetEvent('tr_adminmenu:kill')
AddEventHandler('tr_adminmenu:kill', function(targetId)
    local source = source
    if not HasPermission(source, 'kill') then return end
    TriggerClientEvent('tr_adminmenu:kill', targetId)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'kill', 'playerstate', 'Killed player', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('killed_player'))
    SendNotification(targetId, 'error', locale('you_were_killed', Framework.GetCharacterName(source)))
end)
RegisterNetEvent('tr_adminmenu:freeze')
AddEventHandler('tr_adminmenu:freeze', function(targetId)
    local source = source
    if not HasPermission(source, 'freeze') then return end
    TriggerClientEvent('tr_adminmenu:freeze', targetId)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'freeze', 'playerstate', 'Froze player', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('player_frozen'))
    SendNotification(targetId, 'error', locale('you_were_frozen', Framework.GetCharacterName(source)))
end)
RegisterNetEvent('tr_adminmenu:unfreeze')
AddEventHandler('tr_adminmenu:unfreeze', function(targetId)
    local source = source
    if not HasPermission(source, 'freeze') then return end
    TriggerClientEvent('tr_adminmenu:unfreeze', targetId)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'unfreeze', 'playerstate', 'Unfroze player', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('player_unfrozen'))
    SendNotification(targetId, 'success', locale('you_were_unfrozen', Framework.GetCharacterName(source)))
end)
RegisterNetEvent('tr_adminmenu:setJob')
AddEventHandler('tr_adminmenu:setJob', function(targetId, job, grade)
    local source = source
    if not job then return SendNotification(source, 'error', locale('invalid_job')) end
    if not HasPermission(source, 'set_job') then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    Framework.SetJob(targetId, job, grade or 0)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'setjob', 'management', 'Set job to ' .. job .. ' grade ' .. (grade or 0), tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('job_updated', job))
end)
RegisterNetEvent('tr_adminmenu:fetchMyAvatar')
AddEventHandler('tr_adminmenu:fetchMyAvatar', function()
    local source = source
    GetSteamAvatar(source)
end)
RegisterNetEvent('tr_adminmenu:setGroup')
AddEventHandler('tr_adminmenu:setGroup', function(targetId, group)
    local source = source
    if not HasPermission(source, 'set_group') then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    local myRank = Config.GroupRanks[Framework.GetGroup(source)] or 0
    local targetRank = Config.GroupRanks[Framework.GetGroup(targetId)] or 0
    local newRank = Config.GroupRanks[group] or 0
    if targetRank >= myRank and source ~= targetId then
        return SendNotification(source, 'error', locale('cannot_manage_hierarchy'))
    end
    if newRank >= myRank then
        if newRank > myRank then return SendNotification(source, 'error', locale('cannot_promote_higher')) end
        if newRank == myRank and source ~= targetId then return SendNotification(source, 'error', locale('cannot_promote_equal')) end
    end
    Framework.SetGroup(targetId, group)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'setgroup', 'management', 'Set group to ' .. group, tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('group_updated', group))
end)
RegisterNetEvent('tr_adminmenu:setMoney')
AddEventHandler('tr_adminmenu:setMoney', function(targetId, moneyType, amount)
    local source = source
    if not HasPermission(source, 'set_money') then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    Framework.AddMoney(targetId, moneyType, amount)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'givemoney', 'management', 'Gave ' .. amount .. ' ' .. moneyType, tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('money_set', amount))
end)
RegisterNetEvent('tr_adminmenu:removeMoney')
AddEventHandler('tr_adminmenu:removeMoney', function(targetId, moneyType, amount)
    local source = source
    if not HasPermission(source, 'remove_money') then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    Framework.RemoveMoney(targetId, moneyType, amount)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'removemoney', 'management', 'Removed ' .. amount .. ' from ' .. moneyType, tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('money_removed', amount))
end)
RegisterNetEvent('tr_adminmenu:giveItem')
AddEventHandler('tr_adminmenu:giveItem', function(targetId, itemName, count)
    local source = source
    if not HasPermission(source, 'give_item') then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    Framework.GiveItem(targetId, itemName, count)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'giveitem', 'management', 'Gave ' .. count .. 'x ' .. itemName, tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('gave_item', count, itemName))
end)
RegisterNetEvent('tr_adminmenu:removeItem')
AddEventHandler('tr_adminmenu:removeItem', function(targetId, itemName, count)
    local source = source
    if not HasPermission(source, 'remove_item') then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    Framework.RemoveItem(targetId, itemName, count)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'removeitem', 'management', 'Removed ' .. count .. 'x ' .. itemName, tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('removed_item', count, itemName))
end)
RegisterNetEvent('tr_adminmenu:getPlayerInventory')
AddEventHandler('tr_adminmenu:getPlayerInventory', function(targetId)
    local source = source
    if not IsAdmin(source) then return end
    targetId = tonumber(targetId)
    local inventory = Framework.GetPlayerInventory(targetId)
    TriggerClientEvent('tr_adminmenu:receiveInventory', source, inventory)
end)
RegisterNetEvent('tr_adminmenu:clearInventory')
AddEventHandler('tr_adminmenu:clearInventory', function(targetId)
    local source = source
    if not HasPermission(source, 'clear_inventory') then return end
    Framework.ClearInventory(targetId)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'clearinventory', 'management', 'Cleared inventory', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('inventory_cleared'))
end)
RegisterNetEvent('tr_adminmenu:clearWeapons')
AddEventHandler('tr_adminmenu:clearWeapons', function(targetId)
    local source = source
    if not HasPermission(source, 'clear_inventory') then return end
    Framework.ClearWeapons(targetId)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'clearweapons', 'management', 'Cleared weapons', tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('weapons_cleared'))
end)
RegisterNetEvent('tr_adminmenu:requestMugshot')
AddEventHandler('tr_adminmenu:requestMugshot', function(targetId)
    local source = source
    local avatar = GetSteamAvatar(targetId)
    TriggerClientEvent('tr_adminmenu:receiveMugshot', source, avatar)
end)
RegisterNetEvent('tr_adminmenu:sendDM')
AddEventHandler('tr_adminmenu:sendDM', function(targetId, message)
    local source = source
    if not HasPermission(source, 'send_dm') then return end
    TriggerClientEvent('tr_adminmenu:receiveDM', targetId, Framework.GetCharacterName(source), message)
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(targetId)
    LogAction(Framework.GetIdentifier(source), adminName, 'dm', 'moderation', message, tostring(targetId), targetName, source, targetId)
    SendNotification(source, 'success', locale('dm_sent'))
end)
RegisterNetEvent('tr_adminmenu:staffChat')
AddEventHandler('tr_adminmenu:staffChat', function(text)
    local source = source
    if not HasPermission(source, 'staff_chat') then return end
    local group = Framework.GetGroup(source)
    local msg = {
        name = GetPlayerName(source),
        group = group,
        text = text,
        color = Config.StaffChatColors[group] or '#3B82F6',
        time = os.date('%H:%M'),
    }
    local allPlayers = Framework.GetAllPlayers()
    for _, playerObj in pairs(allPlayers) do
        local src = Framework.GetPlayerSource(playerObj)
        if Config.AdminGroups[Framework.GetGroup(src)] then
            TriggerClientEvent('tr_adminmenu:staffChatMsg', src, {
                name = msg.name, group = msg.group, text = msg.text,
                color = msg.color, time = msg.time, avatar = GetSteamAvatar(source)
            })
        end
    end
end)
RegisterNetEvent('tr_adminmenu:dvall')
AddEventHandler('tr_adminmenu:dvall', function()
    local source = source
    if not HasPermission(source, 'delete_all_vehicles') then return end
    TriggerClientEvent('tr_adminmenu:deleteAllVehicles', -1)
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'dvall', 'vehicle', 'Deleted all vehicles', '', '', source, nil)
    SendNotification(source, 'success', locale('all_vehicles_deleted'))
end)
RegisterNetEvent('tr_adminmenu:log')
AddEventHandler('tr_adminmenu:log', function(action, category, details)
    local source = source
    if IsAdmin(source) then
        local adminName = GetFormattedName(source)
        LogAction(Framework.GetIdentifier(source), adminName, action, category, details, '', '', source, nil)
    end
end)
lib.callback.register('tr_adminmenu:getAllItems', function(source)
    return Framework.GetAllItems()
end)
lib.callback.register('tr_adminmenu:getVehicles', function(source)
    if not IsAdmin(source) then return {} end
    local vehTable = Framework.GetVehiclesTable()
    local vehOwnerCol = Framework.GetVehicleOwnerColumn()
    local vehDataCol = Framework.GetVehicleDataColumn()
    local vehModelCol = Framework.GetVehicleModelColumn()
    local usersTable = Framework.GetUsersTable()
    local idCol = Framework.GetIdentifierColumn()
    local p = promise.new()
    local query
    if Framework.Name == 'esx' then
        query = 'SELECT ov.plate, ov.vehicle, ov.owner, u.firstname, u.lastname FROM owned_vehicles ov LEFT JOIN users u ON u.identifier = ov.owner ORDER BY ov.plate ASC LIMIT 500'
    else
        query = 'SELECT pv.plate, pv.vehicle, pv.mods, pv.citizenid, p.charinfo FROM player_vehicles pv LEFT JOIN players p ON p.citizenid = pv.citizenid ORDER BY pv.plate ASC LIMIT 500'
    end
    MySQL.Async.fetchAll(query, {}, function(vehicles)
        local list = {}
        for _, v in ipairs(vehicles) do
            local modelName = ''
            if Framework.Name == 'esx' then
                if v.vehicle then
                    local ok, data = pcall(json.decode, v.vehicle)
                    if ok and data and data.model then modelName = tostring(data.model) end
                end
            else
                modelName = v.vehicle or ''
            end
            if modelName == '' then modelName = 'Unknown' end
            local ownerName = 'Unknown'
            if Framework.Name == 'esx' then
                if v.firstname and v.lastname then ownerName = v.firstname .. ' ' .. v.lastname end
            else
                if v.charinfo then
                    local ok, ci = pcall(json.decode, v.charinfo)
                    if ok and ci then ownerName = (ci.firstname or 'Unknown') .. ' ' .. (ci.lastname or '') end
                end
            end
            table.insert(list, {
                plate = v.plate, vehicle = modelName,
                owner = v[vehOwnerCol] or v.owner or v.citizenid,
                owner_name = ownerName,
            })
        end
        p:resolve(list)
    end)
    return Citizen.Await(p)
end)
RegisterNetEvent('tr_adminmenu:removeVehicle')
AddEventHandler('tr_adminmenu:removeVehicle', function(plate)
    local source = source
    if not HasPermission(source, 'manage_vehicles') then return end
    MySQL.Async.execute('DELETE FROM ' .. Framework.GetVehiclesTable() .. ' WHERE plate = ?', { plate })
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'removevehicle', 'vehicle', 'Removed vehicle with plate: ' .. plate, '', '', source, nil)
    SendNotification(source, 'success', locale('vehicle_removed', plate))
end)
RegisterNetEvent('tr_adminmenu:changePlate')
AddEventHandler('tr_adminmenu:changePlate', function(oldPlate, newPlate)
    local source = source
    if not HasPermission(source, 'manage_vehicles') then return end
    MySQL.Async.execute('UPDATE ' .. Framework.GetVehiclesTable() .. ' SET plate = ? WHERE plate = ?', { newPlate, oldPlate })
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'changeplate', 'vehicle', 'Changed plate from ' .. oldPlate .. ' to ' .. newPlate, '', '', source, nil)
    SendNotification(source, 'success', locale('plate_changed', newPlate))
end)
RegisterNetEvent('tr_adminmenu:addVehicle')
AddEventHandler('tr_adminmenu:addVehicle', function(playerId, model, plate)
    local source = source
    if not HasPermission(source, 'manage_vehicles') then return end
    local Player = Framework.GetPlayer(playerId)
    if not Player then return SendNotification(source, 'error', locale('player_not_found')) end
    local identifier = Framework.GetIdentifier(playerId)
    local vehTable = Framework.GetVehiclesTable()
    local ownerCol = Framework.GetVehicleOwnerColumn()
    if Framework.Name == 'esx' then
        local props = { model = GetHashKey(model), plate = plate }
        MySQL.Async.execute('INSERT INTO ' .. vehTable .. ' (' .. ownerCol .. ', plate, vehicle) VALUES (?, ?, ?)', { identifier, plate, json.encode(props) })
    else
        local playerLicense = GetPlayerIdentifierByType(playerId, 'license')
        local licenseStr = nil
        if playerLicense then
            licenseStr = playerLicense -- keeps 'license:XXXX' format
        end
        MySQL.Async.execute([[
            INSERT INTO player_vehicles
                (license, citizenid, vehicle, hash, mods, plate, fakeplate, garage, fuel, engine, body, state, depotprice, drivingdistance, status, balance, paymentamount, paymentsleft, financetime)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, 100, 1000, 1000, 1, 0, NULL, NULL, 0, 0, 0, 0)
        ]], { licenseStr, identifier, model, tostring(GetHashKey(model)), nil, plate, nil, nil })
    end
    local adminName = GetFormattedName(source)
    local targetName = GetFormattedName(playerId)
    LogAction(Framework.GetIdentifier(source), adminName, 'addvehicle', 'vehicle', 'Added vehicle ' .. model .. ' plate ' .. plate, tostring(playerId), targetName, source, playerId)
    SendNotification(source, 'success', locale('vehicle_added', model, plate))
end)
RegisterNetEvent('tr_adminmenu:requestAppearance')
AddEventHandler('tr_adminmenu:requestAppearance', function(targetId)
    local source = source
    if not IsAdmin(source) then return end
    local Player = Framework.GetPlayer(targetId)
    if not Player then return end
    TriggerClientEvent('tr_adminmenu:getMyAppearance', targetId, source)
end)
RegisterNetEvent('tr_adminmenu:returnAppearance')
AddEventHandler('tr_adminmenu:returnAppearance', function(requesterId, appearance)
    TriggerClientEvent('tr_adminmenu:receiveAppearance', requesterId, appearance)
end)
RegisterNetEvent('tr_adminmenu:announce')
AddEventHandler('tr_adminmenu:announce', function(message)
    local source = source
    if not HasPermission(source, 'send_announcement') then return end
    TriggerClientEvent('tr_adminmenu:receiveAnnouncement', -1, { message = message, admin = GetPlayerName(source) })
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'announcement', 'system', message, '', '', source, nil)
end)
lib.callback.register('tr_adminmenu:getWeeklyStats', function(source)
    if not IsAdmin(source) then return {} end
    local stats = { bans = 0, kicks = 0, warns = 0 }
    local pending = 3
    local p = promise.new()
    local function done() pending = pending - 1; if pending == 0 then p:resolve(stats) end end
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_bans WHERE timestamp > NOW() - INTERVAL 7 DAY', {}, function(c) stats.bans = c or 0; done() end)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_logs WHERE action = "kick" AND timestamp > NOW() - INTERVAL 7 DAY', {}, function(c) stats.kicks = c or 0; done() end)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_logs WHERE action = "warn" AND timestamp > NOW() - INTERVAL 7 DAY', {}, function(c) stats.warns = c or 0; done() end)
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getTopPlayers', function(source)
    if not IsAdmin(source) then return {} end
    local result = { richest = {}, newest = {} }
    local onlinePlayers = Framework.GetAllPlayers()
    local onlineDict = {}
    for _, playerObj in pairs(onlinePlayers) do
        local src = Framework.GetPlayerSource(playerObj)
        local iden = Framework.GetIdentifier(src)
        if iden then onlineDict[iden] = src end
    end
    local usersTable = Framework.GetUsersTable()
    local idCol = Framework.GetIdentifierColumn()
    local pending = 2
    local p = promise.new()
    local function done() pending = pending - 1; if pending == 0 then p:resolve(result) end end
    local usersTable = Framework.GetUsersTable()
    local idCol = Framework.GetIdentifierColumn()
    if Framework.Name == 'esx' then
        MySQL.Async.fetchAll('SELECT ' .. idCol .. ', firstname, lastname, accounts FROM ' .. usersTable, {}, function(users)
            local richestList = {}
            for _, u in ipairs(users) do
                local money = 0
                if u.accounts then
                    local ok, accounts = pcall(json.decode, u.accounts)
                    if ok and accounts then
                        if accounts.money then money = money + (tonumber(accounts.money) or 0) end
                        if accounts.bank then money = money + (tonumber(accounts.bank) or 0) end
                    end
                end
                table.insert(richestList, { name = (u.firstname or 'Unknown') .. ' ' .. (u.lastname or ''), value = '$' .. Framework.GroupDigits(money), raw_money = money, serverId = onlineDict[u[idCol]] or nil, identifier = u[idCol] })
            end
            table.sort(richestList, function(a, b) return a.raw_money > b.raw_money end)
            for i=1, 5 do if richestList[i] then table.insert(result.richest, richestList[i]) end end
            done()
        end)
        MySQL.Async.fetchAll('SELECT ' .. idCol .. ', firstname, lastname FROM ' .. usersTable .. ' ORDER BY ' .. idCol .. ' DESC LIMIT 5', {}, function(newest)
            for _, u in ipairs(newest) do
                table.insert(result.newest, { name = (u.firstname or 'Unknown') .. ' ' .. (u.lastname or ''), serverId = onlineDict[u[idCol]] or nil, identifier = u[idCol] })
            end
            done()
        end)
    else
        MySQL.Async.fetchAll('SELECT ' .. idCol .. ', charinfo, money FROM ' .. usersTable, {}, function(users)
            local richestList = {}
            for _, u in ipairs(users) do
                local money = 0
                if u.money then
                    local moneyData = u.money
                    if type(moneyData) == 'string' then local ok, parsed = pcall(json.decode, moneyData); if ok then moneyData = parsed end end
                    if type(moneyData) == 'table' then money = (tonumber(moneyData.cash) or 0) + (tonumber(moneyData.bank) or 0) end
                end
                local name = Framework.GetPlayerNameFromDB(u)
                table.insert(richestList, { name = name, value = '$' .. Framework.GroupDigits(money), raw_money = money, serverId = onlineDict[u[idCol]] or nil, identifier = u[idCol] })
            end
            table.sort(richestList, function(a, b) return a.raw_money > b.raw_money end)
            for i=1, 5 do if richestList[i] then table.insert(result.richest, richestList[i]) end end
            done()
        end)
        MySQL.Async.fetchAll('SELECT ' .. idCol .. ', charinfo FROM ' .. usersTable .. ' ORDER BY id DESC LIMIT 5', {}, function(newest)
            for _, u in ipairs(newest) do
                local name = Framework.GetPlayerNameFromDB(u)
                table.insert(result.newest, { name = name, serverId = onlineDict[u[idCol]] or nil, identifier = u[idCol] })
            end
            done()
        end)
    end
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getJobStats', function(source)
    if not IsAdmin(source) then return {} end
    local p = promise.new()
    local allJobs = Framework.GetAllJobs()
    local usersTable = Framework.GetUsersTable()
    if Framework.Name == 'esx' then
        MySQL.Async.fetchAll('SELECT job, COUNT(*) as count FROM ' .. usersTable .. ' GROUP BY job ORDER BY count DESC', {}, function(jobs)
            local result = {}
            for _, j in ipairs(jobs) do
                local label = j.job
                if allJobs and allJobs[j.job] then label = allJobs[j.job].label end
                if label then label = label:gsub("^%l", string.upper) end
                table.insert(result, { name = label or j.job, count = j.count })
            end
            p:resolve(result)
        end)
    else
        MySQL.Async.fetchAll('SELECT job FROM ' .. usersTable, {}, function(rows)
            local jobCounts = {}
            for _, r in ipairs(rows) do
                local jobData = r.job
                if type(jobData) == 'string' then local ok, parsed = pcall(json.decode, jobData); if ok then jobData = parsed end end
                local jobName = type(jobData) == 'table' and jobData.name or 'unemployed'
                jobCounts[jobName] = (jobCounts[jobName] or 0) + 1
            end
            local result = {}
            for name, count in pairs(jobCounts) do
                local label = name
                if allJobs and allJobs[name] then label = allJobs[name].label end
                if label then label = label:gsub("^%l", string.upper) end
                table.insert(result, { name = label or name, count = count })
            end
            table.sort(result, function(a, b) return a.count > b.count end)
            p:resolve(result)
        end)
    end
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getWarnings', function(source, targetId)
    if not IsAdmin(source) then return {} end
    local identifier = Framework.GetIdentifier(targetId)
    if not identifier then return {} end
    local p = promise.new()
    MySQL.Async.fetchAll('SELECT id, admin, details as reason, UNIX_TIMESTAMP(timestamp) as date FROM admin_logs WHERE target = @identifier AND action = "warn" ORDER BY timestamp DESC', { ['@identifier'] = identifier }, function(results)
        local warnings = {}
        for _, w in ipairs(results) do table.insert(warnings, { id = w.id, admin = w.admin, reason = w.reason, timestamp = w.date }) end
        p:resolve(warnings)
    end)
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getPlayerBans', function(source, targetId)
    if not IsAdmin(source) then return {} end
    local identifier = Framework.GetIdentifier(targetId)
    if not identifier then return {} end
    local p = promise.new()
    MySQL.Async.fetchAll('SELECT * FROM admin_bans WHERE identifier = @identifier ORDER BY id DESC', { ['@identifier'] = identifier }, function(results)
        local bans = {}
        for _, b in ipairs(results) do
            table.insert(bans, { reason = b.reason, admin = b.banner_name or b.banner, active = (b.unbanned_by == nil and (b.expire == nil or b.expire == 0 or b.expire > os.time() or b.expire > 2147483647)) })
        end
        p:resolve(bans)
    end)
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getOfflinePlayers', function(source)
    if not IsAdmin(source) or not HasPermission(source, 'offline_players') then return {} end
    local onlinePlayers = Framework.GetAllPlayers()
    local onlineIds = {}
    for _, playerObj in pairs(onlinePlayers) do
        local src = Framework.GetPlayerSource(playerObj)
        local iden = Framework.GetIdentifier(src)
        if iden then onlineIds[iden] = true end
    end
    local p = promise.new()
    local idCol = Framework.GetIdentifierColumn()
    if Framework.Name == 'esx' then
        local phoneEnabled = Config.PlayerInfoFields.phone and Config.PhoneNumberTable and Config.PhoneNumberTable ~= '' and Config.PhoneNumberColumn and Config.PhoneNumberColumn ~= ''
        local phoneCol = phoneEnabled and Config.PhoneNumberColumn or nil
        local phoneTable = phoneEnabled and Config.PhoneNumberTable or nil
        local query = 'SELECT identifier, firstname, lastname, job, job_grade, accounts, `group`'
        if Config.PlayerInfoFields.job2 then query = query .. ', job2, job2_grade' end
        if phoneEnabled and phoneTable == 'users' then query = query .. ', ' .. phoneCol end
        query = query .. ' FROM users'
        MySQL.Async.fetchAll(query, {}, function(users)
            local result = {}
            for _, u in ipairs(users) do
                if not onlineIds[u.identifier] then
                    local money, bank, blackMoney = Framework.ParseOfflineAccounts(u)
                    table.insert(result, {
                        identifier = u.identifier,
                        name = (u.firstname or 'Unknown') .. ' ' .. (u.lastname or ''),
                        firstname = u.firstname or 'Unknown', lastname = u.lastname or '',
                        job = u.job or 'unemployed',
                        job2 = Config.PlayerInfoFields.job2 and (u.job2 or 'none') or nil,
                        jobGrade = u.job_grade or 0, group = u['group'] or 'user',
                        money = money, bank = bank, blackMoney = blackMoney,
                        phoneNumber = (phoneEnabled and phoneTable == 'users' and u[phoneCol]) or 'N/A',
                    })
                end
            end
            p:resolve(result)
        end)
    else
        MySQL.Async.fetchAll('SELECT citizenid, charinfo, job, money, gang FROM players', {}, function(users)
            local result = {}
            for _, u in ipairs(users) do
                if not onlineIds[u.citizenid] then
                    local name = Framework.GetPlayerNameFromDB(u)
                    local money, bank, crypto = Framework.ParseOfflineAccounts(u)
                    local jobData = u.job
                    if type(jobData) == 'string' then local ok, parsed = pcall(json.decode, jobData); if ok then jobData = parsed end end
                    local jobName = type(jobData) == 'table' and jobData.name or 'unemployed'
                    local gangData = u.gang
                    if type(gangData) == 'string' then local ok, parsed = pcall(json.decode, gangData); if ok then gangData = parsed end end
                    local gangName = type(gangData) == 'table' and gangData.name or 'none'
                    table.insert(result, {
                        identifier = u.citizenid, name = name,
                        job = jobName, job2 = gangName, jobGrade = 0,
                        group = 'user', money = money, bank = bank, blackMoney = crypto,
                    })
                end
            end
            p:resolve(result)
        end)
    end
    return Citizen.Await(p)
end)
lib.callback.register('tr_adminmenu:getOfflinePlayerData', function(source, identifier)
    if not IsAdmin(source) or not HasPermission(source, 'offline_players') then return nil end
    if not identifier or identifier == '' then return nil end
    local p = promise.new()
    local result = {}
    local vehTable = Framework.GetVehiclesTable()
    local vehOwnerCol = Framework.GetVehicleOwnerColumn()
    if Framework.Name == 'esx' then
        local phoneEnabled = Config.PlayerInfoFields.phone and Config.PhoneNumberTable and Config.PhoneNumberTable ~= '' and Config.PhoneNumberColumn and Config.PhoneNumberColumn ~= ''
        local phoneCol = phoneEnabled and Config.PhoneNumberColumn or nil
        local phoneTable = phoneEnabled and Config.PhoneNumberTable or nil
        local playtimeEnabled = Config.PlayerInfoFields.playtime and Config.PlaytimeTable and Config.PlaytimeTable ~= '' and Config.PlaytimeColumn and Config.PlaytimeColumn ~= ''
        local playtimeCol = playtimeEnabled and Config.PlaytimeColumn or nil
        local playtimeTable = playtimeEnabled and Config.PlaytimeTable or nil
        local tasks = 5
        if phoneEnabled and phoneTable ~= 'users' then tasks = tasks + 1 end
        if playtimeEnabled and playtimeTable ~= 'users' then tasks = tasks + 1 end
        local function finish() tasks = tasks - 1; if tasks == 0 then p:resolve(result) end end
        local selectCols = 'uuid, identifier, firstname, lastname, dateofbirth, sex, job, job_grade, accounts, `group`, inventory, position, created_at, last_seen'
        if Config.PlayerInfoFields.job2 then selectCols = selectCols .. ', job2, job2_grade' end
        if Config.PlayerInfoFields.metadata_job then selectCols = selectCols .. ', metadata' end
        if phoneEnabled and phoneTable == 'users' then selectCols = selectCols .. ', ' .. phoneCol end
        if playtimeEnabled and playtimeTable == 'users' then selectCols = selectCols .. ', ' .. playtimeCol end
        MySQL.Async.fetchAll('SELECT ' .. selectCols .. ' FROM users WHERE identifier = ?', {identifier}, function(rows)
            if not rows or not rows[1] then tasks = 0; p:resolve(nil); return end
            local u = rows[1]
            local money, bank, blackMoney = Framework.ParseOfflineAccounts(u)
            local allJobs = Framework.GetAllJobs()
            local jobLabel = u.job or 'unemployed'
            local gradeLabel = tostring(u.job_grade or 0)
            if allJobs and allJobs[u.job] then
                jobLabel = allJobs[u.job].label or jobLabel
                local grades = allJobs[u.job].grades
                if grades then for _, g in pairs(grades) do if g.grade == u.job_grade then gradeLabel = g.label or gradeLabel; break end end end
            end
            result.id = u.id; result.identifier = u.identifier
            result.name = (u.firstname or 'Unknown') .. ' ' .. (u.lastname or '')
            result.firstname = u.firstname or 'Unknown'; result.lastname = u.lastname or ''
            result.dateofbirth = u.dateofbirth or 'N/A'; result.sex = u.sex or 'N/A'
            result.job = u.job or 'unemployed'; result.jobLabel = jobLabel
            result.jobGrade = u.job_grade or 0; result.gradeLabel = gradeLabel
            result.group = u['group'] or 'user'
            result.money = money; result.bank = bank; result.blackMoney = blackMoney
            result.phoneNumber = (phoneEnabled and phoneTable == 'users' and u[phoneCol]) or 'N/A'
            result.playtime = (playtimeEnabled and playtimeTable == 'users' and u[playtimeCol]) or 0
            result.created_at = u.created_at or 'N/A'; result.last_seen = u.last_seen or 'N/A'
            result.playerInfoFields = Config.PlayerInfoFields
            if Config.PlayerInfoFields.job2 then
                result.job2 = u.job2 or 'none'; result.job2Grade = u.job2_grade or 0
                local job2Label = result.job2; local job2GradeLabel = tostring(result.job2Grade)
                if allJobs and allJobs[result.job2] then
                    job2Label = allJobs[result.job2].label or job2Label
                    local grades2 = allJobs[result.job2].grades
                    if grades2 then for _, g in pairs(grades2) do if g.grade == result.job2Grade then job2GradeLabel = g.label or job2GradeLabel; break end end end
                end
                result.job2Label = job2Label; result.job2GradeLabel = job2GradeLabel
            end
            if Config.PlayerInfoFields.metadata_job and u.metadata then
                local okMeta, meta = pcall(json.decode, u.metadata)
                if okMeta and meta and meta.job then
                    result.metadataJob = meta.job.name or 'none'; result.metadataJobLabel = meta.job.label or result.metadataJob
                    result.metadataJobGrade = meta.job.grade or 0; result.metadataJobGradeLabel = meta.job.grade_label or tostring(result.metadataJobGrade)
                end
            end
            result.position = nil
            if u.position then local okPos, pos = pcall(json.decode, u.position); if okPos and type(pos) == 'table' then result.position = pos end end
            local invData = {}
            if u.inventory and type(u.inventory) == 'string' and u.inventory ~= '' then
                local okInv, parsed = pcall(json.decode, u.inventory)
                if okInv and type(parsed) == 'table' then
                    for _, item in ipairs(parsed) do
                        if item.name and item.count and item.count > 0 then
                            table.insert(invData, { name = item.name, label = item.label or item.name, count = item.count, slot = item.slot or 0, image = 'nui://ox_inventory/web/images/' .. item.name .. '.png' })
                        end
                    end
                end
            end
            result.inventory = invData
            finish()
        end)
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM ' .. vehTable .. ' WHERE ' .. vehOwnerCol .. ' = ?', {identifier}, function(count) result.vehiclesCount = count or 0; finish() end)
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_logs WHERE target = ? AND action = "warn"', {identifier}, function(count) result.warnsCount = count or 0; finish() end)
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_logs WHERE target = ? AND action = "kick"', {identifier}, function(count) result.kicksCount = count or 0; finish() end)
        MySQL.Async.fetchAll('SELECT * FROM admin_bans WHERE identifier = ? ORDER BY id DESC', {identifier}, function(bans)
            local banList = {}
            if bans then for _, b in ipairs(bans) do table.insert(banList, { reason = b.reason, admin = b.banner_name or b.banner, active = (b.unbanned_by == nil and (b.expire == nil or b.expire == 0 or b.expire > os.time())) }) end end
            result.bans = banList; result.bansCount = #banList; finish()
        end)
        if phoneEnabled and phoneTable ~= 'users' then
            MySQL.Async.fetchAll('SELECT ' .. phoneCol .. ' FROM ' .. phoneTable .. ' WHERE identifier = ?', {identifier}, function(rows)
                result.phoneNumber = (rows and rows[1] and rows[1][phoneCol]) or 'N/A'; finish()
            end)
        end
        if playtimeEnabled and playtimeTable ~= 'users' then
            MySQL.Async.fetchAll('SELECT ' .. playtimeCol .. ' FROM ' .. playtimeTable .. ' WHERE identifier = ?', {identifier}, function(rows)
                result.playtime = (rows and rows[1] and rows[1][playtimeCol]) or 0; finish()
            end)
        end
    else
        local tasks = 5
        local function finish() tasks = tasks - 1; if tasks == 0 then p:resolve(result) end end
        MySQL.Async.fetchAll('SELECT * FROM players WHERE citizenid = ?', {identifier}, function(rows)
            if not rows or not rows[1] then tasks = 0; p:resolve(nil); return end
            local u = rows[1]
            result.identifier = u.citizenid
            result.name = Framework.GetPlayerNameFromDB(u)
            local ci = u.charinfo; if type(ci) == 'string' then local ok, parsed = pcall(json.decode, ci); if ok then ci = parsed end end
            if type(ci) == 'table' then
                result.firstname = ci.firstname or 'Unknown'; result.lastname = ci.lastname or ''
                result.dateofbirth = ci.birthdate or 'N/A'; result.sex = ci.gender == 0 and 'male' or 'female'
                result.phoneNumber = ci.phone or 'N/A'
            else
                result.firstname = 'Unknown'; result.lastname = ''; result.dateofbirth = 'N/A'; result.sex = 'N/A'; result.phoneNumber = 'N/A'
            end
            local money, bank, crypto = Framework.ParseOfflineAccounts(u)
            result.money = money; result.bank = bank; result.blackMoney = crypto
            local jobData = u.job; if type(jobData) == 'string' then local ok, parsed = pcall(json.decode, jobData); if ok then jobData = parsed end end
            if type(jobData) == 'table' then
                result.job = jobData.name or 'unemployed'; result.jobLabel = jobData.label or result.job
                result.jobGrade = jobData.grade and jobData.grade.level or 0; result.gradeLabel = jobData.grade and jobData.grade.name or '0'
            else result.job = 'unemployed'; result.jobLabel = 'Unemployed'; result.jobGrade = 0; result.gradeLabel = '0' end
            local gangData = u.gang; if type(gangData) == 'string' then local ok, parsed = pcall(json.decode, gangData); if ok then gangData = parsed end end
            if type(gangData) == 'table' then
                result.job2 = gangData.name or 'none'; result.job2Label = gangData.label or result.job2
                result.job2Grade = gangData.grade and gangData.grade.level or 0; result.job2GradeLabel = gangData.grade and gangData.grade.name or '0'
            end
            result.group = 'user'; result.playerInfoFields = Config.PlayerInfoFields
            result.position = nil
            if u.position then local okPos, pos = pcall(json.decode, u.position); if okPos and type(pos) == 'table' then result.position = pos end end
            result.inventory = {}
            finish()
        end)
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM ' .. vehTable .. ' WHERE ' .. vehOwnerCol .. ' = ?', {identifier}, function(count) result.vehiclesCount = count or 0; finish() end)
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_logs WHERE target = ? AND action = "warn"', {identifier}, function(count) result.warnsCount = count or 0; finish() end)
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM admin_logs WHERE target = ? AND action = "kick"', {identifier}, function(count) result.kicksCount = count or 0; finish() end)
        MySQL.Async.fetchAll('SELECT * FROM admin_bans WHERE identifier = ? ORDER BY id DESC', {identifier}, function(bans)
            local banList = {}
            if bans then for _, b in ipairs(bans) do table.insert(banList, { reason = b.reason, admin = b.banner_name or b.banner, active = (b.unbanned_by == nil and (b.expire == nil or b.expire == 0 or b.expire > os.time())) }) end end
            result.bans = banList; result.bansCount = #banList; finish()
        end)
    end
    return Citizen.Await(p)
end)
RegisterNetEvent('tr_adminmenu:offlineSetJob')
AddEventHandler('tr_adminmenu:offlineSetJob', function(identifier, job, grade)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'offline_set_job') then return end
    if not identifier or not job then return end
    grade = grade or 0
    if Framework.Name == 'esx' then
        MySQL.Async.execute('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {job, grade, identifier})
    else
        MySQL.Async.fetchAll('SELECT job FROM players WHERE citizenid = ?', {identifier}, function(rows)
            if not rows or not rows[1] then return end
            local jobData = rows[1].job
            if type(jobData) == 'string' then local ok, parsed = pcall(json.decode, jobData); if ok then jobData = parsed end end
            if type(jobData) ~= 'table' then jobData = {} end
            jobData.name = job; if jobData.grade then jobData.grade.level = grade end
            MySQL.Async.execute('UPDATE players SET job = ? WHERE citizenid = ?', {json.encode(jobData), identifier})
        end)
    end
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'set_job', 'management', 'Offline set job to ' .. job .. ' grade ' .. grade, identifier, '', source, nil)
    SendNotification(source, 'success', locale('offline_job_updated', job))
end)
RegisterNetEvent('tr_adminmenu:offlineSetGroup')
AddEventHandler('tr_adminmenu:offlineSetGroup', function(identifier, group)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'offline_set_group') then return end
    if not identifier or not group then return end
    if Framework.Name == 'esx' then
        local usersTable = Framework.GetUsersTable()
        local idCol = Framework.GetIdentifierColumn()
        MySQL.Async.execute('UPDATE ' .. usersTable .. ' SET `group` = ? WHERE ' .. idCol .. ' = ?', {group, identifier})
    else
        MySQL.Async.fetchAll('SELECT license FROM players WHERE citizenid = ?', {identifier}, function(rows)
            if not rows or not rows[1] or not rows[1].license then
                print('[tr_adminmenu] ^1ERROR: Could not find license for citizenid ' .. tostring(identifier) .. '^7')
                return
            end
            local licenseHash = rows[1].license:gsub('^license:', '')
            local knownGroups = {'god', 'admin', 'owner', 'moderator', 'mod'}
            for _, oldGroup in ipairs(knownGroups) do
                ExecuteCommand(('remove_principal identifier.license:%s qbcore.%s'):format(licenseHash, oldGroup))
            end
            ExecuteCommand(('add_principal identifier.license:%s qbcore.%s'):format(licenseHash, group))
            print(('[tr_adminmenu] ^2Offline set group for license:%s to qbcore.%s^7'):format(licenseHash, group))
        end)
    end
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'set_group', 'management', 'Offline set group to ' .. group, identifier, '', source, nil)
    SendNotification(source, 'success', locale('offline_group_updated', group))
end)
RegisterNetEvent('tr_adminmenu:offlineSetMoney')
AddEventHandler('tr_adminmenu:offlineSetMoney', function(identifier, moneyType, amount)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'offline_set_money') then return end
    if not identifier or not moneyType then return end
    amount = tonumber(amount) or 0
    local usersTable = Framework.GetUsersTable()
    local idCol = Framework.GetIdentifierColumn()
    local moneyCol = Framework.Name == 'esx' and 'accounts' or 'money'
    MySQL.Async.fetchAll('SELECT ' .. moneyCol .. ' FROM ' .. usersTable .. ' WHERE ' .. idCol .. ' = ?', {identifier}, function(rows)
        if not rows or not rows[1] then return SendNotification(source, 'error', locale('player_not_found')) end
        local ok, data = pcall(json.decode, rows[1][moneyCol])
        if not ok or not data then data = {} end
        local key = moneyType
        if Framework.Name ~= 'esx' then
            if moneyType == 'money' then key = 'cash' elseif moneyType == 'black_money' then key = 'crypto' end
        end
        data[key] = amount
        MySQL.Async.execute('UPDATE ' .. usersTable .. ' SET ' .. moneyCol .. ' = ? WHERE ' .. idCol .. ' = ?', {json.encode(data), identifier})
        local adminName = GetFormattedName(source)
        LogAction(Framework.GetIdentifier(source), adminName, 'set_money', 'management', 'Offline set ' .. moneyType .. ' to ' .. amount, identifier, '', source, nil)
        SendNotification(source, 'success', locale('offline_money_set', moneyType, amount))
    end)
end)
RegisterNetEvent('tr_adminmenu:offlineRemoveMoney')
AddEventHandler('tr_adminmenu:offlineRemoveMoney', function(identifier, moneyType, amount)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'offline_remove_money') then return end
    if not identifier or not moneyType then return end
    amount = tonumber(amount) or 0
    local usersTable = Framework.GetUsersTable()
    local idCol = Framework.GetIdentifierColumn()
    local moneyCol = Framework.Name == 'esx' and 'accounts' or 'money'
    MySQL.Async.fetchAll('SELECT ' .. moneyCol .. ' FROM ' .. usersTable .. ' WHERE ' .. idCol .. ' = ?', {identifier}, function(rows)
        if not rows or not rows[1] then return SendNotification(source, 'error', locale('player_not_found')) end
        local ok, data = pcall(json.decode, rows[1][moneyCol])
        if not ok or not data then data = {} end
        local key = moneyType
        if Framework.Name ~= 'esx' then
            if moneyType == 'money' then key = 'cash' elseif moneyType == 'black_money' then key = 'crypto' end
        end
        local current = tonumber(data[key]) or 0
        data[key] = math.max(0, current - amount)
        MySQL.Async.execute('UPDATE ' .. usersTable .. ' SET ' .. moneyCol .. ' = ? WHERE ' .. idCol .. ' = ?', {json.encode(data), identifier})
        local adminName = GetFormattedName(source)
        LogAction(Framework.GetIdentifier(source), adminName, 'remove_money', 'management', 'Offline removed $' .. amount .. ' ' .. moneyType, identifier, '', source, nil)
        SendNotification(source, 'success', locale('offline_money_removed', amount, moneyType))
    end)
end)
RegisterNetEvent('tr_adminmenu:offlineGiveItem')
AddEventHandler('tr_adminmenu:offlineGiveItem', function(identifier, itemName, amount)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'offline_give_item') then return end
    if not identifier or not itemName then return end
    amount = tonumber(amount) or 1
    local usersTable = Framework.GetUsersTable()
    local idCol = Framework.GetIdentifierColumn()
    MySQL.Async.fetchAll('SELECT inventory FROM ' .. usersTable .. ' WHERE ' .. idCol .. ' = ?', {identifier}, function(rows)
        if not rows or not rows[1] then return SendNotification(source, 'error', locale('player_not_found')) end
        local inventory = {}
        if rows[1].inventory and rows[1].inventory ~= '' then
            local ok, parsed = pcall(json.decode, rows[1].inventory)
            if ok and type(parsed) == 'table' then inventory = parsed end
        end
        local found = false
        for i=1, #inventory do
            if inventory[i].name == itemName then inventory[i].count = (inventory[i].count or 0) + amount; found = true; break end
        end
        if not found then
            local maxSlot = 0
            for i=1, #inventory do if inventory[i].slot and inventory[i].slot > maxSlot then maxSlot = inventory[i].slot end end
            table.insert(inventory, {name = itemName, count = amount, slot = maxSlot + 1})
        end
        MySQL.Async.execute('UPDATE ' .. usersTable .. ' SET inventory = ? WHERE ' .. idCol .. ' = ?', {json.encode(inventory), identifier})
        local adminName = GetFormattedName(source)
        LogAction(Framework.GetIdentifier(source), adminName, 'give_item', 'management', 'Offline gave ' .. amount .. 'x ' .. itemName, identifier, '', source, nil)
        SendNotification(source, 'success', locale('offline_item_added', amount, itemName))
    end)
end)
RegisterNetEvent('tr_adminmenu:offlineRemoveItem')
AddEventHandler('tr_adminmenu:offlineRemoveItem', function(identifier, itemName, amount)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'offline_remove_item') then return end
    if not identifier or not itemName then return end
    amount = tonumber(amount) or 1
    local usersTable = Framework.GetUsersTable()
    local idCol = Framework.GetIdentifierColumn()
    MySQL.Async.fetchAll('SELECT inventory FROM ' .. usersTable .. ' WHERE ' .. idCol .. ' = ?', {identifier}, function(rows)
        if not rows or not rows[1] then return SendNotification(source, 'error', locale('player_not_found')) end
        local inventory = {}
        if rows[1].inventory and rows[1].inventory ~= '' then
            local ok, parsed = pcall(json.decode, rows[1].inventory)
            if ok and type(parsed) == 'table' then inventory = parsed end
        end
        local found = false
        for i=1, #inventory do
            if inventory[i].name == itemName then
                inventory[i].count = math.max(0, (inventory[i].count or 0) - amount)
                if inventory[i].count == 0 then table.remove(inventory, i) end
                found = true; break
            end
        end
        if not found then return SendNotification(source, 'error', locale('offline_item_not_found')) end
        MySQL.Async.execute('UPDATE ' .. usersTable .. ' SET inventory = ? WHERE ' .. idCol .. ' = ?', {json.encode(inventory), identifier})
        local adminName = GetFormattedName(source)
        LogAction(Framework.GetIdentifier(source), adminName, 'remove_item', 'management', 'Offline removed ' .. amount .. 'x ' .. itemName, identifier, '', source, nil)
        SendNotification(source, 'success', locale('offline_item_removed', amount, itemName))
    end)
end)
RegisterNetEvent('tr_adminmenu:offlineSpawnVehicle')
AddEventHandler('tr_adminmenu:offlineSpawnVehicle', function(identifier, vehicleModel, plateStr)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'offline_give_vehicle') then return end
    if not identifier or not vehicleModel then return end
    local plate = plateStr
    if not plate or plate == '' then
        plate = string.upper(tostring(math.random(10, 99)) .. string.char(math.random(65, 90)) .. string.char(math.random(65, 90)) .. tostring(math.random(100, 999)))
    end
    local vehTable = Framework.GetVehiclesTable()
    local ownerCol = Framework.GetVehicleOwnerColumn()
    if Framework.Name == 'esx' then
        local vehicleProps = { model = GetHashKey(vehicleModel), plate = plate }
        MySQL.Async.execute('INSERT INTO ' .. vehTable .. ' (' .. ownerCol .. ', plate, vehicle) VALUES (?, ?, ?)', { identifier, plate, json.encode(vehicleProps) })
    else
        MySQL.Async.fetchAll('SELECT license FROM players WHERE citizenid = ?', {identifier}, function(rows)
            local licenseStr = nil
            if rows and rows[1] and rows[1].license then
                licenseStr = rows[1].license
            end
            MySQL.Async.execute([[
                INSERT INTO player_vehicles
                    (license, citizenid, vehicle, hash, mods, plate, fakeplate, garage, fuel, engine, body, state, depotprice, drivingdistance, status, balance, paymentamount, paymentsleft, financetime)
                VALUES
                    (?, ?, ?, ?, ?, ?, ?, ?, 100, 1000, 1000, 1, 0, NULL, NULL, 0, 0, 0, 0)
            ]], { licenseStr, identifier, vehicleModel, tostring(GetHashKey(vehicleModel)), nil, plate, nil, nil })
        end)
    end
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'spawn_vehicle', 'vehicle', 'Offline gave vehicle ' .. vehicleModel .. ' (Plate: ' .. plate .. ')', identifier, '', source, nil)
    SendNotification(source, 'success', locale('offline_vehicle_added', vehicleModel))
end)
RegisterNetEvent('tr_adminmenu:offlineSetPos')
AddEventHandler('tr_adminmenu:offlineSetPos', function(identifier, coords)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'offline_set_position') then return end
    if not identifier or not coords then return end
    local posString = json.encode({ x = coords.x, y = coords.y, z = coords.z })
    local usersTable = Framework.GetUsersTable()
    local idCol = Framework.GetIdentifierColumn()
    MySQL.Async.execute('UPDATE ' .. usersTable .. ' SET position = ? WHERE ' .. idCol .. ' = ?', {posString, identifier})
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'teleport', 'playerstate', 'Offline set position', identifier, '', source, nil)
    SendNotification(source, 'success', locale('offline_position_set'))
end)
RegisterNetEvent('tr_adminmenu:offlineBan')
AddEventHandler('tr_adminmenu:offlineBan', function(identifier, reason, duration)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'ban') then return end
    if not identifier or not reason then return end
    local adminName = GetFormattedName(source)
    local adminIdentifier = Framework.GetIdentifier(source)
    local expire = 0
    if duration and duration > 0 then expire = os.time() + (duration * 60) end
    MySQL.Async.fetchAll('SELECT id FROM admin_bans WHERE identifier = ? AND (expire = 0 OR expire > ?)', {identifier, os.time()}, function(rows)
        if rows and #rows > 0 then return SendNotification(source, 'error', locale('offline_already_banned')) end
        MySQL.Async.execute('INSERT INTO admin_bans (identifier, name, banner, banner_name, reason, expire) VALUES (?, ?, ?, ?, ?, ?)', {
            identifier, 'Offline Player', adminIdentifier, adminName, reason, expire
        }, function()
            LogAction(adminIdentifier, adminName, 'ban', 'moderation', 'Offline banned player: ' .. reason, identifier, '', source, nil)
            SendNotification(source, 'success', locale('offline_player_banned', (duration == 0 and 'Permanently' or duration .. ' minutes')))
            MySQL.Async.fetchAll('SELECT * FROM admin_bans ORDER BY id DESC', {}, function(bans)
                local allPlayers = Framework.GetAllPlayers()
                for _, playerObj in pairs(allPlayers) do
                    local src = Framework.GetPlayerSource(playerObj)
                    if Config.AdminGroups[Framework.GetGroup(src)] then
                        TriggerClientEvent('tr_adminmenu:updateBans', src, bans)
                    end
                end
            end)
        end)
    end)
end)
RegisterNetEvent('tr_adminmenu:offlineWarn')
AddEventHandler('tr_adminmenu:offlineWarn', function(identifier, reason)
    local source = source
    if not IsAdmin(source) or not HasPermission(source, 'warn') then return end
    if not identifier or not reason then return end
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'warn', 'moderation', 'Offline warned player: ' .. reason, identifier, '', source, nil)
    SendNotification(source, 'success', locale('offline_player_warned', reason))
end)
CreateThread(function()
    Wait(1000)
    if Config.SteamWebApiKey and Config.SteamWebApiKey ~= '' then
        print('^2[tr_adminmenu] Steam Web API Key configured.^7')
        for _, playerId in ipairs(GetPlayers()) do GetSteamAvatar(tonumber(playerId)) end
    else
        print('^3[tr_adminmenu] WARNING: Config.SteamWebApiKey is missing.^7')
    end
end)
lib.callback.register('tr_adminmenu:getResources', function(source)
    if not HasPermission(source, 'manage_resources') then return {} end
    local resources = {}
    local count = GetNumResources()
    for i = 0, count - 1 do
        local name = GetResourceByFindIndex(i)
        if name then table.insert(resources, { name = name, state = GetResourceState(name) }) end
    end
    table.sort(resources, function(a, b) return a.name < b.name end)
    return resources
end)
RegisterNetEvent('tr_adminmenu:manageResource')
AddEventHandler('tr_adminmenu:manageResource', function(name, action)
    local source = source
    if not HasPermission(source, 'manage_resources') then return end
    if action == 'start' then ExecuteCommand('start ' .. name)
    elseif action == 'stop' then ExecuteCommand('stop ' .. name)
    elseif action == 'restart' then ExecuteCommand('restart ' .. name) end
    local adminName = GetFormattedName(source)
    LogAction(Framework.GetIdentifier(source), adminName, 'resource_' .. action, 'system', 'Resource ' .. action .. ': ' .. name, '', '', source, nil)
    SendNotification(source, 'success', locale('resource_actioned', action, name))
end)
CreateThread(function()
    if Config.LogDeletionHours and Config.LogDeletionHours > 0 then
        while true do
            Wait(1800000)
            MySQL.Async.execute('DELETE FROM admin_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL ? HOUR)', { Config.LogDeletionHours }, function(rowsChanged)
                if rowsChanged > 0 then print(('[tr_adminmenu] Auto-deleted %d old log entries'):format(rowsChanged)) end
            end)
        end
    end
end)
