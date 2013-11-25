local scene = storyboard.newScene()
local app = require('lib.app')

function scene:createScene (event)
    local group = self.view
    local splash = app.newImage('images/splash.png', {g = group, w = 256, h = 115, x = _CX, y = _CY - 10, rp = 'Center'})
    splash.alpha = 0
    
    transition.to(splash, {time = 800, alpha = 1, onComplete = function ()
        timer.performWithDelay(3000, function ()
                storyboard.gotoScene('scenes.intro', 'slideLeft', app.duration)
            end)
        end})

    local l = app.newText{g = group, text = 'Corona SDK Graphics 2.0 Demo by Lerg', x = _CX, y = _H - 60, size = 20}
    l.alpha = 0
    transition.to(l, {time = 800, alpha = 1})
    local l = app.newText{g = group, text = 'Audio Visualisation', x = _CX, y = 60, size = 20}
    l.alpha = 0
    transition.to(l, {time = 800, alpha = 1})
end
function scene:didExitScene()
    storyboard.removeScene('scenes.splash')
end

scene:addEventListener('didExitScene', scene)
scene:addEventListener('createScene', scene)
return scene

