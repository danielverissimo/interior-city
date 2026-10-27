-- local PROPMANAGER_WEBHOOK = ""

-- AddEventHandler("likizao:PropManager:DeleteEntitys", function(user_id, entityArr, isAllEntities)
--     PerformHttpRequest(PROPMANAGER_WEBHOOK, function(err, text, headers)
--     end, 'POST', json.encode({
--         content = "```ini\n[PropManager]\n[USER_ID]: "..user_id.."\n[QTD_ENTIDADES]: "..#entityArr.."\n[DELETOU EM MASSA]: "..(isAllEntities and "SIM" or "NAO").."\n```"
--     }), {
--         ['Content-Type'] = 'application/json'
--     })
-- end)