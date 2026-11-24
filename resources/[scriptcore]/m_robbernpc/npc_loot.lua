-- Sorteios por porta-malas NPC, nunca por slot e nunca para baus de jogadores.
local Proxy = module('vrp', 'lib/Proxy')
local vRP = Proxy.getInterface('vRP')

function BuildNPCTrunkLoot()
    local function validEntries(entries)
        local list, seen = {}, {}
        for _, entry in ipairs(entries or {}) do
            local name = entry.item and vRP.getItemName(entry.item)
            if type(name) == 'string' and name ~= '' and name ~= 'Deleted' and not seen[entry.item] then
                seen[entry.item] = true
                list[#list + 1] = entry
            end
        end
        return list
    end

    local common = validEntries(Config.Loot)
    if #common == 0 then return nil, 'Nenhum item comum valido no loot de NPC.' end
    local minimum = math.max(1, math.floor(tonumber(Config.LootMinCount) or 1))
    local maximum = math.max(minimum, math.floor(tonumber(Config.LootCount) or 2))
    local count = math.min(#common, math.random(minimum, maximum))
    local loot = {}
    local function add(entry)
        local min = math.max(1, math.floor(tonumber(entry.min) or 1))
        local max = math.max(min, math.floor(tonumber(entry.max) or min))
        loot[entry.item] = {amount=math.random(min, max)}
    end
    for i = 1, count do
        local pick = math.random(#common)
        add(table.remove(common, pick))
    end
    for _, group in ipairs(Config.NPCLootGroups or {}) do
        local chance = math.max(0, math.min(100, tonumber(group.chance) or 0))
        if math.random(1, 10000) <= chance * 100 then
            local entries = validEntries(group.items)
            if #entries > 0 then add(entries[math.random(#entries)]) end
        end
    end
    return loot
end
