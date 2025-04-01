// Application Review variables
let applications = [];
let currentApplication = null;
let viewingApplicationDetails = false;

// UI Elements for review
const reviewMenu = document.createElement('div');
reviewMenu.id = 'review-menu';
reviewMenu.className = 'hidden';
document.body.appendChild(reviewMenu);

// Initialize Review Menu HTML
reviewMenu.innerHTML = `
<div class="review-container">
    <div class="review-header">
        <h1 id="review-title">Application Review</h1>
        <button id="close-review" class="close-btn">
            <i class="fas fa-times"></i>
        </button>
    </div>
    
    <div id="applications-list-view">
        <div class="review-info">
            <p>Select an application to review. You can accept or reject applications after reviewing the details.</p>
        </div>
        
        <div class="applications-list" id="applications-list"></div>
    </div>
    
    <div id="application-details-view" class="hidden">
        <button id="back-to-applications" class="back-btn">
            <i class="fas fa-arrow-left"></i> Back to Applications
        </button>
        
        <div class="application-header">
            <h2 id="applicant-name"></h2>
            <p id="application-date"></p>
        </div>
        
        <div id="application-answers"></div>
        
        <div class="review-actions">
            <div class="notes-container">
                <h3>Review Notes</h3>
                <textarea id="review-notes" placeholder="Add optional notes about this application..."></textarea>
            </div>
            
            <div class="action-buttons">
                <button id="reject-application" class="action-btn reject-btn">
                    <i class="fas fa-times-circle"></i>
                    <span>Reject Application</span>
                </button>
                <button id="accept-application" class="action-btn accept-btn">
                    <i class="fas fa-check-circle"></i>
                    <span>Accept Application</span>
                </button>
            </div>
        </div>
    </div>
</div>
`;

//  Review Menu Styles
const reviewStyles = document.createElement('style');
reviewStyles.textContent = `
#review-menu {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.6);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
}

.review-container {
    width: 1000px;
    height: 700px;
    background-color: #1e2130;
    border-radius: 12px;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

.review-header {
    padding: 24px;
    border-bottom: 1px solid #2a2d3e;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.review-header h1 {
    font-size: 24px;
    font-weight: 600;
    color: #4d9bff;
    margin: 0;
}

#applications-list-view, #application-details-view {
    flex: 1;
    overflow-y: auto;
    padding: 24px;
}

.review-info {
    margin-bottom: 20px;
    padding: 12px;
    background-color: #252836;
    border-radius: 8px;
    color: #a1a3af;
}

.applications-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.application-item {
    padding: 16px;
    background-color: #252836;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    justify-content: space-between;
    transition: all 0.2s ease;
}

.application-item:hover {
    background-color: #2a2e40;
}

.application-info h3 {
    font-size: 16px;
    font-weight: 500;
    color: #fff;
    margin: 0 0 4px 0;
}

.application-info p {
    font-size: 14px;
    color: #a1a3af;
    margin: 0;
}

.application-date {
    font-size: 12px;
    color: #6c7183;
    align-self: flex-start;
}

.back-btn {
    background: none;
    border: none;
    color: #4d9bff;
    font-size: 14px;
    cursor: pointer;
    display: flex;
    align-items: center;
    margin-bottom: 24px;
}

.back-btn i {
    margin-right: 8px;
}

.application-header {
    margin-bottom: 24px;
}

.application-header h2 {
    font-size: 24px;
    font-weight: 600;
    color: #fff;
    margin: 0 0 8px 0;
}

.application-header p {
    font-size: 14px;
    color: #a1a3af;
    margin: 0;
}

#application-answers {
    margin-bottom: 32px;
}

.answer-container {
    margin-bottom: 24px;
    background-color: #252836;
    padding: 16px;
    border-radius: 8px;
}

.answer-container h4 {
    font-size: 16px;
    font-weight: 500;
    color: #fff;
    margin: 0 0 12px 0;
}

.answer-container p {
    font-size: 14px;
    color: #fff;
    margin: 0 0 8px 0;
}

.answer-container .answer {
    padding: 12px;
    background-color: #1e2130;
    border-radius: 6px;
    color: #a1a3af;
    line-height: 1.5;
}

.notes-container {
    margin-bottom: 20px;
}

.notes-container h3 {
    font-size: 16px;
    font-weight: 500;
    color: #fff;
    margin: 0 0 12px 0;
}

#review-notes {
    width: 100%;
    height: 100px;
    padding: 12px;
    background-color: #252836;
    border: 1px solid #2a2d3e;
    border-radius: 8px;
    color: #fff;
    font-size: 14px;
    resize: none;
    outline: none;
}

.action-buttons {
    display: flex;
    gap: 16px;
}

.action-btn {
    flex: 1;
    padding: 14px;
    color: #fff;
    border: none;
    border-radius: 8px;
    font-size: 16px;
    font-weight: 500;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background-color 0.2s ease;
}

.action-btn i {
    margin-right: 12px;
    font-size: 18px;
}

.reject-btn {
    background-color: #e53935;
}

.reject-btn:hover {
    background-color: #c62828;
}

.accept-btn {
    background-color: #43a047;
}

.accept-btn:hover {
    background-color: #2e7d32;
}
`;

