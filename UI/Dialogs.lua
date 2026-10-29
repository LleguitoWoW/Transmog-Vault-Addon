local addon, ns = ...

-- Dialogos Blizzard reutilizables: URL de Wowhead, pedir nombre, confirmar.

StaticPopupDialogs["TRANSMOGVAULT_URL"] = {
    text = "Wowhead",
    button1 = CLOSE,
    timeout = 0, whileDead = true, hideOnEscape = true,
    hasEditBox = true, hasWideEditBox = true,
    preferredIndex = 3,
    OnShow = function(self)
        local eb = self.wideEditBox or self.editBox
        eb:SetText("https://www.wowhead.com/wotlk/item=" .. tostring(self.data))
        eb:HighlightText()
        eb:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

function ns.ShowURL(itemId)
    StaticPopup_Show("TRANSMOGVAULT_URL", nil, nil, itemId)
end

StaticPopupDialogs["TRANSMOGVAULT_NAME"] = {
    text = "%s",
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0, whileDead = true, hideOnEscape = true,
    hasEditBox = true,
    preferredIndex = 3,
    OnShow = function(self)
        self.editBox:SetText(self.data.default or "")
        self.editBox:HighlightText()
        self.editBox:SetFocus()
    end,
    OnAccept = function(self)
        local name = strtrim(self.editBox:GetText() or "")
        if name ~= "" then self.data.callback(name) end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = strtrim(self:GetText() or "")
        if name ~= "" then parent.data.callback(name) end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

function ns.PromptName(text, default, callback)
    StaticPopup_Show("TRANSMOGVAULT_NAME", text, nil, { default = default, callback = callback })
end

StaticPopupDialogs["TRANSMOGVAULT_CONFIRM"] = {
    text = "%s",
    button1 = YES,
    button2 = NO,
    timeout = 0, whileDead = true, hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(self) self.data.callback() end,
}

function ns.Confirm(text, callback)
    StaticPopup_Show("TRANSMOGVAULT_CONFIRM", text, nil, { callback = callback })
end

-- Exportar: muestra un texto para copiar con Ctrl+C
StaticPopupDialogs["TRANSMOGVAULT_EXPORT"] = {
    text = "%s",
    button1 = CLOSE,
    timeout = 0, whileDead = true, hideOnEscape = true,
    hasEditBox = true, hasWideEditBox = true, maxLetters = 600,
    preferredIndex = 3,
    OnShow = function(self)
        local eb = self.wideEditBox or self.editBox
        eb:SetText(self.data)
        eb:HighlightText()
        eb:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
}

function ns.ShowExport(title, text)
    StaticPopup_Show("TRANSMOGVAULT_EXPORT", title, nil, text)
end

-- Importar: pegar un texto y devolverlo al callback
StaticPopupDialogs["TRANSMOGVAULT_IMPORT"] = {
    text = "%s",
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0, whileDead = true, hideOnEscape = true,
    hasEditBox = true, hasWideEditBox = true, maxLetters = 600,
    preferredIndex = 3,
    OnShow = function(self)
        local eb = self.wideEditBox or self.editBox
        eb:SetText("")
        eb:SetFocus()
    end,
    OnAccept = function(self)
        local eb = self.wideEditBox or self.editBox
        self.data.callback(strtrim(eb:GetText() or ""))
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        parent.data.callback(strtrim(self:GetText() or ""))
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

function ns.PromptImport(title, callback)
    StaticPopup_Show("TRANSMOGVAULT_IMPORT", title, nil, { callback = callback })
end
