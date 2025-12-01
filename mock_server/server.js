
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json());

// In-memory database
let tasks = [
    {
        id: 'd9a7e7de-093b-4c72-9998-d77489456a3b',
        title: 'Task from Server 1',
        description: 'This task was pre-loaded from the server.',
        isCompleted: false,
        createdAt: '2025-11-29T10:00:00.000Z',
        updatedAt: '2025-11-29T10:00:00.000Z',
        imagePath: null,
        location: null,
    },
    {
        id: 'a8c6c4b1-1b2f-4b3a-9c0d-3f7e9b6a1b3a',
        title: 'Task from Server 2',
        description: 'Another task from the server.',
        isCompleted: false,
        createdAt: '2025-11-29T11:00:00.000Z',
        updatedAt: '2025-11-29T11:00:00.000Z',
        imagePath: null,
        location: null,
    },
];

// Middleware to log requests
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    if (Object.keys(req.body).length > 0) {
        console.log('Body:', req.body);
    }
    next();
});

// --- Routes ---

// Get all tasks
app.get('/tasks', (req, res) => {
    console.log(`Returning ${tasks.length} tasks.`);
    res.json(tasks);
});

// Create a new task
app.post('/tasks', (req, res) => {
    const now = new Date().toISOString();
    const newTask = {
        ...req.body,
        id: req.body.id || uuidv4(), // Use client-provided ID if available
        createdAt: now,
        updatedAt: now,
    };
    tasks.push(newTask);
    console.log('Created new task:', newTask.id);
    res.status(201).json(newTask);
});

// Update a task
app.put('/tasks/:id', (req, res) => {
    const { id } = req.params;
    const taskIndex = tasks.findIndex(t => t.id === id);

    if (taskIndex === -1) {
        // If task not found, treat it as a new creation (upsert)
        const now = new Date().toISOString();
        const newTask = {
            ...req.body,
            id: id,
            createdAt: now, // Or maybe respect a client-sent createdAt? For LWW, updatedAt is key.
            updatedAt: now,
        };
        tasks.push(newTask);
        console.log(`Task with id ${id} not found. Created new task.`);
        return res.status(201).json(newTask);
    }

    const existingTask = tasks[taskIndex];
    const now = new Date().toISOString();

    // LWW check could be done here, but for a mock server, we'll just update.
    // The client is responsible for the LWW logic.
    const updatedTask = {
        ...existingTask,
        ...req.body,
        updatedAt: now, // Always set a new updatedAt timestamp
    };

    tasks[taskIndex] = updatedTask;
    console.log('Updated task:', id);
    res.json(updatedTask);
});

// Delete a task
app.delete('/tasks/:id', (req, res) => {
    const { id } = req.params;
    const initialLength = tasks.length;
    tasks = tasks.filter(t => t.id !== id);

    if (tasks.length === initialLength) {
        console.log(`Task with id ${id} not found for deletion.`);
        return res.status(404).json({ message: 'Task not found' });
    }
    
    console.log('Deleted task:', id);
    res.status(200).json({ message: 'Task deleted successfully' });
});


app.listen(port, () => {
    console.log(`Mock server running at http://localhost:${port}`);
    console.log('Available endpoints:');
    console.log('  GET    /tasks');
    console.log('  POST   /tasks');
    console.log('  PUT    /tasks/:id');
    console.log('  DELETE /tasks/:id');
});
