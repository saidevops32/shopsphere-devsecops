# syntax=docker/dockerfile:1
FROM python:3.12.8-slim-bookworm AS build
WORKDIR /w
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12.8-slim-bookworm
# Non-root user with fixed UID (matches K8s runAsUser)
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin app
COPY --from=build /opt/venv /opt/venv
WORKDIR /app
COPY app ./app
ENV PATH="/opt/venv/bin:$PATH" PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
USER 10001
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
