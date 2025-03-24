
// Datos de tareas
let dailyTasks = [];
let goalTasks = [];
let selectedDailyTaskId = null;
let selectedGoalTaskId = null;

// Técnicas
const techniques = {
    pomodoro: {
        name: "Técnica Pomodoro",
        description: "Divide tu tiempo en intervalos de 25 minutos de trabajo intenso, seguidos de 5 minutos de descanso.",
        workTime: 25,
        breakTime: 5,
        longBreakTime: 15,
        steps: [
            { icon: "fas fa-list", text: "Decide qué tareas vas a realizar" },
            { icon: "fas fa-mobile-alt", text: "Elimina distracciones" },
            { icon: "fas fa-clock", text: "Trabaja 25 minutos" },
            { icon: "fas fa-coffee", text: "Descansa 5 minutos" },
            { icon: "fas fa-redo", text: "Repite 4 veces" },
            { icon: "fas fa-hourglass-end", text: "Toma un descanso largo" }
        ]
    },
    flowtime: {
        name: "Técnica Flowtime",
        description: "Trabaja según tu ritmo natural hasta que sientas que necesitas un descanso.",
        steps: [
            { icon: "fas fa-tasks", text: "Selecciona una tarea específica" },
            { icon: "fas fa-play", text: "Comienza a trabajar" },
            { icon: "fas fa-stopwatch", text: "Registra tu tiempo" },
            { icon: "fas fa-pause", text: "Descansa cuando lo necesites" },
            { icon: "fas fa-coffee", text: "Toma un descanso proporcional" },
            { icon: "fas fa-sync", text: "Repite el ciclo" }
        ]
    },
    timeboxing: {
        name: "Técnica Time Boxing",
        description: "Asigna bloques de tiempo específicos a tareas relacionadas con tus metas y objetivos.",
        steps: [
            { icon: "fas fa-list-ol", text: "Define tus metas y objetivos" },
            { icon: "fas fa-tasks", text: "Divide en tareas específicas" },
            { icon: "fas fa-clock", text: "Asigna bloques de tiempo" },
            { icon: "fas fa-check-double", text: "Completa cada bloque sin distracciones" }
        ]
    }
};

let currentTechnique = null;
let timer = null;
let timeLeft = 0;
let totalTime = 0;
let isBreak = false;

// Inicialización
document.addEventListener('DOMContentLoaded', function() {
    // Cargar tareas guardadas (en una aplicación real, esto vendría de una base de datos)
    loadSavedTasks();
    
    // Manejar la selección de opciones
    const options = document.querySelectorAll('.option');
    
    options.forEach(option => {
        const radio = option.querySelector('input[type="radio"]');
        const label = option.querySelector('label');

        // Manejar clic en la opción completa
        option.addEventListener('click', () => {
            radio.checked = true;
            updateSelectedState();
        });

        // Manejar clic en el label
        label.addEventListener('click', (e) => {
            e.preventDefault(); // Prevenir comportamiento predeterminado
            radio.checked = true;
            updateSelectedState();
        });

        // Manejar cambio en el radio button
        radio.addEventListener('change', () => {
            updateSelectedState();
        });
    });

    // Configurar eventos para los botones del temporizador
    document.getElementById('startTimer').addEventListener('click', startTimerSession);
    document.getElementById('pauseTimer').addEventListener('click', pauseTimer);
    document.getElementById('resumeTimer').addEventListener('click', resumeTimer);
    document.getElementById('completeTaskBtn').addEventListener('click', completeCurrentTask);
    document.getElementById('cancelTimer').addEventListener('click', cancelTimer);
});

function updateSelectedState() {
    const options = document.querySelectorAll('.option');
    options.forEach(opt => {
        const radio = opt.querySelector('input[type="radio"]');
        if (radio.checked) {
            opt.classList.add('selected');
        } else {
            opt.classList.remove('selected');
        }
    });
}

