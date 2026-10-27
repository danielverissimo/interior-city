local scale = 1.5
local screenWidth = math.floor(1920 / scale)
local screenHeight = math.floor(1080 / scale)
local shouldDraw = false
local mouseX = screenWidth * 0.5
local mouseY = screenHeight * 0.5

function IsTelevisionScreenInteractionActive()
    return shouldDraw
end

function SetInteractScreen(enabled)
    enabled = enabled == true

    if enabled and (not duiObj or not CURRENT_SCREEN) then
        MTelevisionNotify("Nenhuma tela ativa para interagir.", "error")
        return
    end

    if not enabled then
        shouldDraw = false
        return
    end

    if shouldDraw then return end
    shouldDraw = true

    CreateThread(function()
        MTelevisionRequestTextureDictionary("fib_pc")

        local w, h = screenWidth, screenHeight
        local minX, maxX = ((w - (w / 2)) / 2), (w - (w / 4))
        local totalX = minX - maxX
        local minY, maxY = ((h - (h / 2)) / 2), (h - (h / 4))
        local totalY = minY - maxY

        while shouldDraw do
            if not duiObj or not CURRENT_SCREEN then
                shouldDraw = false
                break
            end

            local nX = GetControlNormal(0, 239) * screenWidth
            local nY = GetControlNormal(0, 240) * screenHeight

            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisablePlayerFiring(PlayerPedId(), true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 106, true)
            BlockWeaponWheelThisFrame()

            if MTelevisionTxdName and MTelevisionTxnName then
                DrawSprite(MTelevisionTxdName, MTelevisionTxnName, 0.5, 0.5, 0.5, 0.5, 0.0, 255, 255, 255, 255)
            end

            if nX ~= mouseX or nY ~= mouseY then
                mouseX = math.max(325, math.min(965, nX))
                mouseY = math.max(185, math.min(545, nY))

                local duiX = -screenWidth * ((mouseX - minX) / totalX)
                local duiY = -screenHeight * ((mouseY - minY) / totalY)
                SendDuiMouseMove(duiObj, math.floor(duiX), math.floor(duiY))
            end

            DrawSprite("fib_pc", "arrow", mouseX / screenWidth, mouseY / screenHeight, 0.005, 0.01, 0.0, 255, 255, 255, 255)

            if IsControlJustPressed(0, 177) then
                SetInteractScreen(false)
                OpenTVMenu()
            end

            if IsControlPressed(0, 172) then SendDuiMouseWheel(duiObj, 10, 0) end
            if IsControlPressed(0, 173) then SendDuiMouseWheel(duiObj, -10, 0) end

            if IsDisabledControlJustPressed(0, 24) then
                SendDuiMouseDown(duiObj, "left")
            elseif IsDisabledControlJustReleased(0, 24) then
                SendDuiMouseUp(duiObj, "left")
            end

            if IsDisabledControlJustPressed(0, 25) then
                SendDuiMouseDown(duiObj, "right")
            elseif IsDisabledControlJustReleased(0, 25) then
                SendDuiMouseUp(duiObj, "right")
            end

            Wait(0)
        end
    end)
end
