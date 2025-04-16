local Translations = {
    notify = {
        ['no_drugs'] = 'You don\'t have any drugs to sell',
        ['deal_success'] = 'Deal successful!',
        ['deal_failed'] = 'Deal failed',
        ['police_called'] = 'Someone is calling the police!',
        ['npc_hostile'] = 'The NPC became hostile!',
        ['drugs_added'] = 'Drugs added to inventory',
        ['not_admin'] = 'You are not an admin',
    },
    info = {
        ['offer_drugs'] = 'Offer Drugs',
        ['place_product'] = 'Place product here',
        ['asking_price'] = 'Asking Price',
        ['fair_price'] = 'Fair price',
        ['success_chance'] = 'Chance of success',
        ['make_deal'] = 'DONE',
        ['relationship'] = 'Relationship',
        ['addiction'] = 'Addiction',
        ['standards'] = 'Standards',
        ['favourite_effects'] = 'Favourite Effects',
    },
    commands = {
        ['toggle_dealing'] = 'Toggle drug dealing mode',
        ['get_drugs'] = 'Get drugs for testing (Admin Only)',
    },
    effects = {
        ['energizing'] = 'Energizing',
        ['paranoia'] = 'Paranoia',
        ['sneaky'] = 'Sneaky',
    },
    npc_types = {
        ['addict'] = 'Addict',
        ['party'] = 'Party Goer',
        ['casual'] = 'Casual User',
        ['straight'] = 'Straight Edge',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})