// Cargar tareas guardadas (simulado)
function loadSavedTasks() {
    // En una aplicación real, estas tareas vendrían de localStorage o una base de datos
    dailyTasks = [
        { id: 1, name: "Responder emails", completed: false },
        { id: 2, name: "Preparar informe semanal", completed: false },
        { id: 3, name: "Reunión de equipo", completed: false }
    ];
    
    goalTasks = [
        { id: 1, name: "Aprender un nuevo idioma", completed: false },
        { id: 2, name: "Completar curso de programación", completed: false },
        { id: 3, name: "Proyecto personal de desarrollo web", completed: false }
    ];
    
    renderDailyTasks();
    renderGoalTasks();
}

// Navegación entre secciones
function selectTaskType(type) {
    hideAllSections();
    
    if (type === 'daily') {
        document.getElementById('dailyTasksSection').style.display = 'block';
    } else if (type === 'goals') {
        document.getElementById('goalsTasksSection').style.display = 'block';
    }
}

function backToMainMenu() {
    hideAllSections();
    document.getElementById('taskTypeSelection').style.display = 'flex';
}

function backToDailyTasks() {
    hideAllSections();
    document.getElementById('dailyTasksSection').style.display = 'block';
}

function backToGoalTasks() {
    hideAllSections();
    document.getElementById('goalsTasksSection').style.display = 'block';
}

function hideAllSections() {
    document.getElementById('taskTypeSelection').style.display = 'none';
    document.getElementById('dailyTasksSection').style.display = 'none';
    document.getElementById('goalsTasksSection').style.display = 'none';
    document.getElementById('questionnaire').style.display = 'none';
    document.getElementById('timeboxing').style.display = 'none';
    document.getElementById('techniqueInfo').style.display = 'none';
    document.getElementById('techniqueInfo').classList.remove('active');
}

function showQuestionnaire() {
    hideAllSections();
    document.getElementById('questionnaire').style.display = 'block';
}

function showTimeBoxing() {
    hideAllSections();
    document.getElementById('timeboxing').style.display = 'block';
    renderGoalTaskSelection();
}

// Gestión de tareas diarias
function addDailyTask() {
    const taskInput = document.getElementById('dailyTaskInput');
    const taskName = taskInput.value.trim();
    
    if (taskName) {
        const newTask = {
            id: Date.now(),
            name: taskName,
            completed: false
        };
        
        dailyTasks.push(newTask);
        renderDailyTasks();
        taskInput.value = '';
    }
}

function renderDailyTasks() {
    const taskList = document.getElementById('dailyTaskList');
    taskList.innerHTML = '';
    
    if (dailyTasks.length === 0) {
        taskList.innerHTML = '<p>No hay tareas diarias. Agrega algunas para comenzar.</p>';
        return;
    }
    
    dailyTasks.forEach(task => {
        const taskItem = document.createElement('div');
        taskItem.className = `task-item ${task.completed ? 'completed' : ''}`;
        taskItem.innerHTML = `
            <div>
                <input type="checkbox" id="daily-${task.id}" ${task.completed ? 'checked' : ''} 
                    onchange="toggleDailyTaskCompletion(${task.id})">
                <label for="daily-${task.id}">${task.name}</label>
            </div>
            <div class="task-actions">
                <button class="btn btn-outline" onclick="selectDailyTask(${task.id})">Seleccionar</button>
                <button class="btn btn-outline" onclick="editDailyTask(${task.id})">Editar</button>
                <button class="btn btn-secondary" onclick="deleteDailyTask(${task.id})">Eliminar</button>
            </div>
        `;
        taskList.appendChild(taskItem);
    });
}

function toggleDailyTaskCompletion(taskId) {
    const task = dailyTasks.find(t => t.id === taskId);
    if (task) {
        task.completed = !task.completed;
        renderDailyTasks();
    }
}

function selectDailyTask(taskId) {
    selectedDailyTaskId = taskId;
    const task = dailyTasks.find(t => t.id === taskId);
    if (task) {
        showNotification(`Tarea seleccionada: ${task.name}`);
    }
}

