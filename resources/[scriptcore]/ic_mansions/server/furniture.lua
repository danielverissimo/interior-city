local M=ICM
local function catalog()
    if not M.catalogItems then
        local raw=LoadResourceFile(GetCurrentResourceName(),ICMConfig.CatalogFile or'catalog.json')
        local ok,document=pcall(json.decode,raw or'')
        if not ok or type(document)~='table'or type(document.items)~='table'then M.fail('CATALOG_UNAVAILABLE','Catálogo de mobílias inválido.')end
        M.catalogItems={};M.catalogById={}
        for _,row in ipairs(document.items)do
            local item={id=M.text(row.id),name=M.text(row.name),model=M.text(row.model),category=M.text(row.category),price=M.integer(row.price,0,1000000000000)}
            if M.catalogById[item.id]then M.fail('CATALOG_UNAVAILABLE','Catálogo contém identificadores duplicados.')end
            M.catalogItems[#M.catalogItems+1]=item;M.catalogById[item.id]=item
        end
    end
    local out={items={}}
    for _,item in ipairs(M.catalogItems)do
        local row=M.copy(item);local override=M.state().catalogPrices[row.id]
        if override~=nil then row.price=M.integer(override,0,1000000000000)end
        out.items[#out.items+1]=row
    end
    return out
end
M.catalog=catalog
local function itemFor(id)
    M.text(id)
    for _,item in ipairs(catalog().items)do if item.id==id then return item end end
    M.fail('ITEM_NOT_FOUND','Mobília não encontrada no catálogo.')
end
local function furnitureFor(row,id)
    id=M.text(id);for i,f in ipairs(row.furniture or{})do if f.id==id then return f,i end end
    M.fail('FURNITURE_NOT_FOUND','Mobília não encontrada nesta mansão.')
end
local function placementCoords(row,coords,heading)
    local out=M.coords(coords);out.heading=M.number(heading,-360,360)
    if M.distance(out,row.purchaseCoords)>(ICMConfig.FurniturePlacementRadius or 100)then M.fail('OUTSIDE_PROPERTY','A mobília deve ficar no raio da mansão.')end
    return out
end
local function ownFurniture(ctx,row)
    M.owner(ctx,row,true);M.requireTax(row,ctx);M.noPending(row.id)
end
local function selectContext(ctx,id)
    local state=M.state();local position=M.position(ctx.source)
    if id then
        local row=M.find(id)
        if not M.isMember(row,ctx.userId)then M.near(ctx.source,row,ICMConfig.ManagementNearestDistance or 35)end
        return row
    end
    local own,nearestOwned,ownedDistance,nearestMember,memberDistance,nearestPublic,publicDistance={},nil,nil,nil,nil,nil,nil
    for _,row in ipairs(state.mansions)do
        local d=M.distance(position,row.purchaseCoords)
        if row.ownerId==ctx.userId then own[#own+1]=row end
        if row.ownerId==ctx.userId and d<=(ICMConfig.FurnitureAccessRadius or 80)and(not ownedDistance or d<ownedDistance)then nearestOwned,ownedDistance=row,d end
        if M.isMember(row,ctx.userId)and d<=(ICMConfig.FurnitureAccessRadius or 80)and(not memberDistance or d<memberDistance)then nearestMember,memberDistance=row,d end
        if d<=(ICMConfig.ManagementNearestDistance or 35)and(not publicDistance or d<publicDistance)then nearestPublic,publicDistance=row,d end
    end
    if nearestOwned then return nearestOwned end
    if nearestMember then return nearestMember end
    if #own==1 then return own[1]end
    if nearestPublic then return nearestPublic end
    M.fail('NOT_FOUND','Nenhuma mansão disponível neste local.')
end
function M.context(ctx,p)
    local selected,row=pcall(selectContext,ctx,p and p.mansionId)
    if not selected then
        local admin=M.inGroups(ctx.userId,ICMConfig.AdminGroups or{developer=true,dono=true})
        if not(p and p.mansionId)and admin and type(row)=='table'and row.code=='NOT_FOUND'then
            local c=catalog();c.canConfigure=true
            return{mansions={},mansionName='Configuração de mansões',members={},furniture={},maxResidents=0,
                canManage=false,canConfigure=true,canFurniture=false,canPurchase=false,canPayIptu=false,
                canCleanup=false,purchaseAvailable=false,catalog=c,pendingOperations={},sellPercent=ICMConfig.FurnitureSellPercent or 15}
        end
        error(row,0)
    end
    local isMember=M.isMember(row,ctx.userId);local owner=row.ownerId==ctx.userId
    if isMember and(tonumber(row.iptuPaidUntil)or 0)<=0 then M.taxValid(row,ctx,true);row=M.find(row.id)end
    local tax=(tonumber(row.iptuPaidUntil)or 0)>os.time();local c=catalog()
    c.canConfigure=M.inGroups(ctx.userId,ICMConfig.AdminGroups or{developer=true,dono=true})
    local distance=M.distance(M.position(ctx.source),row.purchaseCoords)
    local members=isMember and M.residents(row)or{}
    local furniture={}
    if isMember then for _,f in ipairs(row.furniture or{})do local copy=M.copy(f);copy.refundAmount=math.floor((tonumber(f.paidPrice)or 0)*(ICMConfig.FurnitureSellPercent or 15)/100);furniture[#furniture+1]=copy end end
    local available={}
    for _,m in ipairs(M.state().mansions)do
        if M.isMember(m,ctx.userId)or M.distance(M.position(ctx.source),m.purchaseCoords)<=(ICMConfig.ManagementNearestDistance or 35)then
            available[#available+1]={id=m.id,name=m.name,occupied=m.ownerId~=nil,owned=m.ownerId==ctx.userId}
        end
    end
    local pending=M.pending(row.id)
    local owned=0;for _,entry in ipairs(M.state().mansions)do if entry.ownerId==ctx.userId then owned=owned+1 end end
    return{mansions=available,mansionId=row.id,mansionName=row.name,ownerId=isMember and row.ownerId or nil,
        members=members,maxResidents=row.maxResidents,iptuValue=row.iptuValue,iptuPaidUntil=row.iptuPaidUntil,
        canManage=owner and#pending==0 and(owned==1 or distance<=(ICMConfig.ManagementNearestDistance or 35)),canConfigure=c.canConfigure,canFurniture=owner and tax and#pending==0 and distance<=(ICMConfig.FurnitureAccessRadius or 80),
        canPurchase=not row.ownerId and#pending==0 and distance<=(ICMConfig.PurchaseDistance or 2),
        canPayIptu=isMember and not tax and#pending==0,purchaseAvailable=not row.ownerId,
        catalog=c,furniture=furniture,voucher=row.voucher,voucherLabel=(ICMConfig.AllowedVouchers or{})[row.voucher],price=row.price,
        sellPercent=ICMConfig.FurnitureSellPercent or 15,pendingOperations=isMember and pending or{},
        canCleanup=M.inGroups(ctx.userId,ICMConfig.CleanupGroups or{developer=true,dono=true,admin=true})and row.ownerId~=nil and distance<=(ICMConfig.CleanupDistance or 10)}
end
M.register('getContext',false,M.context)
M.register('getFurnitureContext',false,M.context)
M.register('beginFurniturePurchase',false,function(ctx,p)
    local row=M.find(p.mansionId);ownFurniture(ctx,row);local item=itemFor(p.itemId)
    local token=M.token('placement');M.placements[token]={source=ctx.source,userId=ctx.userId,mansionId=row.id,itemId=item.id,quotedPrice=item.price,expires=os.time()+180}
    return{placementToken=token,item=item,mansionId=row.id}
end)
M.register('cancelFurniturePlacement',false,function(ctx,p)
    local token=M.text(p.placementToken);local placement=M.placements[token]
    if placement and placement.userId==ctx.userId and placement.source==ctx.source then M.placements[token]=nil end
    return{cancelled=true}
end)
M.register('confirmFurniturePlacement',true,function(ctx,p)
    local token=M.text(p.placementToken);local placement=M.placements[token];M.placements[token]=nil
    if not placement or placement.source~=ctx.source or placement.userId~=ctx.userId or placement.mansionId~=p.mansionId or placement.itemId~=p.itemId or placement.expires<os.time()then M.fail('STALE_PLACEMENT','O posicionamento expirou. Inicie novamente.')end
    local row=M.find(p.mansionId);ownFurniture(ctx,row);local item=itemFor(p.itemId);local coords=placementCoords(row,p.coords,p.heading)
    if item.price~=placement.quotedPrice then M.fail('PRICE_CHANGED','O preço da mobília mudou. Confira o novo preço e inicie o posicionamento novamente.')end
    local charged,known=false,true
    return M.change(ctx,row.id,'furniture_purchase',{itemId=item.id,amount=item.price,coords=coords},function()
        known=false;local paid=M.vRP.tryFullPayment(ctx.userId,item.price);known=true
        if paid~=true then M.fail('INSUFFICIENT_FUNDS','Saldo insuficiente para a mobília.')end;charged=true
    end,function(current)
        current.furniture=current.furniture or{}
        local id=M.token('furniture');current.furniture[#current.furniture+1]={id=id,itemId=item.id,model=item.model,name=item.name,paidPrice=item.price,
            x=coords.x,y=coords.y,z=coords.z,heading=coords.heading,placedBy=ctx.userId,createdAt=os.time()}
        current.updatedAt=os.time();return{message='Mobília comprada e posicionada.',furnitureId=id}
    end,function()return known and(not charged or M.refundCash(ctx.userId,item.price))end)
end)
M.register('updateFurniture',true,function(ctx,p)
    local row=M.find(p.mansionId);ownFurniture(ctx,row);local f=furnitureFor(row,p.furnitureId)
    if M.distance(M.position(ctx.source),f)>(ICMConfig.FurnitureEditDistance or 2.2)then M.fail('TOO_FAR','Aproxime-se da mobília para movê-la.')end
    local coords=placementCoords(row,p.coords,p.heading)
    local state=M.copy(M.state());local current=M.find(row.id,state);local target=furnitureFor(current,f.id)
    target.x=coords.x;target.y=coords.y;target.z=coords.z;target.heading=coords.heading;target.updatedAt=os.time()
    M.Store.save(state);M.broadcast();return{message='Mobília atualizada.'}
end)
M.register('sellFurniture',true,function(ctx,p)
    if p.confirmed~=true then M.fail('CONFIRMATION_REQUIRED','Confirme a venda da mobília.')end
    local row=M.find(p.mansionId);ownFurniture(ctx,row);local f,index=furnitureFor(row,p.furnitureId)
    if M.distance(M.position(ctx.source),f)>(ICMConfig.FurnitureEditDistance or 2.2)then M.fail('TOO_FAR','Aproxime-se da mobília para vendê-la.')end
    local refund=math.floor((tonumber(f.paidPrice)or 0)*(ICMConfig.FurnitureSellPercent or 15)/100)
    local state=M.copy(M.state());local current=M.find(row.id,state)
    local op=M.operation(state,'furniture_sale',ctx,row.id,{furnitureId=f.id,amount=refund,before=M.copy(row)})
    table.remove(current.furniture,index);state.operations[op].phase='credit_pending';M.Store.save(state)
    local ok,credited=pcall(M.refundCash,ctx.userId,refund)
    if not ok or not credited then M.fail('RECONCILIATION_REQUIRED','A mobília foi retirada, mas o crédito exige conferência. Não repita a venda.')end
    M.complete(state,op);M.broadcast();return{message='Mobília vendida.',refundAmount=refund}
end)
M.register('saveFurniturePrices',true,function(ctx,p)
    M.admin(ctx);M.table(p.prices);catalog()
    local state=M.copy(M.state());local count=0
    for id,price in pairs(p.prices)do
        itemFor(id);state.catalogPrices[id]=math.floor(M.number(price,0,1000000000000));count=count+1
        if count>10000 then M.fail('INVALID_INPUT','Quantidade de preços excedida.')end
    end
    M.Store.save(state);local current=catalog();current.canConfigure=true
    return{message='Preços atualizados.',catalog=current}
end)
