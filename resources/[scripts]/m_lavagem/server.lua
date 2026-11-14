local Proxy=module('vrp','lib/Proxy')
local vRP=Proxy.getInterface('vRP')
local KEY='sprintwash:v1:state'
local state={factions={},deposits={},history={},seq=0,vaults={}}
local busy=false
local function integer(v,min,max)
  local n=tonumber(v)
  if not n or n~=math.floor(n) or n<(min or 0) or n>(max or 1000000000) then return nil end
  return n
end
local function copy(t) return json.decode(json.encode(t)) end
local function save() vRP.setSData(KEY,json.encode(state)) end
local function initialize()
  local raw=vRP.getSData(KEY)
  if raw and raw~='' then
    local ok,decoded=pcall(json.decode,raw)
    if ok and type(decoded)=='table' then state=decoded end
  end
  state.factions=state.factions or {};state.deposits=state.deposits or {};state.history=state.history or {};state.seq=state.seq or 0;state.vaults=state.vaults or {}
  for k,v in pairs(Config.Factions) do
    if not state.factions[k] then state.factions[k]=copy(v) end
    state.deposits[k]=state.deposits[k] or {};state.vaults[k]=state.vaults[k] or {balance=0,withdrawals={}}
    local f=state.factions[k]
    f.memberPermission=f.memberPermission or v.memberPermission
    f.washGroups=f.washGroups or copy(v.washGroups)
    f.vaultGroups=f.vaultGroups or copy(v.vaultGroups)
    f.washPermissions=f.washPermissions or {}
    f.vaultPermissions=f.vaultPermissions or {}
  end
end
initialize()
local function admin(id)
  if not id then return false end
  for _,p in ipairs(Config.AdminPermissions) do if vRP.hasPermission(id,p) then return true end end
  for _,g in ipairs(Config.AdminGroups) do if vRP.hasGroup(id,g) then return true end end
  return false
