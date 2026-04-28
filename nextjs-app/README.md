# NextJS Copilot Demo App

A minimal Next.js sample application scaffold for GitHub Copilot Deep-Dive Part 2 presentations.

## Overview

This is the base application used for live demos showing:
- **Copilot CLI** — Command-line interactions and inline suggestions
- **Coding Agent** — Automated code generation and implementation
- **Code Review** — Copilot-powered code review workflows
- **TDD Workflows** — Test-driven development patterns

## Tech Stack

- **Next.js 14+** with App Router
- **TypeScript** (strict mode)
- **Tailwind CSS** for styling
- **Jest** for testing
- **React Testing Library** for component tests
- **Zod** for validation

## Getting Started

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build for production
npm build
```

The app will be available at `http://localhost:3000`

## Project Structure

```
src/
├── app/
│   ├── api/              # Next.js Route Handlers
│   ├── layout.tsx        # Root layout
│   ├── page.tsx          # Home page
│   └── globals.css       # Tailwind directives
└── components/           # Reusable React components
```

## API Endpoints

- `GET /api/tasks` — Returns sample tasks

## Development Notes

- All components are TypeScript
- Tailwind CSS is configured for styling
- Jest is configured for unit and integration tests
- Follow the guidelines in `.github/copilot-instructions.md`
