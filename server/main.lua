local QBCore = exports['qb-core']:GetCoreObject()

-- Get a list of jobs for the UI
QBCore.Functions.CreateCallback('dw-jobcenter:server:getJobs', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    cb(Config.Jobs, citizenid, playerName)
end)

-- Get applications for a specific job
QBCore.Functions.CreateCallback('dw-jobcenter:server:getApplications', function(source, cb, jobName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        print("Player not found")
        return cb({}) 
    end
    
    print("=== JOB APPLICATION DEBUG ===")
    print("Player ID: " .. source)
    print("Player job: " .. Player.PlayerData.job.name)
    print("Player grade: " .. Player.PlayerData.job.grade.level)
    
    -- Ensure jobName is a string
    if type(jobName) == "table" then
        print("WARNING: jobName is a table, using Player's current job")
        jobName = Player.PlayerData.job.name
    elseif type(jobName) ~= "string" then
        print("WARNING: jobName is not a string, using Player's current job")
        jobName = Player.PlayerData.job.name
    end
    
    print("Requested job: " .. jobName)
    
    -- Instead of using the ORM, use direct SQL query for debugging
    local query = "SELECT * FROM job_applications WHERE job = '" .. jobName .. "'"
    print("Executing direct SQL query: " .. query)
    
    MySQL.query(query, {}, function(results)
        print("SQL query completed")
        
        if not results then
            print("No results returned from SQL")
            cb({})
            return
        end
        
        print("Found " .. #results .. " total applications")
        
        if #results == 0 then
            print("No applications found for job: " .. jobName)
            cb({})
            return
        end
        
        -- Print all applications
        for i=1, #results do
            print(string.format("App #%d: ID=%s, CitizenID=%s, Status=%s", 
                i,
                results[i].id or "nil", 
                results[i].citizenid or "nil", 
                results[i].status or "nil"))
                
            -- Also check if the answers column has valid data
            if results[i].answers then
                local answers = results[i].answers
                print("Answers raw data length: " .. string.len(answers))
                if string.len(answers) > 0 then
                    -- Try to parse just to check validity
                    local success = pcall(function() json.decode(answers) end)
                    print("JSON parse test: " .. (success and "Valid" or "Invalid") .. " JSON")
                end
            else
                print("Answers column is nil")
            end
        end
        
        -- Process all applications
        for i=1, #results do
            -- Parse answers
            if results[i].answers then
                local success, parsed = pcall(function() return json.decode(results[i].answers) end)
                if success then
                    results[i].answers = parsed
                else
                    print("Failed to parse JSON for application ID " .. (results[i].id or "unknown"))
                    -- Fallback to showing raw answers for debugging
                    results[i].answers = {
                        { question = "Raw data (JSON parse failed)", answer = tostring(results[i].answers) }
                    }
                end
            else
                results[i].answers = {}
            end
            
            -- Format date
            if results[i].date_submitted then
                local timestamp = results[i].date_submitted
                -- Try simple string representation if date formatting fails
                local success, formatted = pcall(function() return os.date('%Y-%m-%d %H:%M', timestamp) end)
                if success then
                    results[i].date_submitted = formatted
                else
                    results[i].date_submitted = tostring(timestamp)
                end
            end
        end
        
        -- Return all applications
        cb(results)
    end)
end)

-- Handle whitelisted job applications
RegisterNetEvent('dw-jobcenter:server:applyForJob', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local jobName = data.job
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local answers = data.answers
    
    -- Check if job exists and is whitelisted
    if not Config.Jobs[jobName] then
        TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "This job doesn't exist!", Config.NotificationTypes.error)
        return
    end
    
    if Config.Jobs[jobName].type ~= "whitelisted" then
        TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "This is not a whitelisted job!", Config.NotificationTypes.error)
        return
    end
    
    -- Format the answers for the database
    local formattedAnswers = {}
    for i, question in ipairs(Config.Jobs[jobName].questions) do
        table.insert(formattedAnswers, {
            question = question,
            answer = answers[i] or ""
        })
    end
    
    print("Saving application for " .. playerName .. " to job " .. jobName)
    
    -- Insert application into database
    MySQL.insert('INSERT INTO job_applications (citizenid, job, name, answers, status, date_submitted) VALUES (?, ?, ?, ?, ?, ?)', {
        citizenid,
        jobName,
        playerName,
        json.encode(formattedAnswers),
        'pending',
        os.date('%Y-%m-%d %H:%M:%S')
    }, function(id)
        if id > 0 then
            print("Application saved successfully with ID: " .. id)
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Your application has been submitted!", Config.NotificationTypes.success)
        else
            print("Failed to save application to database")
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Failed to submit application. Please try again.", Config.NotificationTypes.error)
        end
    end)
end)