function editDailyTask(taskId) {
    const task = dailyTasks.find(t => t.id === taskId);
    if (task) {
        document.getElementById('editDailyTaskInput').value = task.name;
        document.getElementById('editDailyTaskId').value = task.id;
        document.getElementById('dailyTaskEditForm').classList.add('active');
    }
}

function updateDailyTask() {
    const taskId = parseInt(document.getElementById('editDailyTaskId').value);
    const taskName = document.getElementById('editDailyTaskInput').value.trim();
    
    if (taskName) {
        const task = dailyTasks.find(t => t.id === taskId);
        if (task) {
            task.name = taskName;
            renderDailyTasks();
            cancelEditDailyTask();
        }
    }
}

function cancelEditDailyTask() {
    document.getElementById('dailyTaskEditForm').classList.remove('active');
}

function deleteDailyTask(taskId) {
    if (confirm('¿Estás seguro de que quieres eliminar esta tarea?')) {
        dailyTasks = dailyTasks.filter(t => t.id !== taskId);
        renderDailyTasks();
    }
}

// Gestión de metas y objetivos
function addGoalTask() {
    const taskInput = document.getElementById('goalTaskInput');
    const taskName = taskInput.value.trim();
    
    if (taskName) {
        const newTask = {
            id: Date.now(),
            name: taskName,
            completed: false
        };
        
        goalTasks.push(newTask);
        renderGoalTasks();
        taskInput.value = '';
    }
}

function renderGoalTasks() {
    const taskList = document.getElementById('goalTaskList');
    taskList.innerHTML = '';
    
    if (goalTasks.length === 0) {
        taskList.innerHTML = '<p>No hay metas u objetivos. Agrega algunos para comenzar.</p>';
        return;
    }
    
    goalTasks.forEach(task => {
        const taskItem = document.createElement('div');
        taskItem.className = `task-item ${task.completed ? 'completed' : ''}`;
        taskItem.innerHTML = `
            <div>
                <input type="checkbox" id="goal-${task.id}" ${task.completed ? 'checked' : ''} 
                    onchange="toggleGoalTaskCompletion(${task.id})">
                <label for="goal-${task.id}">${task.name}</label>
            </div>
            <div class="task-actions">
                <button class="btn btn-outline" onclick="selectGoalTask(${task.id})">Seleccionar</button>
                <button class="btn btn-outline" onclick="editGoalTask(${task.id})">Editar</button>
                <button class="btn btn-secondary" onclick="deleteGoalTask(${task.id})">Eliminar</button>
            </div>
        `;
        taskList.appendChild(taskItem);
    });
}

function renderGoalTaskSelection() {
    const taskList = document.getElementById('goalTaskSelection');
    taskList.innerHTML = '';
    
    if (goalTasks.length === 0) {
        taskList.innerHTML = '<p>No hay metas u objetivos. Vuelve atrás y agrega algunos para comenzar.</p>';
        return;
    }
    
    goalTasks.filter(task => !task.completed).forEach(task => {
        const taskItem = document.createElement('div');
        taskItem.className = 'task-item';
        taskItem.innerHTML = `
            <div>
                <label>${task.name}</label>
            </div>
            <button class="btn" onclick="selectGoalForTimeBoxing(${task.id})">Seleccionar</button>
        `;
        taskList.appendChild(taskItem);
    });
}

function toggleGoalTaskCompletion(taskId) {
    const task = goalTasks.find(t => t.id === taskId);
    if (task) {
        task.completed = !task.completed;
        renderGoalTasks();
    }
}

function selectGoalTask(taskId) {
    selectedGoalTaskId = taskId;
    const task = goalTasks.find(t => t.id === taskId);
    if (task) {
        showNotification(`Meta/Objetivo seleccionado: ${task.name}`);
    }
}

function selectGoalForTimeBoxing(taskId) {
    selectedGoalTaskId = taskId;
    const task = goalTasks.find(t => t.id === taskId);
    if (task) {
        document.getElementById('selectedGoalInfo').style.display = 'block';
        document.getElementById('selectedGoalName').textContent = task.name;
        document.getElementById('goalTaskSelection').style.display = 'none';
    }
}

