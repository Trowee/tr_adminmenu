lib.locale()
local quickMenuOpen = false
local adminPanelOpen = false
local isSpectating = false
local spectateTarget = nil
local spectateOrigCoords = nil
local function IsAdmin()
    local group = lib.callback.await('tr_adminmenu:getMyGroup', false)
    return Config.AdminGroups[group] == true
end
local function GetAdminGroup()
    return lib.callback.await('tr_adminmenu:getMyGroup', false)
end
local function SendNUI(action, payload)
    SendNUIMessage({ action = action, payload = payload })
end
local uiLocales = {}
CreateThread(function()
    local jsonStr = LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')
    if jsonStr then
        local ok, parsed = pcall(json.decode, jsonStr)
        if ok and type(parsed) == 'table' then uiLocales = parsed end
    end
end)
local function UpdatePlayerList()
    local players = lib.callback.await('tr_adminmenu:getPlayers', false)
    SendNUI('setPlayers', players)
end
RegisterCommand(Config.Commands.QuickMenu.command, function()
    if not IsAdmin() then return end
    local allowed = lib.callback.await('tr_adminmenu:checkDuty', false)
    if not allowed then
        TriggerEvent('tr_adminmenu:notification', 'error', locale('not_on_duty'))
        return
    end
    quickMenuOpen = not quickMenuOpen
    if quickMenuOpen then
        adminPanelOpen = false
        SendNUI('closeAdminPanel')
        local perms = lib.callback.await('tr_adminmenu:getMyPermissions', false)
        SendNUI('setMyPermissions', perms)
        SendNUI('setLocales', uiLocales)
        SendNUI('openQuickMenu')
        SendNUI('setServerName', Config.ServerName)
        UpdatePlayerList()
        SetNuiFocus(true, true)
    else
        SendNUI('closeQuickMenu')
        SetNuiFocus(false, false)
    end
end, false)
RegisterKeyMapping(Config.Commands.QuickMenu.command, Config.Commands.QuickMenu.description, 'keyboard', Config.Commands.QuickMenu.defaultKey)
RegisterCommand(Config.Commands.AdminPanel.command, function()
    if not IsAdmin() then return end
    if adminPanelOpen then
        adminPanelOpen = false
        SendNUI('closeAdminPanel')
        SetNuiFocus(false, false)
        TriggerServerEvent('tr_adminmenu:endDuty')
        return
    end
    local allowed = lib.callback.await('tr_adminmenu:checkDuty', false)
    if not allowed then
        TriggerEvent('tr_adminmenu:notification', 'error', locale('not_on_duty'))
        return
    end
    adminPanelOpen = true
    quickMenuOpen = false
    SendNUI('closeQuickMenu')
    local perms = lib.callback.await('tr_adminmenu:getMyPermissions', false)
    SendNUI('setMyPermissions', perms)
    SendNUI('setLocales', uiLocales)
    SendNUI('openAdminPanel')
    SendNUI('setServerName', Config.ServerName)
    SendNUI('setMyName', GetPlayerName(PlayerId()))
    SendNUI('setMyGroup', GetAdminGroup())
    SendNUI('setMyId', GetPlayerServerId(PlayerId()))
    local avatar = lib.callback.await('tr_adminmenu:getMyAvatar', false)
    SendNUI('setMyAvatar', avatar)
    UpdatePlayerList()
    SetNuiFocus(true, true)
    TriggerServerEvent('tr_adminmenu:startDuty')
end, false)
RegisterKeyMapping(Config.Commands.AdminPanel.command, Config.Commands.AdminPanel.description, 'keyboard', Config.Commands.AdminPanel.defaultKey)
RegisterNUICallback('closeQuickMenu', function(_, cb)
    quickMenuOpen = false
    SetNuiFocus(false, false)
    cb({})
end)
RegisterNUICallback('closeAdminPanel', function(_, cb)
    adminPanelOpen = false
    SetNuiFocus(false, false)
    TriggerServerEvent('tr_adminmenu:endDuty')
    cb({})
end)
RegisterNUICallback('closeWarnModal', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)
RegisterNUICallback('getAllJobs', function(_, cb)
    local jobs = lib.callback.await('tr_adminmenu:getAllJobs', false)
    SendNUI('receiveAllJobs', jobs)
    cb({})
end)
RegisterNUICallback('getAnalytics', function(_, cb)
    local data = lib.callback.await('tr_adminmenu:getAnalytics', false)
    SendNUI('receiveAnalytics', data)
    cb({})
end)
RegisterNUICallback('closeDMReceiveModal', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)
RegisterNUICallback('closeAnnouncementReceiveModal', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)
RegisterNUICallback('quickAction', function(data, cb)
    local action = data.action
    local targetId = data.targetId
    local perms = lib.callback.await('tr_adminmenu:getMyPermissions', false)
    if action == 'noclip' and perms.noclip then
        TriggerEvent('tr_adminmenu:toggleNoclip')
    elseif action == 'goto' and targetId then
        TriggerServerEvent('tr_adminmenu:goto', targetId)
    elseif action == 'bring' and targetId then
        TriggerServerEvent('tr_adminmenu:bring', targetId)
    elseif action == 'spawnvehicle' and perms.spawn_vehicle then
        SpawnAdminVehicle()
    elseif action == 'dv' and perms.manage_vehicles then
        DeleteCurrentVehicle()
    elseif action == 'fix' and perms.manage_vehicles then
        FixCurrentVehicle()
    elseif action == 'heal' and targetId then
        TriggerServerEvent('tr_adminmenu:heal', targetId)
    elseif action == 'revive' and targetId then
        TriggerServerEvent('tr_adminmenu:revive', targetId)
    elseif action == 'kill' and targetId then
        TriggerServerEvent('tr_adminmenu:kill', targetId)
    elseif action == 'kick' and targetId then
        TriggerServerEvent('tr_adminmenu:kick', targetId, data.reason or 'Kicked via Quick Actions')
    elseif action == 'tpm' and perms.teleport then
        local waypoint = GetFirstBlipInfoId(8)
        if DoesBlipExist(waypoint) then
            local coords = GetBlipInfoIdCoord(waypoint)
            local found, z = false, 0.0
            for i = 1, 1000 do
                SetEntityCoordsNoOffset(PlayerPedId(), coords.x, coords.y, i * 1.0, false, false, false)
                Wait(5)
                found, z = GetGroundZFor_3dCoord(coords.x, coords.y, i * 1.0, false)
                if found then break end
            end
            if found then
                SetEntityCoordsNoOffset(PlayerPedId(), coords.x, coords.y, z + 1.0, false, false, false)
            else
                SetEntityCoordsNoOffset(PlayerPedId(), coords.x, coords.y, 300.0, false, false, false)
            end
        else
            TriggerEvent('tr_adminmenu:notification', 'error', 'No waypoint set')
        end
    end
    cb({})
end)
RegisterNUICallback('sendAnnouncement', function(data, cb)
    local msg = data.text or data.message
    if msg then TriggerServerEvent('tr_adminmenu:announce', msg) end
    cb({})
end)
RegisterNUICallback('adminAction', function(data, cb)
    local action = data.action
    local perms = lib.callback.await('tr_adminmenu:getMyPermissions', false)
    if action == 'dvall' and perms.delete_all_vehicles then
        TriggerServerEvent('tr_adminmenu:dvall')
    elseif action == 'noclip' and perms.noclip then
        TriggerEvent('tr_adminmenu:toggleNoclip')
    elseif action == 'spawnvehicle' and perms.spawn_vehicle then
        SpawnAdminVehicle()
    elseif action == 'dv' and perms.manage_vehicles then
        DeleteCurrentVehicle()
    elseif action == 'fix' and perms.manage_vehicles then
        FixCurrentVehicle()
    elseif action == 'stopspectate' then
        StopSpectate()
    end
    cb({})
end)
RegisterNUICallback('playerAction', function(data, cb)
    local action = data.action
    local targetId = data.targetId
    if not targetId then cb({}) return end
    local perms = lib.callback.await('tr_adminmenu:getMyPermissions', false)
    if action == 'goto' then TriggerServerEvent('tr_adminmenu:goto', targetId)
    elseif action == 'bring' then TriggerServerEvent('tr_adminmenu:bring', targetId)
    elseif action == 'spectate' and perms.spectate then StartSpectate(targetId)
    elseif action == 'heal' then TriggerServerEvent('tr_adminmenu:heal', targetId)
    elseif action == 'revive' then TriggerServerEvent('tr_adminmenu:revive', targetId)
    elseif action == 'kill' then TriggerServerEvent('tr_adminmenu:kill', targetId)
    elseif action == 'freeze' then TriggerServerEvent('tr_adminmenu:freeze', targetId)
    elseif action == 'unfreeze' then TriggerServerEvent('tr_adminmenu:unfreeze', targetId)
    elseif action == 'clearinventory' then TriggerServerEvent('tr_adminmenu:clearInventory', targetId)
    elseif action == 'clearweapons' then TriggerServerEvent('tr_adminmenu:clearWeapons', targetId)
    elseif action == 'setjob' then TriggerServerEvent('tr_adminmenu:setJob', targetId, data.job, data.grade)
    elseif action == 'setgroup' then TriggerServerEvent('tr_adminmenu:setGroup', targetId, data.group)
    elseif action == 'setmoney' then TriggerServerEvent('tr_adminmenu:setMoney', targetId, data.moneyType, data.amount)
    elseif action == 'removemoney' then TriggerServerEvent('tr_adminmenu:removeMoney', targetId, data.moneyType, data.amount)
    elseif action == 'giveitem' then TriggerServerEvent('tr_adminmenu:giveItem', targetId, data.itemName, data.itemCount)
    elseif action == 'removeitem' then TriggerServerEvent('tr_adminmenu:removeItem', targetId, data.itemName, data.itemCount)
    elseif action == 'senddm' then TriggerServerEvent('tr_adminmenu:sendDM', targetId, data.message)
    end
    cb({})
end)
RegisterNUICallback('takeScreenshot', function(data, cb)
    local targetId = data.targetId
    if not targetId then cb({}) return end
    if GetResourceState('screencapture') ~= 'started' then
        SendNUI('notification', { type = 'error', text = 'screencapture resource is not running!' })
        cb({}) return
    end
    exports['screencapture']:requestScreenshot({ encoding = 'webp' }, function(screenshotData)
        SendNUI('receiveScreenshot', screenshotData)
    end)
    TriggerServerEvent('tr_adminmenu:log', 'screenshot', 'screenshot', 'Took screenshot of player ID: ' .. targetId)
    cb({})
end)
RegisterNUICallback('getOfflinePlayers', function(_, cb)
    local players = lib.callback.await('tr_adminmenu:getOfflinePlayers', false)
    SendNUI('setOfflinePlayers', players)
    cb({})
end)
RegisterNUICallback('getOfflinePlayerData', function(data, cb)
    local playerData = lib.callback.await('tr_adminmenu:getOfflinePlayerData', false, data.identifier)
    SendNUI('setSelectedOfflinePlayer', playerData)
    cb({})
end)
RegisterNUICallback('offlinePlayerAction', function(data, cb)
    local action = data.action
    local identifier = data.identifier
    if not identifier then cb({}) return end
    local perms = lib.callback.await('tr_adminmenu:getMyPermissions', false)
    if action == 'setjob' and perms.offline_set_job then TriggerServerEvent('tr_adminmenu:offlineSetJob', identifier, data.job, data.grade)
    elseif action == 'setgroup' and perms.offline_set_group then TriggerServerEvent('tr_adminmenu:offlineSetGroup', identifier, data.group)
    elseif action == 'setmoney' and perms.offline_set_money then TriggerServerEvent('tr_adminmenu:offlineSetMoney', identifier, data.moneyType, data.amount)
    elseif action == 'removemoney' and perms.offline_remove_money then TriggerServerEvent('tr_adminmenu:offlineRemoveMoney', identifier, data.moneyType, data.amount)
    elseif action == 'giveitem' and perms.offline_give_item then TriggerServerEvent('tr_adminmenu:offlineGiveItem', identifier, data.itemName, data.amount)
    elseif action == 'removeitem' and perms.offline_remove_item then TriggerServerEvent('tr_adminmenu:offlineRemoveItem', identifier, data.item, data.count)
    elseif action == 'spawnvehicle' and perms.offline_give_vehicle then TriggerServerEvent('tr_adminmenu:offlineSpawnVehicle', identifier, data.model, data.plate)
    elseif action == 'setpos' and perms.offline_set_position then TriggerServerEvent('tr_adminmenu:offlineSetPos', identifier, data.coords)
    end
    cb({})
end)
RegisterNUICallback('offlineWarn', function(data, cb)
    local identifier = data.identifier
    local reason = data.reason
    if not identifier or not reason then cb({}) return end
    local perms = lib.callback.await('tr_adminmenu:getMyPermissions', false)
    if perms.warn then TriggerServerEvent('tr_adminmenu:offlineWarn', identifier, reason) end
    cb({})
end)
RegisterNUICallback('offlineBan', function(data, cb)
    local identifier = data.identifier
    local reason = data.reason
    local duration = data.duration
    if not identifier or not reason or not duration then cb({}) return end
    local perms = lib.callback.await('tr_adminmenu:getMyPermissions', false)
    if perms.ban then TriggerServerEvent('tr_adminmenu:offlineBan', identifier, reason, duration) end
    cb({})
end)
RegisterNUICallback('getAdminPos', function(_, cb)
    local coords = GetEntityCoords(PlayerPedId())
    cb({ x = coords.x, y = coords.y, z = coords.z })
end)
RegisterNUICallback('getPlayers', function(_, cb)
    UpdatePlayerList()
    cb({})
end)
RegisterNUICallback('getPlayerData', function(data, cb)
    local playerData = lib.callback.await('tr_adminmenu:getPlayerData', false, data.id)
    SendNUI('setSelectedPlayer', playerData)
    if playerData and data.withMugshot then
        SendNUI('setSelectedPlayerMugshot', nil)
        TriggerServerEvent('tr_adminmenu:requestAppearance', data.id)
    end
    cb({})
end)
RegisterNUICallback('getPlayerInventory', function(data, cb)
    TriggerServerEvent('tr_adminmenu:getPlayerInventory', data.id)
    cb({})
end)
RegisterNUICallback('getPlayerBans', function(data, cb)
    local bans = lib.callback.await('tr_adminmenu:getPlayerBans', false, data.targetId)
    SendNUI('setPlayerBans', bans)
    cb({})
end)
RegisterNUICallback('banPlayer', function(data, cb)
    TriggerServerEvent('tr_adminmenu:ban', data.targetId, data.duration, data.reason)
    cb({})
end)
RegisterNUICallback('kickPlayer', function(data, cb)
    TriggerServerEvent('tr_adminmenu:kick', data.targetId, data.reason)
    cb({})
end)
RegisterNUICallback('unbanPlayer', function(data, cb)
    TriggerServerEvent('tr_adminmenu:unban', data.banId)
    cb({})
end)
RegisterNUICallback('sendStaffChat', function(data, cb)
    TriggerServerEvent('tr_adminmenu:staffChat', data.text)
    cb({})
end)
RegisterNUICallback('warnPlayer', function(data, cb)
    TriggerServerEvent('tr_adminmenu:warn', data.targetId, data.reason)
    cb({})
end)
RegisterNUICallback('getWarnings', function(data, cb)
    local warns = lib.callback.await('tr_adminmenu:getWarnings', false, data.targetId)
    SendNUI('setPlayerWarnings', warns)
    cb({})
end)
RegisterNUICallback('getLogs', function(_, cb)
    local logs = lib.callback.await('tr_adminmenu:getLogs', false)
    SendNUI('setLogs', logs)
    cb({})
end)
RegisterNUICallback('getBans', function(_, cb)
    local bans = lib.callback.await('tr_adminmenu:getBans', false)
    SendNUI('setBans', bans)
    cb({})
end)
RegisterNUICallback('getOnlineAdmins', function(_, cb)
    local admins = lib.callback.await('tr_adminmenu:getOnlineAdmins', false)
    SendNUI('setOnlineAdmins', admins)
    cb({})
end)
RegisterNUICallback('getAllItems', function(data, cb)
    local items = lib.callback.await('tr_adminmenu:getAllItems', false)
    SendNUI('setAllItems', items)
    cb({})
end)
RegisterNUICallback('getVehicles', function(_, cb)
    local vehicles = lib.callback.await('tr_adminmenu:getVehicles', false)
    SendNUI('setVehicles', vehicles)
    cb({})
end)
RegisterNUICallback('removeVehicle', function(data, cb)
    TriggerServerEvent('tr_adminmenu:removeVehicle', data.plate)
    cb({})
end)
RegisterNUICallback('changePlate', function(data, cb)
    TriggerServerEvent('tr_adminmenu:changePlate', data.oldPlate, data.newPlate)
    cb({})
end)
RegisterNUICallback('getJobStats', function(_, cb)
    local stats = lib.callback.await('tr_adminmenu:getJobStats', false)
    SendNUI('setJobStats', stats)
    cb({})
end)
RegisterNUICallback('getTopPlayers', function(_, cb)
    local data = lib.callback.await('tr_adminmenu:getTopPlayers', false)
    SendNUI('setTopPlayers', data)
    cb({})
end)
RegisterNUICallback('getWeeklyStats', function(_, cb)
    local stats = lib.callback.await('tr_adminmenu:getWeeklyStats', false)
    SendNUI('setWeeklyStats', stats)
    cb({})
end)
RegisterNUICallback('addVehicle', function(data, cb)
    TriggerServerEvent('tr_adminmenu:addVehicle', data.playerId, data.model, data.plate)
    cb({})
end)
function SpawnAdminVehicle()
    local model = Config.AdminVehicle.model
    local plate = Config.AdminVehicle.plate
    Framework.SpawnVehicle(model, GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()), function(vehicle)
        if vehicle then
            SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
            SetVehicleNumberPlateText(vehicle, plate)
            SetEntityAsMissionEntity(vehicle, true, true)
            SetVehicleOnGroundProperly(vehicle)
            TriggerServerEvent('tr_adminmenu:log', 'spawn', 'vehicle', 'Spawned admin vehicle: ' .. model)
        end
    end)
