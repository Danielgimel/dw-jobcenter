Config = {}

-- General Settings
Config.UseTarget = true -- Use target system (true) or DrawText (false)
Config.TargetSystem = 'ox' -- Options: 'qb' for qb-target, 'ox' for ox_target

-- Application Management System
Config.ApplicationSystem = 'internal' -- Options: 'internal' for built-in system, 'dw-bossmenu' for external dw-bossmenu
Config.ReviewLocations = {
    police = {
        pos = vector3(450.17932, -972.69, 30.689582),
        label = "Review Police Applications"
    },
    ambulance = {
        pos = vector3(310.1, -599.43, 43.29),
        label = "Review EMS Applications"
    },
    lawyer = {
        pos = vector3(237.52, -413.1, 48.11),
        label = "Review Legal Applications"
    }
}

-- Job Center Location
Config.JobCenterLocation = vector4(236.32, -409.39, 47.92, 338.72) -- Location of the job center
Config.JobCenterPed = `a_m_y_business_03` -- Ped model hash (consistent across restarts)

-- Blip Settings
Config.UseBlip = true
Config.Blip = {
    sprite = 407, -- Blip sprite (icon)
    color = 27, -- Blip color
    scale = 0.7, -- Blip size
    label = "Job Center" -- Blip name on map
}

-- Job Order - This is the order jobs will appear in the menu
Config.JobOrder = {
    "police",
    "ambulance", 
    "lawyer",
    "mechanic",
    "taxi",
    "delivery"
}

-- Job Settings
Config.Jobs = {
    -- Whitelisted Jobs
    police = {
        label = "Police Officer",
        department = "LSPD",
        salary = "$5,000/week",
        location = "Mission Row Police Department",
        description = "Protect and serve the citizens of Los Santos. Maintain order and enforce the law.",
        requirements = {"Clean record", "Physical fitness", "Background check"},
        schedule = "Flexible shifts, 24/7 operation",
        benefits = {"Health insurance", "Pension plan", "Marked vehicle"},
        type = "whitelisted",
        icon = "👮",
        questions = {
            "Why do you want to join the Police Department?",
            "What do you believe makes a good police officer?",
            "Describe a situation where you had to resolve a conflict.",
            "What is your experience with firearms or self-defense?",
            "How would you handle a situation with an armed suspect?"
        },
        grade = 0, -- Starting grade when accepted
        minReviewGrade = 4 -- Minimum grade required to review applications
    },
    ambulance = {
        label = "Paramedic",
        department = "EMS",
        salary = "$4,500/week",
        location = "Pillbox Medical Center",
        description = "Provide emergency medical care to citizens in critical condition.",
        requirements = {"Medical certification", "Clean record", "Background check"},
        schedule = "Rotating shifts, 24/7 operation",
        benefits = {"Health insurance", "Pension plan", "Emergency vehicle"},
        type = "whitelisted",
        icon = "🚑",
        questions = {
            "Why do you want to become a paramedic?",
            "Describe your experience with emergency medicine.",
            "How would you handle a multi-casualty incident?",
            "What skills do you have that would benefit the EMS team?",
            "How do you handle high-stress situations?"
        },
        grade = 0,
        minReviewGrade = 4
    },
    lawyer = {
        label = "Lawyer",
        department = "Legal Services",
        salary = "$6,000/week",
        location = "Los Santos Courthouse",
        description = "Provide legal representation and advice to citizens of Los Santos.",
        requirements = {"Legal knowledge", "Professional appearance"},
        schedule = "10:00 AM - 6:00 PM",
        benefits = {"Private office", "Professional network"},
        type = "whitelisted",
        icon = "⚖️",
        questions = {
            "Why did you choose to pursue a career in law?",
            "What areas of law are you most interested in?",
            "How would you handle an ethically challenging case?",
            "Describe your experience with legal documentation.",
            "How would you explain complex legal concepts to clients?"
        },
        grade = 0,
        minReviewGrade = 4
    },
    
    -- Civilian Jobs
    mechanic = {
        label = "Mechanic",
        department = "Los Santos Customs",
        salary = "$3,500/week",
        location = "Los Santos Customs Workshop",
        description = "Repair and upgrade vehicles. Provide roadside assistance to citizens in need.",
        requirements = {"Technical knowledge", "Driver's license"},
        schedule = "9:00 AM - 5:00 PM",
        benefits = {"Employee discounts", "Free vehicle repairs"},
        type = "civilian",
        icon = "🔧",
        grade = 0
    },
    taxi = {
        label = "Taxi Driver",
        department = "Downtown Cab Co.",
        salary = "$2,200/week + tips",
        location = "Downtown Cab Co. HQ",
        description = "Transport citizens around Los Santos safely and efficiently.",
        requirements = {"Driver's license", "Knowledge of the city"},
        schedule = "Flexible hours",
        benefits = {"Keep your tips", "Company vehicle"},
        type = "civilian",
        icon = "🚕",
        grade = 0
    },
    delivery = {
        label = "Delivery Driver",
        department = "GoPostal",
        salary = "$2,000/week",
        location = "Various locations around Los Santos",
        description = "Deliver packages to businesses and residents throughout San Andreas.",
        requirements = {"Driver's license", "Clean driving record"},
        schedule = "8:00 AM - 4:00 PM",
        benefits = {"Flexible hours", "Company vehicle"},
        type = "civilian",
        icon = "📦",
        grade = 0
    }
}

Config.NotificationTypes = {
    ['success'] = 'success',
    ['error'] = 'error',
    ['info'] = 'primary'
}