function editGoalTask(taskId) {
    const task = goalTasks.find(t => t.id === taskId);
    if (task) {
        document.getElementById('editGoalTaskInput').value = task.name;
        document.getElementById('editGoalTaskId').value = task.id;
        document.getElementById('goalTaskEditForm').classList.add('active');
    }
}

function updateGoalTask() {
    const taskId = parseInt(document.getElementById('editGoalTaskId').value);
    const taskName = document.getElementById('editGoalTaskInput').value.trim();
    
    if (taskName) {
        const task = goalTasks.find(t => t.id === taskId);
        if (task) {
            task.name = taskName;
            renderGoalTasks();
            cancelEditGoalTask();
        }
    }
}

function cancelEditGoalTask() {
    document.getElementById('goalTaskEditForm').classList.remove('active');
}

function deleteGoalTask(taskId) {
    if (confirm('¿Estás seguro de que quieres eliminar esta meta/objetivo?')) {
        goalTasks = goalTasks.filter(t => t.id !== taskId);
        renderGoalTasks();
    }
}

// Análisis de técnica
function analyzeTechnique() {
    const timeStructure = document.querySelector('input[name="time_structure"]:checked')?.value;
    const interruptions = document.querySelector('input[name="interruptions"]:checked')?.value;
    const taskType = document.querySelector('input[name="task_type"]:checked')?.value;

    if (!timeStructure || !interruptions || !taskType) {
        // Crear una notificación más amigable
        showNotification('Por favor, responde todas las preguntas para continuar', 'warning');

        // Resaltar visualmente las preguntas sin responder
        document.querySelectorAll('.question').forEach(question => {
            const hasAnswer = question.querySelector('input[type="radio"]:checked');
            if (!hasAnswer) {
                question.style.animation = 'shake 0.5s ease-in-out';
                setTimeout(() => {
                    question.style.animation = '';
                }, 500);
            }
        });

        return;
    }

    // Determinar la técnica recomendada
    if ((timeStructure === 'fixed' && interruptions === 'scheduled') || 
        (taskType === 'focused' && interruptions === 'scheduled')) {
        showTechniqueInfo('pomodoro');
    } else {
        showTechniqueInfo('flowtime');
    }
}

function showTechniqueInfo(technique) {
    currentTechnique = techniques[technique];
    hideAllSections();
    const techniqueInfo = document.getElementById('techniqueInfo');
    
    // Verificar si hay una tarea seleccionada
    let selectedTaskInfo = '';
    if (selectedDailyTaskId) {
        const task = dailyTasks.find(t => t.id === selectedDailyTaskId);
        if (task) {
            selectedTaskInfo = `
                <div class="current-task-info">
                    <h3>Tarea seleccionada:</h3>
                    <p>${task.name}</p>
                </div>
            `;
        }
    } else {
        selectedTaskInfo = `
            <div class="current-task-info" style="background-color: var(--warning); color: var(--background);">
                <h3>No has seleccionado ninguna tarea</h3>
                <p>Vuelve a la lista de tareas y selecciona una antes de comenzar.</p>
            </div>
        `;
    }
    
    let stepsHTML = '<div class="technique-steps">';
    currentTechnique.steps.forEach(step => {
        stepsHTML += `
            <div class="technique-step">
                <i class="${step.icon}"></i>
                <p>${step.text}</p>
            </div>
        `;
    });
    stepsHTML += '</div>';

    techniqueInfo.innerHTML = `
        <div class="back-button" onclick="backToDailyTasks()">
            <i class="fas fa-arrow-left"></i> Volver a tareas diarias
        </div>
        <h2>${currentTechnique.name}</h2>
        <p>${currentTechnique.description}</p>
        ${stepsHTML}
        ${selectedTaskInfo}
        <button class="btn" onclick="startTechnique()" ${!selectedDailyTaskId ? 'disabled' : ''}>Comenzar</button>
    `;
    techniqueInfo.classList.add('active');
    techniqueInfo.style.display = 'block';
}

