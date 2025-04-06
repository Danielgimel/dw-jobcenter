local ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('dw-jobcenter:server:getJobs', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    local citizenid = xPlayer.identifier
    local playerName = xPlayer.getName()
    cb(Config.Jobs, citizenid, playerName)
end)

ESX.RegisterServerCallback('dw-jobcenter:server:getApplications', function(source, cb, jobName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return cb({})
    end

    if type(jobName) ~= "string" then
        jobName = xPlayer.job.name
    end

    local query = "SELECT * FROM job_applications WHERE job = ?"
    
    MySQL.query(query, {jobName}, function(results)
        if not results or #results == 0 then
            cb({})
            return
        }

        for i=1, #results do
            if results[i].answers then
                local success, parsed = pcall(function() return json.decode(results[i].answers) end)
                if success then
                    results[i].answers = parsed
                else
                    results[i].answers = {
                        { question = "Raw data (JSON parse failed)", answer = tostring(results[i].answers) }
                    }
                end
            else
                results[i].answers = {}
            end

            if results[i].date_submitted then
                local timestamp = results[i].date_submitted
                local success, formatted = pcall(function() return os.date('%Y-%m-%d %H:%M', timestamp) end)
                if success then
                    results[i].date_submitted = formatted
                else
                    results[i].date_submitted = tostring(timestamp)
                end
            end
        end

        cb(results)
    end)
end)

RegisterNetEvent('dw-jobcenter:server:applyForJob', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local citizenid = xPlayer.identifier
    local jobName = data.job
    local playerName = xPlayer.getName()
    local answers = data.answers

    if not Config.Jobs[jobName] then
        TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "This job doesn't exist!")
        return
    end

    if Config.Jobs[jobName].type ~= "whitelisted" then
        TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "This is not a whitelisted job!")
        return
    end

    local formattedAnswers = {}
    for i, question in ipairs(Config.Jobs[jobName].questions) do
        table.insert(formattedAnswers, {
            question = question,
            answer = answers[i] or ""
        })
    end

    MySQL.insert('INSERT INTO job_applications (citizenid, job, name, answers, status, date_submitted) VALUES (?, ?, ?, ?, ?, ?)', {
        citizenid,
        jobName,
        playerName,
        json.encode(formattedAnswers),
        'pending',
        os.date('%Y-%m-%d %H:%M:%S')
    }, function(id)
        if id > 0 then
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Your application has been submitted!")
        else
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Failed to submit application. Please try again.")
        end
    end)
end)

RegisterNetEvent('dw-jobcenter:server:reviewApplication', function(applicationId, action, notes)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    MySQL.query('SELECT * FROM job_applications WHERE id = ?', {applicationId}, function(results)
        if not results or #results == 0 then
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Application not found!")
            return
        end

        local application = results[1]

        if xPlayer.job.name ~= application.job then
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "You don't have permission to review this application!")
            return
        end

        local minGrade = (Config.Jobs[application.job] and Config.Jobs[application.job].minReviewGrade) or 0
        if xPlayer.job.grade < minGrade then
            TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "You don't have permission to review applications!")
            return
        end

        local newStatus = action == 'accept' and 'accepted' or 'rejected'
        local reviewerName = xPlayer.getName()

        MySQL.update('UPDATE job_applications SET status = ?, reviewer_id = ?, date_reviewed = ?, notes = ? WHERE id = ?', {
            newStatus,
            xPlayer.identifier,
            os.date('%Y-%m-%d %H:%M:%S'),
            notes or '',
            applicationId
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Application " .. newStatus .. "!")
                
                if action == 'accept' then
                    local targetPlayer = ESX.GetPlayerFromIdentifier(application.citizenid)
                    if targetPlayer then
                        targetPlayer.setJob(application.job, Config.Jobs[application.job].grade)
                        TriggerClientEvent('dw-jobcenter:client:sendNotification', targetPlayer.source, "Your application for " .. Config.Jobs[application.job].label .. " has been accepted!")
                    else
                        MySQL.update('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {
                            application.job,
                            Config.Jobs[application.job].grade,
                            application.citizenid
                        })
                    end
                else
                    local targetPlayer = ESX.GetPlayerFromIdentifier(application.citizenid)
                    if targetPlayer then
                        TriggerClientEvent('dw-jobcenter:client:sendNotification', targetPlayer.source, "Your application for " .. Config.Jobs[application.job].label .. " has been rejected.")
                    end
                end
            else
                TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "Failed to update application status.")
            end
        end)
    end)
end)

RegisterNetEvent('dw-jobcenter:server:takeJob', function(jobName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not Config.Jobs[jobName] then
        TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "This job doesn't exist!")
        return
    end

    if Config.Jobs[jobName].type == "whitelisted" then
        TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "You need to apply for this job first!")
        return
    end

    xPlayer.setJob(jobName, Config.Jobs[jobName].grade)
    TriggerClientEvent('dw-jobcenter:client:sendNotification', src, "You are now employed as a " .. Config.Jobs[jobName].label)
end)
