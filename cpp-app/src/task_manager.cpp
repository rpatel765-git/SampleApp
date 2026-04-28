#include "task_manager.h"

TaskManager::TaskManager() : next_id(1) {
}

int TaskManager::add_task(std::string_view title, std::string_view description, Priority priority) {
    auto task = std::make_unique<Task>(
        next_id, 
        std::string(title), 
        std::string(description), 
        priority
    );
    int id = next_id;
    tasks.push_back(std::move(task));
    ++next_id;
    return id;
}

std::vector<std::reference_wrapper<const Task>> TaskManager::list_tasks(
    std::optional<TaskStatus> filter_status) const {
    std::vector<std::reference_wrapper<const Task>> result;
    
    for (const auto& task : tasks) {
        if (!filter_status.has_value() || task->status == filter_status.value()) {
            result.push_back(std::cref(*task));
        }
    }
    
    return result;
}

bool TaskManager::complete_task(int task_id) {
    for (auto& task : tasks) {
        if (task->id == task_id) {
            task->status = TaskStatus::Completed;
            return true;
        }
    }
    return false;
}

bool TaskManager::remove_task(int task_id) {
    auto it = tasks.begin();
    while (it != tasks.end()) {
        if ((*it)->id == task_id) {
            tasks.erase(it);
            return true;
        }
        ++it;
    }
    return false;
}
