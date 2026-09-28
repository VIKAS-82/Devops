FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
COPY delivery_metrics.py .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
CMD ["python", "delivery_metrics.py"]
