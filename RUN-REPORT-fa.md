# 🚀 گزارش اجرای کامل فرانت‌اند DropAgentX / HermesA

> وضعیت: **در حال اجرا** روی `http://0.0.0.0:8080` (پیش‌نمایش زنده) — ۵۰ صفحهٔ مینی‌اپ + ۱۲ صفحهٔ مستقل = **۶۲ صفحه**، همه رندر و اسکرین‌شات شدند.
>
> گالری همهٔ صفحات: `shots/gallery.html` · اسکرین‌شات خام: `shots/pages/` · گزارش JSON: `shots/report.json`

---

## ۱) چطور اجرا شد

| مورد | مقدار |
|---|---|
| حالت اجرا | **وب‌تنها** (بدون `BOT_TOKEN`) → `bot.py` → `_web_only()` → `web_admin.start_server()` |
| سرور | FastAPI + Uvicorn، پورت `8080`، هاست `0.0.0.0` |
| دیتابیس | SQLite — `backend/data/marketplace.db` (از `init_db()` ساخته شد) |
| وابستگی‌ها | `pip install -r backend/requirements.txt` (aiogram / aiosqlite / fastapi / uvicorn / Pillow …) |
| فایل تنظیمات | `backend/.env` ساخته شد (پسورد پنل ادمین: `demo1234`) |

```bash
cd backend
pip install -r requirements.txt
python run.py          # → http://0.0.0.0:8080  (ادمین: /admin)
```

نکته: `run.py` بدون `BOT_TOKEN` هم بالا می‌آید، ولی **فقط اگر `WEB_PORT` ست شده باشد**؛ در `.env` گذاشتم.

---

## ۲) چیزی که در ریپو «جا افتاده بود» (و مجبور شدم بازسازی کنم)

این مهم‌ترین یافتهٔ کار است: **پوستهٔ فرانت‌اند مینی‌اپ در ریپو نیست.**

| فایل | وضعیت در ریپو | کاری که کردم |
|---|---|---|
| `web/app/index.html` | ❌ **کپیِ بیت‌به‌بیت `landing.html`** بود (md5 یکی) → هیچ `<div id="view">`، `<nav>`، `<header>`، sprite آیکون یا `<script>` نداشت. نتیجه: هر مسیر `#/...` همان لندینگ را نشان می‌داد. | ✅ پوستهٔ واقعی مینی‌اپ نوشته شد (۱۵۱ خط) + اسپرایت ۵۴ آیکون SVG + لود همهٔ ۱۷ فایل `js/pages/*`. نسخهٔ قبلی به‌عنوان `index.landing-backup.html` نگه داشته شد. |
| `web/app/css/app.css` | ❌ **وجود نداشت** — در حالی که `pages.css` و همهٔ JSها به توکن‌ها و کلاس‌هایش وابسته‌اند (`--txt`, `--em`, `--dim`, `--nav-h`, `.post`, `.chip`, `.tile`, `.sm-cell`, …). ۱۲۶ کلاس بدون استایل. | ✅ از صفر نوشته شد (۷۷۹ خط): توکن‌های تم NEON، تاپ‌بار، نوار پایین با دکمهٔ +، شیت‌ها، توست، پول‌تو‌رفرش، کارت پست، ریلز، استوری، جدول‌ها، فرم‌ها، حالت‌های skeleton/empty … |
| `web/app/js/core/*` و `js/pages/*` | ✅ کامل بودند (۵۰ صفحه ثبت‌شده) | دست نخوردند (جز ۲ فیکس کوچک پایین) |

بعد از بازسازی، `Object.keys(DGX.pages).length === 50` و **هیچ کلاس بی‌استایلی** باقی نماند (بررسی خودکار روی کل JS).

---

## ۳) فیکس‌های کوچک روی کد پروژه

1. **`js/pages/agent.js`** — لیسنر `visualViewport` بعد از ترک صفحهٔ هرمسا روی المان حذف‌شده کار می‌کرد و `Cannot read properties of null (reading 'style')` می‌داد (بعد از هر resize در هر صفحهٔ دیگر). گارد + حذف لیسنر اضافه شد.
2. **`js/pages/agent.js`** — نوار نوشتن پیام روی نوار پایین می‌افتاد (`bottom = kb`)، حالا `bottom = kb + --nav-h`.
3. **`web_admin.py`** — سقف ریت‌لیمیت hardcode بود (`40/min`): برای تست/ابزار به `WEB_RATE_MAX` و `WEB_RATE_WINDOW` تبدیل شد (پیش‌فرض همان ۴۰ و ۶۰، بدون تغییر رفتار).
4. **`css/app.css`** — `img { max-width:100% }`: تصاویر ۱۰۰۰px داخل کانتینر ۴۴px (`.rr-img`) صفحهٔ «ترندها» را کاملاً سفید/خالی می‌کرد (اسکرول افقی ۱۰۲۷px در ویوپورت ۴۳۰px).

---

## ۴) دادهٔ دمو (تا صفحات خالی نباشند)

