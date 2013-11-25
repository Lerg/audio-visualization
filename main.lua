

-- Hide device's status bar at the top of the screen
display.setStatusBar(display.HiddenStatusBar)

audio = require('audio')
-- Buttons
widget = require('widget')
widget.setTheme('widget_theme_ios')
-- Scene manager
storyboard = require('storyboard')
json = require('json')


-- Various utility functions
local app = require('lib.app')
app.api = require('lib.api')
require('lib.utils')

app.font = native.systemFont
app.fontbold = native.systemFontBold

app.api:loadAudio()

local function main()
    math.randomseed(os.time())
    app.sound_on = true
    app.music_on = true
    storyboard.gotoScene('scenes.splash')
end
main()
