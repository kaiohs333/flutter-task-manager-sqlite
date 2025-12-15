const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;
const dbPath = path.join(__dirname, 'db.json');

// --- Funções de Banco de Dados ---

const readDatabase = () => {
    try {
        if (fs.existsSync(dbPath)) {
            const data = fs.readFileSync(dbPath);
            // Se o arquivo estiver vazio, retorne um objeto padrão
            if (data.length === 0) {
                return { tasks: [] };
            }
            return JSON.parse(data);
        }
    } catch (error) {
        console.error('Error reading database file:', error);
    }
    // Se o arquivo não existe ou está corrompido, retorna um estado inicial
    return { tasks: [] };
};

const writeDatabase = (data) => {
    try {
        fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
    } catch (error) {
        console.error('Error writing to database file:', error);
    }
};

// --- Inicialização e Middlewares ---

let db = readDatabase();

app.use(cors());
app.use(bodyParser.json());

app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    if (req.body && Object.keys(req.body).length > 0) {
        console.log('Body:', req.body);
    }
    next();
});

// --- Rotas ---

// Obter todas as tarefas
app.get('/tasks', (req, res) => {
    console.log(`Returning ${db.tasks.length} tasks.`);
    res.json(db.tasks);
});

// Criar uma nova tarefa
app.post('/tasks', (req, res) => {
    const now = new Date().toISOString();
    const newTask = {
        ...req.body,
        id: req.body.id || uuidv4(),
        createdAt: req.body.createdAt || now,
        updatedAt: now,
    };
    db.tasks.push(newTask);
    writeDatabase(db);
    console.log('Created new task:', newTask.id);
    res.status(201).json(newTask);
});

// Atualizar uma tarefa
app.put('/tasks/:id', (req, res) => {
    const { id } = req.params;
    const taskIndex = db.tasks.findIndex(t => t.id === id);

    if (taskIndex === -1) {
        console.log(`Task with id ${id} not found for update.`);
        return res.status(404).json({ message: 'Task not found' });
    }

    const existingTask = db.tasks[taskIndex];
    const incomingUpdatedAt = new Date(req.body.updatedAt);
    const existingUpdatedAt = new Date(existingTask.updatedAt);

    // Implementação da lógica Last-Write-Wins (LWW) no servidor
    if (incomingUpdatedAt.getTime() <= existingUpdatedAt.getTime()) {
        console.log(`Conflict: Incoming update for task ${id} is older or same as existing.`);
        return res.status(409).json({ message: 'Conflict: Existing version is newer or same.' });
    }

    const updatedTask = {
        ...existingTask,
        ...req.body,
        updatedAt: new Date().toISOString(), // O servidor ainda define o updatedAt para a hora atual do servidor após a validação LWW
    };

    db.tasks[taskIndex] = updatedTask;
    writeDatabase(db);
    console.log('Updated task:', id);
    res.json(updatedTask);
});

// Deletar uma tarefa
app.delete('/tasks/:id', (req, res) => {
    const { id } = req.params;
    const initialLength = db.tasks.length;
    db.tasks = db.tasks.filter(t => t.id !== id);

    if (db.tasks.length === initialLength) {
        console.log(`Task with id ${id} not found for deletion.`);
        return res.status(404).json({ message: 'Task not found' });
    }

    writeDatabase(db);
    console.log('Deleted task:', id);
    res.status(200).json({ message: 'Task deleted successfully' });
});


app.listen(port, () => {
    console.log(`Mock server running at http://localhost:${port}`);
    console.log('Database file is located at:', dbPath);
    console.log('Available endpoints:');
    console.log('  GET    /tasks');
    console.log('  POST   /tasks');
    console.log('  PUT    /tasks/:id');
    console.log('  DELETE /tasks/:id');
});
