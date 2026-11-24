local states, charges, cash = {}, {}, {}
local plantKey, plantPed, handCharge = nil, nil, nil
local function removeObject(entity)
    if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
end
local function loadAsset(name, animation)
    if animation then RequestAnimDict(name) else RequestModel(GetHashKey(name)) end
    local untilTime=GetGameTimer()+1000
    while not (animation and HasAnimDictLoaded(name) or not animation and HasModelLoaded(GetHashKey(name))) do
        if GetGameTimer()>untilTime then return false end
        Wait(10)
    end
    return true
end
local function nearestAtm(location)
    local result,distance=nil,3.0
    local position=vector3(location.x,location.y,location.z)
    for _,model in ipairs(Config.AtmC4.models) do
        local entity=GetClosestObjectOfType(location.x,location.y,location.z,3.0,GetHashKey(model),false,false,false)
        if entity~=0 and DoesEntityExist(entity) then
            local d=#(GetEntityCoords(entity)-position)
            if d<distance then result,distance=entity,d end
        end
    end
    return result
end
local function stopPlant()
    if plantPed and DoesEntityExist(plantPed) then
        FreezeEntityPosition(plantPed,false)
        StopAnimTask(plantPed,'anim@heists@ornate_bank@thermal_charge','thermal_charge',2.0)
    end
    removeObject(handCharge)
    plantKey,plantPed,handCharge=nil,nil,nil
    TriggerEvent('cancelando',false)
end

RegisterNetEvent('m_roubos:plantAtm',function(key,location,heading,seconds)
    if plantKey then return end
    TriggerEvent('m_bank:closeForRobbery')
    local ped=PlayerPedId()
    plantKey,plantPed=key,ped
    local initialHealth=GetEntityHealth(ped)
    local deadline=GetGameTimer()+seconds*1000
    local atm=nearestAtm(location)
    if atm then
        local target=GetEntityCoords(atm)
        SetEntityHeading(ped,GetHeadingFromVector_2d(target.x-GetEntityCoords(ped).x,target.y-GetEntityCoords(ped).y))
    else SetEntityHeading(ped,heading) end
    SetCurrentPedWeapon(ped,GetHashKey('WEAPON_UNARMED'),true)
    FreezeEntityPosition(ped,true)
    TriggerEvent('cancelando',true)
    TriggerEvent('progress',seconds,'Instalando e armando a C4')
    if loadAsset('anim@heists@ornate_bank@thermal_charge',true) and plantKey==key then
        TaskPlayAnim(ped,'anim@heists@ornate_bank@thermal_charge','thermal_charge',8.0,-8.0,seconds*1000,49,0.0,false,false,false)
    end
    if loadAsset('prop_c4_final_green') and plantKey==key then
        local c=GetEntityCoords(ped)
        handCharge=CreateObjectNoOffset(GetHashKey('prop_c4_final_green'),c.x,c.y,c.z,false,false,false)
        AttachEntityToEntity(handCharge,ped,GetPedBoneIndex(ped,28422),0.0,0.0,0.08,0.0,85.0,-90.0,false,false,false,false,2,true)
    end
    while plantKey==key and GetGameTimer()<deadline do
        Wait(0)
        DisablePlayerFiring(PlayerId(),true)
        DisableControlAction(0,24,true)
        DisableControlAction(0,25,true)
        if IsEntityDead(ped) or GetEntityHealth(ped)<initialHealth or IsPedInAnyVehicle(ped,false) then
            vSERVER.cancelRobbery()
            stopPlant()
            return
        end
    end
    if plantKey==key then stopPlant() end
end)

local function createPlacedCharge(key,location,atm)
    if charges[key] or not loadAsset('prop_c4_final_green') then return end
    if not states[key] or states[key].phase~='armed' then return end
    local p=atm and GetOffsetFromEntityInWorldCoords(atm,0.0,-0.18,0.9) or vector3(location.x,location.y,location.z+0.4)
    charges[key]=CreateObjectNoOffset(GetHashKey('prop_c4_final_green'),p.x,p.y,p.z,false,false,false)
    SetEntityCollision(charges[key],false,false)
    FreezeEntityPosition(charges[key],true)
