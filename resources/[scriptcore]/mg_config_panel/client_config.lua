--[[
    mg_config_panel - OPEN CLIENT TRANSPORT / GAME BRIDGE
    NAO OFUSCAR ESTE ARQUIVO.

    Esta camada possui Tunnel/NUI e as rotinas de captura/teleporte que precisam
    permanecer fora do virtualizador para garantir compatibilidade total.
    Toda alteracao persistente continua validada no server.lua protegido.
]]

local Tunnel = module('vrp','lib/Tunnel')
local Server = Tunnel["getInterface"](GetCurrentResourceName())

local panelOpen=false
local positionMode=nil
local positionTarget=nil
local positionLabel=nil
local positionWithHeading=false
local safeZoneCapture=nil

local function round2(v)
    return math.floor(v * 100 + 0.5) / 100
end

local function drawPositionHelp(mode)
    local x,y = 0.5,0.89
    DrawRect(x,y,0.50,0.085,10,14,22,220)
    SetTextFont(4)
    SetTextScale(0.0,0.38)
    SetTextColour(255,255,255,255)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')

    if mode == 'spawn' then
        AddTextComponentSubstringPlayerName('Posicione-se onde o veiculo deve aparecer')
    elseif mode == 'desmanche' or mode == 'mansion' then
        AddTextComponentSubstringPlayerName(positionLabel or (mode == 'mansion' and 'Posicione-se no ponto da mansão' or 'Posicione-se no ponto do desmanche'))
    else
        AddTextComponentSubstringPlayerName('Posicione-se onde o ponto da loja deve ficar')
    end

    EndTextCommandDisplayText(x,y-0.026)

    SetTextScale(0.0,0.31)
    SetTextColour(190,180,255,255)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName('~g~[E]~s~ Confirmar posicao   ~r~[BACKSPACE]~s~ Cancelar')
    EndTextCommandDisplayText(x,y+0.012)
end

local function setPanel(state)
    panelOpen=state
    SetNuiFocus(state,state)
    SendNUIMessage({action=state and 'open' or 'close'})
end

local function openPanel()
    if panelOpen then return end
    if not Server.hasAccess() then
        TriggerEvent('Notify','negado','Você não possui permissão para acessar este painel.',5000)
        return
    end
    setPanel(true)
end

RegisterCommand(Config["Command"],openPanel,false)

-- Atalho padrão do painel: HOME
RegisterCommand('+mg_config_panel_home',function()
    openPanel()
end,false)

RegisterCommand('-mg_config_panel_home',function()
end,false)

RegisterKeyMapping('+mg_config_panel_home','Abrir Painel de Configurações','keyboard','HOME')
RegisterNetEvent('mg_config:open',openPanel)
RegisterNUICallback('close',function(_,cb) setPanel(false); cb({ok=true}) end)

for _,name in ipairs({'getChests','getGarages','getGarageTypes','getShops','getItemList','getCraftSetups','getClothingShops','getBarbershops','getTattooShops','getCloakrooms','getMapMarkings','getManagedGroups','getDesmanches','getSafeZones','getJobs','getRoubos','getBancoCentral','getJoalheria','getRoubocofre','getResidences','getDealership','getServerVehicleCatalog','getMansions'}) do
    RegisterNUICallback(name,function(_,cb)
        cb(Server[name]())
    end)
end

RegisterNUICallback('createChest',function(data,cb) cb(Server.createChest(data)) end)
RegisterNUICallback('updateChest',function(data,cb) cb(Server.updateChest(data)) end)
RegisterNUICallback('deleteChest',function(data,cb) cb(Server.deleteChest(data and data.name)) end)

RegisterNUICallback('createGarage',function(data,cb) cb(Server.createGarage(data)) end)
RegisterNUICallback('updateGarage',function(data,cb) cb(Server.updateGarage(data)) end)
RegisterNUICallback('deleteGarage',function(data,cb) cb(Server.deleteGarage(data and data.id)) end)
RegisterNUICallback('createGarageType',function(data,cb) cb(Server.createGarageType(data)) end)
RegisterNUICallback('updateGarageType',function(data,cb) cb(Server.updateGarageType(data)) end)
RegisterNUICallback('deleteGarageType',function(data,cb) cb(Server.deleteGarageType(data and data.name)) end)


RegisterNUICallback('saveMansion',function(data,cb) cb(Server.saveMansion(data)) end)
RegisterNUICallback('deleteMansion',function(data,cb) cb(Server.deleteMansion(data and data.id)) end)

