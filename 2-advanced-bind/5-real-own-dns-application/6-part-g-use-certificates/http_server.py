from http.server import HTTPServer, SimpleHTTPRequestHandler
import ssl


def main():
    key_file = "appa.prd.coulombel.it.key"
    cert_file = "appa.prd.coulombel.it.crt"
    port = 9443
    httpd = HTTPServer(('0.0.0.0', port), SimpleHTTPRequestHandler)

    httpd.socket = ssl.wrap_socket(httpd.socket,
                                   keyfile=key_file,
                                   certfile=cert_file, server_side=True)

    httpd.serve_forever()


if __name__ == "__main__":
    main()

