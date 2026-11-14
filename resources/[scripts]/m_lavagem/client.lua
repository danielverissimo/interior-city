local open=false
local points={}
local blips={}
local currentFaction=nil
local function close()
  open=false; SetNuiFocus(false,false); SendNUIMessage({type='close'})
end
RegisterNetEvent('sprintwash:open',function(mode,payload)
  open=true; SetNuiFocus(true,true)
  SendNUIMessage({type='open',mode=mode,payload=payload})
end)
RegisterNetEvent('sprintwash:notify',function(message)
  TriggerEvent('Notify','aviso',tostring(message))
end)
RegisterNetEvent('sprintwash:points',function(data)
  points=data or {}
  for _,b in ipairs(blips) do RemoveBlip(b) end
  blips={}
  for key,p in pairs(points) do
    if p.coords and p.blip then
      local b=AddBlipForCoord(p.coords.x+0.0,p.coords.y+0.0,p.coords.z+0.0)
      SetBlipSprite(b,500);SetBlipColour(b,3);SetBlipScale(b,0.75);SetBlipAsShortRange(b,true)
      BeginTextCommandSetBlipName('STRING');AddTextComponentString(p.name or 'Lavagem');EndTextCommandSetBlipName(b)
      blips[#blips+1]=b
    end
  end
end)
RegisterNUICallback('close',function(_,cb) close();cb({ok=true}) end)
RegisterNUICallback('action',function(data,cb)
  if data.action=='capture' then
    local p=GetEntityCoords(PlayerPedId())
    cb({ok=true,coords={x=math.floor(p.x*100)/100,y=math.floor(p.y*100)/100,z=math.floor(p.z*100)/100}})
  else
    TriggerServerEvent('sprintwash:action',data.action,data)
    cb({ok=true})
  end
end)
CreateThread(function()
  Wait(1500);TriggerServerEvent('sprintwash:sync')
  while true do
    local wait=1250
    local ped=PlayerPedId();local pos=GetEntityCoords(ped)
    currentFaction=nil
    for key,p in pairs(points) do
      if p.coords and p.enabled then
        local c=vector3(p.coords.x,p.coords.y,p.coords.z)
        local dist=#(pos-c)
        if dist<22.0 then
          wait=0
          if p.marker then DrawMarker(1,c.x,c.y,c.z-1.0,0,0,0,0,0,0,1.1,1.1,0.4,4,191,242,120,false,false,2,false,nil,nil,false) end
          if dist<Config.InteractionDistance then
            currentFaction=key
            BeginTextCommandDisplayHelp('STRING');AddTextComponentSubstringPlayerName('Pressione ~INPUT_CONTEXT~ para abrir a lavagem');EndTextCommandDisplayHelp(0,false,true,-1)
            if IsControlJustReleased(0,38) and not open then TriggerServerEvent('sprintwash:openWorker',key) end
          end
        end
      end
    end
    Wait(wait)
  end
end)
