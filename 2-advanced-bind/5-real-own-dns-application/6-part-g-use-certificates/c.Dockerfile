FROM python:3.9

WORKDIR /

RUN echo "Hello app C" > indexc.html

COPY http_server.py *.crt *.key ./


ENTRYPOINT ["python3",  "http_server.py"]

EXPOSE 9443

