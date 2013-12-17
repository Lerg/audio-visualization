local _M = {}

local app = require('lib.app')

-- Audio is converted to RAW with ffmpeg command
-- ffmpeg -i fire.mp3 -f u8 -acodec pcm_u8 -ar 16000 -ac 1 fire.raw

function _M:loadAudio()
    local f = io.open(system.pathForFile('music/fire.raw', system.ResourceDirectory), 'rb')
    local data = f:read('*a')
    local audioStream = {}
    for i = 1, data:len() do
        audioStream[#audioStream + 1] = data:sub(i, i):byte() - 127
    end
    self.audioStream = audioStream

    local stream = audio.loadStream('music/fire.mp3')
    local c = audio.play(stream, {loops = -1})
    audio.setVolume(0, {channel = c})
    audio.fade{channel = c, time = 3000, volume = 0.5}
    self.audioStart = system.getTimer()
end

function _M:getAudioFrame()
    local t = system.getTimer() - self.audioStart
    local stream = self.audioStream
    local start_pos = math.floor(t * 16) % #stream
    t = {}
    for i = start_pos, start_pos + 266, 2 do
        if i > #stream then
            t[#t + 1] = stream[i % #stream] * 0.75
        else
            t[#t + 1] = (stream[i] or 0) * 0.75
        end
    end
    return t
end

local floor = math.floor

-- this function is from here:
--   http://lua-users.org/lists/lua-l/2002-09/msg00078.html
local function bxor (a,b)
  local r = 0
  for i = 0, 31 do
    local x = a / 2 + b / 2
    if x ~= floor (x) then
      r = r + 2^i
    end
    a = floor (a / 2)
    b = floor (b / 2)
  end
  return r
end


-- this function is ported from:
--   http://www.kurims.kyoto-u.ac.jp/~ooura/fftman/ftmn1_24.html#sec1_2_4
-- base code is from:
--   http://game11.2ch.net/test/read.cgi/gameama/1182042852/420
local function fft(n, ar, ai)
    local m, mq, i, j, j1, j2, j3, k=0,0,0,0,0,0,0,0
    local theta, w1r, w1i, w3r, w3i=0,0,0,0,0
    local x0r, x0i, x1r, x1i, x3r, x3i=0,0,0,0,0,0
	local atan = math.atan
	local cos = math.cos
	local sin = math.sin
	local floor = math.floor
	
    theta = -8 * atan(1.0) / n
    m = n
    while m > 2 do -- for (m = n; m > 2; m >>= 1)
        mq = floor(m/4) -- mq = m >> 2;
        i = 0
        while i < mq do -- for (i = 0; i < mq; i++) {
            w1r = cos(theta * i)
            w1i = sin(theta * i)
            w3r = cos(theta * 3 * i)
            w3i = sin(theta * 3 * i)
            k = m
            while k<=n do -- for (k = m; k <= n; k <<= 2) {
                j = k - m + i
                while j < n do -- for (j = k - m + i; j < n; j += 2 * k) {
                    j1 = j + mq
                    j2 = j1 + mq
                    j3 = j2 + mq
                    x1r = ar[j] - ar[j2]
                    x1i = ai[j] - ai[j2]
                    ar[j] = ar[j] + ar[j2]
                    ai[j] = ai[j] + ai[j2]
                    x3r = ar[j3] - ar[j1]
                    x3i = ai[j3] - ai[j1]
                    ar[j1] = ar[j1] + ar[j3]
                    ai[j1] = ai[j1] + ai[j3]
                    x0r = x1r - x3i
                    x0i = x1i + x3r
                    ar[j2] = w1r * x0r - w1i * x0i
                    ai[j2] = w1r * x0i + w1i * x0r
                    x0r = x1r + x3i
                    x0i = x1i - x3r
                    ar[j3] = w3r * x0r - w3i * x0i
                    ai[j3] = w3r * x0i + w3i * x0r
                    j = j + (2*k)
                end
				k = k * 4
            end
            i=i+1
        end
        theta =theta * 2
        m = floor(m/2)
    end

    k = 2
    while k<=n do -- for (k = 2; k <= n; k <<= 2) {
        j = k - 2
        while j < n do -- for (j = k - 2; j < n; j += 2 * k) {
            x0r = ar[j] - ar[j + 1]
            x0i = ai[j] - ai[j + 1]
            ar[j] =ar[j]+ar[j + 1]
            ai[j] =ai[j]+ai[j + 1]
            ar[j + 1] = x0r
            ai[j + 1] = x0i
            j = j+(k*2)
        end
        k = k * 4
    end

    i = 0
    j = 1
    while j < n - 1 do -- for (j = 1; j < n - 1; j++) {
        k = floor(n/2)
		i=bxor(i,k)
        while k > i do -- for (k = n >> 1; k > (i ^= k); k >>= 1);
			k = floor(k/2)
			i=bxor(i,k)
		end
		if j < i then
			x0r = ar[j]
			x0i = ai[j]
			ar[j] = ar[i]
			ai[j] = ai[i]
			ar[i] = x0r
			ai[i] = x0i
		end
		j=j+1
    end
end

function _M:getSpectrumFrame()
    local t = system.getTimer() - self.audioStart
    local stream = self.audioStream
    local start_pos = math.floor(t * 16) % #stream
    local j = 0
    local dr, di = {}, {}
    for i = start_pos, start_pos + 2048 do
        if i > #stream then
            dr[j] = stream[i % #stream] / 50
        else
            dr[j] = (stream[i] or 0) / 50
        end
        di[j] = 0
        j = j + 1
    end
    
    fft(2048, dr, di)
    t = {}
    local j = 1
    for i = 1023, 2047 - 8, 8 do
        local sum = 0
        for k = 1, 8 do
            sum = sum + 127 - math.abs(dr[i + k])
        end
        t[j] = sum/8
        j = j + 1
    end
    self.st = t
    return t
end

return _M