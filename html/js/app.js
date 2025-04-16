let activeContact = null;
let playerDrugs = [];
let selectedDrug = null;
let currentQuantity = 1;
let currentPrice = 200;
let fairPrice = 200;
let successChance = 75;
let messageHistory = [];
let contactsList = []; 
let counterOfferSent = false; 
let lastContactTime = 0; 
let conversationStates = {}; 
let hasActiveContact = false; 
let CurrentMeetLocation = null; 

function closeContactPopup() {
    const contactPopup = document.getElementById('contactPopup');
    const overlay = document.getElementById('overlay');
    if (contactPopup) contactPopup.classList.remove('show');
    if (overlay) overlay.classList.remove('show');
}

function showContactPopup() {
    const contactPopup = document.getElementById('contactPopup');
    const overlay = document.getElementById('overlay');
    if (contactPopup) contactPopup.classList.add('show');
    if (overlay) overlay.classList.add('show');
}

function closeCounterOfferPopup() {
    const overlay = document.getElementById('overlay');
    const counterOfferPopup = document.getElementById('counterOfferPopup');
    if (overlay) overlay.classList.remove('show');
    if (counterOfferPopup) counterOfferPopup.classList.remove('show');
}

function openCounterOfferPopup() {
    sendPostMessage('getPlayerDrugs', {}, function(response) {
        if (response && response.status === 'success') {
            playerDrugs = response.drugs;
            
            populateDrugSelector();
            
            resetCounterOffer();
            
            const overlay = document.getElementById('overlay');
            const counterOfferPopup = document.getElementById('counterOfferPopup');
            if (overlay) overlay.classList.add('show');
            if (counterOfferPopup) counterOfferPopup.classList.add('show');
        }
    });
}

function updateNotificationBadge() {
    const notificationBadge = document.querySelector('.notification-badge');
    if (notificationBadge) {
        const count = contactsList.length;
        notificationBadge.textContent = count > 0 ? count : '';
        notificationBadge.style.display = count > 0 ? 'flex' : 'none';
    }
}

function saveConversationState(contactId) {
    if (!activeContact || !contactId) return;
    
    conversationStates[contactId] = {
        messages: JSON.parse(JSON.stringify(activeContact.messages)), 
        responseState: activeContact.currentState || 'initial',
        counterOfferSent: counterOfferSent
    };
    
    console.log(`Saved conversation state for ${contactId} with ${activeContact.messages.length} messages`);
}

function loadConversationState(contactId) {
    if (!contactId || !conversationStates[contactId]) return false;
    
    const state = conversationStates[contactId];
    
    if (activeContact) {
        activeContact.messages = JSON.parse(JSON.stringify(state.messages));
        activeContact.currentState = state.responseState;
        counterOfferSent = state.counterOfferSent;
        
        console.log(`Loaded conversation state for ${contactId} with ${activeContact.messages.length} messages`);
        return true;
    }
    
    return false;
}

document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
    updateTime();
    setInterval(updateTime, 60000); 
    
    contactsList = [];
    updateNotificationBadge();
    
    counterOfferSent = false;
    lastContactTime = 0;
    
    conversationStates = {};
    
    hasActiveContact = false;
    
    CurrentMeetLocation = null;
});

