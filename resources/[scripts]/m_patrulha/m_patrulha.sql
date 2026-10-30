with parametros as (
        select
  #1,Processadora,NI# as id_processadora, 
  #2,Instituição, SQL(select id_instituicao, desc_instituicao from suporte.hierarquia_instituicao where id_processadora =~1,Processadora,NI~ order by 2) # as id_instituicao, 
  date(#3,Data Transação início, D(dd/MM/yyyy)#),NI# as dt_ini,
  date(#4,Data Transação fim, D(dd/MM/yyyy)#) as dt_fim),
transacoes as materialized (
  select
      tl.id   , tl.ss       , tl.mcc    , tl.voidcount
    , tl.date , tl.ca_name    , tl.ca_city  , tl.amount
    , tl.rrn  , tl.functioncode , tl.irc    , tl.tid    , tl.account
    , tl.mid  , tl.responsecode , tl.token_interno      , tl.feefunctioncode
    , tl.issuerfee , tl.reversalcount , tl.displaymessage , tl.acquirer, tl.gltransaction 
  from
    jcard.log_transacoes tl, parametros p
  where
    tl."date" >= (p.dt_ini)
    and tl."date" < (p.dt_fim + 1)
    and tl.deleted = 'N' )
select distinct on (t.id)
    t.id as         "Id Transação"
  , c.nome_impresso as  "Nome embossado"
  , concat(c.bin_6,'XXXXXXXX',lpad(cast (c.ultimos_4_dig as varchar),4,'0')) as "Cartão"
  , ts.desc_status as   "Status cartão"
  , t.ss as         "Bandeira"
  , t.mcc as        "MCC"
  , pe.nome_completo    "Nome do portador"
  , pe.documento          "Cpf"
  , to_CHAR(t.date, 'dd/MM/yyyy hh24:mi:ss') as "Data transação"
  , t.ca_name as      "Estabelecimento"
  , t.ca_city as      "Cidade"
    , replace(to_char(t.amount, 'FM999999990.00'),'.',',')  as "Valor"
    , t.rrn         "Código RRN"
    , upper(case ct.sinal_transacao when 1 then 'Crédito'
                  when -1 then 'Débito'
                  else 'Administrativa' end) "Sinal"
    , t.functioncode    "Código da transação"
  , coalesce(pt.desc_reduzida, ct.desc_transacao_reduzida)    "Transação"
  , upper(ct.desc_transacao_estendida) as "Descrição estendida"
  , replace(to_char(coalesce(t.issuerfee, 0), 'FM999999990.00'),'.',',')  "valor tarifa"
  , upper(ctfee.desc_transacao_estendida) as "Descrição tarifa"
  , (case when(t.irc =  '0000' and t.reversalcount = 0 and t.voidcount = 0 and gltransaction is not null ) then 'Aprovada'
      when(t.irc =  '0000' and (t.reversalcount > 0 or t.voidcount > 0)) then 'Aprovada (Desfeita)'
      when(t.irc <> '0000' and (t.reversalcount > 0 or t.voidcount > 0)) then 'Negada (Desfeita)'
      else 'Negada' end) as "Resultado"
  , (case when(t.irc != '0000') then t.displaymessage
        else '' end) as   "Mensagem"
  , t.responsecode as     "Código resposta"
  , cp.id_conta as      "Id Conta"
  , prod.desc_prod_instituicao as "Produto"
    , pp.desc_prod_plat as    "Produto Plataforma"
  , hpr.desc_ponto_de_relacionamento "Ponto de Relacionamento"
  , hpr.documento as    "CNPJ"
  , t.tid as        "ID terminal"
  , t.mcc as        "MCC"
  , t.mid as        "ID estabelecimento"
  , t."date" as     "Data referencia transação" 
  , ltc.dt_apresentacao as "Data apresentação"
  , ltc.dt_processamento as "Data processamento"
  , t.acquirer      "ID adquirente"
  , hi.desc_instituicao as  "Parceiro"
from transacoes t
inner join cadastral.credencial c on c.token_interno = t.token_interno
inner join cadastral.credencial_conta cc on cc.id_credencial = c.id_credencial 
inner join cadastral.conta_pagamento cp on cp.id_conta = cc.id_conta
inner join parametros p on  cp.id_processadora = (p.id_processadora)
      and cp.id_instituicao = (p.id_instituicao)
inner join suporte.hierarquia_ponto_de_relacionamento hpr on hpr.id_processadora = cp.id_processadora
      and hpr.id_instituicao = cp.id_instituicao
      and hpr.id_regional = cp.id_regional
      and hpr.id_filial = cp.id_filial
      and hpr.id_ponto_de_relacionamento = cp.id_ponto_de_relacionamento
inner join cadastral.produto_instituicao prod on prod.id_prod_instituicao = cp.id_prod_instituicao
inner join cadastral.produto_instituicao_configuracao pic on pic.id_instituicao = cp.id_instituicao 
      and pic.id_prod_instituicao = cp.id_prod_instituicao 
inner join cadastral.produto_plataforma pp on pp.id_prod_plat = pic.id_prod_plat 
inner join cadastral.pessoa pe on pe.id_pessoa = c.id_pessoa
inner join transacional.codigo_transacao ct on ct.cod_transacao = cast(t.functioncode as integer)
left join cadastral.produto_transacao pt on ct.cod_transacao = pt.cod_transacao
  and pt.id_prod_instituicao = cp.id_prod_instituicao
inner join jcard.log_transacoes_controle ltc on ltc.id_transacao = t.id
inner join transacional.redes ss on ss.ss = coalesce(t.ss, 'PPP')
inner join suporte.tipo_status ts on id_status = c.status 
inner join suporte.hierarquia_instituicao hi on hi.id_instituicao = cp.id_instituicao 
left join transacional.codigo_transacao ctfee on ctfee.cod_transacao = cast(t.feefunctioncode as integer)
where true
   and ct.sinal_transacao <> 0
     and not (cp.id_instituicao = 2001 
            and (t.tid is not null 
             and t.acquirer is null 
             and t.responsecode is null 
             and t.mcc is not null))
order by t.id, t.account = cp.id_acct desc nulls last --não mude essa ordem, o 'distinct on' depende dela
