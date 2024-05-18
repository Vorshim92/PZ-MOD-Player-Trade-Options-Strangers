
-- Funzione per ottenere il nome del personaggio
local function getCharacterName(username, displayName)
    if getDebug() or (isClient() and (getAccessLevel() == "admin")) then
        return displayName
    end
    local players = getOnlinePlayers()
    if not players or players:size() == 0 then
        -- print("No players online")
        return displayName
    end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() then
            local playerUsername = player:getUsername()
            -- print("Checking player: " .. tostring(playerUsername))
            if playerUsername == username then
                local characterName = player:getDescriptor():getForename() .. " " .. player:getDescriptor():getSurname()
                -- print("Character name found for " .. username .. ": " .. characterName)
                return characterName
            end
        end
    end
    -- print("No match found for " .. username)
    return displayName
end

-- Salva un riferimento alla funzione originale
local ISFactionAddPlayerUI_populateList_ext = ISFactionAddPlayerUI.populateList

-- Sovrascrivi la funzione populateList
function ISFactionAddPlayerUI:populateList()
    -- print("populateList called")
    self.playerList:clear()
    self.addPlayer.enable = false
    if not self.scoreboard then return end
    for i = 1, self.scoreboard.usernames:size() do
        local username = self.scoreboard.usernames:get(i - 1)
        local displayName = self.scoreboard.displayNames:get(i - 1)
        -- print("Original displayName: " .. tostring(displayName))
        local doIt = false
        if self.changeOwnership then
            doIt = not self.faction:isOwner(username)
        else
            doIt = username ~= self.player:getUsername() and not self.faction:isMember(username)
        end
        if doIt then
            local newPlayer = {}
            newPlayer.name = username

            if SandboxVars.PlayerTradeOptions.useCharacterName or SandboxVars.PlayerTradeOptions.noName then
                displayName = getCharacterName(username, displayName)
                -- print("After getCharacterName, displayName: " .. tostring(displayName))
            end
            -- print("Updated displayName: " .. tostring(displayName))

            if self.changeOwnership then 
                local alreadyFaction = self.faction:isMember(username)
                if not alreadyFaction then
                    newPlayer.tooltip = getText("IGUI_FactionUI_NoMember")
                end
            else
                local alreadyFaction = Faction.isAlreadyInFaction(username)
                if alreadyFaction then
                    newPlayer.tooltip = getText("IGUI_FactionUI_AlreadyHaveFaction")
                end
            end
            local index = self.playerList:addItem(displayName, newPlayer)
            -- print("Item added at index: " .. tostring(index) .. " with displayName: " .. tostring(displayName))

            if newPlayer.tooltip then
                if self.playerList.items[i] then
                    self.playerList.items[i].tooltip = newPlayer.tooltip
                end
            end
        end
    end
end

local ISFactionAddPlayerUI_drawPlayers_ext = ISFactionAddPlayerUI.drawPlayers
function ISFactionAddPlayerUI:drawPlayers(y, item, alt)
    local a = 0.9

    -- self.parent.addPlayer.enable = false
    -- self.parent.selectedPlayer = nil
    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- self:drawRect(100, y-1, 1, self.itemheight,1,self.borderColor.r, self.borderColor.g, self.borderColor.b)
    -- self:drawRect(170, y-1, 1, self.itemheight,1,self.borderColor.r, self.borderColor.g, self.borderColor.b)
    -- self:drawRect(240, y-1, 1, self.itemheight,1,self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15)
        if item.tooltip then
            self.parent.addPlayer.tooltip = item.tooltip
            self.parent.addPlayer.enable = false
            self.parent.selectedPlayer = nil
        else
            self.parent.addPlayer.enable = true
            self.parent.selectedPlayer = item.item.name
        end
    end

    -- Usa item.text invece di item.item.name per visualizzare displayName aggiornato
    self:drawText(item.text, 10, y + 2, 1, 1, 1, a, self.font)

    return y + self.itemheight
end





-- Salva un riferimento alla funzione originale
local ISFactionAddPlayerUI_onClick_ext = ISFactionAddPlayerUI.onClick
function ISFactionAddPlayerUI:onClick(button)
    -- print("onClick called with button: " .. tostring(button.internal))

    if button.internal == "CANCEL" then
        self:setVisible(false);
        self:removeFromUIManager();
    end
    if button.internal == "ADDPLAYER" then
        if not self.changeOwnership then
            local playerName = self.selectedPlayer
            if SandboxVars.PlayerTradeOptions.useCharacterName or SandboxVars.PlayerTradeOptions.noName then
                playerName = getCharacterName(self.selectedPlayer, self.selectedPlayer)
            end

            local modal = ISModalDialog:new(0,0, 350, 150, getText("IGUI_FactionUI_InvitationSent",playerName), false, nil, nil);
            modal:initialise()
            modal:addToUIManager()
            sendFactionInvite(self.faction, self.player, self.selectedPlayer);
        else
            self.faction:setOwner(self.selectedPlayer);
			self.factionUI.isOwner = false;
            self.factionUI:populateList();
			self.factionUI:updateButtons();
            self:setVisible(false);
            self:removeFromUIManager();
            self.faction:syncFaction();
        end
    end
end



local function CustomReceiveFactionInvite(factionName, host)
    if ISFactionUI.inviteDialogs[host] then
        if ISFactionUI.inviteDialogs[host]:isReallyVisible() then return end
        ISFactionUI.inviteDialogs[host] = nil
    end
    -- FIXME: This can appear overtop MainScreen
    if not Faction.getPlayerFaction(getPlayer()) then
        local displayName = host
        if SandboxVars.PlayerTradeOptions.useCharacterName or SandboxVars.PlayerTradeOptions.noName then
            displayName = getCharacterName(host, host)
        end

        local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - 175,getCore():getScreenHeight() / 2 - 75, 350, 150, getText("IGUI_FactionUI_Invitation", displayName, factionName), true, nil, ISFactionUI.onAnswerFactionInvite);
        modal:initialise()
        modal:addToUIManager()
        modal.faction = Faction.getFaction(factionName);
        modal.host = host;
        modal.moveWithMouse = true;
        ISFactionUI.inviteDialogs[host] = modal
    end
end

Events.OnGameBoot.Add(function()
    Events.ReceiveFactionInvite.Remove(ISFactionUI.ReceiveFactionInvite)
    Events.ReceiveFactionInvite.Add(CustomReceiveFactionInvite)
end)
