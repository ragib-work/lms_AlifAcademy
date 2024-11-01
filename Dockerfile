# Use an official Python runtime as a parent image
ARG PYTHON_VERSION=3.12-slim-bullseye
FROM python:${PYTHON_VERSION}

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PIP_NO_CACHE_DIR 1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    build-essential \
    libpq-dev \
    git \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements/base.txt requirements/base.txt
COPY requirements/production.txt requirements/production.txt

# Install production dependencies
RUN pip install --upgrade pip \
    && pip install -r requirements/production.txt

# Copy project files
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Run database migrations
RUN python manage.py migrate

# Create a non-root user for security
RUN addgroup --system django \
    && adduser --system --ingroup django django

# Change ownership of the application directory
RUN chown -R django:django /app

# Switch to non-root user
USER django

# # Expose port (Railway will override this)
# EXPOSE 8000

# Use gunicorn as the production WSGI server
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:$PORT core.wsgi:application"]