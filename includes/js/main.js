/**
 * TimeFlow - JavaScript Principal
 */

document.addEventListener("DOMContentLoaded", () => {
  // Inicializar componentes
  initMobileMenu()
  initTabs()
  initCardSliders()
  initTimeline()
  initFaqCarousel()
  initBackToTop()
  initScrollAnimations()
})

/**
 * Funcionalidad del menú móvil
 */
function initMobileMenu() {
  const menuToggle = document.querySelector(".menu-toggle")
  const navMenu = document.querySelector(".nav-menu")

  if (menuToggle && navMenu) {
    menuToggle.addEventListener("click", () => {
      menuToggle.classList.toggle("active")
      navMenu.classList.toggle("active")
    })

    // Cerrar menú al hacer clic en un enlace
    document.querySelectorAll(".nav-link").forEach((link) => {
      link.addEventListener("click", () => {
        menuToggle.classList.remove("active")
        navMenu.classList.remove("active")
      })
    })
  }
}

/**
 * Funcionalidad de pestañas para la sección problema-solución
 */
function initTabs() {
  const tabBtns = document.querySelectorAll(".tab-btn")
  const tabContents = document.querySelectorAll(".tab-content")

  tabBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      const tabId = btn.getAttribute("data-tab")

      // Quitar clase activa de todos los botones y contenidos
      tabBtns.forEach((b) => b.classList.remove("active"))
      tabContents.forEach((c) => c.classList.remove("active"))

      // Añadir clase activa al botón clickeado y su contenido correspondiente
      btn.classList.add("active")
      document.getElementById(tabId).classList.add("active")
    })
  })
}

/**
 * Deslizadores de tarjetas para las secciones de problema y solución
 */
function initCardSliders() {
  const sliders = document.querySelectorAll(".cards-slider")

  sliders.forEach((slider) => {
    const cards = slider.querySelectorAll(".card")
    const prevBtn = slider.nextElementSibling.querySelector(".prev")
    const nextBtn = slider.nextElementSibling.querySelector(".next")
    const dots = slider.nextElementSibling.querySelectorAll(".dot")
    let currentIndex = 0

    // Establecer estado inicial
    updateSlider()

    // Eventos de escucha
    prevBtn.addEventListener("click", () => {
      currentIndex = (currentIndex - 1 + cards.length) % cards.length
      updateSlider()
    })

    nextBtn.addEventListener("click", () => {
      currentIndex = (currentIndex + 1) % cards.length
      updateSlider()
    })

    dots.forEach((dot, index) => {
      dot.addEventListener("click", () => {
        currentIndex = index
        updateSlider()
      })
    })

    // Funcionalidad de deslizamiento táctil
    let touchStartX = 0
    let touchEndX = 0

    slider.addEventListener("touchstart", (e) => {
      touchStartX = e.changedTouches[0].screenX
    })

    slider.addEventListener("touchend", (e) => {
      touchEndX = e.changedTouches[0].screenX
      handleSwipe()
    })

    function handleSwipe() {
      if (touchEndX < touchStartX - 50) {
        // Deslizar a la izquierda
        currentIndex = (currentIndex + 1) % cards.length
        updateSlider()
      } else if (touchEndX > touchStartX + 50) {
        // Deslizar a la derecha
        currentIndex = (currentIndex - 1 + cards.length) % cards.length
        updateSlider()
      }
    }

    function updateSlider() {
      // Actualizar posiciones de las tarjetas
      cards.forEach((card, index) => {
        card.style.transform = `translateX(${(index - currentIndex) * 100}%)`
      })

      // Actualizar puntos indicadores
      dots.forEach((dot, index) => {
        dot.classList.toggle("active", index === currentIndex)
      })
    }
  })
}

/**
 * Funcionalidad de línea de tiempo horizontal
 */
