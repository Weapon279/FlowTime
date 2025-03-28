function updateGreeting() {
    const hour = new Date().getHours();
    let greeting;
    
    if (hour >= 5 && hour < 12) {
        greeting = "Buenos días";
    } else if (hour >= 12 && hour < 18) {
        greeting = "Buenas tardes";
    } else {
        greeting = "Buenas noches";
    }
    
    document.getElementById('userGreeting').textContent = `${greeting},`;
}

// Función placeholder para el logout
function logout() {
    // Aquí iría tu lógica de cerrar sesión
    console.log("Cerrando sesión...");
}

// Actualizar el saludo al cargar la página
window.onload = function() {
    updateGreeting();
    // Aquí podrías agregar código para cargar el nombre real del usuario y su plan
    // Por ejemplo:
    // document.getElementById('userName').textContent = "Juan Pérez";
    // document.getElementById('userPlan').textContent = "Plan: Premium";
};