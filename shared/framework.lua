Framework = {}
Framework.Name = 'unknown'
local ESX, QBCore = nil, nil

CreateThread(function()
    if GetResourceState('ox_inventory') == 'started' then
        Config.InventorySystem = 'ox_inventory'
    elseif GetResourceState('qs-inventory') == 'started' then
        Config.InventorySystem = 'qs-inventory'
    elseif GetResourceState('core_inventory') == 'started' then
        Config.InventorySystem = 'core_inventory'
    elseif GetResourceState('qb-inventory') == 'started' or GetResourceState('qbx-inventory') == 'started' or GetResourceState('ps-inventory') == 'started' then
        Config.InventorySystem = 'qb-inventory'
    end

    if GetResourceState('qbx_core') == 'started' then
        Framework.Name = 'qbx'
        print('[tr_adminmenu] ^2Framework detected: QBox (qbx_core)^7')
    elseif GetResourceState('qb-core') == 'started' then
        Framework.Name = 'qb'
        QBCore = exports['qb-core']:GetCoreObject()
        print('[tr_adminmenu] ^2Framework detected: QBCore (qb-core)^7')
    elseif GetResourceState('es_extended') == 'started' then
        Framework.Name = 'esx'
        ESX = exports['es_extended']:getSharedObject()
        print('[tr_adminmenu] ^2Framework detected: ESX (es_extended)^7')
    else
        print('[tr_adminmenu] ^1ERROR: No supported framework detected! (ESX, QBCore, QBox)^7')
    end
end)

