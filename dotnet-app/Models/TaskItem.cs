namespace DotnetApp.Models;

/// <summary>
/// Represents a task item in the system.
/// </summary>
public class TaskItem
{
    /// <summary>
    /// Unique identifier for the task.
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Title of the task.
    /// </summary>
    public required string Title { get; set; }

    /// <summary>
    /// Detailed description of the task.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Priority level of the task (Low, Medium, High).
    /// </summary>
    public string Priority { get; set; } = "Medium";

    /// <summary>
    /// Current status of the task (Pending, InProgress, Completed).
    /// </summary>
    public string Status { get; set; } = "Pending";

    /// <summary>
    /// Timestamp when the task was created.
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
