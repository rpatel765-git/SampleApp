# .NET Demo App

.NET Demo App for GitHub Copilot Deep-Dive Part 2.

ASP.NET Core 8 Web API used for live demos.

## Project Structure

- `DotnetApp/` — Main API project
  - `Controllers/` — REST API endpoints
  - `Models/` — Domain models
  - `Data/` — Entity Framework Core DbContext
  - `Program.cs` — Application entry point and configuration

- `Tests/` — Unit tests using xUnit and FluentAssertions

## Building and Running

```bash
# Restore dependencies
dotnet restore

# Build the project
dotnet build

# Run the API
dotnet run --project DotnetApp

# Run tests
dotnet test
```

## API Endpoints

The API provides CRUD operations for tasks:

- `GET /api/tasks` — Get all tasks
- `GET /api/tasks/{id}` — Get a specific task
- `POST /api/tasks` — Create a new task
- `PUT /api/tasks/{id}` — Update a task
- `DELETE /api/tasks/{id}` — Delete a task

## Swagger Documentation

When running in Development mode, Swagger/OpenAPI documentation is available at `/swagger`.

## Technologies

- **ASP.NET Core 8**
- **Entity Framework Core** (In-Memory Database)
- **Swagger/OpenAPI** (Swashbuckle)
- **xUnit** (Testing)
- **FluentAssertions** (Testing fluent API)
