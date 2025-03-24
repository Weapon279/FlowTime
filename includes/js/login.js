/**
 * TimeFlow - Login & Register JavaScript
 * Este archivo maneja la funcionalidad de inicio de sesión y registro,
 * incluyendo la integración con Google Sign-In.
 */

// Elementos DOM
const signInBtn = document.querySelector('#sign-in-btn');
const signUpBtn = document.querySelector('#sign-up-btn');
const container = document.querySelector('.container');
const loginForm = document.querySelector('#login-form');
const registerForm = document.querySelector('#register-form');
const notification = document.querySelector('#notification');
const passwordInput = document.querySelector('#register-password');
const confirmPasswordInput = document.querySelector('#register-confirm-password');

// Variables para Google Sign-In
let googleSignInButton;
let googleSignUpButton;

// Determinar la ruta base del sitio web
const BASE_URL = window.location.protocol + '//' + window.location.host;
const DASHBOARD_PATH = `${BASE_URL}/flowtime/vista/dashboard.html`;

// Función para inicializar Google Sign-In
function initGoogleSignIn() {
    // Configuración para el botón de inicio de sesión con Google
    google.accounts.id.initialize({
        client_id: 'TU_GOOGLE_CLIENT_ID', // Reemplazar con tu Client ID real
        callback: handleGoogleCredentialResponse,
        auto_select: false,
        cancel_on_tap_outside: true,
    });

    // Renderizar el botón de inicio de sesión con Google
    google.accounts.id.renderButton(
        document.getElementById('google-signin-button'),
        { 
            theme: 'outline', 
            size: 'large',
            text: 'signin_with',
            shape: 'rectangular',
            logo_alignment: 'center',
            width: 240
        }
    );

    // Renderizar el botón de registro con Google
    google.accounts.id.renderButton(
        document.getElementById('google-signup-button'),
        { 
            theme: 'outline', 
            size: 'large',
            text: 'signup_with',
            shape: 'rectangular',
            logo_alignment: 'center',
            width: 240
        }
    );
}

// Función para manejar la respuesta de credenciales de Google
// Esta función se llama tanto para inicio de sesión como para registro
function handleGoogleCredentialResponse(response) {
    // Aquí procesamos la respuesta de Google
    if (response.credential) {
        // Obtener el token ID
        const token = response.credential;
        
        // Determinar si estamos en modo de registro o inicio de sesión
        const isSignUpMode = container.classList.contains('sign-up-mode');
        
        // Decodificar el token JWT para obtener la información del usuario
        // Nota: En producción, esta verificación debe hacerse en el servidor
        const payload = decodeJwtResponse(token);
        console.log('Google user info:', payload);
        
        if (isSignUpMode) {
            // Estamos en modo de registro
            handleGoogleSignUp(payload, token);
        } else {
            // Estamos en modo de inicio de sesión
            handleGoogleSignIn(payload, token);
        }
    } else {
        showNotification('Error al procesar la respuesta de Google', 'error');
    }
}

// Función para decodificar el token JWT de Google
// Nota: Esta función es solo para desarrollo. En producción, la verificación
// debe realizarse en el servidor por seguridad.
function decodeJwtResponse(token) {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));
    return JSON.parse(jsonPayload);
}

// Función para manejar el inicio de sesión con Google
function handleGoogleSignIn(userInfo, token) {
    // Aquí enviarías el token al servidor para verificación y autenticación
    console.log('Google Sign-In token:', token);
    
    // Simulación de envío al servidor (reemplazar con tu API real)
    // En un entorno real, enviarías el token al servidor y el servidor
    // verificaría el token con Google y crearía una sesión
    
    // Ejemplo de cómo podrías enviar el token al servidor:
    /*
    fetch('/api/auth/google-signin', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ token }),
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('¡Inicio de sesión con Google exitoso!', 'success');
            setTimeout(() => {
                window.location.href = DASHBOARD_PATH;
            }, 1500);
        } else {
            showNotification(data.message || 'Error al iniciar sesión', 'error');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showNotification('Error al conectar con el servidor', 'error');
    });
    */
    
    // Para esta demostración, simulamos un inicio de sesión exitoso
    showNotification('¡Inicio de sesión con Google exitoso!', 'success');
    
    // Redirigir al dashboard después de un breve retraso
    setTimeout(() => {
        window.location.href = DASHBOARD_PATH;
    }, 1500);
}

