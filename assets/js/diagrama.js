
// Datos de ejemplo (en una aplicación real, estos datos vendrían de una base de datos)
let tasks = [
    { id: 1, name: "Completar informe de proyecto", dueDate: "2025-03-15", category: "Trabajo", urgent: true, important: true },
    { id: 2, name: "Preparar presentación para cliente", dueDate: "2025-03-20", category: "Trabajo", urgent: true, important: true },
    { id: 3, name: "Actualizar CV", dueDate: "2025-04-01", category: "Personal", urgent: false, important: true },
    { id: 4, name: "Responder emails pendientes", dueDate: "2025-03-12", category: "Trabajo", urgent: true, important: false },
    { id: 5, name: "Leer libro nuevo", dueDate: "2025-05-01", category: "Personal", urgent: false, important: false },
    { id: 6, name: "Planificar vacaciones", dueDate: "2025-06-01", category: "Personal", urgent: false, important: true },
    { id: 7, name: "Reunión de equipo semanal", dueDate: "2025-03-14", category: "Trabajo", urgent: true, important: false },
    { id: 8, name: "Hacer ejercicio", dueDate: "2025-03-13", category: "Salud", urgent: false, important: true },
];

function renderTasks() {
    const allTasksList = document.getElementById('allTasks');
    const urgentImportantList = document.getElementById('urgentImportant');
    const importantNotUrgentList = document.getElementById('importantNotUrgent');
    const urgentNotImportantList = document.getElementById('urgentNotImportant');
    const notUrgentNotImportantList = document.getElementById('notUrgentNotImportant');

    allTasksList.innerHTML = '';
    urgentImportantList.innerHTML = '<h3>Urgente e Importante</h3>';
    importantNotUrgentList.innerHTML = '<h3>Importante, No Urgente</h3>';
    urgentNotImportantList.innerHTML = '<h3>Urgente, No Importante</h3>';
    notUrgentNotImportantList.innerHTML = '<h3>Ni Urgente Ni Importante</h3>';

    tasks.forEach((task, index) => {
        const li = createTaskElement(task);
        const matrixTask = createMatrixTaskElement(task);
        
        // Añadir con un pequeño retraso para crear efecto de cascada
        setTimeout(() => {
            allTasksList.appendChild(li);
            li.classList.add('show');
        }, index * 100);

        // Clasificar en la matriz de Eisenhower
        if (task.urgent && task.important) {
            urgentImportantList.appendChild(matrixTask);
        } else if (task.important) {
            importantNotUrgentList.appendChild(matrixTask);
        } else if (task.urgent) {
            urgentNotImportantList.appendChild(matrixTask);
        } else {
            notUrgentNotImportantList.appendChild(matrixTask);
        }
    });
}

function createTaskElement(task) {
    const li = document.createElement('li');
    li.className = 'task-item';
    if (task.urgent && task.important) {
        li.classList.add('urgent-important', 'pulse');
    } else if (task.urgent) {
        li.classList.add('urgent');
    } else if (task.important) {
        li.classList.add('important');
    }

    li.innerHTML = `
        <div class="task-info">
            <strong>${task.name}</strong>
            <br>
            <small>Vence: ${task.dueDate} | Categoría: ${task.category}</small>
        </div>
        <div class="task-actions">
            <button class="btn btn-secondary" onclick="toggleUrgent(${task.id})">
                ${task.urgent ? 'No Urgente' : 'Urgente'}
            </button>
            <button class="btn btn-secondary" onclick="toggleImportant(${task.id})">
                ${task.important ? 'No Importante' : 'Importante'}
            </button>
        </div>
    `;
    return li;
}

function createMatrixTaskElement(task) {
    const div = document.createElement('div');
    div.className = 'matrix-task';
    div.draggable = true;
    div.id = `matrix-task-${task.id}`;
    div.setAttribute('ondragstart', `drag(event, ${task.id})`);
    div.innerHTML = `
        <strong>${task.name}</strong>
        <br>
        <small>${task.dueDate}</small>
    `;
    return div;
}

function toggleUrgent(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (task) {
        task.urgent = !task.urgent;
        renderTasks();
    }
}

function toggleImportant(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (task) {
        task.important = !task.important;
        renderTasks();
    }
}

function autoPrioritize() {
    const today = new Date();
    const oneWeek = 7 * 24 * 60 * 60 * 1000; // Una semana en milisegundos

    tasks.forEach(task => {
        const dueDate = new Date(task.dueDate);
        const timeDiff = dueDate.getTime() - today.getTime();

        // Marcar como urgente si la fecha de vencimiento es en menos de una semana
        task.urgent = timeDiff <= oneWeek;

        // Marcar como importante basado en la categoría (ejemplo simple)
        task.important = task.category === 'Trabajo' || task.category === 'Salud';
    });

    renderTasks();
}

function allowDrop(ev) {
    ev.preventDefault();
    ev.target.closest('.matrix-quadrant').classList.add('drag-over');
}

function drag(ev, taskId) {
    ev.dataTransfer.setData("text", taskId);
}

function drop(ev, quadrant) {
    ev.preventDefault();
    const taskId = parseInt(ev.dataTransfer.getData("text"));
    const task = tasks.find(t => t.id === taskId);
    
    if (task) {
        switch(quadrant) {
            case 'urgentImportant':
                task.urgent = true;
                task.important = true;
                break;
            case 'importantNotUrgent':
                task.urgent = false;
                task.important = true;
                break;
            case 'urgentNotImportant':
                task.urgent = true;
                task.important = false;
                break;
            case 'notUrgentNotImportant':
                task.urgent = false;
                task.important = false;
                break;
        }
        renderTasks();
    }

    ev.target.closest('.matrix-quadrant').classList.remove('drag-over');
}

document.getElementById('autoPrioritizeBtn').addEventListener('click', autoPrioritize);

// Inicializar la página
renderTasks();
