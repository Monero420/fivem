-- Triggered from client. Requests player's data from the database. 
RegisterNetEvent('requestPlayerData')
AddEventHandler('requestPlayerData', function()
    local playerId = source
    local identifier = GetPlayerIdentifierByType(playerId, 'license')
	local defaultMoney = 0
	
	-- Default new player values.
	local newPlayerDefaults = {
		identifier = GetPlayerIdentifierByType(playerId, 'license'),
		bank = 0,
		cash = 0,
		inventory = {},
		weapons = {},
		cars = {},
		properties = {}
	}

	-- Async SQL query promise. Grab data from 'players' table where 'identifier' row matches player fivem license.
    local response = MySQL.query.await('SELECT * FROM players WHERE identifier = ?', { identifier })

    if response and #response > 0 then
        local results = response[1] -- Assuming you only want the first result if there are multiple.
		
		-- Certain DB Rows are stored in JSON, decoding required. Replace original affected data. 
		results.weapons = json.decode(results.weapons)
		results.inventory = json.decode(results.inventory)
		
		-- Trigger client event to push retrieved data to client-side playerData tracking table.
		TriggerClientEvent('recievePlayerData', playerId, results)
    else
        -- If no result for player, create entry with fivem license. Give default new player values.
        MySQL.insert.await('INSERT INTO players (identifier, bank, cash) VALUES (?, ?, ?)', {
			identifier,
			defaultMoney,
			defaultMoney
		})
		-- Trigger client event to push new player data to client-side playerData tracking table.
		TriggerClientEvent('recievePlayerData', playerId, newPlayerDefaults)
    end
end)

-- Triggered from the client. Handles updating database from client-side tracking table.
RegisterNetEvent('recieveUpdateFromClient')
AddEventHandler('recieveUpdateFromClient', function(dataToSend)
	local playerId = source
    local identifier = GetPlayerIdentifierByType(playerId, 'license')
	
	-- Code to handle updating player inventory.
	MySQL.update('UPDATE players SET inventory = ? WHERE identifier = ?', {
		json.encode(dataToSend.inventory), identifier -- convert inventory table to JSON for use with SQL row.
	})

	-- Code to handle updating the player's weapons.
	MySQL.update('UPDATE players SET weapons = ? WHERE identifier = ?', {
		json.encode(dataToSend.weapons), identifier -- convert inventory table to JSON for use with SQL row.
	})
	
	-- Code to handle updating the player's cash.
	MySQL.update('UPDATE players SET cash = ? WHERE identifier = ?', {
		dataToSend.cash, identifier -- convert inventory table to JSON for use with SQL row.
	})

	-- Code to handle updating the player's bank
	MySQL.update('UPDATE players SET bank = ? WHERE identifier = ?', {
		dataToSend.bank, identifier -- convert inventory table to JSON for use with SQL row.
	})
end)

-- Seperate thread to trigger sendPlayerUpdateToServer client event every 30 seconds.
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(30000)
		TriggerClientEvent('sendPlayerUpdateToServer', -1)
	end
end)