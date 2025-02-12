// main.js

document.addEventListener('DOMContentLoaded', () => {
    // Animaciones al hacer scroll
    const scrollAnimations = () => {
        const elements = document.querySelectorAll('.scroll-animate');
        
        elements.forEach(element => {
            const elementTop = element.getBoundingClientRect().top;
            const elementBottom = element.getBoundingClientRect().bottom;
            
            if (elementTop < window.innerHeight && elementBottom > 0) {
                element.classList.add('active');
            } else {
                element.classList.remove('active');
            }
        });
    };

    // Ejecutar animaciones al cargar la página y al hacer scroll
    scrollAnimations();
    window.addEventListener('scroll', scrollAnimations);

    // Efecto de typing para el título principal
    const typingEffect = (element, text, speed = 100) => {
        let i = 0;
        const timer = setInterval(() => {
            if (i < text.length) {
                element.innerHTML += text.charAt(i);
                i++;
            } else {
                clearInterval(timer);
            }
        }, speed);
    };

    const mainTitle = document.querySelector('#hero h1');
    if (mainTitle) {
        const originalText = mainTitle.innerText;
        mainTitle.innerText = '';
        typingEffect(mainTitle, originalText, 50);
    }

    // Contador de estadísticas
    const startCounter = (element, target, duration = 2000) => {
        let start = 0;
        const increment = target / (duration / 16);
        const timer = setInterval(() => {
            start += increment;
            element.textContent = Math.floor(start);
            if (start >= target) {
                element.textContent = target;
                clearInterval(timer);
            }
        }, 16);
    };

    const statElements = document.querySelectorAll('.stat-number');
    statElements.forEach(element => {
        const target = parseInt(element.getAttribute('data-target'));
        startCounter(element, target);
    });

    // Smooth scroll para los enlaces internos
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            document.querySelector(this.getAttribute('href')).scrollIntoView({
                behavior: 'smooth'
            });
        });
    });

    // Toggle para el menú móvil (si lo tienes)
    const menuToggle = document.querySelector('.menu-toggle');
    const mobileMenu = document.querySelector('.mobile-menu');
    
    if (menuToggle && mobileMenu) {
        menuToggle.addEventListener('click', () => {
            mobileMenu.classList.toggle('active');
        });
    }
});