# GitHub Copilot Instructions for Task Tracker

This document provides guidance for using GitHub Copilot to work on the Task Tracker application.

## Java and Language

- **Java Version**: Use Java 21+
- **Records for DTOs**: Use Java records for Data Transfer Objects (DTOs) to reduce boilerplate
  - Example: `public record TaskRequest(String title, String description) {}`
- **Naming Conventions**:
  - Classes: PascalCase (e.g., `TaskController`, `TaskItem`)
  - Variables and methods: camelCase (e.g., `taskId`, `getTaskTitle()`)
  - Constants: UPPER_SNAKE_CASE (e.g., `MAX_PRIORITY`)
  - Packages: lowercase with dots (e.g., `com.demo.tasktracker`)

## Spring Boot Framework

- **Version**: Spring Boot 3.2+
- **Jakarta EE Annotations**: Use `jakarta.*` annotations (not `javax.*`)
  - Example: `@jakarta.persistence.Entity`, `@jakarta.validation.Valid`
- **Application Structure**:
  - **Controllers**: Handle HTTP requests and delegate to services
  - **Services**: Contain business logic (create a service layer if adding complex logic)
  - **Repositories**: Use Spring Data JPA for data access
  - **DTOs**: Use records for request/response objects with `@Valid` validation
  - **Models/Entities**: JPA entities with proper annotations

## Data Persistence

- **Spring Data JPA**: Use repository pattern with `JpaRepository` interface
  - Example: `public interface TaskRepository extends JpaRepository<TaskItem, Long> {}`
- **Custom Queries**: Add custom finder methods in repositories
  - Example: `List<TaskItem> findByStatus(TaskItem.Status status);`
- **Entity Lifecycle**: Use `@PrePersist` and `@PreUpdate` for timestamps
- **Relationships**: Follow proper JPA relationship annotations when modeling associations

## Input Validation

- **Jakarta Bean Validation**: Use annotations from `jakarta.validation.constraints`
  - `@NotBlank`, `@NotNull`, `@NotEmpty`, `@Size`, `@Email`, `@Min`, `@Max`
- **Custom Validators**: Create custom constraint annotations if needed
- **Record Usage**: Define validation annotations in record components
- **Error Handling**: Invalid input should return HTTP 400 with validation error details

## Dependency Injection

- **Constructor Injection**: Always use constructor injection for dependencies (not field injection)
  - Example:
    ```java
    @RestController
    public class TaskController {
        private final TaskRepository taskRepository;
        
        public TaskController(TaskRepository taskRepository) {
            this.taskRepository = taskRepository;
        }
    }
    ```
- **Avoid Field Injection**: Never use `@Autowired` on fields

## REST Controllers

- **Naming**: Suffix class names with `Controller`
- **Request Mapping**: Use `@RestController` and `@RequestMapping` annotations
- **HTTP Methods**: Use appropriate HTTP verbs with `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`
- **Response Entity**: Return `ResponseEntity` for flexible status codes and headers
- **Status Codes**:
  - 200 OK: Successful GET, PUT
  - 201 Created: Successful POST
  - 204 No Content: Successful DELETE
  - 400 Bad Request: Invalid input
  - 404 Not Found: Resource not found
  - 500 Internal Server Error: Server-side errors
- **API Documentation**: Add `@Operation`, `@Tag`, and other SpringDoc annotations for Swagger

## Error Handling

- **Global Exception Handler**: Create `@ControllerAdvice` class for centralized error handling
- **ProblemDetail**: Use Spring's `ProblemDetail` for standardized error responses (RFC 7807)
- **Validation Errors**: Include validation errors in error response
- **Example Structure**:
  ```java
  @ControllerAdvice
  public class GlobalExceptionHandler {
      @ExceptionHandler(ResourceNotFoundException.class)
      public ResponseEntity<ProblemDetail> handleNotFound(ResourceNotFoundException ex) {
          ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.NOT_FOUND);
          detail.setTitle("Resource Not Found");
          detail.setDetail(ex.getMessage());
          return ResponseEntity.status(404).body(detail);
      }
  }
  ```

## Testing

- **Framework**: JUnit 5 (Jupiter)
- **Controller Tests**: Use `@SpringBootTest` with `@AutoConfigureMockMvc` and `MockMvc`
- **Test Structure**:
  - Follow Arrange-Act-Assert (AAA) pattern
  - Use descriptive test method names: `testGetAllTasks()`, `testCreateTaskWithInvalidData()`
- **Mocking**: Use Mockito when needed for isolated unit tests
- **Example**:
  ```java
  @SpringBootTest
  @AutoConfigureMockMvc
  class TaskControllerTest {
      @Autowired
      private MockMvc mockMvc;
      
      @Test
      void testGetAllTasks() throws Exception {
          mockMvc.perform(get("/api/tasks"))
              .andExpect(status().isOk())
              .andExpect(jsonPath("$").isArray());
      }
  }
  ```

## API Documentation

- **SpringDoc OpenAPI**: Use for automatic API documentation
- **Annotations**:
  - `@Operation`: Describe endpoint operations
  - `@Tag`: Group related endpoints
  - `@Parameter`: Document request parameters
  - `@RequestBody`: Document request body
  - `@ApiResponse`: Document response status codes
- **Swagger UI**: Available at `/swagger-ui.html` for interactive testing
- **OpenAPI Spec**: Available at `/v3/api-docs`

## Configuration

- **application.properties**: Configure application settings
  - Database: Connection strings, DDL strategy (`ddl-auto`)
  - Logging: Log levels for packages
  - Server: Port, context path
  - Features: Enable/disable Swagger UI, H2 console, etc.

## Performance Considerations

- **Lazy Loading**: Be mindful of JPA lazy loading in HTTP responses
- **Pagination**: Add pagination for endpoints that return large collections
- **Caching**: Consider `@Cacheable` for frequently accessed data
- **Query Optimization**: Use `@Query` annotations for complex queries

## Code Quality

- **Comments**: Use Javadoc for public classes and methods
- **Logging**: Use SLF4J logger for debugging and troubleshooting
- **Immutability**: Prefer immutable objects (use records for DTOs)
- **Exception Handling**: Create custom exceptions for domain-specific errors
- **Configuration**: Externalize configuration using `application.properties` or environment variables

## Build and Deployment

- **Maven**: Use Maven for building and dependency management
- **Maven Profile**: Consider profiles for different environments (dev, test, prod)
- **Spring Boot Executable JAR**: Application should be packaged as executable JAR
- **Actuator**: Add Spring Boot Actuator endpoints for health checks and metrics (if needed)

## Copilot Usage Tips

- Ask Copilot to generate controller tests using the AAA pattern
- Request entity classes with proper JPA annotations and lifecycle methods
- Use Copilot to create repository queries for complex filtering
- Ask for validation examples using Jakarta Bean Validation
- Request error handling with `@ControllerAdvice` and `ProblemDetail`
- Get help with Spring Data JPA relationships and mappings
