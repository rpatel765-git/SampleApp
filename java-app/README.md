# Task Tracker - Java Spring Boot Demo App

A minimal Java Spring Boot 3 application for GitHub Copilot Deep-Dive Part 2 live demos.

## Quick Start

### Prerequisites
- Java 21+
- Maven 3.8+

### Build
```bash
mvn clean install
```

### Run
```bash
mvn spring-boot:run
```

The application will be available at `http://localhost:8080`

## API Documentation

Once running, access the interactive API documentation:
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **OpenAPI Spec**: http://localhost:8080/v3/api-docs

## Database

This demo uses an in-memory H2 database. To view the database console:
- **H2 Console**: http://localhost:8080/h2-console
- **JDBC URL**: `jdbc:h2:mem:taskdb`
- **Username**: `sa`
- **Password**: (leave blank)

## Project Structure

```
src/
├── main/
│   ├── java/com/demo/tasktracker/
│   │   ├── TaskTrackerApplication.java      # Main application class
│   │   ├── controller/
│   │   │   └── TaskController.java         # REST API endpoints
│   │   ├── model/
│   │   │   └── TaskItem.java              # JPA entity
│   │   ├── repository/
│   │   │   └── TaskRepository.java        # Data access layer
│   │   └── dto/
│   │       └── TaskRequest.java           # Request DTO with validation
│   └── resources/
│       └── application.properties          # Configuration
└── test/
    └── java/com/demo/tasktracker/
        └── controller/
            └── TaskControllerTest.java     # Controller tests
```

## Key Technologies

- **Spring Boot 3.2** - Modern application framework
- **Spring Data JPA** - Data persistence with Hibernate
- **H2 Database** - In-memory SQL database
- **SpringDoc OpenAPI** - Automatic API documentation with Swagger UI
- **Jakarta Validation** - Bean validation with annotations
- **JUnit 5** - Testing framework
- **MockMvc** - Spring MVC testing

## Features

- CRUD operations for tasks
- Filter tasks by status and priority
- Input validation with Jakarta Bean Validation
- RESTful API with comprehensive documentation
- In-memory H2 database for demos
- Unit tests with JUnit 5 and MockMvc

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tasks` | Get all tasks |
| GET | `/api/tasks/{id}` | Get task by ID |
| POST | `/api/tasks` | Create new task |
| PUT | `/api/tasks/{id}` | Update task |
| DELETE | `/api/tasks/{id}` | Delete task |
| GET | `/api/tasks/status/{status}` | Get tasks by status |
| GET | `/api/tasks/priority/{priority}` | Get tasks by priority |

## Testing

Run all tests:
```bash
mvn test
```

## Notes

This is a minimal scaffold designed for GitHub Copilot demonstrations. It showcases:
- Modern Spring Boot 3 best practices
- Clean controller and repository patterns
- Comprehensive API documentation
- Validation and error handling
- Unit testing with MockMvc