end
function DeleteCurrentVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
    end
    if vehicle ~= 0 then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        TriggerServerEvent('tr_adminmenu:log', 'delete', 'vehicle', 'Deleted vehicle')
    end
end
function FixCurrentVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        TriggerServerEvent('tr_adminmenu:log', 'fix', 'vehicle', 'Fixed vehicle')
    end
end
local function GetOnlinePlayerIds()
    local ids = {}
    for _, playerId in ipairs(GetActivePlayers()) do
        local sId = GetPlayerServerId(playerId)
        if sId and sId > 0 then ids[#ids+1] = sId end
    end
    table.sort(ids)
    return ids
end
local function RunSpectateLoop(targetServerId)
    Citizen.CreateThread(function()
        while isSpectating and spectateTarget == targetServerId do
            Citizen.Wait(500)
            local playerIdx = GetPlayerFromServerId(targetServerId)
            if playerIdx ~= -1 then
                local tPed = GetPlayerPed(playerIdx)
                if tPed > 0 then
                    local coords = GetEntityCoords(tPed)
                    SetEntityCoordsNoOffset(PlayerPedId(), coords.x, coords.y, coords.z - 15.0, false, false, false)
                else
                    TriggerEvent('tr_adminmenu:notification', 'error', locale('spectate_target_lost'))
                    StopSpectate()
                    break
                end
            else
                TriggerEvent('tr_adminmenu:notification', 'error', locale('player_left_server'))
                StopSpectate()
                break
            end
        end
    end)
end
function StartSpectate(targetId)
    local targetServerId = targetId
    if targetServerId == GetPlayerServerId(PlayerId()) then
        TriggerEvent('tr_adminmenu:notification', 'error', locale('cannot_spectate_self'))
        return
    end
    local playerIdx = GetPlayerFromServerId(targetServerId)
    local targetPed = 0
    if playerIdx ~= -1 then targetPed = GetPlayerPed(playerIdx) end
    local myOrigCoords = spectateOrigCoords
    if not isSpectating then
        myOrigCoords = GetEntityCoords(PlayerPedId())
        spectateOrigBucket = lib.callback.await('tr_adminmenu:getMyBucket', false)
    else
        NetworkSetInSpectatorMode(false, PlayerPedId())
        isSpectating = false
    end
    if targetPed == 0 or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(targetPed)) > 50.0 then
        TriggerEvent('tr_adminmenu:notification', 'warning', locale('teleporting_to_target'))
        spectateOrigCoords = myOrigCoords
        TriggerServerEvent('tr_adminmenu:log', 'spectate', 'spectate', 'Teleporting to spectate player ID: ' .. targetServerId)
        local data = lib.callback.await('tr_adminmenu:getCoords', false, targetServerId)
        if data and data.coords then
            local coords = data.coords
            TriggerServerEvent('tr_adminmenu:setPlayerBucket', data.bucket or 0)
            SetEntityVisible(PlayerPedId(), false, false)
            SetEntityInvincible(PlayerPedId(), true)
            SetEntityCollision(PlayerPedId(), false, false)
            FreezeEntityPosition(PlayerPedId(), true)
            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 2.0, false, false, false, false)
            local timeout = 0
            while targetPed == 0 and timeout < 20 do
                Wait(250)
                targetPed = GetPlayerPed(GetPlayerFromServerId(targetServerId))
                timeout = timeout + 1
            end
            if targetPed == 0 then
                local idx = GetPlayerFromServerId(targetServerId)
                if idx ~= -1 then targetPed = GetPlayerPed(idx) end
                if targetPed == 0 then
                    TriggerEvent('tr_adminmenu:notification', 'error', locale('player_not_streamed'))
                    if spectateOrigCoords then SetEntityCoords(PlayerPedId(), spectateOrigCoords.x, spectateOrigCoords.y, spectateOrigCoords.z, false, false, false, false); spectateOrigCoords = nil end
                    if spectateOrigBucket ~= nil then TriggerServerEvent('tr_adminmenu:setPlayerBucket', spectateOrigBucket); spectateOrigBucket = nil end
                    SetEntityVisible(PlayerPedId(), true, false); SetEntityInvincible(PlayerPedId(), false)
                    SetEntityCollision(PlayerPedId(), true, true); FreezeEntityPosition(PlayerPedId(), false)
                    return
                end
            end
            TriggerEvent('tr_adminmenu:notification', 'success', locale('spectating_player', targetServerId))
            isSpectating = true
            spectateTarget = targetServerId
            NetworkSetInSpectatorMode(true, targetPed)
            SendNUI('showControlsOverlay', { mode = 'spectate', targetId = targetServerId })
            TriggerServerEvent('tr_adminmenu:log', 'spectate', 'spectate', 'Started spectating player ID: ' .. targetServerId)
            RunSpectateLoop(targetServerId)
        else
            TriggerEvent('tr_adminmenu:notification', 'error', locale('could_not_get_coords'))
            if spectateOrigCoords then SetEntityCoordsNoOffset(PlayerPedId(), spectateOrigCoords.x, spectateOrigCoords.y, spectateOrigCoords.z, false, false, false); spectateOrigCoords = nil end
            if spectateOrigBucket ~= nil then TriggerServerEvent('tr_adminmenu:setPlayerBucket', spectateOrigBucket); spectateOrigBucket = nil end
            SetEntityVisible(PlayerPedId(), true, false); SetEntityInvincible(PlayerPedId(), false)
            SetEntityCollision(PlayerPedId(), true, true); FreezeEntityPosition(PlayerPedId(), false)
        end
        return
    end
    TriggerEvent('tr_adminmenu:notification', 'success', locale('spectating_player', targetServerId))
    spectateOrigCoords = myOrigCoords
    isSpectating = true
    spectateTarget = targetServerId
    SetEntityVisible(PlayerPedId(), false, false); SetEntityInvincible(PlayerPedId(), true)
    SetEntityCollision(PlayerPedId(), false, false); FreezeEntityPosition(PlayerPedId(), true)
    NetworkSetInSpectatorMode(true, targetPed)
    SendNUI('showControlsOverlay', { mode = 'spectate', targetId = targetServerId })
    TriggerServerEvent('tr_adminmenu:log', 'spectate', 'spectate', 'Started spectating player ID: ' .. targetServerId)
    RunSpectateLoop(targetServerId)
