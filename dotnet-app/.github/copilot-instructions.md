# GitHub Copilot Instructions for .NET Projects

## Language and Framework Standards

### C# and .NET

- **Target Framework**: .NET 8.0 (or latest stable)
- **C# Version**: 12 with nullable reference types enabled (`<Nullable>enable</Nullable>`)
- **Implicit Usings**: Enable implicit using directives (`<ImplicitUsings>enable</ImplicitUsings>`)
- **Record Types**: Use records for DTOs and immutable data structures
- **Pattern Matching**: Leverage C# 12 pattern matching features for cleaner code

### Async/Await Patterns

- **All I/O Operations**: Use `async/await` for all I/O-bound operations (database queries, HTTP calls, file operations)
- **Task-Based**: Return `Task` or `Task<T>` from async methods (not `void`)
- **ConfigureAwait**: Use `.ConfigureAwait(false)` in libraries to avoid UI thread capture
- **Proper Naming**: Method names should end with `Async` if they return `Task` or `Task<T>`

### Entity Framework Core

- **DbContext**: Use typed DbContext with DbSet properties for all entities
- **Repository Pattern**: Implement repository interfaces for data access abstraction
  ```csharp
  public interface ITaskRepository
  {
      Task<IEnumerable<TaskItem>> GetAllAsync();
      Task<TaskItem?> GetByIdAsync(int id);
      Task AddAsync(TaskItem task);
      Task UpdateAsync(TaskItem task);
      Task DeleteAsync(int id);
  }
  ```
- **Query Performance**: Use `.AsNoTracking()` for read-only queries
- **Include Relationships**: Use `.Include()` to eager-load related data when needed
- **Dependency Injection**: Inject `DbContext` or repositories via constructor, not service locator pattern

### Validation

- **DataAnnotations**: Use `System.ComponentModel.DataAnnotations` for simple validation
  ```csharp
  public class TaskItem
  {
      [Required(ErrorMessage = "Title is required")]
      [StringLength(200, MinimumLength = 1)]
      public required string Title { get; set; }
  }
  ```
- **FluentValidation**: Use FluentValidation for complex business logic validation
  ```csharp
  public class TaskValidator : AbstractValidator<TaskItem>
  {
      public TaskValidator()
      {
          RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
          RuleFor(x => x.Priority).Must(BeValidPriority);
      }
  }
  ```

### Controllers and API Design

- **Thin Controllers**: Controllers should delegate business logic to services
  ```csharp
  [ApiController]
  [Route("api/[controller]")]
  public class TasksController : ControllerBase
  {
      private readonly ITaskService _service;
      
      public TasksController(ITaskService service) => _service = service;
      
      [HttpGet("{id}")]
      public async Task<ActionResult<TaskDto>> GetTask(int id)
      {
          var task = await _service.GetTaskAsync(id);
          return Ok(task);
      }
  }
  ```
