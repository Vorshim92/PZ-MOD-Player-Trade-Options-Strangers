

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
local ISSafehouseAddPlayerUI_populateList_ext = ISSafehouseAddPlayerUI.populateList
-- Sovrascrivi la funzione populateList
function ISSafehouseAddPlayerUI:populateList()
    -- print("populateList called ")
    self.playerList:clear()
    if not self.scoreboard then return end
    local ownerUsername = self.safehouse:getOwner()
    -- print("Owner of the safehouse: " .. tostring(ownerUsername))
    for i = 1, self.scoreboard.usernames:size() do
        local username = self.scoreboard.usernames:get(i - 1)
        local displayName = self.scoreboard.displayNames:get(i - 1)
        -- print("Checking username: " .. tostring(username))

        if ownerUsername ~= username then
            local newPlayer = {}
            newPlayer.username = username

            if SandboxVars.PlayerTradeOptions.useCharacterName or SandboxVars.PlayerTradeOptions.noName then
                displayName = getCharacterName(username, displayName)
                -- print("After getCharacterName, displayName: " .. tostring(displayName))

            end

            local alreadySafe = self.safehouse:alreadyHaveSafehouse(username)
            if alreadySafe and alreadySafe ~= self.safehouse then
                if alreadySafe:getTitle() ~= "Safehouse" then
                    newPlayer.tooltip = getText("IGUI_SafehouseUI_AlreadyHaveSafehouse", "(" .. alreadySafe:getTitle() .. ")")
                else
                    newPlayer.tooltip = getText("IGUI_SafehouseUI_AlreadyHaveSafehouse", "")
                end
            end
            local item = self.playerList:addItem(displayName, newPlayer)
            -- print("Item added at index with displayName: " .. tostring(displayName))

            if newPlayer.tooltip then
                item.tooltip = newPlayer.tooltip
            end
        else
            -- print("Skipping owner: " .. tostring(username))
        end
    end
end

-- Salva un riferimento alla funzione originale
local ISSafehouseAddPlayerUI_onClick_ext = ISSafehouseAddPlayerUI.onClick

function ISSafehouseAddPlayerUI:onClick(button)
    -- print("onClick called with button: " .. tostring(button.internal))
    if button.internal == "CANCEL" then
        self:setVisible(false)
        self:removeFromUIManager()
        ISSafehouseAddPlayerUI.instance = nil
        return
    end
    if button.internal == "ADDPLAYER" then
        if not self.changeOwnership then
            local playerName = self.selectedPlayer
            if SandboxVars.PlayerTradeOptions.useCharacterName or SandboxVars.PlayerTradeOptions.noName then
                playerName = getCharacterName(self.selectedPlayer, self.selectedPlayer)
            end
            local modal = ISModalDialog:new(0, 0, 350, 150, getText("IGUI_FactionUI_InvitationSent", playerName), false, nil, nil)
            modal:initialise()
            modal:addToUIManager()
            sendSafehouseInvite(self.safehouse, self.player, self.selectedPlayer)
        else
            self.safehouse:setOwner(self.selectedPlayer)
            self.safehouse:syncSafehouse()
            if self.player:getX() >= self.safehouse:getX() - 1 and self.player:getX() < self.safehouse:getX2() + 1 and self.player:getY() >= self.safehouse:getY() - 1 and self.player:getY() < self.safehouse:getY2() + 1 then
                self.safehouse:kickOutOfSafehouse(self.player)
            end
            self.safehouseUI:populateList()
            self:setVisible(false)
            self:removeFromUIManager()
            ISSafehouseAddPlayerUI.instance = nil
        end
    end
end



-- SEZIONE RICEZIONE INVITO

-- Salva un riferimento alla funzione originale
-- Sovrascrivi la funzione ReceiveSafehouseInvite
local function CustomReceiveSafehouseInvite(safehouse, host)
    if ISSafehouseUI.inviteDialogs[host] then
        if ISSafehouseUI.inviteDialogs[host]:isReallyVisible() then return end
        ISSafehouseUI.inviteDialogs[host] = nil
    end

    if not SafeHouse.hasSafehouse(getPlayer()) then
        -- Ottieni il nome del personaggio utilizzando getCharacterName
        local displayName = host
        if SandboxVars.PlayerTradeOptions.useCharacterName or SandboxVars.PlayerTradeOptions.noName then
            displayName = getCharacterName(host, host)
        end

        -- Crea il dialogo di invito utilizzando displayName
        local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - 175, getCore():getScreenHeight() / 2 - 75, 350, 150, getText("IGUI_SafehouseUI_Invitation", displayName), true, nil, ISSafehouseUI.onAnswerSafehouseInvite)
        modal:initialise()
        modal:addToUIManager()
        modal.safehouse = safehouse
        modal.host = host
        modal.moveWithMouse = true
        ISSafehouseUI.inviteDialogs[host] = modal
    end
end

-- Rimuovi l'evento originale e aggiungi il nostro
Events.OnGameBoot.Add(function()
    Events.ReceiveSafehouseInvite.Remove(ISSafehouseUI.ReceiveSafehouseInvite)
    Events.ReceiveSafehouseInvite.Add(CustomReceiveSafehouseInvite)
end)