function setupEventListeners() {
    const homeScreen = document.getElementById('homeScreen');
    const messagesScreen = document.getElementById('messagesScreen');
    const messagesApp = document.getElementById('messagesApp');
    const homeButton = document.getElementById('homeButton');
    const chatScreen = document.getElementById('chatScreen');
    const backToMessages = document.getElementById('backToMessages');
    const overlay = document.getElementById('overlay');
    const addContactBtn = document.getElementById('addContactBtn');
    const homeFromMessages = document.getElementById('homeFromMessages');
    
    const counterOfferBtn = document.getElementById('counterOfferBtn');
    const counterOfferPopup = document.getElementById('counterOfferPopup');
    const sendOfferBtn = document.getElementById('sendOfferBtn');
    const closeCounterOfferBtn = document.getElementById('closeCounterOffer');
    
    const contactPopup = document.getElementById('contactPopup');
    const confirmContactBtn = document.getElementById('confirmContact');
    const cancelContactBtn = document.getElementById('cancelContact');
    const closeContactPopupBtn = document.getElementById('closeContactPopup');
    
    const priceMinus100 = document.getElementById('price-sub-100');
    const priceMinus10 = document.getElementById('price-sub-10');
    const priceMinus1 = document.getElementById('price-sub-1');
    const pricePlus1 = document.getElementById('price-add-1');
    const pricePlus10 = document.getElementById('price-add-10');
    const pricePlus100 = document.getElementById('price-add-100');
    
    const quantityMinus = document.getElementById('quantityMinus');
    const quantityPlus = document.getElementById('quantityPlus');
    
    const drugSelector = document.getElementById('drugSelector');
    
    if (messagesApp) {
        messagesApp.addEventListener('click', function() {
            if (homeScreen) homeScreen.style.transform = 'translateX(-100%)';
            if (messagesScreen) messagesScreen.style.transform = 'translateX(0)';
        });
    }
    
    if (homeFromMessages) {
        homeFromMessages.addEventListener('click', function() {
            if (homeScreen) homeScreen.style.transform = 'translateX(0)';
            if (messagesScreen) messagesScreen.style.transform = 'translateX(100%)';
        });
    }
    
    if (homeButton) {
        homeButton.addEventListener('click', function(e) {
            e.preventDefault();
            if (homeScreen) homeScreen.style.transform = 'translateX(0)';
            if (messagesScreen) messagesScreen.style.transform = 'translateX(100%)';
            if (chatScreen) chatScreen.style.transform = 'translateX(100%)';
            
            closeCounterOfferPopup();
            closeContactPopup();
        });
    }
    
    if (backToMessages) {
        backToMessages.addEventListener('click', function() {
            if (activeContact) {
                saveConversationState(activeContact.id);
            }
            
            if (messagesScreen) messagesScreen.style.transform = 'translateX(0)';
            if (chatScreen) chatScreen.style.transform = 'translateX(100%)';
            closeCounterOfferPopup();
        });
    }
    
    if (addContactBtn) {
        addContactBtn.addEventListener('click', function() {
            if (hasActiveContact) {
                sendPostMessage('showNotification', {
                    message: "You already have an active contact. Finish your business first.",
                    type: 'error'
                });
                return;
            }
            
            const now = Date.now();
            const cooldownTime = 120000; 
            
            if (now - lastContactTime < cooldownTime) {
                const remainingTime = Math.ceil((cooldownTime - (now - lastContactTime)) / 1000 / 60);
                
                sendPostMessage('showNotification', {
                    message: `Please wait ${remainingTime} minute(s) before requesting a new contact.`,
                    type: 'error'
                });
                return;
            }
            
            showContactPopup();
        });
    }
    
    if (confirmContactBtn) {
        confirmContactBtn.addEventListener('click', function() {
            closeContactPopup();
            requestNewContact();
            lastContactTime = Date.now();
            
            CurrentMeetLocation = null;
        });
    }
    
    if (cancelContactBtn) {
        cancelContactBtn.addEventListener('click', function() {
            closeContactPopup();
        });
    }
    
    if (closeContactPopupBtn) {
        closeContactPopupBtn.addEventListener('click', function() {
            closeContactPopup();
        });
    }
    
    if (counterOfferBtn) {
        counterOfferBtn.addEventListener('click', function() {
            openCounterOfferPopup();
        });
    }
    
    if (closeCounterOfferBtn) {
        closeCounterOfferBtn.addEventListener('click', function() {
            closeCounterOfferPopup();
        });
    }
    
    if (priceMinus100) priceMinus100.addEventListener('click', function() { adjustPrice(-100); });
    if (priceMinus10) priceMinus10.addEventListener('click', function() { adjustPrice(-10); });
    if (priceMinus1) priceMinus1.addEventListener('click', function() { adjustPrice(-1); });
    if (pricePlus1) pricePlus1.addEventListener('click', function() { adjustPrice(1); });
    if (pricePlus10) pricePlus10.addEventListener('click', function() { adjustPrice(10); });
    if (pricePlus100) pricePlus100.addEventListener('click', function() { adjustPrice(100); });
    
    if (quantityMinus) quantityMinus.addEventListener('click', decreaseQuantity);
    if (quantityPlus) quantityPlus.addEventListener('click', increaseQuantity);
    
    if (drugSelector) {
        drugSelector.addEventListener('change', function() {
            selectDrug(this.value);
        });
    }
    
    if (sendOfferBtn) {
        sendOfferBtn.addEventListener('click', function() {
            sendCounterOffer();
        });
    }
    
    if (overlay) {
        overlay.addEventListener('click', function() {
            closeCounterOfferPopup();
            closeContactPopup();
        });
    }
    
    document.querySelectorAll('.delete-btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.stopPropagation();
            const messageItem = this.closest('.message-item');
            if (messageItem) {
                const contactId = messageItem.getAttribute('data-id');
                deleteConversation(contactId);
                messageItem.remove();
            }
        });
    });
}

function updateTime() {
    const now = new Date();
    let hours = now.getHours();
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12; 
    
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const dayName = days[now.getDay()];
    
    const timeDisplay = document.getElementById('timeDisplay');
    if (timeDisplay) {
        timeDisplay.textContent = `${hours}:${minutes} ${ampm} ${dayName}`;
    }
}

function requestNewContact() {
    hasActiveContact = false;
    activeContact = null;
    
    CurrentMeetLocation = null;
    
    sendPostMessage('requestNewContact', {}, function(response) {
        if (response && response.status === 'success' && response.contact) {
            hasActiveContact = true;
            
            contactsList = [response.contact]; 
            
            const messagesContainer = document.getElementById('messagesContainer');
            if (messagesContainer) {
                messagesContainer.innerHTML = '';
            }
            
            addContactToMessageList(response.contact);
            
            updateNotificationBadge();
            
            activeContact = response.contact;
            
            conversationStates[response.contact.id] = {
                messages: JSON.parse(JSON.stringify(response.contact.messages)), 
                responseState: 'initial',
                counterOfferSent: false
            };
            
            counterOfferSent = false;
            
            sendPostMessage('showNotification', {
                message: `New contact added: ${response.contact.name}`,
                type: 'success'
            });
        } else {
            sendPostMessage('showNotification', {
                message: `Failed to find a new contact`,
                type: 'error'
            });
        }
    });
}

