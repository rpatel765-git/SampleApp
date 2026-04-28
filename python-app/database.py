"""
Database configuration and session management.

This module handles SQLAlchemy engine initialization, session creation,
and dependency injection for FastAPI endpoints.
"""

import os
from sqlalchemy import create_engine, Engine
from sqlalchemy.orm import sessionmaker, Session

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./app.db")

# Create SQLAlchemy engine
engine: Engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {},
    echo=False,
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Session:
    """
    Dependency injection function for database sessions.

    Yields a database session and ensures it's closed after use.

    Yields:
        Session: SQLAlchemy database session.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
