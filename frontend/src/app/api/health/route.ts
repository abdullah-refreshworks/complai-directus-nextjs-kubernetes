import { NextResponse } from 'next/server';

export async function GET() {
  try {
    // Check if Directus is accessible
    const directusUrl = process.env.NEXT_PUBLIC_DIRECTUS_URL || 'http://localhost:8055';
    const directusHealth = await fetch(`${directusUrl}/server/ping`);
    
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        frontend: 'healthy',
        directus: directusHealth.ok ? 'healthy' : 'unhealthy'
      },
      environment: process.env.NODE_ENV || 'development'
    };

    return NextResponse.json(health, { 
      status: directusHealth.ok ? 200 : 503 
    });
  } catch (error) {
    return NextResponse.json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 503 });
  }
}
