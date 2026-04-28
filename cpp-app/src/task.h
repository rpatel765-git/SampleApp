#pragma once

#include <string>
#include <chrono>

enum class TaskStatus {
    Pending,
    InProgress,
    Completed
};

enum class Priority {
    Low,
    Medium,
    High
};

/**
 * @brief Represents a single task with ID, title, description, priority, and status
 * 
 * A Task is an immutable data structure that tracks work items with timestamps.
 */
class Task {
public:
    /// Task unique identifier
    int id;
    
    /// Task title/name
    std::string title;
    
    /// Detailed task description
    std::string description;
    
    /// Task priority level
    Priority priority;
    
    /// Current task status
    TaskStatus status;
    
    /// Timestamp when task was created
    std::chrono::system_clock::time_point created_at;

    /**
     * @brief Construct a new Task object
     * @param id Unique task identifier
     * @param title Task title
     * @param description Task description
     * @param priority Priority level (default: Medium)
     */
    Task(int id, std::string title, std::string description, 
         Priority priority = Priority::Medium);

    /**
     * @brief Convert task status to human-readable string
     * @return String representation of task status
     */
    std::string status_to_string() const;

    /**
     * @brief Convert priority to human-readable string
     * @return String representation of priority level
     */
    std::string priority_to_string() const;
};
