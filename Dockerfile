# ─────────────────────────────────────────────────────────────────────────────
# تصویر تولیدی Railway — build context = ریشه‌ی مخزن
#
# چرا این Dockerfile در «ریشه» است؟
# داکیومنت Railway: «Railway will look for and use a Dockerfile at the root of
# the source directory» و «برای تشخیص خودکار باید نام فایل دقیقاً Dockerfile
# باشد». قبلاً Dockerfile فقط در backend/ بود و railway.toml هم
# builder = "docker" داشت — که مقدار نامعتبر است (مقادیر معتبر: NIXPACKS،
# DOCKERFILE، RAILPACK، HEROKU). نتیجه: Railway پیش از شروع بیلد داکر رد
# می‌کرد → شکست در ۳-۴ ثانیه، فقط یک خط `unpacking archive` و هیچ لاگ بیلدی.
#
# نکته‌ی مهم: context بیلد همیشه ریشه‌ی سورس (این مخزن) است، حتی اگر مسیر
# Dockerfile جای دیگری باشد. پس همه‌ی COPYها با پیشوند backend/ نوشته شده‌اند
# تا با context ریشه کار کنند.
#
# نسخه‌ی backend/ همین پوشه برای docker-compose (context = ./backend) دست‌نخورده
# باقی می‌ماند؛ این فایل فقط مخصوص Railway/ریشه است.
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_RETRIES=5

# لایه‌ی وابستگی‌ها اول: تغییر کد باعث باطل شدن کش pip نمی‌شود
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Tehran local time: Debian-slim بستهٔ tzdata ندارد و صرفاً ست کردن TZ بی‌اثر
# می‌ماند؛ پس tzdata نصب و localtime لینک می‌شود (بعد از pip تا کش حفظ شود).
ENV TZ=Asia/Tehran
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# کل اپ: run.py + bot.py + web_admin.py + web/ + handlers/ + gateway/ + skills
COPY backend/ ./

# ⚠️ Railway پورت را با PORT تزریق می‌کند و همان را برای healthcheck استفاده
# می‌کند. اینجا WEB_PORT ست نمی‌شود تا هیچ‌وقت PORT را سایه نیندازد (علت کلاسیک
# خطای 502 / «Application failed to respond»). WEB_PORT فقط fallback داخل کد است.
ENV PYTHONUNBUFFERED=1 \
    APP_ENV=production \
    A2A_ENABLED=0

EXPOSE 8080

# Railway از healthcheckPath خودش استفاده می‌کند؛ این HEALTHCHECK برای اجرای
# مستقیم داکر (VPS/لوکال) است و بی‌ضرر است.
HEALTHCHECK --interval=60s --timeout=10s --start-period=60s --retries=5 \
    CMD python -c "import os,urllib.request,sys; p=os.getenv('PORT','8080'); sys.exit(0 if urllib.request.urlopen(f'http://127.0.0.1:{p}/healthz', timeout=5).status==200 else 1)"

# run.py: PORT → WEB_PORT نگاشت می‌شود و وب (FastAPI) + بات (polling) با هم بالا
# می‌آیند؛ بدون BOT_TOKEN فقط بخش وب بالا می‌آید.
CMD ["python", "run.py"]
