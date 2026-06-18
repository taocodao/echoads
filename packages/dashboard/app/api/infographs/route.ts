import { readdirSync } from 'fs';
import { join } from 'path';
import { NextResponse } from 'next/server';

export async function GET() {
  const dir = join(process.cwd(), 'public', 'InfoGraphs');
  const files = readdirSync(dir)
    .filter(f => /\.(jpe?g|png|webp)$/i.test(f))
    .sort();
  return NextResponse.json(files);
}