RegisterNUICallback('createShop',function(data,cb) cb(Server.createShop(data)) end)
RegisterNUICallback('updateShop',function(data,cb) cb(Server.updateShop(data)) end)
RegisterNUICallback('deleteShop',function(data,cb) cb(Server.deleteShop(data and data.name)) end)
RegisterNUICallback('saveCraftSetup',function(data,cb) cb(Server.saveCraftSetup(data)) end)
RegisterNUICallback('deleteCraftSetup',function(data,cb) cb(Server.deleteCraftSetup(data and data.name)) end)


RegisterNUICallback('getPosition',function(_,cb)
    local c=GetEntityCoords(PlayerPedId())
    cb({ok=true,coords={x=round2(c.x),y=round2(c.y),z=round2(c.z)}})
end)

RegisterNUICallback('getPosition4',function(_,cb)
    local ped=PlayerPedId()
    local c=GetEntityCoords(ped)
    cb({ok=true,coords={x=round2(c.x),y=round2(c.y),z=round2(c.z),w=round2(GetEntityHeading(ped))}})
end)

local function startPosition(mode,cb)
    if positionMode then
        cb({ok=false,message='Já existe um posicionamento em andamento.'})
        return
    end

    if not Server.hasAccess() then
        cb({ok=false,message='Sem permissão.'})
        return
    end

    positionMode=mode
    setPanel(false)
    cb({ok=true})
end

RegisterNUICallback('startSpawnPosition',function(_,cb)
    startPosition('spawn',cb)
end)

RegisterNUICallback('startShopPosition',function(_,cb)
    startPosition('shop',cb)
end)

RegisterNUICallback('startDesmanchePosition',function(data,cb)
    if positionMode then
        cb({ok=false,message='Já existe um posicionamento em andamento.'})
        return
    end

    if not Server.hasAccess() then
        cb({ok=false,message='Sem permissão.'})
        return
    end

    positionTarget=tostring(data and data.target or '')
    positionLabel=tostring(data and data.label or 'Posicione-se no ponto do desmanche')
    positionWithHeading=data and data.heading == true or false
    positionMode='desmanche'
    setPanel(false)
    cb({ok=true})
end)



RegisterNUICallback('startMansionPosition',function(data,cb)
    if positionMode then
        cb({ok=false,message='Já existe um posicionamento em andamento.'})
        return
    end
    if not Server.hasAccess() then
        cb({ok=false,message='Sem permissão.'})
        return
    end

    positionTarget=tostring(data and data.target or '')
    positionLabel=tostring(data and data.label or 'Posicione-se no ponto da mansão')
    positionWithHeading=data and data.heading == true or false
    positionMode='mansion'
    setPanel(false)
    cb({ok=true})
end)

RegisterNUICallback('startMansionDoorCapture',function(_,cb)
    if positionMode or safeZoneCapture then
        cb({ok=false,message='Finalize o posicionamento atual primeiro.'})
        return
    end
    if not Server.hasAccess() then
        cb({ok=false,message='Sem permissão.'})
        return
    end
    if GetResourceState(Config["DoorsResource"] or 'doorsv2') ~= 'started' then
        cb({ok=false,message='O doorsv2 não está iniciado.'})
        return
    end
    setPanel(false)
    TriggerEvent('doorsv2:startMansionCapture')
    cb({ok=true})
end)

RegisterNetEvent('mg_config_panel:mansionDoorsCaptured',function(doors)
    SendNUIMessage({action='mansionDoorsCaptured',doors=doors or {}})
    setPanel(true)
end)

RegisterNetEvent('mg_config_panel:mansionDoorCaptureCancelled',function(message)
    SendNUIMessage({action='mansionDoorCaptureCancelled',message=message})
    setPanel(true)
end)

RegisterNUICallback('startSafeZonePolygon',function(data,cb)
    if positionMode or safeZoneCapture then
        cb({ok=false,message='Já existe um modo de posicionamento em andamento.'})
        return
    end
    if not Server.hasAccess() then
        cb({ok=false,message='Sem permissão.'})
        return
    end

    safeZoneCapture={
        target=tonumber(data and data.target) or 1,
        points={},
        minCapturedZ=nil,
        maxCapturedZ=nil
    }

    setPanel(false)
    cb({ok=true})
end)

RegisterNUICallback('teleport',function(data,cb)
    if not Server.hasAccess() then cb({ok=false}); return end

    local c=data and data.coords
    if not c then cb({ok=false}); return end

    local x,y,z=tonumber(c.x),tonumber(c.y),tonumber(c.z)
    if not x or not y or not z then cb({ok=false}); return end

    local ped=PlayerPedId()
    local ent=IsPedInAnyVehicle(ped,false) and GetVehiclePedIsIn(ped,false) or ped
    SetEntityCoords(ent,x,y,z+0.25,false,false,false,false)
    setPanel(false)
    cb({ok=true})
end)

