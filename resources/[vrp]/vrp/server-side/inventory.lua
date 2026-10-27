 local cache = {}
cache['inArena'] = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SETARENA
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.setArena(source, status)
	if status then
		cache['inArena'][source] = true
	else
		cache['inArena'][source] = nil
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CRIAR ITENS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local tn = tonumber
local ts = tostring

local function mageInvOrigin()
    return type(vRP.mageAuditOrigin) == "function" and vRP.mageAuditOrigin() or (GetInvokingResource() or GetCurrentResourceName() or "vrp")
end

local function mageInvIn(context)
    return type(vRP.mageAuditIn) == "function" and vRP.mageAuditIn(context) or false
end

local function mageInvSuppressed()
    return mageInvIn("vrp_give_money") or mageInvIn("vrp_bank_withdraw") or mageInvIn("vrp_bank_deposit")
        or mageInvIn("vrp_full_payment") or mageInvIn("vrp_try_payment")
end

local function mageInvLog(key, user_id, details)
    if type(vRP.mageAuditLog) == "function" then
        vRP.mageAuditLog(key, {
            actorId = tonumber(user_id),
            actorLabel = "JOGADOR AFETADO",
            details = details
        })
    end
end

local function mageInventorySummary(inventory)
    local rows, totalStacks, totalItems = {}, 0, 0
    for _, entry in pairs(type(inventory) == "table" and inventory or {}) do
        if type(entry) == "table" and entry.item then
            totalStacks = totalStacks + 1
            totalItems = totalItems + parseInt(entry.amount)
            if #rows < 15 then
                rows[#rows + 1] = ("%s x%d"):format(tostring(entry.item), parseInt(entry.amount))
            end
        end
    end
    if totalStacks > #rows then rows[#rows + 1] = ("... e mais %d slot(s)"):format(totalStacks - #rows) end
    return totalStacks, totalItems, table.concat(rows, ", ")
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS PADROES
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.getAllItens()
	return Items
end

function vRP.getItemName(idname)
	return itemNameList(idname)
end

function vRP.getItemWeight(idname)
	if Items[idname] then
		return Items[idname].weight
	end
	return 0
end

function vRP.itemFood(args)
    local item = vRP.items[args]
    if item then
        return item.fome,item.sede
    end
end

function vRP.computeItemName(item,args)
	if type(item.name) == "string" then
		return item.name
	else
		return item.name(args)
	end
end

function vRP.computeItemWeight(item,args)
	if type(item.weight) == "number" then
		return item.weight
	else
		return item.weight(args)
	end
end

function vRP.getItemType(args)
	local item = vRP.items[args]
	if item then
		return item.tipo
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMBODYLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function itemBodyList(item)
	if Items[item] then 
		return Items[item]
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMINDEXLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function itemIndexList(item)
	if Items[item] then
		return Items[item].index
	end
end
exports("itemIndexList",itemIndexList)

-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMPNGLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function itemImageList(item)
	if Items[item] then
        if Items[item].png then
            return Items[item].png
        end
        return Items[item].index
    end
end
exports("itemImageList",itemImageList)

-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMNAMELIST
-----------------------------------------------------------------------------------------------------------------------------------------
function itemNameList(item)
	if Items[item] then
		return Items[item].name
	end
	return "Deleted"
end
exports("itemNameList",itemNameList)

-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMTYPELIST
-----------------------------------------------------------------------------------------------------------------------------------------
function itemTypeList(item)
	if Items[item] then
		return Items[item].type
	end
end
exports("itemTypeList",itemTypeList)

-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMAMMOLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function itemAmmoList(item)
	if Items[item] then
		return Items[item].ammo
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEMWEIGHTLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function itemWeightList(item)
	if Items[item] then
		return Items[item].weight
	end
	return 0
end
exports("itemWeightList",itemWeightList)


function vRP.computeChestWeight(items)
	local weight = 0
	for k,v in pairs(items) do
		if itemBodyList(k) then
			weight +=  itemWeightList(k) * tn(v.amount)
		end
	end
	return weight
end

function vRP.swapSlot(user_id,slot,target)
	local data = vRP.getInventory(user_id)
	if not data then return end
	local temp = data[ts(slot)]
	data[ts(slot)] = data[ts(target)]
	data[ts(target)] = temp 
end

function vRP.computeInvWeight(user_id)
	local weight = 0
	local inventory = vRP.getInventory(user_id)
	if inventory then
		for k in pairs(inventory) do
			if vRP.getItemWeight(inventory[k].item) then
				weight = weight + vRP.getItemWeight(inventory[k].item) * parseInt(inventory[k].amount)
			end
		end
		return weight
	end
	return 0
end 

function vRP.computeItemsWeight(items)
	local weight = 0
	if items then
		for k in pairs(items) do
			if vRP.items[items[k].item] then
				weight = weight + vRP.getItemWeight(items[k].item) * parseInt(items[k].amount)
			end
		end
		return weight
	end
	return 0
end 

function vRP.getInventoryItemAmount(user_id,idname)
	local data = vRP.getInventory(user_id)
	if data then
		for k in pairs(data) do
			if data[k].item == idname then
				-- vRP.checkInventoryWeightAndBan(user_id)
				return parseInt(data[k].amount)
			end
		end
	end
	return 0
end

function vRP.getItemInSlot(user_id, idname, target)
	local data = vRP.getInventory(user_id)
	if data then
		for k in pairs(data) do
			if data[k].item == idname then
				return k
			end
		end
	end
	return target
end

function vRP.getInventoryMaxWeight(user_id)
	local data = vRP.getUserDataTable(user_id)
	if data then
		local mochila = data.mochila
		local peso_base = 10 + 30 * tonumber(mochila.quantidade)
		local peso_adicional = 0
		
		if vRP.hasGroup(user_id,"TOP1") or vRP.hasGroup(user_id,"respstaffrealidade") or vRP.hasGroup(user_id,"resplogrealidade") or vRP.hasGroup(user_id,"respeventosrealidade") or vRP.hasGroup(user_id, "developerrealidade") or vRP.hasPermission(user_id, "diretor.permissao") or vRP.hasPermission(user_id, "perm.resplog") or vRP.hasGroup(user_id, "developeroffrealidade") or vRP.hasGroup(user_id, "respilegalrealidade") or vRP.hasGroup(user_id, "respilegaloffrealidade") or vRP.hasGroup(user_id, "resppoliciarealidade") then 
			-- vRP.checkInventoryWeightAndBan(user_id)
			return 100000000+30*tonumber(mochila.quantidade)
		end
		if vRP.hasGroup(user_id, "Pascoa") then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, "VipMaio") then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, "Ferias") then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, "VipIndependencia") then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, "VipMakakero") then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, 'VipHalloween') then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, 'VipDeluxe') then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, 'VipOutono') then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, 'VipBlackfriday') then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, 'VipNatal') then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, 'VipCarnaval') then
			peso_adicional = peso_adicional + 50
		end
		if vRP.hasGroup(user_id, 'mochila350') then
			peso_adicional = peso_adicional + 350
		end
		if vRP.hasGroup(user_id, 'm400') then
			peso_adicional = peso_adicional + 400
		end
		if vRP.hasPermission(user_id, 'perm.yakuza') then
			peso_adicional = peso_adicional + 100
		end
		if vRP.hasPermission(user_id, 'perm.dandara') then
			peso_adicional = peso_adicional + 400
		end
		
		-- vRP.checkInventoryWeightAndBan(user_id)
		return peso_base + peso_adicional
	end