function initTimeline() {
  const timelineItems = document.querySelectorAll(".timeline-item")
  const prevBtn = document.querySelector(".timeline-btn.prev")
  const nextBtn = document.querySelector(".timeline-btn.next")
  const progressBar = document.querySelector(".progress-bar")
  const timelineTrack = document.querySelector(".timeline-track")
  let currentStep = 1
  const totalSteps = timelineItems.length

  // Verificar que los elementos existan
  if (!timelineTrack || !progressBar || !prevBtn || !nextBtn) {
    console.error("Elementos de línea de tiempo no encontrados")
    return
  }

  // Eventos de escucha
  prevBtn.addEventListener("click", () => {
    if (currentStep > 1) {
      currentStep--
      updateTimeline()
    }
  })

  nextBtn.addEventListener("click", () => {
    if (currentStep < totalSteps) {
      currentStep++
      updateTimeline()
    }
  })

  // Funcionalidad de deslizamiento táctil
  let touchStartX = 0
  let touchEndX = 0

  timelineTrack.addEventListener("touchstart", (e) => {
    touchStartX = e.changedTouches[0].screenX
  })

  timelineTrack.addEventListener("touchend", (e) => {
    touchEndX = e.changedTouches[0].screenX
    handleSwipe()
  })

  function handleSwipe() {
    if (touchEndX < touchStartX - 50 && currentStep < totalSteps) {
      // Deslizar a la izquierda
      currentStep++
      updateTimeline()
    } else if (touchEndX > touchStartX + 50 && currentStep > 1) {
      // Deslizar a la derecha
      currentStep--
      updateTimeline()
    }
  }

  function updateTimeline() {
    // Actualizar elemento activo
    timelineItems.forEach((item) => {
      const step = Number.parseInt(item.getAttribute("data-step"))
      item.classList.toggle("active", step === currentStep)
    })

    // Actualizar barra de progreso
    const progress = ((currentStep - 1) / (totalSteps - 1)) * 100
    progressBar.style.width = `${progress}%`

    // Actualizar botones
    prevBtn.disabled = currentStep === 1
    nextBtn.disabled = currentStep === totalSteps

    // Desplazarse al elemento activo
    const activeItem = document.querySelector(`.timeline-item[data-step="${currentStep}"]`)
    if (activeItem) {
      timelineTrack.scrollLeft = activeItem.offsetLeft - timelineTrack.offsetWidth / 2 + activeItem.offsetWidth / 2
    }
  }

  // Establecer estado inicial después de definir todas las funciones
  updateTimeline()
}

/**
 * Funcionalidad de carrusel para preguntas frecuentes
 */
function initFaqCarousel() {
  const faqSlides = document.querySelectorAll(".faq-slide")
  const prevBtn = document.querySelector(".faq-btn.prev")
  const nextBtn = document.querySelector(".faq-btn.next")
  const dots = document.querySelectorAll(".faq-dots .dot")

  // Verificar que los elementos existan
  if (faqSlides.length === 0 || !prevBtn || !nextBtn) {
    return
  }

  let currentIndex = 0

  // Eventos de escucha
  prevBtn.addEventListener("click", () => {
    currentIndex = (currentIndex - 1 + faqSlides.length) % faqSlides.length
    updateFaq()
  })

  nextBtn.addEventListener("click", () => {
    currentIndex = (currentIndex + 1) % faqSlides.length
    updateFaq()
  })

  dots.forEach((dot, index) => {
    dot.addEventListener("click", () => {
      currentIndex = index
      updateFaq()
    })
  })

  // Funcionalidad de deslizamiento táctil
  const faqCarousel = document.querySelector(".faq-carousel")
  if (faqCarousel) {
    let touchStartX = 0
    let touchEndX = 0

    faqCarousel.addEventListener("touchstart", (e) => {
      touchStartX = e.changedTouches[0].screenX
    })

    faqCarousel.addEventListener("touchend", (e) => {
      touchEndX = e.changedTouches[0].screenX
      handleSwipe()
    })

    function handleSwipe() {
      if (touchEndX < touchStartX - 50) {
        // Deslizar a la izquierda
        currentIndex = (currentIndex + 1) % faqSlides.length
        updateFaq()
      } else if (touchEndX > touchStartX + 50) {
        // Deslizar a la derecha
        currentIndex = (currentIndex - 1 + faqSlides.length) % faqSlides.length
        updateFaq()
      }
    }
  }

  function updateFaq() {
    // Actualizar diapositivas
    faqSlides.forEach((slide, index) => {
      slide.classList.toggle("active", index === currentIndex)
    })

    // Actualizar puntos indicadores
    dots.forEach((dot, index) => {
      dot.classList.toggle("active", index === currentIndex)
    })
  }

  // Establecer estado inicial
  updateFaq()
}

