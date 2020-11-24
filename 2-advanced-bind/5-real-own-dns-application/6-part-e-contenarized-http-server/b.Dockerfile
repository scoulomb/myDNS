FROM python:3.9

WORKDIR /

RUN mkdir app

RUN echo "Hello app B" > index.html

ENTRYPOINT ["python3",  "-m",  "http.server", "8080"]

EXPOSE 8080

