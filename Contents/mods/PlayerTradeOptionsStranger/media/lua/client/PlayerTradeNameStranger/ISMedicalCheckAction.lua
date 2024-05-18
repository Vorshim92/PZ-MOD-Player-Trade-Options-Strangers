local ISMedicalCheckAction_perform_ext = ISMedicalCheckAction.perform

function ISMedicalCheckAction:perform()
    local playerNum = self.character:getPlayerNum()
    local x = getPlayerScreenLeft(playerNum) + 70
    local y = getPlayerScreenTop(playerNum) + 50
    local healthPanel = nil
    local healthWindow = ISMedicalCheckAction.getHealthWindowForPlayer(self.otherPlayer)
    if healthWindow then
        healthPanel = healthWindow.nested
        healthWindow:addToUIManager()
        healthWindow:setVisible(true)
    else
        healthPanel = ISHealthPanel:new(self.otherPlayer, x, y, 400, 400)
        healthPanel:initialise()

        local title = getText("IGUI_health_playerHealth", self.otherPlayer:getDescriptor():getForename().." "..self.otherPlayer:getDescriptor():getSurname())
        if isClient() then
            title = getText("IGUI_health_playerHealth", self.otherPlayer:getUsername())
        end
        local wrap = healthPanel:wrapInCollapsableWindow(title)
        wrap:setResizable(false)
        wrap:addToUIManager()
        wrap.visibleTarget = self

        ISMedicalCheckAction.HealthWindows[self.otherPlayer] = wrap
    end

    healthPanel.doctorLevel = self.character:getPerkLevel(Perks.Doctor)
    healthPanel:setOtherPlayer(self.character)
    self.healthPanel = healthPanel  -- Salva il riferimento al pannello per accedervi in seguito

    if JoypadState.players[playerNum + 1] then
        JoypadState.players[playerNum + 1].focus = healthPanel
        updateJoypadFocus(JoypadState.players[playerNum + 1])
    end

    if self.otherPlayer then
        self.character:startReceivingBodyDamageUpdates(self.otherPlayer)
    end

    -- Esegui il codice della funzione originale
    ISBaseTimedAction.perform(self)

    -- Determina il nuovo titolo
    local newTitle
    if SandboxVars.PlayerTradeOptions.useCharacterName then 
        newTitle = getText("IGUI_health_playerHealth", self.otherPlayer:getDescriptor():getForename() .. " " .. self.otherPlayer:getDescriptor():getSurname())
    elseif SandboxVars.PlayerTradeOptions.noName then
        newTitle = getText("IGUI_health_playerHealth", " Viandante")
    else
        newTitle = getText("IGUI_health_playerHealth", self.otherPlayer:getUsername())
    end

    -- Aggiorna il titolo della finestra esistente o appena creata
    if healthWindow then
        healthWindow.title = newTitle
    elseif self.healthPanel:getParent() then
        self.healthPanel:getParent().title = newTitle
    else
        self.healthPanel.title = newTitle
    end
end
