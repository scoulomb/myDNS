import ssl
from http.server import HTTPServer, SimpleHTTPRequestHandler
import socket
# and not from socket import socket

class HTTPServerV6(HTTPServer):
    address_family = socket.AF_INET6


# from part h
def main():
    key_file = "/etc/letsencrypt/live/coulombel.it-0001/privkey.pem"
    cert_file = "/etc/letsencrypt/live/coulombel.it-0001/fullchain.pem"
    port = 9443
    httpd = HTTPServerV6(('::', port), SimpleHTTPRequestHandler)

    httpd.socket = ssl.wrap_socket(httpd.socket,
                                   keyfile=key_file,
                                   certfile=cert_file, server_side=True)

    httpd.serve_forever()


if __name__ == "__main__":
    main()
