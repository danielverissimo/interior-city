local I = ICAdmin
local sessions, serial = {}, 0
local MAX_FRAME, MAX_SIGNAL = 900000, 65536

local function notify(sourceId, data)
    TriggerClientEvent('ic_admin:monitorMessage', sourceId, data)
end
local function audit(action, session, data)
    if I.audit then pcall(I.audit, action, session.context, session.targetId, data or {}) end
end
local function samePlayer(sourceId, userId)
    return sourceId and GetPlayerName(sourceId) ~= nil and tonumber(I.vRP.getUserId(sourceId)) == tonumber(userId)
end
local function authorized(session)
    local current = I.sessions and I.sessions[session.viewer]
    if not current or current.id ~= session.context.sessionId then return false end
    return I.active() and samePlayer(session.viewer, session.viewerId) and samePlayer(session.publisher, session.targetId)
        and I.allowed(session.viewerId, 'map_screen')
end
local function finish(token, reason)
    local session = sessions[token]
    if not session then return end
    sessions[token] = nil
    notify(session.viewer, { kind = 'closed', token = token, reason = reason or 'Transmissão encerrada.' })
    notify(session.publisher, { kind = 'closed', token = token, reason = reason or 'Transmissão encerrada.' })
    audit('monitor.stop', session, { reason = reason or 'closed' })
end
local function findViewer(sourceId)
    for token, session in pairs(sessions) do if session.viewer == sourceId then return token, session end end
end
local function options()
    local c = I.Config and (I.Config.Monitor or I.Config.monitor) or {}
    return {
        width = 960, height = 540, fps = 12, bitrate = 1200000,
        maxSessions = math.max(1, math.min(8, tonumber(c.maxSessions) or 2)),
        relayFps = 8, maxFrameBytes = MAX_FRAME,
        iceServers = c.iceServers or { { urls = 'stun:stun.l.google.com:19302' } }
    }
end

I.register('monitor.start', { permission = 'map_screen', mutating = true, handler = function(ctx, p)
    local id, sourceId = I.target(p.targetId, true)
    if sourceId == ctx.source then I.fail('INVALID_TARGET', 'Selecione outro jogador para monitorar.'); return end
    local count = 0
    for _, session in pairs(sessions) do
        count = count + 1
        if session.publisher == sourceId then I.fail('BUSY', 'Este jogador já está sendo monitorado.'); return end
    end
    local existing = findViewer(ctx.source)
    if existing then finish(existing, 'Administrador iniciou outra transmissão.'); count = count - 1 end
    if count >= options().maxSessions then I.fail('CAPACITY', 'O limite de transmissões simultâneas foi atingido.'); return end
    serial = serial + 1
    local token = ('%s:%s:%s:%s'):format(ctx.userId, os.time(), GetGameTimer(), serial)
    sessions[token] = {
        token = token, viewer = ctx.source, viewerId = ctx.userId, publisher = sourceId, targetId = id,
        context = ctx, lastAt = os.time(), frameAt = 0, frameCount = 0, frameSequence = 0, signalAt = 0, signalCount = 0,
        mode = 'webrtc', started = false
    }
    audit('monitor.start', sessions[token], { transport = 'webrtc' })
    -- Publisher starts only after the receiver signals ready, preventing offer races.
    return { token = token, targetId = id, options = options() }
end })
I.register('monitor.stop', { permission = 'map_screen', mutating = true, handler = function(ctx, p)
    local token, session = findViewer(ctx.source)
    if session and (not p.token or p.token == token) then finish(token, 'Monitor fechado pelo administrador.') end
    return { stopped = true }
end })
I.register('monitor.relay', { permission = 'map_screen', mutating = true, handler = function(ctx, p)
    local session = sessions[tostring(p.token or '')]
    if not session or session.viewer ~= ctx.source or not authorized(session) then I.fail('SESSION_CLOSED', 'Transmissão indisponível.'); return end
    session.mode, session.lastAt = 'relay', os.time()
    notify(session.publisher, { kind = 'relayStart', token = session.token, options = options() })
    audit('monitor.relay', session, {})
    return { transport = 'relay' }
end })

RegisterNetEvent('ic_admin:monitorSignal', function(token, kind, payload)
    local sender = tonumber(source)
    if type(token) ~= 'string' or #token > 160 or type(kind) ~= 'string' or type(payload) ~= 'table' then return end
    local session = sessions[token]
    if not session or (sender ~= session.viewer and sender ~= session.publisher) then return end
    if not authorized(session) then finish(token, 'Jogador desconectado ou permissão revogada.'); return end
    local ok, encoded = pcall(json.encode, payload)
    if not ok or #encoded > MAX_SIGNAL then return end
    local now = os.time()
    if now ~= session.signalAt then session.signalAt, session.signalCount = now, 0 end
    session.signalCount = session.signalCount + 1
    if session.signalCount > 60 then return end
    session.lastAt = now
    if kind == 'ready' and sender == session.viewer and not session.started then
        session.started = true
        notify(session.publisher, { kind = 'publisherStart', token = token, options = options() })
    elseif kind == 'heartbeat' then return
    elseif kind == 'candidate' or (kind == 'offer' and sender == session.publisher) or (kind == 'answer' and sender == session.viewer) then
        notify(sender == session.viewer and session.publisher or session.viewer, { kind = 'signal', token = token, signalKind = kind, payload = payload })
    elseif kind == 'error' then
        audit('monitor.failure', session, { stage = tostring(payload.stage or 'capture'):sub(1, 40) })
        finish(token, 'Falha na captura ou conexão da transmissão.')
    end
end)
AddEventHandler('ic_admin:sessionRevoked', function(sourceId)
    local token = findViewer(tonumber(sourceId))
    if token then finish(token, 'Sessão administrativa encerrada.') end
end)

RegisterNetEvent('ic_admin:monitorFrame', function(token, sequence, frame)
    local sender = tonumber(source)
    if type(token) ~= 'string' or type(frame) ~= 'string' or #frame > MAX_FRAME or not frame:match('^data:image/jpeg;base64,[A-Za-z0-9+/=]+$') then return end
    local session = sessions[token]
    if not session or sender ~= session.publisher or session.mode ~= 'relay' then return end
    if not authorized(session) then finish(token, 'Jogador desconectado ou permissão revogada.'); return end
    local n = tonumber(sequence)
    if not n or n % 1 ~= 0 or n <= session.frameSequence then return end
    local now = os.time()
    if now ~= session.frameAt then session.frameAt, session.frameCount = now, 0 end
    session.frameCount = session.frameCount + 1
    if session.frameCount > 8 then return end
    session.frameSequence, session.lastAt = n, now
    TriggerLatentClientEvent('ic_admin:monitorMessage', session.viewer, 2500000, { kind = 'frame', token = token, frame = frame, sequence = n })
end)

AddEventHandler('playerDropped', function()
    local sender = tonumber(source)
    local list = {}
    for token, session in pairs(sessions) do if session.viewer == sender or session.publisher == sender then list[#list + 1] = token end end
    for _, token in ipairs(list) do finish(token, 'Um participante desconectou.') end
end)
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    local list = {}; for token in pairs(sessions) do list[#list + 1] = token end
    for _, token in ipairs(list) do finish(token, 'Recurso encerrado.') end
end)
CreateThread(function()
    while true do
        Wait(5000)
        local list = {}
        for token, session in pairs(sessions) do
            if os.time() - session.lastAt > 35 or not authorized(session) then list[#list + 1] = token end
        end
        for _, token in ipairs(list) do finish(token, 'Sessão expirada ou permissão revogada.') end
    end
end)
