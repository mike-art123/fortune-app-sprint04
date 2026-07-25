# چک‌لیستِ نهایی‌سازی (قبل از لانچ)

موارد توافق‌شده که «وقتی برنامه نهایی شد» انجام می‌شوند — 2026-07-25.

## 1) تست داخل تلگرام
- [ ] یک فال حافظ بگیر → باید مستقیم و رایگان بیاید (سهمیهٔ روزانه).
- [ ] صفحهٔ «عضویت ویژه» را باز کن → طرح‌ها + دکمهٔ خرید → شیتِ Stars تلگرام.
- [ ] فال دوم حافظ در همان روز (بعد از ENFORCE) → شیتِ دوگزینه‌ای.

## 2) فعال‌سازی تبلیغ واقعی
- [ ] از پنل AdsGram: `ADSGRAM_BLOCK_ID` + سکرت reward → ست در Railway.
- [ ] از پنل Monetag: `MONETAG_ZONE_ID` + سکرت postback → ست در Railway.
- [ ] Reward URL در پنل AdsGram:
      `https://fortune-app-sprint04-production.up.railway.app/api/v1/ads/callback/adsgram?sid={payload}&uid={userid}&token=<SECRET>`
- [ ] S2S postback در پنل Monetag:
      `https://fortune-app-sprint04-production.up.railway.app/api/v1/ads/callback/monetag?sid={var3}&uid={ymid}&token=<SECRET>`

## 3) روشن‌کردن گیت دسترسی
- [ ] بعد از تستِ کاملِ 1 و 2: در Railway → `ENFORCE_ACCESS_LIMITS=true`.

## 4) جزئی
- [ ] تایپوی env در Railway: `LLM_TIIMEOUT_MS` → حذف و `LLM_TIMEOUT_MS` (فعلاً بی‌اثر؛ پیش‌فرض 20s).

## یادداشت‌های فنی
- قیمت‌های VIP (ستاره): `VIP_MONTHLY_STARS` / `VIP_QUARTERLY_STARS` / `VIP_ANNUAL_STARS` (پیش‌فرض 250/600/2000).
- سقف روزانهٔ تبلیغ: `REWARDED_ADS_DAILY_LIMIT` (پیش‌فرض 5).
- فال‌های رایگانِ روزانه: `FREE_DAILY_FORTUNE_IDS` (پیش‌فرض hafez,daily).
- کارِ طراحیِ در صف: فاز ۳ داخلی — خطِ ریتوالِ اختصاصیِ هر فال.
