import { NextResponse } from 'next/server'

export async function GET() {
  const tasks = [
    {
      id: '1',
      title: 'Set up project',
      description: 'Initialize Next.js project',
      completed: true,
    },
    {
      id: '2',
      title: 'Add API routes',
      description: 'Create sample API endpoints',
      completed: true,
    },
    {
      id: '3',
      title: 'Build UI components',
      description: 'Create reusable React components',
      completed: false,
    },
  ]

  return NextResponse.json({ tasks })
}
