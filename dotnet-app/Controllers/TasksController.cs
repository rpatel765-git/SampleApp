using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DotnetApp.Data;
using DotnetApp.Models;

namespace DotnetApp.Controllers;

/// <summary>
/// API controller for managing tasks.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class TasksController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ILogger<TasksController> _logger;

    public TasksController(AppDbContext context, ILogger<TasksController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get all tasks.
    /// </summary>
    /// <returns>List of all tasks.</returns>
    [HttpGet]
    [ProduceResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<TaskItem>>> GetTasks()
    {
        _logger.LogInformation("Fetching all tasks");
        var tasks = await _context.TaskItems.ToListAsync();
        return Ok(tasks);
    }

    /// <summary>
    /// Get a specific task by ID.
    /// </summary>
    /// <param name="id">The task ID.</param>
    /// <returns>The requested task.</returns>
    [HttpGet("{id}")]
    [ProduceResponseType(StatusCodes.Status200OK)]
    [ProduceResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TaskItem>> GetTask(int id)
    {
        _logger.LogInformation("Fetching task with ID: {TaskId}", id);
        var task = await _context.TaskItems.FindAsync(id);

        if (task == null)
        {
            _logger.LogWarning("Task with ID {TaskId} not found", id);
            return NotFound(new ProblemDetails
            {
                Status = StatusCodes.Status404NotFound,
                Title = "Task not found",
                Detail = $"Task with ID {id} does not exist"
            });
        }

        return Ok(task);
    }

    /// <summary>
    /// Create a new task.
    /// </summary>
    /// <param name="task">The task to create.</param>
    /// <returns>The created task.</returns>
    [HttpPost]
    [ProduceResponseType(StatusCodes.Status201Created)]
    [ProduceResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<TaskItem>> CreateTask(TaskItem task)
    {
        _logger.LogInformation("Creating new task: {Title}", task.Title);

        if (string.IsNullOrWhiteSpace(task.Title))
        {
            return BadRequest(new ProblemDetails
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "Invalid task",
                Detail = "Task title is required"
            });
        }

        task.CreatedAt = DateTime.UtcNow;
        _context.TaskItems.Add(task);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Task created with ID: {TaskId}", task.Id);
        return CreatedAtAction(nameof(GetTask), new { id = task.Id }, task);
    }

    /// <summary>
    /// Update an existing task.
    /// </summary>
    /// <param name="id">The task ID.</param>
    /// <param name="task">The updated task data.</param>
    /// <returns>No content.</returns>
    [HttpPut("{id}")]
    [ProduceResponseType(StatusCodes.Status204NoContent)]
    [ProduceResponseType(StatusCodes.Status404NotFound)]
    [ProduceResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateTask(int id, TaskItem task)
    {
        if (id != task.Id)
        {
            return BadRequest(new ProblemDetails
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "ID mismatch",
                Detail = "Task ID in URL does not match ID in request body"
            });
        }

        var existingTask = await _context.TaskItems.FindAsync(id);
        if (existingTask == null)
        {
            return NotFound(new ProblemDetails
            {
                Status = StatusCodes.Status404NotFound,
                Title = "Task not found",
                Detail = $"Task with ID {id} does not exist"
            });
        }

        existingTask.Title = task.Title;
        existingTask.Description = task.Description;
        existingTask.Priority = task.Priority;
        existingTask.Status = task.Status;

        _context.TaskItems.Update(existingTask);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Task with ID {TaskId} updated", id);
        return NoContent();
    }

    /// <summary>
    /// Delete a task.
    /// </summary>
    /// <param name="id">The task ID.</param>
    /// <returns>No content.</returns>
    [HttpDelete("{id}")]
    [ProduceResponseType(StatusCodes.Status204NoContent)]
    [ProduceResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteTask(int id)
    {
        var task = await _context.TaskItems.FindAsync(id);
        if (task == null)
        {
            return NotFound(new ProblemDetails
            {
                Status = StatusCodes.Status404NotFound,
                Title = "Task not found",
                Detail = $"Task with ID {id} does not exist"
            });
        }

        _context.TaskItems.Remove(task);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Task with ID {TaskId} deleted", id);
        return NoContent();
    }
}
