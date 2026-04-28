using Xunit;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using DotnetApp.Controllers;
using DotnetApp.Data;
using DotnetApp.Models;

namespace Tests;

/// <summary>
/// Unit tests for TasksController.
/// </summary>
public class TasksControllerTests
{
    private AppDbContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    private TasksController CreateController(AppDbContext context)
    {
        var mockLogger = new Mock<ILogger<TasksController>>();
        return new TasksController(context, mockLogger.Object);
    }

    [Fact]
    public async Task GetTasks_ReturnsAllTasks()
    {
        // Arrange
        var context = CreateDbContext();
        var controller = CreateController(context);

        var task1 = new TaskItem { Title = "Task 1", Description = "First task" };
        var task2 = new TaskItem { Title = "Task 2", Description = "Second task" };
        context.TaskItems.Add(task1);
        context.TaskItems.Add(task2);
        await context.SaveChangesAsync();

        // Act
        var result = await controller.GetTasks();

        // Assert
        result.Value.Should().HaveCount(2);
    }

    [Fact]
    public async Task CreateTask_WithValidData_ReturnsCreatedAtAction()
    {
        // Arrange
        var context = CreateDbContext();
        var controller = CreateController(context);
        var newTask = new TaskItem { Title = "New Task", Description = "Test task" };

        // Act
        var result = await controller.CreateTask(newTask);

        // Assert
        result.Should().NotBeNull();
        var createdResult = result.Result as CreatedAtActionResult;
        createdResult?.ActionName.Should().Be(nameof(TasksController.GetTask));
    }

    [Fact]
    public async Task GetTask_WithValidId_ReturnsTask()
    {
        // Arrange
        var context = CreateDbContext();
        var controller = CreateController(context);
        var task = new TaskItem { Title = "Test Task" };
        context.TaskItems.Add(task);
        await context.SaveChangesAsync();

        // Act
        var result = await controller.GetTask(task.Id);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult?.Value.Should().BeOfType<TaskItem>();
        ((TaskItem)okResult!.Value!).Title.Should().Be("Test Task");
    }

    [Fact]
    public async Task DeleteTask_WithValidId_RemovesTask()
    {
        // Arrange
        var context = CreateDbContext();
        var controller = CreateController(context);
        var task = new TaskItem { Title = "Task to delete" };
        context.TaskItems.Add(task);
        await context.SaveChangesAsync();

        // Act
        var result = await controller.DeleteTask(task.Id);

        // Assert
        result.Should().BeOfType<NoContentResult>();
        var deletedTask = await context.TaskItems.FindAsync(task.Id);
        deletedTask.Should().BeNull();
    }
}
