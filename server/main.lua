local QBCore, ESX = nil, nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

local ActiveDeals = {}

local function GetPlayer(src)
    if Config.Framework == 'qb' then
        return QBCore.Functions.GetPlayer(src)
    elseif Config.Framework == 'esx' then
        return ESX.GetPlayerFromId(src)
    end
end

local function HasDrug(player, drugName, quantity)
    if not player or not drugName then
        print("^1HasDrug called with invalid parameters^7")
        return false
    end
    
    quantity = tonumber(quantity) or 1
    
    if Config.Framework == 'qb' then
        local item = player.Functions.GetItemByName(drugName)
        if not item then
            print("^1Player does not have item: " .. drugName .. "^7")
            return false
        end
        
        if item.amount < quantity then
            print("^1Player has insufficient quantity - Has: " .. 
                item.amount .. ", Needs: " .. quantity .. "^7")
            return false
        end
    elseif Config.Framework == 'esx' then
        local item = player.getInventoryItem(drugName)
        if not item then
            print("^1Player does not have item: " .. drugName .. "^7")
            return false
        end
        
        if item.count < quantity then
            print("^1Player has insufficient quantity - Has: " .. 
                item.count .. ", Needs: " .. quantity .. "^7")
            return false
        end
    end
    
    return true
end

Citizen.CreateThread(function()
    if Config.Framework == 'qb' then
        if not QBCore.Shared.Items[Config.TrapPhoneItem] then
            QBCore.Functions.AddItem(Config.TrapPhoneItem, {
                name = Config.TrapPhoneItem,
                label = 'Trap Phone',
                weight = 500,
                type = 'item',
                image = 'trap_phone.png',
                unique = true,
                useable = true,
                shouldClose = true,
                combinable = nil,
                description = 'A burner phone used for illegal business'
            })
            
            print("^2Trap Phone: Item registered with QBCore^7")
        end
    end
end)

if Config.Framework == 'qb' then
    QBCore.Functions.CreateCallback('QBCore:HasItem', function(source, cb, itemName, amount)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return cb(false) end
        
        amount = amount or 1
        local item = Player.Functions.GetItemByName(itemName)
        
        if item and item.amount >= amount then
            cb(true)
        else
            cb(false)
        end
    end)
elseif Config.Framework == 'esx' then
    ESX.RegisterServerCallback('QBCore:HasItem', function(source, cb, itemName, amount)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return cb(false) end
        
        amount = amount or 1
        local item = xPlayer.getInventoryItem(itemName)
        
        if item and item.count >= amount then
            cb(true)
        else
            cb(false)
        end
    end)
end

if Config.Framework == 'qb' then
    QBCore.Functions.CreateUseableItem(Config.TrapPhoneItem, function(source, item)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if Player.Functions.GetItemByName(Config.TrapPhoneItem) then
            TriggerClientEvent('trap_phone:usePhone', src)
        end
    end)
elseif Config.Framework == 'esx' then
    ESX.RegisterUsableItem(Config.TrapPhoneItem, function(source)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if xPlayer.getInventoryItem(Config.TrapPhoneItem).count > 0 then
            TriggerClientEvent('trap_phone:usePhone', src)
        end
    end)
end

RegisterServerEvent('trap_phone:registerDeal')
AddEventHandler('trap_phone:registerDeal', function(dealData)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = ""
    if Config.Framework == 'qb' then
        citizenId = Player.PlayerData.citizenid
    elseif Config.Framework == 'esx' then
        citizenId = Player.identifier
    end
    
    local dealId = dealData.dealId or ('deal_' .. citizenId .. '_' .. os.time())
    
    local drugName = dealData.drugName or "weed_baggy"
    local quantity = tonumber(dealData.quantity) or 1
    local price = tonumber(dealData.price) or 200
    
    print("^4SERVER RECEIVED DEAL DATA: " .. drugName .. 
          " x" .. quantity .. " for $" .. price .. "^7")
    
    ActiveDeals[dealId] = {
        playerId = src,
        citizenId = citizenId,
        contactName = dealData.contactName or "Unknown",
        drugName = drugName,
        quantity = quantity,
        price = price,
        location = dealData.location,
        timestamp = os.time(),
        status = 'pending'
    }
    
    print("^4SERVER STORED DEAL: " .. drugName .. 
          " x" .. quantity .. " for $" .. price .. "^7")
    
    local playerName = ""
    if Config.Framework == 'qb' then
        playerName = Player.PlayerData.name
    elseif Config.Framework == 'esx' then
        playerName = Player.getName()
    end
    
    print("^2Trap Phone: Deal registered for " .. playerName .. 
          " - " .. drugName .. " x" .. quantity .. 
          " for $" .. price .. "^7")
end)

RegisterServerEvent('trap_phone:registerTransaction')
AddEventHandler('trap_phone:registerTransaction', function(dealData)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    local drugName = dealData.drugName or "weed_baggy"
    local quantity = tonumber(dealData.quantity) or 1
    local price = tonumber(dealData.price) or 200
    
    print("^2Trap Phone: Transaction initiated - " .. 
          quantity .. "x " .. drugName .. 
          " for $" .. price .. "^7")
    
    local transactionId = 'trans_' .. src .. '_' .. os.time()
    
    local citizenId = ""
    if Config.Framework == 'qb' then
        citizenId = Player.PlayerData.citizenid
    elseif Config.Framework == 'esx' then
        citizenId = Player.identifier
    end
    
    ActiveDeals[transactionId] = {
        playerId = src,
        citizenId = citizenId,
        contactName = dealData.contactName or "Unknown",
        drugName = drugName,
        quantity = quantity,
        price = price,
        timestamp = os.time(),
        status = 'pending'
    }
end)