end
function StopSpectate()
    if not isSpectating then return end
    NetworkSetInSpectatorMode(false, PlayerPedId())
    SetEntityVisible(PlayerPedId(), true, false)
    SetEntityInvincible(PlayerPedId(), false)
    SetEntityCollision(PlayerPedId(), true, true)
    FreezeEntityPosition(PlayerPedId(), false)
    if spectateOrigCoords then
        SetEntityCoords(PlayerPedId(), spectateOrigCoords.x, spectateOrigCoords.y, spectateOrigCoords.z, false, false, false, false)
    end
    if spectateOrigBucket ~= nil then
        TriggerServerEvent('tr_adminmenu:setPlayerBucket', spectateOrigBucket)
    end
    isSpectating = false
    spectateTarget = nil
    spectateOrigCoords = nil
    spectateOrigBucket = nil
    SendNUI('hideControlsOverlay', {})
    TriggerServerEvent('tr_adminmenu:log', 'spectate', 'spectate', 'Stopped spectating')
end
local freecamActive = false
local freecamCam = nil
local freecamPos = nil
local freecamRot = nil
local FREECAM_SPEED = 0.5
local FREECAM_SPEED_FAST = 1.5
local FREECAM_SENSITIVITY = 3.0
RegisterNetEvent('tr_adminmenu:toggleNoclip')
AddEventHandler('tr_adminmenu:toggleNoclip', function()
    if freecamActive then StopFreecam() else StartFreecam() end
end)
function StartFreecam()
    if freecamActive then return end
    freecamActive = true
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    freecamPos = vector3(pos.x, pos.y, pos.z + 2.0)
    freecamRot = vector3(0.0, 0.0, heading)
    if adminPanelOpen then
        adminPanelOpen = false
        SendNUI('closeAdminPanel')
        SetNuiFocus(false, false)
        TriggerServerEvent('tr_adminmenu:endDuty')
    end
    if quickMenuOpen then
        quickMenuOpen = false
        SendNUI('closeQuickMenu')
        SetNuiFocus(false, false)
    end
    SendNUI('showControlsOverlay', { mode = 'noclip' })
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetLocalPlayerInvisibleLocally(true)
    freecamCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', freecamPos.x, freecamPos.y, freecamPos.z, freecamRot.x, freecamRot.y, freecamRot.z, 70.0, false, 0)
    SetCamActive(freecamCam, true)
    RenderScriptCams(true, true, 500, true, false)
    Citizen.CreateThread(function()
        while freecamActive do
            Citizen.Wait(0)
            local ped2 = PlayerPedId()
            local mouseX = GetDisabledControlNormal(0, 1) * FREECAM_SENSITIVITY
            local mouseY = GetDisabledControlNormal(0, 2) * FREECAM_SENSITIVITY
            local newRotX = freecamRot.x - mouseY
            local newRotZ = freecamRot.z - mouseX
            if newRotX > 89.0 then newRotX = 89.0 end
            if newRotX < -89.0 then newRotX = -89.0 end
            freecamRot = vector3(newRotX, 0.0, newRotZ)
            local speed = FREECAM_SPEED
            if IsDisabledControlPressed(0, Config.Keybinds.freecam_speed_boost) then speed = FREECAM_SPEED_FAST end
            local radZ = math.rad(freecamRot.z)
            local radX = math.rad(freecamRot.x)
            local cosZ = math.cos(radZ)
            local sinZ = math.sin(radZ)
            local cosX = math.cos(radX)
            local forward = vector3(-sinZ * cosX, cosZ * cosX, math.sin(radX))
            local right = vector3(cosZ, sinZ, 0.0)
            local moveX, moveY, moveZ = 0.0, 0.0, 0.0
            if IsDisabledControlPressed(0, Config.Keybinds.freecam_forward) then moveX = moveX + forward.x * speed; moveY = moveY + forward.y * speed; moveZ = moveZ + forward.z * speed end
            if IsDisabledControlPressed(0, Config.Keybinds.freecam_backward) then moveX = moveX - forward.x * speed; moveY = moveY - forward.y * speed; moveZ = moveZ - forward.z * speed end
            if IsDisabledControlPressed(0, Config.Keybinds.freecam_left) then moveX = moveX - right.x * speed; moveY = moveY - right.y * speed end
            if IsDisabledControlPressed(0, Config.Keybinds.freecam_right) then moveX = moveX + right.x * speed; moveY = moveY + right.y * speed end
            if IsDisabledControlPressed(0, Config.Keybinds.freecam_down) then moveZ = moveZ - speed end
            if IsDisabledControlPressed(0, Config.Keybinds.freecam_up) then moveZ = moveZ + speed end
            freecamPos = vector3(freecamPos.x + moveX, freecamPos.y + moveY, freecamPos.z + moveZ)
            SetCamCoord(freecamCam, freecamPos.x, freecamPos.y, freecamPos.z)
            SetCamRot(freecamCam, freecamRot.x, freecamRot.y, freecamRot.z, 2)
            SetFocusPosAndVel(freecamPos.x, freecamPos.y, freecamPos.z, 0.0, 0.0, 0.0)
            SetEntityCoordsNoOffset(ped2, freecamPos.x, freecamPos.y, freecamPos.z, false, false, false)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
        end
    end)
