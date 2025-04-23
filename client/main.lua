local QBCore, ESX = nil, nil
local PlayerData = {}
local TrapPhoneVisible = false
local ActiveContact = nil
local ActiveDeal = nil
local CurrentMeetLocation = nil
local LastUsedLocation = nil
local DealerPeds = {}
local TimeSeed = 0
local DealerDeals = {}
local PedDealMap = {}

local phoneProp = 0
local phoneAnimDict = "cellphone@"
local phoneAnim = "cellphone_text_in"

if Config.Framework == 'esx' then
    Citizen.CreateThread(function()
        while ESX == nil do
            Wait(0)
        end
        
        PlayerData = ESX.GetPlayerData()
        print("Initial ESX player data loaded")
    end)
    
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        PlayerData = xPlayer
        print("ESX player data updated from playerLoaded event")
    end)
    
    RegisterNetEvent('esx:addInventoryItem')
    AddEventHandler('esx:addInventoryItem', function(itemName, count)
        print("Item added: " .. itemName .. " x" .. count)
        if not PlayerData.inventory then PlayerData.inventory = {} end
        
        local found = false
        for i=1, #PlayerData.inventory do
            if PlayerData.inventory[i].name == itemName then
                PlayerData.inventory[i].count = count
                found = true
                break
            end
        end
        
        if not found then
            table.insert(PlayerData.inventory, {name = itemName, count = count})
        end
    end)
    
    RegisterNetEvent('esx:removeInventoryItem')
    AddEventHandler('esx:removeInventoryItem', function(itemName, count)
        print("Item removed: " .. itemName .. " x" .. count)
        if not PlayerData.inventory then return end
        
        for i=1, #PlayerData.inventory do
            if PlayerData.inventory[i].name == itemName then
                PlayerData.inventory[i].count = count
                break
            end
        end
    end)
end

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

function StartPhoneAnimation()
    local player = PlayerPedId()
    local animDict = phoneAnimDict
    local animation = phoneAnim
    
    if IsPedInAnyVehicle(player, false) then
        animDict = "cellphone@in_car@ds"
    end
    
    StopAnimTask(player, animDict, animation, 1.0)
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    
    DeletePhone()
    
    TaskPlayAnim(player, animDict, animation, 3.0, 3.0, -1, 50, 0, false, false, false)
    
    local x,y,z = table.unpack(GetEntityCoords(player))
    local propName = `prop_npc_phone_02`
    RequestModel(propName)
    
    while not HasModelLoaded(propName) do
        Citizen.Wait(10)
    end
    
    phoneProp = CreateObject(propName, x, y, z+0.2, true, true, true)
    local boneIndex = GetPedBoneIndex(player, 28422)
    AttachEntityToEntity(phoneProp, player, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(propName)
end

function DeletePhone()
    if phoneProp ~= 0 then
        DeleteObject(phoneProp)
        phoneProp = 0
    end
    
    local player = PlayerPedId()
    StopAnimTask(player, phoneAnimDict, phoneAnim, 1.0)
    StopAnimTask(player, "cellphone@in_car@ds", phoneAnim, 1.0)
end

_G.CurrentDealInfo = nil

Citizen.CreateThread(function()
    while QBCore == nil and ESX == nil do
        Wait(200)
    end
    
    if Config.Framework == 'qb' then
        PlayerData = QBCore.Functions.GetPlayerData()
    elseif Config.Framework == 'esx' then
        PlayerData = ESX.GetPlayerData()
    end
    
    print("^2Trap Phone: Script initializing...^7")
    
    RegisterCommand('trapphone', function()
        ToggleTrapPhone()
    end, false)
    
    RegisterKeyMapping('trapphone', 'Toggle Trap Phone', 'keyboard', 'F8')
    
    RegisterNetEvent('trap_phone:usePhone')
    AddEventHandler('trap_phone:usePhone', function()
        ToggleTrapPhone()
    end)
    
    TimeSeed = GetGameTimer()
    math.randomseed(TimeSeed)
    
    CleanupAllDealerPeds()
end)

AddEventHandler('baseevents:onPlayerDied', function()
    if TrapPhoneVisible then
        CloseTrapPhone()
    end
end)

AddEventHandler('baseevents:onPlayerWasted', function()
    if TrapPhoneVisible then
        CloseTrapPhone()
    end
end)

Citizen.CreateThread(function()
    while true do
        TimeSeed = (TimeSeed + 10000) + GetGameTimer()
        math.randomseed(TimeSeed)
        Wait(60000)
    end
end)

if Config.Framework == 'qb' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData()
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        PlayerData = {}
        CloseTrapPhone()
        CleanupAllDealerPeds()
    end)

    RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
        PlayerData = data
    end)
elseif Config.Framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        PlayerData = xPlayer
    end)
    
    RegisterNetEvent('esx:onPlayerLogout')
    AddEventHandler('esx:onPlayerLogout', function()
        PlayerData = {}
        CloseTrapPhone()
        CleanupAllDealerPeds()
    end)
    
    RegisterNetEvent('esx:setPlayerData')
    AddEventHandler('esx:setPlayerData', function(key, value)
        PlayerData[key] = value
    end)
end

