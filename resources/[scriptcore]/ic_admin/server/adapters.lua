local I=ICAdmin
local A={}; I.Adapter=A
function A.itemCatalog() return I.vRP.getAllItens() or {} end
function A.validItem(item)
    item=I.text(item,80,true,'Item')
    local entry=A.itemCatalog()[item]
    if not entry then I.fail('INVALID_ITEM','Item não encontrado no catálogo da base.') end
    return item,entry
end
function A.ammoForWeapon(weapon)
    local catalog=A.itemCatalog();local entry=catalog[weapon]
    if not entry then return nil end
    if type(entry.ammo)=='string' and catalog[entry.ammo] and catalog[entry.ammo].type=='recharge' then return entry.ammo end
    local candidate='ammo_'..tostring(weapon):lower():gsub('^wbody|',''):gsub('^weapon_','')
    if catalog[candidate] and catalog[candidate].type=='recharge' then return candidate end
end
function A.vehicleCatalog()
    local raw=LoadResourceFile('m_garage','shared-side/listcars.json')
    local ok,list=pcall(json.decode,raw or '')
    if not ok or type(list)~='table' then I.fail('RESOURCE_UNAVAILABLE','Catálogo da garagem indisponível.') end
    return list
end
function A.validVehicle(spawn)
    spawn=I.text(spawn,64,true,'Veículo'):lower()
    if not spawn:match('^[%w_-]+$') or not A.vehicleCatalog()[spawn] then I.fail('INVALID_VEHICLE','Veículo não encontrado na garagem.') end
    return spawn
end
function A.giveItem(id,item,amount)
    I.target(id,true); item=A.validItem(item); amount=I.int(amount,1,1000000,'Quantidade')
    local weight=tonumber(I.vRP.getItemWeight(item)) or 0
    local current=tonumber(I.vRP.computeInvWeight(id)) or 0
    local maximum=tonumber(I.vRP.getInventoryMaxWeight(id)) or 0
    if current+weight*amount>maximum then I.fail('INVENTORY_FULL','O inventário não comporta a entrega.') end
    if I.vRP.giveInventoryItem(id,item,amount,true)~=true then I.fail('DELIVERY_FAILED','Não foi possível entregar o item.') end
    return true
end
function A.giveVehicle(id,spawn)
    I.target(id,true); spawn=A.validVehicle(spawn)
    local affected=I.Store.update('INSERT IGNORE INTO vrp_user_veiculos(user_id,veiculo,ipva) VALUES(?,?,?)',{id,spawn,os.time()})
    if affected~=1 then I.fail('VEHICLE_EXISTS','O jogador já possui esse veículo.') end
    return true
