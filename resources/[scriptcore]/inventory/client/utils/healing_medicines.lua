-- Percentuais da mesma barra da HUD: (vida - 100) / (vida maxima - 100).
local medicines = {
    bandagem = {label='Bandagem', fraction=0.5, preparation=15, seconds=10},
    cicatricure = {label='Cicatricure', fraction=0.375, preparation=3, seconds=20},
    dorflex = {label='Dorflex', fraction=0.225, preparation=3, seconds=45}
}
local healingActive = false

local pillDictionary = 'mp_suicide'
local function startPillAnimation(ped)
    RequestAnimDict(pillDictionary)
    local deadline = GetGameTimer()+2000
    while not HasAnimDictLoaded(pillDictionary) do
        if GetGameTimer() >= deadline then return false end
        Wait(10)
    end
    if PlayerPedId() ~= ped or IsEntityDead(ped) then return false end
    TaskPlayAnim(ped, pillDictionary, 'pill', 8.0, -8.0, 3000, 48, 0.0, false, false, false)
    return true
end
local function stopPillAnimation(ped)
    StopAnimTask(ped, pillDictionary, 'pill', 2.0)
end

-- Dipirona usa apenas a animacao, sem modificar os valores de cura.
function API.takePillAnimation()
    CreateThread(function()
        local ped = PlayerPedId()
        if startPillAnimation(ped) then
            Wait(3000)
            stopPillAnimation(ped)
        end
    end)
end

function API.beginHealingMedicine(item)
    local config = medicines[item]
    if not config or healingActive then return end
    local ped = PlayerPedId()
    local initialHealth = GetEntityHealth(ped)
    if initialHealth <= 110 or IsEntityDead(ped) then return end
    local maximum = GetEntityMaxHealth(ped)
    if initialHealth >= maximum then return end
    healingActive = true
    TriggerEvent('progress', config.preparation, 'Usando '..config.label)
    CreateThread(function()
        local pill = item == 'cicatricure' or item == 'dorflex'
        if pill then startPillAnimation(ped) end
        local previous = initialHealth
        local function cancelled()
            local health = GetEntityHealth(ped)
            return PlayerPedId() ~= ped or IsEntityDead(ped) or health <= 110 or health < previous
        end
        for _=1,config.preparation do
            Wait(1000)
            if cancelled() then
                if pill then stopPillAnimation(ped) end
                healingActive = false
                TriggerEvent('Notify', 'aviso', 'Uso de '..config.label..' interrompido.', 5)
                return
            end
            previous = GetEntityHealth(ped)
        end
        if pill then stopPillAnimation(ped) end
        local total = math.floor((maximum-100)*config.fraction+0.5)
        local delivered = 0
        for second=1,config.seconds do
            Wait(1000)
            if cancelled() then
                healingActive = false
                TriggerEvent('Notify', 'aviso', 'Recuperacao interrompida por dano ou desmaio.', 5)
                return
            end
            local cumulative = math.floor(total*second/config.seconds)
            local current = GetEntityHealth(ped)
            local limit = math.min(maximum, GetEntityMaxHealth(ped))
            SetEntityHealth(ped, math.min(limit, current+cumulative-delivered))
            delivered = cumulative
            previous = GetEntityHealth(ped)
            if previous >= limit then break end
        end
        healingActive = false
        TriggerEvent('Notify', 'sucesso', 'Efeito de '..config.label..' concluido.', 5)
    end)
end
