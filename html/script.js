// Main variables
let jobsData = {};
let jobOrder = [];
let citizenid = '';
let playerName = '';
let selectedJob = null;
let currentFilter = 'all';
let searchTerm = '';
let isOpen = false;

// UI Elements
const jobCenter = document.getElementById('job-center');
const jobList = document.getElementById('job-list');
const jobDetails = document.getElementById('job-details');
const welcomeScreen = document.getElementById('welcome-screen');
const applicationForm = document.getElementById('application-form');
const searchInput = document.getElementById('search-jobs');
const filterButtons = document.querySelectorAll('.filter-btn');
const closeDetailsBtn = document.getElementById('close-details');
const applyJobBtn = document.getElementById('apply-job-btn');
const backToDetailsBtn = document.getElementById('back-to-details');
const submitApplicationBtn = document.getElementById('submit-application');

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openJobCenter') {
        if (isOpen) return; // Prevent double opening
        
        jobsData = data.jobs;
        jobOrder = data.jobOrder;
        citizenid = data.citizenid;
        playerName = data.playerName;
        
        renderJobList();
        jobCenter.classList.remove('hidden');
        isOpen = true;
        
        // Always ensure welcome screen is shown and job details are hidden
        jobDetails.classList.add('hidden');
        welcomeScreen.classList.remove('hidden');
        selectedJob = null;
        
        // Clear any selected class from job items
        const jobItems = document.querySelectorAll('.job-item');
        jobItems.forEach(item => item.classList.remove('selected'));
    } else if (data.action === 'closeJobCenter') {
        closeJobCenter(false); // Don't send callback to server from here
    }
});

// Event Listeners
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeJobCenter(true);
    }
});

searchInput.addEventListener('input', function() {
    searchTerm = this.value.toLowerCase();
    renderJobList();
});

filterButtons.forEach(button => {
    button.addEventListener('click', function() {
        currentFilter = this.dataset.filter;
        
        // Update active filter button
        filterButtons.forEach(btn => btn.classList.remove('active'));
        this.classList.add('active');
        
        renderJobList();
    });
});

closeDetailsBtn.addEventListener('click', function() {
    hideJobDetails();
});

applyJobBtn.addEventListener('click', function() {
    if (!selectedJob) return;
    
    if (selectedJob.type === 'whitelisted') {
        showApplicationForm();
    } else {
        // For non-whitelisted jobs, take the job immediately
        sendNUIMessage({
            type: 'takeJob',
            job: selectedJob.id
        });
    }
});

backToDetailsBtn.addEventListener('click', function() {
    hideApplicationForm();
});

submitApplicationBtn.addEventListener('click', function() {
    if (!selectedJob) return;
    
    // Collect all answers from form
    const questions = document.querySelectorAll('.question-textarea');
    const answers = Array.from(questions).map(q => q.value.trim());
    
    // Validate that all questions are answered
    if (answers.some(a => a === '')) {
        // Show an error message
        alert('Please answer all questions before submitting.');
        return;
    }
    
    // Send application data to the server
    sendNUIMessage({
        type: 'applyForJob',
        job: selectedJob.id,
        answers: answers
    });
});

// Functions
function renderJobList() {
    jobList.innerHTML = '';
    
    // Use the job order from the config to ensure consistent ordering
    jobOrder.forEach(jobId => {
        const job = jobsData[jobId];
        
        // Skip if job doesn't exist in data
        if (!job) return;
        
        // Apply filtering
        if (currentFilter !== 'all' && job.type !== currentFilter) {
            return;
        }
        
        // Apply search
        if (searchTerm && !job.label.toLowerCase().includes(searchTerm)) {
            return;
        }
        
        const jobItem = document.createElement('div');
        jobItem.className = 'job-item';
        jobItem.dataset.jobId = jobId;
        
        // selected class if this is the currently selected job
        if (selectedJob && selectedJob.id === jobId) {
            jobItem.classList.add('selected');
        }
        
        jobItem.innerHTML = `
            <div class="job-item-icon">${job.icon}</div>
            <div class="job-item-info">
                <h3>${job.label}</h3>
                <p>${job.department}</p>
            </div>
            <div class="job-item-arrow">
                <i class="fas fa-chevron-right"></i>
            </div>
        `;
        
        jobItem.addEventListener('click', function() {
            // First hide application form if it's open
            if (!applicationForm.classList.contains('hidden')) {
                applicationForm.classList.add('hidden');
            }
            // Then show the job details
            showJobDetails(jobId);
        });
        
        jobList.appendChild(jobItem);
    });
}

