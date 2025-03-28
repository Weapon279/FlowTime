/**
 * TimeFlow - Loader JavaScript
 * Script para manejar la pantalla de carga con reloj animado y frases motivacionales
 */

// Colección de frases motivacionales
const motivationalQuotes = [
    {
      text: "El tiempo es el recurso más valioso que tienes, porque es limitado. Puedes obtener más dinero, pero no puedes obtener más tiempo.",
      author: "Brian Tracy",
    },
    {
      text: "Tu tiempo es limitado, así que no lo desperdicies viviendo la vida de otra persona.",
      author: "Steve Jobs",
    },
    {
      text: "La clave del éxito es concentrar nuestra mente en lo que queremos, no en lo que tememos.",
      author: "Napoleon Hill",
    },
    {
      text: "No cuentes los días, haz que los días cuenten.",
      author: "Muhammad Ali",
    },
    {
      text: "El tiempo perdido nunca se encuentra de nuevo.",
      author: "Benjamin Franklin",
    },
    {
      text: "La productividad nunca es un accidente. Es siempre el resultado de un compromiso con la excelencia, planificación inteligente y esfuerzo enfocado.",
      author: "Paul J. Meyer",
    },
    {
      text: "No se trata de tener tiempo, se trata de hacer tiempo.",
      author: "Rachael Bermingham",
    },
    {
      text: "La procrastinación es como una tarjeta de crédito: es divertido hasta que recibes la factura.",
      author: "Christopher Parker",
    },
    {
      text: "La mejor manera de predecir el futuro es crearlo.",
      author: "Peter Drucker",
    },
    {
      text: "Concéntrate en ser productivo, no en estar ocupado.",
      author: "Tim Ferriss",
    },
    {
      text: "No hay viento favorable para el que no sabe a dónde va.",
      author: "Séneca",
    },
    {
      text: "La disciplina es el puente entre metas y logros.",
      author: "Jim Rohn",
    },
    {
      text: "El éxito no es la clave de la felicidad. La felicidad es la clave del éxito.",
      author: "Albert Schweitzer",
    },
    {
      text: "La acción es la clave fundamental de todo éxito.",
      author: "Pablo Picasso",
    },
    {
      text: "Nunca dejes para mañana lo que puedas hacer hoy.",
      author: "Thomas Jefferson",
    },
  ]
  
  /**
   * Clase para manejar la pantalla de carga
   */
  class PageLoader {
    constructor() {
      this.loaderElement = document.getElementById("pageLoader")
      this.quoteTextElement = document.getElementById("quoteText")
      this.quoteAuthorElement = document.getElementById("quoteAuthor")
      this.isLoading = false
      this.minDisplayTime = 3000 // Tiempo mínimo de visualización en ms
      this.init()
    }
  
    /**
     * Inicializa el loader
     */
    init() {
      if (!this.loaderElement) return
  
      // Mostrar una cita aleatoria
      this.showRandomQuote()
  
      // Escuchar eventos de carga de la página
      window.addEventListener("load", () => {
        this.hideLoader()
      })
  
      // Método para mostrar el loader al navegar entre páginas
      document.addEventListener("DOMContentLoaded", () => {
        const links = document.querySelectorAll('a:not([target="_blank"])')
        links.forEach((link) => {
          link.addEventListener("click", (e) => {
            // Solo mostrar el loader si el enlace lleva a otra página
            const href = link.getAttribute("href")
            if (href && !href.startsWith("#") && !href.startsWith("javascript:")) {
              e.preventDefault()
              this.showLoader()
  
              // Navegar después de un breve retraso para que se vea el loader
              setTimeout(() => {
                window.location.href = href
              }, 3000)
            }
          })
        })
      })
    }
  
    /**
     * Muestra el loader
     */
    showLoader() {
      if (!this.loaderElement) return
  
      this.isLoading = true
      this.loaderElement.classList.remove("hidden")
      this.showRandomQuote()
  
      // Asegurarse de que el body no se pueda desplazar mientras se muestra el loader
      document.body.style.overflow = "hidden"
  
      // Registrar el tiempo de inicio
      this.startTime = new Date().getTime()
    }
  
    /**
     * Oculta el loader
     */
    hideLoader() {
      if (!this.loaderElement || !this.isLoading) return
  
      // Calcular cuánto tiempo ha pasado desde que se mostró el loader
      const currentTime = new Date().getTime()
      const elapsedTime = currentTime - this.startTime
  
      // Si no ha pasado el tiempo mínimo, esperar
      if (elapsedTime < this.minDisplayTime) {
        setTimeout(() => {
          this.completeHideLoader()
        }, this.minDisplayTime - elapsedTime)
      } else {
        this.completeHideLoader()
      }
    }
  
    /**
     * Completa el proceso de ocultar el loader
     */
    completeHideLoader() {
      this.loaderElement.classList.add("hidden")
      this.isLoading = false
  
      // Restaurar el desplazamiento del body
      document.body.style.overflow = ""
    }
  
    /**
     * Muestra una cita aleatoria
     */
    showRandomQuote() {
      if (!this.quoteTextElement || !this.quoteAuthorElement) return
  
      // Ocultar los elementos de la cita
      this.quoteTextElement.classList.remove("show")
      this.quoteAuthorElement.classList.remove("show")
  
      // Seleccionar una cita aleatoria
      const randomIndex = Math.floor(Math.random() * motivationalQuotes.length)
      const quote = motivationalQuotes[randomIndex]
  
      // Actualizar el contenido después de un breve retraso
      setTimeout(() => {
        this.quoteTextElement.textContent = `"${quote.text}"`
        this.quoteAuthorElement.textContent = `— ${quote.author}`
  
        // Mostrar los elementos con animación
        this.quoteTextElement.classList.add("show")
        this.quoteAuthorElement.classList.add("show")
      }, 300)
    }
  }
  
  // Inicializar el loader cuando el DOM esté listo
  document.addEventListener("DOMContentLoaded", () => {
    window.pageLoader = new PageLoader()
  
    // Mostrar el loader inicialmente
    if (window.pageLoader) {
      window.pageLoader.showLoader()
    }
  })
  
  