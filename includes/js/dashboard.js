        // Datos de ejemplo (en una aplicación real, estos datos vendrían de una base de datos)
        const taskData = {
            completed: 15,
            pending: 8,
            categories: {
                'Trabajo': 10,
                'Personal': 5,
                'Estudio': 4,
                'Salud': 4
            },
            progress: [
                {name: 'Lunes', value: 4},
                {name: 'Martes', value: 3},
                {name: 'Miércoles', value: 5},
                {name: 'Jueves', value: 2},
                {name: 'Viernes', value: 1},
                {name: 'Sábado', value: 0},
                {name: 'Domingo', value: 0}
            ]
        };

        // Actualizar KPIs
        document.getElementById('completedTasks').textContent = taskData.completed;
        document.getElementById('pendingTasks').textContent = taskData.pending;
        document.getElementById('productivity').textContent = 
            Math.round((taskData.completed / (taskData.completed + taskData.pending)) * 100) + '%';

        // Gráfico de progreso de tareas
        Highcharts.chart('taskProgressChart', {
            chart: {
                type: 'column'
            },
            title: {
                text: 'Progreso de Tareas por Día'
            },
            xAxis: {
                categories: taskData.progress.map(day => day.name)
            },
            yAxis: {
                title: {
                    text: 'Tareas Completadas'
                }
            },
            series: [{
                name: 'Tareas Completadas',
                data: taskData.progress.map(day => day.value),
                color: '#A3C9A8'
            }]
        });

        // Gráfico de distribución de tareas
        Highcharts.chart('taskDistributionChart', {
            chart: {
                type: 'pie'
            },
            title: {
                text: 'Distribución de Tareas por Categoría'
            },
            series: [{
                name: 'Tareas',
                data: Object.entries(taskData.categories).map(([name, value]) => ({name, y: value})),
                colors: ['#A3C9A8', '#BFD7EA', '#F5B7A5', '#F4EAE0']
            }]
        });