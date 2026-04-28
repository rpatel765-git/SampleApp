"""
SQLAlchemy ORM models for the application.

This module defines the data models using SQLAlchemy 2.0 style with mapped_column.
"""

from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, Enum
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.orm import mapped_column
import enum


class Base(DeclarativeBase):
    """Base class for all ORM models."""
    pass


class TaskStatus(str, enum.Enum):
    """Enumeration for task status."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"


class TaskPriority(str, enum.Enum):
    """Enumeration for task priority."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class TaskItem(Base):
    """
    Task item model.

    Represents a task with title, description, priority, and status.
    """
    __tablename__ = "tasks"

    id: int = mapped_column(Integer, primary_key=True, index=True)
    title: str = mapped_column(String(255), nullable=False, index=True)
    description: str = mapped_column(Text, nullable=True)
    priority: str = mapped_column(String(20), default=TaskPriority.MEDIUM.value)
    status: str = mapped_column(String(20), default=TaskStatus.PENDING.value)
    created_at: datetime = mapped_column(DateTime, default=datetime.utcnow)

    def __repr__(self) -> str:
        """String representation of TaskItem."""
        return (
            f"<TaskItem(id={self.id}, title='{self.title}', "
            f"status='{self.status}', priority='{self.priority}')>"
        )
