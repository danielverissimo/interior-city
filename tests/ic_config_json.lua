-- Small test-only JSON codec; production uses the FiveM JSON implementation.
local J={}
function J.encode(value)
    local kind=type(value)
    if kind=='nil' then return 'null' end
    if kind=='boolean' or kind=='number' then return tostring(value) end
    if kind=='string' then
        return '"'..value:gsub('[%z\1-\31\\"]',function(c)
            return ({['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'})[c] or ('\\u%04x'):format(c:byte())
        end)..'"'
    end
    assert(kind=='table')
    local array=#value>0
    if array then for key in pairs(value) do if type(key)~='number' or key<1 or key>#value or key%1~=0 then array=false;break end end end
    local out={}
    if array then for _,entry in ipairs(value) do out[#out+1]=J.encode(entry) end;return '['..table.concat(out,',')..']' end
    local keys={};for key in pairs(value) do keys[#keys+1]=key end;table.sort(keys,function(a,b)return tostring(a)<tostring(b) end)
    for _,key in ipairs(keys) do out[#out+1]=J.encode(tostring(key))..':'..J.encode(value[key]) end
    return '{'..table.concat(out,',')..'}'
end
function J.decode(text)
    local i=1
    local function ws()while text:sub(i,i):match('%s') do i=i+1 end end
    local parse
    local function stringValue()
        assert(text:sub(i,i)=='"');i=i+1;local out={}
        while i<=#text do
            local c=text:sub(i,i);i=i+1
            if c=='"' then return table.concat(out) end
            if c=='\\' then
                c=text:sub(i,i);i=i+1
                if c=='u' then out[#out+1]=utf8.char(assert(tonumber(text:sub(i,i+3),16)));i=i+4
                else out[#out+1]=assert(({['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'})[c]) end
            else out[#out+1]=c end
        end
        error('unterminated JSON string')
    end
    parse=function()
        ws();local c=text:sub(i,i)
        if c=='"' then return stringValue() end
        if c=='{' or c=='[' then
            local object=c=='{';local close=object and '}' or ']';i=i+1;ws();local out={}
            if text:sub(i,i)==close then i=i+1;return out end
            while true do
                local key
                if object then key=stringValue();ws();assert(text:sub(i,i)==':');i=i+1 else key=#out+1 end
                out[key]=parse();ws();local separator=text:sub(i,i);i=i+1
                if separator==close then return out end
                assert(separator==',');ws()
            end
        end
        for word,value in pairs({['true']=true,['false']=false}) do if text:sub(i,i+#word-1)==word then i=i+#word;return value end end
        if text:sub(i,i+3)=='null' then i=i+4;return nil end
        local number=text:sub(i):match('^%-?%d+%.?%d*[eE]?[+%-]?%d*')
        assert(number and tonumber(number),'invalid JSON');i=i+#number;return tonumber(number)
    end
    local value=parse();ws();assert(i>#text,'trailing JSON');return value
end
return J
