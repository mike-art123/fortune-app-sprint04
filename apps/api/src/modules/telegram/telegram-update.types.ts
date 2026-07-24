/**
 * Minimal shape of the Telegram Bot API `Update` (webhook payload) that we act
 * on. Declared as interfaces (not classes) so the global ValidationPipe does
 * not strip or reject Telegram's many extra fields — we read only what we need.
 */
export interface TelegramChat {
  id?: number;
  type?: string;
}

export interface TelegramMessage {
  message_id?: number;
  text?: string;
  chat?: TelegramChat;
  from?: { id?: number; first_name?: string };
}

export interface TelegramUpdate {
  update_id?: number;
  message?: TelegramMessage;
}
