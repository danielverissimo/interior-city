-----------------------------------------------------------------------------------------------------------------------------------------
-- TABLE PREPARE SEND NUI
-----------------------------------------------------------------------------------------------------------------------------------------

local clothingCategorys = { ["arms"] = { type = "variation", id = 3 }, ["tshirt"] = { type = "variation", id = 8 }, ["torso"] = { type = "variation", id = 11 }, ["pants"] = { type = "variation", id = 4 }, ["vest"] = { type = "variation", id = 9 }, ["backpack"] = { type = "variation", id = 5 }, ["shoes"] = { type = "variation", id = 6 }, ["mask"] = { type = "mask", id = 1 }, ["hat"] = { type = "prop", id = 0 }, ["glass"] = { type = "prop", id = 1 }, ["ear"] = { type = "prop", id = 2 }, ["watch"] = { type = "prop", id = 6 }, ["bracelet"] = { type = "prop", id = 7 }, ["accessory"] = { type = "variation", id = 7 }, ["decals"] = { type = "variation", id = 10 } }

local clothing_items = {
    {name = 'Braços', index_name = 'arms', category = 'Roupas', category_index = 'cloths', id = 3, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Camiseta', index_name = 'tshirt', category = 'Roupas', category_index = 'cloths', id = 8, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Jaqueta', index_name = 'torso', category = 'Roupas', category_index = 'cloths', id = 11, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Calças', index_name = 'pants', category = 'Roupas', category_index = 'cloths', id = 4, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Sapatos', index_name = 'shoes', category = 'Roupas', category_index = 'cloths', id = 6, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Colete', index_name = 'vest', category = 'Roupas', category_index = 'cloths', id = 9, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Mochila', index_name = 'backpack', category = 'Roupas', category_index = 'cloths', id = 5, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Acessório', index_name = 'accessory', category = 'Roupas', category_index = 'cloths', id = 7, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Decalques', index_name = 'decals', category = 'Roupas', category_index = 'cloths', id = 10, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Máscara', index_name = 'mask', category = 'Acessórios', category_index = 'accessoires', id = 1, model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Chapéu', index_name = 'hat', category = 'Acessórios', category_index = 'accessoires', id = 'p0', model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Óculos', index_name = 'glass', category = 'Acessórios', category_index = 'accessoires', id = 'p1', model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Brincos', index_name = 'ear', category = 'Acessórios', category_index = 'accessoires', id = 'p2', model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Relógio', index_name = 'watch', category = 'Acessórios', category_index = 'accessoires', id = 'p6', model = {value = 0, max = 0}, texture = {value = 0, max = 0}},
    {name = 'Pulseira', index_name = 'bracelet', category = 'Acessórios', category_index = 'accessoires', id = 'p7', model = {value = 0, max = 0}, texture = {value = 0, max = 0}}
}

-----------------------------------------------------------------------------------------------------------------------------------------
-- GET START LIMIT CLOTHS AND MODELS
-----------------------------------------------------------------------------------------------------------------------------------------

function openShopTableCloths()
    local playerPed = PlayerPedId()

    for indexCategory, categoryParameter in pairs(clothingCategorys) do
        for indexCloth, clothParameter in pairs(clothing_items) do

            if indexCategory == clothParameter["index_name"] then
                if (categoryParameter["type"] == "variation" or categoryParameter["type"] == "mask")  then
                    clothing_items[indexCloth]["model"]["max"] = GetNumberOfPedDrawableVariations(playerPed , categoryParameter["id"]) - 1
                    clothing_items[indexCloth]["texture"]["max"] = GetNumberOfPedTextureVariations(playerPed, categoryParameter["id"], GetPedDrawableVariation(playerPed, categoryParameter["id"])) - 1

                    if clothing_items[indexCloth]["texture"]["max"] <= 0 then
                        clothing_items[indexCloth]["texture"]["max"] = 0
                    end
                end

                if categoryParameter["type"] == "prop" then
                    clothing_items[indexCloth]["model"]["max"] = GetNumberOfPedPropDrawableVariations(playerPed,categoryParameter["id"]) - 1
                    clothing_items[indexCloth]["texture"]["max"] = GetNumberOfPedPropTextureVariations(playerPed,categoryParameter["id"],GetPedPropIndex(playerPed, categoryParameter["id"])) - 1

                    if clothing_items[indexCloth]["texture"]["max"] <= 0 then
                        clothing_items[indexCloth]["texture"]["max"] = 0
                    end
                end
                clothing_items[indexCloth]["type"] = categoryParameter["type"]
                local isProp = categoryParameter["type"] == "prop"
                clothing_items[indexCloth]["model"]["value"] = isProp and GetPedPropIndex(playerPed, categoryParameter.id) or GetPedDrawableVariation(playerPed, categoryParameter.id)
                clothing_items[indexCloth]["texture"]["value"] = isProp and math.max(0, GetPedPropTextureIndex(playerPed, categoryParameter.id)) or GetPedTextureVariation(playerPed, categoryParameter.id)
            end 
        end
    end

    return clothing_items
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE LIMIT CLOTH SPECIFIED
-----------------------------------------------------------------------------------------------------------------------------------------

function getShopCloth(index)
    return clothing_items[index]
end

function getNewLimitCloth(tablePos, cloth) -- array
    local playerPed = PlayerPedId()

    local clothTable = clothing_items[tablePos]

    clothTable["model"]["value"] = cloth["model"]["value"]
    clothTable["texture"]["value"] = cloth["texture"]["value"]

    if clothTable["model"]["value"] > clothTable["model"]["max"] then
        clothTable["model"]["value"] = clothTable["model"]["max"]
    end



    if (cloth["type"] == "variation" or cloth["type"] == "mask") then
        clothTable["model"]["max"] = GetNumberOfPedDrawableVariations(playerPed, cloth["id"]) - 1
        
        clothTable["texture"]["max"] = GetNumberOfPedTextureVariations(playerPed, cloth["id"], cloth["model"]["value"]) - 1

        if clothTable["texture"]["max"] <= 0 then
            clothTable["texture"]["max"] = 0
        end
    end

    if cloth["type"] == "prop" then

        local clothCategory = cloth["index_name"]
        local categoryId = clothingCategorys[clothCategory]["id"]

        clothTable["model"]["max"] = GetNumberOfPedPropDrawableVariations(playerPed, categoryId) - 1

        clothTable["texture"]["max"] = cloth["model"]["value"] < 0 and 0 or GetNumberOfPedPropTextureVariations(playerPed, categoryId, cloth["model"]["value"]) - 1

        if clothTable["texture"]["max"] <= 0 then
            clothTable["texture"]["max"] = 0
        end
    end

    return clothing_items
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE CLOTH
-----------------------------------------------------------------------------------------------------------------------------------------

skinData = {
	["pants"] = { item = 0, texture = 0 },
	["arms"] = { item = 0, texture = 0 },
	["tshirt"] = { item = 1, texture = 0 },
	["torso"] = { item = 0, texture = 0 },
	["vest"] = { item = 0, texture = 0 },
	["backpack"] = { item = 0, texture = 0 },
	["shoes"] = { item = 1, texture = 0 },
	["mask"] = { item = 0, texture = 0 },
	["hat"] = { item = -1, texture = 0 },
	["glass"] = { item = 0, texture = 0 },
	["ear"] = { item = -1, texture = 0 },
	["watch"] = { item = -1, texture = 0 },
	["bracelet"] = { item = -1, texture = 0 },
	["accessory"] = { item = 0, texture = 0 },
	["decals"] = { item = 0, texture = 0 },
}

function changeCloth(cloth)
    local ped = PlayerPedId()
    if GetEntityHealth(ped) <= 101 then return false end
    local category = clothingCategorys[cloth.index_name]
    if not category then return false end
    local model = math.floor(tonumber(cloth.model.value) or 0)
    local texture = math.floor(tonumber(cloth.texture.value) or 0)
    local isProp = category.type == "prop"
    local count = isProp and GetNumberOfPedPropDrawableVariations(ped, category.id) or GetNumberOfPedDrawableVariations(ped, category.id)
    model = math.max(isProp and -1 or 0, math.min(model, count - 1))
    local textures = 0
    if model >= 0 then
        textures = isProp and GetNumberOfPedPropTextureVariations(ped, category.id, model) or GetNumberOfPedTextureVariations(ped, category.id, model)
    end
    texture = math.max(0, math.min(texture, textures - 1))
    if isProp then
        if model < 0 then ClearPedProp(ped, category.id)
        else SetPedPropIndex(ped, category.id, model, texture, true) end
    else
        SetPedComponentVariation(ped, category.id, model, texture, 2)
    end
    cloth.model.value = model
    cloth.texture.value = texture
    skinData[cloth.index_name].item = model
    skinData[cloth.index_name].texture = texture
    return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVE CLOTHS
-----------------------------------------------------------------------------------------------------------------------------------------

function clientFunctions.saveClothInServer()
    local ok, message = serverFunctions.purchaseClothes(vRP.getCustomization())
    if not ok then return false, message end
    clientFunctions.closeNuiShop()
    return true
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- ROTATION
-----------------------------------------------------------------------------------------------------------------------------------------

function userRotate(rotation)
    local function f(n)
        n = n + 0.00000
        return n
    end
	SetEntityHeading(PlayerPedId(), f(rotation))
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- CAM FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------

function prepareCamera()
    local playerPed = PlayerPedId()
    local playerCoords = GetOffsetFromEntityInWorldCoords(playerPed, -0.3,2.0,0)

    RenderScriptCams(false,false,0,1,0)

	DestroyCam(cam, false)

	if not DoesCamExist(cam) then
		cam = CreateCam("DEFAULT_SCRIPTED_CAMERA",true)
		SetCamActive(cam,true)
		RenderScriptCams(true,false,0,true,true)
		SetCamCoord(cam, playerCoords["x"],playerCoords["y"],playerCoords["z"] + 0.5)
		SetCamRot(cam,0.0,0.0,GetEntityHeading(PlayerPedId()) + 180)
	end    
end

function changeCamPosition(camPos)
    local playerPed = PlayerPedId()

    local camOffests = {
        ['hat'] = function()
            local playerCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0, 0.75 ,0)
            SetCamCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z + 0.6)
        end,

        ['shirt'] = function()
            local playerCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0, 1.0, 0)
            SetCamCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z + 0.2)
        end,

        ['body'] = function()
            local playerCoords = GetOffsetFromEntityInWorldCoords(playerPed, -0.3, 2.0, 0)
            SetCamCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z + 0.5)
        end,

        ['shoes'] = function()
            local playerCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0, 1.0, 0)
            SetCamCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z - 0.5)
        end,
    }

    if camOffests[camPos] then
        camOffests[camPos]() 
    end
