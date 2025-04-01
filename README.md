![image](https://github.com/user-attachments/assets/b905b5ca-0f98-4f2a-9516-3eb9c0e50dfb)# DW Job Center

A comprehensive job management system for QBCore Base FiveM servers with application processing and review functionality.
![image](https://github.com/user-attachments/assets/ab890beb-f1cd-427e-b922-347087d534c4)

## Features

- Modern UI for job browsing and applications
- Support for both civilian and whitelisted jobs
- Application system with customizable questions
- Application review system for job managers
- Fully configurable job details (salary, requirements, benefits, etc.)
- Support for qb-target and ox_target systems

## Dependencies

- QBCore Framework
- oxmysql or mysql-async
- qb-target or ox_target (optional but recommended)

## Installation

### 1. Import SQL Table

Run the following SQL query in your database to create the necessary table:

```sql
CREATE TABLE IF NOT EXISTS `job_applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `job` varchar(50) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `answers` longtext DEFAULT NULL,
  `status` varchar(50) DEFAULT 'pending',
  `date_submitted` varchar(50) DEFAULT NULL,
  `reviewer_id` varchar(50) DEFAULT NULL,
  `date_reviewed` varchar(50) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2. Install the Resource

1. Download the resource files
2. Place the `dw-jobcenter` folder in your server's resources directory
3. Add `ensure dw-jobcenter` to your server.cfg file (after qb-core and other dependencies)

### 3. Configure the Script

1. Open `config.lua` to customize the job center to your liking
2. Setup your target system
```lua
Config.TargetSystem = 'qb' -- Options: 'qb' for qb-target, 'ox' for ox_target
```
3. Swhich yo dw-bossmenu if you are using the script for best experience
```lua
Config.ApplicationSystem = 'dw-bossmenu' -- Options: 'internal' for built-in system, 'dw-bossmenu' for external dw-bossmenu
```
4. Configure jobs, locations, and other settings

```lua
-- Example of adding a custom job
Config.Jobs["yourjob"] = {
    label = "Your Job Title",
    department = "Department Name",
    salary = "$X,XXX/week",
    location = "Job Location",
    description = "Job description text",
    requirements = {"Requirement 1", "Requirement 2"},
    schedule = "Work schedule",
    benefits = {"Benefit 1", "Benefit 2"},
    type = "whitelisted", -- or "civilian" for instant jobs
    icon = "🔧", -- Job icon in the UI
    questions = { -- Only needed for whitelisted jobs
        "Application question 1?",
        "Application question 2?",
    },
    grade = 0, -- Starting grade when accepted
    minReviewGrade = 4 -- Minimum grade required to review applications
}

-- Add job to job order to display in menu
table.insert(Config.JobOrder, "yourjob")
```

### 4. Set Up Review Locations (Optional)

If you want job managers to review applications at specific locations:

```lua
Config.ReviewLocations["yourjob"] = {
    pos = vector3(x, y, z),
    label = "Review Your Job Applications"
}
```

## Usage

### For Players

1. Visit the Job Center location
2. Browse available jobs
3. Apply for whitelisted jobs by answering questions
4. Take civilian jobs instantly

### For Job Managers

1. Visit the review location for your job
2. Review pending applications
3. Accept or reject applications with optional notes

## Troubleshooting

- If the UI doesn't appear, ensure your NUI is working correctly and check the browser console for errors
- If applications aren't being saved, check your database connection and table structure
- For other issues, check the server console for error messages

## Support

For support, questions, or feature requests, please join our Discord server - https://discord.gg/7Ds8V64fk8.

## License

This resource is licensed under the MIT License. See the LICENSE file for details.

## Images
![image](https://github.com/user-attachments/assets/8bcf054c-329d-4913-9f92-91ae9e34200c)
![image](https://github.com/user-attachments/assets/1c6a2eba-7c54-4cb7-8b52-8d91fad3c53c)
![image](https://github.com/user-attachments/assets/575e119d-9380-497b-856c-bea73bced49d)
https://cdn.discordapp.com/attachments/1154065692660862996/1356742996284014662/image.png?ex=67edace1&is=67ec5b61&hm=3a0e250c400bba4514c187fa0f939f7e0f541903221819d23cc1b4362a5c561c& - Using dw-bossmenu
