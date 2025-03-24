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