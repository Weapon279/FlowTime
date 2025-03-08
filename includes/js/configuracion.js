document.addEventListener('DOMContentLoaded', function() {
    const personalInfoForm = document.getElementById('personalInfoForm');
    const changePasswordForm = document.getElementById('changePasswordForm');
    const logoutBtn = document.getElementById('logoutBtn');

    personalInfoForm.addEventListener('submit', function(e) {
        e.preventDefault();
        // Aquí iría la lógica para guardar los cambios en la información personal
        alert('Información personal actualizada');
    });

    changePasswordForm.addEventListener('submit', function(e) {
        e.preventDefault();
        const newPassword = document.getElementById('newPassword').value;
        const confirmPassword = document.getElementById('confirmPassword').value;

        if (newPassword !== confirmPassword) {
            alert('Las contraseñas no coinciden');
            return;
        }

        // Aquí iría la lógica para cambiar la contraseña
        alert('Contraseña cambiada exitosamente');
    });

    logoutBtn.addEventListener('click', function() {
        if (confirm('¿Estás seguro de que quieres cerrar sesión?')) {
            // Aquí iría la lógica para cerrar sesión
            alert('Sesión cerrada');
            // Redirigir al usuario a la página de inicio de sesión
            // window.location.href = 'login.html';
        }
    });
});