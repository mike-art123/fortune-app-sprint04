# بخت‌نگار — مانیفستِ کاملِ اَست‌ها (نسخهٔ نهایی)

۴۰ تصویرِ فال آماده است. این‌جا **بقیهٔ همه‌چیز** است: از پس‌زمینه و هدر تا داخلِ فلوها.

---

## ۰) اسپکِ سبک — این را همیشه رعایت کن (تا همه هم‌خانواده شوند)

**رنگ‌ها:** طلا `#F6DF9A / #E7C25E / #D9A83E / #A9782A`، برنز، نیویِ عمیق `#0D1732 / #05070F`، اکسنتِ بنفش `#A78BFA`.

**۲ سبک داریم:**

1. **سبکِ تصویر (painterly)** — برای پس‌زمینه‌ها و آرت‌های بزرگ. آخرِ پرامپت بگذار:
   `luxurious Persian mystical, deep midnight-navy and black, warm gold and bronze filigree, soft golden bloom, faint stars, ornate elegant, high detail, cinematic lighting`

2. **سبکِ آیکون (emblem)** — برای همهٔ آیکون‌ها (اکشن‌ها، هدر، نمادها). آخرِ پرامپت بگذار:
   `ornate gold emblem app icon, single centered symbol, polished gold and bronze, subtle warm glow, deep navy background, symmetrical, no text, clean, matching a luxury Persian fortune-app icon set`

**قانونِ طلاییِ هماهنگی:** اول یک آیکون بساز که پسندیدی، بعد لینکش را با **`--sref <URL>`** به بقیهٔ آیکون‌ها بده تا همه یک‌دست شوند. همه `--ar 1:1`.

**پس‌زمینهٔ شفاف:** فقط برای آیکون‌هایی که روی هر جایی می‌نشینند (کوین/جم/تاج). اگر Firefly transparent نداشت، روی نیویِ ساده بساز؛ من با Adobe برش می‌زنم. بقیهٔ آیکون‌ها روی نیوی بمانند (مثلِ چیپ‌های مرجع).

---

## 🟥 اولویتِ ۱ — با این ۱۰ تا، Home و هدر «مو به مو» می‌شود

| فایل | پوشه | نسبت / پس‌زمینه | پرامپت (+ سبک) |
|---|---|---|---|
| `bg_hero.jpg` | `assets/bg/` | 3:2 / تیره | **[سبکِ تصویر]** `ornate Persian arch window at night, distant mosque domes silhouette, glowing lanterns, lit candles, crescent moon and stars, vase of flowers, empty center, NO text` |
| `icon_coin.png` | `assets/icons/` | 1:1 / شفاف | **[سبکِ آیکون]** `a single shiny gold coin with a star emblem` |
| `icon_gem.png` | `assets/icons/` | 1:1 / شفاف | **[سبکِ آیکون]** `a single faceted purple amethyst gem, glowing` |
| `icon_vip.png` | `assets/icons/` | 1:1 / شفاف | **[سبکِ آیکون]** `a small ornate golden royal crown` |
| `qa_daily.png` | `assets/icons/` | 1:1 / نیوی | **[سبکِ آیکون]** `a golden crescent moon with a small sun` |
| `qa_reward.png` | `assets/icons/` | 1:1 / نیوی | **[سبکِ آیکون]** `a golden gift box with ribbon` |
| `qa_luck.png` | `assets/icons/` | 1:1 / نیوی | **[سبکِ آیکون]** `a golden four-leaf clover` |
| `qa_calendar.png` | `assets/icons/` | 1:1 / نیوی | **[سبکِ آیکون]** `a golden ornate calendar page` |
| `qa_estekhare.png` | `assets/icons/` | 1:1 / نیوی | **[سبکِ آیکون]** `a golden holy book with prayer beads` |
| `reward_chest.png` | `assets/store/` | 1:1 / شفاف یا تیره | **[سبکِ تصویر]** `an open golden treasure chest overflowing with glowing coins, sparkles` |

---

## 🟨 اولویتِ ۲

