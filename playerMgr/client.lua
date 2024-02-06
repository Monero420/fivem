local playerData = {} -- Local tracking table for Database data.
local isInventoryOpen = false -- Variable to track the Inventory NUI window state.

-- Function to create a notification on the client's screen.
function Notify(message, color)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, false)
end

-- Function to update MoneyHUD
function UpdateMoneyHUD()
    -- print("Updating MoneyHUD:", playerData.cash, playerData.bank)
    SendNUIMessage({
        type = "updateMoneyHUD",
        cash = playerData.cash,
        bank = playerData.bank
    })
end

function ChangeInventory(itemData)
    local key = itemData.key
	local incrementAmount = itemData.amount
	
	if playerData.inventory[key] then
		playerData.inventory[key] = playerData.inventory[key] + incrementAmount
	else
		playerData.inventory[key] = incrementAmount
	end
	print("Inventory Changed:", json.encode(playerData.inventory))
end

-- Function to toggle the Inventory NUI screen. Also sends copy of players inventory to the NUI.
function ToggleInventoryWindow()
    isInventoryOpen = not isInventoryOpen
    
    SetNuiFocus(isInventoryOpen, isInventoryOpen)
    SendNUIMessage({
        type = "openInventory",
        isVisible = isInventoryOpen,
        inventory = playerData.inventory
    })
end

-- Waits for resource to fully start, then requests player's data from Database. Wait required or results return empty.
AddEventHandler('onClientResourceStart', function (resourceName)
  if(GetCurrentResourceName() ~= resourceName) then
    return
  end
  print('The resource ' .. resourceName .. ' has been started on the client.')
  
  TriggerServerEvent('requestPlayerData')
end)

RegisterNetEvent('sellDrugs')
AddEventHandler('sellDrugs', function(drugType)
    if drugType == 'marijuana' then
        if playerData.inventory ~= nil then
            local cashFromSale = playerData.inventory['marijuana'] * 10
            TriggerEvent('addMoney', cashFromSale)
            playerData.inventory['marijuana'] = nil
        end
    end
end)

-- Triggered from server. Returns results from above initial playerData request.
RegisterNetEvent('recievePlayerData')
AddEventHandler('recievePlayerData', function(updatedPlayerData)
    if updatedPlayerData then
        -- Update client-side playerData tracking table with results.
        playerData = updatedPlayerData
        Citizen.Wait(2500)
        -- Check if DB weapons row came back as a table or empty.
		-- If not empty, give a weapon for each object in the table using the stored hash and 0 ammo.
        if type(playerData.weapons) == 'table' then 
            for _, weapon in pairs(playerData.weapons) do
                local ammunition = tonumber(weapon.ammo)
                GiveWeaponToPed(GetPlayerPed(-1), weapon.hash, ammunition, false, false)
            end 
        elseif type(playerData.weapons) == 'nil' then
            print(playerData.identifier .. ' has no weapons')
        end

        UpdateMoneyHUD()
    else -- Error Handling.
        print("Error: Received nil player data.")
    end
end)

-- Triggered from server. Pushes current state of playerData tracking table to server(Note: server makes this call every 30 seconds).
RegisterNetEvent('sendPlayerUpdateToServer')
AddEventHandler('sendPlayerUpdateToServer', function()
    local dataToSend = playerData
    UpdateMoneyHUD()
    TriggerServerEvent('recieveUpdateFromClient', dataToSend)
end)

-- Triggered externally. Sends the current state of playerData's weapons property back to the caller.
RegisterNetEvent('getPlayerWeapons')
AddEventHandler('getPlayerWeapons', function()
    local playerWeapons = playerData.weapons
    TriggerEvent('recievePlayerWeapons', playerWeapons)
end)

