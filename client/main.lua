local PlayerData = {}
local jobCenterPedCreated = false
local isJobCenterOpen = false
local isReviewOpen = false
local jobCenterPed = nil
local jobCenterBlip = nil

Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports["es_extended"]:getSharedObject()
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
    SetupJobCenter()
    
    if Config.ApplicationSystem == 'internal' then
        SetupReviewPoints()
    end
end)

RegisterNetEvent('esx:playerLoaded')
function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function CreateJobCenterBlip()
    if not Config.UseBlip then return end

    if jobCenterBlip then
        RemoveBlip(jobCenterBlip)
    end

    jobCenterBlip = AddBlipForCoord(Config.JobCenterLocation.x, Config.JobCenterLocation.y, Config.JobCenterLocation.z)
    SetBlipSprite(jobCenterBlip, Config.Blip.sprite)
    SetBlipDisplay(jobCenterBlip, 4)
    SetBlipScale(jobCenterBlip, Config.Blip.scale)
    SetBlipColour(jobCenterBlip, Config.Blip.color)
    SetBlipAsShortRange(jobCenterBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(jobCenterBlip)
end

local function SetupJobCenterPed()
    if jobCenterPedCreated or jobCenterPed ~= nil then return end

    local model = Config.JobCenterPed
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end

    jobCenterPed = CreatePed(4, model, Config.JobCenterLocation.x, Config.JobCenterLocation.y, Config.JobCenterLocation.z - 1.0, Config.JobCenterLocation.w, false, true)
    SetEntityHeading(jobCenterPed, Config.JobCenterLocation.w)
    FreezeEntityPosition(jobCenterPed, true)
    SetEntityInvincible(jobCenterPed, true)
    SetBlockingOfNonTemporaryEvents(jobCenterPed, true)
    TaskStartScenarioInPlace(jobCenterPed, "WORLD_HUMAN_CLIPBOARD", 0, true)

    jobCenterPedCreated = true
end

local function SetupTargetSystem()
    if not Config.UseTarget then return end

    if Config.TargetSystem == 'qb' then
        exports['qb-target']:AddBoxZone("jobcenter", Config.JobCenterLocation.xyz, 2.0, 2.0, {
            name = "jobcenter",
            heading = Config.JobCenterLocation.w,
            debugPoly = false,
            minZ = Config.JobCenterLocation.z - 1,
            maxZ = Config.JobCenterLocation.z + 1,
        }, {
            options = {
                {
                    type = "client",
                    event = "dw-jobcenter:client:openJobCenter",
                    icon = "fas fa-briefcase",
                    label = "Job Center",
                },
            },
            distance = 2.0
        })
    elseif Config.TargetSystem == 'ox' then
        exports.ox_target:addBoxZone({
            coords = Config.JobCenterLocation.xyz,
            size = vector3(2.0, 2.0, 2.0),
            rotation = Config.JobCenterLocation.w,
            debug = false,
            options = {
                {
                    name = 'jobcenter',
                    icon = 'fas fa-briefcase',
                    label = 'Job Center',
                    onSelect = function()
                        TriggerEvent('dw-jobcenter:client:openJobCenter')
                    end
                }
            }
        })
    end
end

local function SetupReviewPoints()
    if Config.ApplicationSystem ~= 'internal' then return end

    for jobName, location in pairs(Config.ReviewLocations) do
        local canAccess = function()
            if not PlayerData.job then return false end
            if PlayerData.job.name ~= jobName then return false end

            local minGrade = Config.Jobs[jobName].minReviewGrade or 1
            return PlayerData.job.grade >= minGrade
        end

        if Config.TargetSystem == 'qb' then
            exports['qb-target']:AddBoxZone("review_"..jobName, location.pos, 1.0, 1.0, {
                name = "review_"..jobName,
                heading = 0.0,
                debugPoly = false,
                minZ = location.pos.z - 1,
                maxZ = location.pos.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "dw-jobcenter:client:openReviewMenu",
                        icon = "fas fa-clipboard-list",
                        label = location.label,
                        job = jobName,
                        canInteract = canAccess,
                        args = {job = jobName}
                    },
                },
                distance = 2.0
            })
        elseif Config.TargetSystem == 'ox' then
            exports.ox_target:addBoxZone({
                coords = location.pos,
                size = vector3(1.0, 1.0, 1.0),
                rotation = 0.0,
                debug = false,
                options = {
                    {
                        name = 'review_'..jobName,
                        icon = 'fas fa-clipboard-list',
                        label = location.label,
                        canInteract = canAccess,
                        onSelect = function()
                            TriggerEvent('dw-jobcenter:client:openReviewMenu', {job = jobName})
                        end
                    }
                }
            })
        else
            Citizen.CreateThread(function()
                while true do
                    local sleep = 1000
                    if canAccess() then
                        local pos = GetEntityCoords(PlayerPedId())
                        local dist = #(pos - location.pos)
                        if dist < 10 then
                            sleep = 0
                            if dist < 1.5 and not isReviewOpen then
                                DrawText3D(location.pos.x, location.pos.y, location.pos.z, "~g~E~w~ - " .. location.label)
                                if IsControlJustReleased(0, 38) then
                                    TriggerEvent('dw-jobcenter:client:openReviewMenu', jobName)
                                end
                            end
                        end
                    end
                    Citizen.Wait(sleep)
                end
            end)
        end
    end
