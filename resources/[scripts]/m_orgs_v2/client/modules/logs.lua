--- @return table
RegisterNUICallback('GetLogsData', function(data, cb)
    local logsData = vTunnel.getLogsData()
    cb(logsData or {
        totalPages = 1,
        currentPage = 1,
        filters = {}
    })
end)

--- @param data table
--- @return table
RegisterNUICallback('GetLogs', function(data, cb)
    if not data or type(data) ~= 'table' then
        print('[Logs Module] Erro: Dados inválidos recebidos')
        cb({})
        return
    end

    local currentPage = tonumber(data.currentPage) or 1
    if currentPage < 1 then
        currentPage = 1
    end

    local selectedFilter = nil
    if data.selectedFilter and type(data.selectedFilter) == 'string' and data.selectedFilter ~= '' then
        if data.selectedFilter == 'chest' or data.selectedFilter == 'hired' or data.selectedFilter == 'fired' or data.selectedFilter == 'craft' then
            selectedFilter = data.selectedFilter
        end
    end

    local logs = vTunnel.getLogs({
        currentPage = currentPage,
        selectedFilter = selectedFilter
    })

    cb(logs or {})
end)