RegisterServerEvent('trap_phone:completeDeal')
AddEventHandler('trap_phone:completeDeal', function(dealId, dealData)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    print("^1RECEIVED FROM CLIENT: dealId=" .. tostring(dealId) .. "^7")
    if dealData then
        print("^1DEAL DATA: drug=" .. tostring(dealData.drugName) .. 
              ", quantity=" .. tostring(dealData.quantity) .. 
              ", price=" .. tostring(dealData.price) .. "^7")
    else
        print("^1NO DEAL DATA RECEIVED^7")
    end
    
    local deal = nil
    
    if dealData and dealData.drugName and dealData.quantity and dealData.price then
        local citizenId = ""
        if Config.Framework == 'qb' then
            citizenId = Player.PlayerData.citizenid
        elseif Config.Framework == 'esx' then
            citizenId = Player.identifier
        end
        
        deal = {
            playerId = src,
            citizenId = citizenId,
            drugName = dealData.drugName,
            quantity = tonumber(dealData.quantity),
            price = tonumber(dealData.price),
            status = 'pending'
        }
        
        print("^2DIRECT DEAL DETAILS USED: " .. 
            deal.drugName .. " x" .. deal.quantity .. 
            " for $" .. deal.price .. "^7")
    elseif dealId and ActiveDeals[dealId] then
        deal = ActiveDeals[dealId]
        print("^3Using stored deal: " .. dealId .. "^7")
    else
        for id, dealInfo in pairs(ActiveDeals) do
            if dealInfo.playerId == src and dealInfo.status == 'pending' then
                deal = dealInfo
                dealId = id
                print("^3Using found deal by player ID^7")
                break
            end
        end
    end
    
    if not deal then
        print("^1NO DEAL FOUND FOR PLAYER^7")
        if Config.Framework == 'qb' then
            TriggerClientEvent('QBCore:Notify', src, 'No active deal found', 'error')
        elseif Config.Framework == 'esx' then
            TriggerClientEvent('esx:showNotification', src, 'No active deal found')
        end
        return
    end
    
    deal.quantity = tonumber(deal.quantity) or 1
    deal.price = tonumber(deal.price) or 200
    
    print("^2FINAL DEAL VALUES: Drug=" .. deal.drugName .. 
        ", Quantity=" .. deal.quantity .. 
        ", Price=$" .. deal.price .. "^7")
    
    if not HasDrug(Player, deal.drugName, deal.quantity) then
        print("^1Player missing drugs: " .. deal.drugName .. " x" .. deal.quantity .. "^7")
        if Config.Framework == 'qb' then
            TriggerClientEvent('QBCore:Notify', src, 'You don\'t have ' .. deal.quantity .. 'x ' .. deal.drugName, 'error')
        elseif Config.Framework == 'esx' then
            TriggerClientEvent('esx:showNotification', src, 'You don\'t have ' .. deal.quantity .. 'x ' .. deal.drugName)
        end
        return
    end
    
    deal.status = 'completed'
    
    if Config.Framework == 'qb' then
        Player.Functions.RemoveItem(deal.drugName, deal.quantity)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[deal.drugName], 'remove', deal.quantity)
        Player.Functions.AddMoney('cash', deal.price)
        TriggerClientEvent('QBCore:Notify', src, 'Deal completed: Received $' .. deal.price .. ' for ' .. deal.quantity .. 'x ' .. deal.drugName, 'success')
    elseif Config.Framework == 'esx' then
        Player.removeInventoryItem(deal.drugName, deal.quantity)
        Player.addMoney(deal.price)
        TriggerClientEvent('esx:showNotification', src, 'Deal completed: Received $' .. deal.price .. ' for ' .. deal.quantity .. 'x ' .. deal.drugName)
    end
    
    local playerName = ""
    if Config.Framework == 'qb' then
        playerName = Player.PlayerData.name
    elseif Config.Framework == 'esx' then
        playerName = Player.getName()
    end
    
    print("^2DEAL COMPLETED: " .. playerName .. 
        " - " .. deal.drugName .. " x" .. deal.quantity .. 
        " for $" .. deal.price .. "^7")
    
    if dealId and ActiveDeals[dealId] then
        ActiveDeals[dealId].status = 'completed'
        
        Citizen.SetTimeout(300000, function()
            if ActiveDeals[dealId] then
                ActiveDeals[dealId] = nil
            end
        end)
    end
end)

if Config.Framework == 'qb' then
    QBCore.Commands.Add('givetrapphone', 'Give trap phone to player (Admin only)', {{name='id', help='Player ID'}}, true, function(source, args)
        local src = source
        local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
        
        if not Player then
            TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
            return
        end
        
        Player.Functions.AddItem(Config.TrapPhoneItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', tonumber(args[1]), QBCore.Shared.Items[Config.TrapPhoneItem], 'add', 1)
        TriggerClientEvent('QBCore:Notify', src, 'Trap phone given to ' .. Player.PlayerData.name, 'success')
    end, 'admin')
elseif Config.Framework == 'esx' then
    RegisterCommand('givetrapphone', function(source, args)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer.getGroup() == 'admin' then
            TriggerClientEvent('esx:showNotification', src, 'You don\'t have permission to use this command')
            return
        end
        
        local targetPlayer = ESX.GetPlayerFromId(tonumber(args[1]))
        if not targetPlayer then
            TriggerClientEvent('esx:showNotification', src, 'Player not found')
            return
        end
        
        targetPlayer.addInventoryItem(Config.TrapPhoneItem, 1)
        TriggerClientEvent('esx:showNotification', src, 'Trap phone given to ' .. targetPlayer.getName())
    end, false)
end
