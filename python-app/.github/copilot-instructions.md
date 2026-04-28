# GitHub Copilot Coding Guidelines for Python FastAPI Projects

This document outlines coding standards and best practices for this Python FastAPI project when using GitHub Copilot.

## Code Style & Standards

### 1. PEP 8 Compliance
- Follow PEP 8 style guide strictly
- Line length: maximum 100 characters
- Use 4 spaces for indentation (never tabs)
- Use meaningful variable and function names (avoid single letters except in loops)
- Group imports: standard library, third-party, local (separated by blank lines)

**Example:**
```python
import os
from datetime import datetime
from typing import Optional

from fastapi import FastAPI
from sqlalchemy import create_engine

from models import TaskItem
```

### 2. Type Hints

**All function signatures must include type hints.** Use modern Python 3.11+ syntax.

```python
# ✅ Good
def process_task(task_id: int, name: str) -> dict[str, str]:
    """Process a task and return metadata."""
    return {"id": task_id, "name": name}

# ❌ Avoid
def process_task(task_id, name):
    return {"id": task_id, "name": name}
```

For complex types, import from `typing`:
```python
from typing import Optional, Union, Literal

def get_task(task_id: int) -> Optional[TaskItem]:
    """Get a task or None if not found."""
    pass

def set_priority(priority: Literal["low", "medium", "high"]) -> None:
    """Set task priority to one of three levels."""
    pass
```

### 3. Pydantic v2 Models

Always use Pydantic v2 for request/response validation.

```python
from pydantic import BaseModel, Field

class TaskCreate(BaseModel):
    """Schema for creating a task."""
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    priority: str = Field(default="medium", pattern="^(low|medium|high)$")

    model_config = {"json_schema_extra": {"example": {...}}}
```

Key points:
- Use `Field()` for validation constraints
- Set `model_config` for serialization options
- Use `model_dump()` and `model_validate()` (not `dict()`)

### 4. SQLAlchemy 2.0 Style

Use modern SQLAlchemy 2.0 syntax with `mapped_column`:

```python
from sqlalchemy.orm import DeclarativeBase, mapped_column
from sqlalchemy import String, Integer, DateTime

class Base(DeclarativeBase):
    """Base class for all ORM models."""
    pass

class TaskItem(Base):
    __tablename__ = "tasks"
    
    id: int = mapped_column(Integer, primary_key=True)
    title: str = mapped_column(String(255), nullable=False, index=True)
    created_at: datetime = mapped_column(DateTime, default=datetime.utcnow)
```

**Avoid old-style Column syntax:**
```python
# ❌ Don't use
id = Column(Integer, primary_key=True)

# ✅ Use instead
id: int = mapped_column(Integer, primary_key=True)
```

### 5. Async Endpoints

Use `async def` for FastAPI endpoints to enable concurrent request handling:

```python
from fastapi import FastAPI, Depends
from sqlalchemy.ext.asyncio import AsyncSession

app = FastAPI()

@app.get("/tasks/{task_id}")
async def get_task(task_id: int, db: AsyncSession = Depends(get_db)) -> TaskResponse:
    """Retrieve a task asynchronously."""
    result = await db.execute(select(TaskItem).where(TaskItem.id == task_id))
    task = result.scalar_one_or_none()
    return task
```

For sync operations, regular `def` is acceptable but prefer `async def`.

### 6. Testing with Pytest

Use pytest with fixtures for consistent, maintainable tests:

```python
import pytest
from fastapi.testclient import TestClient

@pytest.fixture(scope="function")
def client(test_db: Session) -> TestClient:
    """Fixture providing a test HTTP client."""
    return TestClient(app)

def test_create_task(client: TestClient) -> None:
    """Test task creation via POST endpoint."""
    response = client.post("/tasks", json={"title": "Test"})
    assert response.status_code == 201
    assert response.json()["title"] == "Test"
```

Use `httpx.AsyncClient` for async endpoint testing:
```python
@pytest.mark.asyncio
async def test_async_get_task(async_client: AsyncClient) -> None:
    """Test async endpoint."""
    response = await async_client.get("/tasks/1")
    assert response.status_code == 200
```

### 7. Documentation & Docstrings

All public functions, classes, and modules must have docstrings using **Google style**:

