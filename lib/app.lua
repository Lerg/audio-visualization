-------------------------------------------
-- Module table
-------------------------------------------
local _M = {}

-------------------------------------------
-- Define global shortcuts
-------------------------------------------
_M.deviceID = system.getInfo('deviceID')

if system.getInfo('environment') ~= 'simulator' then
    io.output():setvbuf('no')
else
    _M.isSimulator = true
end
local platform = system.getInfo('platformName')
if platform == 'Android' then
    _M.isAndroid = true
elseif platform == 'iPhone OS' then
    _M.isiOS = true
end

if _M.isSimulator then
    -- Prevent global missuse
    local mt = getmetatable(_G)
    if mt == nil then
      mt = {}
      setmetatable(_G, mt)
    end

    mt.__declared = {}

    mt.__newindex = function (t, n, v)
      if not mt.__declared[n] then
        local w = debug.getinfo(2, 'S').what
        if w ~= 'main' and w ~= 'C' then
          error('assign to undeclared variable \'' .. n .. '\'', 2)
        end
        mt.__declared[n] = true
      end
      rawset(t, n, v)
    end
      
    mt.__index = function (t, n)
      if not mt.__declared[n] and debug.getinfo(2, 'S').what ~= 'C' then
        error('variable \'' .. n .. '\' is not declared', 2)
      end
      return rawget(t, n)
    end
end

-- Target 480x320 screen

_W = display.contentWidth
_H = display.contentHeight
_T = display.screenOriginY -- Top
_L = display.screenOriginX -- Left
_R = display.viewableContentWidth - _L -- Right
_B = display.viewableContentHeight - _T-- Bottom4
_CX = math.floor(_W / 2)
_CY = math.floor(_H / 2)

local _COLORS = {}
_COLORS['white'] = {255, 255, 255}
_COLORS['grey'] = {196, 196, 196}
_COLORS['black'] = {0, 0, 0}

_COLORS['red'] = {255, 0, 0}
_COLORS['green'] = {0, 255, 0}
_COLORS['blue'] = {0, 0, 255}

_COLORS['yellow'] = {255, 255, 0}
_COLORS['cyan'] = {0, 255, 255}
_COLORS['magenta'] = {255, 0, 255}

_COLORS['light_green'] = {60, 200, 100}
_COLORS['lighter_green'] = {80, 220, 120}
_COLORS['light_blue'] = {128, 128, 255}

_COLORS['dark_blue'] = {13, 65, 97}
_COLORS['dark_grey'] = {48, 48, 48}
_COLORS['text'] = {55, 25, 0}

local _AUDIO = {}
_AUDIO['button'] = 'sounds/button.wav'

local ext = '.m4a'
if _M.isAndroid or _M.isSimulator then
    ext = '.ogg'
end

--_AUDIO['whot'] = 'sounds/whot' .. ext

local mCeil = math.ceil
local mFloor = math.floor
local mAbs = math.abs
local mAtan2 = math.atan2
local mSin = math.sin
local mCos = math.cos
local mPi = math.pi
local mSqrt = math.sqrt
local mRandom = math.random
local tInsert = table.insert
local tRemove = table.remove
local tForEach = table.foreach
local tShuffle = table.shuffle
local sSub = string.sub

_M.duration = 200

-- Set reference point
function _M.setRP (object, ref_point)
    ref_point = string.lower(ref_point)
    if ref_point == 'topleft' then
        object:setReferencePoint(display.TopLeftReferencePoint)
        object.anchorX, object.anchorY = 0, 0
    elseif ref_point == 'topright' then
        object.anchorX, object.anchorY = 1, 0
    elseif ref_point == 'topcenter' then
        object.anchorX, object.anchorY = 0.5, 0
    elseif ref_point == 'bottomleft' then
        object.anchorX, object.anchorY = 0, 1
    elseif ref_point == 'bottomright' then
        object.anchorX, object.anchorY = 1, 1
    elseif ref_point == 'bottomcenter' then
        object.anchorX, object.anchorY = 0.5, 1
    elseif ref_point == 'centerleft' then
        object.anchorX, object.anchorY = 0, 0.5
    elseif ref_point == 'centerright' then
        object.anchorX, object.anchorY = 1, 0.5
    elseif ref_point == 'center' then
        object.anchorX, object.anchorY = 0.5, 0.5
    end
end

function _M.setFillColor (object, color)
    if type(color) == 'string' then
        color = _COLORS[color]
    end
    object:setFillColor(color[1], color[2], color[3])
end

function _M.setTextColor (object, color)
    if type(color) == 'string' then
        color = _COLORS[color]
    end
    local color = table.copy(color)
    if not color[4] then color[4] = 255 end
    object:setTextColor(color[1], color[2], color[3], color[4])
end

