function CalculateOfferSuccessChance(price, fairPrice, relationship)
    local priceDifference = (price - fairPrice) / fairPrice
    
    local baseChance = relationship or 50
    
    local finalChance = baseChance
    
    if priceDifference <= -0.2 then
        finalChance = finalChance * 1.5
    elseif priceDifference <= -0.1 then
        finalChance = finalChance * 1.3
    elseif priceDifference <= 0 then
        finalChance = finalChance * 1.1
    elseif priceDifference <= 0.1 then
        finalChance = finalChance * 0.9
    elseif priceDifference <= 0.2 then
        finalChance = finalChance * 0.7
    else
        finalChance = finalChance * 0.5
    end
    
    return math.min(95, math.max(5, finalChance))
end

function UpdateRelationship(contactId, changeAmount)
    if not ActiveContact or ActiveContact.id ~= contactId then
        return false
    end
    
    local newRelationship = ActiveContact.relationship + changeAmount
    newRelationship = math.min(100, math.max(0, newRelationship))
    
    ActiveContact.relationship = newRelationship
    
    return true
end

function GenerateRandomPrice(drugName, relationship)
    for _, drug in pairs(Config.TrapPhoneDrugs) do
        if drug.name == drugName then
            local minPrice = drug.priceRange[1]
            local maxPrice = drug.priceRange[2]
            
            local relationshipFactor = relationship / 100
            local adjustedMin = minPrice * (1 - (relationshipFactor * 0.1))
            local adjustedMax = maxPrice * (1 - (relationshipFactor * 0.1))
            
            return math.floor(adjustedMin + math.random() * (adjustedMax - adjustedMin))
        end
    end
    
    return 100
end

function HasEnoughPolice()
    local minPolice = Config.PoliceSettings.minimumPolice
    
    if minPolice <= 0 then
        return true
    end
    
    local policeCount = 0
    local players = QBCore.Functions.GetQBPlayers()
    
    for _, player in pairs(players) do
        if player.PlayerData.job.name == "police" and player.PlayerData.job.onduty then
            policeCount = policeCount + 1
        end
    end
    
    return policeCount >= minPolice
end

RegisterNetEvent('trap_phone:client:setupDealZone')
AddEventHandler('trap_phone:client:setupDealZone', function(data)
    TriggerEvent('drug_selling:client:attemptDeal', data.entity)
end)