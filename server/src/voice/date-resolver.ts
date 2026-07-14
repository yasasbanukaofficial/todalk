export interface ResolvedDate {
  date: Date;
  userExplicitDate: boolean;
}

export interface ResolvedTime {
  hour: number;
  minute: number;
}

export interface ResolvedDateTime {
  date: Date | null;
  time: ResolvedTime | null;
}

const SKIP_WORDS = new Set(['skip', 'none', 'nope', 'nah', 'no date', 'no time', 'no due date', "don't have", 'not sure', 'whatever', 'anything', 'anytime', 'any day']);

function isSkip(text: string): boolean {
  const lower = text.toLowerCase().trim();
  if (SKIP_WORDS.has(lower)) return true;
  return false;
}

export function resolveDateOnly(rawDateText: string, now: Date = new Date()): ResolvedDate | null {
  if (isSkip(rawDateText)) return null;

  const lower = rawDateText.toLowerCase();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  let baseDate: Date | null = null;
  let namedDate = false;

  if (lower.includes('today')) {
    baseDate = new Date(today);
    namedDate = true;
  } else if (lower.includes('tomorrow')) {
    baseDate = new Date(today.getTime() + 86400000);
    namedDate = true;
  } else if (lower.includes('day after tomorrow')) {
    baseDate = new Date(today.getTime() + 2 * 86400000);
    namedDate = true;
  } else if (/in\s+(\d+)\s+days?/.test(lower)) {
    const match = /in\s+(\d+)\s+days?/.exec(lower);
    const n = parseInt(match![1], 10);
    baseDate = new Date(today.getTime() + n * 86400000);
    namedDate = true;
  } else if (/in\s+(\d+)\s+weeks?/.test(lower)) {
    const match = /in\s+(\d+)\s+weeks?/.exec(lower);
    const n = parseInt(match![1], 10);
    baseDate = new Date(today.getTime() + n * 7 * 86400000);
    namedDate = true;
  } else if (/in\s+(\d+)\s+months?/.test(lower)) {
    const match = /in\s+(\d+)\s+months?/.exec(lower);
    const n = parseInt(match![1], 10);
    const month = today.getMonth() + n;
    baseDate = new Date(today.getFullYear() + Math.floor(month / 12), month % 12, today.getDate());
    namedDate = true;
  } else if (lower.includes('next week')) {
    baseDate = new Date(today.getTime() + 7 * 86400000);
    namedDate = true;
  } else if (lower.includes('next month')) {
    const nextMonth = today.getMonth() + 1 > 11 ? 0 : today.getMonth() + 1;
    const nextYear = today.getMonth() + 1 > 11 ? today.getFullYear() + 1 : today.getFullYear();
    baseDate = new Date(nextYear, nextMonth, today.getDate());
    namedDate = true;
  } else if (lower.includes('next year')) {
    baseDate = new Date(today.getFullYear() + 1, today.getMonth(), today.getDate());
    namedDate = true;
  } else if (lower.includes('next')) {
    const weekdays: Record<string, number> = {
      monday: 1, tuesday: 2, wednesday: 3, thursday: 4,
      friday: 5, saturday: 6, sunday: 7,
    };
    for (const [name, target] of Object.entries(weekdays)) {
      if (lower.includes('next ' + name) || lower.includes('next ' + name.slice(0, 3))) {
        const current = today.getDay() || 7;
        let diff = target - current;
        if (diff <= 0) diff += 7;
        diff += 7;
        baseDate = new Date(today.getTime() + diff * 86400000);
        namedDate = true;
        break;
      }
    }
  }

  if (!baseDate) {
    const weekdays: Record<string, number> = {
      monday: 1, tuesday: 2, wednesday: 3, thursday: 4,
      friday: 5, saturday: 6, sunday: 7,
    };
    for (const [name, target] of Object.entries(weekdays)) {
      if (lower.includes(name)) {
        const current = today.getDay() || 7;
        let diff = target - current;
        if (diff <= 0) diff += 7;
        baseDate = new Date(today.getTime() + diff * 86400000);
        namedDate = true;
        break;
      }
    }
  }

  if (!baseDate) {
    const months: Record<string, number> = {
      january: 0, february: 1, march: 2, april: 3, may: 4, june: 5,
      july: 6, august: 7, september: 8, october: 9, november: 10, december: 11,
    };

    const monthDay = /(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:st|nd|rd|th)?/i.exec(lower);
    if (monthDay) {
      const month = months[monthDay[1].toLowerCase()];
      const day = parseInt(monthDay[2], 10);
      let year = today.getFullYear();
      if (month < today.getMonth() || (month === today.getMonth() && day < today.getDate())) {
        year += 1;
      }
      baseDate = new Date(year, month, day);
      namedDate = true;
    }

    if (!baseDate) {
      const dayMonth = /(\d{1,2})(?:st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december)/i.exec(lower);
      if (dayMonth) {
        const day = parseInt(dayMonth[1], 10);
        const month = months[dayMonth[2].toLowerCase()];
        let year = today.getFullYear();
        if (month < today.getMonth() || (month === today.getMonth() && day < today.getDate())) {
          year += 1;
        }
        baseDate = new Date(year, month, day);
        namedDate = true;
      }
    }

    if (!baseDate) {
      const numeric = /(\d{1,2})\s*[\/\-]\s*(\d{1,2})/.exec(lower);
      if (numeric) {
        const a = parseInt(numeric[1], 10);
        const b = parseInt(numeric[2], 10);
        if (a >= 1 && a <= 12 && b >= 1 && b <= 31) {
          let month = a - 1;
          let day = b;
          if (month > today.getMonth() || (month === today.getMonth() && day >= today.getDate())) {
            let year = today.getFullYear();
            baseDate = new Date(year, month, day);
            if (baseDate.getTime() >= today.getTime()) {
              namedDate = true;
            }
          }
        }
        if (!namedDate && b >= 1 && b <= 12 && a >= 1 && a <= 31) {
          let month = b - 1;
          let day = a;
          let year = today.getFullYear();
          if (month < today.getMonth() || (month === today.getMonth() && day < today.getDate())) {
            year += 1;
          }
          baseDate = new Date(year, month, day);
          namedDate = true;
        }
      }
    }
  }

  if (!baseDate) return null;

  if (baseDate.getTime() < today.getTime() && !namedDate) {
    baseDate = new Date(baseDate.getTime() + 86400000);
  }

  return { date: baseDate, userExplicitDate: namedDate };
}

