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
  (date: string) => `Due ${date}. What priority — Low, Medium, or High?`,
  (date: string) => `${date}, cool. Set a priority? Low, Medium, or High?`,
  (date: string) => `${date} it is. Low, Medium, or High?`,
  (date: string) => `So ${date}. Pick a priority: Low, Medium, or High.`,
];

export const DATE_FALLBACK_PROMPTS = [
  "No worries, skip the date. What priority — Low, Medium, or High?",
  "Let's skip the deadline. Low, Medium, or High priority?",
  "Alright, no due date. Low, Medium, or High?",
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
