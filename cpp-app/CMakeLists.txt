cmake_minimum_required(VERSION 3.20)
project(TaskTracker VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Main executable
add_executable(task_tracker
    src/main.cpp
    src/task.cpp
    src/task_manager.cpp
)

target_include_directories(task_tracker PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Enable testing
enable_testing()

# Fetch GoogleTest
include(FetchContent)
FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.13.0.zip
)

# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Test executable
add_executable(test_task_manager
    tests/test_task_manager.cpp
    src/task.cpp
    src/task_manager.cpp
)

target_include_directories(test_task_manager PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(test_task_manager PRIVATE GTest::gtest_main)

add_test(NAME TaskManagerTests COMMAND test_task_manager)
