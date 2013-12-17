local scene = storyboard.newScene()
local app = require('lib.app')
local api = app.api
function scene:createScene (event)
    local group = self.view
    self.viewGroup = display.newGroup()
    self.drawGroup = display.newGroup()
    self.activeSnapshot = display.newSnapshot(_W, _H)
    self.viewGroup:translate(_CX, _CY)
    self.backgroundSnapshot = display.newSnapshot(_W, _H)
    
    self.blackRect = display.newRect(0, 0, _W, _H)
    self.blackRect:setFillColor(0)
    self.blackRect.alpha = 0.05
    
    group:insert(self.viewGroup)
    self.t = timer.performWithDelay(1, function() self:drawAudioWave() end, 0)
    self.start_t = system.getTimer()
    self.audioWaveMode = true
    timer.performWithDelay(15000, function() self:addStuff(-1) end)
    timer.performWithDelay(25000, function() self:removeStuff() end)
    timer.performWithDelay(75000, function() self:addStuff() end)
    timer.performWithDelay(95000, function() self:removeStuff() end)
    timer.performWithDelay(150000, function() self:mode('audio spectrogram');self.audioWaveMode = false end)
    timer.performWithDelay(165000, function() self:addStuff(-1) end)
    timer.performWithDelay(175000, function() self:removeStuff() end)
    timer.performWithDelay(200000, function() self:addStuff() end)
    timer.performWithDelay(240000, function() self:removeStuff() end)
    timer.performWithDelay(300000, function() self:mode('audio wave');self.audioWaveMode = true end)
    timer.performWithDelay(310000, function() self:addStuff() end)
    self:mode('audio wave')
end

function scene:addStuff(d)
    d = d or 1
    local function sine(t, tMax, start, delta)
        return math.sin(d * math.pi * 2 * t/tMax) * delta
    end
    local function cosine(t, tMax, start, delta)
        return math.cos(d * math.pi * 2 * t/tMax) * delta
    end
    for i = 1, 4 do
        self['circle' .. i] = display.newCircle(self.view, 0, 0, 20)
        self['circle' .. i].alpha = 0
        timer.performWithDelay((i - 1) * 1000 + 1, function()
            transition.to(self['circle' .. i], {time = 4000, y = 120, delta = true, transition = sine, iterations = -1})
            transition.to(self['circle' .. i], {time = 4000, x = 140, delta = true, transition = cosine, iterations = -1})
            transition.to(self['circle' .. i], {time = 3000, alpha = 1})
        end)
    end
end

function scene:removeStuff()
    for i = 1, 4 do
        display.remove(self['circle' .. i])
        self['circle' .. i] = nil
    end
end

function scene:mode(txt)
    display.remove(self.label)
    self.label = app.newText{g = self.view, text = txt:upper(), size = 20, x = _CX, y = 40}
    self.label:setFillColor(1)
    transition.to(self.label, {time = 5000, alpha = 0})
end

function scene:drawAudioWave()
    local data 
    if self.audioWaveMode then
        data = api:getAudioFrame()
    else
        data = api:getSpectrumFrame()
    end
    self.drawGroup:insert(self.blackRect)
    display.remove(self.waveLine)
    local d = _W / (#data - 1)
    self.waveLine = display.newLine(self.drawGroup, -_CX, data[1], d - _CX, data[2])
    for i = 3, #data do
        self.waveLine:append(d * (i - 1) - _CX, data[i])
    end
    local r, g, b = HSVtoRGB(system.getTimer()/100 % 360, 1, 1)
    self.waveLine:setStrokeColor(r, g, b)
    
    if self.circle1 then
        self.drawGroup:insert(self.circle1)
        self.circle1:setFillColor(HSVtoRGB((system.getTimer() + 500)/100 % 360, 1, 1))
        self.drawGroup:insert(self.circle2)
        self.circle2:setFillColor(HSVtoRGB((system.getTimer() + 1000)/100 % 360, 1, 1))
        self.drawGroup:insert(self.circle3)
        self.circle3:setFillColor(HSVtoRGB((system.getTimer() + 1500)/100 % 360, 1, 1))
        self.drawGroup:insert(self.circle4)
        self.circle4:setFillColor(HSVtoRGB((system.getTimer() + 2000)/100 % 360, 1, 1))
    end
    
    self.activeSnapshot, self.backgroundSnapshot = self.backgroundSnapshot, self.activeSnapshot
	self.viewGroup:insert(self.activeSnapshot)
    self.activeSnapshot.canvas:insert(self.backgroundSnapshot)
	self.activeSnapshot.canvas:insert(self.drawGroup)
	self.activeSnapshot.alpha = 1
    self.activeSnapshot.fill.effect = nil
	self.backgroundSnapshot.alpha = 0.7
    self:applyEffect(self.backgroundSnapshot)
	self.activeSnapshot:invalidate('canvas')
end

local effects = {
    {nil},
    {'filter.blur'},
    {'filter.swirl', {intensity = function(t) return math.sin(t / 1000) * 0.01 end}},
    {'filter.wobble', {amplitude = 2}},
    {'filter.vignette', {radius = function(t) return (0.5 + math.sin(t / 500) * 0.5) end}},
    {'filter.bulge', {intensity = function(t) return (0.8 + math.cos(t / 1200) * 0.20) end}},
    {'filter.opTile', {numPixels = 8, scale = 1.2}},
    {'filter.opTile', {numPixels = 8, angle = function(t) return math.sin(t / 10000) * 1 end, scale = 1.2}},
    {'filter.opTile', {numPixels = 8, angle = function(t) return -math.sin(t / 10000) * 1 end, scale = 1.2}},
    {'filter.opTile', {numPixels = 8, scale = function(t) return 1 + math.sin(t / 2500) * 1 end}},
    {'filter.frostedGlass', {scale = 64}},
    {'filter.colorChannelOffset', {xTexels = function(t) return math.cos(t / 1000)*3 end, yTexels = function(t) return math.sin(t / 1000)*3 end}},
    {'filter.zoomBlur', {intensity = function(t) return (0.5 - math.cos(t / 1000) * 0.5) * 0.5 end}},
    {'filter.crystallize', {numTiles = 32}},
    {'filter.crystallize', {numTiles = function(t) return 32 + (0.5 + math.sin(t / 1000) * 0.5) * 32 end}},
}
function scene:applyEffect(obj)
    local t = system.getTimer()
    local ind = math.floor(t/10000) % #effects + 1
    if self.last_ind ~= ind then
        self.start_t = t
    end
    t = t - self.start_t
    self.last_ind = ind
    obj.fill.effect = effects[ind][1]
    if effects[ind][2] then
        for k, v in pairs(effects[ind][2]) do
            if type(v) == 'function' then
                obj.fill.effect[k] = v(t)
            else
                obj.fill.effect[k] = v
            end
        end
    end    
end

function scene:didExitScene()
    timer.cancel(self.t)
    storyboard.removeScene('scenes.intro')
end

scene:addEventListener('didExitScene', scene)
scene:addEventListener('createScene', scene)
return scene