- `python tools_seed_demo.py` → ۸ کاربر (`demo_*`)، محصولات، تسک‌ها.
- ۵ کاور واقعی در `uploads/covers/` روی محصولات ست شد (فید/ترند/استوری با عکس).
- یک محصول از کاربر ۱۱ ساخته و **خریداری شد** (سفارش/کتابخانه/فعالیت پر شد)، فالو، لایک و سیو هم ثبت شد.
- **ورود دمو:** در `.env` مقدار `APP_DEV_LOGIN=1` و `APP_ENV=local` ست شد؛ با `?demo=1` در انتهای آدرس ریشه، مینی‌اپ خودکار با کاربر ادمین (`uid=10`) لاگین می‌شود. بدون این، صفحات عمومی (فید/کشف/محصول) سالم‌اند و صفحات کیف‌پول/داشبورد ورود می‌خواهند.

> این پرچم‌ها فقط محلی‌اند؛ در کد سرور شرط `APP_ENV ∈ {dev,test,local}` + `APP_DEV_LOGIN=1` + `HERMES_MODE != api` بررسی می‌شود، پس با کپیِ `.env` روی پروداکشن فعال نمی‌شود.

---

## ۵) فهرست صفحات (همه ۲۰۰)

**مینی‌اپ (SPA، ۵۰ صفحه)** — فید و کشف: `home, explore, reels, drops, trending, fresh, story, search` · بازار: `categories, category, collections, collection, product, related, reviews, seller` · خرید: `order, library, plans, credits` · اجتماعی: `people, follows, notifications, likes, saved, profile, profile-edit, share` · فروشنده: `create, create-drop, drafts, dashboard, analytics, products-manage, payouts` · کیف پول: `wallet, deposit, withdraw, transactions` · سیستم: `agent, settings, help, about, terms, privacy, roadmap, bot, status, activity, sitemap`

**صفحات مستقل (۱۲)** — `/landing` · `/` · `/shop` · `/legacy-home` · `/showcase3d` · `/links` · `/login` · `/admin` · `/insights` · `/live` (SSE) · `/cockpit` (SenPai) · `/offline.html`

**API جانبی سالم:** `/healthz` · `/api/pub/info` · `/api/pub/catalog` · `/api/app/feed|trending|search|product|wallet|activity` · `/api/admin/*` (پشت کوکی ادمین)

---

## ۶) نتیجهٔ تست خودکار

- ۶۲ صفحه اسکرین‌شات شد (Playwright/Chromium، DPR 2؛ موبایل ۴۳۰×۹۳۲، دسکتاپ ۱۴۴۰×۹۰۰).
- **درخواست ناموفق: ۰** (هیچ ۴۰۴/۵۰۰ روی asset یا API).
- **خطای کنسول: ۵** — همه یک الگو دارند: کدی که `await` می‌کند و بعد از ترک صفحه `DGX.$('#x').innerHTML` را صدا می‌زند (`category`, `related`, `plans`, `notifications`, `share`). بی‌خطر ولی بهتر است در `router.js` یا با `AbortController` محافظت شود.

---

## ۷) باگ‌هایی که در خود پروژه دیدم (اصلاح نکردم، فقط گزارش)

1. `web/app/index.html` در ریپو، `landing.html` است → مینی‌اپ اصلاً بالا نمی‌آمد (ریشهٔ همهٔ مشکلات بالا).
2. `web/app/css/app.css` گم شده → ۱۲۶ کلاس بدون استایل.
3. `README` به `docs/`, `backend/tests/`, `backend/requirements*.lock` و … اشاره می‌کند ولی بخشی از این‌ها ناقص/جدا آپلود شده‌اند (`git log` فقط ۳ کامیت دارد).
4. `.env.example` می‌گوید `A2A_ENABLED=0` ولی `bot.py` پیش‌فرضِ کد را `1` می‌گیرد؛ برای اجرای محلی باید صریح صفر شود.
5. `agent.js` — نشتی لیسنر `visualViewport` (فیکس شد) و وابستگی نوار پیام به `bottom` اینلاین.
6. اسکرول افقی صفحهٔ ترند به‌خاطر `img` بی‌قید (فیکس شد).
7. متن‌های خام انگلیسی در تراکنش‌ها (`engagement_save`, `Purchased`) — مپ دوزبانه در `wallet.js` کامل نیست.
8. ریت‌لیمیت سراسری `40/min` روی IP به‌راحتی در لود یک صفحهٔ سنگین هم قابل لمس است (حالا قابل تنظیم شد).

---

## ۸) دستورها برای خودت

```bash
# اجرای سرور
cd /home/user/HermesA/backend && python run.py

# بازسازی دادهٔ دمو
python tools_seed_demo.py

# گرفتن دوبارهٔ همهٔ اسکرین‌شات‌ها (سرور باید بالا باشد)
cd /home/user/HermesA/shots && python capture.py
python build_gallery.py     # → gallery.html
```

پیش‌نمایش زنده: سرور همین حالا روی پورت ۸۰۸۰ در حال اجراست. مسیرهای پیشنهادی برای گشتن:

| مسیر | چه چیزی |
|---|---|
| `/` | مینی‌اپ (فید) — با `?demo=1` لاگین خودکار |
| `/landing`, `/showcase3d`, `/links` | صفحات بازاریابی/ویترین |
| `/login` سپس `/admin`, `/insights`, `/live` | پنل مدیریت (رمز: `demo1234`) |
| `/cockpit` | کاکپیت SenPai (چت AI) |
| `/shop`, `/legacy-home` | فروشگاه کلاسیک |
