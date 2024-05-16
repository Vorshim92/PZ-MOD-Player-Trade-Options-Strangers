local function getCharacterName(player)
    if SandboxVars.PlayerTradeOptions.noName then
        return "Viandante" -- Restituisce una stringa vuota se l'opzione noName è abilitata
    else
        return player:getDescriptor():getForename() .. " " .. player:getDescriptor():getSurname();
    end
end

local ISTradingUIHistorical_prerender = ISTradingUIHistorical.prerender
function ISTradingUIHistorical:prerender()
    if SandboxVars.PlayerTradeOptions.useCharacterName then
        local z = 10;
        local splitPoint = 100;
        local x = 10;
        self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
        self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
        local otherPlayerName = getCharacterName(self.otherPlayer)
        self:drawText(getText("IGUI_ISTradingUIHistorical_Title", otherPlayerName), self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, getText("IGUI_ISTradingUIHistorical_Title", otherPlayerName)) / 2), z, 1,1,1,1, UIFont.Medium);
    end    
    if not SandboxVars.PlayerTradeOptions.useCharacterName and not SandboxVars.PlayerTradeOptions.noName then
        ISTradingUIHistorical_prerender(self)
    end

end
