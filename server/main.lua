local QBCore = exports['qb-core']:GetCoreObject()
local ActiveDeals = {}

Citizen.CreateThread(function()
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
end)

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

QBCore.Functions.CreateUseableItem(Config.TrapPhoneItem, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.Functions.GetItemByName(Config.TrapPhoneItem) then
        TriggerClientEvent('trap_phone:usePhone', src)
    end
end)

RegisterServerEvent('trap_phone:registerDeal')
AddEventHandler('trap_phone:registerDeal', function(dealData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
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
    
    print("^2Trap Phone: Deal registered for " .. Player.PlayerData.name .. 
          " - " .. drugName .. " x" .. quantity .. 
          " for $" .. price .. "^7")
end)

RegisterServerEvent('trap_phone:registerTransaction')
AddEventHandler('trap_phone:registerTransaction', function(dealData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local drugName = dealData.drugName or "weed_baggy"
    local quantity = tonumber(dealData.quantity) or 1
    local price = tonumber(dealData.price) or 200
    
    print("^2Trap Phone: Transaction initiated - " .. 
          quantity .. "x " .. drugName .. 
          " for $" .. price .. "^7")
    
    local transactionId = 'trans_' .. src .. '_' .. os.time()
    
    ActiveDeals[transactionId] = {
        playerId = src,
        citizenId = Player.PlayerData.citizenid,
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
    local Player = QBCore.Functions.GetPlayer(src)
    
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
        deal = {
            playerId = src,
            citizenId = Player.PlayerData.citizenid,
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
        TriggerClientEvent('QBCore:Notify', src, 'No active deal found', 'error')
        return
    end
    
    deal.quantity = tonumber(deal.quantity) or 1
    deal.price = tonumber(deal.price) or 200
    
    print("^2FINAL DEAL VALUES: Drug=" .. deal.drugName .. 
        ", Quantity=" .. deal.quantity .. 
        ", Price=$" .. deal.price .. "^7")
    
    if not HasDrug(Player, deal.drugName, deal.quantity) then
        print("^1Player missing drugs: " .. deal.drugName .. " x" .. deal.quantity .. "^7")
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have ' .. deal.quantity .. 'x ' .. deal.drugName, 'error')
        return
    end
    
    deal.status = 'completed'
    
    Player.Functions.RemoveItem(deal.drugName, deal.quantity)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[deal.drugName], 'remove', deal.quantity)
    
    Player.Functions.AddMoney('cash', deal.price)
    
    TriggerClientEvent('QBCore:Notify', src, 'Deal completed: Received $' .. deal.price .. ' for ' .. deal.quantity .. 'x ' .. deal.drugName, 'success')
    
    print("^2DEAL COMPLETED: " .. Player.PlayerData.name .. 
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

function HasDrug(player, drugName, quantity)
    if not player or not drugName then
        print("^1HasDrug called with invalid parameters^7")
        return false
    end
    
    quantity = tonumber(quantity) or 1
    
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
    
    return true
end

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