end
local function notify(src,msg) TriggerClientEvent('sprintwash:notify',src,msg) end
local function groupsCatalog()
  local raw=LoadResourceFile('vrp','cfg/groups.json') or '{}'
  local ok,obj=pcall(json.decode,raw)
  local names={}
  if ok and type(obj)=='table' and type(obj.groups)=='table' then
    for _,g in ipairs(obj.groups) do if type(g.name)=='string' then names[#names+1]=g.name end end
  end
  table.sort(names)
  return names
end
local function points()
  local out={}
  for k,f in pairs(state.factions) do out[k]={label=f.label,coords=f.coords,blip=f.blip,marker=f.marker,name=f.name,enabled=f.enabled} end
  return out
end
local function sync() TriggerClientEvent('sprintwash:points',-1,points()) end
local function near(src,f)
  if not f.coords then return false end
  local ped=GetPlayerPed(src);if ped==0 then return false end
  local pos=GetEntityCoords(ped)
  return #(pos-vector3(f.coords.x,f.coords.y,f.coords.z))<=Config.MaxServerDistance
end
local function matches(id,groups,permissions)
  for _,g in ipairs(groups or {}) do if vRP.hasGroup(id,g) then return true end end
  for _,p in ipairs(permissions or {}) do if vRP.hasPermission(id,p) then return true end end
  return false
end
-- Sem bypass de admin: o jogador precisa pertencer a faccao correta.
local function member(id,f)
  return f.memberPermission and f.memberPermission~='' and vRP.hasPermission(id,f.memberPermission)==true
end
local function allowed(id,f)
  return member(id,f) and matches(id,f.washGroups,f.washPermissions)
end
local function vaultAllowed(id,f)
  return member(id,f) and matches(id,f.vaultGroups,f.vaultPermissions)
end
local function countItems(id,item) return tonumber(vRP.getInventoryItemAmount(id,item)) or 0 end
local function pendingSum(key)
  local n=0
  for _,d in ipairs(state.deposits[key] or {}) do if d.status=='pending' then n=n+d.amount end end
  return n
end
local function workerPayload(id,key)
  local f=state.factions[key]
  return {faction=key,label=f.label,fee=f.fee,perBleach=f.perBleach,dirty=pendingSum(key),bleach=countItems(id,Config.BleachItem),canWash=allowed(id,f),canDeposit=member(id,f),deposits=member(id,f) and state.deposits[key] or {},vaultBalance=(state.vaults[key] or {}).balance or 0,canVault=vaultAllowed(id,f)}
end
local function sendWorker(src,key)
  local id=vRP.getUserId(src);local f=state.factions[key]
  if not id or not f or not f.enabled or not near(src,f) or not member(id,f) then notify(src,'Acesso negado: voce nao pertence a esta organizacao.');return end
  TriggerClientEvent('sprintwash:open',src,'worker',workerPayload(id,key))
end
local function sendAdmin(src)
  local id=vRP.getUserId(src);if not admin(id) then notify(src,'Acesso administrativo negado.');return end
  local recent={}
  for i=#state.history,math.max(1,#state.history-49),-1 do recent[#recent+1]=state.history[i] end
  TriggerClientEvent('sprintwash:open',src,'admin',{factions=state.factions,vaults=state.vaults,groups=groupsCatalog(),counts={vanilla=pendingSum('vanilla'),bahamas=pendingSum('bahamas')}})
end
RegisterCommand('lavagemadmin',function(src)
  if src>0 then sendAdmin(src) end
end,false)
RegisterCommand('lavagembau',function(src,args)
  if src<=0 then return end
  local id=vRP.getUserId(src)
  local key=tostring(args[1] or ''):lower()
  local f=state.factions[key]
  if not f then
    for k,candidate in pairs(state.factions) do
      if vaultAllowed(id,candidate) then key=k;f=candidate;break end
    end
  end
  if not f or not vaultAllowed(id,f) then notify(src,'Sem permissao para o cofre de lavagem.');return end
  TriggerClientEvent('sprintwash:open',src,'vault',{faction=key,label=f.label,balance=state.vaults[key].balance,canWithdraw=true,withdrawals=state.vaults[key].withdrawals})
end,false)
RegisterCommand('lavagem',function(src,args)
  if src<=0 then return end
  local key=tostring(args[1] or ''):lower()
  if key~='' then sendWorker(src,key);return end
  for k,f in pairs(state.factions) do if f.enabled and near(src,f) then sendWorker(src,k);return end end
  notify(src,'Va ate o ponto de lavagem da sua faccao.')
end,false)
RegisterNetEvent('sprintwash:sync',function() TriggerClientEvent('sprintwash:points',source,points()) end)
RegisterNetEvent('sprintwash:openWorker',function(key) sendWorker(source,tostring(key)) end)
local function runLocked(fn)
  if busy then return false,'Outra operacao esta em andamento.' end
  busy=true
  local ok,err=pcall(fn)
  busy=false
  if not ok then print('^1[Sprint Wash] '..tostring(err)..'^7');return false,'Falha interna. Verifique o console.' end
  return true
end
local function doDeposit(src,id,key,amount)
  local f=state.factions[key]
  if not f or not f.enabled or not near(src,f) or not member(id,f) then notify(src,'Voce nao pertence a esta organizacao.');return end
  amount=integer(amount,1,Config.MaxPerOperation)
  if not amount or countItems(id,Config.DirtyItem)<amount then notify(src,'Dinheiro sujo insuficiente ou valor invalido.');return end
  local ok,msg=runLocked(function()
    if not vRP.tryGetInventoryItem(id,Config.DirtyItem,amount,true) then notify(src,'Nao foi possivel retirar dinheiro sujo.');return end
    state.seq=state.seq+1
    state.deposits[key][#state.deposits[key]+1]={id=state.seq,userId=id,amount=amount,remaining=amount,status='pending',created=os.time()}
    save()
    notify(src,'Deposito registrado: R$ '..amount)
    sendWorker(src,key)
  end)
  if not ok then notify(src,msg) end
end
local function doWash(src,id,key,amount)
  local f=state.factions[key]
  if not f or not f.enabled or not allowed(id,f) or not near(src,f) then notify(src,'Sem acesso.');return end
  amount=integer(amount,1,Config.MaxPerOperation)
  if not amount or amount>pendingSum(key) then notify(src,'Valor invalido ou sem deposito suficiente.');return end
  local bleach=math.ceil(amount/f.perBleach)
  if countItems(id,Config.BleachItem)<bleach then notify(src,'Alvejante insuficiente: precisa de '..bleach..'.');return end
  local ok,msg=runLocked(function()
    if not vRP.tryGetInventoryItem(id,Config.BleachItem,bleach,true) then notify(src,'Falha ao retirar alvejante.');return end
    state.seq=state.seq+1
    local operation={id=state.seq,employee=id,faction=key,amount=amount,bleach=bleach,fee=f.fee,commission=math.floor(amount*f.fee/100),status='processing',created=os.time(),payments={}}
    local remaining=amount
    for _,d in ipairs(state.deposits[key]) do
      if remaining<=0 then break end
      if d.status=='pending' then
        local used=math.min(d.remaining,remaining)
        d.remaining=d.remaining-used
        if d.remaining==0 then d.status='consumed' end
        operation.payments[#operation.payments+1]={userId=d.userId,amount=used,paid=false}
        remaining=remaining-used
      end
    end
    state.history[#state.history+1]=operation
    save()
    -- O lavador recebe 70% em notas limpas no inventario, para entrega manual.
    -- Nao creditar o cliente no banco nem automaticamente no inventario dele.
    -- Registro previo evita repeticao automatica em caso de reinicio inesperado.
    local cleanAmount=amount-operation.commission
    operation.cleanAmount=cleanAmount
    operation.cleanRecipient=id
    operation.payoutStatus='crediting'
    save()
    local credited=true
    if cleanAmount>0 then credited=(vRP.giveMoney(id,cleanAmount)==true) end
    if not credited then
      operation.payoutStatus='review'
      operation.status='review'
      save()
      notify(src,'Falha ao entregar notas limpas. Operacao bloqueada para revisao manual; confira inventario e logs.')
      sendWorker(src,key)
      return
    end
    operation.payoutStatus='paid'
    operation.status='vault_pending'
    save()
    local vault=state.vaults[key]
    vault.balance=vault.balance+operation.commission
    operation.chestPaid=true
    operation.status='done';operation.completed=os.time()
    save()
    notify(src,'Lavagem concluida. Notas limpas entregues ao seu inventario; entregue-as ao cliente. Comissao no cofre.')
    sendWorker(src,key)
  end)
  if not ok then notify(src,msg) end
end
RegisterNetEvent('sprintwash:action',function(action,data)
  local src=source;local id=vRP.getUserId(src)
  if not id or type(data)~='table' or type(action)~='string' then return end
  if action=='deposit' then doDeposit(src,id,tostring(data.faction or ''),data.amount);return end
  if action=='wash' then doWash(src,id,tostring(data.faction or ''),data.amount);return end
  if action=='refreshWorker' then sendWorker(src,tostring(data.faction or ''));return end
  if action=='refreshAdmin' then sendAdmin(src);return end
  if action=='openVault' then
    local key=tostring(data.faction or '')
    local f=state.factions[key]
    if not f or not member(id,f) or not allowed(id,f) or not near(src,f) then notify(src,'Acesso negado ao cofre desta lavagem.');return end
    TriggerClientEvent('sprintwash:open',src,'vault',{faction=key,label=f.label,balance=state.vaults[key].balance,canWithdraw=vaultAllowed(id,f),withdrawals=vaultAllowed(id,f) and state.vaults[key].withdrawals or {}})
    return
  end
  if action=='withdrawVault' then
    local key=tostring(data.faction or '')
    local f=state.factions[key]
    local amount=integer(data.amount,1,Config.MaxPerOperation)
    if not f or not vaultAllowed(id,f) or not near(src,f) or not amount then notify(src,'Saque negado.');return end
    local ok,msg=runLocked(function()
      local vault=state.vaults[key]
      if amount>vault.balance then notify(src,'Saldo insuficiente no cofre.');return end
      -- Persistir debito ANTES de creditar: falha entre as etapas requer
      -- revisao manual, nunca saque duplicado.
      state.seq=state.seq+1
      local entry={id=state.seq,userId=id,amount=amount,status='crediting',created=os.time()}
      vault.balance=vault.balance-amount
      vault.withdrawals[#vault.withdrawals+1]=entry
      save()
      local given=vRP.giveMoney(id,amount)
      if given~=true then
        entry.status='review'
        save()
        notify(src,'Saque pendente de revisao. Nao tente repetir antes de conferir logs.')
        return
      end
      entry.status='paid';save()
      notify(src,'Saque de R$ '..amount..' realizado.')
      TriggerClientEvent('sprintwash:open',src,'vault',{faction=key,label=f.label,balance=vault.balance,canWithdraw=true,withdrawals=vault.withdrawals})
    end)
    if not ok then notify(src,msg) end
    return
  end
  if action=='saveFaction' then
    if not admin(id) then return end
    local key=tostring(data.faction or '');local f=state.factions[key]
    local incoming=data.config
    if not f or type(incoming)~='table' then return end
    local fee=integer(incoming.fee,0,100)
    local perBleach=integer(incoming.perBleach,1,10000000)
    local permission=tostring(incoming.permission or '')
    local name=tostring(incoming.name or '')
    if not fee or not perBleach or #permission<3 or #permission>90 or #name<1 or #name>60 then notify(src,'Valores invalidos.');return end
    local coords=nil
    if incoming.coords then
      local x,y,z=tonumber(incoming.coords.x),tonumber(incoming.coords.y),tonumber(incoming.coords.z)
      if not x or not y or not z or math.abs(x)>10000 or math.abs(y)>10000 or math.abs(z)>3000 then notify(src,'Coordenadas invalidas.');return end
      coords={x=x,y=y,z=z}
    end
    local function validList(list)
      if type(list)~='table' or #list>40 then return nil end
      local out={}
      for _,value in ipairs(list) do
        if type(value)~='string' or #value<2 or #value>90 or not value:match('^[%w_.%-]+$') then return nil end
        out[#out+1]=value
      end
      return out
    end
    local catalog={}
    for _,g in ipairs(groupsCatalog()) do catalog[g]=true end
    local wg=validList(incoming.washGroups)
    local vg=validList(incoming.vaultGroups)
    local wp=validList(incoming.washPermissions)
    local vp=validList(incoming.vaultPermissions)
    if not wg or not vg or not wp or not vp or (#wg+#wp)==0 or (#vg+#vp)==0 then notify(src,'Selecione cargos validos para lavar e para o cofre.');return end
    for _,g in ipairs(wg) do if not catalog[g] then notify(src,'Cargo inexistente: '..g);return end end
    for _,g in ipairs(vg) do if not catalog[g] then notify(src,'Cargo inexistente: '..g);return end end
    -- A permissao de organizacao e fixa por faccao, para impedir mistura.
    f.washGroups=wg;f.vaultGroups=vg;f.washPermissions=wp;f.vaultPermissions=vp
    f.fee=fee;f.perBleach=perBleach;f.permission=permission;f.name=name;f.enabled=incoming.enabled==true;f.blip=incoming.blip==true;f.marker=incoming.marker==true;f.coords=coords
    save();sync();notify(src,'Configuracao salva.');sendAdmin(src)
  end
end)
CreateThread(function() Wait(2500);sync() end)
