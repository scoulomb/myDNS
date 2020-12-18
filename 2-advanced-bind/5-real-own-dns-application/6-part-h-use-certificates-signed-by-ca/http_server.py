from http.server import HTTPServer, SimpleHTTPRequestHandler
import ssl


def main():
    key_file = "/etc/letsencrypt/live/coulombel.it-0001/privkey.pem"
    cert_file = "/etc/letsencrypt/live/coulombel.it-0001/fullchain.pem"
    port = 9443
    httpd = HTTPServer(('0.0.0.0', port), SimpleHTTPRequestHandler)

    httpd.socket = ssl.wrap_socket(httpd.socket,
                                   keyfile=key_file,
                                   certfile=cert_file, server_side=True)

    httpd.serve_forever()


if __name__ == "__main__":
    main()

