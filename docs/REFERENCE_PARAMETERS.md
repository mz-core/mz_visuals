# Referência visualsettings.dat original

O ZIP anexado continha `visualsettings.dat` com 1.092 entradas numéricas / 1.087 nomes únicos, `client.lua` com `/showvisual` e `fxmanifest.lua` com dependência vRP. Não foi copiado para produção.

Critérios da whitelist: parâmetros de tipo float, visualmente reversíveis, sem mexer em densidade de entidades, visibilidade policial, cenário, desativação de efeitos de gameplay ou limites de streaming que poderiam quebrar o mundo.

- Faróis: `car.headlights.global.HeadlightIntensityMult`, `car.headlights.global.HeadlightDistMult`, `car.headlights.fullbeam.CoronaIntensityMult`
- Coronas: `misc.coronas.intensityScaleGlobal`, `misc.coronas.sizeScaleGlobal`
- Bloom: `bloom.blurblendmult.large`, `bloom.blurblendmult.med`, `bloom.blurblendmult.small`
- Cidade: `distantlights.size`, `distantlights.sizeReflections`
- Chuva: `rain.diffuse`, `rain.ambient`
- Desfoque: `defaultmotionblur.strength`

A função `GET_VISUAL_SETTING_FLOAT` pode não encontrar todas as chaves em todas as builds. Falha é isolada por `pcall`, sem aplicar chaves inválidas. Mudanças são temporárias e locais. `rain.NumberParticles` (int/sem garantia de runtime) e `weather.CycleDuration` (risco conhecido de crash) foram excluídos.