end


local horizontalFloat = 0.0
local verticalFloat = 0.55

function moveCamPosition(camPos, floatPos)
    local camPositions = {
        ['VERTICAL'] = function()
            verticalFloat = floatPos

            if verticalFloat < 0 then
                verticalFloat = verticalFloat / 0.59
            end

            if verticalFloat >= 0.8 then
                verticalFloat = 0.8
            end
        end,

        ['HORIZONTAL'] = function()
            horizontalFloat = floatPos

            if horizontalFloat < 0 then
                horizontalFloat = -0.1
            end
        end,
    }

    if camPositions[camPos] then
        camPositions[camPos]()
    end

    local playerCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0, (0.45 + horizontalFloat) ,0.10)
    SetCamCoord(cam, playerCoords.x, playerCoords.y, (playerCoords.z + (verticalFloat * 1))   )
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- OPEN NUI
-----------------------------------------------------------------------------------------------------------------------------------------

local usingIntcUi = false

local function hideShopUi()
    if usingIntcUi and GetResourceState("intc_lojaroupas") == "started" then
        exports.intc_lojaroupas:hide()
    end
    usingIntcUi = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end

function clientFunctions.openNuiShop()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    if skinshopOpen or IsPedInAnyVehicle(ped, false) or GetEntityHealth(ped) <= 101
        or (model ~= GetHashKey('mp_f_freemode_01') and model ~= GetHashKey('mp_m_freemode_01'))
        or (skinshopIsCapturingThumbnails and skinshopIsCapturingThumbnails()) then return end
    skinshopOpen = true
    customCamLocation = nil
    oldData = vRP.getCustomization()
    TriggerEvent('flaviin:toggleHud', false)
    local data = {
        customs = openShopTableCloths(),
        gender = model == GetHashKey('mp_f_freemode_01') and 'female' or 'male',
        heading = GetEntityHeading(ped),
        price = SkinshopPurchasePrice
    }
    usingIntcUi = GetResourceState("intc_lojaroupas") == "started"
    if usingIntcUi then
        exports.intc_lojaroupas:show(data)
    else
        SendNUIMessage({action = 'open', data = data})
        SetNuiFocus(true, true)
        SetCursorLocation(0.9, 0.25)
    end
    prepareCamera()
    vRP.playAnim(false,{{"mp_sleep","bind_pose_180"}},true)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE NUI