end

function vRP.clearInventory(user_id)
    local data = vRP.getUserDataTable(user_id)
    if data then
        local stacks, totalItems, summary = mageInventorySummary(data.inventory)
        data.inventory = {}
        if stacks > 0 then
            mageInvLog("vrp_inventory_clear", user_id,
                ("**Resource:** %s\n**Função:** vRP.clearInventory\n**Slots removidos:** %d\n**Quantidade total removida:** %d\n**Conteúdo:** %s"):format(
                    mageInvOrigin(), stacks, totalItems, summary ~= "" and summary or "-"
                ))
        end
        return true
    end
    return false
end

function vRP.parseItem(idname)
	return splitString(idname,"|")
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES DO INVENTARIO
-----------------------------------------------------------------------------------------------------------------------------------------

function vRP.giveInventoryItem(user_id,idname,amount,notify,slot)
    local source = vRP.getUserSource(user_id)
    local data = vRP.getInventory(user_id)
    amount = parseInt(amount)

    if not itemBodyList(idname) then return false end
    if type(notify) == "string" then
        slot = notify
        notify = true
    end
    if not data then return false end
    if amount <= 0 then
        mageInvLog("vrp_security_invalid_inventory_amount", user_id,
            ("**Resource:** %s\n**Função:** vRP.giveInventoryItem\n**Item:** %s\n**Quantidade inválida:** %s"):format(
                mageInvOrigin(), tostring(idname), tostring(amount)
            ))
        return false
    end

    local finalSlot = slot
    if not finalSlot then
        local initial = 5
        repeat
            initial = initial + 1
        until data[ts(initial)] == nil or (data[ts(initial)] and data[ts(initial)].item == idname)
        initial = ts(initial)
        finalSlot = initial
        if data[initial] == nil then
            data[initial] = { item = idname, amount = amount }
        elseif data[initial] and data[initial].item == idname then
            data[initial].amount = tn(data[initial].amount) + amount
        end
    else
        finalSlot = ts(finalSlot)
        if data[finalSlot] then
            if data[finalSlot].item == idname then
                local oldAmount = tn(data[finalSlot].amount)
                data[finalSlot] = { item = idname, amount = tn(oldAmount) + amount }
            else
                data[finalSlot] = { item = idname, amount = amount }
            end
        else
            data[finalSlot] = { item = idname, amount = amount }
        end
    end

    if source and notify and itemBodyList(idname) then
        TriggerClientEvent("itensNotify",source,"sucesso", amount , vRP.getItemName(idname), idname, vRP.getItemWeight(idname)*amount)
    end

    if not mageInvSuppressed() then
        local key = idname == "money" and "vrp_wallet_inventory_credit" or "vrp_inventory_give_item"
        mageInvLog(key, user_id,
            ("**Resource:** %s\n**Função:** vRP.giveInventoryItem\n**Item:** %s (%s)\n**Quantidade:** %d\n**Slot:** %s"):format(
                mageInvOrigin(), tostring(vRP.getItemName(idname) or idname), tostring(idname), amount, tostring(finalSlot or "automático")
            ))
    end
    return true
