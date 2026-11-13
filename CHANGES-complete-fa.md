# ✅ نسخهٔ کامل‌شدهٔ HermesA / DropAgentX — سورس‌کد

این زیپ **کل سورس پروژه** است (بک‌اند + فرانت‌اند + مستندات + تست‌ها) با یک تفاوت مهم:
فرانت‌اند **کامل و اجراشدنی** شده — چون در آپلود اصلی، دو فایل حیاتیِ مینی‌اپ وجود نداشت و
هیچ صفحه‌ای بالا نمی‌آمد.

> فقط فایل‌های سورس داخل است: بدون `data/`، بدون `uploads/`، بدون `.env`، بدون `__pycache__`
> و بدون اسکرین‌شات‌ها.

---

## ۱) اجرا (۳ دستور)

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env        # ← WEB_PASSWORD و WEB_SECRET را پر کن
python run.py               # → http://localhost:8080
```

حداقلِ `.env` برای اجرای محلی (وب‌تنها، بدون ربات تلگرام):

```env
BOT_TOKEN=
ADMIN_IDS=
WEB_PORT=8080
WEB_HOST=0.0.0.0
WEB_PASSWORD=تغییرم بده
WEB_SECRET=یک-hex-تصادفی-۳۲بایتی      # python -c "import secrets;print(secrets.token_hex(32))"
COOKIE_SECURE=0                        # پشت HTTPS بگذار 1
A2A_ENABLED=0
```

اسکریپت‌های کمکی:

```bash
python tools_seed_demo.py     # کاربر/محصول/تسک دمو (نیاز به ADMIN_IDS)
python tools_db_doctor.py     # بررسی سلامت دیتابیس
cd backend && pytest -q       # ۱۰۰ تست
```

---

## ۲) چه چیزی «کامل» شد

### الف) دو فایل گم‌شدهٔ فرانت‌اند (بزرگ‌ترین مشکل ریپو)

| فایل | وضعیت قبل | حالا |
|---|---|---|
| `backend/web/app/index.html` | بیت‌به‌بیت همان `landing.html` بود (md5 یکسان) → نه `#view`، نه `#nav`، نه `#topbar`، نه sprite آیکون، نه `<script>`. نتیجه: هر مسیر `#/...` همان لندینگ را نشان می‌داد و **کل مینی‌اپ مرده بود**. | پوستهٔ واقعی مینی‌اپ از صفر نوشته شد: اسپرایت **۵۴ آیکون SVG**، تاپ‌بار/`view`/نوار پایین/`hubFab`/`hubSheet`/`toast`، لود ۱۷ فایل `js/pages/*`، بوت با `DGX.boot()`، ثبت Service Worker. |
| `backend/web/app/css/app.css` | **وجود نداشت** — ولی `pages.css` و همهٔ فایل‌های JS به توکن‌ها و کلاس‌هایش وابسته‌اند (`--txt`, `--em`, `--dim`, `--nav-h`, `.post`, `.chip`, `.tile`, `.sm-cell`, …): ۱۲۶ کلاس بی‌استایل. | از صفر نوشته شد (~۷۹۰ خط): توکن‌های تم NEON، تاپ‌بار، نوار پایین با دکمهٔ +، شیت‌ها، توست، پول‌تو‌رفرش، کارت پست، ریلز، استوری‌ویوئر، کارت‌های آماری، فرم‌ها، skeleton/empty، و اصلاحیه‌های چیدمان (هدرینگ‌ها، `buybar`، کامپوزر هرمسا، `img` سرریز). |

بعد از این دو، هر **۵۰ صفحهٔ مینی‌اپ** + ۱۲ صفحهٔ مستقل رندر می‌شوند (تست خودکار: ۰ درخواست
ناموفق، ۵ خطای بی‌خطر async).

### ب) باگ‌های کد

1. **`web/app/js/pages/agent.js`** — لیسنر `visualViewport` بعد از ترک صفحهٔ هرمسا روی المان
   حذف‌شده کار می‌کرد و در هر resize در صفحه‌های دیگر `Cannot read properties of null` می‌داد
   → گارد + `removeEventListener`.
2. **`web/app/js/pages/agent.js`** — نوار نوشتن پیام زیر نوار پایین می‌افتاد؛ حالا
   `bottom = keyboard + var(--nav-h)`.
