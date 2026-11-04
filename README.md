# MZ Visuals v1.0.0

Resource **standalone** para FiveM / MZ Framework. Perfis gráficos individuais, `/fps on|off|auto`, monitor de FPS e NUI local. **Não é um mod de texturas, NVE ou um controle de opções gráficas internas do GTA V**.

## Instalação

1. Extraia a pasta `mz_visuals` em `resources/[mz]/mz_visuals/` (não coloque ZIP dentro do diretório de resources).
2. Em `server.cfg`, depois dos recursos-base, adicione:

   ```cfg
   ensure mz_visuals
   ```

3. Reinicie o servidor ou execute `refresh` e `ensure mz_visuals` no console.
4. No FiveM, digite **`/graficos`** para abrir a interface.

Não requer vRP, SQL, Node, ox_lib, mz_core ou mz_settings. A configuração global é `config.lua`; cada jogador guarda suas preferências em **KVP local do cliente**. Se a MZ centralizar a configuração no futuro, crie um adaptador para `mz_settings` preservando esta responsabilidade.

## Comandos

| Comando | Ação |
|---|---|
| `/graficos` | Abre/fecha o painel de gráficos (bloqueia abertura se já houver outra NUI focada) |
| `/fps on` | Ativa temporariamente Batata e registra o perfil anterior |
| `/fps off` | Retorna ao perfil anterior quando ativado por `/fps on` |
| `/fps auto` | Seleciona o perfil Automático (Baixo ↔ Equilibrado ↔ Alto) |

A escolha por NUI é salva imediatamente; `fps on` é **temporário** (não persiste Batata no login, apenas a preferência anterior). Selecionar um novo perfil cancela o modo temporário.

## Perfis e limites

- **Original:** repõe os valores obtidos pelo `GetVisualSettingFloat()` quando este resource iniciou.
- **Batata:** diminui alguns efeitos visuais e ativa `SetReducePedModelBudget` / `SetReduceVehicleModelBudget` (se permitido no config). Não desativa pedestres, veículos, polícia ou animações.
- **Baixo:** efeitos mais discretos.
- **Equilibrado:** alterações leves para a maioria dos jogadores.
- **Alto / Ultra:** aumenta o brilho e alguns efeitos selecionados; pode piorar o FPS.
- **Automático:** sobe/desce um único perfil quando as médias de FPS se sustentam por várias janelas, com cooldown. Não detecta especificações do PC nem busca limiar garantido.
- **Personalizado:** seis controles: faróis, halos, bloom, luzes distantes, aparência da chuva e desfoque.

### Valores técnicos

Foram examinadas **1.092 linhas numéricas** da referência `vrp_visualsettings.zip` (1.087 chaves únicas), mas o resource usa só **13 parâmetros em allowlist**. Nenhuma configuração é aplicada às cegas. Cada parâmetro é lido da configuração já carregada do cliente por `GetVisualSettingFloat()`, protegido com `pcall`. Se ausente/incompatível, é **ignorado**. Valores novos são multiplicadores conservadores em relação à medição inicial; posição `50` significa o mesmo valor observado inicialmente. **`weather.CycleDuration` jamais é aplicado.**

**AVISO:** `SetVisualSettingFloat` muda o valor temporariamente para o cliente e a engine FiveM gerencia overrides por chave. Não execute simultaneamente `mz_visuals` com outro resource que sobrescreva as mesmas entradas de visualsettings: há risco de conflito e a restauração pode não corresponder ao resultado do outro resource. Os valores originais são os observados ao **iniciar** `mz_visuals`, não necessariamente os valores de fábrica do GTA em presença de outros mods.

**FPS:** não existe como prometer "+40 FPS". FPS ON só muda alguns efeitos/streaming budgets, e dependendo do gargalo pode não aumentar o FPS. O contador é uma aproximação de frames observados no runtime por janela de 2 s. A comparação antes/depois não é um benchmark: se o jogador mudou de região ou olhou para outro lado, a cena também mudou.

