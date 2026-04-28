"""
FastAPI application entry point.

This module initializes the FastAPI app and defines routes for health checks
and task management CRUD operations.
"""

from fastapi import FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from database import engine, get_db
from models import Base, TaskItem
from schemas import TaskCreate, TaskUpdate, TaskResponse, TaskList

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Python FastAPI Demo App",
    description="Demo app for GitHub Copilot Deep-Dive presentation",
    version="0.1.0",
)


@app.get("/health", status_code=status.HTTP_200_OK)
def health_check() -> dict[str, str]:
    """
    Health check endpoint.

    Returns:
        dict: Status message indicating the service is healthy.
    """
    return {"status": "healthy"}


@app.get("/tasks", response_model=TaskList)
def list_tasks(skip: int = 0, limit: int = 10, db: Session = None) -> TaskList:
    """
    List all tasks with pagination.

    Args:
        skip: Number of tasks to skip (default: 0).
        limit: Maximum number of tasks to return (default: 10).
        db: Database session dependency.

    Returns:
        TaskList: Paginated list of tasks.
    """
    if db is None:
        db = next(get_db())
    
    try:
        tasks = db.query(TaskItem).offset(skip).limit(limit).all()
        total = db.query(TaskItem).count()
        return TaskList(items=tasks, total=total)
    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error occurred",
        ) from e


@app.get("/tasks/{task_id}", response_model=TaskResponse)
def get_task(task_id: int, db: Session = None) -> TaskResponse:
    """
    Retrieve a specific task by ID.

    Args:
        task_id: The ID of the task to retrieve.
        db: Database session dependency.

    Returns:
        TaskResponse: The requested task.

    Raises:
        HTTPException: If the task is not found.
    """
    if db is None:
        db = next(get_db())
    
    task = db.query(TaskItem).filter(TaskItem.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found",
        )
    return task


@app.post("/tasks", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(task: TaskCreate, db: Session = None) -> TaskResponse:
    """
    Create a new task.

    Args:
        task: Task creation payload.
        db: Database session dependency.

    Returns:
        TaskResponse: The created task with ID.

    Raises:
        HTTPException: If task creation fails.
    """
    if db is None:
        db = next(get_db())
    
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


@app.put("/tasks/{task_id}", response_model=TaskResponse)
def update_task(task_id: int, task_update: TaskUpdate, db: Session = None) -> TaskResponse:
    """
    Update an existing task.

    Args:
        task_id: The ID of the task to update.
        task_update: Task update payload.
        db: Database session dependency.

    Returns:
        TaskResponse: The updated task.

    Raises:
        HTTPException: If the task is not found or update fails.
    """
    if db is None:
        db = next(get_db())
    
    db_task = db.query(TaskItem).filter(TaskItem.id == task_id).first()
    if not db_task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found",
        )

    try:
        update_data = task_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_task, field, value)
        db.commit()
        db.refresh(db_task)
        return db_task
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update task",
        ) from e


@app.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: int, db: Session = None) -> None:
    """
    Delete a task by ID.

    Args:
        task_id: The ID of the task to delete.
        db: Database session dependency.

    Raises:
        HTTPException: If the task is not found or deletion fails.
    """
    if db is None:
        db = next(get_db())
    
    db_task = db.query(TaskItem).filter(TaskItem.id == task_id).first()
    if not db_task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Task with id {task_id} not found",
        )

    try:
        db.delete(db_task)
        db.commit()
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to delete task",
        ) from e


@app.exception_handler(Exception)
async def global_exception_handler(request, exc: Exception):  # type: ignore
    """
    Global exception handler for uncaught exceptions.

    Args:
        request: The HTTP request.
        exc: The exception that was raised.

    Returns:
        JSONResponse: Error response with 500 status.
    """
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred"},
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
