local FILE="jobs.json"
local JobData={central={},npc={},jobs={},extras={}}

local function trim(v) return tostring(v or ""):gsub("^%s+",""):gsub("%s+$","") end
local function clone(v)
    if type(v)~="table" then return v end
    local o={} for k,x in pairs(v) do o[k]=clone(x) end return o
end

local function restoreKeys(v)
    if type(v)~="table" then return v end
    local o={}
    for k,x in pairs(v) do
        local nk=k
        if type(k)=="string" and k:match("^%-?%d+$") then
            nk=tonumber(k)
        end
        o[nk]=restoreKeys(x)
    end
    return o
end

local function normalizeVec(v,count)
    if type(v)~="table" then return nil end
    local o={}
    for i=1,count do
        local n=tonumber(v[i] or v[tostring(i)])
        if not n then return nil end
        o[i]=n
    end
    return o
end

local function applyRuntime()
    cfg.central=clone(JobData.central or {})
    cfg.npcloc=clone(JobData.npc or {})
    cfg.list=restoreKeys(JobData.jobs or {})
    cfg.extra=clone(JobData.extras or {})
end

local function loadData()
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if not ok or type(data)~="table" then
        print("^1[m_empregos]^7 jobs.json inválido.")
        data={}
    end
    JobData.central=data.central or {}
    JobData.npc=data.npc or {}
    JobData.jobs=data.jobs or {}
    JobData.extras=data.extras or {}
    applyRuntime()
end

local function saveData()
    local ok=SaveResourceFile(GetCurrentResourceName(),FILE,json.encode(JobData),-1)
    if not ok then return false,"Não foi possível salvar jobs.json." end
    applyRuntime()
    TriggerClientEvent("m_empregos:syncConfig",-1,JobData)
    TriggerEvent("m_empregos:serverConfigUpdated",JobData)
    return true
end

local function normalizeUniform(t)
    if type(t)~="table" then return {} end
    return clone(t)
end

local function normalizeJob(name,p)
    if type(p)~="table" then return nil,"Dados do emprego inválidos." end
    name=trim(name)
    if name=="" then return nil,"Emprego inválido." end
    local start=normalizeVec(p.inicio,3)
    if not start then return nil,"Local inicial inválido." end
    local levels=tonumber(p.total_nivel)
    if not levels or levels<1 then return nil,"Quantidade de níveis inválida." end

    return {
        index=trim(p.index~="" and p.index or name),
        inicio=start,
        total_nivel=math.floor(levels),
        xp_for_level=clone(p.xp_for_level or {}),
        payment_for_level=clone(p.payment_for_level or {}),
        uniforme=normalizeUniform(p.uniforme)
    }
end

loadData()

CreateThread(function()
    Wait(0)
    TriggerEvent("m_empregos:serverConfigUpdated",JobData)
end)

RegisterNetEvent("m_empregos:requestConfig",function()
    TriggerClientEvent("m_empregos:syncConfig",source,JobData)
end)

exports("getJobsConfig",function()
    return clone(JobData)
end)

exports("updateJob",function(name,payload,extra)
    name=trim(name)
    if not JobData.jobs[name] then return false,"Emprego não encontrado." end
    local job,err=normalizeJob(name,payload)
    if not job then return false,err end

    local old=clone(JobData.jobs[name])
    local oldExtra=clone(JobData.extras[name])
    JobData.jobs[name]=job
    JobData.extras[name]=type(extra)=="table" and clone(extra) or JobData.extras[name] or {}

    local ok,msg=saveData()
    if not ok then
        JobData.jobs[name]=old
        JobData.extras[name]=oldExtra
        applyRuntime()
        return false,msg
    end

    MageEmpregosLog("jobs_config_job_changed", {
        actorLabel = "SISTEMA / RESOURCE",
        details = ("Emprego alterado: %s\nResource solicitante: %s\nNíveis configurados: %s"):format(
            name, tostring(GetInvokingResource() or "m_empregos"), tostring(job.total_nivel or "-")
        )
    })
    return true,"Emprego atualizado em tempo real."
end)

exports("updateJobsGlobal",function(payload)
    payload=type(payload)=="table" and payload or {}
    local central=normalizeVec(payload.central,3)
    local npc=normalizeVec(payload.npc,4)
    if not central then return false,"Posição da Central de Empregos inválida." end
    if not npc then return false,"Posição do NPC inválida." end

    JobData.central=central
    JobData.npc=npc
    local ok,msg=saveData()
    if not ok then return false,msg end
    MageEmpregosLog("jobs_config_global_changed", {
        actorLabel = "SISTEMA / RESOURCE",
        details = ("Resource solicitante: %s\nCentral: %.2f, %.2f, %.2f\nNPC: %.2f, %.2f, %.2f, %.2f"):format(
            tostring(GetInvokingResource() or "m_empregos"),
            central[1], central[2], central[3], npc[1], npc[2], npc[3], npc[4]
        )
    })
    return true,"Configurações globais atualizadas."
end)

exports("captureJobUniform",function(playerSource,jobName)
    playerSource=tonumber(playerSource)
    jobName=trim(jobName)
    if not playerSource or not JobData.jobs[jobName] then
        return false,"Emprego ou jogador inválido."
    end

    local custom=vRPclient.getCustomization(playerSource)
    if type(custom)~="table" then return false,"Não foi possível capturar a roupa atual." end

    local ped=GetPlayerPed(playerSource)
    local model=ped and GetEntityModel(ped) or 0
    local sex=nil
    if model==1885233650 then sex="masculino"
    elseif model==-1667301416 then sex="feminino" end
    if not sex then return false,"Modelo do personagem não reconhecido." end

    JobData.jobs[jobName].uniforme=JobData.jobs[jobName].uniforme or {}
    JobData.jobs[jobName].uniforme[sex]=clone(custom)

    local ok,msg=saveData()
    if not ok then return false,msg end
    local userId = vRP.getUserId(playerSource)
    MageEmpregosLog("jobs_config_uniform_captured", {
        actorId = userId,
        details = ("Emprego: %s\nSexo do uniforme: %s\nResource solicitante: %s"):format(
            jobName, sex, tostring(GetInvokingResource() or "m_empregos")
        )
    })
    return true,("Uniforme %s de %s capturado."):format(sex,jobName),clone(JobData.jobs[jobName].uniforme)
end)
