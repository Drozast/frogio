// Centralized API URL configuration
// Uses internal Docker network URL for SSR, external URL as fallback

export const API_URL =
  process.env.INTERNAL_API_URL ||
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  'http://localhost:3000';

// Client-side API URL (always uses public URL)
export const CLIENT_API_URL =
  process.env.NEXT_PUBLIC_API_URL ||
  'http://localhost:3000';
