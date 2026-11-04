local resource = GetCurrentResourceName()
local kvpKey = 'mz_visuals:v1:preferences'
local uiOpen = false
local fps = 0
local fpsHistory = {}
local fpsHistoryMax = 30
local lowSamples, highSamples = 0, 0
local lastAutoChange = 0
local boostReferenceFps, boostAfterFps = nil, nil
local boostStart = 0

local state = {
    profile = Config.DefaultProfile,
    custom = MZVisuals.CopySettings(MZVisuals.Presets.equilibrado.settings),
    overlay = Config.ShowFpsOverlayByDefault,
    effectiveProfile = Config.DefaultProfile,
    boost = false,
    boostPrevious = nil
}

local function allowed(profile)
    return MZVisuals.IsProfileAllowed(profile)
end

local function defaultProfile()
    return allowed(Config.DefaultProfile) and Config.DefaultProfile or 'original'
end

local function averageLast(n)
    local sum, count = 0, 0
    for i = #fpsHistory, math.max(1, #fpsHistory - n + 1), -1 do
        sum = sum + fpsHistory[i]
        count = count + 1
    end
    return count > 0 and math.floor(sum / count + 0.5) or 0
end

local function loadPreferences()
    state.profile = defaultProfile()
    if not Config.AllowFpsOverlay then state.overlay = false end
    local raw = GetResourceKvpString(kvpKey)
    if not raw or #raw > 4096 then return end
    local ok, saved = pcall(json.decode, raw)
    if not ok or type(saved) ~= 'table' then return end
    if allowed(saved.profile) then state.profile = saved.profile end
    local custom = MZVisuals.ValidateSettings(saved.custom)
    if custom then state.custom = custom end
    if Config.AllowFpsOverlay and type(saved.overlay) == 'boolean' then state.overlay = saved.overlay end
    if allowed(saved.effectiveProfile) and saved.effectiveProfile ~= 'auto' and saved.effectiveProfile ~= 'custom' then
        state.effectiveProfile = saved.effectiveProfile
    end
end

local function savePreferences()
    local ok, payload = pcall(json.encode, {
        profile = (state.boost and state.boostPrevious) or state.profile,
        custom = state.custom,
        overlay = state.overlay,
        effectiveProfile = state.effectiveProfile
    })
    if ok and type(payload) == 'string' then SetResourceKvp(kvpKey, payload) end
end

local function effectiveSettings()
    local id = state.profile == 'auto' and state.effectiveProfile or state.profile
    if id == 'custom' then return state.custom end
    local preset = MZVisuals.Presets[id]
    return preset and preset.settings or MZVisuals.Presets.equilibrado.settings
end

local function apply()
    local id = state.profile == 'auto' and state.effectiveProfile or state.profile
    if id ~= 'original' and id ~= 'custom' and not allowed(id) then id = defaultProfile() end
    MZVisualsEngine.Apply(id, effectiveSettings())
end

local function snapshots()
    local list = {}
    for _, id in ipairs(MZVisuals.Order) do
        if allowed(id) then
            local p = MZVisuals.Presets[id]
            list[#list + 1] = { id = id, label = p.label, description = p.description, icon = p.icon }
        end
    end
    local controls = {}
    for _, key in ipairs(MZVisuals.ControlOrder) do
        local c = Config.Controls[key]
        controls[#controls + 1] = { id = key, label = c.label, description = c.description, min = c.min, max = c.max }
    end
    local language = MZVisuals.GetLocale()
    for _, entry in ipairs(list) do
        local translation = language.profiles[entry.id]
        if translation then entry.label, entry.description = translation[1], translation[2] end
    end
    for _, entry in ipairs(controls) do
        local translation = language.controls[entry.id]
        if translation then entry.label, entry.description = translation[1], translation[2] end
    end
    return list, controls
end

local function buildState()
    local profiles, controls = snapshots()
    local baseline = MZVisualsEngine.Diagnostics()
    return {
        profile = state.profile,
        locale = MZVisuals.Locales[Config.Locale] and Config.Locale or 'pt-BR',
        effectiveProfile = state.effectiveProfile,
        boost = state.boost,
        overlay = state.overlay,
        settings = effectiveSettings(),
        profiles = profiles,
        controls = controls,
        fps = fps,
        average = averageLast(10),
        boostBefore = boostReferenceFps,
        boostAfter = boostAfterFps,
        diagnostics = baseline,
        allowCustom = Config.AllowPlayersToCustomize,
        allowOverlay = Config.AllowFpsOverlay
    }
end

local function publishState()
    SendNUIMessage({ action = 'state', data = buildState() })
end

local function notify(message)
    print(('[mz_visuals] %s'):format(message))
    TriggerEvent('chat:addMessage', { color = { 95, 205, 235 }, args = { 'MZ Visuals', message } })
end

local function closeUi()
    if not uiOpen then return end
    uiOpen = false
    SendNUIMessage({ action = 'visibility', open = false })
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end

local function openUi()
    if uiOpen then return end
    if IsNuiFocused() then
        notify(MZVisuals.GetLocale().messages.menuBusy)
        return
    end
    uiOpen = true
    SetNuiFocusKeepInput(false)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'visibility', open = true })
    publishState()