- **REST Conventions**:
  - Use plural nouns for route names: `/api/tasks`, not `/api/task`
  - Use HTTP verbs correctly: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`
  - Return appropriate status codes: 200 (OK), 201 (Created), 204 (No Content), 400 (Bad Request), 404 (Not Found)
- **Route Attributes**: Use `[Route]`, `[HttpGet]`, `[HttpPost]`, etc. for explicit routing
- **Response Types**: Decorate endpoints with `[ProduceResponseType]` for Swagger documentation

### Service Layer

- **Single Responsibility**: Each service should handle one domain concern
- **Dependency Injection**: Constructor injection for all dependencies
  ```csharp
  public class TaskService : ITaskService
  {
      private readonly ITaskRepository _repository;
      private readonly ILogger<TaskService> _logger;
      
      public TaskService(ITaskRepository repository, ILogger<TaskService> logger)
      {
          _repository = repository;
          _logger = logger;
      }
  }
  ```
- **Business Logic**: Keep business logic out of controllers and in service layer

### Error Handling

- **ProblemDetails (RFC 7807)**: Use `ProblemDetails` for error responses
  ```csharp
  if (task == null)
  {
      return NotFound(new ProblemDetails
      {
          Status = StatusCodes.Status404NotFound,
          Title = "Task not found",
          Detail = $"Task with ID {id} does not exist"
      });
  }
  ```
- **Exception Handling**: Use custom exceptions for domain-specific errors
  ```csharp
  public class TaskNotFoundException : Exception
  {
      public TaskNotFoundException(int taskId) 
          : base($"Task with ID {taskId} not found") { }
  }
  ```
- **Logging**: Log exceptions at appropriate levels (Error, Warning, Information)

### Testing with xUnit and FluentAssertions

- **Test Naming**: Use `MethodName_Scenario_ExpectedResult` pattern
  ```csharp
  [Fact]
  public async Task GetTask_WithValidId_ReturnsOkResult()
  ```
- **Arrange-Act-Assert**: Structure all tests with AAA pattern
  ```csharp
  public async Task CreateTask_WithValidData_ReturnsCreatedAtAction()
  {
      // Arrange
      var context = CreateDbContext();
      var service = new TaskService(context);
      var newTask = new TaskItem { Title = "Test" };
      
      // Act
      var result = await service.CreateTaskAsync(newTask);
      
      // Assert
      result.Should().NotBeNull();
      result.Title.Should().Be("Test");
  }
  ```
- **Fluent Assertions**: Use FluentAssertions for readable assertions
  ```csharp
  result.Should().BeOfType<OkObjectResult>();
  tasks.Should().HaveCount(2);
  model.Title.Should().Be("Expected Title");
  exception.Message.Should().Contain("required");
  ```
- **Mocking**: Use Moq for mocking dependencies
  ```csharp
  var mockRepository = new Mock<ITaskRepository>();
  mockRepository
      .Setup(r => r.GetByIdAsync(It.IsAny<int>()))
      .ReturnsAsync(expectedTask);
  ```

### API Documentation

- **Swagger/OpenAPI**: All public endpoints must have XML documentation comments
  ```csharp
  /// <summary>
  /// Get a task by ID.
  /// </summary>
  /// <param name="id">The task ID.</param>
  /// <returns>The task details.</returns>
  [HttpGet("{id}")]
  public async Task<ActionResult<TaskDto>> GetTask(int id)
  ```
- **Enable Documentation**: Configure Swagger in `Program.cs`:
  ```csharp
  builder.Services.AddSwaggerGen();
  // In app configuration
  app.UseSwagger();
  app.UseSwaggerUI();
  ```

### Dependency Injection

- **Constructor Injection**: Always use constructor injection, never service locator
- **Lifetime Management**:
  - `AddTransient()` — New instance each time
  - `AddScoped()` — New instance per HTTP request (for DbContext, repositories)
  - `AddSingleton()` — Single instance for application lifetime (for stateless services)
- **Configuration**:
  ```csharp
  builder.Services.AddScoped<ITaskRepository, TaskRepository>();
  builder.Services.AddScoped<ITaskService, TaskService>();
  builder.Services.AddDbContext<AppDbContext>(options =>
      options.UseInMemoryDatabase("TasksDb"));
  ```

## Project Structure

```
Project/
├── Program.cs           — Application startup
├── appsettings.json     — Configuration
├── Controllers/         — API endpoints
├── Services/            — Business logic
├── Repositories/        — Data access
├── Models/              — Domain models
├── Data/
│   └── AppDbContext.cs  — EF Core DbContext
├── Dtos/                — Data transfer objects
└── Tests/               — Unit tests
```

## Code Style Guidelines

- **Naming Conventions**:
  - `PascalCase` for class names, method names, properties
  - `camelCase` for local variables and parameters
  - `PascalCase` for constants
  - Prefix interfaces with `I`: `ITaskService`, `IRepository`
- **Null Coalescing**: Use `??` and `?.` operators
- **String Interpolation**: Use `$"text {variable}"` instead of `string.Format()`
- **LINQ**: Prefer method chain syntax over query syntax for consistency
- **Comments**: Use `///` XML comments for public APIs, `//` for implementation details

## Performance Considerations

- **Database Queries**: Minimize database round-trips, use batch operations
- **Async All The Way**: Don't block on async calls (avoid `.Result` or `.Wait()`)
- **Caching**: Cache frequently accessed data appropriately
- **Logging**: Use structured logging with context information
