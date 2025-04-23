Config = {}

Config.Framework = 'qb' -- 'qb' for QBCore, 'esx' for ESX

Config.TrapPhoneItem = 'trapphone'

Config.UseQBTarget = true -- Use QB-Target (QBCore only)
Config.UseOxTarget = false -- Use ox_target (Works with both QBCore and ESX)

Config.Phone = {
    DefaultX = 70,    -- % from right edge of screen
    DefaultY = 70,    -- % from bottom of screen
    DefaultScale = 0.8 -- Scale of phone UI (0.8 = 80% of original size)
}

Config.ContactCooldown = 2 -- 2 minutes between requesting new contacts

Config.Contacts = {
    {
        name = "Kevin Oakley",
        avatar = "👨",
        avatarColor = "#9C6E3C",
        verified = true, -- Has checkmark
        initialMessage = "Hey, I could use some Mega Death. Got any? I'll pay."
    },
    {
        name = "Eugene Buckley",
        avatar = "👴",
        avatarColor = "#9E9E9E",
        verified = true,
        initialMessage = "Need something special for a party tonight. What you got?"
    },
    {
        name = "Charles Rowland",
        avatar = "👨‍🦳", 
        avatarColor = "#E0E0E0",
        verified = true,
        initialMessage = "My usual guy is out. Can you hook me up with something good?"
    },
    {
        name = "Greg Thompson",
        avatar = "🧔",
        avatarColor = "#BDBDBD",
        verified = true,
        initialMessage = "I heard you might have some product. Looking to buy."
    },
    {
        name = "Ken Walsh",
        avatar = "👨‍🦱",
        avatarColor = "#A1887F",
        verified = false,
        initialMessage = "Friend gave me your contact. Looking for some party favors."
    },
    {
        name = "Peter Santiago",
        avatar = "👦",
        avatarColor = "#90CAF9",
        verified = false,
        initialMessage = "Yo, someone said you could help me out with some stuff?"
    },
    {
        name = "Elizabeth Chen",
        avatar = "👩",
        avatarColor = "#81D4FA",
        verified = false,
        initialMessage = "Need some product for me and my friends this weekend."
    },
    {
        name = "Michael Davis",
        avatar = "👨‍🦰",
        avatarColor = "#FF5722",
        verified = false,
        initialMessage = "Hey, heard you're the one to talk to about some recreational goods?"
    },
    {
        name = "Sarah Johnson",
        avatar = "👩‍🦱",
        avatarColor = "#E91E63",
        verified = true,
        initialMessage = "I'm organizing a beach party. Need supplies. You available?"
    },
    {
        name = "Tyrone Jackson",
        avatar = "🧔‍♂️",
        avatarColor = "#8BC34A",
        verified = true,
        initialMessage = "My connect got busted. Need a new supplier. Heard good things."
    },
    {
        name = "Jennifer Lopez",
        avatar = "💃",
        avatarColor = "#9C27B0",
        verified = false,
        initialMessage = "Friend from downtown said you might have what I need for this weekend."
    },
    {
        name = "David Kim",
        avatar = "🧑‍🎓",
        avatarColor = "#2196F3",
        verified = false,
        initialMessage = "College party coming up. Looking to make it memorable. You got goods?"
    },
    {
        name = "Marcus Reed",
        avatar = "🕴️",
        avatarColor = "#607D8B",
        verified = true,
        initialMessage = "Business professional looking for something to help with stress. Discreet."
    },
    {
        name = "Liam Rodriguez",
        avatar = "🧑",
        avatarColor = "#795548",
        verified = false,
        initialMessage = "Looking for something to make this weekend interesting. You selling?"
    },
    {
        name = "Zoe Williams",
        avatar = "👱‍♀️",
        avatarColor = "#FFC107",
        verified = true,
        initialMessage = "VIP party at the club this weekend. Need premium stuff."
    }
}

Config.TrapPhoneDrugs = {
    {
        name = "weed_baggy",
        label = "Weed Baggy",
        streetName = "Green", 
        basePrice = 220,
        priceRange = {200, 240}
    },
    {
        name = "coke_baggy",
        label = "Cocaine Baggy", 
        streetName = "Snow",
        basePrice = 550,
        priceRange = {500, 600}
    },
    {
        name = "meth_baggy",
        label = "Meth Baggy",
        streetName = "Ice",
        basePrice = 380,
        priceRange = {350, 410}
    },
    {
        name = "mega_death",  
        label = "Mega Death", 
        streetName = "Mega Death",
        basePrice = 450,
        priceRange = {400, 500}
    }
}