-- Handle application reviews
RegisterNetEvent('dw-jobcenter:server:reviewApplication', function(applicationId, action, notes)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    print("Processing application review:")
    print("Application ID: " .. applicationId)
    print("Action: " .. action)
    print("Reviewer: " .. Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname)
    
    -- Get application details
    MySQL.query('SELECT * FROM job_applications WHERE id = ?', {applicationId}, function(results)
        if not results or #results == 0 then
            print("Application not found in database")
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Application not found!", Config.NotificationTypes.error)
            return
        end
        
        local application = results[1]
        print("Found application for job: " .. (application.job or "unknown"))
        
        -- Check if reviewer has permission
        if Player.PlayerData.job.name ~= application.job then
            print("Reviewer job does not match application job")
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "You don't have permission to review this application!", Config.NotificationTypes.error)
            return
        end
        
        -- Check reviewer grade (relaxed for debugging)
        local minGrade = Config.Jobs[application.job] and Config.Jobs[application.job].minReviewGrade or 0
        if Player.PlayerData.job.grade.level < minGrade then
            print("Reviewer grade too low: " .. Player.PlayerData.job.grade.level .. " < " .. minGrade)
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "You don't have permission to review applications!", Config.NotificationTypes.error)
            return
        end
        
        -- Update application status
        local newStatus = action == 'accept' and 'accepted' or 'rejected'
        local reviewerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        
        print("Updating application status to: " .. newStatus)
        
        -- Update the application in the database
        MySQL.update('UPDATE job_applications SET status = ?, reviewer_id = ?, date_reviewed = ?, notes = ? WHERE id = ?', {
            newStatus,
            Player.PlayerData.citizenid,
            os.date('%Y-%m-%d %H:%M:%S'),
            notes or '',
            applicationId
        }, function(rowsChanged)
            print("Database update result: " .. rowsChanged .. " rows changed")
            
            if rowsChanged > 0 then
                TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Application " .. newStatus .. "!", Config.NotificationTypes.success)
                
                -- If accepted, set the player's job
                if action == 'accept' then
                    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(application.citizenid)
                    if targetPlayer then
                        -- Player is online, set job immediately
                        print("Applicant is online, setting job immediately")
                        targetPlayer.Functions.SetJob(application.job, Config.Jobs[application.job].grade)
                        TriggerClientEvent('dw-jobcenter:client:sendNotification', targetPlayer.PlayerData.source, "Your application for " .. Config.Jobs[application.job].label .. " has been accepted!", Config.NotificationTypes.success)
                    else
                        -- Player is offline, update in database
                        print("Applicant is offline, updating database")
                        MySQL.update('UPDATE players SET job = ?, job_grade = ? WHERE citizenid = ?', {
                            application.job,
                            Config.Jobs[application.job].grade,
                            application.citizenid
                        })
                    end
                else
                    -- If rejected, notify the player if they're online
                    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(application.citizenid)
                    if targetPlayer then
                        print("Notifying applicant of rejection")
                        TriggerClientEvent('dw-jobcenter:client:sendNotification', targetPlayer.PlayerData.source, "Your application for " .. Config.Jobs[application.job].label .. " has been rejected.", Config.NotificationTypes.error)
                    end
                end
            else
                print("Database update failed")
                TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Failed to update application status.", Config.NotificationTypes.error)
            end
        end)
    end)
end)

-- Handle non-whitelisted job selection
RegisterNetEvent('dw-jobcenter:server:takeJob', function(jobName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if job exists and is not whitelisted
    if not Config.Jobs[jobName] then
        TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "This job doesn't exist!", Config.NotificationTypes.error)
        return
    end
    
    if Config.Jobs[jobName].type == "whitelisted" then
        TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "You need to apply for this job first!", Config.NotificationTypes.error)
        return
    end
    
    -- Set player's job
    Player.Functions.SetJob(jobName, Config.Jobs[jobName].grade)
    TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "You are now employed as a " .. Config.Jobs[jobName].label, Config.NotificationTypes.success)
end)