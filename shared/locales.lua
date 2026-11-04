-- O idioma da interface eh escolhido pelo DONO em Config.Locale, nao por jogador.
MZVisuals.Locales = {
    ['pt-BR'] = {
        profiles = {}, controls = {},
        messages = {
            menuBusy = 'Feche o inventário/telefone/outro menu antes de abrir /graficos.',
            boostOn = 'FPS Boost ligado. Digite /fps off para restaurar o perfil anterior.',
            boostBlocked = 'O dono do servidor desabilitou o perfil Batata.',
            boostOff = 'FPS Boost desligado. Perfil anterior restaurado.',
            boostNotOn = 'O modo FPS Boost não estava ativado por /fps on.',
            autoOn = 'Ajuste automático de FPS ativado.',
            autoBlocked = 'O ajuste automático está desabilitado pelo servidor.',
            help = 'Comandos: /fps on, /fps off, /fps auto, /graficos'
        }
    },
    ['en-US'] = {
        profiles = {
            original={'Original','Restores the initial local game values.'},
            batata={'Potato','Favors stability with reduced streaming model budgets.'},
            baixo={'Low','Subtle effects for modest computers.'},
            equilibrado={'Balanced','Clean visuals with good readability.'},
            alto={'High','Richer lighting and ambient effects.'},
            ultra={'Ultra','Enhanced visuals without changing texture quality.'},
            auto={'Automatic','Gradually adjusts the preset based on FPS.'},
            custom={'Custom','Fine-tune the individual sliders.'}
        },
        controls = {
            headlights={'Headlights','Adjusts headlight brightness and reach'},
            coronas={'Light halos','Size and brightness of light coronas'},
            bloom={'Bloom','Soft glow around light sources'},
            distantLights={'Distant lights','Appearance of distant city lights'},
            rainLook={'Rain appearance','Rain glow (does not reduce particles)'},
            motionBlur={'Motion blur','Adjusts motion-blur strength'}
        },
        messages = {
            menuBusy = 'Close your inventory, phone or other UI before opening /graficos.',
            boostOn = 'FPS Boost enabled. Use /fps off to restore your previous preset.',
            boostBlocked = 'Potato mode is disabled by the server owner.',
            boostOff = 'FPS Boost disabled. Previous preset restored.',
            boostNotOn = 'FPS Boost was not enabled using /fps on.',
            autoOn = 'Automatic FPS adjustment enabled.',
            autoBlocked = 'Automatic FPS adjustment is disabled by the server.',
            help = 'Commands: /fps on, /fps off, /fps auto, /graficos'
        }
    }
}
function MZVisuals.GetLocale()
    return MZVisuals.Locales[Config.Locale] or MZVisuals.Locales['pt-BR']
end
