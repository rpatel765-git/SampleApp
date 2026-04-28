#include "task.h"

Task::Task(int id, std::string title, std::string description, Priority priority)
    : id(id), 
      title(std::move(title)), 
      description(std::move(description)), 
      priority(priority), 
      status(TaskStatus::Pending),
      created_at(std::chrono::system_clock::now()) {
}

std::string Task::status_to_string() const {
    switch (status) {
        case TaskStatus::Pending:
            return "Pending";
        case TaskStatus::InProgress:
            return "InProgress";
        case TaskStatus::Completed:
            return "Completed";
        default:
            return "Unknown";
    }
}

std::string Task::priority_to_string() const {
    switch (priority) {
        case Priority::Low:
            return "Low";
        case Priority::Medium:
            return "Medium";
        case Priority::High:
            return "High";
        default:
            return "Unknown";
    }
}
