#include "task_manager.h"
#include <iostream>
#include <string>

void print_usage() {
    std::cout << "TaskTracker - Simple CLI Task Manager\n\n"
              << "Usage:\n"
              << "  task_tracker add <title> <description> [priority]\n"
              << "  task_tracker list [status]\n"
              << "  task_tracker complete <task_id>\n"
              << "  task_tracker remove <task_id>\n"
              << "  task_tracker help\n\n"
              << "Priority levels: low, medium (default), high\n"
              << "Status filters: pending, in_progress, completed\n";
}

Priority parse_priority(std::string_view priority_str) {
    if (priority_str == "low") return Priority::Low;
    if (priority_str == "high") return Priority::High;
    return Priority::Medium;
}

TaskStatus parse_status(std::string_view status_str) {
    if (status_str == "in_progress") return TaskStatus::InProgress;
    if (status_str == "completed") return TaskStatus::Completed;
    return TaskStatus::Pending;
}

void print_task(const Task& task) {
    std::cout << "  [" << task.id << "] " << task.title 
              << " | Priority: " << task.priority_to_string()
              << " | Status: " << task.status_to_string() << "\n"
              << "      " << task.description << "\n";
}

int main(int argc, char* argv[]) {
    TaskManager manager;

    if (argc < 2) {
        print_usage();
        return 0;
    }

    std::string command = argv[1];

    if (command == "help") {
        print_usage();
    }
    else if (command == "add" && argc >= 4) {
        std::string title = argv[2];
        std::string description = argv[3];
        Priority priority = (argc >= 5) ? parse_priority(argv[4]) : Priority::Medium;
        
        int id = manager.add_task(title, description, priority);
        std::cout << "Task created with ID: " << id << "\n";
    }
    else if (command == "list") {
        std::optional<TaskStatus> filter;
        if (argc >= 3) {
            filter = parse_status(argv[2]);
        }
        
        auto tasks = manager.list_tasks(filter);
        
        if (tasks.empty()) {
            std::cout << "No tasks found.\n";
        } else {
            std::cout << "Tasks:\n";
            for (const auto& task : tasks) {
                print_task(task.get());
            }
        }
    }
    else if (command == "complete" && argc >= 3) {
        int task_id = std::stoi(argv[2]);
        if (manager.complete_task(task_id)) {
            std::cout << "Task " << task_id << " marked as completed.\n";
        } else {
            std::cout << "Task " << task_id << " not found.\n";
        }
    }
    else if (command == "remove" && argc >= 3) {
        int task_id = std::stoi(argv[2]);
        if (manager.remove_task(task_id)) {
            std::cout << "Task " << task_id << " removed.\n";
        } else {
            std::cout << "Task " << task_id << " not found.\n";
        }
    }
    else {
        std::cerr << "Unknown command or invalid arguments.\n";
        print_usage();
        return 1;
    }

    return 0;
}
