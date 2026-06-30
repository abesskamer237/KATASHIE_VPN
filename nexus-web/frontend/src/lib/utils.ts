import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Returns the Unix timestamp (seconds) for the end of an expiry date string.
 * The date is stored in SQLite as "YYYY-MM-DD" (UTC) and expires at the end
 * of that UTC day (23:59:59Z). If the string already contains a time component
 * it is used as-is.
 */
export function expiryToUnix(expiresAt: string): number {
  if (!expiresAt) return 0;
  // If the value looks like a pure date ("YYYY-MM-DD"), append end-of-day UTC time
  const dateOnly = /^\d{4}-\d{2}-\d{2}$/.test(expiresAt);
  const iso = dateOnly ? `${expiresAt}T23:59:59Z` : expiresAt;
  const ms = Date.parse(iso);
  return Number.isNaN(ms) ? 0 : Math.floor(ms / 1000);
}