function addContactToMessageList(contact) {
    const messagesContainer = document.getElementById('messagesContainer');
    if (!messagesContainer) return;
    
    const existingItem = document.querySelector(`.message-item[data-id="${contact.id}"]`);
    if (existingItem) {
        console.warn("Contact already exists in UI:", contact.id);
        return;
    }
    
    const messageItem = document.createElement('div');
    messageItem.className = 'message-item';
    messageItem.setAttribute('data-id', contact.id);
    
    const lastMessage = contact.messages[contact.messages.length - 1];
    
    messageItem.innerHTML = `
        <div class="avatar" style="background-color: ${contact.avatarColor}">
            <div class="avatar-icon">
                <span class="char-img">${contact.avatar}</span>
            </div>
            <div class="online-indicator"></div>
        </div>
        <div class="message-content">
            <div class="contact-name">
                <span class="contact-name-text">${contact.name}</span>
                <span class="online-dot"></span>
            </div>
            <div class="message-preview">${lastMessage ? lastMessage.text : ''}</div>
        </div>
        <div class="message-actions">
            <button class="delete-btn">
                <i class="fa fa-times"></i>
            </button>
        </div>
    `;
    
    messageItem.addEventListener('click', function() {
        openChat(contact);
    });
    
    const deleteBtn = messageItem.querySelector('.delete-btn');
    if (deleteBtn) {
        deleteBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            deleteConversation(contact.id);
            messageItem.remove();
            
            const index = contactsList.findIndex(c => c.id === contact.id);
            if (index !== -1) {
                contactsList.splice(index, 1);
                updateNotificationBadge();
            }
            
            hasActiveContact = false;
            
            CurrentMeetLocation = null;
        });
    }
    
    messagesContainer.appendChild(messageItem);
    
    updateNotificationBadge();
}

function openChat(contact) {
    const messagesScreen = document.getElementById('messagesScreen');
    const chatScreen = document.getElementById('chatScreen');
    if (!messagesScreen || !chatScreen) return;
    
    activeContact = JSON.parse(JSON.stringify(contact));
    
    const stateLoaded = loadConversationState(contact.id);
    
    if (!stateLoaded) {
        contact.currentState = 'initial';
        counterOfferSent = false;
    }
    
    updateChatHeader(activeContact);
    
    updateChatMessages(activeContact.messages);
    
    updateResponseOptions(activeContact.currentState || 'initial');
    
    messagesScreen.style.transform = 'translateX(-100%)';
    chatScreen.style.transform = 'translateX(0)';
}

function updateChatHeader(contact) {
    const chatName = document.getElementById('chatName');
    const chatAvatar = document.getElementById('chatAvatar');
    const repBar = document.getElementById('repBar');
    const checkIcon = document.getElementById('checkIcon');
    
    if (chatName) chatName.textContent = contact.name;
    
    if (chatAvatar) {
        chatAvatar.style.backgroundColor = contact.avatarColor;
        chatAvatar.innerHTML = `<span class="char-img">${contact.avatar}</span>`;
    }
    
    if (repBar) {
        repBar.style.setProperty('--relationship', `${contact.relationship}%`);
    }
    
    if (checkIcon) {
        checkIcon.style.display = contact.verified ? 'flex' : 'none';
    }
}

function updateChatMessages(messages) {
    const chatContainer = document.getElementById('chatContainer');
    if (!chatContainer) return;
    
    console.log(`Updating chat with ${messages.length} messages`);
    
    chatContainer.innerHTML = '';
    
    messageHistory = JSON.parse(JSON.stringify(messages));
    
    messages.forEach((message, index) => {
        const messageElement = document.createElement('div');
        messageElement.className = `message-bubble message-${message.sender}`;
        messageElement.textContent = message.text;
        messageElement.setAttribute('data-index', index);
        chatContainer.appendChild(messageElement);
    });
    
    chatContainer.scrollTop = chatContainer.scrollHeight;
}

function updateResponseOptions(state) {
    const optionsContainer = document.getElementById('optionsContainer');
    if (!optionsContainer) return;
    
    if (activeContact) {
        activeContact.currentState = state;
    }
    
    optionsContainer.innerHTML = '';
    
    if (state === 'initial') {
        const dealBtn = document.createElement('button');
        dealBtn.className = 'option-btn option-disabled';
        dealBtn.textContent = 'Deal';
        dealBtn.style.opacity = '0.5';
        dealBtn.style.cursor = 'not-allowed';
        dealBtn.disabled = true;
        dealBtn.title = 'You must make a counter offer first';
        optionsContainer.appendChild(dealBtn);
        
        const counterBtn = document.createElement('button');
        counterBtn.className = 'option-btn';
        counterBtn.textContent = '[Counter-offer]';
        counterBtn.addEventListener('click', function() {
            openCounterOfferPopup();
        });
        optionsContainer.appendChild(counterBtn);
        
        const rejectBtn = document.createElement('button');
        rejectBtn.className = 'option-btn';
        rejectBtn.textContent = 'Not right now';
        rejectBtn.addEventListener('click', function() {
            sendPlayerResponse('Not right now', 'deal_rejected');
        });
        optionsContainer.appendChild(rejectBtn);
        
        return;
    }
    
    const stateHandler = responseStateHandlers[state];
    if (stateHandler) {
        stateHandler(optionsContainer);
    } else {
        defaultResponseOptions(optionsContainer);
    }
    
    if (activeContact) {
        saveConversationState(activeContact.id);
    }
}

