# TaskTracker - C++ Demo App for GitHub Copilot Deep-Dive Part 2

A minimal C++ command-line task tracker application used as a live demo scaffold for GitHub Copilot productivity sessions.

## Overview

TaskTracker is a simple but representative C++ application demonstrating:
- Modern C++ (C++20) with standard library features
- CMake build system with GoogleTest integration
- RAII and smart pointer usage patterns
- Basic CLI argument parsing
- Unit testing with GoogleTest

## Building

### Prerequisites
- C++20 compatible compiler (GCC 10+, Clang 12+, or MSVC 2019+)
- CMake 3.20 or later

### Build Steps

```bash
cd cpp-app
mkdir build
cd build
cmake ..
cmake --build .
```

### Running

```bash
# Show help
./task_tracker help

# Add a task
./task_tracker add "Buy milk" "From the store" high

# List all tasks
./task_tracker list

# List pending tasks
./task_tracker list pending

# Complete a task
./task_tracker complete 1

# Remove a task
./task_tracker remove 1
```

### Running Tests

```bash
ctest
# or
./test_task_manager
```

## Project Structure

```
cpp-app/
├── CMakeLists.txt              # Top-level CMake configuration
├── src/
│   ├── main.cpp               # CLI entry point
│   ├── task.h / task.cpp      # Task data structure
│   └── task_manager.h / cpp   # Task management logic
├── tests/
│   └── test_task_manager.cpp  # GoogleTest suite
└── README.md                   # This file
```

## Key C++ Features Demonstrated

- **C++20 Standard**: Uses modern language features like std::optional, std::string_view
- **Smart Pointers**: std::unique_ptr for automatic resource management
- **RAII**: Proper resource initialization and cleanup
- **CMake**: Modern target-based build configuration
- **GoogleTest**: Comprehensive unit testing framework
- **Doxygen Comments**: Professional API documentation

## Use Cases

This scaffold is designed for:
- GitHub Copilot presentation demonstrations
- Teaching modern C++ practices
- Rapid prototyping of CLI applications
- Showing Copilot's ability to understand C++ idioms and generate idiomatic code