3. **`web/app/css/app.css`** — `img { max-width: 100% }` و محدودسازی `.rr-img img` و …؛
   بدون این، تصویر ۱۰۰۰px داخل کانتینر ۴۴px در صفحهٔ «ترندها» کل صفحه را سفید می‌کرد
   (اسکرول افقی ۱۰۲۷px در ویوپورت ۴۳۰px).
4. **`web_admin.py`** — سقف ریت‌لیمیت hardcode بود (`40/min`): حالا با
   `WEB_RATE_MAX` / `WEB_RATE_WINDOW` قابل تنظیم است (پیش‌فرض همان ۴۰/۶۰ — بدون تغییر رفتار).
5. **`tests/test_v099.py`** — دو تست تحلیل رشد شکست می‌خوردند، چون `init_db()` هنگام ست‌بودن
   `ADMIN_IDS` کاربر ادمینِ دمو را هم می‌سازد و شمارش «کاربر جدید امروز» را ۴ می‌کرد.
   فیکسچر `isolated_db` الان بعد از ساخت دیتابیس، ردیف‌های seed را پاک می‌کند.

**نتیجه: `pytest -q` → ۱۰۰ passed** (قبلاً ۹۸ passed / ۲ failed).

### ج) بهبود تجربهٔ توسعه

- در `web/app/index.html` یک بلوک کوچک اضافه شد: اگر آدرس `?demo=1` داشته باشد و کاربر
  لاگین نباشد، از مسیر توسعهٔ سرور (`APP_DEV_LOGIN=1` + `APP_ENV=local`) توکن می‌گیرد و
  وارد حساب دمو می‌شود. روی پروداکشن خودبه‌خود بی‌اثر است (سرور ۴۰۱ می‌دهد).

---

## ۳) ساختار

```text
HermesA/
├─ backend/                 ← FastAPI + aiogram + SQLite
│  ├─ run.py · bot.py · config.py · database.py · app_api.py · web_admin.py
│  ├─ handlers/             ← ۱۸ روتر ربات
│  ├─ gateway/ router/ shared/ skills_builtin/ tests/
│  ├─ web/                  ← ✳️ کل فرانت‌اند (همان چیزی که مرورگر می‌گیرد)
│  │  ├─ app/               ← مینی‌اپ: index.html ✳️ + css/{design-system,pages,app ✳️}.css
│  │  │                        + js/core/{tg,api,ui,router}.js + js/pages/*.js (۵۰ صفحه)
│  │  ├─ landing.html · storefront.html · showcase3d.html · links.html
│  │  ├─ login.html · admin.html · insights.html · live.html · offline.html
│  │  ├─ senpai/            ← کاکپیت SenPai (app.html/css/js)
│  │  ├─ fonts/ · assets/ · manifest.webmanifest · sw.js · icon.svg
│  │  └─ docs/ (مستندات فارسی)
│  └─ CHANGELOG-*.md …      ← تاریخچهٔ نسخه‌ها (دست‌نخورده)
├─ frontend/                ← locales + کیت UI (senpai تکراری)
├─ docker-compose.yml · railway.toml · Procfile
└─ README.md · architecture.svg
```

✳️ = فایل‌هایی که در این نسخه ساخته/بازنویسی شده‌اند.

---

## ۴) چه چیزی هنوز «کامل» نیست (و چرا)

- `/admin`، `/insights`، `/live` در خود ریپو **دموی استاتیک** هستند (هیچ `fetch`ای ندارند)؛
  داده‌هایشان ثابت است. APIهای واقعی (`/api/admin/*`) در `web_admin.py` پیاده‌سازی شده‌اند،
  ولی HTML این سه صفحه به آن‌ها وصل نیست. (برای همین دست نزدم — تصمیم محصولی است.)
- بخشی از `docs/` و چند فایل `CHANGELOG` در آپلود اصلی ناقص بودند؛ همان‌ها که بود حفظ شده.
- برای اجرای ربات تلگرام واقعی، `BOT_TOKEN` و `ADMIN_IDS` لازم است.
- `A2A_ENABLED` پیش‌فرض در کد `1` است ولی `.env.example` می‌گوید `0`؛ برای اجرای محلی
  صریحاً `0` بگذار تا پورت‌های ۹۰۰۱/۹۰۲۰ باز نشوند.