const responseStateHandlers = {
    'deal_accepted': function(container) {
        const locationBtn = document.createElement('button');
        locationBtn.className = 'option-btn';
        locationBtn.textContent = 'Send me the location';
        locationBtn.addEventListener('click', function() {
            sendPlayerResponse('Send me the location', 'meet_location');
            
            setTimeout(() => {
                sendLocationRequest();
            }, 300);
        });
        container.appendChild(locationBtn);
        
        const noResponseBtn = document.createElement('button');
        noResponseBtn.className = 'option-btn';
        noResponseBtn.textContent = 'I\'ll be in touch';
        noResponseBtn.addEventListener('click', function() {
            sendPlayerResponse('I\'ll be in touch', 'no_response');
        });
        container.appendChild(noResponseBtn);
    },
    
    'deal_rejected': function(container) {
        const laterBtn = document.createElement('button');
        laterBtn.className = 'option-btn';
        laterBtn.textContent = 'Maybe another time';
        laterBtn.addEventListener('click', function() {
            sendPlayerResponse('Maybe another time', 'closed');
        });
        container.appendChild(laterBtn);
        
        const dontSellBtn = document.createElement('button');
        dontSellBtn.className = 'option-btn';
        dontSellBtn.textContent = 'I don\'t sell that stuff';
        dontSellBtn.addEventListener('click', function() {
            sendPlayerResponse('I don\'t sell that stuff', 'closed');
        });
        container.appendChild(dontSellBtn);
    },
    
    'counter_accepted': function(container) {
        responseStateHandlers['deal_accepted'](container);
    },
    
    'counter_rejected': function(container) {
        responseStateHandlers['deal_rejected'](container);
    },
    
    'meet_location': function(container) {
        container.innerHTML = '<div style="text-align: center; color: #666; padding: 10px;">Meeting location set</div>';
    },
    
    'no_response': function(container) {
        const continueBtn = document.createElement('button');
        continueBtn.className = 'option-btn';
        continueBtn.textContent = 'I\'m ready to meet now';
        continueBtn.addEventListener('click', function() {
            sendPlayerResponse('I\'m ready to meet now', 'ready_to_meet');
            
            setTimeout(() => {
                sendLocationRequest();
            }, 500);
        });
        container.appendChild(continueBtn);
        
        const locationBtn = document.createElement('button');
        locationBtn.className = 'option-btn';
        locationBtn.textContent = 'Send me the location';
        locationBtn.addEventListener('click', function() {
            sendPlayerResponse('Send me the location', 'meet_location');
            
            setTimeout(() => {
                sendLocationRequest();
            }, 300);
        });
        container.appendChild(locationBtn);
    },
    
    'ready_to_meet': function(container) {
        const locationBtn = document.createElement('button');
        locationBtn.className = 'option-btn';
        locationBtn.textContent = 'Send me the location';
        locationBtn.addEventListener('click', function() {
            sendPlayerResponse('Send me the location', 'meet_location');
            
            setTimeout(() => {
                sendLocationRequest();
            }, 300);
        });
        container.appendChild(locationBtn);
    },
    
    'closed': function(container) {
        container.innerHTML = '<div style="text-align: center; color: #666; padding: 10px;">Conversation ended</div>';
    }
};

function defaultResponseOptions(container) {
    const infoText = document.createElement('div');
    infoText.style.textAlign = 'center';
    infoText.style.color = '#666';
    infoText.style.padding = '10px';
    infoText.textContent = 'No response options available';
    container.appendChild(infoText);
}

