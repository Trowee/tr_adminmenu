Webhooks = {}

-- Main webhook for all admin actions
Webhooks.MainWebhook = 'YOUR_DISCORD_WEBHOOK_HERE'

-- Per-category webhook overrides (leave empty to use MainWebhook)
-- If a category-specific webhook is set, it will be used instead of MainWebhook
Webhooks.CategoryWebhooks = {
    ban = '',
    kick = '',
    teleport = '',
    spawn = '',
    kill = '',
    heal = '',
    revive = '',
    spectate = '',
    vehicle = '',
    inventory = '',
    announcement = '',
    freeze = '',
    admin = '',
    money = '',
    item = '',
    job = '',
    group = '',
    dm = '',
    console = '',
    resource = '',
    warn = '',
}

-- Webhook embed appearance settings
Webhooks.ServerName = 'TR Scripts'
Webhooks.ServerIcon = 'https://cdn.discordapp.com/avatars/521032505344655380/27d80b98a0444d295fdfe861c76cb397.webp?size=1024'
Webhooks.EmbedColor = 3447003
Webhooks.IncludeTimestamp = true
Webhooks.IncludeIdentifiers = true
