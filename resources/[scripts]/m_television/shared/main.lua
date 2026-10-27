function MTelevisionVec3(coord)
    if not coord then return vector3(0.0, 0.0, 0.0) end
    return vector3((coord.x or 0.0) + 0.0, (coord.y or 0.0) + 0.0, (coord.z or 0.0) + 0.0)
end

function MTelevisionScreenKey(coords, model)
    local c = MTelevisionVec3(coords)
    return ("%s:%.2f:%.2f:%.2f"):format(tostring(model or 0), c.x, c.y, c.z)
end

function MTelevisionCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end

    local out = {}
    seen[value] = out
    for k, v in pairs(value) do
        out[MTelevisionCopy(k, seen)] = MTelevisionCopy(v, seen)
    end
    return out
end

function MTelevisionTrim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end