function sendPlayerResponse(message, nextState) {
    if (activeContact) {
        console.log(`Before sending response - Messages count: ${activeContact.messages.length}`);
        
        const originalMessages = JSON.parse(JSON.stringify(activeContact.messages));
        
        const messageObj = {
            sender: 'me',
            text: message,
            time: getCurrentTime()
        };
        
        activeContact.messages.push(messageObj);
        
        updateChatMessages(activeContact.messages);
        
        updateMessagePreview(activeContact.id, message);
        
        const isLocationRelated = nextState === 'meet_location' || nextState === 'ready_to_meet';
        
        const skipLocationRequest = isLocationRelated && CurrentMeetLocation !== null;
        
        let extraData = {};
        if (selectedDrug) {
            extraData = {
                drugName: selectedDrug.label,
                drugItemName: selectedDrug.name,
                quantity: currentQuantity,
                price: currentPrice,
                skipLocationRequest: skipLocationRequest
            };
            console.log(`Including drug details: ${selectedDrug.name} x${currentQuantity} for $${currentPrice}`);
            console.log(`Skip location request: ${skipLocationRequest}`);
        }
        
        sendPostMessage('sendMessage', {
            message: message,
            nextState: nextState,
            contactId: activeContact.id,
            preserveChat: true,
            originalMessageCount: activeContact.messages.length,
            skipLocationRequest: skipLocationRequest,
            ...extraData
        }, function(response) {
            if (response && response.status === 'success') {
                console.log(`Response successful - Messages received: ${response.messages ? response.messages.length : 'none'}`);
                
                if (!response.messages || response.messages.length < originalMessages.length) {
                    console.log("Message loss detected, restoring from backup!");
                    
                    let restoredMessages = JSON.parse(JSON.stringify(originalMessages));
                    
                    const lastMessage = restoredMessages[restoredMessages.length - 1];
                    if (!lastMessage || lastMessage.sender !== 'me' || lastMessage.text !== message) {
                        restoredMessages.push(messageObj);
                    }
                    
                    if (isLocationRelated) {
                        const locations = ["Vinewood Hills", "Downtown", "Mirror Park", "Sandy Shores"];
                        const randomLocation = locations[Math.floor(Math.random() * locations.length)];
                            
                        const locationMessage = {
                            sender: 'them',
                            text: `I'll be waiting at ${randomLocation}. Make sure you're not followed.`,
                            time: getCurrentTime()
                        };
                        
                        const hasLocationMessage = restoredMessages.some(msg => 
                            msg.sender === 'them' && msg.text.includes('waiting at')
                        );
                        
                        if (!hasLocationMessage) {
                            restoredMessages.push(locationMessage);
                        }
                        
                        CurrentMeetLocation = randomLocation;
                    }
                    
                    activeContact.messages = restoredMessages;
                    
                    updateChatMessages(activeContact.messages);
                    
                    if (activeContact.messages.length > 0) {
                        const lastMsg = activeContact.messages[activeContact.messages.length - 1];
                        updateMessagePreview(activeContact.id, lastMsg.text);
                    }
                } else {
                    activeContact.messages = response.messages;
                    
                    updateChatMessages(activeContact.messages);
                    
                    if (activeContact.messages.length > 0) {
                        const lastMsg = activeContact.messages[activeContact.messages.length - 1];
                        updateMessagePreview(activeContact.id, lastMsg.text);
                    }
                    
                    if (isLocationRelated && response.locationSet) {
                        CurrentMeetLocation = response.locationName || "Unknown";
                        console.log(`Updated current meet location to: ${CurrentMeetLocation}`);
                    }
                }
                
                updateResponseOptions(nextState);
                
                activeContact.currentState = nextState;
                
                saveConversationState(activeContact.id);
                
                console.log(`After server response - Messages count: ${activeContact.messages.length}`);
            } else {
                console.log("Server response failed, using local backup");
                
                activeContact.messages = JSON.parse(JSON.stringify(originalMessages));
                
                const lastMessage = activeContact.messages[activeContact.messages.length - 1];
                if (!lastMessage || lastMessage.sender !== 'me' || lastMessage.text !== message) {
                    activeContact.messages.push(messageObj);
                }
                
                setTimeout(() => {
                    let responseText = "OK, got it.";
                    
                    switch(nextState) {
                        case 'deal_accepted':
                            responseText = "Great! I'll set everything up.";
                            break;
                        case 'deal_rejected':
                            responseText = "Fine, whatever. Your loss.";
                            break;
                        case 'meet_location':
                            responseText = "I'll be waiting at Vinewood Hills. Come alone.";
                            CurrentMeetLocation = "Vinewood Hills";
                            break;
                        case 'no_response':
                            responseText = "Don't take too long or I'll find someone else.";
                            break;
                        case 'ready_to_meet':
                            responseText = "Great, I'm ready too. Let me send you the location.";
                            break;
                        case 'closed':
                            responseText = "Whatever man.";
                            break;
                    }
                    
                    const responseObj = {
                        sender: 'them',
                        text: responseText,
                        time: getCurrentTime()
                    };
                    
                    const hasSimilarMessage = activeContact.messages.some(msg => 
                        msg.sender === 'them' && msg.text === responseText
                    );
                    
                    if (!hasSimilarMessage) {
                        activeContact.messages.push(responseObj);
                    }
                    
                    if (nextState === 'deal_accepted') {
                        setTimeout(() => {
                            const followUpMsg = "Where and when should we meet?";
                            
                            const hasFollowUp = activeContact.messages.some(msg => 
                                msg.sender === 'them' && msg.text === followUpMsg
                            );
                            
                            if (!hasFollowUp) {
                                const followUpObj = {
                                    sender: 'them',
                                    text: followUpMsg,
                                    time: getCurrentTime()
                                };
                                
                                activeContact.messages.push(followUpObj);
                            }
                            
                            updateChatMessages(activeContact.messages);
                            updateMessagePreview(activeContact.id, followUpMsg);
                        }, 800);
                    }
                    
                    if (nextState === 'ready_to_meet') {
                        setTimeout(() => {
                            const locationMsg = "I'll be waiting at Mirror Park. Come alone.";
                            
                            const hasLocation = activeContact.messages.some(msg => 
                                msg.sender === 'them' && msg.text.includes('waiting at')
                            );
                            
                            if (!hasLocation) {
                                const locationObj = {
                                    sender: 'them',
                                    text: locationMsg,
                                    time: getCurrentTime()
                                };
                                activeContact.messages.push(locationObj);
                            }
                            
                            updateChatMessages(activeContact.messages);
                            updateMessagePreview(activeContact.id, locationMsg);
                            
                            nextState = 'meet_location';
                            updateResponseOptions(nextState);
                            activeContact.currentState = nextState;
                            saveConversationState(activeContact.id);
                            
                            sendPostMessage('setWaypoint', {
                                location: 'Mirror Park',
                                drugName: selectedDrug ? selectedDrug.name : null,
                                drugItemName: selectedDrug ? selectedDrug.name : null,
                                quantity: currentQuantity,
                                price: currentPrice,
                                skipLocationRequest: skipLocationRequest
                            });
                            
                            CurrentMeetLocation = "Mirror Park";
                        }, 1000);
                    }
                    
                    if (nextState === 'meet_location') {
                        sendPostMessage('setWaypoint', {
                            location: 'Vinewood Hills',
                            drugName: selectedDrug ? selectedDrug.label : null,
                            drugItemName: selectedDrug ? selectedDrug.name : null,
                            quantity: currentQuantity,
                            price: currentPrice,
                            skipLocationRequest: skipLocationRequest
                        });
                        
                        CurrentMeetLocation = "Vinewood Hills";
                    }
                    
                    updateChatMessages(activeContact.messages);
                    updateMessagePreview(activeContact.id, responseText);
                    
                    updateResponseOptions(nextState);
                    activeContact.currentState = nextState;
                    
                    saveConversationState(activeContact.id);
                    
                    console.log(`After local backup - Messages count: ${activeContact.messages.length}`);
                }, 800);
            }
        });
    }
}

function updateMessagePreview(contactId, text) {
    const messageItem = document.querySelector(`.message-item[data-id="${contactId}"]`);
    if (messageItem) {
        const messagePreview = messageItem.querySelector('.message-preview');
        if (messagePreview) {
            messagePreview.textContent = text;
        }
    }
}

function getCurrentTime() {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
}

