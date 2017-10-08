function Any(t, predicate, iter)
    t = t or {}
    iter = iter or ipairs

    for k, v in iter(t) do
        if predicate(v, k) then
            return true
        end
    end

    return false
end

function Keys(t)
    local keys = {}
    for k, v in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end