```python
def create_task(task_data: TaskCreate, db: Session) -> TaskResponse:
    """
    Create a new task in the database.
    
    This function validates the input data via Pydantic, creates a TaskItem
    record in the database, and returns the created task with ID assigned.
    
    Args:
        task_data: Task creation payload validated by TaskCreate schema.
        db: SQLAlchemy database session.
    
    Returns:
        TaskResponse: The created task with auto-generated ID and timestamp.
    
    Raises:
        HTTPException: If database commit fails (returns 400 Bad Request).
        ValidationError: If task_data doesn't match TaskCreate schema.
    
    Example:
        >>> task = create_task(TaskCreate(title="Fix bug"), db_session)
        >>> task.id
        42
    """
    pass
```

Module-level docstrings are required:
```python
"""
SQLAlchemy ORM models for the application.

This module defines data models using SQLAlchemy 2.0 with mapped_column syntax.
All models inherit from Base and are automatically mapped to database tables.
"""
```

### 8. Error Handling

Always use `HTTPException` with proper status codes and meaningful messages:

```python
from fastapi import HTTPException, status

def get_task(task_id: int, db: Session) -> TaskResponse:
    """Get a task or raise 404."""
    task = db.query(TaskItem).filter(TaskItem.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found",
        )
    return task

def create_task(task: TaskCreate, db: Session) -> TaskResponse:
    """Create a task or raise 400 on validation failure."""
    try:
        db_task = TaskItem(**task.model_dump())
        db.add(db_task)
        db.commit()
        db.refresh(db_task)
        return db_task
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create task",
        ) from e
```

Use custom error models for consistent error responses:
```python
from pydantic import BaseModel

class ErrorResponse(BaseModel):
    """Standard error response model."""
    detail: str
    status_code: int
    timestamp: Optional[datetime] = None
```

### 9. Python 3.11+ Features

Leverage modern Python features:

```python
# Use match/case (structural pattern matching)
match priority:
    case "high" | "critical":
        return 1
    case "medium":
        return 2
    case "low":
        return 3
    case _:
        raise ValueError("Unknown priority")

# Use dictionary union (|)
config = {"host": "localhost"} | {"port": 8000}

# Use built-in tomllib for TOML parsing
import tomllib
with open("pyproject.toml", "rb") as f:
    config = tomllib.load(f)

# Use type unions with | operator
def process(value: int | str | None) -> None:
    pass
```

### 10. Configuration Management

Use environment variables and `pydantic-settings`:

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings from environment variables."""
    database_url: str = "sqlite:///./app.db"
    debug: bool = False
    api_key: Optional[str] = None
    
    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
```

## Code Organization

### Module Structure
```
app/
├── main.py           # FastAPI app, route handlers, middleware
├── models.py         # SQLAlchemy ORM models
├── schemas.py        # Pydantic validation schemas
├── database.py       # Database configuration, sessions
├── services/         # Business logic (optional)
│   ├── task_service.py
│   └── user_service.py
├── dependencies.py   # Shared dependencies (optional)
└── config.py         # Settings and constants (optional)
```

### Import Order
1. Standard library
2. Third-party packages
3. Local application modules

```python
import os
import logging
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session

from models import TaskItem
from schemas import TaskResponse
from database import get_db
```

## Common Patterns

### Dependency Injection
```python
def get_db() -> Session:
    """Database session dependency."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/tasks")
def list_tasks(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)) -> list[TaskResponse]:
    """List tasks with pagination."""
    return db.query(TaskItem).offset(skip).limit(limit).all()
```

### Transactions & Rollback
```python
try:
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task
except SQLAlchemyError as e:
    db.rollback()
    raise HTTPException(status_code=400, detail="Creation failed") from e
```

### Pagination
```python
@app.get("/tasks")
def list_tasks(skip: int = Query(0, ge=0), limit: int = Query(10, ge=1, le=100)) -> dict:
    """List tasks with validated pagination parameters."""
    return {
        "items": db.query(TaskItem).offset(skip).limit(limit).all(),
        "total": db.query(TaskItem).count(),
    }
```

## Copilot Usage Tips

When using GitHub Copilot with this codebase:

1. **Provide context** in comments before complex functions
2. **Include type hints** in your prompts to guide Copilot
3. **Reference existing patterns** in the codebase
4. **Ask for docstrings** explicitly if Copilot omits them
5. **Verify generated code** against these guidelines

Example Copilot prompt:
```
# Create a Pydantic v2 schema for user authentication
# with email validation and password strength constraints.
# Include model_config for serialization.
```

## Resources

- [PEP 8 Style Guide](https://pep8.org/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic v2 Documentation](https://docs.pydantic.dev/latest/)
- [SQLAlchemy 2.0 Documentation](https://docs.sqlalchemy.org/20/)
- [Python 3.11+ Features](https://docs.python.org/3.11/whatsnew/3.11.html)
