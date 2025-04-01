local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local jobCenterPedCreated = false
local isJobCenterOpen = false
local isReviewOpen = false
local jobCenterPed = nil
local jobCenterBlip = nil

-- Functions
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
    
    -- Remove existing blip if it exists
    if jobCenterBlip then
        RemoveBlip(jobCenterBlip)
    end
    
    -- Create new blip
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
        Wait(0)
    end
    
    -- Use a consistent spawn position
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
        -- Setup for qb-target
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
        -- Setup for ox_target
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
    -- Skip if using external boss menu
    if Config.ApplicationSystem ~= 'internal' then return end
    
    -- Setup review points for each job
    for jobName, location in pairs(Config.ReviewLocations) do
        -- Check if player has the required job and grade to access this point
        local canAccess = function()
            if not PlayerData.job then return false end
            if PlayerData.job.name ~= jobName then return false end
            
            local minGrade = Config.Jobs[jobName].minReviewGrade or 1
            return PlayerData.job.grade.level >= minGrade
        end
        
        if Config.TargetSystem == 'qb' then
            -- Setup for qb-target
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
            -- Setup for ox_target
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
            -- Setup draw text for non-target systems
            CreateThread(function()
                while true do
                    local sleep = 1000
                    if canAccess() then
                        local pos = GetEntityCoords(PlayerPedId())
                        local dist = #(pos - location.pos)
                        
                        if dist < 10 then
                            sleep = 0
                            if dist < 1.5 then
                                if not isReviewOpen then
                                    DrawText3D(location.pos.x, location.pos.y, location.pos.z, "~g~E~w~ - " .. location.label)
                                    if IsControlJustReleased(0, 38) then -- E key
                                        TriggerEvent('dw-jobcenter:client:openReviewMenu', jobName)
                                    end
                                end
                            end
                        end
                    end
                    Wait(sleep)
                end
            end)
        end
    end
end

local function SetupDrawText()
    if Config.UseTarget then return end
    
    CreateThread(function()
        while true do
            local sleep = 1000
            local pos = GetEntityCoords(PlayerPedId())
            local dist = #(pos - Config.JobCenterLocation.xyz)
            
            if dist < 10 then
                sleep = 0
                if dist < 1.5 then
                    if not isJobCenterOpen then
                        DrawText3D(Config.JobCenterLocation.x, Config.JobCenterLocation.y, Config.JobCenterLocation.z, "~g~E~w~ - Open Job Center")
                        if IsControlJustReleased(0, 38) then -- E key
                            TriggerEvent('dw-jobcenter:client:openJobCenter')
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

local function SetupJobCenter()
    -- Create blip on the map
    CreateJobCenterBlip()
    
    -- Setup target system or draw text based on config
    if Config.UseTarget then
        SetupTargetSystem()
    else
        SetupDrawText()
    end
    
    -- Create the job center ped
    SetupJobCenterPed()
end

local function OpenJobCenter()
    if isJobCenterOpen then return end
    
    isJobCenterOpen = true
    
    QBCore.Functions.TriggerCallback('dw-jobcenter:server:getJobs', function(jobs, citizenid, playerName)
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
    SendNUIMessage({
        action = "closeJobCenter"
    })
    
    -- Reset state immediately
    isJobCenterOpen = false
end

local function OpenReviewMenu(jobNameInput)
    if isReviewOpen then return end
    
    -- Get the actual job name (handle if it's a table)
    local jobName = PlayerData.job.name -- Default to player's job
    
    -- Check if input is a table
    if type(jobNameInput) == "table" then
        -- See if there's a job field in the table
        if jobNameInput.job and type(jobNameInput.job) == "string" then
            jobName = jobNameInput.job
        end
    elseif type(jobNameInput) == "string" and jobNameInput ~= "" then
        jobName = jobNameInput
    end
    
    -- Validate the job exists in config
    if not Config.Jobs[jobName] then
        QBCore.Functions.Notify('Invalid job configuration for: ' .. jobName, 'error')
        return
    end
    
    QBCore.Functions.Notify('Checking for applications...', 'primary')
    isReviewOpen = true
    
    QBCore.Functions.TriggerCallback('dw-jobcenter:server:getApplications', function(applications)
        if not applications or #applications == 0 then
            QBCore.Functions.Notify('There are no applications to review', 'error')
            isReviewOpen = false
            return
        end
        
        QBCore.Functions.Notify('Found ' .. #applications .. ' applications', 'success')
        
        -- Set safe defaults for missing values
        local jobLabel = "Unknown Job"
        if Config.Jobs[jobName] and Config.Jobs[jobName].label then
            jobLabel = Config.Jobs[jobName].label
        end
        
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
    SendNUIMessage({
        action = "closeReviewMenu"
    })
    
    -- Reset state immediately
    isReviewOpen = false
end

CreateThread(function()
    while true do
        Wait(0)
        if isReviewOpen and IsControlJustReleased(0, 322) then -- ESC key
            CloseReviewMenu()
        end
    end
end)

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData() or {}
    SetupJobCenter()
    
    if Config.ApplicationSystem == 'internal' then
        SetupReviewPoints()
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Events
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
    QBCore.Functions.Notify(message, type)
end)

-- NUI Callbacks
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

-- Resource Initialization - only call once
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    -- Initialize PlayerData
    PlayerData = QBCore.Functions.GetPlayerData() or {}
    
    SetupJobCenter()
    
    if Config.ApplicationSystem == 'internal' then
        SetupReviewPoints()
    end
end)

-- Handle resource stopping
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    -- Clean up when resource stops
    if isJobCenterOpen then
        SetNuiFocus(false, false)
    end
    
    if isReviewOpen then
        SetNuiFocus(false, false)
    end
    
    -- Delete ped on resource stop
    if jobCenterPed ~= nil then
        DeletePed(jobCenterPed)
        jobCenterPed = nil
        jobCenterPedCreated = false
    end
    
    -- Remove blip on resource stop
    if jobCenterBlip ~= nil then
        RemoveBlip(jobCenterBlip)
        jobCenterBlip = nil
    end
end)