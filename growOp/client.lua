local buyer = {
    coords = vector3(93.52327, -1292.009, 29.26874),
    heading = 293.9462890625,
    interactionMarker = vector3(94.52327, -1291.25, 28.26874)
}

local blip = AddBlipForCoord(buyer.interactionMarker.x, buyer.interactionMarker.y, buyer.interactionMarker.z)

-- Customize the blip appearance (optional)
SetBlipSprite(blip, 140) -- You can change the sprite ID as needed -- ID 110 is GunStore
SetBlipDisplay(blip, 4) -- Display on both the minimap and the world map
SetBlipScale(blip, 1.0) -- Adjust the blip size

-- Initialization of Client-side tracking table for plants.
local plantedPlants = {}

-- Command to plant a seed
RegisterCommand('plant', function()
    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1)))
    local offsetX, offsetY, offsetZ = 0.0, 2.0, -1.0
    TriggerServerEvent('plantSeed', x + offsetX, y + offsetY, z + offsetZ)
end)

RegisterNetEvent('updateTrackingTable')
AddEventHandler('updateTrackingTable', function(sharedPlantData)
    plantedPlants = sharedPlantData
end)

RegisterNetEvent('msgClient')
AddEventHandler('msgClient', function(message)
    print(message)
end)

-- Thread used to draw a marker in front of each planted plant. Also checks to see if the user is close enough to harvest the plant and if they're requesting to do so.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for _, plant in pairs(plantedPlants) do
            if plant.harvested == false then
                DrawMarker( 1, plant.markerPosition.x, plant.markerPosition.y, plant.markerPosition.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 0, 155, false, true, 2, nil, nil, false )
            end
        end
        for _, plant in pairs(plantedPlants) do
            local playerPosition = GetEntityCoords(GetPlayerPed(-1))
            
            if IsControlJustReleased(1, 38) and plant.harvested == false and Vdist(plant.markerPosition.x, plant.markerPosition.y, plant.markerPosition.z, playerPosition.x, playerPosition.y, playerPosition.z) < 1.15 then
                TriggerServerEvent('harvestPlant', plant.id)
            end
        end

        local playerPosition = GetEntityCoords(GetPlayerPed(-1))

        DrawMarker( 1, buyer.interactionMarker.x, buyer.interactionMarker.y, buyer.interactionMarker.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 0, 155, false, true, 2, nil, nil, false )
        if IsControlJustReleased(1, 38) and Vdist(buyer.interactionMarker.x, buyer.interactionMarker.y, buyer.interactionMarker.z, playerPosition.x, playerPosition.y, playerPosition.z) < 1.15 then
            print('Standing in the sell marker!')
            TriggerEvent('sellDrugs', 'marijuana')
        end
    end
end)

-- Function to spawn an NPC and make them sit in a chair
function SpawnBuyerNpc()
    local spawnPosition = buyer.coords
    local spawnHeading = buyer.heading

    RequestModel("a_m_y_hippy_01")  -- Request the model

    while not HasModelLoaded("a_m_y_hippy_01") do
        Wait(500)
    end

    local buyerNpc = CreatePed(4, "a_m_y_hippy_01", spawnPosition.x, spawnPosition.y, spawnPosition.z, spawnHeading, false, false)

    if DoesEntityExist(buyerNpc) then
		Wait(5000)
        local heightOffset = -2.0
        --TaskStartScenarioInPlace(buyerNpc, "PROP_HUMAN_SEAT_CHAIR", heightOffset, true)
        print("NPC spawned.")
    else
        print("Error: NPC failed to spawn.")
    end

    TaskStartScenarioInPlace(buyerNpc, "WORLD_HUMAN_SMOKING_POT", 0, true)
end

SpawnBuyerNpc()

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        DeleteEntity(buyerNpc)
    end
end)