end
function A.groups(id)
    local out={};for name,present in pairs(I.vRP.getUserGroups(id) or {}) do if present then out[#out+1]=name end end
    table.sort(out);return out
end
function I.snapshot(value)
    local id,source=I.target(value,false)
    local identity=I.vRP.getUserIdentity(id) or {}
    local name=((identity.nome or '')..' '..(identity.sobrenome or '')):match('^%s*(.-)%s*$')
    local out={id=id,name=name~='' and name or ('Passaporte #'..id),online=source~=nil,source=source,
        ping=source and GetPlayerPing(source) or nil,
        identity={nome=identity.nome,sobrenome=identity.sobrenome,idade=identity.idade,telefone=identity.telefone,registro=identity.registro},
        wallet=source and (tonumber(I.vRP.getMoney(id)) or 0) or nil,bank=tonumber(I.vRP.getBankMoney(id)) or 0,
        groups=source and A.groups(id) or {},inventory={}}
    if source then
        for slot,entry in pairs(I.vRP.getInventory(id) or {}) do
            if type(entry)=='table' then out.inventory[#out.inventory+1]={slot=tostring(slot),item=entry.item,amount=tonumber(entry.amount) or 0,name=I.vRP.getItemName(entry.item) or entry.item} end
        end
    end
    local subject=I.subject(id)
    out.warnings=I.Store.query("SELECT id,reason,starts_at,ends_at,state FROM ic_admin_discipline WHERE subject_key=? AND kind='warning' ORDER BY id DESC LIMIT 100",{subject})
    return out
end
function I.onlinePlayers()
    local players={}
    for _,sourceString in ipairs(GetPlayers()) do
        local source=tonumber(sourceString);local id=I.vRP.getUserId(source)
        if id and not (I.userLocks and I.userLocks[id]) then
            local identity=I.vRP.getUserIdentity(id) or {}
            local ped=GetPlayerPed(source);local coords=ped~=0 and GetEntityCoords(ped) or nil
            players[#players+1]={id=id,source=source,name=(identity.nome or GetPlayerName(source) or '')..' '..(identity.sobrenome or ''),ping=GetPlayerPing(source),coords=coords and {x=coords.x,y=coords.y,z=coords.z},bucket=GetPlayerRoutingBucket(source)}
        end
    end
    table.sort(players,function(a,b)return a.id<b.id end); return players
end
function A.banActive(id)
    return I.Store.query('SELECT user_id FROM mirtin_bans WHERE user_id=? AND (time=0 OR time>UNIX_TIMESTAMP()) LIMIT 1',{id})[1]~=nil
end
function A.recordDiscipline(ctx,id,kind,reason,state)
    return I.Store.insert('INSERT INTO ic_admin_discipline(subject_key,user_id,actor_id,kind,reason,starts_at,state) VALUES(?,?,?,?,?,?,?)',{I.subject(id),id,ctx.userId,kind,reason,os.time(),state or 'archived'})
end
function A.setBan(ctx,id,banned,reason)
    local _,source=I.target(id,false)
    I.effect(ctx)
    local statements
    if banned then
        statements={{query='INSERT INTO mirtin_bans(user_id,motivo,banimento,desbanimento,time,hwid,owner,staff) VALUES(?,?,?,?,0,0,0,?) ON DUPLICATE KEY UPDATE motivo=VALUES(motivo),banimento=VALUES(banimento),desbanimento=VALUES(desbanimento),time=0,staff=VALUES(staff)',values={id,reason,os.date('%d/%m/%Y às %H:%M'),'Nunca',ctx.userId}}}
    else
        statements={
            {query='DELETE FROM mirtin_bans WHERE user_id=?',values={id}},
            {query='DELETE FROM mirtin_bans_hwid WHERE id=?',values={id}},
            {query='DELETE FROM mirtin_bans_ip WHERE user_id=?',values={id}}
        }
    end
    if not I.Store.transaction(statements) then I.fail('STORAGE_ERROR','Não foi possível alterar o banimento.') end
    local refreshed=exports['vrp']:icAdminRefreshBanCaches()
    if refreshed~=true then I.fail('CACHE_ERROR','Banimento persistido; cache exige conferência.') end
    A.recordDiscipline(ctx,id,banned and 'ban' or 'unban',reason)
    local currentSource=I.vRP.getUserSource(id)
    if banned and currentSource and I.vRP.getUserId(currentSource)==id then I.vRP.kick(currentSource,'Banido: '..reason) end
    return {id=id,banned=banned}
end
function A.checkGroupHierarchy(ctx,group,targetId)
    local definitions=I.vRP.getGroups() or {}
    if not definitions[group] then I.fail('INVALID_GROUP','Cargo não encontrado.') end
    local actorRank=I.Config.ranks[ctx.role] or 0
    local groupRank=I.Config.ranks[group] or 0
    if groupRank>=actorRank then I.fail('HIERARCHY','Não é possível alterar cargo igual ou superior ao seu.') end
    local targetRole=I.role(targetId)
    if targetRole and (I.Config.ranks[targetRole] or 0)>=actorRank then I.fail('HIERARCHY','O jogador possui cargo igual ou superior ao seu.') end
end