function _M.setStrokeColor (object, color)
    if type(color) == 'string' then
        color = _COLORS[color]
    end
    local color = table.copy(color)
    if not color[4] then color[4] = 255 end
    object:setStrokeColor(color[1], color[2], color[3], color[4])
end

function _M.setColor (object, color)
    if type(color) == 'string' then
        color = _COLORS[color]
    end
    local color = table.copy(color)
    if not color[4] then color[4] = 255 end
    object:setColor(color[1], color[2], color[3], color[4])
end

function _M.newImage(filename, params)
    params = params or {}
    local w, h = params.w or _W, params.h or _H
    local image = display.newImageRect(filename, params.dir or system.ResourceDirectory, w, h)
    if not image then return end
    if params.rp then
        _M.setRP(image, params.rp)
    end
    image.x = params.x or 0
    image.y = params.y or 0
    if params.g then
        params.g:insert(image)
    end
    return image
end

function _M.newText(params)
    params = params or {}
    local text
    if params.align then
        text = display.newText{text = params.text or '',
            x = params.x or 0, y = params.y or 0,
            width = params.w, height = params.h or (params.w and 0),
            font = params.font or _M.font,
            fontSize = params.size or 16,
            align = params.align or 'center'}
    elseif params.w then
        text = display.newEmbossedText(params.text or '', 0, 0, params.w, params.h or 0, params.font or _M.font, params.size or 16)
    else
        text = display.newEmbossedText(params.text or '', 0, 0, params.font or _M.font, params.size or 16)
    end
    if params.rp then
        _M.setRP(text, params.rp)
    end
    text.x = params.x or 0
    text.y = params.y or 0
    if params.g then
        params.g:insert(text)
    end
    if params.color then
        _M.setTextColor(text, params.color)
    end
    return text
end

function _M.buildBackground(height)
    local group = display.newGroup()
    local w, h = 125, 125
    local W, H = math.floor(display.viewableContentWidth / w), math.floor(height / h)
    local img
    for y = 0, H + 1 do
        for x = 0, W + 1 do
            img = display.newImageRect(group, 'images/back.jpg', w, h)
            img:setReferencePoint(display.TopLeftReferencePoint)
            img.x, img.y = _L + x * w, y * h
        end
    end
    return group
end

function _M.transition(object, params)
    params = params or {}
    params.delay = params.delay or 0
    object.alpha = 0
    local transParams = {time = 800, alpha = 1, transition = function (a,b,c,d) local v = easing.outExpo(a,b,c,d); if v > 1 then return 1 else return v end end}
    if params.delay > 0 then
        object.isVisible = false
        transParams.onStart = function (obj) obj.isVisible = true end
        transParams.delay = params.delay * 30
    end
    transition.to(object, transParams)
end

function _M.alert(txt)
    if type(txt) == 'string' then
        native.showAlert(_M.name, txt, {'OK'})
    end
end

function _M.returnTrue(obj)
    if obj then
        local function rt() return true end
        obj:addEventListener('touch', rt)
        obj:addEventListener('tap', rt)
        obj.isHitTestable = true
    else
        return true
    end
end

_M.loadedSounds = {}
function _M:loadSound (sound_type)
    if not self.loadedSounds[sound_type] then
        local filename = _AUDIO[sound_type]
        self.loadedSounds[sound_type] = audio.loadSound(filename)
    end
    return self.loadedSounds[sound_type]
end

local audioChannel, otherAudioChannel, currentSong, curAudio, prevAudio = 1
audio.crossFadeBackground = function (path, force)
    if _M.music_on then
        local musicPath = _AUDIO[path]
        if currentSong == musicPath and audio.getVolume{channel = audioChannel} > 0.1 and not force then return false end
        audio.fadeOut({channel=audioChannel, time=1000})
        if audioChannel==1 then audioChannel,otherAudioChannel=2,1 else audioChannel,otherAudioChannel=1,2 end
        audio.setVolume( 0.5, {channel = audioChannel})
        curAudio = audio.loadStream( musicPath )
        audio.play(curAudio, {channel=audioChannel, loops=-1, fadein=1000})
        prevAudio = curAudio
        currentSong = musicPath
        audio.currentBackgroundChannel = audioChannel
    end
end
audio.reserveChannels(2)
audio.currentBackgroundChannel = 1

audio.playSFX = function (snd, params)
    if _M.sound_on then
        local channel
        if type(snd) == 'string' then channel=audio.play(audio.loadSound(_AUDIO[snd]), params)
        else channel=audio.play(snd, params) end
        audio.setVolume(1, {channel = channel})
        return channel
    end
end

function _M:initUser(t)
    self.user = json.decode(readFile('user.txt'))
    if not self.user then
        self.user = t
        self:saveUser()
    end
end

function _M:saveUser()
    saveFile('user.txt', json.encode(self.user))
end

return _M