-- Removes money from the player's cash balance.
RegisterNetEvent('deductMoney')
AddEventHandler('deductMoney', function(amount, reasonType, reason)
	if tonumber(playerData.cash) < tonumber(amount) then
		Notify("You don't have enough cash!", {255, 0, 0})
	else
        playerData.cash = playerData.cash - amount
        Notify("Purchase made for: $" .. amount, {255, 0, 0})
        UpdateMoneyHUD()
        
        if reasonType == "apparelPurchase" then
		    if reason == "armorPurchase" then
                local itemData = { key = "armor", amount = 1 }
		        ChangeInventory(itemData)
            elseif reason == "parachutePurchase" then
                local itemData = { key = "parachute", amount = 1 }
		        ChangeInventory(itemData)
            end
		elseif reasonType == "ammoBoxPurchase" then
			local itemData = { key = "ammoBox", amount = 1 }
		    ChangeInventory(itemData)
		end
	end
end)

RegisterNetEvent('addMoney')
AddEventHandler('addMoney', function(amount)
    playerData.cash = playerData.cash + amount
    Notify("Obtained $" .. amount, {255, 0, 0})
    UpdateMoneyHUD()
end)

-- Triggered whenever the player spawns
RegisterNetEvent('playerSpawned')
AddEventHandler('playerSpawned', function()
    if type(playerData.weapons) == 'table' then 
		for _, weapon in pairs(playerData.weapons) do
			local ammunition = tonumber(weapon.ammo)
			GiveWeaponToPed(GetPlayerPed(-1), weapon.hash, ammunition, false, false)
		end 
	elseif type(playerData.weapons) == 'nil' then
		print(playerData.identifier .. ' has no weapons')
	end
end)

RegisterNetEvent('addWeapon')
AddEventHandler('addWeapon', function(weaponToAdd, price)

    if tonumber(playerData.cash) < tonumber(price) then
		Notify("You don't have enough cash!", {255, 0, 0})
	else
        playerData.cash = playerData.cash - price
        Notify("Purchase made for: $" .. price, {255, 0, 0})
        UpdateMoneyHUD()
        GiveWeaponToPed(GetPlayerPed(-1), weaponToAdd.hash, 200, false, false)
        table.insert(playerData.weapons, weaponToAdd)
    end
end)

-- Adds items to Inventory(Note: this is sometimes called from other scripts).
RegisterNetEvent('updateInventory')
AddEventHandler('updateInventory', function(itemToAdd)
	ChangeInventory(itemToAdd)
end)

-- Register the 'I' key press event to toggleInventory command.
RegisterKeyMapping("toggleInventory", "Toggle Inventory Window", "keyboard", "I")
RegisterCommand("toggleInventory", function()
    ToggleInventoryWindow()
end)

-- Triggered from NUI. Runs ToggleInventoryWindow() to exit NUI.
RegisterNUICallback('exit', function()
    ToggleInventoryWindow()
end)

RegisterNUICallback('useAmmoBox', function()
    playerData.inventory["ammoBox"] = playerData.inventory["ammoBox"] - 1

    -- Iterate over the player's weapons and give full ammo for each weapon
    for _, weapon in pairs(playerData.weapons) do
        AddAmmoToPed(GetPlayerPed(-1), tostring(weapon.hash), 300)
        --TaskReloadWeapon(GetPlayerPed(-1))
    end

    if playerData.inventory["ammoBox"] == 0 then
        playerData.inventory["ammoBox"] = nil
    end
end)

RegisterNUICallback('useArmor', function()
    playerData.inventory["armor"] = playerData.inventory["armor"] - 1
    SetPedArmour(GetPlayerPed(-1), 100)
    if playerData.inventory["armor"] == 0 then
        playerData.inventory["armor"] = nil
    end
end)

RegisterNUICallback('useParachute', function()
    playerData.inventory["parachute"] = playerData.inventory["parachute"] - 1
    TriggerEvent('givePlayerParachute')
    if playerData.inventory["parachute"] == 0 then
        playerData.inventory["parachute"] = nil
    end
end)

-- Debugging command to display certain player data(Note: TO BE REMOVED).
RegisterCommand('getstats', function()
    print("Bank: " .. playerData.bank .. ", Cash: " .. playerData.cash .. ", Inventory: " .. json.encode(playerData.inventory))
end)