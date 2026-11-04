-- Unico owner das alteracoes de visualsettings.dat efetuadas por mz_visuals.
MZVisualsEngine = {}

local active = {}
local lastApplied = {}
local baseline = {}
local invalid = {}
local baselineCaptured = false
local budgetReduced = false

local mappings = {
    { key = 'car.headlights.global.HeadlightIntensityMult', control = 'headlights',    low = 0.82, high = 1.28 },
    { key = 'car.headlights.global.HeadlightDistMult',      control = 'headlights',    low = 0.94, high = 1.12 },
    { key = 'car.headlights.fullbeam.CoronaIntensityMult',  control = 'headlights',    low = 0.88, high = 1.25 },
    { key = 'misc.coronas.intensityScaleGlobal',            control = 'coronas',       low = 0.68, high = 1.30 },
    { key = 'misc.coronas.sizeScaleGlobal',                 control = 'coronas',       low = 0.78, high = 1.15 },
    { key = 'bloom.blurblendmult.large',                    control = 'bloom',         low = 0.55, high = 1.32 },
    { key = 'bloom.blurblendmult.med',                      control = 'bloom',         low = 0.55, high = 1.30 },
    { key = 'bloom.blurblendmult.small',                    control = 'bloom',         low = 0.68, high = 1.20 },
    { key = 'distantlights.size',                           control = 'distantLights', low = 0.80, high = 1.20 },
    { key = 'distantlights.sizeReflections',                control = 'distantLights', low = 0.80, high = 1.20 },
    { key = 'rain.diffuse',                                 control = 'rainLook',      low = 0.85, high = 1.10 },
    { key = 'rain.ambient',                                 control = 'rainLook',      low = 0.85, high = 1.10 },
    { key = 'defaultmotionblur.strength',                   control = 'motionBlur',    low = 0.0,  high = 1.10 }
}

local function log(message)
    if Config.Debug then print(('[mz_visuals] %s'):format(message)) end
end

local function capture()
    if baselineCaptured then return end

    local captured, total = 0, 0
    local tempBaseline, tempInvalid = {}, {}

    for _, mapping in ipairs(mappings) do
        total = total + 1
        local ok, value = pcall(function()
            if type(GetVisualSettingFloat) ~= 'function' then return nil end
            return GetVisualSettingFloat(mapping.key)
        end)

        -- Baseline tem que ser positivo e finito. Zero ou negativo = jogo ainda carregando.
        if ok and type(value) == 'number' and value == value
            and value > 0 and value < 1000 then
            tempBaseline[mapping.key] = value
            captured = captured + 1
            log(('baseline OK %s = %.4f'):format(mapping.key, value))
        else
            tempInvalid[mapping.key] = true
            log(('baseline INVALIDO %s = %s (ignorado)'):format(mapping.key, tostring(value)))
        end
    end

    -- Exige pelo menos metade das chaves validas.
    if captured < (total / 2) then
        log(('capture() falhou: %d/%d validos. Tentando depois.'):format(captured, total))
        return
    end

    baseline = tempBaseline
    invalid = tempInvalid
    baselineCaptured = true
    log(('capture() concluido: %d/%d chaves validas'):format(captured, total))
end

local function restoreVisuals()
    for key in pairs(active) do
        local value = baseline[key]
        if value ~= nil then
            pcall(SetVisualSettingFloat, key, value)
        end
    end
    active = {}
    lastApplied = {}
end

local function reduceBudget(enabled)
    if not Config.AllowStreamingBudgetReduction then enabled = false end
    if enabled == budgetReduced then return end
    budgetReduced = enabled
    if type(SetReducePedModelBudget) == 'function' then pcall(SetReducePedModelBudget, enabled) end
    if type(SetReduceVehicleModelBudget) == 'function' then pcall(SetReduceVehicleModelBudget, enabled) end
end

function MZVisualsEngine.Apply(profile, settings)
    capture()
    if not baselineCaptured then return end

    if profile == 'original' then
        restoreVisuals()
        reduceBudget(false)
        return
    end

    local valid = MZVisuals.ValidateSettings(settings)
    if not valid then return end

    for _, mapping in ipairs(mappings) do
        local initial = baseline[mapping.key]
        if initial ~= nil and not invalid[mapping.key] then
            local strength = (valid[mapping.control] - 50) / 50
            local multiplier = strength < 0
                and (1 + strength * (1 - mapping.low))
                or (1 + strength * (mapping.high - 1))
            local value = initial * multiplier

            -- CLAMP DE SEGURANCA: nunca deixa virar zero/negativo.
            if value < 0.05 then value = 0.05 end
            if value > 20 then value = 20 end

            if lastApplied[mapping.key] == nil or math.abs(lastApplied[mapping.key] - value) > 0.0001 then
                if Config.Debug then
                    log(('apply %s : baseline=%.4f mult=%.3f final=%.4f'):format(
                        mapping.key, initial, multiplier, value))
                end
                local ok, err = pcall(SetVisualSettingFloat, mapping.key, value)
                if ok then
                    active[mapping.key] = true
                    lastApplied[mapping.key] = value
                else
                    log(('ERRO ao aplicar %s: %s'):format(mapping.key, tostring(err)))
                end
            end
        end
    end
    reduceBudget(profile == 'batata')
end

function MZVisualsEngine.Restore()
    restoreVisuals()
    reduceBudget(false)
end

function MZVisualsEngine.Diagnostics()
    local available, skipped = 0, 0
    for _, map in ipairs(mappings) do
        if baseline[map.key] ~= nil then available = available + 1 else skipped = skipped + 1 end
    end
    return { available = available, skipped = skipped, captured = baselineCaptured }
end