end

function vRP.tryGetInventoryItem(user_id,idname,amount,notify,slot)
	if amount<0 then
		vRP.setBanned(user_id, 1, "tryGetInventoryItem")
		return false
	end
	local data = vRP.getInventory(user_id)
	if not data then return end
	if type(notify) == "string" then 
		slot = notify
		notify = true
	end
	local source = vRP.getUserSource(user_id)
	local amount = parseInt(amount)
	if not slot then
		for k,v in pairs(data) do
			if v.item == idname and parseInt(v.amount) >= amount then
				v.amount = v.amount - amount
				if v.amount <= 0 then
					data[k] = nil
				end
				if notify and itemBodyList(idname) then
					TriggerClientEvent("itensNotify",source,"negado", amount , vRP.getItemName(idname), idname, vRP.getItemWeight(idname)*amount)
				end
				return true
			end
		end
	else
		local slot  = ts(slot)
		if data[slot] and data[slot].item == idname and parseInt(data[slot].amount) >= amount then
			data[slot].amount = data[slot].amount - amount
			if data[slot].amount <= 0 then
				data[slot] = nil
			end
			if notify and itemBodyList(idname) then
				TriggerClientEvent("itensNotify",source,"negado", amount , vRP.getItemName(idname), idname, vRP.getItemWeight(idname)*amount)
			end
			return true
		end
	end  
