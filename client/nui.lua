local QBCore, ESX = nil, nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

function GetCurrentTimeFormatted()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    
    if hours < 10 then hours = "0" .. hours end
    if minutes < 10 then minutes = "0" .. minutes end
    
    return hours .. ":" .. minutes
end

RegisterNUICallback('closePhone', function(data, cb)
    CloseTrapPhone()
    cb({status = "success"})
end)

RegisterNUICallback('requestNewContact', function(data, cb)
    local newContact = CreateNewContact()
    
    if newContact then
        cb({
            status = "success",
            contact = newContact
        })
    else
        cb({
            status = "error",
            message = "Failed to create new contact"
        })
    end
end)

RegisterNUICallback('showNotification', function(data, cb)
    if Config.Framework == 'qb' then
        QBCore.Functions.Notify(data.message, data.type)
    elseif Config.Framework == 'esx' then
        ESX.ShowNotification(data.message)
    else
        TriggerEvent('trap_phone:showNotification', data.message, data.type)
    end
    cb({status = "success"})
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    if CurrentMeetLocation then
        print("^3A meeting location is already set. Updating deal info only.^7")
        
        local drugName = data.drugItemName or data.drugName
        local quantity = tonumber(data.quantity) or 1
        local price = tonumber(data.price) or 200
        
        if ActiveDeal then
            ActiveDeal.drugName = drugName
            ActiveDeal.quantity = quantity
            ActiveDeal.price = price
            
            _G.CurrentDealInfo = {
                drugName = drugName,
                quantity = quantity,
                price = price,
                timestamp = GetGameTimer()
            }
            
            print("^2Updated ActiveDeal without new location: " .. 
                  ActiveDeal.drugName .. " x" .. 
                  ActiveDeal.quantity .. " for $" .. 
                  ActiveDeal.price .. "^7")
                  
            TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
        end
        
        cb({status = "success", message = "Deal details updated, using existing meeting location"})
        return
    end
    
    local drugName = data.drugItemName or data.drugName
    local quantity = tonumber(data.quantity) or 1
    local price = tonumber(data.price) or 200
    
    print("^3SetWaypoint: Drug=" .. tostring(drugName) .. 
          ", Quantity=" .. tostring(quantity) .. 
          ", Price=" .. tostring(price) .. "^7")
    
    ActiveDeal = {
        drugName = drugName or "weed_baggy",
        quantity = quantity,
        price = price,
        contactName = ActiveContact and ActiveContact.name or "Unknown"
    }
    
    _G.CurrentDealInfo = {
        drugName = drugName or "weed_baggy",
        quantity = quantity,
        price = price,
        timestamp = GetGameTimer()
    }
    
    print("^2Created/Updated ActiveDeal with: " .. 
          ActiveDeal.drugName .. " x" .. 
          ActiveDeal.quantity .. " for $" .. 
          ActiveDeal.price .. "^7")
    
    TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
    
    local success = ProcessDealLocation()
    
    cb({status = "success", message = "Waypoint set"})
end)