// Gestión de Time Boxing
function startTimeBoxing() {
    if (!selectedGoalTaskId) {
        showNotification('Por favor, selecciona una meta u objetivo primero', 'warning');
        return;
    }
    
    const duration = parseInt(document.getElementById('timeboxDuration').value);
    if (isNaN(duration) || duration < 5 || duration > 180) {
        showNotification('Por favor, ingresa una duración válida entre 5 y 180 minutos', 'warning');
        return;
    }
    
    currentTechnique = techniques.timeboxing;
    timeLeft = duration * 60;
    totalTime = timeLeft;
    
    const task = goalTasks.find(t => t.id === selectedGoalTaskId);
    document.getElementById('timerTitle').textContent = `Time Boxing: ${task.name}`;
    document.getElementById('currentTaskName').textContent = task.name;
    document.getElementById('timerModal').style.display = 'block';
    
    updateTimer();
}

// Funciones del temporizador
function startTechnique() {
    if (!selectedDailyTaskId) {
        showNotification('Por favor, selecciona una tarea primero', 'warning');
        return;
    }
    
    const task = dailyTasks.find(t => t.id === selectedDailyTaskId);
    document.getElementById('currentTaskName').textContent = task.name;
    document.getElementById('timerModal').style.display = 'block';
    
    if (currentTechnique.name === "Técnica Pomodoro") {
        startPomodoro();
    } else {
        startFlowtime();
    }
}

function startPomodoro() {
    isBreak = false;
    timeLeft = currentTechnique.workTime * 60;
    totalTime = timeLeft;
    updateTimer();
    document.getElementById('timerTitle').textContent = "Tiempo de trabajo";
    document.getElementById('completeTaskBtn').style.display = 'inline-block';
}

function startFlowtime() {
    timeLeft = 0;
    totalTime = 0;
    updateTimer(true);
    document.getElementById('timerTitle').textContent = "Tiempo de flujo";
    document.getElementById('completeTaskBtn').style.display = 'inline-block';
}

