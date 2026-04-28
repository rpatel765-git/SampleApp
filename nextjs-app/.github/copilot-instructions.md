# Copilot Instructions for NextJS Demo App

## Code Style & Language

- **TypeScript**: Always use strict mode. All files should be `.ts` or `.tsx`
- **React**: Functional components and hooks only. No class components
- **React 18+**: Use modern hooks (useState, useEffect, useContext, etc.)

## Architecture

- **App Router**: Use Next.js App Router (in `src/app/`), NOT the Pages Router
- **Server Components**: Default to Server Components. Use Client Components (`'use client'`) only when:
  - Interactive state is needed (useState, useEffect)
  - Browser APIs are required (window, localStorage, etc.)
  - Event handlers are needed (onClick, onChange, etc.)

## Styling

- **Tailwind CSS**: Only use Tailwind for styling
- **No CSS Modules**: Avoid `.module.css`
- **Utility-First**: Use Tailwind utility classes for all styling

## API Routes

- **Location**: `src/app/api/[route]/route.ts`
- **Format**: Use Next.js Route Handlers (the `route.ts` pattern)
- **Validation**: Use Zod for request/response validation
- **Example**:
  ```typescript
  import { NextResponse, NextRequest } from 'next/server'
  import { z } from 'zod'

  const taskSchema = z.object({
    title: z.string().min(1),
    description: z.string().optional(),
  })

  export async function POST(request: NextRequest) {
    const body = await request.json()
    const validation = taskSchema.safeParse(body)
    
    if (!validation.success) {
      return NextResponse.json(
        { error: validation.error },
        { status: 400 }
      )
    }

    return NextResponse.json({ success: true })
  }
  ```

## Testing

- **Framework**: Jest + React Testing Library
- **Files**: Tests live in `__tests__/` or adjacent `.test.ts(x)` files
- **Focus**: Unit tests for utilities, integration tests for components/API routes
- **Example**:
  ```typescript
  import { render, screen } from '@testing-library/react'
  import Home from '@/app/page'

  describe('Home', () => {
    it('renders the heading', () => {
      render(<Home />)
      expect(screen.getByText('Team Task Tracker')).toBeInTheDocument()
    })
  })
  ```

## Navigation & Links

- **Use `next/link`**: For all internal navigation
  ```typescript
  import Link from 'next/link'
  export function Nav() {
    return <Link href="/tasks">Tasks</Link>
  }
  ```

## Images

- **Use `next/image`**: For all images (optimization, lazy loading)
  ```typescript
  import Image from 'next/image'
  export function Avatar() {
    return <Image src="/avatar.png" alt="Avatar" width={40} height={40} />
  }
  ```

## Accessibility (WCAG 2.1 AA)

- **Semantic HTML**: Use proper heading hierarchy, `<button>`, `<label>`, etc.
- **ARIA Attributes**: Use `aria-label`, `aria-describedby`, `role` where needed
- **Color Contrast**: Ensure minimum 4.5:1 contrast for text
- **Focus Management**: Ensure keyboard navigation works
- **Alt Text**: All images must have meaningful `alt` text

## Best Practices

1. **Keep Components Focused**: One responsibility per component
2. **Props Typing**: Always type component props with interfaces or types
3. **Error Handling**: Handle errors gracefully; show user-friendly messages
4. **Performance**: Use `next/dynamic` for lazy-loaded components if needed
5. **Environment Variables**: Use `.env.local` for sensitive data; prefix public vars with `NEXT_PUBLIC_`
6. **Type Safety**: No `any` types; use proper TypeScript interfaces

## File Organization

```
src/
├── app/
│   ├── api/              # API routes
│   ├── layout.tsx        # Root layout
│   ├── page.tsx          # Home page
│   └── globals.css       # Global styles
├── components/           # Reusable components
│   ├── ui/               # UI components (Button, Input, etc.)
│   └── features/         # Feature-specific components
├── lib/                  # Utilities and helpers
├── types/                # TypeScript types/interfaces
└── styles/               # Global styles (if additional)
```

## Common Commands

```bash
npm run dev          # Start dev server
npm run build        # Build for production
npm start            # Start production server
npm test             # Run tests
npm run lint         # Run ESLint
```
