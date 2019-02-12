ESX = nil
local connectedPlayers = {}
local playerJobs       = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('esx_scoreboard:getPlayers', function(source, cb)
	cb(connectedPlayers)
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(15000)

		CountJobs()
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5000)

		UpdatePing()
	end
end)

AddEventHandler('es:playerLoaded', function(Source, user)
	if user.getGroup() == 'user' then
		TriggerClientEvent('esx_scoreboard:toggleID', Source)
	end
end)

AddEventHandler('esx:playerLoaded', function(player)
	connectedPlayers[player] = {}
	connectedPlayers[player].ping = GetPlayerPing(player)
	connectedPlayers[player].id = player

	local identifier = GetPlayerIdentifiers(player)[1]

	MySQL.Async.fetchAll('SELECT firstname, lastname, license, name FROM users WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function (result)
		if result[1].firstname and result[1].lastname and result[1].name then
			connectedPlayers[player].license = result[1].firstname .. ' ' .. result[1].lastname
			connectedPlayers[player].steamname = result[1].name
		elseif result[1].license then
			connectedPlayers[player].license = result[1].name
		else
			connectedPlayers[player].license = 'Unknown player name'
		end

		TriggerClientEvent('esx_scoreboard:updateConnectedPlayers', -1, connectedPlayers)
	end)

	TriggerEvent('es:getPlayerFromId', player, function(user)
		if user.getGroup() == 'user' then
			TriggerClientEvent('esx_scoreboard:toggleID', player)
		end
	end)
end)

AddEventHandler('esx:playerDropped', function(playerID)
	connectedPlayers[playerID] = nil

	TriggerClientEvent('esx_scoreboard:updateConnectedPlayers', -1, connectedPlayers)
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.CreateThread(function()
			Citizen.Wait(1000)
			ForceCountPlayers()
			CountJobs()
		end)
	end
end)

TriggerEvent('es:addGroupCommand', 'screfresh', 'admin', function(source, args, user)
	ForceCountPlayers()
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, {help = "Refresh esx_scoreboard names!"})

TriggerEvent('es:addGroupCommand', 'sctoggle', 'admin', function(source, args, user)
	TriggerClientEvent('esx_scoreboard:toggleID', source)
end, function(source, args, user)
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Insufficient Permissions.' } })
end, {help = "Toggle ID column on the scoreboard!"})

function ForceCountPlayers()
	local xPlayers = ESX.GetPlayers()
	local player, identifier

	connectedPlayers = {}

	for i=1, #xPlayers, 1 do
		player = xPlayers[i]

		connectedPlayers[player] = {}
		connectedPlayers[player].ping = GetPlayerPing(player)
		connectedPlayers[player].id = player

		identifier = GetPlayerIdentifiers(player)[1]

		MySQL.Async.fetchAll('SELECT firstname, lastname, license, name FROM users WHERE identifier = @identifier', {
			['@identifier'] = identifier
		}, function (result)

			if result[1].firstname and result[1].lastname and result[1].name then
				connectedPlayers[player].license = result[1].firstname .. ' ' .. result[1].lastname
				connectedPlayers[player].steamname = result[1].name
			elseif result[1].license then
				connectedPlayers[player].license = result[1].name
			else
				connectedPlayers[player].license = 'Unknown player name'
			end
	
		end)

		-- await!
		while connectedPlayers[player].license == nil do
			Citizen.Wait(1)
		end

		TriggerEvent('es:getPlayerFromId', player, function(user)
			if user.getGroup() == 'user' then
				TriggerClientEvent('esx_scoreboard:toggleID', player)
			end
		end)

	end

	TriggerClientEvent('esx_scoreboard:updateConnectedPlayers', -1, connectedPlayers)

end

function UpdatePing()
	for k,v in pairs(connectedPlayers) do
		v.ping = GetPlayerPing(k)
	end

	TriggerClientEvent('esx_scoreboard:updatePing', -1, connectedPlayers)
end

function CountJobs()
	local EMSConnected = 0
	local PoliceConnected = 0
	local TaxiConnected = 0
	local MechanicConnected = 0
	local CardealerConnected = 0
	local EstateConnected = 0
	local PlayerConnected = 0

	local xPlayers, xPlayer = ESX.GetPlayers()
	for i=1, #xPlayers, 1 do

		xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		PlayerConnected = PlayerConnected + 1

		if xPlayer.job.name == 'ambulance' then
			EMSConnected = EMSConnected + 1
		elseif xPlayer.job.name == 'police' then
			PoliceConnected = PoliceConnected + 1
		elseif xPlayer.job.name == 'taxi' then
			TaxiConnected = TaxiConnected + 1
		elseif xPlayer.job.name == 'mecano' then
			MechanicConnected = MechanicConnected + 1
		elseif xPlayer.job.name == 'cardealer' then
			CardealerConnected = CardealerConnected + 1
		elseif xPlayer.job.name == 'realestateagent' then
			EstateConnected = EstateConnected + 1
		end
	end

	TriggerClientEvent('esx_scoreboard:updatePlayerJobs', -1, json.encode({
			ems = EMSConnected,
			police = PoliceConnected,
			taxi = TaxiConnected,
			mechanic = MechanicConnected,
			cardealer = CardealerConnected,
			estate = EstateConnected,
			player_count = PlayerConnected
	}))
end