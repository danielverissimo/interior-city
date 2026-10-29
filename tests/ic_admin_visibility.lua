-- Emit the actual service predicate for execution by the disposable SQL suite.
local root,scenario=arg[1],arg[2]
local methods={}
ICAdmin={definitions={},Config={},Records={},Store={},vRP={}}
local I=ICAdmin
I.register=function(name,value)methods[name]=value.handler end
I.allowed=function(_,key)
    if scenario=='staff' or scenario=='history' then return key=='view_calls' or scenario=='history' and key=='calls_history' end
    return false
end
I.subject=function()return scenario=='reused' and 'new-person' or 'viewer'end
I.int=function(value)return tonumber(value)end
I.vRP.hasPermission=function(_,permission)return scenario=='police' and permission=='perm.policia'end
I.Records.list=function(_,where,params)
    print(where);for _,value in ipairs(params)do print(value)end;return {},0
end
I.Records.byIds=function()return {}end
I.Store.query=function()return {}end
exports=function()end
dofile(root..'/resources/[scriptcore]/ic_admin/server/calls.lua')
methods['calls.list']({userId=10},{page=1})