end
function StopFreecam()
    if not freecamActive then return end
    freecamActive = false
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetLocalPlayerInvisibleLocally(false)
    local startX, startY, startZ = freecamPos.x, freecamPos.y, freecamPos.z
    local groundZ = startZ
    local found = false
    for attempt = 1, 3 do
        local ok, z = GetGroundZFor_3dCoord(startX, startY, startZ + 100.0, false)
        if ok then groundZ = z + 1.0; found = true; break end
        Wait(50)
    end
    if found and (startZ - groundZ) > 3.0 then
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, false)
        SetEntityHeading(ped, freecamRot.z)
        local dropZ = startZ
        local dropSpeed = 5.0
        while dropZ > groundZ + 2.0 do
            dropZ = dropZ - dropSpeed
            if dropZ < groundZ + 1.0 then dropZ = groundZ + 1.0 end
            SetEntityCoordsNoOffset(ped, startX, startY, dropZ, false, false, false)
            Wait(0)
        end
        SetEntityCoordsNoOffset(ped, startX, startY, groundZ, false, false, false)
        Wait(200)
        SetEntityInvincible(ped, false)
    elseif found then
        SetEntityCoordsNoOffset(ped, startX, startY, groundZ, false, false, false)
        SetEntityHeading(ped, freecamRot.z)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
    else
        SetEntityCoordsNoOffset(ped, startX, startY, startZ, false, false, false)
        SetEntityHeading(ped, freecamRot.z)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
    end
    RenderScriptCams(false, true, 500, true, false)
    if freecamCam then DestroyCam(freecamCam, false); freecamCam = nil end
    ClearFocus()
    SendNUI('hideControlsOverlay', {})
