FROM python:3.9-slim
RUN pip instal flask
WORKDIR /myweb
COPY main.py /myweb/main.py
CMD ["python", "/myweb/main.py"]