export function resolveTimeOnly(rawTimeText: string): ResolvedTime | null {
  if (isSkip(rawTimeText)) return null;

  const lower = rawTimeText.toLowerCase();

  const ampm = /(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i.exec(lower);
  if (ampm) {
    let hour = parseInt(ampm[1], 10);
    const minute = ampm[2] ? parseInt(ampm[2], 10) : 0;
    const period = ampm[3].toLowerCase();
    if (period === 'pm' && hour < 12) hour += 12;
    if (period === 'am' && hour === 12) hour = 0;
    return { hour, minute };
  }

  const military = /(\d{1,2}):(\d{2})\s*(hours?)?/i.exec(lower);
  if (military) {
    const hour = parseInt(military[1], 10);
    const minute = parseInt(military[2], 10);
    if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
      return { hour, minute };
    }
  }

  if (/\b\d{1,2}\s*(pm|am)\b/i.test(lower)) {
    const match = /\b(\d{1,2})\s*(pm|am)\b/i.exec(lower);
    let hour = parseInt(match![1], 10);
    const period = match![2].toLowerCase();
    if (period === 'pm' && hour < 12) hour += 12;
    if (period === 'am' && hour === 12) hour = 0;
    return { hour, minute: 0 };
  }

  if (lower.includes('midnight')) return { hour: 0, minute: 0 };
  if (lower.includes('noon')) return { hour: 12, minute: 0 };
  if (lower.includes('morning')) return { hour: 9, minute: 0 };
  if (lower.includes('afternoon')) return { hour: 14, minute: 0 };
  if (lower.includes('evening')) return { hour: 18, minute: 0 };

  if (/at\s+(\d{1,2})\b/.test(lower)) {
    const match = /at\s+(\d{1,2})\b/.exec(lower);
    const hour = parseInt(match![1], 10);
    if (hour >= 1 && hour <= 12) return { hour: hour < 7 ? hour + 12 : hour, minute: 0 };
    if (hour >= 13 && hour <= 23) return { hour, minute: 0 };
  }

  return null;
}

export function resolveDateAndTime(text: string, now: Date = new Date()): { date: ResolvedDate | null; time: ResolvedTime | null } {
  const date = resolveDateOnly(text, now);
  const time = resolveTimeOnly(text);
  return { date, time };
}

export function combineDateTime(date: Date, time: ResolvedTime | null): Date {
  if (!time) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59);
  }
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), time.hour, time.minute);
}

