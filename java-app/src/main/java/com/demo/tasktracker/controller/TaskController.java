package com.demo.tasktracker.controller;

import com.demo.tasktracker.dto.TaskRequest;
import com.demo.tasktracker.model.TaskItem;
import com.demo.tasktracker.repository.TaskRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/tasks")
@Tag(name = "Tasks", description = "Task management endpoints")
public class TaskController {
    private final TaskRepository taskRepository;

    public TaskController(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    @GetMapping
    @Operation(summary = "Get all tasks")
    public ResponseEntity<List<TaskItem>> getAllTasks() {
        List<TaskItem> tasks = taskRepository.findAll();
        return ResponseEntity.ok(tasks);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get task by ID")
    public ResponseEntity<TaskItem> getTaskById(@PathVariable Long id) {
        Optional<TaskItem> task = taskRepository.findById(id);
        return task.map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    @Operation(summary = "Create a new task")
    public ResponseEntity<TaskItem> createTask(@Valid @RequestBody TaskRequest request) {
        TaskItem task = new TaskItem(
                request.title(),
                request.description(),
                request.priority(),
                request.status()
        );
        TaskItem savedTask = taskRepository.save(task);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedTask);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing task")
    public ResponseEntity<TaskItem> updateTask(
            @PathVariable Long id,
            @Valid @RequestBody TaskRequest request) {
        Optional<TaskItem> existingTask = taskRepository.findById(id);
        if (existingTask.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        TaskItem task = existingTask.get();
        task.setTitle(request.title());
        task.setDescription(request.description());
        task.setPriority(request.priority());
        task.setStatus(request.status());

        TaskItem updatedTask = taskRepository.save(task);
        return ResponseEntity.ok(updatedTask);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a task")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        if (!taskRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        taskRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/status/{status}")
    @Operation(summary = "Get tasks by status")
    public ResponseEntity<List<TaskItem>> getTasksByStatus(
            @PathVariable TaskItem.Status status) {
        List<TaskItem> tasks = taskRepository.findByStatus(status);
        return ResponseEntity.ok(tasks);
    }

    @GetMapping("/priority/{priority}")
    @Operation(summary = "Get tasks by priority")
    public ResponseEntity<List<TaskItem>> getTasksByPriority(
            @PathVariable TaskItem.Priority priority) {
        List<TaskItem> tasks = taskRepository.findByPriority(priority);
        return ResponseEntity.ok(tasks);
    }
}