document.head.appendChild(reviewStyles);

//  event listeners for review menu
document.getElementById('close-review').addEventListener('click', function() {
    closeReviewMenu(true);
});

//  global escape key handler
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && !reviewMenu.classList.contains('hidden')) {
        console.log('ESC pressed, closing review menu');
        closeReviewMenu(true);
    }
});

document.getElementById('back-to-applications').addEventListener('click', function() {
    hideApplicationDetails();
});

document.getElementById('accept-application').addEventListener('click', function() {
    if (!currentApplication) return;
    
    const notes = document.getElementById('review-notes').value;
    sendReviewDecision('accept', notes);
});

document.getElementById('reject-application').addEventListener('click', function() {
    if (!currentApplication) return;
    
    const notes = document.getElementById('review-notes').value;
    sendReviewDecision('reject', notes);
});

// Review Menu Functions
function renderApplicationsList() {
    const listContainer = document.getElementById('applications-list');
    listContainer.innerHTML = '';
    
    if (applications.length === 0) {
        listContainer.innerHTML = '<div class="no-applications">No pending applications to review.</div>';
        return;
    }
    
    applications.forEach(app => {
        const appItem = document.createElement('div');
        appItem.className = 'application-item';
        appItem.dataset.id = app.id;
        
        // Default values for missing data
        const name = app.name || "Unknown Applicant";
        const citizenid = app.citizenid || "Unknown";
        const dateSubmitted = app.date_submitted || "No submission date";
        
        console.log(`Application ${app.id}: Date = "${dateSubmitted}"`);
        
        appItem.innerHTML = `
            <div class="application-info">
                <h3>${name}</h3>
                <p>Citizen ID: ${citizenid}</p>
            </div>
            <div class="application-date">
                ${dateSubmitted}
            </div>
        `;
        
        appItem.addEventListener('click', function() {
            showApplicationDetails(app);
        });
        
        listContainer.appendChild(appItem);
    });
}

function showApplicationDetails(application) {
    currentApplication = application;
    
    // Update UI
    document.getElementById('applicant-name').textContent = application.name;
    document.getElementById('application-date').textContent = `Applied on: ${application.date_submitted}`;
    
    // Render answers
    const answersContainer = document.getElementById('application-answers');
    answersContainer.innerHTML = '';
    
    if (application.answers && application.answers.length > 0) {
        application.answers.forEach((qa, index) => {
            const answerContainer = document.createElement('div');
            answerContainer.className = 'answer-container';
            
            answerContainer.innerHTML = `
                <h4>Question ${index + 1}</h4>
                <p>${qa.question}</p>
                <div class="answer">${qa.answer}</div>
            `;
            
            answersContainer.appendChild(answerContainer);
        });
    } else {
        answersContainer.innerHTML = '<div class="no-answers">No answers provided.</div>';
    }
    
    // Reset notes
    document.getElementById('review-notes').value = '';
    
    // Show details view
    document.getElementById('applications-list-view').classList.add('hidden');
    document.getElementById('application-details-view').classList.remove('hidden');
    viewingApplicationDetails = true;
}

function hideApplicationDetails() {
    document.getElementById('application-details-view').classList.add('hidden');
    document.getElementById('applications-list-view').classList.remove('hidden');
    currentApplication = null;
    viewingApplicationDetails = false;
}

function sendReviewDecision(action, notes) {
    fetch(`https://${GetParentResourceName()}/reviewApplication`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            id: currentApplication.id,
            action: action,
            notes: notes
        })
    });
    
    // Remove this application from the list
    applications = applications.filter(app => app.id !== currentApplication.id);
    
    // Go back to list view
    hideApplicationDetails();
    
    // Re-render the list
    renderApplicationsList();
    
    // If no more applications, close the menu
    if (applications.length === 0) {
        setTimeout(() => {
            closeReviewMenu();
        }, 1500);
    }
}

function openReviewMenu(data) {
    applications = data.applications;
    document.getElementById('review-title').textContent = `${data.jobLabel} Applications`;
    
    // Show the menu
    reviewMenu.classList.remove('hidden');
    
    // Reset views
    hideApplicationDetails();
    
    // Render applications list
    renderApplicationsList();
}

function closeReviewMenu(sendCallback = true) {
    reviewMenu.classList.add('hidden');
    applications = [];
    currentApplication = null;
    
    if (sendCallback) {
        console.log('Sending closeReviewMenu callback to server');
        fetch(`https://${GetParentResourceName()}/closeReviewMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
}

//  Review Menu Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openReviewMenu') {
        openReviewMenu(data);
    } else if (data.action === 'closeReviewMenu') {
        closeReviewMenu();
    }
});