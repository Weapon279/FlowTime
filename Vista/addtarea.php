<?php
require_once '../Modelo/tareasadd.php';

?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tareas - Time Management Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600&family=Nunito:wght@300;400;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary: #A3C9A8;
            --primary-light: #BFD7EA;
            --secondary: #F5B7A5;
            --accent: #F4EAE0;
            --background: #FFFFFF;
            --surface: #F4EAE0;
            --text: #333333;
            --text-light: #6D8299;
            --border: #BFD7EA;
            --success: #A3C9A8;
            --warning: #F5B7A5;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Nunito', sans-serif;
            background-color: var(--background);
            color: var(--text);
            line-height: 1.5;
        }

        .dashboard {
            display: grid;
            grid-template-columns: 250px 1fr;
            min-height: 100vh;
        }

        .sidebar {
            background-color: var(--surface);
            padding: 1.5rem;
            border-right: 1px solid var(--border);
            animation: slideIn 0.5s ease-out;
        }

        @keyframes slideIn {
            from {
                transform: translateX(-100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            margin-bottom: 2rem;
        }

        .logo h1 {
            font-family: 'Poppins', sans-serif;
            font-size: 1.5rem;
            color: var(--primary);
        }

        .nav-links {
            list-style: none;
        }

        .nav-links li {
            margin-bottom: 0.5rem;
        }

        .nav-links a {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.75rem;
            text-decoration: none;
            color: var(--text);
            border-radius: 0.5rem;
            transition: all 0.3s ease;
        }

        .nav-links a:hover,
        .nav-links a.active {
            background-color: var(--primary);
            color: var(--background);
        }

        .main-content {
            padding: 2rem;
            animation: fadeIn 0.5s ease-out;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
            }
            to {
                opacity: 1;
            }
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
        }

        .search-container {
            display: flex;
            gap: 1rem;
        }

        .search-input {
            padding: 0.5rem 1rem;
            border: 1px solid var(--border);
            border-radius: 0.5rem;
            font-family: 'Nunito', sans-serif;
        }

        .btn {
            padding: 0.5rem 1rem;
            border: none;
            border-radius: 0.5rem;
            background-color: var(--primary);
            color: var(--background);
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }

        .btn:hover {
            background-color: var(--primary-light);
        }

        .task-list {
            display: grid;
            gap: 1rem;
        }

        .task-item {
            background-color: var(--surface);
            padding: 1rem;
            border-radius: 0.5rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            animation: slideUp 0.3s ease-out;
        }

        @keyframes slideUp {
            from {
                transform: translateY(20px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        .task-item.completed {
            opacity: 0.6;
        }

        .task-item.completed .task-title {
            text-decoration: line-through;
        }

        .task-actions {
            display: flex;
            gap: 0.5rem;
        }

        .task-actions button {
            background: none;
            border: none;
            cursor: pointer;
            font-size: 1rem;
            color: var(--text);
            transition: color 0.3s ease;
        }

        .task-actions button:hover {
            color: var(--primary);
        }

        .loading {
            text-align: center;
            padding: 2rem;
            font-size: 1.2rem;
            color: var(--text-light);
        }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
        }

        .modal-content {
            background-color: var(--background);
            margin: 15% auto;
            padding: 2rem;
            border-radius: 0.5rem;
            width: 80%;
            max-width: 500px;
            animation: modalSlideDown 0.3s ease-out;
        }

        @keyframes modalSlideDown {
            from {
                transform: translateY(-50px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        .close {
            color: var(--text-light);
            float: right;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }

        .close:hover,
        .close:focus {
            color: var(--text);
            text-decoration: none;
            cursor: pointer;
        }

        .form-group {
            margin-bottom: 1rem;
        }

        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
        }

        .form-group input,
        .form-group textarea,
        .form-group select {
            width: 100%;
            padding: 0.5rem;
            border: 1px solid var(--border);
            border-radius: 0.25rem;
            font-family: 'Nunito', sans-serif;
        }

        @media (max-width: 768px) {
            .dashboard {
                grid-template-columns: 1fr;
            }

            .sidebar {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="dashboard">
        <aside class="sidebar">
            <div class="logo">
                <i class="fas fa-clock fa-2x" style="color: var(--primary);"></i>
                <h1>TimeFlow</h1>
            </div>
            <nav>
                <ul class="nav-links">
                    <li><a href="dashboard.html"><i class="fas fa-home"></i> Dashboard</a></li>
                    <li><a href="addtarea.php" class="active"><i class="fas fa-tasks"></i> Tareas</a></li>
                    <li><a href="calendario.html"><i class="fas fa-calendar"></i> Calendario</a></li>
                    <li><a href="analisis.html"><i class="fas fa-chart-line"></i> Análisis</a></li>
                    <li><a href="configuracion.html"><i class="fas fa-cog"></i> Configuración</a></li>
                </ul>
            </nav>
        </aside>

        <main class="main-content">
            <header class="header">
                <h2>Tareas</h2>
                <div class="search-container">
                    <input type="text" id="searchInput" class="search-input" placeholder="Buscar tareas...">
                    <button id="searchBtn" class="btn">Buscar</button>
                    <button id="addTaskBtn" class="btn">Nueva Tarea</button>
                </div>
            </header>

            <div id="taskList" class="task-list">
                <!-- Tasks will be loaded here -->
            </div>

            <div id="loading" class="loading">Cargando tareas...</div>
        </main>
    </div>

    <div id="addTaskModal" class="modal">
        <div class="modal-content">
            <span class="close">&times;</span>
            <h2>Agregar Nueva Tarea</h2>
            <form id="addTaskForm">
                <div class="form-group">
                    <label for="taskTitle">Título de la Tarea</label>
                    <input type="text" id="taskTitle" required>
                </div>
                <div class="form-group">
                    <label for="taskDescription">Descripción</label>
                    <textarea id="taskDescription" rows="3"></textarea>
                </div>
                <div class="form-group">
                    <label for="taskDate">Fecha</label>
                    <input type="date" id="taskDate" required>
                </div>
                <div class="form-group">
                    <label for="taskType">Tipo</label>
                    <select id="taskType">
                        <option value="Trabajo">Trabajo</option>
                        <option value="Descanso">Descanso</option>
                        <option value="Ejercicio">Ejercicio</option>
                        <option value="Otro">Otro</option>
                    </select>
                </div>
                <button type="submit" class="btn">Agregar Tarea</button>
            </form>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const taskList = document.getElementById('taskList');
            const searchInput = document.getElementById('searchInput');
            const searchBtn = document.getElementById('searchBtn');
            const loading = document.getElementById('loading');
            const addTaskBtn = document.getElementById('addTaskBtn');
            const addTaskModal = document.getElementById('addTaskModal');
            const addTaskForm = document.getElementById('addTaskForm');
            const closeModal = addTaskModal.querySelector('.close');

            // Function to render tasks
            function renderTasks(tasksToRender) {
                taskList.innerHTML = '';
                tasksToRender.forEach(task => {
                    const taskElement = document.createElement('div');
                    taskElement.classList.add('task-item');
                    if (task.completed) {
                        taskElement.classList.add('completed');
                    }
                    taskElement.innerHTML = `
                        <span class="task-title">${task.title}</span>
                        <div class="task-info">
                            <span>${task.date}</span>
                            <span>${task.type}</span>
                        </div>
                        <div class="task-actions">
                            <button onclick="toggleTask(${task.id})">
                                <i class="fas ${task.completed ? 'fa-undo' : 'fa-check'}"></i>
                            </button>
                            <button onclick="deleteTask(${task.id})">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    `;
                    taskList.appendChild(taskElement);
                });
            }

            // Load tasks from the server
            function loadTasks() {
                loading.style.display = 'block';
                taskList.style.display = 'none';

                fetch('db_operations.php?action=get_tasks')
                    .then(response => response.json())
                    .then(data => {
                        loading.style.display = 'none';
                        taskList.style.display = 'grid';
                        renderTasks(data);
                    })
                    .catch(error => {
                        console.error('Error:', error);
                        loading.style.display = 'none';
                    });
            }

            // Search functionality
            function searchTasks() {
                const searchTerm = searchInput.value.toLowerCase();
                fetch(`db_operations.php?action=search_tasks&term=${searchTerm}`)
                    .then(response => response.json())
                    .then(data => {
                        renderTasks(data);
                    })
                    .catch(error => {
                        console.error('Error:', error);
                    });
            }

            // Toggle task completion status
            window.toggleTask = function(id) {
                fetch(`db_operations.php?action=toggle_task&id=${id}`, { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            loadTasks();
                        }
                    })
                    .catch(error => {
                        console.error('Error:', error);
                    });
            }

            // Delete task
            window.deleteTask = function(id) {
                fetch(`db_operations.php?action=delete_task&id=${id}`, { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            loadTasks();
                        }
                    })
                    .catch(error => {
                        console.error('Error:', error);
                    });
            }

            // Event listeners
            searchBtn.addEventListener('click', searchTasks);
            searchInput.addEventListener('keyup', function(event) {
                if (event.key === 'Enter') {
                    searchTasks();
                }
            });

            addTaskBtn.addEventListener('click', function() {
                addTaskModal.style.display = 'block';
            });

            closeModal.addEventListener('click', function() {
                addTaskModal.style.display = 'none';
            });

            window.addEventListener('click', function(event) {
                if (event.target == addTaskModal) {
                    addTaskModal.style.display = 'none';
                }
            });

            addTaskForm.addEventListener('submit', function(e) {
                e.preventDefault();
                const title = document.getElementById('taskTitle').value;
                const description = document.getElementById('taskDescription').value;
                const date = document.getElementById('taskDate').value;
                const type = document.getElementById('taskType').value;

                const formData = new FormData();
                formData.append('title', title);
                formData.append('description', description);
                formData.append('date', date);
                formData.append('type', type);

                fetch('db_operations.php?action=add_task', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        addTaskModal.style.display = 'none';
                        addTaskForm.reset();
                        loadTasks();
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                });
            });

            // Initial load
            loadTasks();
        });
    </script>
</body>
</html>