end
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isSpectating then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
            if IsDisabledControlJustPressed(0, Config.Keybinds.spectate_exit) then StopSpectate() end
            if IsDisabledControlJustPressed(0, Config.Keybinds.spectate_next) then
                local ids = GetOnlinePlayerIds()
                local myId = GetPlayerServerId(PlayerId())
                local nextId = nil
                for i, id in ipairs(ids) do if id > spectateTarget and id ~= myId then nextId = id; break end end
                if not nextId then for i, id in ipairs(ids) do if id ~= myId then nextId = id; break end end end
                if nextId then SendNUI('showControlsOverlay', { mode = 'spectate', targetId = nextId }); StartSpectate(nextId) end
            end
            if IsDisabledControlJustPressed(0, Config.Keybinds.spectate_prev) then
                local ids = GetOnlinePlayerIds()
                local myId = GetPlayerServerId(PlayerId())
                local prevId = nil
                for i = #ids, 1, -1 do if ids[i] < spectateTarget and ids[i] ~= myId then prevId = ids[i]; break end end
                if not prevId then for i = #ids, 1, -1 do if ids[i] ~= myId then prevId = ids[i]; break end end end
                if prevId then SendNUI('showControlsOverlay', { mode = 'spectate', targetId = prevId }); StartSpectate(prevId) end
            end
        end
        if freecamActive then
            DisableControlAction(0, Config.Keybinds.noclip_exit, true)
            if IsDisabledControlJustPressed(0, Config.Keybinds.noclip_exit) then StopFreecam() end
        end
        if not isSpectating and not freecamActive then Citizen.Wait(200) end
    end
