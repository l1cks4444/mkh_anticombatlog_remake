ESX = exports['es_extended']:getSharedObject()


local Config = {
    Webhook = "webhook hier",
    Discord = {
        username = "Anti-Combatlog",
        color = 16711680,
        title = "Combat Log Report"
    }
}

RegisterCommand('jojonas', function()
    sendToDiscord("AA", "WWWWWW")
end, false)

function sendToDiscord(title, message)
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Discord.username,
        embeds = {{
            title = title,
            description = message,
            color = Config.Discord.color
        }}
    }), { ['Content-Type'] = 'application/json' })
end

local disconnects = {}

AddEventHandler('playerDropped', function(reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local coords = GetEntityCoords(GetPlayerPed(src))
    TriggerEvent('esx_skin:getPlayerSkin', src, function(skin)
        disconnects[src] = {
            name = xPlayer.getName(),
            identifier = xPlayer.getIdentifier(),
            coords = coords,
            time = os.time(),
            reason = reason or 'Unbekannt',
            reported = false,
            skin = skin
        }
        TriggerClientEvent('mkh_anticombatlog:spawnDummy', -1, src, coords, xPlayer.getName(), reason, skin)
        SetTimeout(45000, function()
            disconnects[src] = nil
            TriggerClientEvent('mkh_anticombatlog:removeDummy', -1, src)
        end)
    end)
end)

RegisterNetEvent('mkh_anticombatlog:reportPlayer', function(target, reportReason)
    print("mkh_anticombatlog:reportPlayer")
    local reporter = source
    local xReporter = ESX.GetPlayerFromId(reporter)
    print("reporter:", reporter)
    print("xReporter:", xReporter)
    print("disconnects[target]:", disconnects[target])
    if not xReporter or not disconnects[target] then 
        print("DEBUG: Aborted: xReporter or disconnects[target] missing")
        return 
    end
    print("reported")
    disconnects[target].reported = true
    disconnects[target].reportReason = reportReason
    local webhookMsg = ("**Combatlogger:** %s (%s)\n**Reporter:** %s (%s)\n**Grund:** %s\n**Disconnect Reason:** %s")
        :format(disconnects[target].name, disconnects[target].identifier, xReporter.getName(), xReporter.getIdentifier(), reportReason, disconnects[target].reason)
    print("DEBUG: Sending webhook message:", webhookMsg)
    sendToDiscord(Config.Discord.title, webhookMsg)
end)
