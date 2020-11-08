#!/bin/bash
# https://gist.github.com/ikbear/56b28f5ecaed76ebb0ca

echo "This is start named and keep container running."

cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}

trap cleanup SIGINT SIGTERM

systemctl start named
systemctl enable named
systemctl status named

while [ 1 ]
do
  sleep 60 &
  wait $!
done