RegisterNUICallback('sendMessage', function(data, cb)
    if not ActiveContact then
        cb({
            status = "error", 
            message = "No active contact"
        })
        return
    end
    
    local originalMessageCount = #ActiveContact.messages
    
    print("^3Before adding player message - Message count: " .. originalMessageCount .. "^7")
    
    table.insert(ActiveContact.messages, {
        sender = "me",
        text = data.message,
        time = GetCurrentTimeFormatted()
    })
    
    local responseState = data.nextState
    local responseOptions = Config.NPCResponses[responseState]
    
    local drugName = data.drugName
    local drugItemName = data.drugItemName
    local quantity = tonumber(data.quantity) or 1
    local price = tonumber(data.price) or 200
    
    local skipLocationRequest = data.skipLocationRequest
    
    if responseState == "deal_accepted" or responseState == "meet_location" or responseState == "ready_to_meet" then
        if not ActiveDeal then
            print("^2Creating new ActiveDeal for state: " .. responseState .. "^7")
            
            ActiveDeal = {
                drugName = drugItemName or drugName or "weed_baggy",
                quantity = quantity,
                price = price,
                contactName = ActiveContact.name
            }
            
            _G.CurrentDealInfo = {
                drugName = drugItemName or drugName or "weed_baggy",
                quantity = quantity,
                price = price,
                timestamp = GetGameTimer()
            }
            
            TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
        else
            print("^2Using existing ActiveDeal for state: " .. responseState .. "^7")
            if drugItemName then ActiveDeal.drugName = drugItemName 
            elseif drugName then ActiveDeal.drugName = drugName end
            if quantity then ActiveDeal.quantity = quantity end
            if price then ActiveDeal.price = price end
            
            _G.CurrentDealInfo = {
                drugName = ActiveDeal.drugName,
                quantity = ActiveDeal.quantity,
                price = ActiveDeal.price,
                timestamp = GetGameTimer()
            }
        end
    end
    
    if responseState == "meet_location" then
        if not ActiveDeal then
            print("^1Warning: No ActiveDeal before meet_location - creating default^7")
            ActiveDeal = {
                drugName = drugItemName or drugName or "weed_baggy",
                quantity = quantity, 
                price = price,
                contactName = ActiveContact.name
            }
            
            _G.CurrentDealInfo = {
                drugName = drugItemName or drugName or "weed_baggy",
                quantity = quantity,
                price = price,
                timestamp = GetGameTimer()
            }
            
            TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
        end
        
        if not CurrentMeetLocation and not skipLocationRequest then
            ProcessDealLocation()
        else
            print("^3Meeting location already exists or skip request received - not creating new location^7")
            _G.CurrentDealInfo = {
                drugName = ActiveDeal.drugName,
                quantity = ActiveDeal.quantity,
                price = ActiveDeal.price,
                timestamp = GetGameTimer()
            }
            
            TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
        end
        
        cb({
            status = "success",
            messages = ActiveContact.messages,
            preserveChat = true
        })
        return
    end
    
    if responseState == "ready_to_meet" then
        local readyText = "Great, I'm ready too. Let me send you the location."
        table.insert(ActiveContact.messages, {
            sender = "them",
            text = readyText,
            time = GetCurrentTimeFormatted()
        })
        
        if not ActiveDeal then
            print("^1Warning: No ActiveDeal before ready_to_meet - creating default^7")
            ActiveDeal = {
                drugName = drugItemName or drugName or "weed_baggy",
                quantity = quantity,
                price = price,
                contactName = ActiveContact.name
            }
            
            _G.CurrentDealInfo = {
                drugName = drugItemName or drugName or "weed_baggy",
                quantity = quantity,
                price = price,
                timestamp = GetGameTimer()
            }
            
            TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
        end
        
        if not CurrentMeetLocation and not skipLocationRequest then
            Citizen.SetTimeout(800, function()
                ProcessDealLocation()
                
                SendNUIMessage({
                    action = "updateMessages",
                    messages = ActiveContact.messages,
                    preserveChat = true
                })
            end)
        else
            print("^3Not setting new location - already exists or skip requested^7")
            _G.CurrentDealInfo = {
                drugName = ActiveDeal.drugName,
                quantity = ActiveDeal.quantity,
                price = ActiveDeal.price,
                timestamp = GetGameTimer()
            }
        end
    end
    
    print("^3After sendMessage processing - Message count: " .. #ActiveContact.messages .. "^7")
    
    if responseOptions and responseState ~= "meet_location" then
        local responseText = responseOptions[math.random(#responseOptions)]
        
        Citizen.SetTimeout(800, function()
            table.insert(ActiveContact.messages, {
                sender = "them",
                text = responseText,
                time = GetCurrentTimeFormatted()
            })
            
            if responseState == "deal_accepted" then
                Citizen.SetTimeout(800, function()
                    local followUpMessage = "Where and when should we meet?"
                    
                    table.insert(ActiveContact.messages, {
                        sender = "them",
                        text = followUpMessage,
                        time = GetCurrentTimeFormatted()
                    })
                    
                    SendNUIMessage({
                        action = "updateMessages",
                        messages = ActiveContact.messages,
                        preserveChat = true
                    })
                    
                    print("^3After follow-up message - Message count: " .. #ActiveContact.messages .. "^7")
                end)
            else
                SendNUIMessage({
                    action = "updateMessages",
                    messages = ActiveContact.messages,
                    preserveChat = true
                })
                
                print("^3After response message - Message count: " .. #ActiveContact.messages .. "^7")
            end
        end)
    end
    
    cb({
        status = "success",
        messages = ActiveContact.messages,
        preserveChat = true
    })
end)

RegisterNUICallback('sendCounterOffer', function(data, cb)
    if not ActiveContact then
        cb({
            status = "error", 
            message = "No active contact"
        })
        return
    end
    
    print("^3Before counter offer - Messages count: " .. #ActiveContact.messages .. "^7")
    
    local drugName = data.drugName
    local drugItemName = data.drugItemName
    local quantity = tonumber(data.quantity) or 1
    local price = tonumber(data.price) or 200
    local fairPrice = data.fairPrice
    local successChance = data.successChance
    
    print("^4COUNTER OFFER DATA - Drug Label: " .. drugName .. 
          ", Item Name: " .. (drugItemName or "unknown") .. 
          ", Quantity: " .. quantity .. 
          ", Price: " .. price .. "^7")
    
    local counterMessage = "I can give you " .. quantity .. "x " .. 
        drugName .. " for $" .. price .. ". Deal?"
    
    table.insert(ActiveContact.messages, {
        sender = "me",
        text = counterMessage,
        time = GetCurrentTimeFormatted()
    })
    
    local roll = math.random(100)
    local accepted = roll <= successChance
    
    local responseOptions = nil
    if accepted then
        responseOptions = Config.NPCResponses.counter_accepted
    else
        responseOptions = Config.NPCResponses.counter_rejected
    end
    
    local responseText = responseOptions[math.random(#responseOptions)]
    
    local actualDrugName = drugItemName
    
    if not actualDrugName then
        for _, drug in pairs(Config.TrapPhoneDrugs) do
            if drug.label == drugName then
                actualDrugName = drug.name
                break
            end
        end
    end
    
    if not actualDrugName then
        if #Config.TrapPhoneDrugs > 0 then
            actualDrugName = Config.TrapPhoneDrugs[1].name
        else
            actualDrugName = "weed_baggy"
        end
    end
    
    ActiveDeal = {
        drugName = actualDrugName,
        quantity = quantity,
        price = price,
        contactName = ActiveContact.name,
        accepted = accepted
    }
    
    _G.CurrentDealInfo = {
        drugName = actualDrugName,
        quantity = quantity, 
        price = price,
        accepted = accepted,
        timestamp = GetGameTimer()
    }
    
    print("^4COUNTER OFFER - Global deal info updated [" .. GetGameTimer() .. "]: " .. actualDrugName .. 
          " x" .. quantity .. " for $" .. price .. 
          " (Accepted: " .. tostring(accepted) .. ")^7")
    
    cb({
        status = "success",
        messages = ActiveContact.messages,
        preserveChat = true
    })
    
    Citizen.SetTimeout(800, function()
        table.insert(ActiveContact.messages, {
            sender = "them",
            text = responseText,
            time = GetCurrentTimeFormatted()
        })
        
        SendNUIMessage({
            action = "updateMessages",
            messages = ActiveContact.messages,
            offerAccepted = accepted,
            preserveChat = true
        })
        
        print("^3After counter response - Messages count: " .. #ActiveContact.messages .. "^7")
        
        if accepted then
            TriggerServerEvent('trap_phone:registerTransaction', ActiveDeal)
            
            Citizen.SetTimeout(800, function()
                table.insert(ActiveContact.messages, {
                    sender = "them",
                    text = "So, where should we meet?",
                    time = GetCurrentTimeFormatted()
                })
                
                SendNUIMessage({
                    action = "updateMessages",
                    messages = ActiveContact.messages,
                    offerAccepted = true,
                    preserveChat = true
                })
                
                print("^3After follow-up message - Messages count: " .. #ActiveContact.messages .. "^7")
            end)
        end
    end)
end)

RegisterNUICallback('getPlayerDrugs', function(data, cb)
    local playerDrugs = GetPlayerDrugs()
    cb({
        status = "success",
        drugs = playerDrugs
    })
end)

RegisterNUICallback('deleteConversation', function(data, cb)
    ActiveContact = nil
    ActiveDeal = nil
    CurrentMeetLocation = nil
    _G.CurrentDealInfo = nil
    
    cb({
        status = "success",
        message = "Conversation deleted"
    })
end)

RegisterNUICallback('getActiveContact', function(data, cb)
    if ActiveContact then
        cb({
            status = "success",
            contact = ActiveContact
        })
    else
        cb({
            status = "error",
            message = "No active contact"
        })
    end
end)
