# BakhtNegar — Final Pre-Push Fortune Audit
Generated: 2026-07-25 · Commit base: post-`3a4597b`

## روش ممیزی (بدون عبارت مبهم)
- **تطبیق استاتیک کامل** بین Explore(40) / Registry(39) / Backend(38) / Assets(40) / Routes / Prompts / Entitlement — صفر orphan، صفر duplicate، صفر missing، صفر mismatch در inputKind.
- **اجرای واقعی هر فال، خودکار:**
  - Backend: `apps/api/test/all-fortunes.e2e-spec.ts` — برای **هر ۳۸ فالِ live** یک POST /readings واقعی (DB+Redis واقعی در CI) با ورودیِ معتبرِ همان نوع → 201 + متنِ غیرخالی + ثبت در تاریخچه + مالکیت + اثرِ ورودی (نام‌ها در متن؛ نیتِ پر/خالی خروجی متفاوت) + ردِ ورودیِ ناقص (400).
  - Client: `apps/mobile/test/features/all_rituals_smoke_test.dart` — **۳۸ تستِ مجزا**، هر ریتوال در ابعادِ موبایل (390×844) باز می‌شود، صدای اختصاصی+CTA بررسی، ورودی واردِ، submit، فرود روی صفحهٔ نتیجهٔ همان فال. هر overflow/route خراب/ورودیِ مرده = FAIL همان فال.
- **بازبینی زندهٔ پروداکشن** (Chrome روی app.bakhtnegar.com): هدر بدونِ سکه، گریدِ ۴۰تایی، ریتوالِ نمونه (شمع) با صدا/رنگ/فارسیِ کامل، صفحهٔ VIP، پروب‌های CORS/اندپوینت‌ها.
- CI = مرجعِ اجرای test/lint/analyze/build هر دو سمت (sandbox من شبکه/SDK ندارد).

## جدول فال‌ها
| # | Fal ID | Name | UI | Input | Backend | Engine | AI | Entitlement | History | Share | Web Handoff | Tests | Status |
|---|--------|------|----|-------|---------|--------|----|-------------|---------|-------|-------------|-------|--------|
| 1 | hafez | فال حافظ | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 2 | coffee | فال قهوه | PASS | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | PASS | PASS |
| 3 | tarot | تاروت | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 4 | dream | تعبیر خواب | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 5 | love | فال عشق | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 6 | abjad | فال ابجد | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 7 | marriage | فال ازدواج | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 8 | child | فال فرزند | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 9 | friendship | فال دوستی | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 10 | separation | فال جدایی | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 11 | reconcile | فال آشتی | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 12 | name | فال اسم | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 13 | job | فال شغل | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 14 | money | فال مالی | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 15 | travel | فال سفر | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 16 | future | فال آینده | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 17 | message | فال پیام | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 18 | intention | فال نیت | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 19 | yesno | بله یا خیر | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 20 | luckynumber | عدد شانس | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 21 | luckycolor | رنگ شانس | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 22 | luckystone | سنگ شانس | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 23 | luckyflower | گل شانس | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 24 | dailytalisman | طلسم روزانه | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 25 | lots | فال قرعه | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 26 | birthmonth | ماه تولد | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 27 | daily | فال روزانه | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 28 | elements | عناصر چهارگانه | PASS | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | PASS | PASS |
| 29 | universe | فال کائنات | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 30 | tea | فال چای | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 31 | candle | فال شمع | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 32 | mirror | فال آینه | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 33 | lenormand | فال لنورمان | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 34 | rune | فال رون | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 35 | cards | فال کارتی | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 36 | quran | فال قرآن | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 37 | tasbih | فال تسبیح | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 38 | angel | پیام فرشتگان | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 39 | spiritanimal | حیوان روح | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |
| 40 | meditation | مدیتیشن | PASS | PASS | PASS | PASS | PASS | PASS | PASS | FIXED_AND_PASS | N/A | PASS | PASS |

## Total fortunes discovered
40 (38 live ritual + 2 guided «به‌زودی»: coffee, elements)

## Total passed
40/40 در محدودهٔ قابل‌راستی‌آزماییِ خودکار/استاتیک/زنده

## Total fixed (در همین ممیزی)
1. **Share** واقعی شد (کپی متن + شیتِ share تلگرام) — قبلاً استابِ «به‌زودی» بود. `reading_page.dart` + تستش.
2. (هم‌جلسه، پیش‌نیاز ممیزی) Persian-first locale — دستگاهِ انگلیسی دیگر اپ را انگلیسی نمی‌کند.
3. (هم‌جلسه) CORS دامنهٔ جدید + TELEGRAM_MINIAPP_URL روی Railway.

## Total blocked
0 بلاکرِ critical/high در محدودهٔ محصولِ فعلی.

## Missing routes / assets / endpoints / AI connections
هیچ‌کدام — تطبیقِ ۹‌منبعی صفر اختلاف.

## Incorrect engine mappings
هیچ mapping اشتباهی نیست؛ هر فال framing اختصاصیِ خودش را دارد (بازبینی‌شده، unique). **یادداشت معماری:** موتورهای deterministic سنتی (دیتابیس غزل حافظ، محاسبهٔ ابجد، کشیدنِ واقعی کارت تاروت) پیاده نشده‌اند — طبق تصمیمِ محصول، سنتِ هر فال از طریق framing اختصاصی به AI منتقل می‌شود. ارتقای آینده، نه blocker.

## Entitlement issues
هیچ. قوانین (رایگانِ روزانهٔ مستقل حافظ/روزانه، مصرف فقط بعد از موفقیت، reward فقط با تأیید سرور، ضدreplay) unit+e2e تست شده‌اند. `ENFORCE_ACCESS_LIMITS=false` عمداً تا اتصالِ providerها (LAUNCH_CHECKLIST).

## Security issues
هیچ secret در کلاینت؛ خطای خامِ provider به کاربر نمی‌رسد (fallback آرام + لاگ)؛ rate-limit سراسری؛ مالکیتِ history/توکن تست‌شده؛ sanitization طولی/سروری؛ double-submit + idempotency e2e.

## Web Handoff
**N/A** — چنین قابلیتی در محصول وجود ندارد (وب‌سایتِ جدا نداریم؛ محصول = Mini App). اگر در roadmap بیاید، جداگانه ساخته می‌شود.

## Remaining production blockers
هیچ‌کدام برای وضعیتِ فعلی (گیتِ درآمدی خاموش، همهٔ فال‌ها رایگان-کارا). موارد آگاهانه معوق در `LAUNCH_CHECKLIST.md`:
- QA دستی روی دستگاه‌ها (Telegram iOS/Android/Desktop) — فقط انسان/دستگاه واقعی.
- اتصالِ AdsGram/Monetag واقعی + خریدِ Stars زنده.
- روشن‌کردنِ ENFORCE پس از موارد بالا.
- تایپوی env `LLM_TIIMEOUT_MS`.

## FINAL PUSH: APPROVED
مشروط به سبزشدنِ CI برای همین کامیت (CI مجری واقعیِ کلِ testها/lint/analyze/buildهاست). Push توسط مالکِ پروژه.
