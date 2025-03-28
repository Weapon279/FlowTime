// Dashboard.js - Funcionalidad principal del dashboard

// Declarar Highcharts como variable global si no está ya definida
if (typeof Highcharts === "undefined") {
  var Highcharts = window.Highcharts
}

// Esperar a que el DOM esté completamente cargado
document.addEventListener("DOMContentLoaded", () => {
  // Inicializar componentes después de que la pantalla de carga desaparezca
  setTimeout(initializeDashboard, 1500)

  // Agregar eventos a los botones de acción
  document.querySelectorAll(".card-action-btn").forEach((btn) => {
    btn.addEventListener("click", function () {
      if (this.title === "Actualizar") {
        const card = this.closest(".dashboard-card")
        simulateDataRefresh(card)
      }
    })
  })
})

// Inicializar el dashboard
function initializeDashboard() {
  // Actualizar datos de KPIs con animación
  animateCounter("completedTasks", 0, 27, 1500)
  animateCounter("pendingTasks", 0, 8, 1500)
  animateCounter("productivity", 0, 78, 1500, "%")
  animateCounter("focusedTime", 0, 32, 1500, "h")

  // Inicializar gráficos
  initializeCharts()

  // Cargar datos de tareas y actividades
  loadRecentTasks()
  loadRecentActivity()
  loadUpcomingEvents()

  // Inicializar eventos de interacción
  initializeInteractions()
}

// Animar contadores para los KPIs
function animateCounter(elementId, start, end, duration, suffix = "") {
  const element = document.getElementById(elementId)
  if (!element) return

  let startTime = null

  function animation(currentTime) {
    if (!startTime) startTime = currentTime
    const timeElapsed = currentTime - startTime
    const progress = Math.min(timeElapsed / duration, 1)
    const value = Math.floor(progress * (end - start) + start)

    element.textContent = value + suffix

    if (progress < 1) {
      requestAnimationFrame(animation)
    }
  }

  requestAnimationFrame(animation)
}

// Inicializar gráficos
function initializeCharts() {
  // Configuración global para quitar la marca de agua de Highcharts
  if (Highcharts) {
    Highcharts.setOptions({
      credits: {
        enabled: false, // Esto elimina la marca de agua de Highcharts
      },
    })
  }

  // Gráfico de progreso de tareas
  Highcharts.chart("taskProgressChart", {
    chart: {
      type: "column",
      backgroundColor: "transparent",
    },
    title: {
      text: null,
    },
    xAxis: {
      categories: ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"],
      crosshair: true,
    },
    yAxis: {
      min: 0,
      title: {
        text: "Tareas",
      },
    },
    tooltip: {
      headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
      pointFormat:
        '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' +
        '<td style="padding:0"><b>{point.y}</b></td></tr>',
      footerFormat: "</table>",
      shared: true,
      useHTML: true,
    },
    plotOptions: {
      column: {
        pointPadding: 0.2,
        borderWidth: 0,
      },
    },
    series: [
      {
        name: "Completadas",
        color: "#A3C9A8",
        data: [5, 7, 3, 6, 4, 2, 0],
      },
      {
        name: "Pendientes",
        color: "#F5B7A5",
        data: [2, 1, 3, 2, 0, 0, 0],
      },
    ],
  })

  // Gráfico de distribución de tareas por categoría
  Highcharts.chart("taskDistributionChart", {
    chart: {
      type: "pie",
      backgroundColor: "transparent",
    },
    title: {
      text: null,
    },
    tooltip: {
      pointFormat: "{series.name}: <b>{point.percentage:.1f}%</b>",
    },
    accessibility: {
      point: {
        valueSuffix: "%",
      },
    },
    plotOptions: {
      pie: {
        allowPointSelect: true,
        cursor: "pointer",
        dataLabels: {
          enabled: true,
          format: "<b>{point.name}</b>: {point.percentage:.1f} %",
        },
      },
    },
    series: [
      {
        name: "Categorías",
        colorByPoint: true,
        data: [
          {
            name: "Trabajo",
            y: 45,
            color: "#A3C9A8",
          },
          {
            name: "Estudios",
            y: 25,
            color: "#BFD7EA",
          },
          {
            name: "Personal",
            y: 20,
            color: "#F5B7A5",
          },
          {
            name: "Otros",
            y: 10,
            color: "#F4EAE0",
          },
        ],
      },
    ],
  })
}

// Cargar tareas recientes
function loadRecentTasks() {
  const taskList = document.getElementById("recentTasksList")
  if (!taskList) return

  const tasks = [
    {
      name: "Preparar informe semanal",
      date: "Hoy, 14:30",
      status: "pending",
      priority: "high",
    },
    {
      name: "Reunión con el equipo",
      date: "Hoy, 10:00",
      status: "completed",
      priority: "medium",
    },
    {
      name: "Revisar propuesta de diseño",
      date: "Ayer, 16:45",
      status: "in-progress",
      priority: "medium",
    },
    {
      name: "Actualizar documentación",
      date: "Ayer, 11:20",
      status: "pending",
      priority: "low",
    },
  ]

  taskList.innerHTML = ""
  tasks.forEach((task) => {
    const taskItem = document.createElement("div")
    taskItem.className = "task-item"
    taskItem.innerHTML = `
      <div class="task-status ${task.status}"></div>
      <div class="task-content">
        <h4>${task.name}</h4>
        <p>${task.date}</p>
      </div>
      <div class="task-priority ${task.priority}">${task.priority}</div>
    `
    taskList.appendChild(taskItem)
  })
}

