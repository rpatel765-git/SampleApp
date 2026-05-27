"""
SQLAlchemy ORM models for the application.

This module defines the data models using SQLAlchemy 2.0 style with mapped_column.
"""

"""SQLAlchemy ORM models for the application."""

from datetime import datetime
import enum

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


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

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    priority: Mapped[str] = mapped_column(String(20), default=TaskPriority.MEDIUM.value)
    status: Mapped[str] = mapped_column(String(20), default=TaskStatus.PENDING.value)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    def __repr__(self) -> str:
        """String representation of TaskItem."""
        return (
            f"<TaskItem(id={self.id}, title='{self.title}', "
            f"status='{self.status}', priority='{self.priority}')>"
        )
