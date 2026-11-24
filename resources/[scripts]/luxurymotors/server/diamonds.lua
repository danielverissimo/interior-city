-- Carteira premium independente do item de inventario "diamante".
LuxuryDiamonds = {ready=false}
local maximum = 1000000000
local function integer(value)
    value=tonumber(value)
    return value and value == value and value > 0 and value <= maximum and value % 1 == 0 and value or nil
end
local function query(sql, params) return exports.oxmysql:query_async(sql, params or {}) end
local function transaction(queries) return exports.oxmysql:transaction_async(queries) == true end

CreateThread(function()
    while not LuxuryDiamonds.ready do
    local ok, err = pcall(function()
        query([[CREATE TABLE IF NOT EXISTS luxury_diamond_wallets (
            user_id INT NOT NULL PRIMARY KEY, balance BIGINT UNSIGNED NOT NULL DEFAULT 0
        ) ENGINE=InnoDB]])
        query([[CREATE TABLE IF NOT EXISTS luxury_diamond_ledger (
            reference VARCHAR(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL PRIMARY KEY,
            user_id INT NOT NULL, amount BIGINT NOT NULL, kind VARCHAR(16) NOT NULL,
            applied TINYINT NOT NULL DEFAULT 0, actor VARCHAR(100), vehicle VARCHAR(80),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX(user_id)
        ) ENGINE=InnoDB]])
        LuxuryDiamonds.ready=true
    end)
    if not ok then
        print('[luxurymotors] Carteira de diamantes indisponivel; nova tentativa em 5s: '..tostring(err))
        Wait(5000)
    end
    end
end)

function LuxuryDiamonds.balance(user)
    if not LuxuryDiamonds.ready then return nil end
    local rows=query('SELECT balance FROM luxury_diamond_wallets WHERE user_id=?', {user})
    return rows and rows[1] and tonumber(rows[1].balance) or 0
end

exports('getDiamondBalanceForUser',function(user)
    local ok,balance=pcall(LuxuryDiamonds.balance,tonumber(user))
    return ok and balance or nil
end)

function LuxuryDiamonds.publish(user, spent, item)
    local player=vRP.getUserSource(user)
    if not player then return end
    if spent and spent>0 then
        TriggerClientEvent('Notify',player,'sucesso',('Você gastou %s diamantes na compra de %s. O veículo foi enviado para sua garagem.'):format(spent,tostring(item or 'um veículo')),8)
    end
    local ok,balance=pcall(LuxuryDiamonds.balance,user)
    TriggerClientEvent('luxurymotors:diamondWallet',player,{ok=ok and balance~=nil,balance=ok and balance or nil})
end

local requests={}
RegisterNetEvent('luxurymotors:requestDiamondWallet',function()
    local player=source
    local now=GetGameTimer()
    if requests[player] and now-requests[player]<2000 then return end
    requests[player]=now
    local user=vRP.getUserId(player)
    if user then LuxuryDiamonds.publish(user) end
end)
AddEventHandler('playerDropped',function() requests[source]=nil end)
AddEventHandler('vRP:playerSpawn',function(user) LuxuryDiamonds.publish(user) end)

function Server.getDiamondBalance()
    local user=vRP.getUserId(source)
    if not user then return {ok=false} end
    local ok, balance=pcall(LuxuryDiamonds.balance,user)
    return {ok=ok and balance ~= nil, balance=ok and balance or nil}
end

-- Apenas servidor/console. Nunca registrar um evento de rede para conceder saldo.
local function credit(user, amount, order, actor)
    user,amount=integer(user),integer(amount)
    if not LuxuryDiamonds.ready then return false,'Carteira indisponivel.' end
    if not user or not amount or type(order) ~= 'string' or #order < 3 or #order > 100 or not order:match('^[%w_%-%.:]+$') then
        return false,'Informe ID, quantidade inteira e numero unico do pedido (3 a 100 caracteres).'
    end
    local reference='credit:'..order
    local ok, result=pcall(function()
        local users=query('SELECT id FROM vrp_users WHERE id=? LIMIT 1',{user})
        if not users or not users[1] then return false end
        return transaction({
            {query='INSERT IGNORE INTO luxury_diamond_wallets (user_id,balance) VALUES (?,0)',values={user}},
            {query="INSERT IGNORE INTO luxury_diamond_ledger (reference,user_id,amount,kind,actor) VALUES (?,?,?,'credit',?)",values={reference,user,amount,tostring(actor):sub(1,100)}},
            {query=[[UPDATE luxury_diamond_wallets w JOIN luxury_diamond_ledger l ON l.user_id=w.user_id
                SET w.balance=w.balance+l.amount WHERE l.reference=? AND l.applied=0]],values={reference}},
            {query='UPDATE luxury_diamond_ledger SET applied=1 WHERE reference=?',values={reference}}
        })
    end)
    if not ok or not result then return false,'Credito nao confirmado. Consulte o pedido antes de repetir com outro numero.' end
    local verified,rows=pcall(query,'SELECT user_id,amount FROM luxury_diamond_ledger WHERE reference=? AND applied=1',{reference})
    if not verified then return false,'Confirmacao indisponivel. Confira este mesmo pedido antes de tentar outro numero.' end
    local entry=rows and rows[1]
    if not entry or tonumber(entry.user_id) ~= user or tonumber(entry.amount) ~= amount then
        return false,'Numero de pedido ja utilizado com outro jogador ou valor.'
    end
    print(('[luxurymotors] Diamantes: pedido %s | ID %s | quantidade %s | operador %s (pedido unico, sem duplicacao)'):format(order,user,amount,tostring(actor)))
    LuxuryDiamonds.publish(user)
    return true,'Pedido confirmado. Se ja havia sido creditado, o saldo nao foi duplicado.'
end

exports('creditDiamonds', function(user, amount, order)
    -- Permitir somente integracoes aprovadas explicitamente no server.cfg.
    local resource=GetInvokingResource()
    if not resource or not IsPrincipalAceAllowed('resource.'..resource,'luxurymotors.creditDiamonds') then
        return false,'Resource sem ACE luxurymotors.creditDiamonds.'
    end
    return credit(user,amount,order,'resource:'..resource)
end)

local adminCreditSequence=0
exports('adminCreditDiamonds',function(actorSource,target,amount)
    -- Somente os dois adaptadores de administracao, apos suas permissoes
    -- existentes. Nenhum evento de rede concede saldo por esta funcao.
    local resource=GetInvokingResource()
    if resource~='m_paineladm_v2' and resource~='vrp_admin' then return false,'Origem nao autorizada.' end
    local actor=vRP.getUserId(tonumber(actorSource))
    if not actor then return false,'Administrador invalido.' end
    target,amount=integer(target),integer(amount)
    if not target or not amount then return false,'Informe ID e quantidade inteiros e positivos.' end
    -- A aba Itens do painel so entrega ao proprio administrador.
    if resource=='m_paineladm_v2' and target~=actor then return false,'Esta aba entrega somente ao proprio administrador.' end
    adminCreditSequence=adminCreditSequence+1
    local order=('admin:%s:%s:%s:%s:%s'):format(resource,actor,os.time(),adminCreditSequence,math.random(1,2147483646))
    local ok,message=credit(target,amount,order,resource..':ID '..actor)
    if not ok then return false,message end
    local targetSource=vRP.getUserSource(target)
    if targetSource then TriggerClientEvent('Notify',targetSource,'sucesso',('Você recebeu %s diamantes.'):format(amount),6) end
    return true,('%s diamantes adicionados ao ID %s.'):format(amount,target)
end)
RegisterCommand('luxurydiamantes',function(player,args)
    local user=player > 0 and vRP.getUserId(player) or nil
    if player > 0 and (not user or not vRP.hasGroup(user,'dono')) then return end
    local ok,message=credit(args[1],args[2],args[3],player == 0 and 'console' or 'dono:'..user)
    if player > 0 then TriggerClientEvent('Notify',player,ok and 'sucesso' or 'negado',message,8) else print('[luxurymotors] '..message) end
end,false)

-- Debito, historico e entrega na mesma transacao: sem cobrar sem entregar.
function LuxuryDiamonds.purchase(user, vehicle, price, ipva, tuning)
    if not LuxuryDiamonds.ready or not integer(price) then return {ok=false,message='Carteira ou preco em diamantes indisponivel.'} end
    local reference=('purchase:%s:%s:%s:%s'):format(user,os.time(),GetGameTimer(),math.random(1,2147483646))
    local ok, committed=pcall(transaction,{
        {query='UPDATE luxury_diamond_wallets SET balance=balance WHERE user_id=?',values={user}},
        {query=[[INSERT INTO luxury_diamond_ledger (reference,user_id,amount,kind,vehicle,applied)
            SELECT ?,w.user_id,?,'purchase',?,1 FROM luxury_diamond_wallets w
            WHERE w.user_id=? AND w.balance>=? AND NOT EXISTS
            (SELECT 1 FROM vrp_user_veiculos WHERE user_id=? AND veiculo=?)]],
            values={reference,-price,vehicle,user,price,user,vehicle}},
        {query=[[INSERT INTO vrp_user_veiculos (user_id,veiculo,ipva,tunagem)
            SELECT user_id,vehicle,?,? FROM luxury_diamond_ledger WHERE reference=?]],values={ipva,tuning,reference}},
        {query=[[UPDATE luxury_diamond_wallets w JOIN luxury_diamond_ledger l ON w.user_id=l.user_id
            SET w.balance=w.balance+l.amount WHERE l.reference=?]],values={reference}}
    })
    if not ok then
        print('[luxurymotors] Conferir transacao de diamantes '..reference..': '..tostring(committed))
    end
    -- A resposta pode se perder apos COMMIT. Conferir o recibo antes de repetir.
    local verified, rows=pcall(query,'SELECT reference FROM luxury_diamond_ledger WHERE reference=?',{reference})
    if not verified then return {ok=false,pendingVerification=true,message='Confirmacao indisponivel. Contate o suporte antes de repetir.',reference=reference} end
    if rows and rows[1] then return {ok=true,price=price,currency='diamonds',paymentMethod='diamonds',reference=reference} end
    return {ok=false,message=ok and committed and 'Diamantes insuficientes ou veiculo ja adquirido.' or 'Nao foi possivel concluir a compra em diamantes.'}
end

local accessDuration = 30 * 24 * 60 * 60
local latestPayment = [[SELECT reference, -amount AS price, kind,
    UNIX_TIMESTAMP(created_at) AS paid_at
    FROM luxury_diamond_ledger
    WHERE user_id=? AND vehicle=? AND applied=1 AND kind IN ('purchase','renewal')
    ORDER BY created_at DESC, reference DESC LIMIT 1]]

local function vehicleAccess(user, vehicle)
    if not LuxuryDiamonds.ready then return nil end
    local rows = query(latestPayment, {user, vehicle})
    if not rows then return nil end
    local payment = rows[1]
    if not payment then return {premium=false} end
    return {
        premium=true,
        price=tonumber(payment.price),
        expiresAt=tonumber(payment.paid_at) + accessDuration,
        reference=payment.reference
    }
end

exports('getVehicleAccess', vehicleAccess)

exports('getPremiumVehicles', function(user)
    if not LuxuryDiamonds.ready then return nil end
    local rows = query([[SELECT DISTINCT vehicle FROM luxury_diamond_ledger
        WHERE user_id=? AND applied=1 AND kind='purchase' AND vehicle IS NOT NULL]], {user})
    if not rows then return nil end
    local vehicles = {}
    for _, row in ipairs(rows) do vehicles[row.vehicle:lower()] = true end
    return vehicles
end)

exports('renewVehicleAccess', function(user, vehicle, expectedReference)
    if GetInvokingResource() ~= 'm_garage' then return false end
    local access = vehicleAccess(user, vehicle)
    if not access or not access.premium or access.reference ~= expectedReference or access.expiresAt > os.time() then
        return false, 'A situação do veículo mudou. Tente retirar novamente.'
    end

    local reference = ('renewal:%s:%s:%s:%s'):format(user, os.time(), GetGameTimer(), math.random(1,2147483646))
    local ok, committed = pcall(transaction, {
        {query='UPDATE luxury_diamond_wallets SET balance=balance WHERE user_id=?',values={user}},
        {query=[[INSERT INTO luxury_diamond_ledger (reference,user_id,amount,kind,vehicle,applied)
            SELECT ?,w.user_id,-payment.price,'renewal',?,1
            FROM luxury_diamond_wallets w
            JOIN (]] .. latestPayment .. [[) payment ON payment.reference=?
            JOIN vrp_user_veiculos v ON v.user_id=w.user_id AND v.veiculo=?
            WHERE w.user_id=? AND w.balance>=payment.price AND payment.paid_at+?<=UNIX_TIMESTAMP()]],
            values={reference,vehicle,user,vehicle,expectedReference,vehicle,user,accessDuration}},
        {query=[[UPDATE luxury_diamond_wallets w JOIN luxury_diamond_ledger l ON l.user_id=w.user_id
            SET w.balance=w.balance+l.amount WHERE l.reference=?]],values={reference}}
    })
    local verified, rows = pcall(query, 'SELECT reference FROM luxury_diamond_ledger WHERE reference=?', {reference})
    if not verified then
        return false, 'Confirmação indisponível. Consulte o suporte com o recibo '..reference..'.'
    end
    if rows and rows[1] then
        LuxuryDiamonds.publish(user)
        return true, 'Veículo renovado por 30 dias. Você já pode retirá-lo da garagem.'
    end
    if ok and committed then
        return false, 'Diamantes insuficientes ou a situação do veículo mudou.'
    end
    return false, 'Não foi possível renovar o veículo. Tente novamente.'
end)