/**
 * Testimonials slider
 */
function initTestimonials() {
  const testimonios = document.querySelectorAll(".testimonio")
  const dots = document.querySelectorAll(".dot")
  const prevBtn = document.querySelector(".prev-btn")
  const nextBtn = document.querySelector(".next-btn")
  let currentIndex = 0

  function showTestimonio(index) {
    testimonios.forEach((testimonio) => testimonio.classList.remove("active"))
    dots.forEach((dot) => dot.classList.remove("active"))

    testimonios[index].classList.add("active")
    dots[index].classList.add("active")
    currentIndex = index
  }

  if (dots.length) {
    dots.forEach((dot, index) => {
      dot.addEventListener("click", () => showTestimonio(index))
    })
  }

  if (prevBtn) {
    prevBtn.addEventListener("click", () => {
      currentIndex = (currentIndex - 1 + testimonios.length) % testimonios.length
      showTestimonio(currentIndex)
    })
  }

  if (nextBtn) {
    nextBtn.addEventListener("click", () => {
      currentIndex = (currentIndex + 1) % testimonios.length
      showTestimonio(currentIndex)
    })
  }

  // Auto rotate testimonials
  setInterval(() => {
    currentIndex = (currentIndex + 1) % testimonios.length
    showTestimonio(currentIndex)
  }, 5000)
}

/**
 * FAQ accordion
 */
function initFaqAccordion() {
  const faqItems = document.querySelectorAll(".faq-item")

  faqItems.forEach((item) => {
    const question = item.querySelector(".faq-question")

    question.addEventListener("click", () => {
      const isActive = item.classList.contains("active")

      // Close all items
      faqItems.forEach((faqItem) => {
        faqItem.classList.remove("active")
      })

      // Open current item if it wasn't active
      if (!isActive) {
        item.classList.add("active")
      }
    })
  })
}

/**
 * Funcionalidad del botón volver arriba
 */
function initBackToTop() {
  const backToTopBtn = document.getElementById("back-to-top")

  if (backToTopBtn) {
    window.addEventListener("scroll", () => {
      if (window.pageYOffset > 300) {
        backToTopBtn.classList.add("show")
      } else {
        backToTopBtn.classList.remove("show")
      }
    })

    backToTopBtn.addEventListener("click", () => {
      window.scrollTo({
        top: 0,
        behavior: "smooth",
      })
    })
  }
}

/**
 * Animaciones de desplazamiento
 */
function initScrollAnimations() {
  // Desplazamiento suave para enlaces de anclaje
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener("click", function (e) {
      const targetId = this.getAttribute("href")

      if (targetId === "#") return

      const targetElement = document.querySelector(targetId)

      if (targetElement) {
        e.preventDefault()

        const headerHeight = document.querySelector(".header").offsetHeight
        const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - headerHeight

        window.scrollTo({
          top: targetPosition,
          behavior: "smooth",
        })
      }
    })
  })

  // Animar elementos cuando entran en el viewport
  const animatedElements = document.querySelectorAll(
    ".problema-card, .solucion-card, .timeline-item, .beneficio-card, .faq-item",
  )

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.style.opacity = "1"
            entry.target.style.transform = "translateY(0)"
            observer.unobserve(entry.target)
          }
        })
      },
      { threshold: 0.1 },
    )

    animatedElements.forEach((element) => {
      observer.observe(element)
    })
  } else {
    // Fallback para navegadores que no soportan IntersectionObserver
    animatedElements.forEach((element) => {
      element.style.opacity = "1"
      element.style.transform = "translateY(0)"
    })
  }
}

