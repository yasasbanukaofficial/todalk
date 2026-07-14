export const GREETING_PROMPTS = [
  (name: string) => `Hey ${name}, what do you need to get done?`,
  (name: string) => `${name}, what's the task?`,
  (name: string) => `What are we adding, ${name}?`,
  (name: string) => `${name}, tell me what to put on your list.`,
];

export const RETRY_PROMPTS = [
  "Sorry, didn't catch that. Say it again?",
  "Missed it — one more time?",
  "Didn't get it. Could you repeat?",
  "Hmm, didn't hear you. Try again?",
];

export const CONFIRM_TASK_PROMPTS = [
  (title: string) => `Got it — ${title}. When's it due?`,
  (title: string) => `${title}, noted. Need a due date for this?`,
  (title: string) => `Okay, ${title}. What's the deadline?`,
  (title: string) => `${title}, got it. When do you need it by?`,
];

export const DATE_CONFIRM_PROMPTS = [
  (date: string) => `${date}. What time?`,
  (date: string) => `Due ${date} — what time?`,
  (date: string) => `Okay, ${date}. Got a time?`,
  (date: string) => `${date}. When's the time?`,
];

export const DATE_FALLBACK_PROMPTS = [
  "No worries, skip the date. What time?",
  "Let's skip the date. Got a time?",
  "Alright, no due date. Any preferred time?",
];

export const TIME_FALLBACK_PROMPTS = [
  "No problem, no time. What priority — Low, Medium, or High?",
  "Skip the time. Low, Medium, or High priority?",
  "Alright. Low, Medium, or High?",
];

export const TIME_CONFIRM_PROMPTS = [
  (time: string) => `${time}. What priority — Low, Medium, or High?`,
  (time: string) => `At ${time}. Set priority: Low, Medium, or High?`,
  (time: string) => `${time}. Low, Medium, or High?`,
  (time: string) => `So ${time}. Pick a priority.`,
];

export const PRIORITY_CONFIRM_PROMPTS = [
  (title: string) => `Done — ${title} is on your list.`,
  (title: string) => `Added. ${title}, all set.`,
  (title: string) => `That's saved — ${title}.`,
  (title: string) => `${title} is in. You're good.`,
];

export function pick<T>(pool: T[], lastIndex: number): { value: T; index: number } {
  let index = Math.floor(Math.random() * pool.length);
  if (index === lastIndex && pool.length > 1) {
    index = (index + 1) % pool.length;
  }
  return { value: pool[index], index };
}