function deleteConversation(contactId) {
    sendPostMessage('deleteConversation', {
        contactId: contactId
    });
    
    if (conversationStates[contactId]) {
        delete conversationStates[contactId];
    }
    
    const index = contactsList.findIndex(c => c.id === contactId);
    if (index !== -1) {
        contactsList.splice(index, 1);
        updateNotificationBadge();
    }
    
    if (activeContact && activeContact.id === contactId) {
        activeContact = null;
    }
    
    hasActiveContact = false;
    
    CurrentMeetLocation = null;
}

function populateDrugSelector() {
    const drugSelector = document.getElementById('drugSelector');
    if (!drugSelector) return;
    
    drugSelector.innerHTML = '';
    
    playerDrugs.forEach(drug => {
        const option = document.createElement('option');
        option.value = drug.name;
        option.textContent = drug.label;
        drugSelector.appendChild(option);
    });
    
    if (playerDrugs.length > 0) {
        selectDrug(playerDrugs[0].name);
    }
}

function selectDrug(drugName) {
    selectedDrug = playerDrugs.find(drug => drug.name === drugName);
    
    if (selectedDrug) {
        currentQuantity = 1;
        
        fairPrice = selectedDrug.basePrice;
        
        currentPrice = fairPrice;
        
        calculateSuccessChance();
        
        updateCounterOfferUI();
    }
}

function calculateSuccessChance() {
    const totalFairPrice = fairPrice * currentQuantity;
    const priceDifference = (currentPrice - totalFairPrice) / totalFairPrice;
    
    let baseChance = 70;
    
    if (priceDifference <= -0.3) {
        successChance = 95;
    } else if (priceDifference <= -0.2) {
        successChance = 90;
    } else if (priceDifference <= -0.1) {
        successChance = 80;
    } else if (priceDifference <= 0) {
        successChance = 70;
    } else if (priceDifference <= 0.1) {
        successChance = 60;
    } else if (priceDifference <= 0.1) {
        successChance = 60;
    } else if (priceDifference <= 0.2) {
        successChance = 40;
    } else if (priceDifference <= 0.3) {
        successChance = 20;
    } else {
        successChance = 10;
    }
    
    return successChance;
}

function resetCounterOffer() {
    currentQuantity = 1;
    
    if (playerDrugs.length > 0) {
        selectDrug(playerDrugs[0].name);
    }
}

function updateCounterOfferUI() {
    if (!selectedDrug) return;
    
    const itemQuantityDisplay = document.getElementById('itemQuantityDisplay');
    if (itemQuantityDisplay) {
        itemQuantityDisplay.textContent = `${currentQuantity}x ${selectedDrug.label}`;
    }
    
    const priceDisplay = document.getElementById('priceDisplay');
    const currentPriceDisplay = document.getElementById('currentPrice');
    if (priceDisplay) priceDisplay.textContent = `$${currentPrice}`;
    if (currentPriceDisplay) currentPriceDisplay.textContent = `$${currentPrice}`;
    
    const calculatedFairPrice = fairPrice * currentQuantity;
    const fairPriceDisplay = document.getElementById('fairPriceDisplay');
    if (fairPriceDisplay) {
        fairPriceDisplay.textContent = `Fair price: $${calculatedFairPrice}`;
    }
    
    calculateSuccessChance();
    
    const sendOfferBtn = document.getElementById('sendOfferBtn');
    if (sendOfferBtn) {
        sendOfferBtn.textContent = `Send (${successChance}%)`;
    }
}

function increaseQuantity() {
    if (!selectedDrug) return;
    
    if (currentQuantity < selectedDrug.amount) {
        currentQuantity++;
        calculateSuccessChance();
        updateCounterOfferUI();
    }
}

function decreaseQuantity() {
    if (currentQuantity > 1) {
        currentQuantity--;
        calculateSuccessChance();
        updateCounterOfferUI();
    }
}

function adjustPrice(amount) {
    currentPrice += amount;
    
    if (currentPrice < 0) {
        currentPrice = 0;
    }
    
    calculateSuccessChance();
    
    updateCounterOfferUI();
}

