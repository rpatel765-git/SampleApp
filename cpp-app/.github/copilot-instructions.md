# C++ Development Guidelines for GitHub Copilot

This document provides coding standards and best practices for this C++ project. Use these guidelines to ensure consistency and quality when working with GitHub Copilot.

## Language & Compilation

- **C++ Standard**: C++20 (mandatory)
  - Use modern language features: concepts, ranges, std::optional, std::string_view
  - Use std::format for string formatting where supported
  - Prefer std::ranges algorithms over traditional iteration
  
- **Compiler Requirements**: GCC 10+, Clang 12+, or MSVC 2019+

## Memory Management

- **RAII (Resource Acquisition Is Initialization)**: All resources must follow RAII principles
  - Files, memory, locks, and other resources must be automatically managed
  - No manual `new`/`delete` calls allowed in application code
  
- **Smart Pointers**: Use smart pointers exclusively for dynamic memory
  - `std::unique_ptr<T>` for exclusive ownership
  - `std::shared_ptr<T>` for shared ownership (use sparingly)
  - Never use raw pointers for ownership
  
- **String References**: Use `std::string_view` for non-owning string parameters
  - Function signatures should prefer `std::string_view` over `const std::string&`
  - Only use `std::string` when ownership is required

## Build System

- **CMake**: Modern CMake 3.20+ with target-based configuration
  - Use `target_include_directories()` instead of `include_directories()`
  - Use `target_link_libraries()` for linking dependencies
  - Define targets explicitly; avoid global flags
  - Link against FetchContent for external dependencies (GoogleTest, etc.)

## Testing

- **Framework**: GoogleTest (gtest) for all unit tests
- **Test Organization**: One test file per module, named `test_<module>.cpp`
- **Test Coverage**: Aim for 80%+ line coverage
- **Naming**: Test classes use `<ComponentName>Test`, test methods use `TestName` (PascalCase)

## Code Style

### Comments and Documentation

- **Doxygen Comments**: All public APIs must have Doxygen-style comments
  - Use `///` for documentation comments (preferred over `/**`)
  - Include `@brief` for short descriptions
  - Use `@param` for parameters and `@return` for return values
  - Example:
    ```cpp
    /// @brief Adds a new task to the manager
    /// @param title The task title (non-empty)
    /// @return ID of the newly created task
    int add_task(std::string_view title);
    ```

### Header Files

- **Include Guards**: Use `#pragma once` (preferred over `#ifndef` guards)
- **Order of Includes**:
  1. Standard library headers (`#include <vector>`, etc.)
  2. Third-party headers (`#include <gtest/gtest.h>`, etc.)
  3. Local project headers (`#include "task.h"`, etc.)
- **Minimize Includes**: Only include what's needed to avoid compilation overhead

### Code Organization

- **Const-Correctness**: Mark methods `const` when they don't modify state
- **constexpr**: Use `constexpr` for compile-time evaluated functions where possible
- **Namespacing**: Use namespaces to avoid naming conflicts (consider `app::` or `tasktracker::` for larger projects)
- **Enums**: Prefer `enum class` over unscoped `enum` for type safety

### Function & Variable Naming

- **Functions**: Use snake_case (e.g., `add_task()`, `list_tasks()`)
- **Classes**: Use PascalCase (e.g., `TaskManager`, `Task`)
- **Member Variables**: Use snake_case with optional trailing `_` (e.g., `task_id`, `tasks_`)
- **Constants**: Use UPPER_SNAKE_CASE (e.g., `MAX_TASKS`, `DEFAULT_PRIORITY`)

## Error Handling

- **Approach**: Prefer exceptions over error codes in modern C++
- **std::optional**: Use for optional return values with no error context
- **std::expected**: Use for operations that can fail with error information (C++23 or polyfill)
- **Exceptions**: Throw standard exception types (`std::runtime_error`, `std::invalid_argument`, etc.)
- **Try-Catch**: Use only at system boundaries (main, external API calls)

## Performance Considerations

- **Move Semantics**: Implement move constructors and move assignment operators for large objects
  - Use `std::move()` when passing temporaries
  - Enable return value optimization (RVO)
  
- **Avoid Copies**: Use references and const-references where appropriate
- **Reserve Space**: Call `reserve()` on containers when size is known upfront
- **Inline**: Let the compiler decide; don't over-use `inline` keyword

## Modern C++ Features to Use

- `std::optional<T>` for optional values
- `std::string_view` for string references
- `std::unique_ptr<T>` for ownership
- `std::vector<T>` for dynamic arrays
- `std::map<K, V>` or `std::unordered_map` for key-value pairs
- Structured bindings: `auto [a, b] = get_pair();`
- Range-based for loops: `for (const auto& item : container)`
- Lambda functions for callbacks and predicates

## Features to Avoid

- Raw pointers for ownership
- C-style arrays (use `std::array<T, N>` or `std::vector<T>`)
- C-style casts (use `static_cast<T>`, `dynamic_cast<T>`, `const_cast<T>`, `reinterpret_cast<T>`)
- Global variables (use namespaces or singletons carefully)
- `goto` statements
- Preprocessor macros (use `constexpr` or `inline` functions instead)

## Dependencies

- **GoogleTest**: For unit testing
- **Standard Library**: Prefer STL over external dependencies
- **No C++ Runtime Libraries**: Use only standard C++ features

## Continuous Integration

- All code must build without warnings on supported compilers
- All tests must pass
- Use CMake with modern generators (Ninja, Unix Makefiles, Visual Studio 16+)