RegisterNetEvent('trap_phone:showNotification')
AddEventHandler('trap_phone:showNotification', function(message, type)
    if Config.Framework == 'qb' then
        QBCore.Functions.Notify(message, type)
    elseif Config.Framework == 'esx' then
        ESX.ShowNotification(message)
    end
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    if CurrentMeetLocation then
        print("^3Meeting location already exists, updating deal info only^7")
        
        local drugName = data.drugItemName or data.drugName
        local quantity = tonumber(data.quantity) or 1
        local price = tonumber(data.price) or 200
        
        if ActiveDeal then
            ActiveDeal.drugName = drugName
            ActiveDeal.quantity = quantity
            ActiveDeal.price = price
            
            print("^2Updated ActiveDeal without changing location: " .. 
                  ActiveDeal.drugName .. " x" .. 
                  ActiveDeal.quantity .. " for $" .. 
                  ActiveDeal.price .. "^7")
        else
            ActiveDeal = {
                drugName = drugName,
                quantity = quantity,
                price = price,
                contactName = ActiveContact and ActiveContact.name or "Unknown"
            }
            
            print("^2Created new ActiveDeal with existing location: " .. 
                  ActiveDeal.drugName .. " x" .. 
                  ActiveDeal.quantity .. " for $" .. 
                  ActiveDeal.price .. "^7")
        end
        
        _G.CurrentDealInfo = {
            drugName = drugName,
            quantity = quantity,
            price = price,
            timestamp = GetGameTimer()
        }
        
        TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
        
        cb({status = "success", message = "Deal details updated"})
        return
    end

    local drugName = data.drugItemName or data.drugName or "weed_baggy"
    local quantity = tonumber(data.quantity) or 1
    local price = tonumber(data.price) or 200
    
    print("^3Creating new ActiveDeal in setWaypoint: " .. drugName .. " x" .. quantity .. " for $" .. price .. "^7")
    
    ActiveDeal = {
        drugName = drugName,
        quantity = quantity,
        price = price,
        contactName = ActiveContact and ActiveContact.name or "Unknown"
    }
    
    _G.CurrentDealInfo = {
        drugName = drugName,
        quantity = quantity,
        price = price,
        timestamp = GetGameTimer()
    }
    
    print("^4Global deal info set: " .. _G.CurrentDealInfo.drugName .. 
          " x" .. _G.CurrentDealInfo.quantity .. 
          " for $" .. _G.CurrentDealInfo.price .. "^7")
    
    TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
    
    local success = ProcessDealLocation()
    
    cb({status = "success", message = "Waypoint set"})
end)

function ToggleTrapPhone()
    if HasTrapPhone() then
        if TrapPhoneVisible then
            CloseTrapPhone()
        else
            OpenTrapPhone()
        end
    else
        if Config.Framework == 'qb' then
            QBCore.Functions.Notify('You need a trap phone to do this', 'error')
        elseif Config.Framework == 'esx' then
            ESX.ShowNotification('You need a trap phone to do this')
        end
    end
end

function HasTrapPhone()
    print("Checking for trap phone: " .. Config.TrapPhoneItem)
    
    if Config.Framework == 'qb' then
        local items = PlayerData.items
        if not items then return false end
        
        for _, item in pairs(items) do
            if item.name == Config.TrapPhoneItem and item.amount > 0 then
                return true
            end
        end
    elseif Config.Framework == 'esx' then
        if not PlayerData.inventory then 
            print("ESX: PlayerData.inventory is nil")
            return false 
        end
        
        print("ESX Inventory Contents:")
        for _, item in pairs(PlayerData.inventory) do
            print(item.name .. " x" .. (item.count or 0))
        end
        
        for _, item in pairs(PlayerData.inventory) do
            if item.name == Config.TrapPhoneItem and item.count > 0 then
                print("Found trap phone in inventory: " .. item.count)
                return true
            end
        end
    end
    
    return false
end

function OpenTrapPhone()
    TrapPhoneVisible = true
    SetNuiFocus(true, true)
    
    StartPhoneAnimation()
    
    local availableDrugs = GetPlayerDrugs()
    
    local contacts = {}
    if ActiveContact then
        table.insert(contacts, ActiveContact)
    end
    
    local currentMeetLocationData = nil
    if CurrentMeetLocation then
        currentMeetLocationData = CurrentMeetLocation
    end
    
    local playerName = ""
    if Config.Framework == 'qb' then
        playerName = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname
    elseif Config.Framework == 'esx' then
        playerName = PlayerData.name
    end
    
    SendNUIMessage({
        action = 'openPhone',
        drugs = availableDrugs,
        contacts = contacts,
        playerName = playerName,
        currentMeetLocation = currentMeetLocationData
    })
    
    Citizen.CreateThread(function()
        while TrapPhoneVisible do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
            Wait(0)
        end
    end)
end

function CloseTrapPhone()
    TrapPhoneVisible = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closePhone'
    })
    
    DeletePhone()
end

