Config = {}

---@param ServerName string The name of your server displayed in the admin menu and on ban cards.
Config.ServerName = 'Trowe'

---@param BanAppealUrl string The URL players will see when they are banned (e.g. your Discord appeal channel).
Config.BanAppealUrl = 'https://discord.gg/'

---@param DiscordUrl string The URL for the Discord button shown on the ban card.
Config.DiscordUrl = 'https://discord.gg/'

---@param BanIP boolean If true, players will also be checked and banned by their IP address.
Config.BanIP = true

---@param LogDeletionHours number Automatically deletes old logs from the database after X hours (set to 0 to disable this feature).
Config.LogDeletionHours = 168

---@param SteamWebApiKey string Steam Web API key for fetching player avatars (get yours at https://steamcommunity.com/dev/apikey). Leave empty if not used.
Config.SteamWebApiKey = ''

---@param PhoneNumberTable string Database table used for fetching the player's phone number.
Config.PhoneNumberTable = ''
Config.PhoneNumberColumn = ''

---@param PropertiesTable string Database table used for fetching properties owned by a player.
Config.PropertiesTable = 'owned_properties'
Config.PropertiesOwnerColumn = 'owner'

---@param PlaytimeTable string Database table and column used for playtime tracking.
Config.PlaytimeTable = 'players'
Config.PlaytimeColumn = 'playtime'

---@param PlayerInfoFields table Toggle which fields are shown in the detailed player profile. Set to true to show, false to hide.
Config.PlayerInfoFields = {
    characterName = true,
    steamName = true,
    job = true,
    job2 = false,
    metadata_job = false,
    grade = true,
    group = true,
    position = true,
    cash = true,
    bank = true,
    black_money = true,
    phone = false,
    vehiclesOwned = true,
    inVehicle = true,
    ping = true,
    identifiers = true,
    playtime = false,
    uuid = true,
}

---@param AdminDutyCheck function Function used to check if the admin is currently on duty. Return true if duty system is not used.
Config.AdminDutyCheck = function(source)
    -- Example for custom framework duty:
    -- local Player = Framework.GetPlayer(source)
    -- return Player.PlayerData.metadata['onduty']
    return true
end

---@param GetPlayerUUID function Custom function to retrieve the UUID/citizenid of a player.
Config.GetPlayerUUID = function(source)
    local Player = Framework.GetPlayer(source)
    if not Player then return '' end
    
    if Framework.Name == 'qbx' or Framework.Name == 'qb' then
        return Player.PlayerData.citizenid
    elseif Framework.Name == 'esx' then
        -- Return whatever unique identifier you use for ESX (usually identifier)
        return Player.identifier or Player.getIdentifier()
    end
    
    return ''
end

---@param AdminGroups table Defines which groups are considered admins and can open the menu.
Config.AdminGroups = {
    ['moderator'] = true,
    ['admin']     = true,
    ['developer']     = true,
}

---@param AdminIdentifiers table Manually map specific identifiers to an admin group (bypasses framework group checks).
Config.AdminIdentifiers = {
    -- ['fivem:123456'] = 'admin',
    -- ['discord:123456789'] = 'owner',
}

---@param GroupRanks table The hierarchy of ranks (higher number = higher rank). Used to prevent lower ranks from punishing higher ranks.
Config.GroupRanks = {
    ['moderator'] = 1,
    ['admin']     = 2,
    ['developer']     = 3,
}

---@param EnabledSections table Toggles for different sections in the admin panel sidebar.
Config.EnabledSections = {
    home = true,
    players = true,
    offline_players = true,
    bans = true,
    kick = false,
    spectate = true,
    logs = true,
    admins = true,
    staffchat = true,
    vehicles = true,
    client_executor = true,
    manage_resources = true,
}

---@param NotificationSystem string The notification system to use: 'nui' (built-in), 'esx', or 'ox_lib'.
Config.NotificationSystem = 'nui'

---@param AnnouncementDuration number How long (in milliseconds) announcements stay on screen.
Config.AnnouncementDuration = 7000

---@param AdminVehicle table The vehicle model and plate string used when spawning an admin vehicle.
Config.AdminVehicle = {
    model = 'blista',
    plate = 'ADMIN',
}

---@param BanDurations table A list of available ban duration options shown in the ban menu.
Config.BanDurations = {
    { label = '1 Hour',    seconds = 3600 },
    { label = '6 Hours',   seconds = 21600 },
    { label = '12 Hours',  seconds = 43200 },
    { label = '1 Day',     seconds = 86400 },
    { label = '3 Days',    seconds = 259200 },
    { label = '7 Days',    seconds = 604800 },
    { label = '14 Days',   seconds = 1209600 },
    { label = '30 Days',   seconds = 2592000 },
    { label = 'Permanent', seconds = 0 },
}

---@param StaffChatColors table Hex color codes assigned to each admin group for the staff chat.
Config.StaffChatColors = {
    ['moderator'] = '#3B82F6', -- Light Blue
    ['admin']     = '#10B981', -- Green
    ['developer']     = '#DC2626', -- Dark Red
}

local ownerPerms = {
    -- Moderation
    noclip = true, goto_player = true, bring = true, freeze = true, spectate = true,
    kick = true, ban = true, warn = true, send_dm = true, send_announcement = true,

    -- Player State & Management
    heal = true, revive = true, kill = true, teleport = true,
    view_inventory = true, clear_inventory = true, give_item = true, remove_item = true,
    set_job = true, set_group = true, set_money = true, remove_money = true,

    -- Vehicles
    spawn_vehicle = true, manage_vehicles = true, delete_all_vehicles = true,

    -- Server & System
    staff_chat = true, view_logs = true, client_executor = true, manage_resources = true, view_ip = true,

    -- Offline Actions
    offline_players = true, offline_set_job = true, offline_set_group = true,
    offline_set_money = true, offline_remove_money = true, offline_give_item = true,
    offline_remove_item = true, offline_give_vehicle = true, offline_set_position = true,
}

local adminPerms = {
    -- Moderation
    noclip = true, goto_player = true, bring = true, freeze = true, spectate = true,
    kick = true, ban = true, warn = true, send_dm = true, send_announcement = true,

    -- Player State & Management
    heal = true, revive = true, kill = true, teleport = true,
    view_inventory = true, clear_inventory = false, give_item = true, remove_item = true,
    set_job = true, set_group = false, set_money = false, remove_money = false,

    -- Vehicles
    spawn_vehicle = true, manage_vehicles = false, delete_all_vehicles = false,

    -- Server & System
    staff_chat = true, view_logs = true, client_executor = false, manage_resources = false, view_ip = false,

    -- Offline Actions
    offline_players = true, offline_set_job = false, offline_set_group = false,
    offline_set_money = false, offline_remove_money = false, offline_give_item = false,
    offline_remove_item = false, offline_give_vehicle = false, offline_set_position = false,
}

local moderatorPerms = {
    -- Moderation
    noclip = true, goto_player = true, bring = true, freeze = true, spectate = true,
    kick = true, ban = false, warn = true, send_dm = true, send_announcement = false,

    -- Player State & Management
    heal = false, revive = false, kill = false, teleport = true,
    view_inventory = true, clear_inventory = false, give_item = false, remove_item = false,
    set_job = false, set_group = false, set_money = false, remove_money = false,

    -- Vehicles
    spawn_vehicle = true, manage_vehicles = false, delete_all_vehicles = false,

    -- Server & System
    staff_chat = true, view_logs = true, client_executor = false, manage_resources = false, view_ip = false,

    -- Offline Actions
    offline_players = false, offline_set_job = false, offline_set_group = false,
    offline_set_money = false, offline_remove_money = false, offline_give_item = false,
    offline_remove_item = false, offline_give_vehicle = false, offline_set_position = false,
}

---@param Permissions table Defines what each admin group is allowed to do.
--- You can create as many custom permission tables as you want above (e.g. local headAdminPerms = {...})
--- and assign them to your custom groups below. There is no limit.
Config.Permissions = {
    ['moderator'] = moderatorPerms,
    ['admin']     = adminPerms,
    ['owner']     = ownerPerms,
}

---@param HexPermissions table Grant specific permissions to individual players via their Steam Hex, regardless of their group.
Config.HexPermissions = {
    -- ['steam:110000100000000'] = {
    --     view_ip = true,
    --     ban = true
    -- }
}

---@param Commands table Commands and default keybinds for opening the menus.
Config.Commands = {
    AdminPanel = {
        command = 'amenu',
        description = 'Open Admin Panel',
        defaultKey = 'DELETE'
    },
    QuickMenu = {
        command = 'amenuquick',
        description = 'Open Quick Admin Menu',
        defaultKey = 'F10'
    }
}

---@param Keybinds table Control IDs for spectating and noclip keybinds (FiveM Controls).
Config.Keybinds = {
    spectate_exit           = 194,
    spectate_next           = 175,
    spectate_prev           = 174,
    noclip_exit             = 194,
    freecam_forward         = 32,
    freecam_backward        = 33,
    freecam_left            = 34,
    freecam_right           = 35,
    freecam_up              = 38,
    freecam_down            = 44,
    freecam_speed_boost     = 209,
}