// Función para manejar el registro con Google
function handleGoogleSignUp(userInfo, token) {
    // Extraer información relevante del usuario
    const { name, email, picture, given_name, family_name } = userInfo;
    
    // Aquí enviarías el token y la información del usuario al servidor para registro
    console.log('Google Sign-Up token:', token);
    console.log('Registrando usuario con Google:', { name, email, picture });
    
    // Simulación de envío al servidor (reemplazar con tu API real)
    // En un entorno real, enviarías el token al servidor y el servidor
    // verificaría el token con Google, crearía una cuenta de usuario si no existe,
    // y luego crearía una sesión
    
    // Ejemplo de cómo podrías enviar los datos al servidor:
    /*
    fetch('/api/auth/google-signup', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
            token,
            userData: {
                name: given_name,
                lastname: family_name || '',
                email,
                profilePicture: picture
            }
        }),
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('¡Registro con Google exitoso!', 'success');
            setTimeout(() => {
                window.location.href = DASHBOARD_PATH;
            }, 1500);
        } else {
            showNotification(data.message || 'Error al registrarse', 'error');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showNotification('Error al conectar con el servidor', 'error');
    });
    */
    
    // Para esta demostración, simulamos un registro exitoso
    showNotification('¡Registro con Google exitoso!', 'success');
    
    // Redirigir al dashboard después de un breve retraso
    setTimeout(() => {
        window.location.href = DASHBOARD_PATH;
    }, 1500);
}

// Event Listeners para cambiar entre formularios
signUpBtn.addEventListener('click', () => {
    container.classList.add('sign-up-mode');
});

signInBtn.addEventListener('click', () => {
    container.classList.remove('sign-up-mode');
});

// Event Listener para el formulario de inicio de sesión
loginForm.addEventListener('submit', function(e) {
    e.preventDefault();
    
    const email = document.querySelector('#login-email').value;
    const password = document.querySelector('#login-password').value;
    
    // Validación básica
    if (!email || !password) {
        showNotification('Por favor, completa todos los campos', 'error');
        return;
    }
    
    // Validación de formato de email
    if (!isValidEmail(email)) {
        showNotification('Por favor, ingresa un correo electrónico válido', 'error');
        return;
    }
    
    // Simulación de inicio de sesión (reemplazar con tu API real)
    const loginBtn = loginForm.querySelector('.btn');
    loginBtn.classList.add('loading');
    loginBtn.disabled = true;
    
    // Simulación de tiempo de carga
    setTimeout(() => {
        // Aquí iría la lógica real de autenticación con tu backend
        console.log('Iniciando sesión con:', { email, password });
        
        // Simulación de éxito
        showNotification('¡Inicio de sesión exitoso!', 'success');
        
        // Redirigir al dashboard después de un breve retraso
        setTimeout(() => {
            window.location.href = DASHBOARD_PATH;
        }, 1500);
        
        loginBtn.classList.remove('loading');
        loginBtn.disabled = false;
    }, 1500);
});

// Event Listener para el formulario de registro
registerForm.addEventListener('submit', function(e) {
    e.preventDefault();
    
    const name = document.querySelector('#register-name').value;
    const lastname = document.querySelector('#register-lastname').value;
    const email = document.querySelector('#register-email').value;
    const password = document.querySelector('#register-password').value;
    const confirmPassword = document.querySelector('#register-confirm-password').value;
    const termsAccepted = document.querySelector('#terms').checked;
    
    // Validación básica
    if (!name || !lastname || !email || !password || !confirmPassword) {
        showNotification('Por favor, completa todos los campos', 'error');
        return;
    }
    
    // Validación de formato de email
    if (!isValidEmail(email)) {
        showNotification('Por favor, ingresa un correo electrónico válido', 'error');
        return;
    }
    
    // Validación de contraseña
    if (!isValidPassword(password)) {
        showNotification('La contraseña debe tener al menos 8 caracteres, incluyendo una letra mayúscula, una minúscula y un número', 'error');
        return;
    }
    
    // Verificar que las contraseñas coincidan
    if (password !== confirmPassword) {
        showNotification('Las contraseñas no coinciden', 'error');
        highlightPasswordMismatch(true);
        return;
    } else {
        highlightPasswordMismatch(false);
    }
    
    if (!termsAccepted) {
        showNotification('Debes aceptar los términos y condiciones', 'error');
        return;
    }
    
    // Simulación de registro (reemplazar con tu API real)
    const registerBtn = registerForm.querySelector('.btn');
    registerBtn.classList.add('loading');
    registerBtn.disabled = true;
    
    // Simulación de tiempo de carga
    setTimeout(() => {
        // Aquí iría la lógica real de registro con tu backend
        console.log('Registrando usuario:', { name, lastname, email, password });
        
        // Simulación de éxito
        showNotification('¡Registro exitoso! Ya puedes iniciar sesión', 'success');
        
        // Cambiar al formulario de inicio de sesión después de un breve retraso
        setTimeout(() => {
            container.classList.remove('sign-up-mode');
            registerForm.reset();
        }, 1500);
        
        registerBtn.classList.remove('loading');
        registerBtn.disabled = false;
    }, 1500);
});