end)
RegisterNUICallback('getAvailableGroups', function(data, cb)
    local groups = lib.callback.await('tr_adminmenu:getAvailableGroups', false)
    SendNUI('setAvailableGroups', groups)
    cb({})
end)
RegisterNUICallback('getResources', function(data, cb)
    local resources = lib.callback.await('tr_adminmenu:getResources', false)
    SendNUI('setResources', resources)
    cb({})
end)
RegisterNUICallback('manageResource', function(data, cb)
    TriggerServerEvent('tr_adminmenu:manageResource', data.name, data.action)
    cb({})
end)
RegisterNUICallback('checkDuty', function(data, cb)
    local allowed = lib.callback.await('tr_adminmenu:checkDuty', false)
    if not allowed then
        SendNUI('closeAdminPanel')
        TriggerEvent('tr_adminmenu:notification', 'error', 'You are not on admin duty.')
    end
    cb({})
end)
RegisterNetEvent('tr_adminmenu:teleportTo')
AddEventHandler('tr_adminmenu:teleportTo', function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
end)
RegisterNetEvent('tr_adminmenu:freeze')
AddEventHandler('tr_adminmenu:freeze', function() FreezeEntityPosition(PlayerPedId(), true) end)
RegisterNetEvent('tr_adminmenu:unfreeze')
AddEventHandler('tr_adminmenu:unfreeze', function() FreezeEntityPosition(PlayerPedId(), false) end)
RegisterNetEvent('tr_adminmenu:heal')
AddEventHandler('tr_adminmenu:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
end)
RegisterNetEvent('tr_adminmenu:kill')
AddEventHandler('tr_adminmenu:kill', function() SetEntityHealth(PlayerPedId(), 0) end)
RegisterNetEvent('tr_adminmenu:revive')
AddEventHandler('tr_adminmenu:revive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPlayerInvincible(PlayerId(), false)
    ClearPedBloodDamage(ped)
    ClearPedTasks(ped)
    if Framework.Name == 'esx' then
        TriggerEvent('esx_ambulancejob:revive')
        TriggerEvent('esx:onPlayerSpawn')
    else
        TriggerEvent('hospital:client:Revive')
    end
end)
RegisterNetEvent('tr_adminmenu:deleteAllVehicles')
AddEventHandler('tr_adminmenu:deleteAllVehicles', function()
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then SetEntityAsMissionEntity(vehicle, true, true); DeleteEntity(vehicle) end
    end
end)
RegisterNetEvent('tr_adminmenu:receiveAnnouncement')
AddEventHandler('tr_adminmenu:receiveAnnouncement', function(data)
    SendNUI('openAnnouncement', { text = data.message, admin = data.admin })
end)
RegisterNetEvent('tr_adminmenu:staffChatMsg')
AddEventHandler('tr_adminmenu:staffChatMsg', function(msg) SendNUI('addStaffMessage', msg) end)
RegisterNetEvent('tr_adminmenu:receiveInventory')
AddEventHandler('tr_adminmenu:receiveInventory', function(inventory) SendNUI('setSelectedPlayerInventory', inventory) end)
RegisterNetEvent('tr_adminmenu:updateBans')
AddEventHandler('tr_adminmenu:updateBans', function(bans) SendNUI('setBans', bans) end)
RegisterNetEvent('tr_adminmenu:notification')
AddEventHandler('tr_adminmenu:notification', function(type, text)
    SendNUI('createNotification', { type = type, text = text })
end)
local function ApplyAppearance(ped, appearance)
    if appearance.headBlend then
        local hb = appearance.headBlend
        SetPedHeadBlendData(ped, tonumber(hb.shapeFirst) or 0, tonumber(hb.shapeSecond) or 0, tonumber(hb.shapeThird) or 0, tonumber(hb.skinFirst) or 0, tonumber(hb.skinSecond) or 0, tonumber(hb.skinThird) or 0, tonumber(hb.shapeMix) or 0.0, tonumber(hb.skinMix) or 0.0, tonumber(hb.thirdMix) or 0.0, false)
    end
    if appearance.components then for id, data in pairs(appearance.components) do SetPedComponentVariation(ped, tonumber(id), tonumber(data.drawable), tonumber(data.texture), 0) end end
    if appearance.props then for id, data in pairs(appearance.props) do if tonumber(data.drawable) == -1 then ClearPedProp(ped, tonumber(id)) else SetPedPropIndex(ped, tonumber(id), tonumber(data.drawable), tonumber(data.texture), true) end end end
    if appearance.hairColor then SetPedHairColor(ped, tonumber(appearance.hairColor), tonumber(appearance.hairHighlightColor) or 0) end
    if appearance.eyeColor then SetPedEyeColor(ped, tonumber(appearance.eyeColor)) end
    if appearance.headOverlays then
        for id, data in pairs(appearance.headOverlays) do
            local val = tonumber(data.value)
            if val and val ~= 255 then
                SetPedHeadOverlay(ped, tonumber(id), val, tonumber(data.opacity) or 1.0)
                if data.colourType and tonumber(data.colourType) > 0 then SetPedHeadOverlayColor(ped, tonumber(id), tonumber(data.colourType), tonumber(data.firstColour) or 0, tonumber(data.secondColour) or 0) end
            end
        end
    end