function GetPlayerDrugs()
    local playerDrugs = {}
    
    if Config.Framework == 'qb' then
        local items = PlayerData.items
        if not items then return playerDrugs end
        
        for _, item in pairs(items) do
            for _, drugConfig in pairs(Config.TrapPhoneDrugs) do
                if item.name == drugConfig.name and item.amount > 0 then
                    table.insert(playerDrugs, {
                        name = item.name,
                        label = drugConfig.label,
                        streetName = drugConfig.streetName,
                        amount = item.amount,
                        basePrice = drugConfig.basePrice,
                        minPrice = drugConfig.priceRange[1],
                        maxPrice = drugConfig.priceRange[2]
                    })
                    break
                end
            end
        end
    elseif Config.Framework == 'esx' then
        local inventory = nil
        
        print("ESX PlayerData Structure: ")
        for k, v in pairs(PlayerData) do
            print(k, type(v))
        end
        
        if PlayerData.inventory then
            inventory = PlayerData.inventory
            print("Using standard ESX inventory")
        elseif ESX.GetPlayerData().inventory then
            inventory = ESX.GetPlayerData().inventory
            print("Using ESX GetPlayerData inventory")
        else
            print("No inventory found in PlayerData, trying to get it directly")
            ESX.TriggerServerCallback('esx:getPlayerData', function(data)
                if data and data.inventory then
                    inventory = data.inventory
                end
            end)
            
            local waited = 0
            while inventory == nil and waited < 10 do
                Citizen.Wait(100)
                waited = waited + 1
            end
        end
        
        if not inventory then
            print("Failed to get inventory from ESX")
            return playerDrugs
        end
        
        for k, item in pairs(inventory) do
            print("Checking item: " .. item.name .. " count: " .. tostring(item.count))
            
            for _, drugConfig in pairs(Config.TrapPhoneDrugs) do
                if item.name == drugConfig.name and item.count and item.count > 0 then
                    print("Found matching drug: " .. item.name .. " x" .. item.count)
                    table.insert(playerDrugs, {
                        name = item.name,
                        label = drugConfig.label,
                        streetName = drugConfig.streetName,
                        amount = item.count,
                        basePrice = drugConfig.basePrice,
                        minPrice = drugConfig.priceRange[1],
                        maxPrice = drugConfig.priceRange[2]
                    })
                    break
                end
            end
        end
    end
    
    print("Found " .. #playerDrugs .. " drugs in inventory")
    return playerDrugs
end

function GetCurrentTimeFormatted()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    
    if hours < 10 then hours = "0" .. hours end
    if minutes < 10 then minutes = "0" .. minutes end
    
    return hours .. ":" .. minutes
end

function GetRandomMeetLocation()
    TimeSeed = (TimeSeed + 12345) + GetGameTimer()
    math.randomseed(TimeSeed)
    
    local availableLocations = {}
    for i, location in ipairs(Config.MeetLocations) do
        table.insert(availableLocations, location)
    end
    
    if LastUsedLocation then
        for i, location in ipairs(availableLocations) do
            if location.name == LastUsedLocation.name then
                table.remove(availableLocations, i)
                break
            end
        end
    end
    
    if #availableLocations == 0 then
        for i, location in ipairs(Config.MeetLocations) do
            table.insert(availableLocations, location)
        end
    end
    
    local randomIndex = math.random(1, #availableLocations)
    local chosenLocation = availableLocations[randomIndex]
    
    LastUsedLocation = chosenLocation
    
    print("^3Selected meeting location: " .. chosenLocation.name .. "^7")
    
    return chosenLocation
end

function CreateNewContact()
    TimeSeed = (TimeSeed + 54321) + GetGameTimer()
    math.randomseed(TimeSeed)
    
    local availableContacts = {}
    for i, contact in ipairs(Config.Contacts) do
        table.insert(availableContacts, contact)
    end
    
    if ActiveContact then
        for i, contact in ipairs(availableContacts) do
            if contact.name == ActiveContact.name then
                table.remove(availableContacts, i)
                break
            end
        end
    end
    
    if #availableContacts == 0 then
        for i, contact in ipairs(Config.Contacts) do
            table.insert(availableContacts, contact)
        end
    end
    
    local randomIndex = math.random(1, #availableContacts)
    local contact = availableContacts[randomIndex]
    
    local contactId = 'contact_' .. GetGameTimer() .. '_' .. math.random(1000, 9999)
    
    local newContact = {
        id = contactId,
        name = contact.name,
        avatar = contact.avatar,
        avatarColor = contact.avatarColor,
        verified = contact.verified,
        relationship = math.random(30, 70),
        initialMessage = contact.initialMessage,
        messages = {}
    }
    
    table.insert(newContact.messages, {
        sender = 'them',
        text = contact.initialMessage,
        time = GetCurrentTimeFormatted()
    })
    
    ActiveContact = newContact
    
    _G.CurrentDealInfo = nil
    ActiveDeal = nil
    CurrentMeetLocation = nil
    
    SendNUIMessage({
        action = 'newContact',
        contact = newContact
    })
    
    print("^2Trap Phone: New contact created: " .. newContact.name .. "^7")
    
    return newContact
end

function ProcessDealLocation()
    if CurrentMeetLocation then
        
        if not ActiveDeal and _G.CurrentDealInfo then
            ActiveDeal = {
                drugName = _G.CurrentDealInfo.drugName,
                quantity = _G.CurrentDealInfo.quantity,
                price = _G.CurrentDealInfo.price,
                contactName = ActiveContact and ActiveContact.name or "Unknown"
            }
            print("^2Recreated ActiveDeal from global data^7")
        end
        
        return false
    end

    if not ActiveDeal then
        print("^1Critical: ProcessDealLocation called without ActiveDeal - creating a default one^7")
        
        if _G.CurrentDealInfo then
            ActiveDeal = {
                drugName = _G.CurrentDealInfo.drugName,
                quantity = _G.CurrentDealInfo.quantity,
                price = _G.CurrentDealInfo.price,
                contactName = ActiveContact and ActiveContact.name or "Unknown"
            }
            print("^2Created ActiveDeal from global data: " .. 
                  ActiveDeal.drugName .. " x" .. 
                  ActiveDeal.quantity .. " for $" .. 
                  ActiveDeal.price .. "^7")
        else
            ActiveDeal = {
                drugName = "weed_baggy",
                quantity = 1,
                price = 200,
                contactName = ActiveContact and ActiveContact.name or "Unknown"
            }
            
            _G.CurrentDealInfo = {
                drugName = "weed_baggy",
                quantity = 1,
                price = 200,
                timestamp = GetGameTimer()
            }
            
            print("^3Created default ActiveDeal with no existing data^7")
        end
        
        TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
    else
        _G.CurrentDealInfo = {
            drugName = ActiveDeal.drugName,
            quantity = ActiveDeal.quantity,
            price = ActiveDeal.price,
            timestamp = GetGameTimer()
        }
    end
    
    local location = GetRandomMeetLocation()
    if not location then
        print("^1Warning: Failed to get random location^7")
        return false
    end
    
    CurrentMeetLocation = location
    
    if ActiveContact then
        print("^3Before adding location message - Messages count: " .. #ActiveContact.messages .. "^7")
    end
    
    local responses = Config.NPCResponses.meet_location
    local responseIndex = math.random(1, #responses)
    local response = string.format(responses[responseIndex], location.name)
    
    if ActiveContact then
        local isDuplicate = false
        if #ActiveContact.messages > 0 then
            local lastMsg = ActiveContact.messages[#ActiveContact.messages]
            if lastMsg.sender == 'them' and lastMsg.text == response then
                isDuplicate = true
                print("^3Avoided adding duplicate location message^7")
            end
        end
        
        if not isDuplicate then
            table.insert(ActiveContact.messages, {
                sender = 'them',
                text = response,
                time = GetCurrentTimeFormatted()
            })
        end
        
        SendNUIMessage({
            action = 'updateMessages',
            messages = ActiveContact.messages,
            preserveChat = true,
            locationSet = true,
            locationName = location.name
        })
        
        print("^3After adding location message - Messages count: " .. #ActiveContact.messages .. "^7")
    end
    
    SetNewWaypoint(location.coords.x, location.coords.y)
    
    SetupMeetingPoint(location)
    
    if Config.Framework == 'qb' then
        QBCore.Functions.Notify('Meeting location marked on your GPS', 'success')
    elseif Config.Framework == 'esx' then
        ESX.ShowNotification('Meeting location marked on your GPS')
    end
    
    if math.random(100) <= Config.PoliceSettings.alertChance then
        AlertPolice()
    end
    
    return true
end

function GetSafeGroundPosition(position)
    local x, y, z = position.x, position.y, position.z
    local groundFound, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    
    if groundFound then
        return vector3(x, y, groundZ)
    else
        local offsetX = math.random(-5, 5)
        local offsetY = math.random(-5, 5)
        groundFound, groundZ = GetGroundZFor_3dCoord(x + offsetX, y + offsetY, z, false)
        
        if groundFound then
            return vector3(x + offsetX, y + offsetY, groundZ)
        else
            return vector3(x, y, z + 0.5)
        end
    end
end

function GetNearestRoadPosition(coords)
    local safePos = GetSafeGroundPosition(coords)
    
    local success, roadPosition = GetNthClosestVehicleNode(safePos.x, safePos.y, safePos.z, 1, 0, 0, 0)
    
    if success then
        if type(roadPosition) == "vector3" then
            return roadPosition
        end
    end
    
    local success2, roadPos = GetClosestVehicleNodeWithHeading(safePos.x, safePos.y, safePos.z, 0, 3.0, 0)
    
    if success2 and type(roadPos) == "vector3" then
        return roadPos
    end
    
    return safePos
end

function SetupMeetingPoint(location)
    if not ActiveDeal then
        print("^1Error: No active deal when trying to setup meeting point^7")
        if _G.CurrentDealInfo then
            ActiveDeal = {
                drugName = _G.CurrentDealInfo.drugName,
                quantity = _G.CurrentDealInfo.quantity,
                price = _G.CurrentDealInfo.price,
                contactName = ActiveContact and ActiveContact.name or "Unknown"
            }
            print("^2Created ActiveDeal from global data in SetupMeetingPoint^7")
        else
            print("^1No global deal info available, cannot setup meeting^7")
            return
        end
    end
    
    ActiveDeal.quantity = tonumber(ActiveDeal.quantity) or 1
    ActiveDeal.price = tonumber(ActiveDeal.price) or 200
    
    print("^4BEFORE CREATING DEAL - Active Deal Values: " .. 
          ActiveDeal.drugName .. " x" .. 
          ActiveDeal.quantity .. " for $" .. 
          ActiveDeal.price .. "^7")
    
    local dealId = 'deal_' .. GetGameTimer() .. '_' .. math.random(1000, 9999)
    
    local exactDrugName = ActiveDeal.drugName
    local exactQuantity = tonumber(ActiveDeal.quantity)
    local exactPrice = tonumber(ActiveDeal.price)
    
    print("^3Setting up deal - Drug: " .. exactDrugName .. 
          ", Quantity: " .. exactQuantity .. 
          ", Price: $" .. exactPrice .. "^7")
    
    local dealDetails = {
        dealId = dealId,
        contactName = ActiveContact and ActiveContact.name or "Unknown",
        drugName = exactDrugName,
        quantity = exactQuantity,
        price = exactPrice,
        location = location
    }
    
    print("^4CRITICAL - Deal details before storage: " .. 
          dealDetails.drugName .. " x" .. 
          dealDetails.quantity .. " for $" .. 
          dealDetails.price .. "^7")
    
    DealerDeals[dealId] = {
        dealId = dealId,
        contactName = dealDetails.contactName,
        drugName = exactDrugName,
        quantity = exactQuantity,
        price = exactPrice,
        location = location
    }
    
    print("^4VERIFICATION - DealerDeals[" .. dealId .. "]: " .. 
          DealerDeals[dealId].drugName .. " x" .. 
          DealerDeals[dealId].quantity .. " for $" .. 
          DealerDeals[dealId].price .. "^7")
    
    _G.CurrentDealInfo = {
        drugName = exactDrugName,
        quantity = exactQuantity,
        price = exactPrice,
        timestamp = GetGameTimer()
    }
    
    print("^4CRITICAL - Global deal info updated: " .. 
          _G.CurrentDealInfo.drugName .. " x" .. 
          _G.CurrentDealInfo.quantity .. " for $" .. 
          _G.CurrentDealInfo.price .. "^7")
    
    TriggerServerEvent('trap_phone:registerDeal', DealerDeals[dealId])
    
    CreateDealerNPCAtLocation(location, dealId)
    
    TriggerEvent('drug_selling:client:createDealerNPC', {
        dealId = dealId,
        drugName = exactDrugName,
        quantity = exactQuantity,
        price = exactPrice,
        coords = location.coords
    })
end

function CreateDealerNPCAtLocation(location, dealId)
    if not DealerDeals[dealId] then
        print("^1ERROR: No DealerDeals found for dealId " .. dealId .. " before creating NPC^7")
        return
    end
    
    local exactDrugName = DealerDeals[dealId].drugName
    local exactQuantity = tonumber(DealerDeals[dealId].quantity)
    local exactPrice = tonumber(DealerDeals[dealId].price)
    
    print("^4CREATE DEALER - Using exact deal info: " .. 
          exactDrugName .. " x" .. exactQuantity .. 
          " for $" .. exactPrice .. "^7")
    
    Citizen.CreateThread(function()
        local isPlayerClose = false
        local proximityCheckInterval = 3000
        local timeoutCounter = 0
        local maxTimeout = 40
        
        while not isPlayerClose and timeoutCounter < maxTimeout do
            Wait(proximityCheckInterval)
            timeoutCounter = timeoutCounter + 1
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distanceToLocation = #(playerCoords - location.coords)
            
            if distanceToLocation < 200.0 then
                isPlayerClose = true
            end
        end
        
        if not DealerDeals[dealId] then
            print("^1Error: DealerDeals was lost during proximity wait for dealId: " .. dealId .. "^7")
            
            DealerDeals[dealId] = {
                dealId = dealId,
                contactName = ActiveContact and ActiveContact.name or "Unknown",
                drugName = exactDrugName,
                quantity = exactQuantity,
                price = exactPrice,
                location = location
            }
            
            print("^2Recreated DealerDeals with exact values: " .. 
                  exactDrugName .. " x" .. exactQuantity .. 
                  " for $" .. exactPrice .. "^7")
        else
            DealerDeals[dealId].drugName = exactDrugName
            DealerDeals[dealId].quantity = exactQuantity
            DealerDeals[dealId].price = exactPrice
            
            print("^2Verified and corrected DealerDeals data: " .. 
                  DealerDeals[dealId].drugName .. " x" .. 
                  DealerDeals[dealId].quantity .. " for $" .. 
                  DealerDeals[dealId].price .. "^7")
        end
        
        print("^2Creating dealer NPC at location: " .. location.name .. "^7")
        
        local pedModels = {
            "a_m_m_eastsa_01",
            "a_m_m_eastsa_02",
            "a_m_y_eastsa_01",
            "a_m_m_soucent_01",
            "a_m_y_soucent_01",
            "a_m_m_mexlabor_01",
            "g_m_y_mexgoon_01",
            "a_m_m_afriamer_01",
            "a_m_y_mexthug_01",
            "cs_orleans"
        }
        
        TimeSeed = (TimeSeed + 98765) + GetGameTimer()
        math.randomseed(TimeSeed)
        local pedModel = pedModels[math.random(#pedModels)]
        
        local pedHash = GetHashKey(pedModel)
        RequestModel(pedHash)
        
        local modelLoadTimeoutCounter = 0
        while not HasModelLoaded(pedHash) and modelLoadTimeoutCounter < 100 do
            Wait(100)
            modelLoadTimeoutCounter = modelLoadTimeoutCounter + 1
        end
        
        if HasModelLoaded(pedHash) then
            local offsetX = math.random(-3, 3) * 0.5
            local offsetY = math.random(-3, 3) * 0.5
            local dealerPos = vector3(location.coords.x + offsetX, location.coords.y + offsetY, location.coords.z)
            
            local groundFound, groundZ = GetGroundZFor_3dCoord(dealerPos.x, dealerPos.y, dealerPos.z, false)
            if groundFound then
                dealerPos = vector3(dealerPos.x, dealerPos.y, groundZ)
            end
            
            local dealerPed = CreatePed(4, pedHash, dealerPos.x, dealerPos.y, dealerPos.z, 0.0, false, true)
            
            table.insert(DealerPeds, dealerPed)
            
            SetEntityInvincible(dealerPed, true)
            SetBlockingOfNonTemporaryEvents(dealerPed, true)
            
            local heading = math.random(0, 359) + 0.0
            SetEntityHeading(dealerPed, heading)
            
            local blip = AddBlipForEntity(dealerPed)
            SetBlipSprite(blip, 500)
            SetBlipColour(blip, 1)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Drug Deal")
            EndTextCommandSetBlipName(blip)
            
            Wait(500)
            
            local animDict = "amb@world_human_smoking@male@male_a@base"
            RequestAnimDict(animDict)
            
            local animLoadTimeoutCounter = 0
            while not HasAnimDictLoaded(animDict) and animLoadTimeoutCounter < 100 do
                Wait(100)
                animLoadTimeoutCounter = animLoadTimeoutCounter + 1
            end
            
            local propName = "prop_cs_ciggy_01"
            RequestModel(GetHashKey(propName))
            
            local propLoadTimeoutCounter = 0
            while not HasModelLoaded(GetHashKey(propName)) and propLoadTimeoutCounter < 100 do
                Wait(100)
                propLoadTimeoutCounter = propLoadTimeoutCounter + 1
            end
            
            if HasAnimDictLoaded(animDict) and HasModelLoaded(GetHashKey(propName)) then
                TaskPlayAnim(dealerPed, animDict, "base", 8.0, -8.0, -1, 1, 0, false, false, false)
                
                local boneIndex = GetPedBoneIndex(dealerPed, 28422)
                local cigaretteProp = CreateObject(GetHashKey(propName), dealerPos.x, dealerPos.y, dealerPos.z, true, true, true)
                
                if cigaretteProp ~= 0 then
                    AttachEntityToEntity(cigaretteProp, dealerPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                end
                
                SetModelAsNoLongerNeeded(GetHashKey(propName))
            end
            
            PedDealMap[dealerPed] = dealId
            
            print("^3Dealer deal data - DealId: " .. dealId .. 
                  ", Drug: " .. exactDrugName .. 
                  ", Quantity: " .. exactQuantity .. 
                  ", Price: $" .. exactPrice .. "^7")
            
            PedDealMap[dealerPed] = dealId
            
            if Entity then
                local state = Entity(dealerPed).state
                if state then
                    local dealDetailsCopy = {
                        dealId = dealId,
                        drugName = exactDrugName,
                        quantity = exactQuantity,
                        price = exactPrice,
                        contactName = DealerDeals[dealId].contactName
                    }
                    state:set('dealDetails', dealDetailsCopy, true)
                    print("^2Deal details saved to entity state successfully^7")
                end
            end
            
            _G.CurrentDealInfo = {
                drugName = exactDrugName,
                quantity = exactQuantity,
                price = exactPrice,
                timestamp = GetGameTimer()
            }
            
            Citizen.InvokeNative(0x9CB1A1623062F402, dealerPed, "trap_dealer_" .. dealId)
            
            print("^4CRITICAL - Global deal info updated: " .. _G.CurrentDealInfo.drugName .. 
                  " x" .. _G.CurrentDealInfo.quantity .. 
                  " for $" .. _G.CurrentDealInfo.price .. "^7")
            
            if Config.Framework == 'qb' then
                QBCore.Functions.Notify('The dealer is waiting for you at the marked location', 'info')
            elseif Config.Framework == 'esx' then
                ESX.ShowNotification('The dealer is waiting for you at the marked location')
            end
            
            if Config.Framework == 'qb' and Config.UseQBTarget then
                SetupQBTargetInteraction(dealerPed, dealId, blip)
            elseif Config.UseOxTarget then
                SetupOxTargetInteraction(dealerPed, dealId, blip)
            else
                SetupDealerInteraction(dealerPed, dealId, blip)
            end
            
            SetModelAsNoLongerNeeded(pedHash)
        else
            print("^1Failed to load dealer ped model^7")
        end
    end)
end

function SetupQBTargetInteraction(dealerPed, dealId, blip)
    exports['qb-target']:AddTargetEntity(dealerPed, {
        options = {
            {
                type = "client",
                event = "",
                icon = "fas fa-handshake",
                label = "Trap Deal",
                action = function()
                    if ActiveDeal and ActiveDeal.drugName and ActiveDeal.quantity and ActiveDeal.price then
                        print("^4CRITICAL - Using ActiveDeal as highest priority source^7")
                        print("^4ActiveDeal contains: " .. ActiveDeal.drugName .. 
                              " x" .. ActiveDeal.quantity .. 
                              " for $" .. ActiveDeal.price .. "^7")
                        
                        local exactDealDetails = {
                            dealId = dealId or "active_deal",
                            drugName = ActiveDeal.drugName,
                            quantity = tonumber(ActiveDeal.quantity),
                            price = tonumber(ActiveDeal.price)
                        }
                        
                        print("^4CRITICAL - Using exact ActiveDeal details: " .. 
                              exactDealDetails.drugName .. " x" .. 
                              exactDealDetails.quantity .. " for $" .. 
                              exactDealDetails.price .. "^7")
                        
                        local dealCompleted = HandleDrugDeal(dealerPed, dealId, exactDealDetails)
                        
                        if dealCompleted then
                            if blip and DoesBlipExist(blip) then
                                RemoveBlip(blip)
                            end
                        end
                        
                        return
                    end
                
                    local dealDetails = nil
                    
                    local pedDealId = PedDealMap[dealerPed] or dealId
                    
                    print("^4Looking for deal. Ped Deal ID: " .. tostring(pedDealId) .. "^7")
                    
                    if pedDealId and DealerDeals and DealerDeals[pedDealId] then
                        dealDetails = DealerDeals[pedDealId]
                        print("^2QB-Target: Found deal in DealerDeals with ID: " .. pedDealId .. "^7")
                    
                    elseif Entity then
                        local state = Entity(dealerPed).state
                        if state and state.dealDetails then
                            dealDetails = state.dealDetails
                            print("^2QB-Target: Found deal in entity state^7")
                        end
                    
                    elseif _G.CurrentDealInfo then
                        dealDetails = {
                            dealId = pedDealId or "global_deal",
                            drugName = _G.CurrentDealInfo.drugName,
                            quantity = _G.CurrentDealInfo.quantity,
                            price = _G.CurrentDealInfo.price
                        }
                        print("^2QB-Target: Using global CurrentDealInfo^7")
                    
                    elseif ActiveDeal then
                        dealDetails = {
                            dealId = pedDealId or "active_deal",
                            drugName = ActiveDeal.drugName,
                            quantity = ActiveDeal.quantity,
                            price = ActiveDeal.price
                        }
                        print("^2QB-Target: Using ActiveDeal as fallback^7")
                    end
                    
                    if dealDetails then
                        print("^3QB-Target interaction with details - Drug: " .. dealDetails.drugName .. 
                              ", Quantity: " .. tostring(dealDetails.quantity) .. 
                              ", Price: $" .. tostring(dealDetails.price) .. "^7")
                    else
                        print("^1QB-Target: No deal details found! Creating default deal.^7")
                        
                        dealDetails = {
                            dealId = pedDealId or "default_deal",
                            drugName = "weed_baggy",
                            quantity = 1,
                            price = 200
                        }
                    end
                    
                    local dealCompleted = HandleDrugDeal(dealerPed, pedDealId, dealDetails)
                    
                    if dealCompleted then
                        if blip and DoesBlipExist(blip) then
                            RemoveBlip(blip)
                        end
                    end
                end,
                canInteract = function()
                    return true
                end,
            }
        },
        distance = 2.5,
    })
end

function SetupOxTargetInteraction(dealerPed, dealId, blip)
    exports.ox_target:addLocalEntity(dealerPed, {
        {
            name = 'drug_deal_' .. dealId,
            icon = 'fas fa-handshake',
            label = 'Trap Deal',
            distance = 2.5,
            onSelect = function()
                if ActiveDeal and ActiveDeal.drugName and ActiveDeal.quantity and ActiveDeal.price then
                    print("^4CRITICAL - Using ActiveDeal as highest priority source^7")
                    print("^4ActiveDeal contains: " .. ActiveDeal.drugName .. 
                          " x" .. ActiveDeal.quantity .. 
                          " for $" .. ActiveDeal.price .. "^7")
                    
                    local exactDealDetails = {
                        dealId = dealId or "active_deal",
                        drugName = ActiveDeal.drugName,
                        quantity = tonumber(ActiveDeal.quantity),
                        price = tonumber(ActiveDeal.price)
                    }
                    
                    print("^4CRITICAL - Using exact ActiveDeal details: " .. 
                          exactDealDetails.drugName .. " x" .. 
                          exactDealDetails.quantity .. " for $" .. 
                          exactDealDetails.price .. "^7")
                    
                    local dealCompleted = HandleDrugDeal(dealerPed, dealId, exactDealDetails)
                    
                    if dealCompleted then
                        if blip and DoesBlipExist(blip) then
                            RemoveBlip(blip)
                        end
                    end
                    
                    return
                end
            
                local dealDetails = nil
                
                local pedDealId = PedDealMap[dealerPed] or dealId
                
                print("^4Looking for deal. Ped Deal ID: " .. tostring(pedDealId) .. "^7")
                
                if pedDealId and DealerDeals and DealerDeals[pedDealId] then
                    dealDetails = DealerDeals[pedDealId]
                    print("^2OX-Target: Found deal in DealerDeals with ID: " .. pedDealId .. "^7")
                
                elseif Entity then
                    local state = Entity(dealerPed).state
                    if state and state.dealDetails then
                        dealDetails = state.dealDetails
                        print("^2OX-Target: Found deal in entity state^7")
                    end
                
                elseif _G.CurrentDealInfo then
                    dealDetails = {
                        dealId = pedDealId or "global_deal",
                        drugName = _G.CurrentDealInfo.drugName,
                        quantity = _G.CurrentDealInfo.quantity,
                        price = _G.CurrentDealInfo.price
                    }
                    print("^2OX-Target: Using global CurrentDealInfo^7")
                
                elseif ActiveDeal then
                    dealDetails = {
                        dealId = pedDealId or "active_deal",
                        drugName = ActiveDeal.drugName,
                        quantity = ActiveDeal.quantity,
                        price = ActiveDeal.price
                    }
                    print("^2OX-Target: Using ActiveDeal as fallback^7")
                end
                
                if dealDetails then
                    print("^3OX-Target interaction with details - Drug: " .. dealDetails.drugName .. 
                          ", Quantity: " .. tostring(dealDetails.quantity) .. 
                          ", Price: $" .. tostring(dealDetails.price) .. "^7")
                else
                    print("^1OX-Target: No deal details found! Creating default deal.^7")
                    
                    dealDetails = {
                        dealId = pedDealId or "default_deal",
                        drugName = "weed_baggy",
                        quantity = 1,
                        price = 200
                    }
                end
                
                local dealCompleted = HandleDrugDeal(dealerPed, pedDealId, dealDetails)
                
                if dealCompleted then
                    if blip and DoesBlipExist(blip) then
                        RemoveBlip(blip)
                    end
                end
            end
        }
    })
end

function SetupDealerInteraction(dealerPed, dealId, blip)
    Citizen.CreateThread(function()
        local interactionActive = true
        local dealCompleted = false
        
        while interactionActive and DoesEntityExist(dealerPed) do
            Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pedCoords = GetEntityCoords(dealerPed)
            local distance = #(playerCoords - pedCoords)
            
            if distance < 2.0 and not dealCompleted then
                AddTextEntry('TRAPPHONE_DEAL', "Press ~INPUT_CONTEXT~ to deal with the dealer")
                DisplayHelpTextThisFrame('TRAPPHONE_DEAL', false)
                
                if IsControlJustReleased(0, 38) then
                    if ActiveDeal and ActiveDeal.drugName and ActiveDeal.quantity and ActiveDeal.price then
                        print("^4CRITICAL - Using ActiveDeal as highest priority source^7")
                        print("^4ActiveDeal contains: " .. ActiveDeal.drugName .. 
                              " x" .. ActiveDeal.quantity .. 
                              " for $" .. ActiveDeal.price .. "^7")
                        
                        local exactDealDetails = {
                            dealId = dealId or "active_deal",
                            drugName = ActiveDeal.drugName,
                            quantity = tonumber(ActiveDeal.quantity),
                            price = tonumber(ActiveDeal.price)
                        }
                        
                        print("^4CRITICAL - Using exact ActiveDeal details: " .. 
                              exactDealDetails.drugName .. " x" .. 
                              exactDealDetails.quantity .. " for $" .. 
                              exactDealDetails.price .. "^7")
                        
                        local dealCompleted = HandleDrugDeal(dealerPed, dealId, exactDealDetails)
                        
                        if dealCompleted then
                            if blip and DoesBlipExist(blip) then
                                RemoveBlip(blip)
                            end
                        end
                        
                        return
                    end
                
                    local dealDetails = nil
                    
                    local pedDealId = PedDealMap[dealerPed] or dealId
                    
                    print("^4Looking for deal with E-Key. Ped Deal ID: " .. tostring(pedDealId) .. "^7")
                    
                    if pedDealId and DealerDeals and DealerDeals[pedDealId] then
                        dealDetails = DealerDeals[pedDealId]
                        print("^2E-Key: Found deal in DealerDeals with ID: " .. pedDealId .. "^7")
                    
                    elseif Entity then
                        local state = Entity(dealerPed).state
                        if state and state.dealDetails then
                            dealDetails = state.dealDetails
                            print("^2E-Key: Found deal in entity state^7")
                        end
                    
                    elseif _G.CurrentDealInfo then
                        dealDetails = {
                            dealId = pedDealId or "global_deal",
                            drugName = _G.CurrentDealInfo.drugName,
                            quantity = _G.CurrentDealInfo.quantity,
                            price = _G.CurrentDealInfo.price
                        }
                        print("^2E-Key: Using global CurrentDealInfo^7")
                    
                    elseif ActiveDeal then
                        dealDetails = {
                            dealId = pedDealId or "active_deal",
                            drugName = ActiveDeal.drugName,
                            quantity = ActiveDeal.quantity,
                            price = ActiveDeal.price
                        }
                        print("^2E-Key: Using ActiveDeal as fallback^7")
                    end
                    
                    if dealDetails then
                        print("^3E-Key interaction with details - Drug: " .. dealDetails.drugName .. 
                              ", Quantity: " .. tostring(dealDetails.quantity) .. 
                              ", Price: $" .. tostring(dealDetails.price) .. "^7")
                    else
                        print("^1E-Key: No deal details found! Creating default deal.^7")
                        
                        dealDetails = {
                            dealId = pedDealId or "default_deal",
                            drugName = "weed_baggy",
                            quantity = 1,
                            price = 200
                        }
                    end
                    
                    dealCompleted = HandleDrugDeal(dealerPed, pedDealId, dealDetails)
                    
                    if dealCompleted then
                        if blip and DoesBlipExist(blip) then
                            RemoveBlip(blip)
                        end
                    end
                end
            end
            
            if distance > 100.0 then
                interactionActive = false
            end
            
            if dealCompleted then
                interactionActive = false
            end
        end
    end)
end

function HandleDrugDeal(dealerPed, dealId, dealDetails)
    if ActiveDeal and ActiveDeal.drugName and ActiveDeal.quantity and ActiveDeal.price then
        print("^4CRITICAL - Using ActiveDeal as highest priority source^7")
        print("^4ActiveDeal contains: " .. ActiveDeal.drugName .. 
              " x" .. ActiveDeal.quantity .. 
              " for $" .. ActiveDeal.price .. "^7")
        
        local exactDealDetails = {
            dealId = dealId or "active_deal",
            drugName = ActiveDeal.drugName,
            quantity = tonumber(ActiveDeal.quantity),
            price = tonumber(ActiveDeal.price)
        }
        
        print("^4CRITICAL - Using exact ActiveDeal details: " .. 
              exactDealDetails.drugName .. " x" .. 
              exactDealDetails.quantity .. " for $" .. 
              exactDealDetails.price .. "^7")
        
        local drugName = exactDealDetails.drugName
        local quantity = exactDealDetails.quantity
        local price = exactDealDetails.price
        
        print("^3FINAL DEAL VALUES BEFORE CALLBACK - Drug: " .. drugName .. 
              ", Quantity: " .. tostring(quantity) .. 
              ", Price: $" .. tostring(price) .. "^7")
        
        if Config.Framework == 'qb' then
            QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
                HandleDrugDealResponse(hasItem, dealerPed, dealId, drugName, quantity, price, blip)
            end, drugName, quantity)
        elseif Config.Framework == 'esx' then
            ESX.TriggerServerCallback('QBCore:HasItem', function(hasItem)
                HandleDrugDealResponse(hasItem, dealerPed, dealId, drugName, quantity, price, blip)
            end, drugName, quantity)
        end
        
        return true
    end

    print("^2HandleDrugDeal called with dealId: " .. tostring(dealId) .. "^7")
    if dealDetails then
        print("^2Received dealDetails directly - drug: " .. tostring(dealDetails.drugName) .. 
              ", quantity: " .. tostring(dealDetails.quantity) .. 
              ", price: " .. tostring(dealDetails.price) .. "^7")
    else
        print("^1NO DEAL DETAILS RECEIVED DIRECTLY^7")
    end
    
    local finalDealDetails = nil
    
    if dealDetails and dealDetails.drugName and dealDetails.quantity and dealDetails.price then
        finalDealDetails = dealDetails
        print("^2Using directly provided dealDetails^7")
    
    elseif dealId and DealerDeals and DealerDeals[dealId] then
        finalDealDetails = DealerDeals[dealId]
        print("^2Using DealerDeals[" .. dealId .. "]^7")
    
    elseif Entity and DoesEntityExist(dealerPed) then
        local state = Entity(dealerPed).state
        if state and state.dealDetails then
            finalDealDetails = state.dealDetails
            print("^2Using Entity state dealDetails^7")
        end
    
    elseif _G.CurrentDealInfo then
        finalDealDetails = {
            drugName = _G.CurrentDealInfo.drugName,
            quantity = _G.CurrentDealInfo.quantity,
            price = _G.CurrentDealInfo.price
        }
        print("^2Using global CurrentDealInfo^7")
    
    elseif ActiveDeal then
        finalDealDetails = {
            drugName = ActiveDeal.drugName,
            quantity = ActiveDeal.quantity,
            price = ActiveDeal.price
        }
        print("^2Using ActiveDeal as fallback^7")
    end
    
    if not finalDealDetails then
        if Config.Framework == 'qb' then
            QBCore.Functions.Notify('No active deal to complete', 'error')
        elseif Config.Framework == 'esx' then
            ESX.ShowNotification('No active deal to complete')
        end
        return false
    end
    
    local drugName = finalDealDetails.drugName or "weed_baggy"
    local quantity = tonumber(finalDealDetails.quantity) or 1
    local price = tonumber(finalDealDetails.price) or 200
    
    print("^3FINAL DEAL VALUES BEFORE CALLBACK - Drug: " .. drugName .. 
          ", Quantity: " .. tostring(quantity) .. 
          ", Price: $" .. tostring(price) .. "^7")
    
    if Config.Framework == 'qb' then
        QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
            HandleDrugDealResponse(hasItem, dealerPed, dealId, drugName, quantity, price, blip)
        end, drugName, quantity)
    elseif Config.Framework == 'esx' then
        ESX.TriggerServerCallback('QBCore:HasItem', function(hasItem)
            HandleDrugDealResponse(hasItem, dealerPed, dealId, drugName, quantity, price, blip)
        end, drugName, quantity)
    end
    
    return true
end

function HandleDrugDealResponse(hasItem, dealerPed, dealId, drugName, quantity, price, blip)
    if hasItem then
        local playerPed = PlayerPedId()
        
        RequestAnimDict("mp_common")
        while not HasAnimDictLoaded("mp_common") do
            Wait(10)
        end
        
        TaskTurnPedToFaceEntity(dealerPed, playerPed, 1000)
        Wait(1000)
        
        ClearPedTasks(dealerPed)
        
        TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, 2000, 0, 0, false, false, false)
        
        TaskPlayAnim(dealerPed, "mp_common", "givetake1_b", 8.0, -8.0, 2000, 0, 0, false, false, false)
        
        Wait(2000)
        
        local dealData = {
            dealId = dealId,
            drugName = drugName,
            quantity = quantity,
            price = price
        }
        
        TriggerServerEvent('trap_phone:completeDeal', dealId, dealData)
        
        if Config.Framework == 'qb' then
            QBCore.Functions.Notify('Deal completed successfully. You received $' .. price .. ' for ' .. quantity .. 'x ' .. drugName, 'success')
        elseif Config.Framework == 'esx' then
            ESX.ShowNotification('Deal completed successfully. You received $' .. price .. ' for ' .. quantity .. 'x ' .. drugName)
        end
        
        ActiveDeal = nil
        _G.CurrentDealInfo = nil
        CurrentMeetLocation = nil
        
        ClearPedTasksImmediately(dealerPed)
        TaskWanderStandard(dealerPed, 10.0, 10)
        
        Citizen.SetTimeout(15000, function()
            if DoesEntityExist(dealerPed) then
                PedDealMap[dealerPed] = nil
                DeleteEntity(dealerPed)
            end
        end)
        
        if DealerDeals[dealId] then
            DealerDeals[dealId] = nil
        end
        
        return true
    else
        if Config.Framework == 'qb' then
            QBCore.Functions.Notify('You don\'t have ' .. quantity .. 'x ' .. drugName, 'error')
        elseif Config.Framework == 'esx' then
            ESX.ShowNotification('You don\'t have ' .. quantity .. 'x ' .. drugName)
        end
        return false
    end
end

function CleanupAllDealerPeds()
    for _, ped in ipairs(DealerPeds) do
        if DoesEntityExist(ped) then
            PedDealMap[ped] = nil
            DeleteEntity(ped)
        end
    end
    DealerPeds = {}
    
    DealerDeals = {}
    
    PedDealMap = {}
    
    _G.CurrentDealInfo = nil
    CurrentMeetLocation = nil
end

function AlertPolice()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    TriggerServerEvent('police:server:policeAlert', 'Suspicious Phone Activity', playerCoords)
    
    if Config.Framework == 'qb' then
        QBCore.Functions.Notify('Someone might have reported suspicious activity', 'error')
    elseif Config.Framework == 'esx' then
        ESX.ShowNotification('Someone might have reported suspicious activity')
    end
end

RegisterNetEvent('drug_selling:client:createDealerNPC')
AddEventHandler('drug_selling:client:createDealerNPC', function(data)
    print("^2Trap Phone: External createDealerNPC event triggered for " .. data.dealId .. "^7")
end)