// Cargar actividad reciente
function loadRecentActivity() {
  const activityList = document.getElementById("recentActivityList")
  if (!activityList) return

  const activities = [
    {
      type: "completed",
      name: "Completaste una tarea",
      description: "Diseñar wireframes para la app",
      time: "Hace 2 horas",
    },
    {
      type: "added",
      name: "Agregaste una nueva tarea",
      description: "Preparar informe semanal",
      time: "Hace 3 horas",
    },
    {
      type: "session",
      name: "Sesión de Pomodoro",
      description: "4 ciclos completados",
      time: "Hace 5 horas",
    },
    {
      type: "added",
      name: "Agregaste un evento",
      description: "Reunión de planificación",
      time: "Ayer",
    },
  ]

  activityList.innerHTML = ""
  activities.forEach((activity) => {
    const activityItem = document.createElement("div")
    activityItem.className = "activity-item"
    activityItem.innerHTML = `
      <div class="activity-icon ${activity.type}">
        <i class="fas ${getActivityIcon(activity.type)}"></i>
      </div>
      <div class="activity-content">
        <h4>${activity.name}</h4>
        <p>${activity.description}</p>
        <p>${activity.time}</p>
      </div>
    `
    activityList.appendChild(activityItem)
  })
}

// Obtener icono según el tipo de actividad
function getActivityIcon(type) {
  switch (type) {
    case "completed":
      return "fa-check"
    case "added":
      return "fa-plus"
    case "session":
      return "fa-clock"
    default:
      return "fa-circle"
  }
}

// Cargar próximos eventos
function loadUpcomingEvents() {
  const eventsList = document.getElementById("upcomingEventsList")
  if (!eventsList) return

  const events = [
    {
      title: "Reunión de equipo",
      time: "Hoy, 15:00",
      countdown: "En 2 horas",
      icon: "fa-users",
    },
    {
      title: "Entrega de proyecto",
      time: "Mañana, 10:00",
      countdown: "En 1 día",
      icon: "fa-briefcase",
    },
    {
      title: "Revisión de sprint",
      time: "Viernes, 14:30",
      countdown: "En 3 días",
      icon: "fa-tasks",
    },
  ]

  eventsList.innerHTML = ""
  events.forEach((event) => {
    const eventItem = document.createElement("div")
    eventItem.className = "upcoming-event"
    eventItem.innerHTML = `
      <div class="upcoming-event-icon">
        <i class="fas ${event.icon}"></i>
      </div>
      <div class="upcoming-event-info">
        <div class="upcoming-event-title">${event.title}</div>
        <div class="upcoming-event-time">${event.time}</div>
      </div>
      <div class="upcoming-event-countdown">${event.countdown}</div>
    `
    eventsList.appendChild(eventItem)
  })
}

// Inicializar interacciones y eventos
function initializeInteractions() {
  // Hacer que las tarjetas de tareas sean interactivas
  document.querySelectorAll(".task-item").forEach((item) => {
    item.addEventListener("click", () => {
      // Simular navegación a la página de detalles de la tarea
      showNotification("Abriendo detalles de la tarea...")
    })
  })

  // Hacer que los botones de acción rápida tengan efecto de hover
  document.querySelectorAll(".action-button").forEach((btn) => {
    btn.addEventListener("mouseenter", function () {
      this.style.transform = "translateY(-5px)"
    })

    btn.addEventListener("mouseleave", function () {
      this.style.transform = ""
    })
  })
}

// Simular actualización de datos
function simulateDataRefresh(card) {
  // Mostrar efecto de carga
  const chartContainer = card.querySelector(".chart-container")
  if (chartContainer) {
    chartContainer.innerHTML = '<div class="loading-indicator"><i class="fas fa-spinner fa-spin"></i></div>'

    // Simular tiempo de carga
    setTimeout(() => {
      // Restaurar el gráfico (en una aplicación real, se actualizarían los datos)
      showNotification("Datos actualizados correctamente")
      initializeCharts() // Reinicializar los gráficos
    }, 1500)
  }
}

// Mostrar notificación
function showNotification(message) {
  const notification = document.createElement("div")
  notification.className = "notification"
  notification.innerHTML = `
    <div class="notification-content">
      <i class="fas fa-info-circle"></i>
      <span>${message}</span>
    </div>
  `

  document.body.appendChild(notification)

  // Estilo de la notificación
  Object.assign(notification.style, {
    position: "fixed",
    bottom: "20px",
    right: "20px",
    backgroundColor: "var(--primary)",
    color: "white",
    padding: "12px 20px",
    borderRadius: "8px",
    boxShadow: "0 4px 12px rgba(0, 0, 0, 0.15)",
    zIndex: "9999",
    opacity: "0",
    transform: "translateY(20px)",
    transition: "opacity 0.3s, transform 0.3s",
  })

  // Animar entrada
  setTimeout(() => {
    notification.style.opacity = "1"
    notification.style.transform = "translateY(0)"
  }, 10)

  // Eliminar después de 3 segundos
  setTimeout(() => {
    notification.style.opacity = "0"
    notification.style.transform = "translateY(20px)"

    setTimeout(() => {
      document.body.removeChild(notification)
    }, 300)
  }, 3000)
}

