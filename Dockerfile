FROM python:3.11-slim

# Install system deps for psycopg2
RUN apt-get update && apt-get install -y libpq-dev gcc && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

# Use non-root user (better for security)
RUN useradd -m appuser
USER appuser

CMD ["gunicorn", "-b", "0.0.0.0:8080", "main:app"]

