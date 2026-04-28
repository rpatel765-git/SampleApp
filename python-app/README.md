# Python FastAPI Demo App

A minimal but representative FastAPI scaffold for GitHub Copilot Deep-Dive Part 2 live demonstrations.

## Overview

This demo application showcases a clean, production-inspired FastAPI architecture with:
- RESTful task management API (CRUD operations)
- SQLAlchemy 2.0 ORM with SQLite backend
- Pydantic v2 request/response validation
- Comprehensive pytest test suite with fixtures
- Type hints throughout
- Professional error handling and logging patterns

## Project Structure

```
python-app/
├── main.py                 # FastAPI application and endpoints
├── models.py              # SQLAlchemy ORM models
├── schemas.py             # Pydantic request/response schemas
├── database.py            # Database configuration and session management
├── pyproject.toml         # Project configuration (Python 3.11+)
├── requirements.txt       # Pip-compatible dependencies
├── .github/
│   └── copilot-instructions.md  # Copilot-specific guidelines
└── tests/
    ├── __init__.py
    ├── conftest.py        # Pytest fixtures
    └── test_main.py       # API endpoint tests
```

## Quick Start

### Installation

```bash
pip install -r requirements.txt
```

Or with dev dependencies:

```bash
pip install -e ".[dev]"
```

### Running the App

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

Interactive docs: `http://localhost:8000/docs`

### Running Tests

```bash
pytest -v
pytest --cov=.  # With coverage
pytest -s       # With print statements
```

## API Endpoints

- `GET /health` — Health check
- `GET /tasks` — List tasks (paginated)
- `GET /tasks/{task_id}` — Retrieve specific task
- `POST /tasks` — Create new task
- `PUT /tasks/{task_id}` — Update task
- `DELETE /tasks/{task_id}` — Delete task

## Task Model

Tasks have the following fields:
- `id`: Unique identifier (auto-generated)
- `title`: Task title (required, 1-255 chars)
- `description`: Optional detailed description
- `priority`: `low`, `medium`, or `high` (default: `medium`)
- `status`: `pending`, `in_progress`, or `completed` (default: `pending`)
- `created_at`: Timestamp (auto-generated)

## Design Patterns

This scaffold demonstrates:
- **Separation of Concerns**: Models, schemas, routes, and database logic separated
- **Type Safety**: Full type hints on all function signatures (PEP 484)
- **Validation**: Pydantic v2 for robust input/output validation
- **Error Handling**: HTTPException with meaningful status codes and messages
- **Testing**: Fixture-based test setup with in-memory database
- **Documentation**: Comprehensive docstrings (Google style) on all public functions
- **Configuration**: pyproject.toml for modern Python packaging

## Development Notes

- Python 3.11+ required (uses modern type hint syntax)
- SQLite for development; can be swapped for PostgreSQL, MySQL, etc.
- All endpoints include proper error handling and logging
- Test database uses in-memory SQLite for speed and isolation

## GitHub Copilot Integration

See `.github/copilot-instructions.md` for Copilot-specific coding guidelines used in this project.