function showJobDetails(jobId) {
    // Get job data
    selectedJob = {
        id: jobId,
        ...jobsData[jobId]
    };
    
    // Update job details UI
    document.getElementById('job-icon').innerHTML = selectedJob.icon;
    document.getElementById('job-title').textContent = selectedJob.label;
    document.getElementById('job-department').textContent = selectedJob.department;
    document.getElementById('job-salary').textContent = selectedJob.salary;
    document.getElementById('job-location').textContent = selectedJob.location;
    document.getElementById('job-schedule').textContent = selectedJob.schedule;
    document.getElementById('job-type').textContent = selectedJob.type.charAt(0).toUpperCase() + selectedJob.type.slice(1);
    document.getElementById('job-description').textContent = selectedJob.description;
    
    // Update requirements list
    const requirementsList = document.getElementById('job-requirements');
    requirementsList.innerHTML = '';
    selectedJob.requirements.forEach(req => {
        const li = document.createElement('li');
        li.textContent = req;
        requirementsList.appendChild(li);
    });
    
    // Update benefits list
    const benefitsList = document.getElementById('job-benefits');
    benefitsList.innerHTML = '';
    selectedJob.benefits.forEach(benefit => {
        const li = document.createElement('li');
        li.textContent = benefit;
        benefitsList.appendChild(li);
    });
    
    // Update selected item in job list
    const jobItems = document.querySelectorAll('.job-item');
    jobItems.forEach(item => {
        item.classList.remove('selected');
        if (item.dataset.jobId === jobId) {
            item.classList.add('selected');
        }
    });
    
    // Show job details
    welcomeScreen.classList.add('hidden');
    jobDetails.classList.remove('hidden');
    
    // Update apply button based on job type
    if (selectedJob.type === 'whitelisted') {
        applyJobBtn.innerHTML = '<i class="fas fa-file-alt"></i><span>Apply for this Position</span>';
    } else {
        applyJobBtn.innerHTML = '<i class="fas fa-briefcase"></i><span>Accept this Job</span>';
    }
}

function hideJobDetails() {
    jobDetails.classList.add('hidden');
    welcomeScreen.classList.remove('hidden');
    selectedJob = null;
    
    // Update selected items in job list
    const jobItems = document.querySelectorAll('.job-item');
    jobItems.forEach(item => item.classList.remove('selected'));
}

function showApplicationForm() {
    // Update application form title
    document.getElementById('application-job-title').textContent = selectedJob.label;
    
    // Generate questions
    const formQuestionsContainer = document.getElementById('form-questions');
    formQuestionsContainer.innerHTML = '';
    
    selectedJob.questions.forEach((question, index) => {
        const questionContainer = document.createElement('div');
        questionContainer.className = 'question-container';
        
        questionContainer.innerHTML = `
            <h4>Question ${index + 1}</h4>
            <p>${question}</p>
            <textarea class="question-textarea" placeholder="Your answer..." data-question-id="${index}"></textarea>
        `;
        
        formQuestionsContainer.appendChild(questionContainer);
    });
    
    // Show application form
    jobDetails.classList.add('hidden');
    applicationForm.classList.remove('hidden');
}

function hideApplicationForm() {
    applicationForm.classList.add('hidden');
    jobDetails.classList.remove('hidden');
}

function closeJobCenter(sendCallback = true) {
    // Clear state immediately
    isOpen = false;
    jobCenter.classList.add('hidden');
    hideJobDetails();
    hideApplicationForm();
    selectedJob = null;
    
    // Only send callback if requested (to avoid double callbacks)
    if (sendCallback) {
        fetch(`https://${GetParentResourceName()}/closeJobCenter`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
}

function sendNUIMessage(data) {
    fetch(`https://${GetParentResourceName()}/${data.type}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    });
}