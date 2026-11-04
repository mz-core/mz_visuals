MZVisuals = MZVisuals or {}

-- Normal / original aplica os VALORES LIDOS do cliente, nao valores copiados do ZIP antigo.
MZVisuals.Presets = {
    original = {
        label = 'Original', description = 'Restaura os valores capturados no inicio.', icon = 'rotate-ccw',
        settings = { headlights = 50, coronas = 50, bloom = 50, distantLights = 50, rainLook = 50, motionBlur = 50 }
    },
    batata = {
        label = 'Batata', description = 'Foco em estabilidade e modelos de streaming mais leves.', icon = 'zap',
        settings = { headlights = 30, coronas = 12, bloom = 0, distantLights = 20, rainLook = 35, motionBlur = 0 }
    },
    baixo = {
        label = 'Baixo', description = 'Efeitos discretos para computadores modestos.', icon = 'gauge',
        settings = { headlights = 38, coronas = 30, bloom = 15, distantLights = 32, rainLook = 40, motionBlur = 0 }
    },
    equilibrado = {
        label = 'Equilibrado', description = 'Visual limpo com boa legibilidade.', icon = 'sliders',
        settings = { headlights = 50, coronas = 45, bloom = 45, distantLights = 48, rainLook = 50, motionBlur = 40 }
    },
    alto = {
        label = 'Alto', description = 'Luzes mais elaboradas e iluminação aprimorada.', icon = 'sun',
        settings = { headlights = 65, coronas = 70, bloom = 65, distantLights = 68, rainLook = 65, motionBlur = 48 }
    },
    ultra = {
        label = 'Ultra', description = 'Efeitos visuais realçados, sem alterar texturas ou resolução.', icon = 'sparkles',
        settings = { headlights = 80, coronas = 86, bloom = 78, distantLights = 80, rainLook = 75, motionBlur = 55 }
    },
    auto = {
        label = 'Automático', description = 'Adapta um nível por vez conforme a média de FPS.', icon = 'activity'
    },
    custom = {
        label = 'Personalizado', description = 'Valores individuais dos controles.', icon = 'settings-2'
    }
}

MZVisuals.Order = { 'original', 'batata', 'baixo', 'equilibrado', 'alto', 'ultra', 'auto', 'custom' }
MZVisuals.ControlOrder = { 'headlights', 'coronas', 'bloom', 'distantLights', 'rainLook', 'motionBlur' }

function MZVisuals.IsProfileAllowed(profile)
    return type(profile) == 'string' and MZVisuals.Presets[profile] ~= nil
        and Config.AllowedProfiles[profile] == true
        and (profile ~= 'auto' or Config.AllowAutoMode)
        and (profile ~= 'custom' or Config.AllowPlayersToCustomize)
end

function MZVisuals.ValidateSettings(input)
    if type(input) ~= 'table' then return nil end
    local valid = {}
    for _, key in ipairs(MZVisuals.ControlOrder) do
        local spec = Config.Controls[key]
        local value = tonumber(input[key])
        if value == nil or value ~= value or value == math.huge or value == -math.huge then return nil end
        valid[key] = math.floor(math.max(spec.min, math.min(spec.max, value)) + 0.5)
    end
    return valid
end

function MZVisuals.CopySettings(settings)
    local values = {}
    for _, key in ipairs(MZVisuals.ControlOrder) do values[key] = settings[key] end
    return values
end
