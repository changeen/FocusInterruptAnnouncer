-- FocusInterruptAnnouncer.lua
local addonName = "FocusInterruptAnnouncer"
local FIA = {}

-- 默认配置
FIA.defaults = {
    enabled = true,
    customMessage = "我焦点断 {mark}{name}",
    cooldown = 2,
}

-- 标记名称映射
FIA.markNames = {
    [1] = "{星形}",
    [2] = "{圆形}",
    [3] = "{菱形}",
    [4] = "{三角}",
    [5] = "{月亮}",
    [6] = "{方块}",
    [7] = "{十字}",
    [8] = "{骷髅}",
}

-- 状态变量
FIA.lastAnnounceTime = 0
FIA.db = FIA.defaults

-- ========== 核心喊话函数 ==========

local function PerformAnnouncement()
    if not FIA.db.enabled then return end
    if not UnitExists("focus") then return end
    
    -- 检查冷却时间
    local currentTime = GetTime()
    if currentTime - FIA.lastAnnounceTime < FIA.db.cooldown then
        return
    end
    
    -- 检查是否为敌方
    if not UnitIsEnemy("player", "focus") then return end
    
    -- 获取焦点信息
    local focusName = UnitName("focus") or "未知目标"
    
    -- 获取团队标记
    local raidTargetIndex = GetRaidTargetIndex("focus")
    local markText = ""
    if raidTargetIndex and FIA.markNames[raidTargetIndex] then
        markText = FIA.markNames[raidTargetIndex] .. " "
    end
    
    -- 构建消息
    local message = FIA.db.customMessage
        :gsub("{name}", focusName)
        :gsub("{mark}", markText)
    
    -- 发送消息
    SendChatMessage(message, "SAY")
    FIA.lastAnnounceTime = currentTime
end

-- ========== 事件处理 ==========

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_FOCUS_CHANGED" then
        PerformAnnouncement()
    end
end)

-- ========== 配置面板（修正版） ==========