end

function vRP.tryGetInventoryItem(user_id,idname,amount,notify,slot)
    local requestedAmount = tonumber(amount) or 0
    amount = parseInt(amount)
    if amount <= 0 then
        mageInvLog("vrp_security_invalid_inventory_amount", user_id,
            ("**Resource:** %s\n**Função:** vRP.tryGetInventoryItem\n**Item:** %s\n**Quantidade inválida:** %s"):format(
                mageInvOrigin(), tostring(idname), tostring(requestedAmount)
            ))
        return false
    end

    local source = vRP.getUserSource(user_id)
    local data = vRP.getInventory(user_id)
    if not user_id or not data then return false end

    local removedSlot = nil
    if not slot then
        for k,v in pairs(data) do
            if v.item == idname and parseInt(v.amount) >= amount then
                v.amount = parseInt(v.amount) - amount
                if parseInt(v.amount) <= 0 then data[k] = nil end
                removedSlot = k
                break
            end
        end
    else
        slot = tostring(slot)
        if data[slot] and data[slot].item == idname and parseInt(data[slot].amount) >= amount then
            data[slot].amount = parseInt(data[slot].amount) - amount
            if parseInt(data[slot].amount) <= 0 then data[slot] = nil end
            removedSlot = slot
        end
    end

    if not removedSlot then return false end

    if source and notify then
        TriggerClientEvent("itensNotify",source,"negado", amount , vRP.getItemName(idname), idname, vRP.getItemWeight(idname)*amount)
    end

    if not mageInvSuppressed() then
        local key = idname == "money" and "vrp_wallet_try_remove_money" or "vrp_inventory_try_remove_item"
        mageInvLog(key, user_id,
            ("**Resource:** %s\n**Função:** vRP.tryGetInventoryItem\n**Item:** %s (%s)\n**Quantidade removida:** %d\n**Slot:** %s"):format(
                mageInvOrigin(), tostring(vRP.getItemName(idname) or idname), tostring(idname), amount, tostring(removedSlot)
            ))
    end
    return true
end

function vRP.getSlotItem(user_id, slot)
	local inventory = vRP.getInventory(user_id)
	if not inventory then
		return
	end
	
	return  ((inventory[slot]) and inventory[slot]) or nil
end

