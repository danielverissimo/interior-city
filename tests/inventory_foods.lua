local root = assert(arg[1])
json = dofile(root .. '/tests/ic_config_json.lua')
local function read(path)
    local file = assert(io.open(root .. '/' .. path, 'rb'))
    local content = file:read('*a')
    file:close()
    return content
end

local enabled, accepted = true, true
local consumed, events, objects, timers = {}, {}, {}, {}
exports = setmetatable({ vrp = {
    areNeedsEnabled = function() return enabled end,
    consumeNeeds = function(_, user, hunger, thirst)
        consumed[#consumed + 1] = { user, hunger, thirst }
        return accepted
    end
} }, { __call = function() end })
GlobalState = {}
vRP = { giveInventoryItem = function() error('New drinks must not create empty water bottles') end }
vRPc = {
    _CarregarObjeto = function(...) objects[#objects + 1] = { ... } end,
    _DeletarObjeto = function() end
}
function IsDuplicityVersion() return false end
function TriggerClientEvent(...) events[#events + 1] = { ... } end
function SetTimeout(_, fn) timers[#timers + 1] = fn end
function GetCurrentResourceName() return 'inventory' end
function LoadResourceFile(_, path) return read('resources/[scriptcore]/inventory/' .. path) end
function vec3(x, y, z) return { x = x, y = y, z = z } end

dofile(root .. '/resources/[scriptcore]/inventory/config/shared.items.lua')
dofile(root .. '/resources/[scriptcore]/inventory/config/shared.shops.loader.lua')
local legacy = dofile(root .. '/resources/[vrp]/vrp/cfg/items.lua').items
local catalog = json.decode(read('media/foods/catalog.json'))
assert(#catalog.items == 15)
for _, entry in ipairs(catalog.items) do
    local id, item = entry.id, assert(Items[entry.id], entry.id)
    local reference, old = assert(Items[entry.reference]), assert(legacy[id])
    assert(item.index == id and item.png == id and item.name == entry.name)
    assert(item.weight == reference.weight and old[3] == item.weight)
    assert(item.needs.hunger == reference.needs.hunger and item.needs.thirst == reference.needs.thirst)
    assert((old[4] or 0) == -item.needs.hunger and (old[5] or 0) == -item.needs.thirst)
    assert(old[1] == item.name and old[2] == (item.needs.thirst > 0 and 'beber' or 'comer'))
    assert(Shops[entry.shop].items[id] == entry.price)
    assert(entry.image == 'images/' .. item.png .. '.png')

    enabled, accepted = true, true
    local result, callbacks
    callbacks = 0
    item.func(42, 7, id, 1, function(value) result = value; callbacks = callbacks + 1 end)
    assert(result == true and callbacks == 1, id .. ': consumption callback')
    local needs = consumed[#consumed]
    assert(needs[1] == 42 and needs[2] == item.needs.hunger and needs[3] == item.needs.thirst)
    assert(objects[#objects][4] == item.prop, id .. ': prop mapping')
    for _, timer in ipairs(timers) do timer() end
    timers = {}

    local count, objectCount = #consumed, #objects
    enabled = false
    item.func(42, 7, id, 1, function(value) result = value end)
    assert(type(result) == 'table' and result.error and #consumed == count and #objects == objectCount)

    enabled, accepted = true, false
    item.func(42, 7, id, 1, function(value) result = value end)
    assert(type(result) == 'table' and result.error and #objects == objectCount)
end

-- Existing items retain their original props when no override is configured.
play_eat(7, 'hamburguer', 5)
assert(objects[#objects][4] == 'prop_cs_burger_01')
play_drink(7, 'cafe', 5)
assert(objects[#objects][4] == 'prop_fib_coffee')
assert(Shops.Lanchonete.items.coxinha == 100 and Shops.Restaurante.items.marmita == 300)
io.write('15 foods: inventory/vRP/shop contracts, consumption, disabled/failed needs and props passed\n')
