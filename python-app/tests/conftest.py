"""
Pytest fixtures for testing.

This module provides shared fixtures for test client and test database setup.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool

from main import app, get_db
from models import Base


@pytest.fixture(scope="function")
def test_db() -> Session:
    """
    Create a test database session.

    Uses an in-memory SQLite database for fast, isolated tests.

    Yields:
        Session: SQLAlchemy session for testing.
    """
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    def override_get_db() -> Session:  # type: ignore
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    yield TestingSessionLocal()

    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
def client(test_db: Session) -> TestClient:
    """
    Create a test HTTP client.

    Args:
        test_db: Test database session fixture.

    Returns:
        TestClient: FastAPI test client.
    """
    return TestClient(app)
