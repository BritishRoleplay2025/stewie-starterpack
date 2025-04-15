local QBCore = exports['qb-core']:GetCoreObject()
local starterPackGiven = {}
-- Server event to give multiple items to the player
RegisterNetEvent("giveMultipleItems", function(items)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Loop through all items in the received list and give them to the player
        for _, itemData in pairs(items) do
            local item = itemData.item
            local amount = itemData.amount
            
            -- Add item to player's inventory
            local success = Player.Functions.AddItem(item, amount)
            
            if success then
             --   print("[DEBUG] Gave " .. amount .. " " .. item .. " to player " .. src)  -- Debugging success
            else
            --    print("[ERROR] Failed to give " .. item .. " to player " .. src)  -- Debugging failure
            end
        end
    else
    --    print("[ERROR] Player not found!")
    end
end)


RegisterServerEvent('stewie-starterpack:deductMoney')
AddEventHandler('stewie-starterpack:deductMoney', function(amount, paymentType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)  -- Get the player object
    
    if paymentType == 'cash' then
        -- Check if the player has enough cash
        if Player.Functions.GetMoney("cash") >= amount then
            -- Deduct the money from the player's cash
            Player.Functions.RemoveMoney("cash", amount)
           -- TriggerClientEvent('QBCore:Notify', src, "You have successfully rented the vehicle using cash.", "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "You don't have enough cash.", "error")
        end
    elseif paymentType == 'bank' then
        -- Check if the player has enough bank balance
        if Player.Functions.GetMoney("bank") >= amount then
            -- Deduct the money from the player's bank account
            Player.Functions.RemoveMoney("bank", amount)
           -- TriggerClientEvent('QBCore:Notify', src, "You have successfully rented the vehicle using your bank account.", "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "You don't have enough funds in your bank.", "error")
        end
    end
end)

local function isPlateTaken(plate)
    return MySQL.scalar.await('SELECT 1 FROM `player_vehicles` WHERE `plate` = ?', {plate})
end

local function generatePlate()
    return lib.string.random('........', 8)
end

local function giveStarterCar(source, model)
    local plate = generatePlate()

    repeat plate = generatePlate() until not isPlateTaken(plate)

    local player = QBCore.Functions.GetPlayer(source)
    local license = player.PlayerData.license
    local citizenId = player.PlayerData.citizenid

    local props, vehicleNetId = lib.callback.await('spawnVehicle', source, model)

    props.plate = plate
    print(plate, 'plate')

    while GetVehicleNumberPlateText(NetworkGetEntityFromNetworkId(vehicleNetId)) ~= plate do
      SetVehicleNumberPlateText(NetworkGetEntityFromNetworkId(vehicleNetId), plate)
      Wait(0)
    end
    TriggerClientEvent('givekeys', source, plate)

    MySQL.insert("INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage) VALUES (?, ?, ?, ?, ?, ?, ?)", {license, citizenId, model, joaat(model), json.encode(props), plate, nil})
end

-- Event to handle giving the starter pack
RegisterNetEvent("giveStarterPack", function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    -- Check if the player already has the starter pack
    if starterPackGiven[player.PlayerData.citizenid] then
        TriggerClientEvent('QBCore:Notify', src, "You have already received your starter pack!", "error")
        return
    end

    -- Mark the player as having received the starter pack
    starterPackGiven[player.PlayerData.citizenid] = true


    -- Now proceed to give the starter pack items
    TriggerClientEvent("receiveStarterPack", src)
    Wait(5000)
    giveStarterCar(src, Config.RandomVehicles[math.random(1, #Config.RandomVehicles)])
end)

RegisterNetEvent('kickPlayerForAction', function(reason)
    local _source = source  -- Get the player ID who triggered the event
    local playerName = GetPlayerName(_source)  -- Get the player�s nam
    -- Kick the player with a reason
    DropPlayer(_source, 'You were Kicked' .. reason)
end)