end
RegisterNetEvent('m_roubos:atmState',function(state)
    if type(state)~='table' or not state.key or not state.location then return end
    local previous=states[state.key]
    if plantKey==state.key and state.phase~='planting' then stopPlant() end
    if state.phase=='cancelled' or state.phase=='restored' then
        local atm=nearestAtm(state.location)
        if atm then SetEntityRenderScorched(atm,false) end
        removeObject(charges[state.key]);removeObject(cash[state.key])
        charges[state.key],cash[state.key],states[state.key]=nil,nil,nil
        return
    end
    state.fuseDeadline=GetGameTimer()+(tonumber(state.seconds) or 0)*1000
    states[state.key]=state
    if state.phase~='armed' then removeObject(charges[state.key]);charges[state.key]=nil end
    if state.phase=='exploded' and (not previous or previous.phase~='exploded') then
        local atm=nearestAtm(state.location)
        if atm then SetEntityRenderScorched(atm,true) end
        if state.explosionPlayer==GetPlayerServerId(PlayerId()) then
            local p=atm and GetEntityCoords(atm) or vector3(state.location.x,state.location.y,state.location.z)
            AddExplosion(p.x,p.y,p.z+0.6,2,1.0,true,false,1.0)
        end
    end
    if state.phase=='empty' then removeObject(cash[state.key]);cash[state.key]=nil end
end)
RegisterNetEvent('m_roubos:forceStop',function() if plantKey then stopPlant() end end)

local function atmUnavailable(position)
    for _,state in pairs(states) do
        if #(position-vector3(state.location.x,state.location.y,state.location.z))<3.0 then return true end
    end
    return false
end
AtmRobberyClient={isBusyNear=atmUnavailable}
exports('isAtmUnavailable',function(x,y,z) return atmUnavailable(vector3(x,y,z)) end)

RegisterNetEvent('m_roubos:useC4',function()
    local ped=PlayerPedId()
    if plantKey or IsEntityDead(ped) or IsPedInAnyVehicle(ped,false) then return end
    local position=GetEntityCoords(ped)
    if not nearestAtm({x=position.x,y=position.y,z=position.z}) then
        TriggerEvent('Notify','negado','Aproxime-se de um caixa eletronico para instalar a C4.',5)
        return
    end
    local nearest,distance=nil,3.0
    for _,point in pairs(Config.roubos) do
        if point.type=='caixa' then
            local d=#(position-vector3(point.x,point.y,point.z))
            if d<distance then nearest,distance=point,d end
        end
    end
    if nearest then vSERVER.startRobbery('caixa',nearest.id)
    else TriggerEvent('Notify','aviso','Este caixa ainda nao possui ponto de roubo cadastrado.',5) end
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('m_roubos:requestAtmState')
    local nextCollect=0
    while true do
        local pause=750
        local ped=PlayerPedId()
        local position=GetEntityCoords(ped)
        for key,state in pairs(states) do
            local l=state.location
            local distance=#(position-vector3(l.x,l.y,l.z))
            if distance<50.0 then
                local atm=nearestAtm(l)
                if state.phase=='armed' and not charges[key] then createPlacedCharge(key,l,atm) end
                if (state.phase=='exploded' or state.phase=='looting') and atm then SetEntityRenderScorched(atm,true) end
                if state.phase=='exploded' and not cash[key] and loadAsset('prop_cash_pile_01') then
                    if states[key] and states[key].phase=='exploded' then
                        cash[key]=CreateObjectNoOffset(GetHashKey('prop_cash_pile_01'),l.x,l.y,l.z-0.9,false,false,false)
                        FreezeEntityPosition(cash[key],true)
                        SetEntityCollision(cash[key],false,false)
                    end
                end
                if distance<15.0 and state.phase=='armed' then
                    pause=0
                    drawTxt('C4 ARMADA - AFASTE-SE! ~r~'..math.max(0,math.ceil((state.fuseDeadline-GetGameTimer())/1000))..'s',4,0.5,0.87,0.42,255,255,255,220)
                elseif distance<2.0 and state.phase=='exploded' and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped,false) then
                    pause=0
                    drawTxt('PRESSIONE ~g~G~w~ PARA RECOLHER O DINHEIRO DO CAIXA',4,0.5,0.87,0.42,255,255,255,220)
                    if IsControlJustPressed(0,47) and GetGameTimer()>nextCollect then
                        nextCollect=GetGameTimer()+1500
                        vSERVER.collectAtm(key)
                    end
                end
            end
        end
        Wait(pause)
    end
end)
AddEventHandler('onResourceStop',function(resource)
    if resource~=GetCurrentResourceName() then return end
    if plantKey then stopPlant() end
    for _,entity in pairs(charges) do removeObject(entity) end
    for _,entity in pairs(cash) do removeObject(entity) end
    for _,state in pairs(states) do local atm=nearestAtm(state.location);if atm then SetEntityRenderScorched(atm,false) end end
end)