Config.MeetLocations = {
    { name = "Sandy Shores", coords = vector3(1777.64, 3799.93, 33.65) },
    { name = "Paleto Bay", coords = vector3(-159.89, 6385.76, 31.47) },
    { name = "Vinewood Hills", coords = vector3(-1530.32, 142.43, 55.65) },
    { name = "Downtown", coords = vector3(219.72, -805.97, 30.39) },
    { name = "East Los Santos", coords = vector3(1122.25, -644.54, 56.81) },
    { name = "Mirror Park", coords = vector3(1124.05, -644.34, 56.81) },
    { name = "Chumash", coords = vector3(-3175.41, 1087.95, 20.84) },
    { name = "Harmony", coords = vector3(593.0, 2744.4, 41.9) },
    { name = "La Mesa", coords = vector3(845.52, -1162.56, 25.28) },
    { name = "Vespucci Beach", coords = vector3(-1348.63, -1236.19, 4.57) },
    { name = "Rockford Hills", coords = vector3(-816.84, -191.68, 37.62) },
    { name = "Grapeseed", coords = vector3(1701.24, 4921.91, 42.06) },
    { name = "Del Perro Pier", coords = vector3(-1589.01, -1042.63, 13.02) },
    { name = "Senora Desert", coords = vector3(2352.14, 3133.23, 48.21) },
    { name = "Pacific Bluffs", coords = vector3(-2022.67, -465.03, 11.46) },
    { name = "Davis", coords = vector3(88.33, -1924.33, 20.79) },
    { name = "Legion Square", coords = vector3(195.17, -934.0, 30.69) },
    { name = "Little Seoul", coords = vector3(-679.55, -878.31, 24.48) },
    { name = "El Burro Heights", coords = vector3(1384.05, -2079.77, 52.23) },
    { name = "Cypress Flats", coords = vector3(817.14, -2135.99, 29.36) },
    { name = "Observatory", coords = vector3(-402.09, 1196.38, 325.64) },
    { name = "Mount Chiliad", coords = vector3(450.04, 5566.86, 796.68) },
    { name = "Tongva Hills", coords = vector3(-1866.3, 2062.58, 135.43) }
}

Config.ResponseOptions = {
    initial = {
        {text = "Deal", value = "deal", nextState = "deal_accepted"},
        {text = "[Counter-offer]", value = "counter", nextState = "counter_offer"},
        {text = "Not right now", value = "reject", nextState = "deal_rejected"}
    },
    deal_accepted = {
        {text = "Send me the location", value = "location", nextState = "meet_location"},
        {text = "I'll be in touch", value = "no_response", nextState = "no_response"}
    },
    deal_rejected = {
        {text = "Maybe another time", value = "another_time", nextState = "closed"},
        {text = "I don't sell that stuff", value = "dont_sell", nextState = "closed"}
    }
}

Config.NPCResponses = {
    deal_accepted = {
        "Great! I'll set everything up.",
        "Perfect! Let me know where to meet.",
        "Excellent. Let me know where and when.",
        "Nice! I'm ready when you are.",
        "That's what I'm talking about. Just need the meeting spot.",
        "Awesome, got the cash ready. Where should we meet?",
        "Sounds good to me. Just tell me when and where."
    },
    counter_accepted = {
        "Deal. That works for me.",
        "Alright, I can do that price.",
        "Fine by me, we have a deal.",
        "That'll work. See you soon.",
        "I can live with that price. Let's do it.",
        "That's fair enough. I'll take it.",
        "You drive a hard bargain, but it's a deal."
    },
    counter_rejected = {
        "Sorry, that's too expensive for me.",
        "I can't go that high. Maybe next time.",
        "That's way more than I can afford.",
        "No thanks, I'll find someone else.",
        "You're crazy with those prices. No way.",
        "That's a ripoff. I'll pass.",
        "Too rich for my blood. I'll look elsewhere."
    },
    meet_location = {
        "Meet me at %s in 30 minutes. Don't be late.",
        "I'll be waiting at %s. Come alone.",
        "Let's meet at %s. Be discreet.",
        "I'll see you at %s. Make sure you're not followed.",
        "I'm heading to %s now. Don't bring any heat.",
        "Look for me at %s. I'll be smoking a cigarette.",
        "Come to %s. Park away from cameras.",
        "I'll be at %s. No phones, no cops, no problems.",
        "Meet me behind the building at %s. Be careful."
    },
    no_response = {
        "Don't take too long or I'll find someone else.",
        "Alright, let me know soon.",
        "Don't keep me waiting.",
        "Fine, but don't ghost me.",
        "I've got other buyers waiting, so hurry up.",
        "I won't hold this deal forever.",
        "My schedule's tight. Don't waste my time."
    },
    closed = {
        "Whatever man.",
        "Your loss.",
        "Fine by me.",
        "I'll find someone else.",
        "No skin off my back.",
        "Plenty of other buyers out there.",
        "Don't call this number again."
    }
}

Config.PoliceSettings = {
    minimumPolice = 0,  
    alertChance = 10    
}
