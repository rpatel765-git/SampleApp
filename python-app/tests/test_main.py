"""
Sample tests for the FastAPI application.

This module demonstrates testing patterns using pytest and httpx.
"""

from fastapi.testclient import TestClient


def test_health_check(client: TestClient) -> None:
    """
    Test the health check endpoint.

    Args:
        client: FastAPI test client fixture.
    """
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_create_task(client: TestClient) -> None:
    """
    Test creating a new task.

    Args:
        client: FastAPI test client fixture.
    """
    task_data = {
        "title": "Test Task",
        "description": "This is a test task",
        "priority": "high",
        "status": "pending",
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == task_data["title"]
    assert data["priority"] == task_data["priority"]
    assert "id" in data
    assert "created_at" in data


def test_list_tasks(client: TestClient) -> None:
    """
    Test listing tasks.

    Args:
        client: FastAPI test client fixture.
    """
    # Create a task first
    task_data = {
        "title": "Task 1",
        "description": "First test task",
        "priority": "medium",
    }
    client.post("/tasks", json=task_data)

    # List tasks
    response = client.get("/tasks")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1


def test_get_task(client: TestClient) -> None:
    """
    Test retrieving a specific task.

    Args:
        client: FastAPI test client fixture.
    """
    # Create a task
    task_data = {"title": "Get Test Task", "priority": "low"}
    create_response = client.post("/tasks", json=task_data)
    task_id = create_response.json()["id"]

    # Get the task
    response = client.get(f"/tasks/{task_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == task_id
    assert data["title"] == "Get Test Task"


def test_update_task(client: TestClient) -> None:
    """
    Test updating a task.

    Args:
        client: FastAPI test client fixture.
    """
    # Create a task
    task_data = {"title": "Original Title", "status": "pending"}
    create_response = client.post("/tasks", json=task_data)
    task_id = create_response.json()["id"]

    # Update the task
    update_data = {"title": "Updated Title", "status": "completed"}
    response = client.put(f"/tasks/{task_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated Title"
    assert data["status"] == "completed"


def test_delete_task(client: TestClient) -> None:
    """
    Test deleting a task.

    Args:
        client: FastAPI test client fixture.
    """
    # Create a task
    task_data = {"title": "Task to Delete"}
    create_response = client.post("/tasks", json=task_data)
    task_id = create_response.json()["id"]

    # Delete the task
    response = client.delete(f"/tasks/{task_id}")
    assert response.status_code == 204

    # Verify it's deleted
    get_response = client.get(f"/tasks/{task_id}")
    assert get_response.status_code == 404


def test_task_not_found(client: TestClient) -> None:
    """
    Test retrieving a non-existent task.

    Args:
        client: FastAPI test client fixture.
    """
    response = client.get("/tasks/99999")
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()
