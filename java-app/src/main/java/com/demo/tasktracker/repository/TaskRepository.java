package com.demo.tasktracker.repository;

import com.demo.tasktracker.model.TaskItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<TaskItem, Long> {
    List<TaskItem> findByStatus(TaskItem.Status status);
    List<TaskItem> findByPriority(TaskItem.Priority priority);
}
