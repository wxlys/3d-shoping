FROM docker.m.daocloud.io/library/python:3.11-slim

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir --index-url https://pypi.tuna.tsinghua.edu.cn/simple --timeout 120 --retries 5 -r requirements.txt

COPY app.py ./

ENV MOCK_HOST=0.0.0.0
ENV MOCK_PORT=5055
ENV PYTHONUNBUFFERED=1

EXPOSE 5055

CMD ["gunicorn", "--bind", "0.0.0.0:5055", "--workers", "1", "--threads", "4", "--timeout", "30", "app:app"]
