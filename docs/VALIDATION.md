# Registro de validação – mz_visuals v1.0.0

## Evidências offline

- Lua 5.4: sintaxe compilada (config, presets, locais, engine, client main).
- Fluxos smoke: argumentos inválidos, validação/limites dos sliders, keys não encontradas, modo de streaming reduzido e restauração das chaves lidas inicialmente.
- Mocks FiveM: comandos FPS on/off/auto, callback NUI de selecionar preset, customização, NUI focus/ESC logic local.
- JavaScript: `node --check web/app.js`.
- NUI Playwright headless: 1440×900 / 1920×1080 / 900×650 / 640×800; 8 presets, 6 sliders, restore, switch FPS, sem erros de execução nem scroll horizontal global.
- Evidências visuais: `docs/ui_profiles_preview.png`, `docs/ui_controls_preview.png`, `docs/ui_desktop_preview.png`, `docs/ui_small_preview.png`.

## Fora de escopo / ainda pendente

- Não foi possível executar `FXServer`, `Citizen.InvokeNative` ou a renderização do GTA V neste ambiente.
- O efeito real de cada uma das 13 chaves pode variar por build, hardware e outros resources. Cada chave indisponível é ignorada com segurança.
- O frame-rate não foi medido em runtime FiveM; não existe ganho de FPS comprovado até homologação em ambiente representativo.
- Alterações em outros resources (mz_core, mz_hud, mz_phone) não foram realizadas.