function updateTimer(counting_up = false) {
    const minutes = Math.floor(timeLeft / 60);
    const seconds = timeLeft % 60;
    document.getElementById('timerDisplay').textContent = 
        `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
    
    const progress = counting_up ? 
        (timeLeft / (60 * 60)) * 100 : // Máximo 1 hora para Flowtime
        ((totalTime - timeLeft) / totalTime) * 100;
    document.getElementById('progressFill').style.width = `${progress}%`;
}

function startTimerSession() {
    document.getElementById('startTimer').style.display = 'none';
    document.getElementById('pauseTimer').style.display = 'inline-block';
    
    if (!timer) {
        timer = setInterval(() => {
            if (currentTechnique.name === "Técnica Pomodoro") {
                timeLeft--;
                if (timeLeft <= 0) {
                    clearInterval(timer);
                    timer = null;
                    if (!isBreak) {
                        isBreak = true;
                        timeLeft = currentTechnique.breakTime * 60;
                        totalTime = timeLeft;
                        document.getElementById('timerTitle').textContent = "Tiempo de descanso";
                        showNotification("¡Tiempo de descanso!");
                        document.getElementById('startTimer').style.display = 'inline-block';
                        document.getElementById('pauseTimer').style.display = 'none';
                    } else {
                        completeSession();
                    }
                }
            } else if (currentTechnique.name === "Técnica Time Boxing") {
                timeLeft--;
                if (timeLeft <= 0) {
                    clearInterval(timer);
                    timer = null;
                    completeTimeBoxSession();
                }
            } else {
                timeLeft++;
                if (timeLeft >= 60 * 60) { // Límite de 1 hora para Flowtime
                    clearInterval(timer);
                    timer = null;
                    showNotification("Has estado trabajando por 1 hora. ¿Necesitas un descanso?");
                    document.getElementById('startTimer').style.display = 'inline-block';
                    document.getElementById('pauseTimer').style.display = 'none';
                }
            }
            updateTimer(currentTechnique.name === "Técnica Flowtime");
        }, 1000);
    }
}

function pauseTimer() {
    if (timer) {
        clearInterval(timer);
        timer = null;
        document.getElementById('pauseTimer').style.display = 'none';
        document.getElementById('resumeTimer').style.display = 'inline-block';
    }
}

function resumeTimer() {
    document.getElementById('resumeTimer').style.display = 'none';
    document.getElementById('pauseTimer').style.display = 'inline-block';
    startTimerSession();
}

function cancelTimer() {
    if (confirm("¿Estás seguro de que quieres cancelar la sesión?")) {
        if (timer) {
            clearInterval(timer);
            timer = null;
        }
        document.getElementById('timerModal').style.display = 'none';
        resetTimerControls();
    }
}

function resetTimerControls() {
    document.getElementById('startTimer').style.display = 'inline-block';
    document.getElementById('pauseTimer').style.display = 'none';
    document.getElementById('resumeTimer').style.display = 'none';
    document.getElementById('completeTaskBtn').style.display = 'none';
}

function completeSession() {
    if (confirm("¿Has completado la tarea?")) {
        completeCurrentTask();
    } else {
        document.getElementById('timerModal').style.display = 'none';
        resetTimerControls();
    }
}

function completeTimeBoxSession() {
    showNotification("¡Time Box completado!");
    if (confirm("¿Has avanzado en tu meta/objetivo? ¿Quieres marcarla como completada?")) {
        completeCurrentTask();
    } else {
        document.getElementById('timerModal').style.display = 'none';
        resetTimerControls();
        backToGoalTasks();
    }
}

function completeCurrentTask() {
    if (currentTechnique.name === "Técnica Time Boxing") {
        if (selectedGoalTaskId) {
            const task = goalTasks.find(t => t.id === selectedGoalTaskId);
            if (task) {
                task.completed = true;
                renderGoalTasks();
                showNotification(`¡Meta/Objetivo "${task.name}" completado!`);
            }
        }
        document.getElementById('timerModal').style.display = 'none';
        resetTimerControls();
        backToGoalTasks();
    } else {
        if (selectedDailyTaskId) {
            const task = dailyTasks.find(t => t.id === selectedDailyTaskId);
            if (task) {
                task.completed = true;
                renderDailyTasks();
                showNotification(`¡Tarea "${task.name}" completada!`);
            }
        }
        document.getElementById('timerModal').style.display = 'none';
        resetTimerControls();
        backToDailyTasks();
    }
}

// Funciones para la sección de consejos
function toggleTips() {
    const tipsContent = document.getElementById('tipsContent');
    const tipsHeader = document.querySelector('.tips-header');
    
    if (tipsContent.classList.contains('collapsed')) {
        tipsContent.classList.remove('collapsed');
        tipsHeader.classList.remove('collapsed');
    } else {
        tipsContent.classList.add('collapsed');
        tipsHeader.classList.add('collapsed');
    }
}

function showTechniqueInfo(tabId) {
    // Ocultar todos los contenidos de técnicas
    document.querySelectorAll('.technique-content').forEach(content => {
        content.classList.remove('active');
    });
    
    // Mostrar el contenido seleccionado
    document.getElementById(tabId).classList.add('active');
    
    // Actualizar las pestañas activas
    document.querySelectorAll('.technique-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Activar la pestaña seleccionada
    event.currentTarget.classList.add('active');
}

function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.style.position = 'fixed';
    notification.style.bottom = '20px';
    notification.style.right = '20px';
    notification.style.padding = '1rem';
    notification.style.backgroundColor = type === 'success' ? 'var(--primary)' : 'var(--warning)';
    notification.style.color = 'var(--background)';
    notification.style.borderRadius = '0.5rem';
    notification.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
    notification.style.animation = 'slideUp 0.3s ease-out';
    notification.style.zIndex = '2000';
    notification.textContent = message;

    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.animation = 'slideUp 0.3s ease-out reverse';
        setTimeout(() => document.body.removeChild(notification), 300);
    }, 3000);
}