end

local function SetupDrawText()
    if Config.UseTarget then return end

    Citizen.CreateThread(function()
        while true do
            local sleep = 1000
            local pos = GetEntityCoords(PlayerPedId())
            local dist = #(pos - Config.JobCenterLocation.xyz)
            if dist < 10 then
                sleep = 0
                if dist < 1.5 and not isJobCenterOpen then
                    DrawText3D(Config.JobCenterLocation.x, Config.JobCenterLocation.y, Config.JobCenterLocation.z, "~g~E~w~ - Open Job Center")
                    if IsControlJustReleased(0, 38) then
                        TriggerEvent('dw-jobcenter:client:openJobCenter')
                    end
                end
            end
            Citizen.Wait(sleep)
        end
    end)
end

local function SetupJobCenter()
    CreateJobCenterBlip()
    if Config.UseTarget then
        SetupTargetSystem()
    else
        SetupDrawText()
    end
    SetupJobCenterPed()
end

local function OpenJobCenter()
    if isJobCenterOpen then return end

    isJobCenterOpen = true

    ESX.TriggerServerCallback('dw-jobcenter:server:getJobs', function(jobs, citizenid, playerName)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openJobCenter",
            jobs = jobs,
            jobOrder = Config.JobOrder,
            citizenid = citizenid,
            playerName = playerName
        })
    end)
end

local function CloseJobCenter()
    if not isJobCenterOpen then return end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeJobCenter" })
    isJobCenterOpen = false
end

local function OpenReviewMenu(jobNameInput)
    if isReviewOpen then return end

    local jobName = PlayerData.job.name
    if type(jobNameInput) == "table" then
        if jobNameInput.job and type(jobNameInput.job) == "string" then
            jobName = jobNameInput.job
        end
    elseif type(jobNameInput) == "string" and jobNameInput ~= "" then
        jobName = jobNameInput
    end

    if not Config.Jobs[jobName] then
        ESX.ShowNotification('Invalid job configuration for: ' .. jobName)
        return
    end

    ESX.ShowNotification('Checking for applications...')
    isReviewOpen = true

    ESX.TriggerServerCallback('dw-jobcenter:server:getApplications', function(applications)
        if not applications or #applications == 0 then
            ESX.ShowNotification('There are no applications to review')
            isReviewOpen = false
            return
        end

        ESX.ShowNotification('Found ' .. #applications .. ' applications')
        local jobLabel = Config.Jobs[jobName].label or "Unknown Job"

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openReviewMenu",
            applications = applications,
            jobName = jobName,
            jobLabel = jobLabel
        })
    end, jobName)
end

local function CloseReviewMenu()
    if not isReviewOpen then return end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeReviewMenu" })
    isReviewOpen = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isReviewOpen and IsControlJustReleased(0, 322) then
            CloseReviewMenu()
        end
    end
end)

RegisterNetEvent('dw-jobcenter:client:openJobCenter', function()
    OpenJobCenter()
end)

RegisterNetEvent('dw-jobcenter:client:closeJobCenter', function()
    CloseJobCenter()
end)

RegisterNetEvent('dw-jobcenter:client:openReviewMenu', function(data)
    OpenReviewMenu(data)
end)

RegisterNetEvent('dw-jobcenter:client:closeReviewMenu', function()
    CloseReviewMenu()
end)

RegisterNetEvent('dw-jobcenter:client:sendNotification', function(message, type)
    ESX.ShowNotification(message)
end)

RegisterNUICallback('closeJobCenter', function(_, cb)
    CloseJobCenter()
    cb('ok')
end)

RegisterNUICallback('closeReviewMenu', function(_, cb)
    CloseReviewMenu()
    cb('ok')
end)

RegisterNUICallback('applyForJob', function(data, cb)
    TriggerServerEvent('dw-jobcenter:server:applyForJob', data)
    CloseJobCenter()
    cb('ok')
end)

RegisterNUICallback('takeJob', function(data, cb)
    TriggerServerEvent('dw-jobcenter:server:takeJob', data.job)
    CloseJobCenter()
    cb('ok')
end)

RegisterNUICallback('reviewApplication', function(data, cb)
    TriggerServerEvent('dw-jobcenter:server:reviewApplication', data.id, data.action, data.notes)
    cb('ok')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    while ESX == nil do Citizen.Wait(10) end
    PlayerData = ESX.GetPlayerData() or {}
    SetupJobCenter()
    if Config.ApplicationSystem == 'internal' then
        SetupReviewPoints()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if isJobCenterOpen then
        SetNuiFocus(false, false)
    end

    if isReviewOpen then
        SetNuiFocus(false, false)
    end

    if jobCenterPed ~= nil then
        DeletePed(jobCenterPed)
        jobCenterPed = nil
        jobCenterPedCreated = false
    end

    if jobCenterBlip ~= nil then
        RemoveBlip(jobCenterBlip)
        jobCenterBlip = nil
    end
end)
