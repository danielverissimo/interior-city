local methods, events, messages, audits = {}, {}, {}, {}
local players, allowed, enabled = { [10] = 1, [20] = 2, [30] = 3, [40] = 4 }, true, true
ICAdmin = {
    Config = {}, ready = true,
    sessions = { [10] = { id = 'session1' }, [30] = { id = 'session3' }, [40] = { id = 'session4' } },
    active = function() return enabled end,
    register = function(name, definition) methods[name] = definition.handler end,
    fail = function(code, message) error(code .. ':' .. message) end,
    target = function(id) for sourceId, userId in pairs(players) do if userId == id then return userId, sourceId end end; error('OFFLINE') end,
    allowed = function() return allowed end,
    audit = function(...) audits[#audits + 1] = {...} end,
    vRP = { getUserId = function(sourceId) return players[sourceId] end }
}
function GetPlayerName(sourceId) return players[sourceId] and ('Player ' .. sourceId) end
function GetGameTimer() return 1234 end
function GetCurrentResourceName() return 'ic_admin' end
function TriggerClientEvent(event, recipient, payload) messages[#messages + 1] = { event, recipient, payload } end
function TriggerLatentClientEvent(event, recipient, _bandwidth, payload) TriggerClientEvent(event, recipient, payload) end
function RegisterNetEvent(name, callback) events[name] = callback end
function AddEventHandler(name, callback) events[name] = callback end
function CreateThread() end
json = { encode = function() return '{}' end }
dofile('resources/[scriptcore]/ic_admin/server/monitor.lua')
local ctx = { source = 10, userId = 1, sessionId = 'session1' }
local first = methods['monitor.start'](ctx, { targetId = 2 })
assert(first.token and #messages == 0, 'publisher must wait for ready')
source = 30; events['ic_admin:monitorSignal'](first.token, 'ready', {})
assert(#messages == 0, 'unrelated player cannot start publisher')
source = 10; events['ic_admin:monitorSignal'](first.token, 'ready', {})
assert(#messages == 1 and messages[1][2] == 20 and messages[1][3].kind == 'publisherStart')
source = 10; events['ic_admin:monitorSignal'](first.token, 'offer', { sdp = 'forged' })
assert(#messages == 1, 'viewer cannot impersonate publisher offer')
source = 20; events['ic_admin:monitorSignal'](first.token, 'offer', { sdp = 'ok' })
assert(#messages == 2 and messages[2][2] == 10)
methods['monitor.relay'](ctx, { token = first.token })
local before = #messages
source = 30; events['ic_admin:monitorFrame'](first.token, 1, 'data:image/jpeg;base64,AAAA')
assert(#messages == before, 'nonparticipant frame rejected')
source = 20; events['ic_admin:monitorFrame'](first.token, 1, 'data:image/jpeg;base64,AAAA')
assert(#messages == before + 1, 'publisher frame accepted')
events['ic_admin:monitorFrame'](first.token, 1, 'data:image/jpeg;base64,AAAA')
assert(#messages == before + 1, 'replayed frame rejected')
events['ic_admin:monitorFrame'](first.token, 2, 'data:text/html;base64,AAAA')
assert(#messages == before + 1, 'nonjpeg frame rejected')
allowed = false
events['ic_admin:monitorFrame'](first.token, 2, 'data:image/jpeg;base64,AAAA')
assert(messages[#messages][3].kind == 'closed', 'revocation closes session')
allowed = true
local second = methods['monitor.start'](ctx, { targetId = 2 })
players[20] = 99
source = 20; events['ic_admin:monitorSignal'](second.token, 'candidate', {})
assert(messages[#messages][3].kind == 'closed', 'source reuse closes session')
players[20] = 2
local third = methods['monitor.start'](ctx, { targetId = 2 })
methods['monitor.start']({ source = 30, userId = 3, sessionId = 'session3' }, { targetId = 4 })
local ok = pcall(methods['monitor.start'], { source = 40, userId = 4, sessionId = 'session4' }, { targetId = 3 })
assert(not ok, 'global session cap enforced')
methods['monitor.stop'](ctx, { token = third.token })
assert(messages[#messages][3].kind == 'closed')
print('IC Admin monitoring tests passed')
