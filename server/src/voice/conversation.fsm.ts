import { pick, GREETING_PROMPTS, RETRY_PROMPTS, CONFIRM_TASK_PROMPTS, DATE_CONFIRM_PROMPTS, DATE_FALLBACK_PROMPTS, PRIORITY_CONFIRM_PROMPTS } from './prompts';
import { resolveDueDate, formatDateShort, formatDateOnly, parsePriority } from './date-resolver';

export enum ConvoState {
  GREETING = 'greeting',
  AWAITING_TASK = 'awaitingTask',
  AWAITING_DATE = 'awaitingDate',
  AWAITING_PRIORITY = 'awaitingPriority',
  SAVING = 'saving',
  DONE = 'done',
}

export interface ConversationSession {
  userId: string;
  userName: string;
  state: ConvoState;
  taskTitle: string;
  dueDate: Date | null;
  priority: 'LOW' | 'MEDIUM' | 'HIGH';
  retryCount: number;
  lastGreetingIndex: number;
  lastConfirmTaskIndex: number;
  lastDateConfirmIndex: number;
  lastDateFallbackIndex: number;
  lastPriorityConfirmIndex: number;
  lastRetryIndex: number;
}

export interface ActionResult {
  text: string;
  state: ConvoState;
}

export const MAX_RETRIES = 2;
const SKIP_WORDS = new Set(['skip', 'none', 'nope', 'nah', 'no date', "don't have", 'not sure', 'whatever', 'no', 'not really', 'never mind']);

function isExactSkip(text: string): boolean {
  const lower = text.toLowerCase().trim();
  return SKIP_WORDS.has(lower) || SKIP_WORDS.has(lower.replace(/[^a-z\s]/g, '').trim());
}

export function createSession(userId: string, userName: string): ConversationSession {
  return {
    userId,
    userName,
    state: ConvoState.GREETING,
    taskTitle: '',
    dueDate: null,
    priority: 'MEDIUM',
    retryCount: 0,
    lastGreetingIndex: -1,
    lastConfirmTaskIndex: -1,
    lastDateConfirmIndex: -1,
    lastDateFallbackIndex: -1,
    lastPriorityConfirmIndex: -1,
    lastRetryIndex: -1,
  };
}

export function getGreeting(session: ConversationSession): ActionResult {
  const { value, index } = pick(GREETING_PROMPTS, session.lastGreetingIndex);
  session.lastGreetingIndex = index;
  session.state = ConvoState.AWAITING_TASK;
  session.retryCount = 0;
  return { text: value(session.userName), state: ConvoState.AWAITING_TASK };
}

export function processTranscript(session: ConversationSession, transcript: string): ActionResult | null {
  const trimmed = transcript.trim();
  if (!trimmed) {
    if (session.retryCount < MAX_RETRIES) {
      session.retryCount++;
      const { value, index } = pick(RETRY_PROMPTS, session.lastRetryIndex);
      session.lastRetryIndex = index;
      return { text: value, state: session.state };
    }
    return null;
  }

  session.retryCount = 0;

  switch (session.state) {
    case ConvoState.AWAITING_TASK:
      session.taskTitle = trimmed;
      {
        const { value, index } = pick(CONFIRM_TASK_PROMPTS, session.lastConfirmTaskIndex);
        session.lastConfirmTaskIndex = index;
        session.state = ConvoState.AWAITING_DATE;
        return { text: value(session.taskTitle), state: ConvoState.AWAITING_DATE };
      }

    case ConvoState.AWAITING_DATE: {
      if (isExactSkip(trimmed)) {
        const { value, index } = pick(DATE_FALLBACK_PROMPTS, session.lastDateFallbackIndex);
        session.lastDateFallbackIndex = index;
        session.state = ConvoState.AWAITING_PRIORITY;
        return { text: value, state: ConvoState.AWAITING_PRIORITY };
      }

      const resolved = resolveDueDate(trimmed);
      if (resolved) {
        session.dueDate = resolved.date;
        const dateStr = formatDateOnly(resolved.date);
        const { value, index } = pick(DATE_CONFIRM_PROMPTS, session.lastDateConfirmIndex);
        session.lastDateConfirmIndex = index;
        session.state = ConvoState.AWAITING_PRIORITY;
        return { text: value(dateStr), state: ConvoState.AWAITING_PRIORITY };
      }

      if (session.retryCount < MAX_RETRIES) {
        session.retryCount++;
        return {
          text: "I didn't get the date. Try 'tomorrow', 'next Monday', or 'March 15'.",
          state: ConvoState.AWAITING_DATE,
        };
      }
      const { value, index } = pick(DATE_FALLBACK_PROMPTS, session.lastDateFallbackIndex);
      session.lastDateFallbackIndex = index;
      session.state = ConvoState.AWAITING_PRIORITY;
      return { text: value, state: ConvoState.AWAITING_PRIORITY };
    }

    case ConvoState.AWAITING_PRIORITY: {
      session.priority = parsePriority(trimmed);
      const { value, index } = pick(PRIORITY_CONFIRM_PROMPTS, session.lastPriorityConfirmIndex);
      session.lastPriorityConfirmIndex = index;
      session.state = ConvoState.SAVING;
      return { text: value(session.taskTitle), state: ConvoState.SAVING };
    }
  }

  return null;
}