function vRP.removeInventoryItem(user_id,idname,amount)
    local source = vRP.getUserSource(user_id)
    local data = vRP.getInventory(user_id)
    local requestedAmount = tonumber(amount) or 0
    amount = parseInt(amount)
    if amount <= 0 then
        mageInvLog("vrp_security_invalid_inventory_amount", user_id,
            ("**Resource:** %s\n**Função:** vRP.removeInventoryItem\n**Item:** %s\n**Quantidade inválida:** %s"):format(
                mageInvOrigin(), tostring(idname), tostring(requestedAmount)
            ))
        return false
    end
    if not user_id or not data then return false end

    local removedSlot = nil
    for k,v in pairs(data) do
        if v.item == idname and parseInt(v.amount) >= amount then
            v.amount = parseInt(v.amount) - amount
            if parseInt(v.amount) <= 0 then data[k] = nil end
            removedSlot = k
            break
        end
    end

    if not removedSlot then return false end
    if source then
        TriggerClientEvent("itensNotify",source,"negado", amount , vRP.getItemName(idname), idname, vRP.getItemWeight(idname)*amount)
    end

    if not mageInvSuppressed() then
        local key = idname == "money" and "vrp_wallet_remove_money" or "vrp_inventory_remove_item"
        mageInvLog(key, user_id,
            ("**Resource:** %s\n**Função:** vRP.removeInventoryItem\n**Item:** %s (%s)\n**Quantidade removida:** %d\n**Slot:** %s"):format(
                mageInvOrigin(), tostring(vRP.getItemName(idname) or idname), tostring(idname), amount, tostring(removedSlot)
            ))
    end
    return true
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CHECKAMOUNT BAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.checkInventoryWeightAndBan(user_id)
    local totalWeight = vRP.computeInvWeight(user_id)  
    local source = vRP.getUserSource(user_id)

    if totalWeight > 6600 and not vRP.hasPermission(user_id, "perm.mochilastaff") then
        mageInvLog("vrp_security_inventory_overweight", user_id,
            ("**Resource:** %s\n**Peso detectado:** %.2f KG\n**Limite de segurança:** 6600 KG\n**Ação:** jogador derrubado e banido"):format(
                mageInvOrigin(), tonumber(totalWeight) or 0
            ))
		vRP.sendLog("", "O ID "..user_id.." está com "..totalWeight.." KG no inventário!")
		DropPlayer(source, 'Você foi pego pelo makakero LGBT!')
		vRP.setBanned(user_id, 1, "Você foi pego pelo makakero LGBT!")
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE MOCHILA
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.addMochila(user_id)
    local data = vRP.getUserDataTable(user_id)
    if not data then return false end
    local mochila = data.mochila or { quantidade = 0, perder = 0 }
    mochila.quantidade = tonumber(mochila.quantidade) or 0
    mochila.perder = tonumber(mochila.perder) or 0
    local before = mochila.quantidade
    data.mochila = { quantidade = before + 1, perder = mochila.perder }
    mageInvLog("vrp_backpack_added", user_id,
        ("**Resource:** %s\n**Função:** vRP.addMochila\n**Mochilas antes:** %d\n**Mochilas depois:** %d"):format(mageInvOrigin(), before, before + 1))
    return true
end

function vRP.remMochila(user_id)
    local data = vRP.getUserDataTable(user_id)
    if data and data.mochila then
        local before = tonumber(data.mochila.quantidade) or 0
        local perder = tonumber(data.mochila.perder) or 0
        data.mochila = { quantidade = 0, perder = perder }
        if before ~= 0 then
            mageInvLog("vrp_backpack_removed", user_id,
                ("**Resource:** %s\n**Função:** vRP.remMochila\n**Mochilas antes:** %d\n**Mochilas depois:** 0"):format(mageInvOrigin(), before))
        end
        return true
    end
    return false
end

function vRP.getMochilaAmount(user_id)
	local data = vRP.getUserDataTable(user_id)
	if data then

		if data.mochila then
			-- vRP.checkInventoryWeightAndBan(user_id)
			return (data.mochila.quantidade or 0)
		end
	end

	return 0
end

function vRP.atualizarMochila(user_id, time)
    local data = vRP.getUserDataTable(user_id)
    if not data then return false end
    local mochila = data.mochila or { quantidade = 0, perder = 0 }
    local before = tonumber(mochila.perder) or 0
    local after = tonumber(time) or 0
    data.mochila = { quantidade = tonumber(mochila.quantidade) or 0, perder = after }
    if before ~= after then
        mageInvLog("vrp_backpack_expiration", user_id,
            ("**Resource:** %s\n**Função:** vRP.atualizarMochila\n**Expiração anterior:** %s\n**Nova expiração:** %s"):format(
                mageInvOrigin(), tostring(before), tostring(after)
            ))
    end
    return true
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENTOS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:playerJoin", function(user_id,source,name)
	local data = vRP.getUserDataTable(user_id)
	if not data then return end
	
	if not data.inventory then
		data.inventory = {}
	end

	if not data.mochila then
		data.mochila = { quantidade = 0, perder = 0 }
	end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- NATION GET INVENTARIO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function vRP.getVehicleName(name)
	return exports["fusion_garage"]:getVehicleName(name)
end

function vRP.getVehicleTrunk(name)
	return exports["fusion_garage"]:getVehicleTrunk(name)
end

