local I=ICAdmin
I.definitions.reconciliation_manage={key='reconciliation_manage',label='Conferir operações e entregas incertas'}
I.register('reconciliation.list',{permission='reconciliation_manage',handler=function(ctx,p)
    I.requireOwner(ctx)
    local page=I.int(p.page or 1,1,100000,'Página')
    local total=I.Store.query("SELECT COUNT(*) AS total FROM ic_admin_operations WHERE state='uncertain'")[1]
    local operations=I.Store.query([[SELECT SHA2(operation_key,256) AS id,actor_id,method,state,payload,created_at
        FROM ic_admin_operations WHERE state='uncertain' ORDER BY created_at DESC,operation_key LIMIT 50 OFFSET ?]],{(page-1)*50})
    for _,row in ipairs(operations) do
        local ok,data=pcall(json.decode,row.payload);row.payload=ok and I.Audit.clean(data) or '[inválido]'
    end
    local assignments,vipTotal=I.Records.list('vip_assignments',"state IN ('applying','uncertain') OR JSON_SEARCH(payload,'one','uncertain',NULL,'$.claims[*].state') IS NOT NULL",{},page,50)
    return {operations=operations,total=tonumber(total and total.total) or 0,assignments=assignments,totalAssignments=vipTotal,page=page,pageSize=50}
end})
I.register('reconciliation.resolve',{permission='reconciliation_manage',mutating=true,handler=function(ctx,p)
    I.requireOwner(ctx)
    local reason=I.text(p.reason,500,true,'Motivo')
    local evidence=I.text(p.evidence,1000,true,'Evidência da conferência')
    local id=I.text(p.id,96,true,'Registro')
    if p.confirmId~=id then I.fail('CONFIRMATION_REQUIRED','Digite o identificador do registro para confirmar.') end
    local review={actorId=ctx.userId,at=os.time(),reason=reason,evidence=evidence,outcome=p.outcome}
    if p.kind=='operation' then
        if not id:match('^[a-f0-9]+$') or #id~=64 or (p.outcome~='applied' and p.outcome~='failed') then I.fail('INVALID','Conferência inválida.') end
        local row=I.Store.query("SELECT operation_key,result,method FROM ic_admin_operations WHERE SHA2(operation_key,256)=? AND state='uncertain'",{id})[1]
        if not row then I.fail('CONFLICT','Operação já conferida ou não encontrada.') end
        local ok,previous=pcall(json.decode,row.result or '{}')
        local result={requestId=ok and previous.requestId or '',ok=p.outcome=='applied',data={reconciled=true,review=review},error=p.outcome=='failed' and {code='MANUALLY_RECONCILED',message='Conferida manualmente sem repetir efeitos.'} or nil}
        I.effect(ctx)
        if I.Store.update("UPDATE ic_admin_operations SET state=?,result=? WHERE operation_key=? AND state='uncertain'",{p.outcome,json.encode(result),row.operation_key})~=1 then I.fail('CONFLICT','Operação alterada durante a conferência.') end
    elseif p.kind=='vip' then
        return I.withLock('vip_assignments',function()
            local value,rev=I.Records.get('vip_assignments',id)
            if not value then I.fail('NOT_FOUND','Entrega não encontrada.') end
            value.reviews=value.reviews or {};if #value.reviews>=100 then I.fail('LIMIT','Limite de conferências desta entrega.') end
            if p.outcome=='archive' then
                if value.state~='uncertain' and value.state~='applying' then I.fail('CONFLICT','Entrega não está pendente.') end
                value.state='archived'
            elseif p.outcome=='items_applied' then
                if value.state~='uncertain' and value.state~='applying' then I.fail('CONFLICT','Entrega não está pendente.') end
                I.target(value.userId,true)
                if value.subjectKey~=I.subject(value.userId) or not I.vRP.hasGroup(value.userId,value.group) then I.fail('CONFLICT','Cargo VIP não confirmado para este jogador.') end
                local expires=tonumber(I.vRP.getUserGroupExpiration(value.userId,value.group)) or 0
                if expires<=os.time() then I.fail('EXPIRED','VIP sem validade ativa confirmada.') end
                value.expiresAt=expires;value.state='active';value.itemsState='applied'
            elseif p.outcome=='claim_applied' or p.outcome=='claim_not_applied' then
                local index=I.int(p.claimIndex,1,#(value.claims or {}),'Resgate')
                local claim=value.claims[index]
                if claim.state~='uncertain' and claim.state~='applying' then I.fail('CONFLICT','Resgate já conferido.') end
                claim.state=p.outcome=='claim_applied' and 'applied' or 'not_applied';claim.review=review
            else I.fail('INVALID','Resultado de conferência inválido.') end
            value.reviews[#value.reviews+1]=review
            I.effect(ctx);I.Records.save('vip_assignments',value,rev)
            I.audit('reconciliation.vip',ctx,value.userId,{assignmentId=id,review=review})
            return {reconciled=true,assignment=value}
        end)
    else I.fail('INVALID','Tipo de registro inválido.') end
    return {reconciled=true}
end})
