<?php
require_once '../Controlador/conexion.php';
?>
<?php

// Handle different actions
$action = $_GET['action'] ?? '';

switch ($action) {
    case 'get_tasks':
        getTasks();
        break;
    case 'add_task':
        addTask();
        break;
    case 'toggle_task':
        toggleTask();
        break;
    case 'delete_task':
        deleteTask();
        break;
    case 'search_tasks':
        searchTasks();
        break;
    default:
        echo json_encode(['error' => 'Invalid action']);
}

function getTasks() {
    global $conn;
    $sql = "SELECT * FROM tareas ORDER BY fecha DESC";
    $result = $conn->query($sql);
    $tasks = [];

    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $tasks[] = $row;
        }
    }

    echo json_encode($tasks);
}

function addTask() {
    global $conn;
    $title = $_POST['title'];
    $description = $_POST['description'];
    $date = $_POST['date'];
    $type = $_POST['type'];

    $sql = "INSERT INTO tareas (titulo, descripcion, fecha, tipo) VALUES (?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssss", $title, $description, $date, $type);

    if ($stmt->execute()) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }

    $stmt->close();
}

function toggleTask() {
    global $conn;
    $id = $_GET['id'];

    $sql = "UPDATE tareas SET completada = NOT completada WHERE id_tarea = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }

    $stmt->close();
}

function deleteTask() {
    global $conn;
    $id = $_GET['id'];

    $sql = "DELETE FROM tareas WHERE id_tarea = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }

    $stmt->close();
}

function searchTasks() {
    global $conn;
    $term = $_GET['term'];

    $sql = "SELECT * FROM tareas WHERE titulo LIKE ? OR descripcion LIKE ? ORDER BY fecha DESC";
    $stmt = $conn->prepare($sql);
    $searchTerm = "%$term%";
    $stmt->bind_param("ss", $searchTerm, $searchTerm);
    $stmt->execute();
    $result = $stmt->get_result();

    $tasks = [];
    while ($row = $result->fetch_assoc()) {
        $tasks[] = $row;
    }

    echo json_encode($tasks);
    $stmt->close();
}

$conn->close();
?>