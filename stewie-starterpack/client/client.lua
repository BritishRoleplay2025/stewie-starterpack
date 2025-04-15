local QBCore = exports['qb-core']:GetCoreObject()
local pedModel = Config.NPC.model  -- Get NPC model from config
local pedCoords = Config.NPC.coords  -- Get NPC coordinates from config
local spawnedPed = nil

-- Function to spawn the ped
Citizen.CreateThread(function()
    RequestModel(GetHashKey(pedModel))
    while not HasModelLoaded(GetHashKey(pedModel)) do
        Wait(500)
    end

    spawnedPed = CreatePed(4, GetHashKey(pedModel), pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, true)

    -- Set ped properties
    SetEntityInvincible(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    TaskStartScenarioInPlace(spawnedPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

    -- Freeze the ped so it doesn't move
    FreezeEntityPosition(spawnedPed, true)


    -- Apply selected target system
    if Config.TargetSystem == "qb-target" and GetResourceState("qb-target") == "started" then
        exports['qb-target']:AddTargetEntity(spawnedPed, {
            options = {
                {
                    type = "client",
                    event = "pedInteractionMenu",
                    icon = "fas fa-comments",
                    label = "Talk to NPC"
                }
            },
            distance = 2.0
        })
    elseif Config.TargetSystem == "ox_target" and GetResourceState("ox_target") == "started" then
        exports.ox_target:addLocalEntity(spawnedPed, {
            {
                name = "npc_talk",
                event = "pedInteractionMenu",
                icon = "fas fa-comments",
                label = "Talk to NPC",
                distance = 2.0
            }
        })
    else
        print("^1[ERROR] Invalid or missing target system! Check config.lua.^0")
    end
end)

-- Event to open the menu when interacting with the ped
RegisterNetEvent("pedInteractionMenu", function()
    lib.registerContext({
        id = 'ped_menu',
        title = 'NPC Interaction',
        options = {
            {
                title = "Receive Starter Pack",
                description = "Get a nice starter pack.",
                icon = "fas fa-gift",
                event = "testOptionEvent"  
            },
            {
                title = "Hire Vehicle",
                description = "Rent a vehicle for a short period.",
                icon = "fas fa-car",
                event = "showVehicleListMenu"  -- Trigger the vehicle list menu                    
            },
            {
                title = "Leave",
                description = "End the conversation.",
                icon = "fas fa-times"
            }
        }
    })
    lib.showContext('ped_menu')  -- Show the menu
end)


RegisterNetEvent("testOptionEvent", function()
    -- Close the menu if open
    lib.hideContext()

    -- Show the Alert Dialog with a custom Yes/No option
    local alert = lib.alertDialog({
        header = 'Accepting the Rules',
        content = "Before You Recive Your Starter Pack, you agree to the following rules:\n\n" ..
        "1. No Cheating or Exploiting\n" ..
        "2. Respect All Players\n" ..
        "3. No RDM (Random Deathmatch)\n" ..
        "4. No VDM (Vehicle Deathmatch)\n" ..
        "5. Roleplay Standards\n" ..
        "6. No Advertising\n" ..
        "7. Follow Server Specific Rules\n" ..
        "8. No Spamming\n" ..
        "9. Respect Admin Decisions\n" ..
        "10. Use Common Sense\n\n" ..
        "Should You Press Cancel Will Result In You Failing Following The Rules And Being Kicked From The Server\n\n" ..
        "Do you accept these rules and want to receive the Starter Pack?",
        centered = true,
        cancel = true,  -- Adds the "No" option, which acts as cancel
        ConfirmLabel = "Yes"  -- Changing the button text from "Confirm" to "Yes"
    })

    -- Debugging the result from the alert dialog
    TriggerEvent("checkAndGiveStarterPack")

    -- Handle the result
    if alert == "cancel" then
        print("User selected No (cancel)! Kicking the player...")
        
        -- Trigger the server event to log the action and kick the player
        local reason = " You Failed To Accept The Rules"  -- Set a reason for the ban/kick
        TriggerServerEvent('kickPlayerForAction', reason)
        
    elseif alert == "ok" then
        print("User selected Yes!")  -- This should print if "Yes" is selected
        -- Add the behavior for Yes (proceed action) here
    else
     --   print("Unexpected alert result: " .. tostring(alert))  -- This will help catch any unexpected result
    end
end)



RegisterNetEvent("receiveStarterPack", function()
    local playerPed = PlayerPedId()

    -- Request and load the animation dictionary
    RequestAnimDict("mp_common")
    while not HasAnimDictLoaded("mp_common") do
        Wait(100)
    end

    -- Start the animation
    TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Show progress bar while the animation plays
    lib.progressBar({
        duration = 5000, -- Duration of the progress bar (in milliseconds)
        label = 'Receiving Starter Pack...',  -- Progress bar label
        useWhileDead = false,  -- Don't allow progress while dead
        canCancel = true,  -- Allow the player to cancel the progress bar
        disable = {
            car = true,  -- Disable progress if in a car
        },
    })

    -- Wait for the progress bar to complete (2 seconds)
    Wait(2000)

    -- Cancel the animation after the progress bar completes
    ClearPedTasks(playerPed)  -- This stops the animation

    -- After animation and progress bar complete, give the player the items
    TriggerEvent('QBCore:Notify', "You received your Starter Pack!", "success")  -- Notify player

    -- Trigger server event to give multiple items from the config
    for _, item in ipairs(Config.StarterPackItems) do
        TriggerServerEvent("giveMultipleItems", {
            { item = item.item, amount = item.amount }
        })
    end
end)


-- Event to trigger receiving the starter pack
RegisterNetEvent("checkAndGiveStarterPack", function()
    -- Request the server to check if the player has already received the starter pack
    TriggerServerEvent("giveStarterPack")
end)



RegisterNetEvent("showVehicleListMenu", function()
    -- Get the vehicles from the config
    local vehicles = Config.Vehicles

    -- Create the menu options for each vehicle in the list
    local options = {}
    for _, vehicle in ipairs(vehicles) do
        table.insert(options, {
            title = vehicle.label,
            description = "Rent a " .. vehicle.label .. " for $" .. vehicle.price,
            icon = "fas fa-car",
            event = "hireSelectedVehicle",  -- Event to trigger when a vehicle is selected
            args = { vehicle.model, vehicle.price }  -- Pass model and price as arguments
        })
    end

    -- Register and show the vehicle list menu
    lib.registerContext({
        id = 'vehicle_menu',
        title = 'Choose a Vehicle',
        options = options  -- Use the options list created above
    })

    lib.showContext('vehicle_menu')  -- Show the menu
end)

-- Event when the player selects a vehicle
RegisterNetEvent("hireSelectedVehicle", function(vehicleData)
    -- Ensure vehicleData is valid (contains model and price)
    if vehicleData and vehicleData[1] and vehicleData[2] then
        local vehicleModel = vehicleData[1]
        local vehiclePrice = vehicleData[2]

        -- Prompt the player to choose payment method and hire duration in minutes
        local input = lib.inputDialog('Payment Method & Hire Duration', {
            { type = 'checkbox', label = 'Pay by Cash', description = 'Select to pay using cash.' },
            { type = 'checkbox', label = 'Pay by Bank', description = 'Select to pay using bank account.' },
            { type = 'select', label = 'How long to rent?', options = {
                { label = '10 minutes', value = 10 },
                { label = '15 minutes', value = 15 },
                { label = '30 minutes', value = 30 }
            }, description = 'Select how long to rent the vehicle for.' }
        })

        if input then
            local payByCash = input[1]  -- Check if the player selected Cash
            local payByBank = input[2]  -- Check if the player selected Bank
            local hireDuration = input[3]  -- Get the selected hire duration in minutes

            local playerMoney = QBCore.Functions.GetPlayerData().money["cash"]  -- Get player's cash
            local playerBank = QBCore.Functions.GetPlayerData().money["bank"]  -- Get player's bank account

            -- Check if the player has selected Cash or Bank
            if payByCash then
                -- If paying by cash, check if the player has enough cash
                if playerMoney >= vehiclePrice then
                    -- Deduct the rental price from the player's cash
                    TriggerServerEvent("stewie-starterpack:deductMoney", vehiclePrice, 'cash')

                    -- Inform the player that they've paid and the vehicle is ready
                    TriggerEvent('QBCore:Notify', "You have rented the vehicle for $" .. vehiclePrice .. " using cash.", "success")
                    rentVehicle(vehicleModel, hireDuration)
                else
                    -- Notify the player if they don't have enough cash
                    TriggerEvent('QBCore:Notify', "You don't have enough cash to rent this vehicle.", "error")
                end
            elseif payByBank then
                -- If paying by bank, check if the player has enough bank balance
                if playerBank >= vehiclePrice then
                    -- Deduct the rental price from the player's bank account
                    TriggerServerEvent("stewie-starterpack:deductMoney", vehiclePrice, 'bank')

                    -- Inform the player that they've paid and the vehicle is ready
                    TriggerEvent('QBCore:Notify', "You have rented the vehicle for $" .. vehiclePrice .. " using your bank account.", "success")
                    rentVehicle(vehicleModel, hireDuration)
                else
                    -- Notify the player if they don't have enough bank balance
                    TriggerEvent('QBCore:Notify', "You don't have enough funds in your bank to rent this vehicle.", "error")
                end
            else
                -- Notify the player if no payment method was selected
                TriggerEvent('QBCore:Notify', "Please select a payment method.", "error")
            end
        else
            -- Notify the player if they canceled the dialog
            TriggerEvent('QBCore:Notify', "Payment method and duration selection canceled.", "error")
        end
    else
        -- Handle invalid data scenario
        TriggerEvent('QBCore:Notify', "Invalid vehicle data received.", "error")
    end
end)


function rentVehicle(vehicleModel, hireDuration)
    -- Convert hire duration from minutes to seconds
    local hireDurationInSeconds = hireDuration * 60

    -- Request the vehicle model
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(500)
    end

    -- Define the spawn coordinates and heading
    local spawnCoords = vector4(-1034.6, -2729.76, 20.07, 235.6)

    -- Create the vehicle at the specified coordinates
    local vehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)

    -- Check if vehicle creation succeeded
    if vehicle == 0 then
        TriggerEvent('QBCore:Notify', "Vehicle spawn failed, try again!", "error")
        return
    end

    -- Set the player as the driver of the vehicle
    local playerPed = PlayerPedId()
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    -- Set vehicle doors to unlocked
    SetVehicleDoorsLocked(vehicle, 1)

    -- Trigger the event to give the player the vehicle keys
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicle))

    -- Inform the player that the vehicle has been rented
    TriggerEvent('QBCore:Notify', "Vehicle rented successfully for " .. hireDuration .. " minutes!", "success")

    -- Delete the vehicle after the selected hire duration
    Citizen.SetTimeout(hireDurationInSeconds * 1000, function()  -- hireDurationInSeconds is in seconds, convert to milliseconds
        DeleteEntity(vehicle)  -- Delete the spawned vehicle
        TriggerEvent('QBCore:Notify', "Vehicle has been deleted after " .. hireDuration .. " minutes.", "info")  -- Optional: Notify the player
    end)
end

local function spawnVehicle(model)
    lib.requestModel(model)

    local spawnCoords = vector4(-1034.6, -2729.76, 20.07, 235.6)

    -- Create the vehicle at the specified coordinates
    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)

    -- Check if vehicle creation succeeded
    if vehicle == 0 then
        TriggerEvent('QBCore:Notify', "Vehicle spawn failed, try again!", "error")
        return
    end

    -- Set the player as the driver of the vehicle
    local playerPed = PlayerPedId()
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    -- Set vehicle doors to unlocked
    SetVehicleDoorsLocked(vehicle, 1)

    -- Trigger the event to give the player the vehicle keys
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicle))

    return vehicle
end

lib.callback.register('spawnVehicle', function(model)
    local vehicle = spawnVehicle(model)
    return QBCore.Functions.GetVehicleProperties(vehicle), NetworkGetNetworkIdFromEntity(vehicle)
end)

RegisterNetEvent('givekeys', function(plate)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
end)