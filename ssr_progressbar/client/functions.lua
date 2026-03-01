mythic_action = {
    name = "",
    duration = 0,
    label = "",
    useWhileDead = false,
    canCancel = true,
	disarm = true,
    controlDisables = {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false,
    },
    animation = {
        animDict = nil,
        anim = nil,
        flags = 0,
        task = nil,
    },
    prop = {
        model = nil,
        bone = nil,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    },
    propTwo = {
        model = nil,
        bone = nil,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    },
}

local isDoingAction = false
local wasCancelled = false
local isAnim = false
local isProp = false
local isPropTwo = false
local prop_net = nil
local propTwo_net = nil
local runProgThread = false

local wait = Citizen.Wait
local createThread = Citizen.CreateThread
local playerPedId = PlayerPedId
local isEntityDead = IsEntityDead
local isControlJustPressed = IsControlJustPressed

local function hasControlDisables(action)
    if action == nil or action.controlDisables == nil then
        return false
    end

    local disables = action.controlDisables
    return disables.disableMouse or disables.disableMovement or disables.disableCarMovement or disables.disableCombat
end

function Progress(action, finish)
	Process(action, nil, nil, finish)
end

function ProgressWithStartEvent(action, start, finish)
	Process(action, start, nil, finish)
end

function ProgressWithTickEvent(action, tick, finish)
	Process(action, nil, tick, finish)
end

function ProgressWithStartAndTick(action, start, tick, finish)
	Process(action, start, tick, finish)
end

function Process(action, start, tick, finish)
	ActionStart()
    mythic_action = action

    if not isEntityDead(playerPedId()) or mythic_action.useWhileDead then
        if not isDoingAction then
            isDoingAction = true
            wasCancelled = false
            isAnim = false
            isProp = false
            isPropTwo = false

            SendNUIMessage({
                action = "mythic_progress",
                duration = mythic_action.duration,
                label = mythic_action.label,
                colors = {
                    progressBar = (Config and Config.Colors and Config.Colors.progressBar) or nil,
                    percentText = (Config and Config.Colors and Config.Colors.percentText) or nil
                }
            })

            createThread(function ()
                if start ~= nil then
                    start()
                end

                local shouldCheckDeath = not mythic_action.useWhileDead
                local deathCheckTimer = 0
                local loopWait = 50
                if tick ~= nil then
                    loopWait = 1
                elseif mythic_action.canCancel then
                    loopWait = 5
                end

                while isDoingAction do
                    wait(loopWait)

                    if tick ~= nil then
                        tick()
                    end

                    if mythic_action.canCancel and isControlJustPressed(0, 178) then
                        TriggerEvent("ssr_progressbar:client:cancel")
                        break
                    end

                    if shouldCheckDeath then
                        deathCheckTimer = deathCheckTimer + loopWait
                        if deathCheckTimer >= 150 then
                            deathCheckTimer = 0
                            if isEntityDead(playerPedId()) then
                                TriggerEvent("ssr_progressbar:client:cancel")
                                break
                            end
                        end
                    end
                end

                if finish ~= nil then
                    finish(wasCancelled)
                end
            end)
        else
            print('[ssr_progressbar] Already Doing An Action')
        end
    else
        print('[ssr_progressbar] Cannot Perform An Action While Dead')
    end
end

