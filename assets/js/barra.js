/**
* TimeFlow - Sidebar JavaScript
*/

document.addEventListener("DOMContentLoaded", () => {
  // Inicializar componentes
  initSidebar()
 })
 
 /**
 * Inicializar la funcionalidad del sidebar
 */
 function initSidebar() {
  const dashboard = document.querySelector(".dashboard")
  const sidebar = document.querySelector(".sidebar")
  const sidebarToggle = document.getElementById("sidebarToggle")
  const mobileSidebarToggle = document.getElementById("mobileSidebarToggle")
 
  // Verificar si hay un estado guardado en localStorage
  const sidebarState = localStorage.getItem("sidebarState")
  if (sidebarState === "collapsed" && dashboard) {
    dashboard.classList.add("sidebar-collapsed")
  }
 
  // Toggle del sidebar en escritorio
  if (sidebarToggle && dashboard) {
    sidebarToggle.addEventListener("click", () => {
      dashboard.classList.toggle("sidebar-collapsed")
 
      // Guardar estado en localStorage
      const isCollapsed = dashboard.classList.contains("sidebar-collapsed")
      localStorage.setItem("sidebarState", isCollapsed ? "collapsed" : "expanded")
    })
  }
 
  // Toggle del sidebar en móvil
  if (mobileSidebarToggle && sidebar) {
    mobileSidebarToggle.addEventListener("click", () => {
      sidebar.classList.toggle("show")
    })
  }
 
  // Cerrar sidebar en móvil al hacer clic fuera
  document.addEventListener("click", (event) => {
    if (!sidebar) return
 
    const isClickInsideSidebar = sidebar.contains(event.target)
    const isClickOnToggle = mobileSidebarToggle && mobileSidebarToggle.contains(event.target)
 
    if (!isClickInsideSidebar && !isClickOnToggle && sidebar.classList.contains("show")) {
      sidebar.classList.remove("show")
    }
  })
 }
  /**
   * Inicializar el toggle de tema claro/oscuro
   */
  function initThemeToggle() {
    const themeToggle = document.getElementById("themeToggle")
    const htmlElement = document.documentElement
  
    // Verificar si hay un tema guardado en localStorage
    const savedTheme = localStorage.getItem("theme")
    if (savedTheme) {
      htmlElement.setAttribute("data-theme", savedTheme)
      updateThemeIcon(savedTheme)
    }
  
    if (themeToggle) {
      themeToggle.addEventListener("click", () => {
        const currentTheme = htmlElement.getAttribute("data-theme")
        const newTheme = currentTheme === "dark" ? "light" : "dark"
  
        htmlElement.setAttribute("data-theme", newTheme)
        localStorage.setItem("theme", newTheme)
  
        updateThemeIcon(newTheme)
      })
    }
  
    function updateThemeIcon(theme) {
      if (!themeToggle) return
  
      const icon = themeToggle.querySelector("i")
      if (theme === "dark") {
        icon.className = "fas fa-sun"
      } else {
        icon.className = "fas fa-moon"
      }
    }
  }
  
  /**
   * Inicializar los dropdowns
   */
  function initDropdowns() {
    // Implementación de dropdowns si es necesario
    // Esta función puede expandirse según las necesidades
  }
  
  /**
   * Inicializar los gráficos con Highcharts
   */
  function initCharts() {
    // Gráfico de progreso de tareas
    Highcharts.chart("taskProgressChart", {
      chart: {
        type: "column",
        backgroundColor: "transparent",
        style: {
          fontFamily: "Nunito, sans-serif",
        },
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
          data: [3, 5, 4, 7, 6, 2, 1],
        },
        {
          name: "Pendientes",
          color: "#F5B7A5",
          data: [2, 3, 5, 1, 2, 1, 0],
        },
      ],
    })
  
    // Gráfico de distribución de tiempo
    Highcharts.chart("timeDistributionChart", {
      chart: {
        type: "pie",
        backgroundColor: "transparent",
        style: {
          fontFamily: "Nunito, sans-serif",
        },
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
          name: "Tiempo",
          colorByPoint: true,
          data: [
            {
              name: "Desarrollo",
              y: 35,
              color: "#A3C9A8",
            },
            {
              name: "Reuniones",
              y: 20,
              color: "#BFD7EA",
            },
            {
              name: "Planificación",
              y: 15,
              color: "#F5B7A5",
            },
            {
              name: "Investigación",
              y: 20,
              color: "#F4EAE0",
            },
            {
              name: "Otros",
              y: 10,
              color: "#6D8299",
            },
          ],
        },
      ],
    })
  
    // Gráfico de tendencia de productividad
    Highcharts.chart("productivityTrendChart", {
      chart: {
        type: "spline",
        backgroundColor: "transparent",
        style: {
          fontFamily: "Nunito, sans-serif",
        },
      },
      title: {
        text: null,
      },
      xAxis: {
        categories: ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"],
      },
      yAxis: {
        title: {
          text: "Productividad (%)",
        },
        min: 0,
        max: 100,
      },
      tooltip: {
        crosshairs: true,
        shared: true,
      },
      plotOptions: {
        spline: {
          marker: {
            radius: 4,
            lineColor: "#666666",
            lineWidth: 1,
          },
        },
      },
      series: [
        {
          name: "Esta semana",
          color: "#A3C9A8",
          marker: {
            symbol: "circle",
          },
          data: [65, 70, 75, 85, 80, 75, 78],
        },
        {
          name: "Semana anterior",
          color: "#BFD7EA",
          marker: {
            symbol: "diamond",
          },
          data: [60, 65, 70, 75, 70, 65, 70],
        },
      ],
    })
  }
  
  /**
   * Inicializar el modal de tareas
   */
  function initTaskModal() {
    const addTaskBtn = document.querySelector(".add-task-btn")
    const taskModal = document.getElementById("taskModal")
    const closeModal = document.querySelector(".close-modal")
    const cancelTask = document.getElementById("cancelTask")
    const saveTask = document.getElementById("saveTask")
  
    if (addTaskBtn && taskModal) {
      addTaskBtn.addEventListener("click", () => {
        taskModal.classList.add("show")
      })
    }
  
    if (closeModal) {
      closeModal.addEventListener("click", () => {
        taskModal.classList.remove("show")
      })
    }
  
    if (cancelTask) {
      cancelTask.addEventListener("click", () => {
        taskModal.classList.remove("show")
      })
    }
  
    if (saveTask) {
      saveTask.addEventListener("click", () => {
        // Aquí iría la lógica para guardar la tarea
        // Por ahora solo cerramos el modal
        taskModal.classList.remove("show")
  
        // Mostrar notificación de éxito
        showNotification("Tarea guardada correctamente", "success")
      })
    }
  
    // Cerrar modal al hacer clic fuera
    window.addEventListener("click", (event) => {
      if (event.target === taskModal) {
        taskModal.classList.remove("show")
      }
    })
  }
  
  /**
   * Mostrar notificación
   */
  function showNotification(message, type = "info") {
    // Crear elemento de notificación
    const notification = document.createElement("div")
    notification.className = `notification ${type}`
    notification.innerHTML = `
          <div class="notification-content">
              <i class="fas ${type === "success" ? "fa-check-circle" : "fa-info-circle"}"></i>
              <span>${message}</span>
          </div>
          <button class="notification-close">
              <i class="fas fa-times"></i>
          </button>
      `
  
    // Añadir al DOM
    document.body.appendChild(notification)
  
    // Mostrar con animación
    setTimeout(() => {
      notification.classList.add("show")
    }, 10)
  
    // Configurar cierre automático
    setTimeout(() => {
      notification.classList.remove("show")
      setTimeout(() => {
        notification.remove()
      }, 300)
    }, 5000)
  
    // Configurar cierre manual
    const closeBtn = notification.querySelector(".notification-close")
    if (closeBtn) {
      closeBtn.addEventListener("click", () => {
        notification.classList.remove("show")
        setTimeout(() => {
          notification.remove()
        }, 300)
      })
    }
  }
  
  /**
   * Animar elementos al cargar la página
   */
  function animateElements() {
    const elements = document.querySelectorAll(".kpi-card, .chart-card, .widget-card")
  
    elements.forEach((element, index) => {
      element.classList.add("fade-in")
      element.style.animationDelay = `${index * 0.1}s`
    })
  }
  
  /**
   * Actualizar valores de KPI con datos reales
   * Esta función se llamaría después de obtener datos del servidor
   */
  function updateKPIs(data) {
    // Esta es una función de ejemplo que se implementaría
    // cuando se integre con el backend
    // Ejemplo:
    // document.getElementById('completedTasks').textContent = data.completedTasks;
    // document.getElementById('pendingTasks').textContent = data.pendingTasks;
    // document.getElementById('productivity').textContent = data.productivity + '%';
    // document.getElementById('focusTime').textContent = data.focusTime + 'h';
  }
  
  