end

local function chooseProfile(id, isBoost)
    if not allowed(id) then return false end
    if isBoost then
        if not state.boost then
            state.boostPrevious = state.profile
            boostReferenceFps = #fpsHistory >= 3 and averageLast(5) or nil
            boostAfterFps = nil
            boostStart = GetGameTimer()
        end
        state.boost = true
    else
        state.boost = false
        state.boostPrevious = nil
        boostReferenceFps, boostAfterFps = nil, nil
    end
    state.profile = id
    if id == 'auto' then
        local initial = Config.Auto.initialProfile
        if not allowed(initial) then initial = 'equilibrado' end
        if not allowed(initial) then initial = 'baixo' end
        state.effectiveProfile = allowed(initial) and initial or defaultProfile()
        lowSamples, highSamples = 0, 0
        lastAutoChange = GetGameTimer()
    else
        state.effectiveProfile = id
    end
    apply()
    savePreferences()
    publishState()
    return true
end

local function disableBoost()
    if not state.boost then return false end
    local previous = state.boostPrevious
    state.boost = false
    state.boostPrevious = nil
    boostReferenceFps, boostAfterFps = nil, nil
    if not allowed(previous) then previous = defaultProfile() end
    return chooseProfile(previous, false)
end

local function setCustom(input)
    if not allowed('custom') then return false end
    local valid = MZVisuals.ValidateSettings(input)
    if not valid then return false end
    state.custom = valid
    return chooseProfile('custom', false)
end

local function toggleOverlay(enabled)
    if not Config.AllowFpsOverlay or type(enabled) ~= 'boolean' then return false end
    state.overlay = enabled
    savePreferences()
    publishState()
    return true
end

RegisterCommand('graficos', function()
    if uiOpen then closeUi() else openUi() end
end, false)

RegisterCommand('fps', function(_, args)
    local action = type(args[1]) == 'string' and args[1]:lower() or ''
    if action == 'on' then
        if chooseProfile('batata', true) then
            notify(MZVisuals.GetLocale().messages.boostOn)
        else
            notify(MZVisuals.GetLocale().messages.boostBlocked)
        end
    elseif action == 'off' then
        if disableBoost() then
            notify(MZVisuals.GetLocale().messages.boostOff)
        else
            notify(MZVisuals.GetLocale().messages.boostNotOn)
        end
    elseif action == 'auto' then
        if chooseProfile('auto', false) then
            notify(MZVisuals.GetLocale().messages.autoOn)
        else
            notify(MZVisuals.GetLocale().messages.autoBlocked)
        end
    else
        notify(MZVisuals.GetLocale().messages.help)
    end
end, false)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb({ ok = true })
end)

RegisterNUICallback('selectPreset', function(data, cb)
    if not uiOpen then
        cb({ ok = false, error = 'menu_closed' }); return
    end
    local id = type(data) == 'table' and data.id or nil
    local ok = id ~= nil and chooseProfile(id, false)
    cb({ ok = ok, state = ok and buildState() or nil })
end)

RegisterNUICallback('updateSettings', function(data, cb)
    if not uiOpen then
        cb({ ok = false, error = 'menu_closed' }); return
    end
    local ok = setCustom(type(data) == 'table' and data.settings or nil)
    cb({ ok = ok, state = ok and buildState() or nil })
end)