**Não controlamos:** texturas, resolução, MSAA, sombras globais do menu GTA, VRAM, geração de NPCs por `mz_population`, ocultação de jogadores/veículos, LOD de props relevantes, clima sincronizado, efeitos policiais ou timecycle de outros scripts.

## Configuração (`config.lua`)

- `Config.DefaultProfile = 'equilibrado'` — perfil aplicado ao cliente ao iniciar.
- `Config.Locale = 'pt-BR'` ou `'en-US'` — idioma **único para todo o servidor**.
- `Config.AllowAutoMode` / `Config.AllowPlayersToCustomize` — permite recursos.
- `Config.AllowStreamingBudgetReduction` — habilita modo reduzido de orçamento de modelos em Batata.
- `Config.AllowedProfiles` — allowlist dos presets disponíveis na interface/comandos.
- `Config.ShowFpsOverlayByDefault` / `Config.AllowFpsOverlay` — contador opcional.
- `Config.Auto` — limiares, quantidade de amostras e cooldown do perfil automático.

Se quiser zero overrides automáticos na entrada do jogador, use `Config.DefaultProfile = 'original'`.

## Integrações MZ

- **`mz_core`**: não modificado. O sistema gráfico não é owner do player lifecycle.
- **`mz_settings`**: nenhum acesso direto presumido. A configuração global funciona independentemente.
- **`mz_hud`**: não modificado. Um contador separado é renderizado por NUI apenas quando ativado. Para HUD único, consumir `exports['mz_visuals']:GetAverageFps()`.
- **NUI de telefone/inventário**: `IsNuiFocused()` evita abrir o painel em cima de outra interface. Ao fechar libera apenas o foco adquirido pelo próprio `mz_visuals`.
- **`mz_banguard`, `mz_police`, `mz_population`**: nenhum evento, entidade, persistência ou configuração alterada.

### Exports client-side

```lua
local profile, effectiveProfile = exports['mz_visuals']:GetVisualProfile()
local avgFps = exports['mz_visuals']:GetAverageFps()
exports['mz_visuals']:OpenGraphicsMenu()
```

## Testes / homologação

Smoke offline: `python tests/test_lua_offline.py` (liblua5.4 disponível no ambiente); `python tests/test_ui.py` (Playwright/Chromium). No FiveM, execute este roteiro:

1. Inicie `mz_visuals` com o jogo aberto e use `/graficos`; verifique perfis e desfoque visual sob dia/noite/chuva.
2. Teste `/fps on` → `/fps off` e confira restauração do perfil e preferências após reconexão.
3. Teste os sliders, modo Original, modo Automático após um período de FPS persistentemente baixo/alto.
4. Abra inventário ou telefone e tente `/graficos` (não deve roubar o foco).
5. Alterne `/graficos` enquanto no carro e com HUD/telefone; confirme ESC e ausência de travas.
6. Execute `restart mz_visuals` com Batata ativo; confirme que as alterações do resource são removidas e o foco foi liberado.
7. Compare FPS com o mesmo local/câmera/clima antes/depois e procure erros F8.
8. Verifique em GTA Enhanced/Legacy usados pela cidade e em builds de cliente suportados.

**Status**: código e NUI testados offline, **não homologado em runtime FiveM**. Não instalar automaticamente em produção sem fazer estes testes.

## Créditos técnicos e referência

Referência fornecida pelo usuário: `vrp_visualsettings.zip`, visualsettings.dat antigo. O parser vRP e o arquivo original **não** foram copiados; foram adaptadas apenas as ideias e os nomes de 13 parâmetros visuais, com controles/restore novos.

FiveM native `SET_VISUAL_SETTING_FLOAT` e `GET_VISUAL_SETTING_FLOAT` (fonte oficial): https://github.com/citizenfx/fivem/blob/master/code/components/extra-natives-five/src/VisualSettingsNatives.cpp

NUI: https://docs.fivem.net/docs/scripting-manual/nui-development/nui-callbacks/