local function CreateConfigPanel()
    local panel = CreateFrame("Frame", "FocusInterruptConfig", UIParent)
    panel.name = "焦点打断喊话"
    panel:SetSize(380, 260)
    panel:SetPoint("CENTER")
    
    -- 背景
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetColorTexture(0, 0, 0, 0.9)
    
    -- 边框
    local border = panel:CreateTexture(nil, "BORDER")
    border:SetColorTexture(0.2, 0.2, 0.2, 1)
    border:SetPoint("TOPLEFT", panel, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 1, -1)
    
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- 标题栏
    local titleBar = CreateFrame("Frame", nil, panel)
    titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -2)
    titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
    titleBar:SetHeight(28)
    
    local titleBarBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBarBg:SetAllPoints(titleBar)
    titleBarBg:SetColorTexture(0.1, 0.1, 0.2, 1)
    
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetText("焦点打断喊话设置")
    titleText:SetTextColor(1, 0.8, 0)
    
    -- 关闭按钮
    local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -5, 0)
    closeButton:SetSize(24, 24)
    closeButton:SetScript("OnClick", function() panel:Hide() end)
    
    -- 内容区域
    local contentFrame = CreateFrame("Frame", nil, panel)
    contentFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 15, -15)
    contentFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -15, 50)
    
    local currentY = 0
    
    -- 启用插件
    local enabledCB = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
    enabledCB:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, currentY)
    enabledCB.Text:SetText("启用插件")
    enabledCB:SetChecked(FIA.db.enabled)
    enabledCB:SetScript("OnClick", function(self)
        FIA.db.enabled = self:GetChecked()
    end)
    
    currentY = currentY - 35
    
    -- 冷却时间设置
    local cooldownLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cooldownLabel:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, currentY)
    cooldownLabel:SetText("喊话冷却时间:")
    
    currentY = currentY - 25
    
    local cooldownSlider = CreateFrame("Slider", nil, contentFrame, "OptionsSliderTemplate")
    cooldownSlider:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, currentY)
    cooldownSlider:SetWidth(200)
    cooldownSlider:SetHeight(20)
    cooldownSlider:SetMinMaxValues(0.5, 10)
    cooldownSlider:SetValue(FIA.db.cooldown)
    cooldownSlider:SetValueStep(0.5)
    cooldownSlider.Low:SetText("0.5")
    cooldownSlider.High:SetText("10")
    
    local function UpdateCooldownText()
        cooldownSlider.Text:SetText(string.format("%.1f秒", FIA.db.cooldown))
    end
    
    cooldownSlider:SetScript("OnValueChanged", function(self, value)
        FIA.db.cooldown = value
        UpdateCooldownText()
    end)
    
    UpdateCooldownText()
    
    currentY = currentY - 40
    
    -- 自定义消息
    local messageLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageLabel:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, currentY)
    messageLabel:SetText("自定义喊话消息:")
    
    currentY = currentY - 25
    
    local messageBox = CreateFrame("EditBox", nil, contentFrame, "InputBoxTemplate")
    messageBox:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, currentY)
    messageBox:SetSize(340, 20)
    messageBox:SetText(FIA.db.customMessage)
    messageBox:SetAutoFocus(false)
    messageBox:SetScript("OnEnterPressed", function(self)
        FIA.db.customMessage = self:GetText()
        self:ClearFocus()
    end)
    messageBox:SetScript("OnEscapePressed", function(self)
        self:SetText(FIA.db.customMessage)
        self:ClearFocus()
    end)
    
    currentY = currentY - 30
    
    -- 消息提示
    local messageHint = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    messageHint:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, currentY)
    messageHint:SetText("可用变量: {name}=目标名, {mark}=团队标记")
    messageHint:SetTextColor(0.8, 0.8, 0.8)
    
    -- 底部按钮区域
    local buttonFrame = CreateFrame("Frame", nil, panel)
    buttonFrame:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 15, 15)
    buttonFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -15, 15)
    buttonFrame:SetHeight(30)
    
    -- 重置按钮（左侧）
    local resetButton = CreateFrame("Button", nil, buttonFrame, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", buttonFrame, "LEFT", 0, 0)
    resetButton:SetSize(80, 25)
    resetButton:SetText("重置")
    resetButton:SetScript("OnClick", function()
        -- 重置为默认设置
        for k, v in pairs(FIA.defaults) do
            FIA.db[k] = v
        end
        
        -- 更新界面
        enabledCB:SetChecked(FIA.db.enabled)
        messageBox:SetText(FIA.db.customMessage)
        cooldownSlider:SetValue(FIA.db.cooldown)
        UpdateCooldownText()
        
        print("|cFF00FF00焦点打断:|r 已重置为默认设置")
    end)
    
    -- 保存按钮（右侧）
    local saveButton = CreateFrame("Button", nil, buttonFrame, "UIPanelButtonTemplate")
    saveButton:SetPoint("RIGHT", buttonFrame, "RIGHT", 0, 0)
    saveButton:SetSize(80, 25)
    saveButton:SetText("保存")
    saveButton:SetScript("OnClick", function()
        panel:Hide()
        print("|cFF00FF00焦点打断:|r 设置已保存")
    end)
    
    panel:Hide()
    return panel
end

-- 显示配置面板
local function ShowConfigPanel()
    if not FIA.configPanel then
        FIA.configPanel = CreateConfigPanel()
    end
    
    if FIA.configPanel:IsShown() then
        FIA.configPanel:Hide()
    else
        FIA.configPanel:Show()
        FIA.configPanel:Raise()
    end
end

-- ========== 命令处理 ==========

SLASH_FOCUSINTERRUPT1 = "/fia"
SlashCmdList["FOCUSINTERRUPT"] = function(msg)
    if msg == "config" or msg == "" then
        ShowConfigPanel()
    elseif msg == "toggle" then
        FIA.db.enabled = not FIA.db.enabled
        print("|cFF00FF00焦点打断:|r " .. (FIA.db.enabled and "已启用" or "已禁用"))
    else
        print("|cFF00FF00=== 焦点打断喊话插件 ===|r")
        print("|cFFFF8000/fia|r - 打开设置面板")
        print("|cFFFF8000/fia toggle|r - 启用/禁用插件")
    end
end

-- ========== 插件加载 ==========

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        print("|cFF00FF00焦点打断喊话插件已加载。输入 /fia 打开设置。|r")
        self:UnregisterAllEvents()
    end
end)