if IsDuplicityVersion() then
    function Framework.GetPlayer(source)
        if Framework.Name == 'esx' then
            return ESX.GetPlayerFromId(source)
        elseif Framework.Name == 'qb' then
            return QBCore.Functions.GetPlayer(source)
        elseif Framework.Name == 'qbx' then
            return exports.qbx_core:GetPlayer(source)
        end
        return nil
    end

    function Framework.GetIdentifier(source)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then return xPlayer.getIdentifier() end
            return nil
        else
            local Player = Framework.GetPlayer(source)
            if Player then return Player.PlayerData.citizenid end
            return nil
        end
    end

    function Framework.GetGroup(source)
        local identifiers = GetPlayerIdentifiers(source)

        if Config.AdminIdentifiers then
            for _, id in ipairs(identifiers) do
                if Config.AdminIdentifiers[id] then
                    return Config.AdminIdentifiers[id]
                end
            end
        end

        local aceGroups = {'god', 'owner', 'admin', 'moderator', 'mod'}
        for _, group in ipairs(aceGroups) do
            if IsPlayerAceAllowed(source, 'group.' .. group) then
                if group == 'mod' then return 'moderator' end
                return group
            end
        end

        for _, id in ipairs(identifiers) do
            for _, group in ipairs(aceGroups) do
                if IsPrincipalAceAllowed('identifier.' .. id, 'group.' .. group) or IsPrincipalAceAllowed(id, 'group.' .. group) then
                    if group == 'mod' then return 'moderator' end
                    return group
                end
            end
        end

        if Config.HexPermissions then
            for _, id in ipairs(identifiers) do
                if Config.HexPermissions[id] then
                    return 'admin' -- Let them open the menu, their specific perms are restricted by HasPermission later
                end
            end
        end


        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then return xPlayer.getGroup() end
            return 'user'
        elseif Framework.Name == 'qbx' then
            local Player = exports.qbx_core:GetPlayer(source)
            if Player and Player.PlayerData.group then return Player.PlayerData.group end
            return 'user'
        else
            if QBCore and QBCore.Functions.HasPermission(source, 'god') then return 'god'
            elseif QBCore and QBCore.Functions.HasPermission(source, 'admin') then return 'admin'
            elseif QBCore and QBCore.Functions.HasPermission(source, 'mod') then return 'moderator'
            end
            return 'user'
        end
    end

    function Framework.GetCharacterName(source)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then return xPlayer.getName() end
            return GetPlayerName(source) or 'Unknown'
        else
            local Player = Framework.GetPlayer(source)
            if Player then
                local charinfo = Player.PlayerData.charinfo
                if charinfo then
                    return (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')
                end
            end
            return GetPlayerName(source) or 'Unknown'
        end
    end

    function Framework.GetPlayerMoney(source)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then return 0, 0, 0 end
            local accounts = xPlayer.getAccounts()
            local money, bank, blackMoney = 0, 0, 0
            for _, acc in ipairs(accounts) do
                if acc.name == 'money' then money = acc.money
                elseif acc.name == 'bank' then bank = acc.money
                elseif acc.name == 'black_money' then blackMoney = acc.money
                end
            end
            return money, bank, blackMoney
        else
            local Player = Framework.GetPlayer(source)
            if not Player then return 0, 0, 0 end
            local money = Player.PlayerData.money and Player.PlayerData.money['cash'] or 0
            local bank = Player.PlayerData.money and Player.PlayerData.money['bank'] or 0
            local crypto = Player.PlayerData.money and Player.PlayerData.money['crypto'] or 0
            return money, bank, crypto
        end
    end

    function Framework.GetPlayerJob(source)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then return 'unemployed', 'Unemployed', 0, '0' end
            local job = xPlayer.getJob()
            return job.name, job.label, job.grade, job.grade_label or tostring(job.grade)
        else
            local Player = Framework.GetPlayer(source)
            if not Player then return 'unemployed', 'Unemployed', 0, '0' end
            local job = Player.PlayerData.job
            if job then
                return job.name, job.label, job.grade.level, job.grade.name or tostring(job.grade.level)
            end
            return 'unemployed', 'Unemployed', 0, '0'
        end
    end

    function Framework.GetPlayerJob2(source)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then return 'none', 'None', 0, '0' end
            if xPlayer.getJob2 then
                local job2 = xPlayer.getJob2()
                if job2 then return job2.name, job2.label, job2.grade, job2.grade_label or tostring(job2.grade) end
            end
            return 'none', 'None', 0, '0'
        else
            local Player = Framework.GetPlayer(source)
            if not Player then return 'none', 'None', 0, '0' end
            local gang = Player.PlayerData.gang
            if gang then
                return gang.name, gang.label, gang.grade.level, gang.grade.name or tostring(gang.grade.level)
            end
            return 'none', 'None', 0, '0'
        end
    end

    function Framework.SetJob(source, job, grade)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then xPlayer.setJob(job, grade or 0) end
        else
            local Player = Framework.GetPlayer(source)
            if Player then Player.Functions.SetJob(job, grade or 0) end
        end
    end

    function Framework.SetGroup(source, group)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then xPlayer.setGroup(group) end
        else
            local license = GetPlayerIdentifierByType(source, 'license')
            if license then
                local licenseHash = license:gsub('^license:', '')
                local knownGroups = {'god', 'admin', 'owner', 'moderator', 'mod'}
                for _, oldGroup in ipairs(knownGroups) do
                    ExecuteCommand(('remove_principal identifier.license:%s qbcore.%s'):format(licenseHash, oldGroup))
                end
                ExecuteCommand(('add_principal identifier.license:%s qbcore.%s'):format(licenseHash, group))
                print(('[tr_adminmenu] ^2Set group for license:%s to qbcore.%s^7'):format(licenseHash, group))
            else
                print('[tr_adminmenu] ^1ERROR: Could not find license identifier for source ' .. tostring(source) .. '^7')
            end
        end
    end

    function Framework.AddMoney(source, moneyType, amount)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then xPlayer.addAccountMoney(moneyType, amount) end
        else
            local Player = Framework.GetPlayer(source)
            if Player then
                local qbType = moneyType
                if moneyType == 'money' then qbType = 'cash' end
                if moneyType == 'black_money' then qbType = 'crypto' end
                Player.Functions.AddMoney(qbType, amount)
            end
        end
    end

    function Framework.RemoveMoney(source, moneyType, amount)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then xPlayer.removeAccountMoney(moneyType, amount) end
        else
            local Player = Framework.GetPlayer(source)
            if Player then
                local qbType = moneyType
                if moneyType == 'money' then qbType = 'cash' end
                if moneyType == 'black_money' then qbType = 'crypto' end
                Player.Functions.RemoveMoney(qbType, amount)
            end
        end
    end

    function Framework.GetAllPlayers()
        if Framework.Name == 'esx' then
            return ESX.GetExtendedPlayers()
        elseif Framework.Name == 'qb' then
            return QBCore.Functions.GetQBPlayers()
        elseif Framework.Name == 'qbx' then
            local players = {}
            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                local Player = exports.qbx_core:GetPlayer(src)
                if Player then
                    players[src] = Player
                end
            end
            return players
        end
        return {}
    end

    function Framework.GetPlayerSource(playerObj)
        if Framework.Name == 'esx' then
            return playerObj.source
        else
            return playerObj.PlayerData.source
        end
    end

    function Framework.GetPlayerCoords(source)
        if Framework.Name == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then return xPlayer.getCoords(true) end
        end
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            return GetEntityCoords(ped)
        end
        return nil
    end

    function Framework.GetAllJobs()
        if Framework.Name == 'esx' then
            return (ESX.GetJobs and ESX.GetJobs()) or ESX.Jobs or {}
        elseif Framework.Name == 'qb' then
            return QBCore.Shared.Jobs or {}
        elseif Framework.Name == 'qbx' then
            return exports.qbx_core:GetJobs() or {}
        end
        return {}
    end

    function Framework.GiveItem(source, itemName, count)
        if Config.InventorySystem == 'ox_inventory' then
            exports.ox_inventory:AddItem(source, itemName, count)
        elseif Config.InventorySystem == 'qs-inventory' then
            exports['qs-inventory']:AddItem(source, itemName, count)
        elseif Config.InventorySystem == 'core_inventory' then
            exports.core_inventory:addItem(source, itemName, count)
        else
            if Framework.Name == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then xPlayer.addInventoryItem(itemName, count) end
            else
                local Player = Framework.GetPlayer(source)
                if Player then Player.Functions.AddItem(itemName, count) end
            end
        end
    end

    function Framework.RemoveItem(source, itemName, count)
        if Config.InventorySystem == 'ox_inventory' then
            exports.ox_inventory:RemoveItem(source, itemName, count)
        elseif Config.InventorySystem == 'qs-inventory' then
            exports['qs-inventory']:RemoveItem(source, itemName, count)
        elseif Config.InventorySystem == 'core_inventory' then
            exports.core_inventory:removeItem(source, itemName, count)
        else
            if Framework.Name == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then xPlayer.removeInventoryItem(itemName, count) end
            else
                local Player = Framework.GetPlayer(source)
                if Player then Player.Functions.RemoveItem(itemName, count) end
            end
        end
    end

    function Framework.GetPlayerInventory(source)
        local inventory = {}
        if Config.InventorySystem == 'ox_inventory' then
            if GetResourceState('ox_inventory') == 'started' then
                local ok, items = pcall(function() return exports.ox_inventory:GetInventoryItems(source) end)
                if not ok or not items then
                    ok, items = pcall(function() return exports.ox_inventory:GetInventory(source, false) end)
                end
                if ok and items then
                    for _, item in pairs(items) do
                        if item and item.count and item.count > 0 then
                            table.insert(inventory, { name = item.name, label = item.label, count = item.count, slot = item.slot, image = 'nui://ox_inventory/web/images/' .. item.name .. '.png' })
                        end
                    end
                end
            end
        elseif Config.InventorySystem == 'qs-inventory' then
            local items = exports['qs-inventory']:GetInventory(source)
            if items then
                for _, item in ipairs(items) do
                    if item.count and item.count > 0 then
                        table.insert(inventory, { name = item.name, label = item.label, count = item.count, slot = item.slot or 0, image = 'nui://qs-inventory/html/img/items/' .. item.name .. '.png' })
                    end
                end
            end
        else
            if Framework.Name == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then
                    local items = xPlayer.getInventory()
                    for _, item in ipairs(items) do
                        if item.count and item.count > 0 then
                            table.insert(inventory, { name = item.name, label = item.label, count = item.count, slot = item.slot or 0, image = '' })
                        end
                    end
                end
            else
                local Player = Framework.GetPlayer(source)
                if Player then
                    local items = Player.PlayerData.items
                    if items then
                        for _, item in pairs(items) do
                            if item and item.amount and item.amount > 0 then
                                table.insert(inventory, { name = item.name, label = item.label or item.name, count = item.amount, slot = item.slot or 0, image = 'nui://qb-inventory/html/images/' .. item.name .. '.png' })
                            end
                        end
                    end
                end
            end
        end
        return inventory
    end

    function Framework.ClearInventory(source)
        if Config.InventorySystem == 'ox_inventory' then
            exports.ox_inventory:ClearInventory(source)
        else
            if Framework.Name == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then
                    local items = xPlayer.getInventory()
                    for _, item in pairs(items) do
                        if item.count and item.count > 0 then xPlayer.removeInventoryItem(item.name, item.count) end
                    end
                end
            else
                local Player = Framework.GetPlayer(source)
                if Player then Player.Functions.ClearInventory() end
            end
        end
    end

    function Framework.ClearWeapons(source)
        if Config.InventorySystem == 'ox_inventory' then
            local ok, inventory = pcall(function() return exports.ox_inventory:GetInventoryItems(source) end)
            if ok and inventory then
                for _, item in pairs(inventory) do
                    if string.match(string.lower(item.name), "^weapon_") then
                        exports.ox_inventory:RemoveItem(source, item.name, item.count)
                    end
                end
            end
        else
            if Framework.Name == 'esx' then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then
                    local loadout = xPlayer.getLoadout()
                    for _, weapon in ipairs(loadout) do
                        xPlayer.removeWeapon(weapon.name)
                    end
                    local items = xPlayer.getInventory()
                    for _, item in pairs(items) do
                        if string.match(string.lower(item.name), "^weapon_") and item.count > 0 then
                            xPlayer.removeInventoryItem(item.name, item.count)
                        end
                    end
                end
            else
                local Player = Framework.GetPlayer(source)
                if Player then
                    local items = Player.PlayerData.items
                    if items then
                        for _, item in pairs(items) do
                            if item and string.match(string.lower(item.name), "^weapon_") and item.amount > 0 then
                                Player.Functions.RemoveItem(item.name, item.amount)
                            end
                        end
                    end
                end
            end
        end
    end

    function Framework.GetAllItems()
        local items = {}
        local addedItems = {}
        local function addItem(name, label, desc, img)
            if not addedItems[name] then
                table.insert(items, { name = name, label = label, description = desc, image = img })
                addedItems[name] = true
            end
        end
        if GetResourceState('ox_inventory') == 'started' then
            local ok, oxItems = pcall(function() return exports.ox_inventory:Items() end)
            if ok and oxItems and next(oxItems) then
                for name, data in pairs(oxItems) do
                    addItem(name, data.label or name, data.description or '', 'nui://ox_inventory/web/images/' .. name .. '.png')
                end
            else
                local ok3, dbItems = pcall(function() return MySQL.Sync.fetchAll('SELECT name, label FROM items', {}) end)
                if ok3 and dbItems then
                    for _, item in ipairs(dbItems) do
                        addItem(item.name, item.label, '', 'nui://ox_inventory/web/images/' .. item.name .. '.png')
                    end
                end
            end
        elseif Config.InventorySystem == 'qs-inventory' then
            local qsItems = exports['qs-inventory']:GetItemList()
            for name, data in pairs(qsItems) do
                addItem(name, data.label, data.description, 'nui://qs-inventory/html/img/items/' .. name .. '.png')
            end
        else
            if Framework.Name == 'esx' then
                local esxItems = ESX.GetItems()
                for name, label in pairs(esxItems) do
                    local lbl = type(label) == 'table' and label.label or label
                    addItem(name, lbl, '', '')
                end
            else
                local sharedItems = QBCore and QBCore.Shared.Items or {}
                for name, data in pairs(sharedItems) do
                    addItem(name, data.label or name, data.description or '', 'nui://qb-inventory/html/images/' .. name .. '.png')
                end
            end
        end
        table.sort(items, function(a, b) return (a.label or a.name or ''):lower() < (b.label or b.name or ''):lower() end)
        return items
    end

    function Framework.GetUsersTable()
        if Framework.Name == 'esx' then
            return 'users'
        else
            return 'players'
        end
    end

    function Framework.GetIdentifierColumn()
        if Framework.Name == 'esx' then
            return 'identifier'
        else
            return 'citizenid'
        end
    end

    function Framework.GetVehiclesTable()
        if Framework.Name == 'esx' then
            return 'owned_vehicles'
        else
            return 'player_vehicles'
        end
    end

    function Framework.GetVehicleOwnerColumn()
        if Framework.Name == 'esx' then
            return 'owner'
        else
            return 'citizenid'
        end
    end

    function Framework.GetVehiclePlateColumn()
        return 'plate'
    end

    function Framework.GetVehicleDataColumn()
        if Framework.Name == 'esx' then
            return 'vehicle'
        else
            return 'mods'
        end
    end

    function Framework.GetVehicleModelColumn()
        if Framework.Name == 'esx' then
            return nil
        else
            return 'vehicle'
        end
    end

    function Framework.GetPlayerNameFromDB(row)
        if Framework.Name == 'esx' then
            return (row.firstname or 'Unknown') .. ' ' .. (row.lastname or '')
        else
            local charinfo = row.charinfo
            if type(charinfo) == 'string' then
                local ok, parsed = pcall(json.decode, charinfo)
                if ok and parsed then charinfo = parsed end
            end
            if type(charinfo) == 'table' then
                return (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')
            end
            return row.name or 'Unknown'
        end
    end

    function Framework.ParseOfflineAccounts(row)
        if Framework.Name == 'esx' then
            local money, bank, blackMoney = 0, 0, 0
            if row.accounts then
                local ok, accounts = pcall(json.decode, row.accounts)
                if ok and accounts then
                    money = tonumber(accounts.money) or 0
                    bank = tonumber(accounts.bank) or 0
                    blackMoney = tonumber(accounts.black_money) or 0
                end
            end
            return money, bank, blackMoney
        else
            local money, bank, crypto = 0, 0, 0
            if row.money then
                local moneyData = row.money
                if type(moneyData) == 'string' then
                    local ok, parsed = pcall(json.decode, moneyData)
                    if ok and parsed then moneyData = parsed end
                end
                if type(moneyData) == 'table' then
                    money = tonumber(moneyData.cash) or 0
                    bank = tonumber(moneyData.bank) or 0
                    crypto = tonumber(moneyData.crypto) or 0
                end
            end
            return money, bank, crypto
        end
    end

    function Framework.GroupDigits(amount)
        if Framework.Name == 'esx' and ESX.Math then
            return ESX.Math.GroupDigits(amount)
        end
        local formatted = tostring(math.floor(amount))
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    end
else
    function Framework.GetPlayerData()
        if Framework.Name == 'esx' then
            return ESX.GetPlayerData()
        elseif Framework.Name == 'qb' then
            return QBCore.Functions.GetPlayerData()
        elseif Framework.Name == 'qbx' then
            return exports.qbx_core:GetPlayerData()
        end
        return nil
    end

    function Framework.GetPlayerGroup()
        local data = Framework.GetPlayerData()
        if not data then return 'user' end
        if Framework.Name == 'esx' then
            return data.group or 'user'
        else
            local perms = {'god', 'admin', 'mod'}
            for _, perm in ipairs(perms) do
                if QBCore and QBCore.Functions.HasPermission(perm) then
                    if perm == 'mod' then return 'moderator' end
                    return perm
                end
            end
            return data.group or 'user'
        end
    end

    function Framework.SpawnVehicle(model, coords, heading, cb)
        local hash = type(model) == 'number' and model or GetHashKey(model)
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 100 do
            Wait(50)
            timeout = timeout + 1
        end
        if not HasModelLoaded(hash) then
            if cb then cb(nil) end
            return
        end
        local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
        if cb then cb(vehicle) end
    end
end
