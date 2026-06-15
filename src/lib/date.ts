import {
  format,
  formatDistanceToNow,
  differenceInDays,
  differenceInHours,
  differenceInMinutes,
  isPast,
  isFuture,
} from "date-fns";

export function formatDate(ts: number): string {
  return format(new Date(ts), "MMM d, yyyy");
}

export function formatDateTime(ts: number): string {
  return format(new Date(ts), "MMM d, yyyy 'at' h:mm a");
}

export function timeAgo(ts: number): string {
  return formatDistanceToNow(new Date(ts), { addSuffix: true });
}

export function countdown(openAt: number): string {
  const now = new Date();
  const target = new Date(openAt);

  if (isPast(target)) return "Ready to open";

  const days = differenceInDays(target, now);
  if (days > 0) return `${days}d remaining`;

  const hours = differenceInHours(target, now);
  if (hours > 0) return `${hours}h remaining`;

  const minutes = differenceInMinutes(target, now);
  return `${minutes}m remaining`;
}

export function timeElapsed(from: number, to: number): string {
  return formatDistanceToNow(new Date(from), { addSuffix: true });
}

export function isOpenable(openAt: number): boolean {
  return isPast(new Date(openAt));
}

export function isSealed(openAt: number): boolean {
  return isFuture(new Date(openAt));
}
