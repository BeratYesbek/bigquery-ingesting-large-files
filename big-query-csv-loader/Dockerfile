FROM python:3.12-slim

ENV PYTHONUNBUFFERED=True

COPY requirements.txt ./
RUN pip install -r requirements.txt

ENV APP_HOME=/app
WORKDIR $APP_HOME
COPY src/ ./src/

ENV PYTHONPATH="${PYTHONPATH}:/app/src"

CMD ["python", "-m", "src.main"]