function sendCounterOffer() {
    if (!selectedDrug || !activeContact) return;
    
    console.log(`Before sending counter offer - Messages count: ${activeContact.messages.length}`);
    
    const originalMessages = JSON.parse(JSON.stringify(activeContact.messages));
    
    const offerQuantity = parseInt(currentQuantity);
    const offerPrice = parseInt(currentPrice);
    
    const offerData = {
        drugName: selectedDrug.label,
        drugItemName: selectedDrug.name,
        quantity: offerQuantity,
        price: offerPrice,
        fairPrice: fairPrice * offerQuantity,
        successChance: successChance,
        contactId: activeContact.id,
        preserveChat: true
    };
    
    console.log(`Sending counter offer: ${selectedDrug.name} (${selectedDrug.label}) x${offerQuantity} (${typeof offerQuantity}) for $${offerPrice} (${typeof offerPrice})`);
    
    closeCounterOfferPopup();
    
    const counterMessage = `I can give you ${offerQuantity}x ${selectedDrug.label} for $${offerPrice}. Deal?`;
    const messageObj = {
        sender: 'me',
        text: counterMessage,
        time: getCurrentTime()
    };
    
    activeContact.messages.push(messageObj);
    
    updateChatMessages(activeContact.messages);
    
    updateMessagePreview(activeContact.id, counterMessage);
    
    counterOfferSent = true;
    
    updateResponseOptions('initial');
    
    saveConversationState(activeContact.id);
    
    sendPostMessage('sendCounterOffer', offerData, function(response) {
        if (response && response.status === 'success') {
            console.log('Counter offer sent successfully');
            
            if (response.messages && response.messages.length >= originalMessages.length) {
                console.log(`Received ${response.messages.length} messages with preserveChat flag`);
                
                activeContact.messages = response.messages;
                
                updateChatMessages(response.messages);
                
                if (response.messages.length > 0) {
                    const lastMsg = response.messages[response.messages.length - 1];
                    updateMessagePreview(activeContact.id, lastMsg.text);
                }
                
                if (response.offerAccepted !== undefined) {
                    updateResponseOptions(response.offerAccepted ? 'counter_accepted' : 'counter_rejected');
                    
                    saveConversationState(activeContact.id);
                }
            } else {
                console.log("Message loss detected in counter offer response, keeping local messages");
            }
            
            console.log(`After server counter offer response - Messages count: ${activeContact.messages.length}`);
        } else {
            console.log("Server response failed for counter offer, using local fallback");
            
            setTimeout(() => {
                const accepted = Math.random() > 0.3;
                
                const responseText = accepted ? 
                    "Deal! That works for me." : 
                    "Sorry, that's too expensive for me.";
                
                const hasResponse = activeContact.messages.some(msg => 
                    msg.sender === 'them' && msg.text === responseText
                );
                
                if (!hasResponse) {
                    const responseMsg = {
                        sender: 'them',
                        text: responseText,
                        time: getCurrentTime()
                    };
                    
                    activeContact.messages.push(responseMsg);
                }
                
                if (accepted) {
                    const followUpText = "So, where should we meet?";
                    
                    const hasFollowUp = activeContact.messages.some(msg => 
                        msg.sender === 'them' && msg.text === followUpText
                    );
                    
                    if (!hasFollowUp) {
                        setTimeout(() => {
                            const followUpMsg = {
                                sender: 'them',
                                text: followUpText,
                                time: getCurrentTime()
                            };
                            
                            activeContact.messages.push(followUpMsg);
                            updateChatMessages(activeContact.messages);
                            updateMessagePreview(activeContact.id, followUpMsg.text);
                        }, 1000);
                    }
                }
                
                updateChatMessages(activeContact.messages);
                
                updateResponseOptions(accepted ? 'counter_accepted' : 'counter_rejected');
                
                updateMessagePreview(activeContact.id, responseText);
                
                saveConversationState(activeContact.id);
                
                console.log(`After local counter offer fallback - Messages count: ${activeContact.messages.length}`);
            }, 1000);
        }
    });
}

function sendLocationRequest() {
    if (!activeContact) return;

    const skipLocationRequest = !!CurrentMeetLocation;

    const drugInfo = {};
    if (selectedDrug) {
        drugInfo.drugName = selectedDrug.label;
        drugInfo.drugItemName = selectedDrug.name;
        drugInfo.quantity = parseInt(currentQuantity);
        drugInfo.price = parseInt(currentPrice);
    }

    sendPostMessage('setWaypoint', {
        location: 'requested',
        skipLocationRequest: skipLocationRequest,
        ...drugInfo,
        preserveChat: true
    }, function(response) {
        console.log(`Location request sent with drug info: ${JSON.stringify(drugInfo)}`);
        console.log(`Skip location flag: ${skipLocationRequest}`);
        
        if (response && response.status === 'success') {
            console.log('Waypoint set successfully');
            
            if (response.locationName) {
                CurrentMeetLocation = response.locationName;
                console.log(`Updated current meet location to: ${CurrentMeetLocation}`);
            }
        }
    });
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openPhone') {
        const phoneContainer = document.querySelector('.phone-container');
        if (phoneContainer) {
            phoneContainer.style.display = 'block';
            phoneContainer.classList.add('phone-in');
        }
        
        if (data.drugs) {
            playerDrugs = data.drugs;
        }
        
        if (data.currentMeetLocation) {
            CurrentMeetLocation = data.currentMeetLocation;
            console.log(`Phone opened with active meeting location: ${CurrentMeetLocation}`);
        } else {
            CurrentMeetLocation = null;
        }
        
        if (data.contacts) {
            contactsList = data.contacts.map(contact => JSON.parse(JSON.stringify(contact))); 
            
            updateNotificationBadge();
            
            const messagesContainer = document.getElementById('messagesContainer');
            if (messagesContainer) {
                messagesContainer.innerHTML = '';
                
                contactsList.forEach(contact => {
                    addContactToMessageList(contact);
                });
            }
            
            contactsList.forEach(contact => {
                if (!conversationStates[contact.id]) {
                    conversationStates[contact.id] = {
                        messages: JSON.parse(JSON.stringify(contact.messages)), 
                        responseState: 'initial',
                        counterOfferSent: false
                    };
                }
            });
            
            hasActiveContact = contactsList.length > 0;
        }
    } 
    else if (data.action === 'closePhone') {
        if (activeContact) {
            saveConversationState(activeContact.id);
        }
        
        const phoneContainer = document.querySelector('.phone-container');
        if (phoneContainer) {
            phoneContainer.classList.remove('phone-in');
            phoneContainer.classList.add('phone-out');
            
            setTimeout(() => {
                phoneContainer.style.display = 'none';
                phoneContainer.classList.remove('phone-out');
            }, 300);
        }
    }
    else if (data.action === 'newContact') {
        if (data.contact) {
            hasActiveContact = true;
            
            contactsList = [JSON.parse(JSON.stringify(data.contact))]; 
            
            const messagesContainer = document.getElementById('messagesContainer');
            if (messagesContainer) {
                messagesContainer.innerHTML = '';
            }
            
            addContactToMessageList(data.contact);
            
            conversationStates[data.contact.id] = {
                messages: JSON.parse(JSON.stringify(data.contact.messages)), 
                responseState: 'initial',
                counterOfferSent: false
            };
            
            updateNotificationBadge();
            
            CurrentMeetLocation = null;
        }
    }
    else if (data.action === 'updateMessages') {
        if (data.messages && activeContact) {
            console.log(`updateMessages event: Received ${data.messages.length} messages, preserveChat=${data.preserveChat}`);
            
            if (data.preserveChat) {
                if (data.messages.length >= activeContact.messages.length) {
                    activeContact.messages = JSON.parse(JSON.stringify(data.messages)); 
                } else {
                    console.log("Warning: Server sent fewer messages than we have locally, keeping local version");
                }
            } else {
                activeContact.messages = JSON.parse(JSON.stringify(data.messages)); 
            }
            
            updateChatMessages(activeContact.messages);
            
            if (activeContact.messages.length > 0) {
                const lastMsg = activeContact.messages[activeContact.messages.length - 1];
                updateMessagePreview(activeContact.id, lastMsg.text);
            }
            
            if (data.locationSet) {
                CurrentMeetLocation = data.locationName || "Unknown";
                console.log(`Updated current meet location to: ${CurrentMeetLocation}`);
            }
            
            if (activeContact.id) {
                saveConversationState(activeContact.id);
            }
        }
        
        if (data.offerAccepted !== undefined) {
            updateResponseOptions(data.offerAccepted ? 'counter_accepted' : 'counter_rejected');
        }
    }
});