-----------------------------------------------------------------------------------------------------------------------------------------

function clientFunctions.closeNuiShopAndReset()
    skinshopOpen = false
    if oldData and next(oldData) then
        vRP.setCustomization(oldData)
    end

    TriggerEvent("flaviin:toggleHud",true)
    hideShopUi()
    RenderScriptCams(false,true,250,1,0)
	DestroyCam(cam,false)
    oldData = {}
    ClearPedTasks(PlayerPedId())
end

function clientFunctions.closeNuiShop()
    skinshopOpen = false
    TriggerEvent("flaviin:toggleHud",true)
    hideShopUi()
    RenderScriptCams(false,true,250,1,0)
	DestroyCam(cam,false)
    oldData = {}
    ClearPedTasks(PlayerPedId())
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE NUI LIMIT CLOTHS
-----------------------------------------------------------------------------------------------------------------------------------------

function updateNuiLimitCloths(index, custom)
    local customs = getNewLimitCloth(index, custom)
    if usingIntcUi and GetResourceState("intc_lojaroupas") == "started" then
        exports.intc_lojaroupas:updateLimits(customs)
    else
        SendNUIMessage({action = 'UPDATE_CUSTOM', data = customs})
    end
end

-- Release focus and camera if the resource is restarted with the fitting room open.
AddEventHandler("onResourceStop", function(resource)
    if skinshopOpen and (resource == GetCurrentResourceName() or (resource == "intc_lojaroupas" and usingIntcUi)) then
        clientFunctions.closeNuiShopAndReset()
    end
end)
