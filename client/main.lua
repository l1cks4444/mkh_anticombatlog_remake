print('C : M')

ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        Citizen.Wait(0)
    end
    print('DEBUG: ESX initialisiert:', ESX ~= nil)
end)


local dummies = {}
local dummyReasons = {}

RegisterNetEvent('mkh_anticombatlog:spawnDummy', function(src, coords, name, reason, skin)
    local model = skin and skin.model or `mp_m_freemode_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(10) end
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z -1, 0.0, false, true)
    if skin then
        for i=0, 11 do
            local drawable = skin["drawable_"..i]
            local texture = skin["texture_"..i]
            if drawable and texture then
                SetPedComponentVariation(ped, i, drawable, texture, 2)
            end
        end
        for i=0, 7 do
            local prop = skin["prop_"..i]
            local propTex = skin["prop_texture_"..i]
            if prop and prop > -1 then
                SetPedPropIndex(ped, i, prop, propTex or 0, true)
            else
                ClearPedProp(ped, i)
            end
        end
    end
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_BUM_SLUMPED", 0, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    dummies[src] = {ped = ped, name = name, coords = coords}
    dummyReasons[src] = reason or 'Noch nicht gemeldet'
    Citizen.SetTimeout(15000, function() -- timeout
        if dummies[src] and dummies[src].ped then DeleteEntity(dummies[src].ped) end
        dummies[src] = nil
        dummyReasons[src] = nil
    end)
end)

RegisterNetEvent('mkh_anticombatlog:removeDummy', function(src)
    if dummies[src] and dummies[src].ped then
        DeleteEntity(dummies[src].ped)
    end
    dummies[src] = nil
    dummyReasons[src] = nil
end)

RegisterCommand('testdummy', function()
    local coords = GetEntityCoords(PlayerPedId())
    local testSkin = {
        model = `mp_m_freemode_01`,
        drawables = { [3]=0, [4]=1, [6]=1, [8]=15, [11]=1 },
        props = { [0]=1 }
    }
    local testName = "W Spieler"
    local testId = 1
    local testReason = "W Reason"
    TriggerEvent('mkh_anticombatlog:spawnDummy', testId, coords, testName, testReason, testSkin)
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        for src, data in pairs(dummies) do
            local dist = #(playerCoords - data.coords)
            if dist < 3.0 then
                local reason = dummyReasons[src] or 'Noch nicht gemeldet'
                DrawText3D(data.coords.x, data.coords.y, data.coords.z + 1.0, "Spieler hat Server verlassen\nPress [E] to Report\nID: "..src.." ("..data.name..")\nReason: "..reason)
                if IsControlJustReleased(0, 38) then -- E
                    print('DEBUG: E pressed, opening ESX dialog for src:', src)
                    if ESX and ESX.UI and ESX.UI.Menu then
                        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'report_reason', {
                            title = 'Grund für Report eingeben'
                        }, function(data2, menu)
                            print('DEBUG: Dialog callback, data2:', json.encode(data2))
                            local reason = data2.value
                            print('DEBUG: Eingetragener Grund:', reason)
                            if reason and reason ~= '' then
                                print('DEBUG: Sende Report an Server, src:', src, 'reason:', reason)
                                TriggerServerEvent('mkh_anticombatlog:reportPlayer', src, reason)
                                ESX.ShowNotification('Report gesendet!')
                            else
                                print('DEBUG: Kein Grund eingegeben!')
                                ESX.ShowNotification('Bitte einen Grund eingeben!')
                            end
                            menu.close()
                        end, function(data2, menu)
                            print('DEBUG: Dialog abgebrochen')
                            menu.close()
                        end)
                    else
                        print('ERROR: ESX oder ESX.UI.Menu ist nil!')
                        if ESX and ESX.ShowNotification then
                            ESX.ShowNotification('ESX nicht korrekt geladen, bitte später versuchen!')
                        end
                    end
                end
            end
        end
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
end 