// Función para validar el formato de email
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Función para validar la fortaleza de la contraseña
function isValidPassword(password) {
    // Al menos 8 caracteres, una mayúscula, una minúscula y un número
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
    return passwordRegex.test(password);
}

// Función para resaltar visualmente cuando las contraseñas no coinciden
function highlightPasswordMismatch(mismatch) {
    if (mismatch) {
        passwordInput.classList.add('password-error');
        confirmPasswordInput.classList.add('password-error');
    } else {
        passwordInput.classList.remove('password-error');
        confirmPasswordInput.classList.remove('password-error');
    }
}

// Validación en tiempo real de coincidencia de contraseñas
if (confirmPasswordInput) {
    confirmPasswordInput.addEventListener('input', function() {
        const password = passwordInput.value;
        const confirmPassword = this.value;
        
        if (password && confirmPassword) {
            if (password !== confirmPassword) {
                highlightPasswordMismatch(true);
            } else {
                highlightPasswordMismatch(false);
            }
        }
    });
}

// Función para mostrar notificaciones
function showNotification(message, type) {
    const notificationEl = document.getElementById('notification');
    const messageEl = notificationEl.querySelector('.notification-message');
    
    // Configurar el tipo de notificación
    notificationEl.className = 'notification';
    notificationEl.classList.add(type);
    notificationEl.classList.add('show');
    
    // Establecer el mensaje
    messageEl.textContent = message;
    
    // Ocultar la notificación después de 5 segundos
    setTimeout(() => {
        notificationEl.classList.remove('show');
        notificationEl.classList.add('hide');
    }, 5000);
}

// Inicializar Google Sign-In cuando la API esté cargada
window.onload = function() {
    // Verificar si la API de Google está cargada
    if (typeof google !== 'undefined' && google.accounts) {
        initGoogleSignIn();
    } else {
        console.error('Google API no está disponible');
        showNotification('No se pudo cargar la API de Google', 'error');
    }
};

// Crear imágenes SVG para las ilustraciones si no existen
function createPlaceholderSVG() {
    // Verificar si las imágenes existen
    const loginIllustration = document.querySelector('img[src="img/login-illustration.svg"]');
    const registerIllustration = document.querySelector('img[src="img/register-illustration.svg"]');
    
    // Si no existen, crear placeholders
    if (loginIllustration && !imageExists(loginIllustration.src)) {
        loginIllustration.src = createSVGDataURL('login');
    }
    
    if (registerIllustration && !imageExists(registerIllustration.src)) {
        registerIllustration.src = createSVGDataURL('register');
    }
}

// Verificar si una imagen existe
function imageExists(url) {
    const http = new XMLHttpRequest();
    http.open('HEAD', url, false);
    try {
        http.send();
        return http.status !== 404;
    } catch(e) {
        return false;
    }
}

// Crear URL de datos SVG para placeholders
function createSVGDataURL(type) {
    let color1 = '#a3c9a8';
    let color2 = '#f5b7a5';
    
    // SVG básico para ilustraciones
    const svg = type === 'login' 
        ? `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">
            <rect width="100%" height="100%" fill="#f9f9f9" />
            <circle cx="150" cy="120" r="60" fill="${color1}" />
            <rect x="90" y="190" width="120" height="80" rx="10" fill="${color2}" />
            <text x="150" y="240" font-family="Arial" font-size="16" text-anchor="middle" fill="#fff">TimeFlow</text>
          </svg>`
        : `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">
            <rect width="100%" height="100%" fill="#f9f9f9" />
            <rect x="70" y="70" width="160" height="160" rx="15" fill="${color2}" />
            <circle cx="150" cy="120" r="30" fill="#fff" />
            <rect x="110" y="160" width="80" height="10" rx="5" fill="#fff" />
            <rect x="110" y="180" width="80" height="10" rx="5" fill="#fff" />
            <text x="150" y="220" font-family="Arial" font-size="16" text-anchor="middle" fill="#fff">Registro</text>
          </svg>`;
    
    return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
}

// Ejecutar al cargar la página
document.addEventListener('DOMContentLoaded', function() {
    createPlaceholderSVG();
});