/** The authenticated caller (doc 52 §28). Populated by the auth guard. */
export interface AuthenticatedPrincipal {
  userId: string;
  telegramId?: string;
  roles: readonly string[];
}