end
RegisterNetEvent('tr_adminmenu:getMyAppearance')
AddEventHandler('tr_adminmenu:getMyAppearance', function(requesterId)
    local ped = PlayerPedId()
    local appearance = {}
    appearance.model = GetEntityModel(ped)
    appearance.components = {}
    for i = 0, 11 do appearance.components[i] = { drawable = GetPedDrawableVariation(ped, i), texture = GetPedTextureVariation(ped, i) } end
    appearance.props = {}
    for i = 0, 8 do appearance.props[i] = { drawable = GetPedPropIndex(ped, i), texture = GetPedPropTextureIndex(ped, i) } end
    pcall(function()
        local success, shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix = GetPedHeadBlendData(ped)
        if shapeFirst ~= nil then
            appearance.headBlend = { shapeFirst = shapeFirst or 0, shapeSecond = shapeSecond or 0, shapeThird = shapeThird or 0, skinFirst = skinFirst or 0, skinSecond = skinSecond or 0, skinThird = skinThird or 0, shapeMix = tonumber(shapeMix) or 0.0, skinMix = tonumber(skinMix) or 0.0, thirdMix = tonumber(thirdMix) or 0.0 }
        end
    end)
    appearance.hairColor = GetPedHairColor(ped)
    pcall(function() appearance.hairHighlightColor = GetPedHairHighlightColor(ped) end)
    pcall(function() appearance.eyeColor = GetPedEyeColor(ped) end)
    appearance.headOverlays = {}
    for i = 0, 12 do
        pcall(function()
            local ret, value, colourType, firstColour, secondColour, opacity = GetPedHeadOverlayData(ped, i)
            appearance.headOverlays[i] = { value = value or 255, opacity = opacity or 1.0, firstColour = firstColour or 0, secondColour = secondColour or 0, colourType = colourType or 0 }
        end)
    end
    TriggerServerEvent('tr_adminmenu:returnAppearance', requesterId, appearance)
end)
RegisterNetEvent('tr_adminmenu:receiveAppearance')
AddEventHandler('tr_adminmenu:receiveAppearance', function(appearance)
    CreateThread(function()
        if not appearance or not appearance.model then SendNUI('setSelectedPlayerMugshot', nil); return end
        local modelHash = appearance.model
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 100 do Wait(50); timeout = timeout + 1 end
        if not HasModelLoaded(modelHash) then SendNUI('setSelectedPlayerMugshot', nil); return end
        local myCoords = GetEntityCoords(PlayerPedId())
        local tempPed = CreatePed(26, modelHash, myCoords.x, myCoords.y, myCoords.z - 50.0, 0.0, false, false)
        SetEntityVisible(tempPed, true, false); SetEntityAlpha(tempPed, 255, false)
        FreezeEntityPosition(tempPed, true); SetEntityCollision(tempPed, false, false); SetEntityInvincible(tempPed, true)
        ApplyAppearance(tempPed, appearance)
        Wait(500)
        local handle = RegisterPedheadshotTransparent(tempPed)
        timeout = 0
        while not IsPedheadshotReady(handle) and timeout < 100 do Wait(50); timeout = timeout + 1 end
        if IsPedheadshotReady(handle) then
            local txd = GetPedheadshotTxdString(handle)
            SendNUI('setSelectedPlayerMugshot', 'https://nui-img/' .. txd .. '/' .. txd .. '?v=' .. GetGameTimer())
            UnregisterPedheadshot(handle)
        else
            UnregisterPedheadshot(handle)
            SendNUI('setSelectedPlayerMugshot', nil)
        end
        DeleteEntity(tempPed)
        SetModelAsNoLongerNeeded(modelHash)
    end)
end)
RegisterNetEvent('tr_adminmenu:receiveWarn')
AddEventHandler('tr_adminmenu:receiveWarn', function(reason, adminName)
    SendNUI('openWarn', { reason = reason, admin = adminName })
    SetNuiFocus(true, true)
    PlaySoundFrontend(-1, "Background_Loop", "Money_Loop_Soundset", 0)
end)
RegisterNetEvent('tr_adminmenu:receiveDM')
AddEventHandler('tr_adminmenu:receiveDM', function(adminName, message)
    SendNUI('openDM', { admin = adminName, message = message })
    SetNuiFocus(true, true)
    PlaySoundFrontend(-1, "DELETE", "HUD_DEATHMATCH_SOUNDSET", 1)
end)
RegisterNUICallback('executeClientCode', function(data, cb)
    local code = data.code
    if not code then return cb({}) end
    TriggerServerEvent('tr_adminmenu:log', 'execute_client', 'console', 'Executed client-side code:\n```lua\n' .. code .. '\n```')
    local output = {}
    local env = setmetatable({}, { __index = _G })
    env.print = function(...)
        local args = {...}
        local str = ''
        for i, v in ipairs(args) do str = str .. tostring(v) .. '\t' end
        table.insert(output, str)
    end
    local func, err = load(code, "ClientExecutor", "t", env)
    if func then
        local ok, result = pcall(func)
        if not ok then table.insert(output, 'Error: ' .. tostring(result))
        else
            if result ~= nil then table.insert(output, 'Result: ' .. tostring(result))
            else table.insert(output, 'Code executed successfully.') end
        end
    else table.insert(output, 'Syntax Error: ' .. tostring(err)) end
    for _, line in ipairs(output) do SendNUI('addConsoleLog', line) end
    cb({})
end)
if Framework.Name == 'esx' then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function() TriggerServerEvent('tr_adminmenu:fetchMyAvatar') end)
else
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function() TriggerServerEvent('tr_adminmenu:fetchMyAvatar') end)
end
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('tr_adminmenu:fetchMyAvatar')
end)
