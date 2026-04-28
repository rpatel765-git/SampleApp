#pragma once

#include "task.h"
#include <vector>
#include <memory>
#include <optional>

/**
 * @brief Manages a collection of tasks with add, list, and complete operations
 * 
 * TaskManager uses std::vector for efficient task storage and RAII principles
 * for automatic resource management.
 */
class TaskManager {
public:
    /**
     * @brief Construct a new TaskManager object
     */
    TaskManager();

    /**
     * @brief Add a new task to the manager
     * @param title Task title
     * @param description Task description
     * @param priority Task priority (default: Medium)
     * @return ID of the newly created task
     */
    int add_task(std::string_view title, std::string_view description, 
                 Priority priority = Priority::Medium);

    /**
     * @brief List all tasks, optionally filtered by status
     * @param filter_status Optional status to filter by
     * @return Vector of task references matching the filter
     */
    std::vector<std::reference_wrapper<const Task>> list_tasks(
        std::optional<TaskStatus> filter_status = std::nullopt) const;

    /**
     * @brief Mark a task as completed
     * @param task_id ID of the task to complete
     * @return true if task was found and completed, false otherwise
     */
    bool complete_task(int task_id);

    /**
     * @brief Remove a task from the manager
     * @param task_id ID of the task to remove
     * @return true if task was found and removed, false otherwise
     */
    bool remove_task(int task_id);

    /**
     * @brief Get the total number of tasks
     * @return Count of all tasks in the manager
     */
    constexpr size_t task_count() const { return tasks.size(); }

private:
    /// Collection of managed tasks
    std::vector<std::unique_ptr<Task>> tasks;
    
    /// Next task ID counter
    int next_id;
};