function ActionStart()
    if runProgThread then
        return
    end

    runProgThread = true
    createThread(function()
        while runProgThread do
            local sleep = 250

            if isDoingAction then
                local ped = playerPedId()
                local shouldDisable = hasControlDisables(mythic_action)
                sleep = shouldDisable and 0 or 150

                if not isAnim then
                    if mythic_action.animation ~= nil then
                        if mythic_action.animation.task ~= nil then
                            TaskStartScenarioInPlace(ped, mythic_action.animation.task, 0, true)
                        elseif mythic_action.animation.animDict ~= nil and mythic_action.animation.anim ~= nil then
                            if mythic_action.animation.flags == nil then
                                mythic_action.animation.flags = 1
                            end

                            if (DoesEntityExist(ped) and not isEntityDead(ped)) then
                                loadAnimDict( mythic_action.animation.animDict )
                                TaskPlayAnim(ped, mythic_action.animation.animDict, mythic_action.animation.anim, 3.0, 1.0, -1, mythic_action.animation.flags, 0, 0, 0, 0)
                            end
                        else
                            TaskStartScenarioInPlace(ped, 'PROP_HUMAN_BUM_BIN', 0, true)
                        end
                    end

                    isAnim = true
                end
                if not isProp and mythic_action.prop ~= nil and mythic_action.prop.model ~= nil then
                    local modelHash = GetHashKey(mythic_action.prop.model)
                    RequestModel(modelHash)

                    while not HasModelLoaded(modelHash) do
                        wait(0)
                    end

                    local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
                    local modelSpawn = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, true)

                    local netid = ObjToNet(modelSpawn)
                    SetNetworkIdExistsOnAllMachines(netid, true)
                    NetworkSetNetworkIdDynamic(netid, true)
                    SetNetworkIdCanMigrate(netid, false)
                    if mythic_action.prop.bone == nil then
                        mythic_action.prop.bone = 60309
                    end

                    if mythic_action.prop.coords == nil then
                        mythic_action.prop.coords = { x = 0.0, y = 0.0, z = 0.0 }
                    end

                    if mythic_action.prop.rotation == nil then
                        mythic_action.prop.rotation = { x = 0.0, y = 0.0, z = 0.0 }
                    end

                    AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, mythic_action.prop.bone), mythic_action.prop.coords.x, mythic_action.prop.coords.y, mythic_action.prop.coords.z, mythic_action.prop.rotation.x, mythic_action.prop.rotation.y, mythic_action.prop.rotation.z, 1, 1, 0, 1, 0, 1)
                    prop_net = netid

                    isProp = true
                    
                    if not isPropTwo and mythic_action.propTwo ~= nil and mythic_action.propTwo.model ~= nil then
                        local modelTwoHash = GetHashKey(mythic_action.propTwo.model)
                        RequestModel(modelTwoHash)

                        while not HasModelLoaded(modelTwoHash) do
                            wait(0)
                        end

                        local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
                        local modelSpawn = CreateObject(modelTwoHash, pCoords.x, pCoords.y, pCoords.z, true, true, true)

                        local netid = ObjToNet(modelSpawn)
                        SetNetworkIdExistsOnAllMachines(netid, true)
                        NetworkSetNetworkIdDynamic(netid, true)
                        SetNetworkIdCanMigrate(netid, false)
                        if mythic_action.propTwo.bone == nil then
                            mythic_action.propTwo.bone = 60309
                        end

                        if mythic_action.propTwo.coords == nil then
                            mythic_action.propTwo.coords = { x = 0.0, y = 0.0, z = 0.0 }
                        end

                        if mythic_action.propTwo.rotation == nil then
                            mythic_action.propTwo.rotation = { x = 0.0, y = 0.0, z = 0.0 }
                        end

                        AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, mythic_action.propTwo.bone), mythic_action.propTwo.coords.x, mythic_action.propTwo.coords.y, mythic_action.propTwo.coords.z, mythic_action.propTwo.rotation.x, mythic_action.propTwo.rotation.y, mythic_action.propTwo.rotation.z, 1, 1, 0, 1, 0, 1)
                        propTwo_net = netid

                        isPropTwo = true
                    end
                end

                if shouldDisable then
                    DisableActions(ped)
                end
            end
            wait(sleep)
        end
    end)
end

function Cancel()
    isDoingAction = false
    wasCancelled = true

    ActionCleanup()

    SendNUIMessage({
        action = "mythic_progress_cancel"
    })
end

function Finish()
    isDoingAction = false
    ActionCleanup()
end

function ActionCleanup()
    local ped = PlayerPedId()
    --ClearPedTasks(ped)

    if mythic_action.animation ~= nil then
        if mythic_action.animation.task ~= nil or (mythic_action.animation.animDict ~= nil and mythic_action.animation.anim ~= nil) then
            ClearPedSecondaryTask(ped)
            StopAnimTask(ped, mythic_action.animation.animDict, mythic_action.animation.anim, 1.0)
        else
            ClearPedTasks(ped)
        end
    end

    if prop_net then
        local propEntity = NetToObj(prop_net)
        if propEntity and DoesEntityExist(propEntity) then
            DetachEntity(propEntity, 1, 1)
            DeleteEntity(propEntity)
        end
    end

    if propTwo_net then
        local propTwoEntity = NetToObj(propTwo_net)
        if propTwoEntity and DoesEntityExist(propTwoEntity) then
            DetachEntity(propTwoEntity, 1, 1)
            DeleteEntity(propTwoEntity)
        end
    end

    prop_net = nil
    propTwo_net = nil
    runProgThread = false
end

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		wait(5)
	end
end

function DisableActions(ped)
    if mythic_action.controlDisables.disableMouse then
        DisableControlAction(0, 1, true) -- LookLeftRight
        DisableControlAction(0, 2, true) -- LookUpDown
        DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
    end

    if mythic_action.controlDisables.disableMovement then
        DisableControlAction(0, 30, true) -- disable left/right
        DisableControlAction(0, 31, true) -- disable forward/back
        DisableControlAction(0, 36, true) -- INPUT_DUCK
        DisableControlAction(0, 21, true) -- disable sprint
    end

    if mythic_action.controlDisables.disableCarMovement then
        DisableControlAction(0, 63, true) -- veh turn left
        DisableControlAction(0, 64, true) -- veh turn right
        DisableControlAction(0, 71, true) -- veh forward
        DisableControlAction(0, 72, true) -- veh backwards
        DisableControlAction(0, 75, true) -- disable exit vehicle
    end

    if mythic_action.controlDisables.disableCombat then
        DisablePlayerFiring(PlayerId(), true) -- Disable weapon firing
        DisableControlAction(0, 24, true) -- disable attack
        DisableControlAction(0, 25, true) -- disable aim
        DisableControlAction(1, 37, true) -- disable weapon select
        DisableControlAction(0, 47, true) -- disable weapon
        DisableControlAction(0, 58, true) -- disable weapon
        DisableControlAction(0, 140, true) -- disable melee
        DisableControlAction(0, 141, true) -- disable melee
        DisableControlAction(0, 142, true) -- disable melee
        DisableControlAction(0, 143, true) -- disable melee
        DisableControlAction(0, 263, true) -- disable melee
        DisableControlAction(0, 264, true) -- disable melee
        DisableControlAction(0, 257, true) -- disable melee
    end
end