function sendPostMessage(action, data = {}, callback = null) {
    const messageId = `msg_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    
    data.messageId = messageId;
    
    if (callback) {
        window.callbacks = window.callbacks || {};
        window.callbacks[messageId] = callback;
    }
    
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    })
    .then(resp => resp.json())
    .then(resp => {
        if (window.callbacks && window.callbacks[messageId]) {
            window.callbacks[messageId](resp);
            delete window.callbacks[messageId];
        }
    })
    .catch(error => {
        console.error('Error:', error);
        if (window.callbacks && window.callbacks[messageId]) {
            if (action === 'requestNewContact') {
                callback({
                    status: 'success',
                    contact: {
                        id: 'test_contact_' + Date.now(),
                        name: 'Kevin Oakley',
                        avatar: '👨',
                        avatarColor: '#9C6E3C',
                        verified: true,
                        relationship: 50,
                        messages: [
                            {
                                sender: 'them',
                                text: 'Hey, I could use some Mega Death. Got any? I\'ll pay.',
                                time: getCurrentTime()
                            }
                        ]
                    }
                });
            } else if (action === 'sendCounterOffer') {
                let accepted = Math.random() > 0.2; 
                
                let response = {
                    status: 'success',
                    offerAccepted: accepted,
                    messages: [
                        ...activeContact.messages,
                    ],
                    preserveChat: true
                };
                
                response.messages.push({
                    sender: 'them',
                    text: accepted ? 
                        'Deal! That works for me.' : 
                        'Sorry, that\'s too expensive for me.',
                    time: getCurrentTime()
                });
                
                if (accepted) {
                    response.messages.push({
                        sender: 'them',
                        text: 'So, where should we meet?',
                        time: getCurrentTime()
                    });
                }
                
                callback(response);
            } else if (action === 'sendMessage') {
                const nextState = data.nextState;
                
                let response = {
                    status: 'success',
                    messages: [
                        ...activeContact.messages
                    ],
                    preserveChat: true
                };
                
                if (nextState === 'deal_rejected') {
                    response.messages.push({
                        sender: 'them',
                        text: 'Fine, whatever. Your loss.',
                        time: getCurrentTime()
                    });
                } else if (nextState === 'deal_accepted') {
                    response.messages.push({
                        sender: 'them',
                        text: 'Great! I\'ll set everything up.',
                        time: getCurrentTime()
                    });
                    response.messages.push({
                        sender: 'them',
                        text: 'Where and when should we meet?',
                        time: getCurrentTime()
                    });
                } else if (nextState === 'meet_location') {
                    response.messages.push({
                        sender: 'them',
                        text: 'I\'ll be waiting at Vinewood Hills. Come alone.',
                        time: getCurrentTime()
                    });
                    
                    CurrentMeetLocation = "Vinewood Hills";
                    response.locationSet = true;
                    response.locationName = "Vinewood Hills";
                } else if (nextState === 'ready_to_meet') {
                    response.messages.push({
                        sender: 'them',
                        text: 'Great, I\'m ready too. Let me send you the location.',
                        time: getCurrentTime()
                    });
                    setTimeout(() => {
                        response.messages.push({
                            sender: 'them',
                            text: 'I\'ll be waiting at Mirror Park. Come alone.',
                            time: getCurrentTime()
                        });
                        
                        CurrentMeetLocation = "Mirror Park";
                    }, 800);
                }
                
                callback(response);
            } else if (action === 'setWaypoint') {
                console.log('Setting waypoint to ' + data.location);
                
                if (data.location && data.location !== 'requested') {
                    CurrentMeetLocation = data.location;
                } else {
                    CurrentMeetLocation = "Default Location";
                }
                
                callback({
                    status: 'success', 
                    message: 'Waypoint set',
                    locationSet: true,
                    locationName: CurrentMeetLocation
                });
            } else {
                callback({status: 'success', message: 'Test mode, no game client'});
            }
            delete window.callbacks[messageId];
        }
    });
}

function GetParentResourceName() {
    try {
        return window.GetParentResourceName();
    } catch(e) {
        return 'nc-trapphone';
    }
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        if (activeContact) {
            saveConversationState(activeContact.id);
        }
        
        sendPostMessage('closePhone');
    }
});