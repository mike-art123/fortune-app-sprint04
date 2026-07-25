import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../common/exceptions/domain.exception';
import { VipConfig, type VipPlan } from '../../config/vip.config';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import { AppLoggerService } from '../../infrastructure/logging/app-logger.service';
import { TelegramBotService } from './telegram-bot.service';
import type { TelegramUpdate } from './telegram-update.types';

export interface VipPlanView {
  id: string;
  titleFa: string;
  stars: number;
  days: number;
}

export interface VipStatusView {
  isVip: boolean;
  plan: string | null;
  expiresAt: string | null;
  plans: VipPlanView[];
}

const PAYLOAD_PREFIX = 'vip';

/**
 * VIP payments over Telegram Stars (XTR) — the only payment method. The client
 * asks for an invoice link and opens it inside Telegram; Telegram then drives
 * our webhook: pre_checkout_query is validated against the payload and plan,
 * and successful_payment activates (or extends) the subscription exactly once —
 * the stored telegram_payment_charge_id makes webhook retries idempotent.
 * VIP status itself is always read server-side; the client never asserts it.
 */
@Injectable()
export class TelegramPaymentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly bot: TelegramBotService,
    private readonly vip: VipConfig,
    private readonly logger: AppLoggerService,
  ) {}

  async status(userId: string, now: Date = new Date()): Promise<VipStatusView> {
    const subscription = await this.prisma.subscription.findUnique({ where: { userId } });
    const active =
      subscription !== null &&
      subscription.status === 'active' &&
      subscription.currentPeriodEnd.getTime() > now.getTime();
    return {
      isVip: active,
      plan: active ? subscription.plan : null,
      expiresAt: active ? subscription.currentPeriodEnd.toISOString() : null,
      plans: this.vip.plans.map((p) => ({
        id: p.id,
        titleFa: p.titleFa,
        stars: p.stars,
        days: p.days,
      })),
    };
  }

  /** Create a Stars invoice link for one plan, bound to this user. */
  async createInvoiceLink(userId: string, planId: string): Promise<{ link: string }> {
    const plan = this.vip.planById(planId);
    if (!plan) {
      throw new DomainException('NOT_FOUND', 'این طرح را نمی‌شناسیم.', {
        status: HttpStatus.NOT_FOUND,
      });
    }

    const payload = `${PAYLOAD_PREFIX}:${userId}:${plan.id}:${Date.now().toString(36)}`;
    const res = await this.bot.api('createInvoiceLink', {
      title: 'عضویت ویژه بخت‌نگار',
      description: `${plan.titleFa} — همهٔ فال‌ها بدون تبلیغ و بدون محدودیت روزانه`,
      payload,
      currency: 'XTR',
      prices: [{ label: plan.titleFa, amount: plan.stars }],
    });
    if (!res.ok || typeof res.result !== 'string') {
      throw new DomainException('INTERNAL', 'ساختِ صورت‌حساب ناموفق بود؛ دوباره تلاش کن.', {
        status: HttpStatus.BAD_GATEWAY,
        retryable: true,
        developerMessage: res.description ?? 'createInvoiceLink failed',
      });
    }
    return { link: res.result };
  }

  /** Webhook dispatch: payment updates only; everything else is ignored. */
  async handleUpdate(update: TelegramUpdate): Promise<void> {
    if (update.pre_checkout_query) {
      await this.handlePreCheckout(update.pre_checkout_query);
      return;
    }
    if (update.message?.successful_payment) {
      await this.handleSuccessfulPayment(update.message);
    }
  }

  private async handlePreCheckout(
    query: NonNullable<TelegramUpdate['pre_checkout_query']>,
  ): Promise<void> {
    const parsed = this.parsePayload(query.invoice_payload);
    const plan = parsed ? this.vip.planById(parsed.planId) : null;
    const ok =
      parsed !== null &&
      plan !== null &&
      query.currency === 'XTR' &&
      query.total_amount === plan.stars;

    await this.bot.api('answerPreCheckoutQuery', {
      pre_checkout_query_id: query.id,
      ok,
      ...(ok ? {} : { error_message: 'این پرداخت معتبر نیست؛ دوباره تلاش کن.' }),
    });
    this.logger.info('telegram.payment.precheckout', { ok, payload: query.invoice_payload });
  }

  private async handleSuccessfulPayment(
    message: NonNullable<TelegramUpdate['message']>,
  ): Promise<void> {
    const payment = message.successful_payment;
    if (!payment) return;
    const parsed = this.parsePayload(payment.invoice_payload);
    const plan = parsed ? this.vip.planById(parsed.planId) : null;
    if (!parsed || !plan) {
      this.logger.error('telegram.payment.unparseable', {
        payload: payment.invoice_payload ?? null,
      });
      return;
    }

    const user = await this.prisma.user.findUnique({ where: { id: parsed.userId } });
    if (!user) {
      this.logger.error('telegram.payment.unknown_user', { userId: parsed.userId });
      return;
    }
    const payerId = message.from?.id;
    if (payerId != null && String(payerId) !== user.telegramId) {
      this.logger.error('telegram.payment.payer_mismatch', {
        userId: parsed.userId,
        payerId: String(payerId),
      });
      return;
    }

    const chargeId = payment.telegram_payment_charge_id ?? null;
    await this.activate(parsed.userId, plan, chargeId);
  }

  /** Activate or extend, exactly once per charge id (webhook retries safe). */
  private async activate(userId: string, plan: VipPlan, chargeId: string | null): Promise<void> {
    const now = new Date();
    const current = await this.prisma.subscription.findUnique({ where: { userId } });

    if (chargeId && current?.platformTransactionId === chargeId) {
      this.logger.info('telegram.payment.replayed', { userId, chargeId });
      return;
    }

    const activeUntil =
      current && current.status === 'active' && current.currentPeriodEnd.getTime() > now.getTime()
        ? current.currentPeriodEnd
        : now;
    const currentPeriodEnd = new Date(activeUntil.getTime() + plan.days * 24 * 3600 * 1000);

    await this.prisma.subscription.upsert({
      where: { userId },
      create: {
        userId,
        plan: plan.id,
        status: 'active',
        currentPeriodEnd,
        platformTransactionId: chargeId,
      },
      update: {
        plan: plan.id,
        status: 'active',
        currentPeriodEnd,
        platformTransactionId: chargeId,
      },
    });
    this.logger.info('telegram.payment.activated', {
      userId,
      plan: plan.id,
      until: currentPeriodEnd.toISOString(),
    });
  }

  private parsePayload(payload: string | undefined): { userId: string; planId: string } | null {
    if (!payload) return null;
    const parts = payload.split(':');
    if (parts.length !== 4 || parts[0] !== PAYLOAD_PREFIX) return null;
    const userId = parts[1] ?? '';
    const planId = parts[2] ?? '';
    if (userId.length === 0 || planId.length === 0) return null;
    return { userId, planId };
  }
}