| فایل | پوشه | پرامپت |
|---|---|---|
| `nav_orb.png` | `assets/icons/` (شفاف) | **[آیکون]** `a glowing magical purple-gold orb sphere with a star inside` |
| `avatar_default.png` | `assets/icons/` (شفاف) | **[آیکون]** `a mystical golden silhouette portrait bust` |
| `vip_card.png` | `assets/store/` (3:2، تیره) | **[تصویر]** `a luxurious VIP membership card, gold crown, purple and gold, ornate, empty center` |
| `icon_star.png` | `assets/icons/` (شفاف) | **[آیکون]** `a single golden five-point star` |

**نمادهای فالِ قهوه — `assets/symbols/` (۸ آیکونِ شفاف، همه [آیکون]):**
`sym_bird` پرنده · `sym_heart` قلب · `sym_tree` درخت · `sym_road` راهِ پیچ‌درپیچ · `sym_mountain` کوه · `sym_eye` چشم · `sym_fish` ماهی · `sym_snake` مار
(پرامپت هر کدام: `a golden <symbol> symbol` + سبکِ آیکون)

**تاروت — `assets/tarot/` (نسبت 2:3 عمودی، همه [تصویر]):**
`tarot_back` (پشتِ کارتِ طلایی متقارن) · `tarot_moon` · `tarot_star` · `tarot_sun` · `tarot_wheel` · `tarot_lovers` · `tarot_magician`
(پرامپت: `an ornate tarot card, gold border on deep navy, '<name>' motif` + سبکِ تصویر)

---

## 🟩 اولویتِ ۳ — بعداً

- `bg_screen.jpg` — بافتِ نیویِ ستاره‌ایِ ملایمِ پس‌زمینه (فعلاً گرادیان داریم).
- `empty_state.png` — «یک فانوسِ تنها در تاریکی» برای تاریخچهٔ خالی.
- `coin_pack_s/m/l.png` و `gem_pack_s/m/l.png` — بسته‌های فروشگاه.
- دسته‌کارت‌های کاملِ **لنورمان / رون / کارتی** — وقتی آن فال‌ها فعال شدند.

---

## ✅ چک‌لیست: هر صفحه چه می‌خواهد (تا مطمئن شوی چیزی جا نمانده)

| صفحه | اَست‌ها |
|---|---|
| **اسپلش** | لوگو ✅ (داریم) |
| **Home** | `bg_hero`، `icon_coin/gem/vip`، ۵ آیکونِ `qa_*`، ۵ آرتِ فال ✅، `reward_chest`، `nav_orb` |
| **همه فال‌ها** | ۴۰ آرتِ فال ✅ (تیترها اَست ندارند) |
| **ورودی/نیت (Ritual)** | آرتِ همان فال ✅ (پس‌زمینه: گرادیان) |
| **نتیجهٔ فال + تفسیر** | آرتِ فال ✅ + آیکون‌های اکشن‌بار = **آیکونِ متریال** (ذخیره/اشتراک/کپی/دوباره) — اَستِ سفارشی لازم **نیست** |
| **فالِ قهوه** | `coffee` ✅ + ۸ `sym_*` |
| **تاروت** | `tarot_back` + رخِ کارت‌ها |
| **پروفایل** | `avatar_default`، `icon_coin/gem/star`، `vip_card`؛ آیکونِ منو = متریال |
| **کیف‌پول/فروشگاه** | `reward_chest`، بسته‌های سکه/جم |
| **جایزهٔ روزانه** | `reward_chest`؛ تیکِ ۷روزه = متریال |
| **حالتِ خالی/خطا** | `empty_state` |

**نکته:** آیکون‌های ریزِ داخلِ دکمه‌ها/منو/تب‌بار را از آیکون‌های آمادهٔ Flutter (Material) با رنگِ طلایی می‌سازم — لازم نیست بسازی. فقط اَست‌های جدولِ بالا را بده.

---

## اگر عجله داری
فقط **۱۰ اَستِ اولویتِ ۱** را بساز → Home و هدر کامل می‌شوند. بقیه به‌مرور.
