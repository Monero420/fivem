local plantedPlants = {}

RegisterServerEvent('plantSeed')
AddEventHandler('plantSeed', function(originX, originY, originZ)
    local playerID = source
    local plantID = #plantedPlants + 1
    local markerOffsetX = 1.0

    Citizen.CreateThread(function()

        plantedPlants[plantID] = {
            id = plantID,
            growthStage = 1,
            playerID = playerID,
            harvested = false,
            position = {
                x = originX,
                y = originY,
                z = originZ
            },
            markerPosition = {
                x = originX - markerOffsetX,
                y = originY,
                z = originZ
            },
            object = CreateObject(GetHashKey('bkr_prop_weed_01_small_01a'), originX, originY, originZ, true, false, false),
        }

        print("Plant ID: " .. plantedPlants[plantID].object .. ", planted.")

        local sharedPlantData = plantedPlants
        TriggerClientEvent('updateTrackingTable', -1, sharedPlantData)
    end)
    
end)

RegisterServerEvent('harvestPlant')
AddEventHandler('harvestPlant', function(id)
    
    for _, plant in pairs(plantedPlants) do
        if plant.id == id then
            if plant.harvested == false and plant.growthStage == 3 then
                print("Plant ID: " .. plant.object .. ", harvested.")

                DeleteEntity(plant.object)

                plant.harvested = true
                plant.position.x, plant.position.y, plant.position.z = nil
                plant.markerPosition.x, plant.markerPosition.y, plant.markerPosition.z = nil

                local sharedPlantData = plantedPlants
                TriggerClientEvent('updateTrackingTable', -1, sharedPlantData)
				
		local itemData = { key = "marijuana", amount = 180 }
		TriggerClientEvent('updateInventory', source, itemData)
            else
                TriggerClientEvent('msgClient', source, "This plant has already been harvested or is not ready yet!")
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        for _, plant in pairs(plantedPlants) do
                if plant.harvested == false and plant.growthStage < 3 then
                    plant.growthStage = plant.growthStage + 1
                    DeleteEntity(plant.object)

                    if plant.growthStage == 2 then
                        plant.object = CreateObject(GetHashKey('bkr_prop_weed_med_01a'), plant.position.x, plant.position.y, plant.position.z - 2.5, true, false, false)
                    elseif plant.growthStage == 3 then
                        plant.object = CreateObject(GetHashKey('bkr_prop_weed_lrg_01a'), plant.position.x, plant.position.y, plant.position.z - 2.5, true, false, false)
                    end
                end
            
                local sharedPlantData = plantedPlants
                TriggerClientEvent('updateTrackingTable', -1, sharedPlantData)
        end
    end
end)
