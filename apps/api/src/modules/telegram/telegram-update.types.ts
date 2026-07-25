/**
 * Minimal shape of the Telegram Bot API `Update` (webhook payload) that we act
 * on. Declared as interfaces (not classes) so the global ValidationPipe does
 * not strip or reject Telegram's many extra fields — we read only what we need.
 */
export interface TelegramChat {
  id?: number;
  type?: string;
}

export interface TelegramSuccessfulPayment {
  currency?: string;
  total_amount?: number;
  invoice_payload?: string;
  telegram_payment_charge_id?: string;
}

export interface TelegramMessage {
  message_id?: number;
  text?: string;
  chat?: TelegramChat;
  from?: { id?: number; first_name?: string };
  successful_payment?: TelegramSuccessfulPayment;
}

export interface TelegramPreCheckoutQuery {
  id?: string;
  from?: { id?: number };
  currency?: string;
  total_amount?: number;
  invoice_payload?: string;
}

export interface TelegramUpdate {
  update_id?: number;
  message?: TelegramMessage;
  pre_checkout_query?: TelegramPreCheckoutQuery;
}
