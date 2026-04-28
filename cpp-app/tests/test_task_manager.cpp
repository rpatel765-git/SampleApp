#include <gtest/gtest.h>
#include "task_manager.h"

class TaskManagerTest : public ::testing::Test {
protected:
    TaskManager manager;
};

/**
 * @brief Test that tasks can be added and listed
 */
TEST_F(TaskManagerTest, AddAndListTasks) {
    int id1 = manager.add_task("Buy groceries", "Milk, eggs, bread", Priority::Medium);
    int id2 = manager.add_task("Fix bug", "Null pointer exception in main loop", Priority::High);
    
    EXPECT_EQ(id1, 1);
    EXPECT_EQ(id2, 2);
    EXPECT_EQ(manager.task_count(), 2);
    
    auto tasks = manager.list_tasks();
    EXPECT_EQ(tasks.size(), 2);
}

/**
 * @brief Test that tasks can be marked as completed
 */
TEST_F(TaskManagerTest, CompleteTask) {
    int id = manager.add_task("Write tests", "Unit tests for TaskManager", Priority::High);
    
    EXPECT_TRUE(manager.complete_task(id));
    
    auto pending_tasks = manager.list_tasks(TaskStatus::Pending);
    EXPECT_EQ(pending_tasks.size(), 0);
    
    auto completed_tasks = manager.list_tasks(TaskStatus::Completed);
    EXPECT_EQ(completed_tasks.size(), 1);
}

/**
 * @brief Test that tasks can be removed
 */
TEST_F(TaskManagerTest, RemoveTask) {
    int id1 = manager.add_task("Task 1", "Description 1", Priority::Low);
    int id2 = manager.add_task("Task 2", "Description 2", Priority::Medium);
    
    EXPECT_EQ(manager.task_count(), 2);
    
    EXPECT_TRUE(manager.remove_task(id1));
    EXPECT_EQ(manager.task_count(), 1);
    
    EXPECT_FALSE(manager.remove_task(id1));
    EXPECT_EQ(manager.task_count(), 1);
}

/**
 * @brief Test that removing non-existent task returns false
 */
TEST_F(TaskManagerTest, RemoveNonExistentTask) {
    EXPECT_FALSE(manager.remove_task(999));
}
