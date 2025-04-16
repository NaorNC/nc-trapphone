# nc-trapphone

A comprehensive and immersive burner phone system for drug dealing in QBCore Framework with realistic messaging, dynamic pricing, and NPC deal locations.
- For support and more resources, join our Discord - [Discord.gg/NCHub](https://discord.gg/NCHub)
## Preview & Support
Youtube Video Showcase - [Click Me](https://www.youtube.com/watch?v=nR1-rCSCgdk)

![NCHub Trap Phone   Drug Selling](https://github.com/user-attachments/assets/100b8e3b-7ead-4980-8c44-471ea41a3929)

## Features

- **Interactive Phone Interface**: Fully functional trap phone UI with messaging system
- **Dynamic Contact System**: Request new contacts for deals with cooldown timers
- **Counter-Offer Mechanics**: Negotiate prices with contacts based on relationship
- **Location-Based Deals**: Meet dealers at random locations throughout the map
- **NPC Dealer Generation**: Realistic dealer NPCs spawn at meeting locations
- **Inventory Integration**: Full item management with drug quantities and prices
- **Police Alert System**: Configurable chance of police notification
- **Relationship System**: Build rapport with recurring contacts for better deals
- **Multiple Interaction Methods**: Support for both qb-target and traditional E-key interactions

## Dependencies

- QBCore Framework
- qb-target (optional, for enhanced interactions)

## Optional Integrations

- Various police dispatch systems
- Custom inventory systems

## Installation

1. Download or clone this repository
2. Place the resource in your server's `resources` folder
3. Add `ensure nc-trapphone` to your server.cfg
4. Add the trap phone item to your items.lua (see below for instructions)
5. Configure settings in `config.lua` to match your server's economy
6. Restart your server

## Item Installation

### Adding the Trap Phone Item

#### For Older QBCore (items.lua):
```lua
['trapphone'] = {
    ['name'] = 'trapphone',
    ['label'] = 'Trap Phone',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'trap_phone.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'A burner phone used for illegal business'
},
```

#### For Newer QBCore (shared/items.lua):
```lua
['trapphone'] = {
    name = 'trapphone',
    label = 'Trap Phone',
    weight = 500,
    type = 'item',
    image = 'trap_phone.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A burner phone used for illegal business'
},
```

### Adding Drug Items (if needed)

#### For Older QBCore (items.lua):
```lua
['weed_baggy'] = {
    ['name'] = 'weed_baggy',
    ['label'] = 'Weed Baggy',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'weed_baggy.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Small bag of weed'
},
['coke_baggy'] = {
    ['name'] = 'coke_baggy',
    ['label'] = 'Cocaine Baggy',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'coke_baggy.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Small bag of cocaine'
},
['meth_baggy'] = {
    ['name'] = 'meth_baggy',
    ['label'] = 'Meth Baggy',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'meth_baggy.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Small bag of meth'
},
['mega_death'] = {
    ['name'] = 'mega_death',
    ['label'] = 'Mega Death',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'mega_death.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'High-value custom drug'
},
```

#### For Newer QBCore (shared/items.lua):
```lua
['weed_baggy'] = {
    name = 'weed_baggy',
    label = 'Weed Baggy',
    weight = 200,
    type = 'item',
    image = 'weed_baggy.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Small bag of weed'
},
['coke_baggy'] = {
    name = 'coke_baggy',
    label = 'Cocaine Baggy',
    weight = 200,
    type = 'item',
    image = 'coke_baggy.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Small bag of cocaine'
},
['meth_baggy'] = {
    name = 'meth_baggy',
    label = 'Meth Baggy',
    weight = 200,
    type = 'item',
    image = 'meth_baggy.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Small bag of meth'
},
['mega_death'] = {
    name = 'mega_death',
    label = 'Mega Death',
    weight = 200,
    type = 'item',
    image = 'mega_death.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'High-value custom drug'
},
```

## Configuration Options

The `config.lua` file provides extensive customization options:

```lua
Config = {
    TrapPhoneItem = 'trapphone',        -- Item name for the trap phone
    UseQBTarget = true,                 -- Use QB-Target instead of E key
    ContactCooldown = 2,                -- Minutes between requesting new contacts
    PoliceSettings = {
        minimumPolice = 0,              -- Minimum police required for functionality
        alertChance = 10                -- Chance (0-100) that police will be alerted
    },
    MeetLocations = {                   -- Configurable meeting locations
        { name = "Vinewood Hills", coords = vector3(-1530.32, 142.43, 55.65) },
        { name = "Downtown", coords = vector3(219.72, -805.97, 30.39) },
        -- And many more locations
    },
    TrapPhoneDrugs = {                  -- Configurable drug types with pricing
        {
            name = "weed_baggy",
            label = "Weed Baggy",
            streetName = "Green", 
            basePrice = 220,
            priceRange = {200, 240}
        },
        -- Additional drugs can be configured
    }
}
```

## Image Installation

Make sure to add the following images to your inventory resource:
- `trap_phone.png` - For the trap phone item
- `weed_baggy.png` - For weed baggies (if not already present)
- `coke_baggy.png` - For cocaine baggies (if not already present)
- `meth_baggy.png` - For meth baggies (if not already present)
- `mega_death.png` - For the custom Mega Death drug

## Usage

1. Obtain a trap phone item through your server's economy
2. Use the trap phone from your inventory to open the interface
3. Request a new contact and wait for them to message you
4. Negotiate drug prices using the counter-offer system
5. Agree on a meeting location with your contact
6. Travel to the marked location on your map
7. Interact with the dealer NPC to complete the transaction
8. Be careful - deals may alert police based on your configuration settings!

## Admin Commands

- `/givetrapphone [id]` - Admin command to give a trap phone to a specific player ID

## Customization

- Modify contacts, prices, and locations in the config.lua file
- Adjust the police notification settings based on your server's needs
- Customize the UI appearance through the CSS files