RegisterNUICallback('toggleOverlay', function(data, cb)
    if not uiOpen then
        cb({ ok = false, error = 'menu_closed' }); return
    end
    local ok = toggleOverlay(type(data) == 'table' and data.value or nil)
    cb({ ok = ok, state = ok and buildState() or nil })
end)

RegisterNUICallback('restoreDefaults', function(_, cb)
    if not uiOpen then
        cb({ ok = false, error = 'menu_closed' }); return
    end
    local ok = chooseProfile('original', false)
    cb({ ok = ok, state = ok and buildState() or nil })
end)

local function maybeAdjustAuto()
    if state.profile ~= 'auto' or not Config.AllowAutoMode or uiOpen or IsPauseMenuActive() or IsNuiFocused() then
        lowSamples, highSamples = 0, 0
        return
    end
    if fps < 1 then return end
    if fps < Config.Auto.lowFps then
        lowSamples, highSamples = lowSamples + 1, 0
    elseif fps > Config.Auto.highFps then
        highSamples, lowSamples = highSamples + 1, 0
    else
        lowSamples, highSamples = 0, 0
    end
    if GetGameTimer() - lastAutoChange < Config.Auto.cooldownMs then return end

    local ladder = Config.Auto.ladder
    local index = 1
    for i, id in ipairs(ladder) do
        if id == state.effectiveProfile then
            index = i; break
        end
    end
    local nextId = nil
    if lowSamples >= Config.Auto.downSamples then
        for i = index - 1, 1, -1 do if allowed(ladder[i]) then
                nextId = ladder[i]; break
            end end
    elseif highSamples >= Config.Auto.upSamples then
        for i = index + 1, #ladder do if allowed(ladder[i]) then
                nextId = ladder[i]; break
            end end
    end
    if nextId then
        state.effectiveProfile = nextId
        lastAutoChange = GetGameTimer()
        lowSamples, highSamples = 0, 0
        apply()
        savePreferences()
        publishState()
    end
end

CreateThread(function()
    loadPreferences()

    -- So aplica depois do jogador estar no mundo e o cliente ter carregado visualsettings.
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    Wait(3000)

    if state.profile == 'auto' then
        local restored = state.effectiveProfile
        local found = false
        for _, id in ipairs(Config.Auto.ladder) do if id == restored then
                found = true; break
            end end
        state.effectiveProfile = found and allowed(restored) and restored or Config.Auto.initialProfile
    end

    apply()
    SendNUIMessage({ action = 'visibility', open = false })
    publishState()
end)

CreateThread(function()
    local windowStarted = GetGameTimer()
    local frames = 0
    while true do
        Wait(0)
        frames = frames + 1
        local now = GetGameTimer()
        if now < windowStarted then
            windowStarted = now; frames = 0
        end
        if now - windowStarted >= Config.Auto.sampleWindowMs then
            local duration = now - windowStarted
            fps = duration > 0 and math.floor((frames * 1000 / duration) + 0.5) or 0
            windowStarted, frames = now, 0
            if not IsPauseMenuActive() and not IsNuiFocused() and fps > 0 then
                fpsHistory[#fpsHistory + 1] = fps
                if #fpsHistory > fpsHistoryMax then table.remove(fpsHistory, 1) end
                maybeAdjustAuto()
                if state.boost and not boostAfterFps and now - boostStart >= 14000 and #fpsHistory >= 5 then
                    boostAfterFps = averageLast(5)
                end
            end
            if uiOpen or state.overlay then
                SendNUIMessage({
                    action = 'stats',
                    data = {
                        fps = fps,
                        average = averageLast(10),
                        boostBefore = boostReferenceFps,
                        boostAfter = boostAfterFps,
                        overlay = state.overlay,
                        profile = state.profile,
                        effectiveProfile = state.effectiveProfile
                    }
                })
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= resource then return end
    closeUi()
    MZVisualsEngine.Restore()
end)

exports('GetVisualProfile', function()
    return state.profile, state.effectiveProfile
end)

exports('GetAverageFps', function()
    return averageLast(10)
end)

exports('OpenGraphicsMenu', openUi)
