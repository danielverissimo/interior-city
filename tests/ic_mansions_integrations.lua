local root=assert(arg[1])
local provider,state,answer,throws='m_mansions','started',true,false
local calls=0
local logged={}
GlobalState={ic_mansions_permissions={['perm.mansion']=true}}
function GetConvar(_,fallback)return provider or fallback end
function GetResourceState()return state end
function print(message)logged[#logged+1]=message end
exports=setmetatable({},{__index=function(_,name)
    assert(name==provider)
    return {checkAccessByPermission=function(_,source,permission)
        assert(source==7 and type(permission)=='string');calls=calls+1
        if throws then error('PRIVATE_CONNECTION_VALUE')end
        return answer
    end}
end})
for _,path in ipairs({'resources/[scriptcore]/inventory/server/modules/chest.lua','resources/[scriptcore]/m_garage/server-side/functions.lua'})do
    local stream=assert(io.open(root..'/'..path));local raw=stream:read('*a');stream:close()
    local first=assert(raw:find('local function mansionIptuAccess',1,true))
    local last=assert(raw:find('\nend',first,true))+3
    local access=assert(load(raw:sub(first,last)..'\nreturn mansionIptuAccess',path))()
    provider='m_mansions';state='missing';throws=false;answer=true
    assert(access(7,'perm.ordinary')==true)
    provider='ic_mansions'
    assert(access(7,'perm.mansion')==false,'known mansion must stay closed while selected provider is down')
    assert(access(7,'perm.ordinary')==true,'unrelated resources remain available with known permission registry')
    state='started';answer=false
    local before=calls
    assert(access(7,'perm.new_pending')==false and calls==before+1,'running provider must decide newly journaled permissions')
    answer=nil;assert(access(7,'perm.mansion')==false,'missing own response must not grant access')
    throws=true;assert(access(7,'perm.mansion')==false)
    assert(not logged[#logged]:find('PRIVATE_CONNECTION_VALUE',1,true))
    throws=false;answer=true;assert(access(7,'perm.mansion')==true)
end
io.write('mansion dependency selection and outage guards passed\n')