CreateThread(function()
    while true do
        if positionMode then
            drawPositionHelp(positionMode)
            DisableControlAction(0,200,true)

            if IsControlJustPressed(0,38) then
                local ped=PlayerPedId()
                local c=GetEntityCoords(ped)
                local mode=positionMode
                positionMode=nil

                if mode=='spawn' then
                    SendNUIMessage({
                        action='spawnPositionCaptured',
                        coords={x=round2(c.x),y=round2(c.y),z=round2(c.z),w=round2(GetEntityHeading(ped))}
                    })
                elseif mode=='desmanche' then
                    local coords={
                        x=round2(c.x),
                        y=round2(c.y),
                        z=round2(c.z)
                    }

                    if positionWithHeading then
                        coords.w=round2(GetEntityHeading(ped))
                    end

                    SendNUIMessage({
                        action='desmanchePositionCaptured',
                        target=positionTarget,
                        coords=coords
                    })

                    positionTarget=nil
                    positionLabel=nil
                    positionWithHeading=false
                elseif mode=='mansion' then
                    local coords={x=round2(c.x),y=round2(c.y),z=round2(c.z)}
                    if positionWithHeading then coords.w=round2(GetEntityHeading(ped)) end
                    SendNUIMessage({action='mansionPositionCaptured',target=positionTarget,coords=coords})
                    positionTarget=nil
                    positionLabel=nil
                    positionWithHeading=false
                else
                    SendNUIMessage({
                        action='shopPositionCaptured',
                        coords={x=round2(c.x),y=round2(c.y),z=round2(c.z)}
                    })
                end

                setPanel(true)
            elseif IsControlJustPressed(0,177) then
                local mode=positionMode
                positionMode=nil

                if mode=='desmanche' or mode=='mansion' then
                    SendNUIMessage({
                        action=mode=='mansion' and 'mansionPositionCancelled' or 'desmanchePositionCancelled',
                        target=positionTarget
                    })
                    positionTarget=nil
                    positionLabel=nil
                    positionWithHeading=false
                else
                    SendNUIMessage({
                        action=mode=='spawn' and 'spawnPositionCancelled' or 'shopPositionCancelled'
                    })
                end

                setPanel(true)
            end

            Wait(0)
        else
            if panelOpen and IsControlJustPressed(0,200) then setPanel(false) end
            Wait(panelOpen and 0 or 500)
        end
    end
end)


