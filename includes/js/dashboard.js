// async-dashboard.js

document.addEventListener('DOMContentLoaded', () => {
    loadUserData();
    loadSummaryCards();
    loadTasks();
    loadAIRecommendations();
    setupTaskSearch();
    setupNewTaskButton();
});

async function loadUserData() {
    try {
        const response = await fetch('/api/user-data');
        const userData = await response.json();
        document.getElementById('userName').textContent = userData.name;
    } catch (error) {
        console.error('Error al cargar datos del usuario:', error);
    }
}

async function loadSummaryCards() {
    try {
        const response = await fetch('/api/summary-data');
        const summaryData = await response.json();
        const summaryCardsContainer = document.getElementById('summaryCards');
        summaryCardsContainer.innerHTML = '';

        summaryData.forEach((item, index) => {
            const card = document.createElement('div');
            card.className = `card animate-slideInBottom`;
            card.style.animationDelay = `${index * 0.1}s`;
            card.innerHTML = `
                <h3>${item.title}</h3>
                <p class="big-number">${item.value}</p>
            `;
            summaryCardsContainer.appendChild(card);
        });
    } catch (error) {
        console.error('Error al cargar datos de resumen:', error);
    }
}

async function loadTasks() {
    try {
        const response = await fetch('/api/tasks');
        const tasks = await response.json();
        const taskList = document.getElementById('taskList');
        taskList.innerHTML = '';

        tasks.forEach(task => {
            const li = document.createElement('li');
            li.innerHTML = `
                <input type="checkbox" id="task${task.id}" ${task.completed ? 'checked' : ''}>
                <label for="task${task.id}">${task.title}</label>
                <span class="task-time">${task.time}</span>
            `;
            taskList.appendChild(li);
        });
    } catch (error) {
        console.error('Error al cargar tareas:', error);
    }
}

async function loadAIRecommendations() {
    try {
        const response = await fetch('/api/ai-recommendations');
        const recommendations = await response.json();
        const aiRecommendationsContainer = document.getElementById('aiRecommendations');
        aiRecommendationsContainer.innerHTML = '';

        recommendations.forEach(recommendation => {
            const card = document.createElement('div');
            card.className = 'recommendation-card';
            card.innerHTML = `<p>${recommendation.message}</p>`;
            aiRecommendationsContainer.appendChild(card);
        });
    } catch (error) {
        console.error('Error al cargar recomendaciones de IA:', error);
    }
}

function setupTaskSearch() {
    const searchInput = document.getElementById('taskSearch');
    searchInput.addEventListener('input', async (e) => {
        const searchTerm = e.target.value.toLowerCase();
        const taskList = document.getElementById('taskList');
        const tasks = taskList.getElementsByTagName('li');

        for (let task of tasks) {
            const taskText = task.textContent.toLowerCase();
            if (taskText.includes(searchTerm)) {
                task.style.display = '';
            } else {
                task.style.display = 'none';
            }
        }
    });
}

function setupNewTaskButton() {
    const newTaskBtn = document.getElementById('newTaskBtn');
    newTaskBtn.addEventListener('click', () => {
        // Aquí iría la lógica para abrir un modal o formulario para crear una nueva tarea
        alert('Funcionalidad para crear nueva tarea');
    });
}

// dashboard.js
document.addEventListener('DOMContentLoaded', () => {
    initializeCharts();
    setupModal();
    setupCalendar();
});

