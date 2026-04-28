package com.demo.tasktracker.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import com.demo.tasktracker.model.TaskItem;

public record TaskRequest(
        @NotBlank(message = "Title is required")
        String title,

        String description,

        @NotNull(message = "Priority is required")
        TaskItem.Priority priority,

        @NotNull(message = "Status is required")
        TaskItem.Status status
) {
}