CreateThread(function()
    while true do
        if safeZoneCapture then
            Wait(0)

            local ped=PlayerPedId()
            local c=GetEntityCoords(ped)
            local points=safeZoneCapture.points

            -- Ajuda visual simples e leve.
            DrawRect(0.5,0.875,0.54,0.105,10,14,22,225)
            SetTextFont(4)
            SetTextScale(0.0,0.36)
            SetTextColour(255,255,255,255)
            SetTextCentre(true)
            SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(
                ('DESENHANDO SAFEZONE  |  Pontos: ~b~%d~s~'):format(#points)
            )
            EndTextCommandDisplayText(0.5,0.842)

            SetTextScale(0.0,0.29)
            SetTextColour(205,210,220,255)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(
                '~g~[E]~s~ Adicionar ponto   ~y~[BACKSPACE]~s~ Concluir   ~r~[X]~s~ Cancelar'
            )
            EndTextCommandDisplayText(0.5,0.882)

            -- Pontos e linhas já capturados.
            for i,p in ipairs(points) do
                DrawMarker(28,p.x,p.y,p.z+0.15,0,0,0,0,0,0,0.20,0.20,0.20,74,168,255,190,false,false,2,false,nil,nil,false)
                if i>1 then
                    local prev=points[i-1]
                    DrawLine(prev.x,prev.y,prev.z+0.15,p.x,p.y,p.z+0.15,74,168,255,190)
                end
            end

            if #points>0 then
                local last=points[#points]
                DrawLine(last.x,last.y,last.z+0.15,c.x,c.y,c.z+0.15,74,168,255,120)
                if #points>=3 then
                    local first=points[1]
                    DrawLine(c.x,c.y,c.z+0.15,first.x,first.y,first.z+0.15,74,168,255,80)
                end
            end

            DisableControlAction(0,200,true)

            if IsControlJustPressed(0,38) then -- E
                local p={x=round2(c.x),y=round2(c.y),z=round2(c.z)}
                points[#points+1]=p
                safeZoneCapture.minCapturedZ=safeZoneCapture.minCapturedZ and math.min(safeZoneCapture.minCapturedZ,p.z) or p.z
                safeZoneCapture.maxCapturedZ=safeZoneCapture.maxCapturedZ and math.max(safeZoneCapture.maxCapturedZ,p.z) or p.z
                TriggerEvent('Notify','sucesso',('Ponto %d adicionado.'):format(#points),1500)

            elseif IsControlJustPressed(0,177) then -- BACKSPACE
                if #points<3 then
                    TriggerEvent('Notify','negado','Adicione pelo menos 3 pontos para formar o polígono.',3000)
                else
                    local payload={
                        action='safeZonePolygonCaptured',
                        target=safeZoneCapture.target,
                        coords={},
                        minCapturedZ=safeZoneCapture.minCapturedZ,
                        maxCapturedZ=safeZoneCapture.maxCapturedZ
                    }

                    for _,p in ipairs(points) do
                        payload.coords[#payload.coords+1]={x=p.x,y=p.y}
                    end

                    safeZoneCapture=nil
                    SendNUIMessage(payload)
                    setPanel(true)
                end

            elseif IsControlJustPressed(0,73) then -- X
                local target=safeZoneCapture.target
                safeZoneCapture=nil
                SendNUIMessage({action='safeZonePolygonCancelled',target=target})
                setPanel(true)
            end
        else
            Wait(400)
        end
    end
end)

AddEventHandler('onResourceStop',function(resource)
    if resource~=GetCurrentResourceName() then return end
    if panelOpen or positionMode or safeZoneCapture then SetNuiFocus(false,false) end
end)

RegisterNUICallback('createClothingShop',function(data,cb) cb(Server.createClothingShop(data)) end)
RegisterNUICallback('updateClothingShop',function(data,cb) cb(Server.updateClothingShop(data)) end)
RegisterNUICallback('deleteClothingShop',function(data,cb) cb(Server.deleteClothingShop(data and data.id)) end)

RegisterNUICallback('createBarbershop',function(data,cb) cb(Server.createBarbershop(data)) end)
RegisterNUICallback('updateBarbershop',function(data,cb) cb(Server.updateBarbershop(data)) end)
RegisterNUICallback('deleteBarbershop',function(data,cb) cb(Server.deleteBarbershop(data and data.id)) end)

RegisterNUICallback('createTattooShop',function(data,cb)
    cb(Server.createTattooShop(data))
end)

RegisterNUICallback('updateTattooShop',function(data,cb)
    cb(Server.updateTattooShop(data))
end)

RegisterNUICallback('deleteTattooShop',function(data,cb)
    cb(Server.deleteTattooShop(data and data.id))
end)


RegisterNUICallback('saveCloakroom',function(data,cb)
    cb(Server.saveCloakroom(data))
end)

RegisterNUICallback('deleteCloakroom',function(data,cb)
    cb(Server.deleteCloakroom(data and data.name))
end)

RegisterNUICallback('getCurrentOutfit',function(_,cb)
    if not Server.hasAccess() then
        cb({ok=false,message='Sem permissão.'})
        return
    end

    local ped=PlayerPedId()
    local model=GetEntityModel(ped)
    local male=GetHashKey('mp_m_freemode_01')
    local female=GetHashKey('mp_f_freemode_01')
    local gender=nil

    if model==male then
        gender='masculino'
    elseif model==female then
        gender='feminino'
    else
        cb({ok=false,message='Use um personagem freemode masculino ou feminino para capturar o fardamento.'})
        return
    end

    local outfit={}

    -- Componentes completos do ped: máscara, cabelo, torso, calça, mochila,
    -- sapato, acessórios, camisa, colete, decals e jaqueta.
    for component=0,11 do
        -- Componente 2 = cabelo. Não deve fazer parte do fardamento.
        if component ~= 2 then
            outfit[tostring(component)]={
                GetPedDrawableVariation(ped,component),
                GetPedTextureVariation(ped,component),
                GetPedPaletteVariation(ped,component)
            }
        end
    end

    -- Props completos: chapéu, óculos, orelha, relógio, pulseira etc.
    for prop=0,7 do
        outfit['p'..prop]={
            GetPedPropIndex(ped,prop),
            GetPedPropTextureIndex(ped,prop)
        }
    end

    cb({ok=true,gender=gender,outfit=outfit})
end)


RegisterNUICallback(
    'createMapMarking',
    function(data, cb)
        cb(Server.createMapMarking(data))
    end
)

RegisterNUICallback(
    'updateMapMarking',
    function(data, cb)
        cb(Server.updateMapMarking(data))
    end
)

RegisterNUICallback(
    'deleteMapMarking',
    function(data, cb)
        cb(Server.deleteMapMarking(data and data.id))
    end
)


RegisterNUICallback('saveManagedGroup',function(data,cb)
    cb(Server.saveManagedGroup(data))
end)

RegisterNUICallback('deleteManagedGroup',function(data,cb)
    cb(Server.deleteManagedGroup(data and data.name))
end)


RegisterNUICallback('createFacGroups',function(data,cb)
    cb(Server.createFacGroups(data))
end)


RegisterNUICallback('deleteFacBundle',function(data,cb)
    cb(Server.deleteFacBundle(data))
end)


RegisterNUICallback('createDesmanche',function(data,cb)
    cb(Server.createDesmanche(data))
end)

RegisterNUICallback('updateDesmanche',function(data,cb)
    cb(Server.updateDesmanche(data))
end)

RegisterNUICallback('deleteDesmanche',function(data,cb)
    cb(Server.deleteDesmanche(data and data.name))
end)

RegisterNUICallback('saveDesmancheSettings',function(data,cb)
    cb(Server.saveDesmancheSettings(data))
end)


RegisterNUICallback('createSafeZone',function(data,cb)
    cb(Server.createSafeZone(data))
end)

RegisterNUICallback('updateSafeZone',function(data,cb)
    cb(Server.updateSafeZone(data))
end)

RegisterNUICallback('deleteSafeZone',function(data,cb)
    cb(Server.deleteSafeZone(data and data.name))
end)

RegisterNUICallback('saveSafeZoneSettings',function(data,cb)
    cb(Server.saveSafeZoneSettings(data))
end)


RegisterNUICallback('updateJob',function(data,cb)
    cb(Server.updateJob(data))
end)

RegisterNUICallback('captureJobUniform',function(data,cb)
    cb(Server.captureJobUniform(data))
end)

RegisterNUICallback('saveJobsGlobal',function(data,cb)
    cb(Server.saveJobsGlobal(data))
end)


RegisterNUICallback('saveRobberySetup',function(data,cb) cb(Server.saveRobberySetup(data)) end)
RegisterNUICallback('addRobberyLocation',function(data,cb) cb(Server.addRobberyLocation(data)) end)
RegisterNUICallback('updateRobberyLocation',function(data,cb) cb(Server.updateRobberyLocation(data)) end)
RegisterNUICallback('deleteRobberyLocation',function(data,cb) cb(Server.deleteRobberyLocation(data)) end)
RegisterNUICallback('saveRobberyGlobalSettings',function(data,cb) cb(Server.saveRobberyGlobalSettings(data)) end)

RegisterNUICallback('saveBancoCentral',function(data,cb) cb(Server.saveBancoCentral(data)) end)

RegisterNUICallback('saveJoalheria',function(data,cb) cb(Server.saveJoalheria(data)) end)

RegisterNUICallback('saveRoubocofre',function(data,cb) cb(Server.saveRoubocofre(data)) end)


RegisterNUICallback('saveResidence',function(data,cb) cb(Server.saveResidence(data)) end)
RegisterNUICallback('deleteResidence',function(data,cb) cb(Server.deleteResidence(data)) end)
RegisterNUICallback('saveResidenceInterior',function(data,cb) cb(Server.saveResidenceInterior(data)) end)
RegisterNUICallback('deleteResidenceInterior',function(data,cb) cb(Server.deleteResidenceInterior(data)) end)
RegisterNUICallback('saveResidencesSettings',function(data,cb) cb(Server.saveResidencesSettings(data)) end)




RegisterNUICallback('saveServerVehicle',function(data,cb) cb(Server.saveServerVehicle(data)) end)
RegisterNUICallback('deleteServerVehicle',function(data,cb) cb(Server.deleteServerVehicle(data)) end)
RegisterNUICallback('deleteServerVehiclesBatch',function(data,cb) cb(Server.deleteServerVehiclesBatch(data)) end)
RegisterNUICallback('saveDealershipVehicle',function(data,cb) cb(Server.saveDealershipVehicle(data)) end)
RegisterNUICallback('deleteDealershipVehicle',function(data,cb) cb(Server.deleteDealershipVehicle(data)) end)
RegisterNUICallback('saveDealershipSettings',function(data,cb) cb(Server.saveDealershipSettings(data)) end)