function initializeCharts() {
    // Gráfica de Eficiencia
    const efficiencyCtx = document.getElementById('efficiencyChart').getContext('2d');
    new Chart(efficiencyCtx, {
        type: 'doughnut',
        data: {
            datasets: [{
                data: [85, 15],
                backgroundColor: [
                    'var(--color-green)',
                    'var(--color-beige)'
                ]
            }]
        },
        options: {
            cutout: '80%',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });

    // Gráfica de Productividad
    const productivityCtx = document.getElementById('productivityChart').getContext('2d');
    new Chart(productivityCtx, {
        type: 'line',
        data: {
            labels: ['9AM', '10AM', '11AM', '12PM', '1PM', '2PM', '3PM', '4PM', '5PM'],
            datasets: [{
                label: 'Productividad',
                data: [65, 75, 85, 70, 60, 80, 90, 85, 80],
                borderColor: 'var(--color-green)',
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100
                }
            }
        }
    });
}

function setupModal() {
    const modal = document.getElementById('newTaskModal');
    const newTaskBtn = document.getElementById('newTaskBtn');
    const closeModal = document.querySelector('.close-modal');
    const cancelBtn = document.getElementById('cancelTask');
    const saveBtn = document.getElementById('saveTask');

    newTaskBtn.addEventListener('click', () => {
        modal.classList.add('active');
    });

    function closeModalHandler() {
        modal.classList.remove('active');
    }

    closeModal.addEventListener('click', closeModalHandler);
    cancelBtn.addEventListener('click', closeModalHandler);
    
    saveBtn.addEventListener('click', () => {
        // Aquí iría la lógica para guardar la tarea
        closeModalHandler();
    });

    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            closeModalHandler();
        }
    });
}

function setupCalendar() {
    const calendarGrid = document.getElementById('calendarGrid');
    const hours = Array.from({length: 12}, (_, i) => `${i + 9}:00`);
    
    let calendarHTML = '<div class="calendar-hours">';
    
    hours.forEach(hour => {
        calendarHTML += `
            <div class="hour-slot">
                <div class="hour-label">${hour}</div>
                <div class="hour-content"></div>
            </div>
        `;
    });
    
    calendarHTML += '</div>';
    calendarGrid.innerHTML = calendarHTML;
}

<>
document.addEventListener('DOMContentLoaded', function() {
    // Modal functionality
    const modal = document.getElementById('taskModal');
    const newTaskBtn = document.getElementById('newTaskBtn');
    const closeBtn = document.querySelector('.close-btn');
    const cancelBtn = document.getElementById('cancelBtn');
    
    ```javascript
    const cancelBtn = document.getElementById('cancelBtn');
    const saveBtn = document.getElementById('saveBtn');

    // Show modal
    newTaskBtn.addEventListener('click', () => {
        modal.classList.add('active');
    });

    // Hide modal
    const hideModal = () => {
        modal.classList.remove('active');
    };

    closeBtn.addEventListener('click', hideModal);
    cancelBtn.addEventListener('click', hideModal);
    modal.addEventListener('click', (e) => {
        if (e.target === modal) hideModal();
    });

    // Charts
    const efficiencyChart = new Chart(document.getElementById('efficiencyChart'), {
        type: 'doughnut',
        data: {
            datasets: [{
                data: [85, 15],
                backgroundColor: [
                    'var(--primary)',
                    'var(--border)'
                ],
                borderWidth: 0
            }]
        },
        options: {
            cutout: '80%',
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });

    const productivityChart = new Chart(document.getElementById('productivityChart'), {
        type: 'line',
        data: {
            labels: ['9AM', '10AM', '11AM', '12PM', '1PM', '2PM', '3PM', '4PM', '5PM'],
            datasets: [{
                label: 'Productividad',
                data: [65, 70, 85, 80, 75, 90, 85, 80, 88],
                borderColor: 'var(--primary)',
                tension: 0.4,
                fill: false
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100,
                    grid: {
                        display: false
                    }
                },
                x: {
                    grid: {
                        display: false
                    }
                }
            }
        }
    });

    // Form submission
    const taskForm = document.getElementById('taskForm');
    saveBtn.addEventListener('click', (e) => {
        e.preventDefault();
        if (taskForm.checkValidity()) {
            // Here you would typically send the data to your backend
            hideModal();
            taskForm.reset();
        } else {
            taskForm.reportValidity();
        }
    });
});
