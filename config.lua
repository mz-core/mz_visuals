-- MZ VISUALS - configuracao global do DONO DO SERVIDOR.
-- Nao e preciso alterar mz_core, mz_hud ou mz_settings para rodar.
Config = {}

Config.Debug = false
Config.Locale = 'pt-BR' -- idioma GLOBAL do servidor: pt-BR / en-US
Config.DefaultProfile = 'equilibrado'
Config.AllowPlayersToCustomize = true
Config.AllowAutoMode = true
Config.AllowStreamingBudgetReduction = true -- apenas perfis de desempenho; nao altera densidade de NPCs
Config.ShowFpsOverlayByDefault = false
Config.AllowFpsOverlay = true

-- Opcional: restringe os perfis disponiveis. Inclua 'original' para desfazer ajustes.
Config.AllowedProfiles = {
    original = true,
    batata = true,
    baixo = true,
    equilibrado = true,
    alto = true,
    ultra = true,
    auto = true,
    custom = true
}

-- Auto: muda um DEGRAU de cada vez, apenas apos varias janelas persistentes.
-- 2s por janela; 5 amostras consecutivas abaixo de 45 FPS para reduzir.
-- 10 amostras acima de 72 FPS para subir. Desligado enquanto NUI ou pause estiverem abertos.
Config.Auto = {
    sampleWindowMs = 2000,
    lowFps = 45,
    highFps = 72,
    downSamples = 5,
    upSamples = 10,
    cooldownMs = 45000,
    initialProfile = 'equilibrado',
    ladder = { 'baixo', 'equilibrado', 'alto' }
}

-- Alcances conservadores dos sliders; evitar valores extremos e efeitos competitivos.
Config.Controls = {
    headlights = { label = 'Faróis', min = 0, max = 100, default = 50, description = 'Intensidade e alcance suave dos faróis' },
    coronas = { label = 'Coronas', min = 0, max = 100, default = 50, description = 'Tamanho e brilho dos halos luminosos' },
    bloom = { label = 'Bloom', min = 0, max = 100, default = 50, description = 'Brilho difuso de luzes' },
    distantLights = { label = 'Luzes distantes', min = 0, max = 100, default = 50, description = 'Aparência de pontos de luz da cidade' },
    rainLook = { label = 'Visual da chuva', min = 0, max = 100, default = 50, description = 'Brilho aparente da chuva (não reduz partículas)' },
    motionBlur = { label = 'Desfoque', min = 0, max = 100, default = 50, description = 'Intensidade de desfoque de movimento' }
}

-- O sistema limita sobreposicoes com outros recursos: jamais aplica timecycle,
-- clima, alteracao de densidade populacional, escondimento de entidades ou efeitos policiais.