export function resolveDueDate(rawDateText: string, now: Date = new Date()): ResolvedDate | null {
  const lower = rawDateText.toLowerCase();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  let baseDate: Date | null = null;
  let namedDate = false;

  if (lower.includes('today')) {
    baseDate = new Date(today);
    namedDate = true;
  } else if (lower.includes('tomorrow')) {
    baseDate = new Date(today.getTime() + 86400000);
    namedDate = true;
  } else if (lower.includes('next week')) {
    baseDate = new Date(today.getTime() + 7 * 86400000);
    namedDate = true;
  } else if (lower.includes('next month')) {
    const nextMonth = today.getMonth() + 1 > 11 ? 0 : today.getMonth() + 1;
    const nextYear = today.getMonth() + 1 > 11 ? today.getFullYear() + 1 : today.getFullYear();
    baseDate = new Date(nextYear, nextMonth, today.getDate());
    namedDate = true;
  } else if (lower.includes('next year')) {
    baseDate = new Date(today.getFullYear() + 1, today.getMonth(), today.getDate());
    namedDate = true;
  } else {
    const weekdays: Record<string, number> = {
      monday: 1, tuesday: 2, wednesday: 3, thursday: 4,
      friday: 5, saturday: 6, sunday: 7,
    };
    for (const [name, target] of Object.entries(weekdays)) {
      if (lower.includes(name)) {
        const current = today.getDay() || 7;
        let diff = target - current;
        if (diff <= 0) diff += 7;
        baseDate = new Date(today.getTime() + diff * 86400000);
        namedDate = true;
        break;
      }
    }

    if (!baseDate) {
      const dateRegex = /(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:st|nd|rd|th)?/i;
      const match = dateRegex.exec(lower);
      if (match) {
        const months: Record<string, number> = {
          january: 0, february: 1, march: 2, april: 3, may: 4, june: 5,
          july: 6, august: 7, september: 8, october: 9, november: 10, december: 11,
        };
        const month = months[match[1].toLowerCase()];
        const day = parseInt(match[2], 10);
        let year = today.getFullYear();
        if (month < today.getMonth() || (month === today.getMonth() && day < today.getDate())) {
          year += 1;
        }
        baseDate = new Date(year, month, day);
        namedDate = true;
      }
    }
  }

  if (!baseDate) return null;

  const parsed = extractTime(baseDate, lower);

  if (parsed.getTime() < now.getTime() && !namedDate) {
    const tomorrow = extractTime(
      new Date(baseDate.getTime() + 86400000),
      lower,
    );
    return { date: tomorrow, userExplicitDate: false };
  }

  return { date: parsed, userExplicitDate: namedDate };
}

function extractTime(date: Date, text: string): Date {
  const lower = text.toLowerCase();
  const timeRegex = /(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i;
  const match = timeRegex.exec(lower);
  if (match) {
    let hour = parseInt(match[1], 10);
    const min = match[2] ? parseInt(match[2], 10) : 0;
    const ampm = match[3].toLowerCase();
    if (ampm === 'pm' && hour < 12) hour += 12;
    if (ampm === 'am' && hour === 12) hour = 0;
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), hour, min);
  }
  if (lower.includes('morning')) return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 9);
  if (lower.includes('afternoon')) return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 14);
  if (lower.includes('evening')) return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 18);
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59);
}

export function formatDateOnly(dt: Date): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const date = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate());
  const diff = Math.round((date.getTime() - today.getTime()) / 86400000);

  if (diff === 0) return 'today';
  if (diff === 1) return 'tomorrow';
  if (diff === 2) return 'the day after tomorrow';

  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  if (diff > 1 && diff <= 7) return dayNames[dt.getDay()];

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const suffix = daySuffix(dt.getDate());
  return `${months[dt.getMonth()]} ${dt.getDate()}${suffix}`;
}

export function formatTimeOnly(dt: Date): string {
  const hours = dt.getHours();
  const minutes = dt.getMinutes();
  const hour12 = hours > 12 ? hours - 12 : (hours === 0 ? 12 : hours);
  const amPm = hours >= 12 ? 'PM' : 'AM';
  if (minutes === 0) return `${hour12} ${amPm}`;
  return `${hour12}:${minutes.toString().padStart(2, '0')} ${amPm}`;
}

export function formatDateShort(dt: Date): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const date = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate());
  const diff = Math.round((date.getTime() - today.getTime()) / 86400000);

  const hours = dt.getHours();
  const minutes = dt.getMinutes();
  const hour12 = hours > 12 ? hours - 12 : (hours === 0 ? 12 : hours);
  const amPm = hours >= 12 ? 'PM' : 'AM';

  if (diff === 0) return `today at ${hour12} ${amPm}`;
  if (diff === 1) return `tomorrow at ${hour12} ${amPm}`;

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const suffix = daySuffix(dt.getDate());
  const min = minutes.toString().padStart(2, '0');
  return `${months[dt.getMonth()]} ${dt.getDate()}${suffix} at ${hour12}:${min} ${amPm}`;
}

function daySuffix(day: number): string {
  if (day >= 11 && day <= 13) return 'th';
  switch (day % 10) {
    case 1: return 'st';
    case 2: return 'nd';
    case 3: return 'rd';
    default: return 'th';
  }
}

export function parsePriority(text: string): 'LOW' | 'MEDIUM' | 'HIGH' {
  const lower = text.toLowerCase();
  if (lower.includes('high') || lower.includes('urgent') || lower.includes('important')) return 'HIGH';
  if (lower.includes('low') || lower.includes('minor') || lower.includes('easy')) return 'LOW';
  return 'MEDIUM';
}
