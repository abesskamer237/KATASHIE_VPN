#!/usr/bin/env python3
import socket, threading, selectors, sys, time, getopt

LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8880
PASS = ''
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:109'
RESPONSE = b'HTTP/1.1 101 WebSocket Dropbear\r\nContent-Length: 104857600000\r\n\r\n'


class Server(threading.Thread):
    def __init__(self, host, port):
        super().__init__(daemon=True)
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()
        self.running = False

    def run(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind((self.host, self.port))
            s.listen(100)
            s.settimeout(2)
            self.running = True
            print(f"Server listening on {self.host}:{self.port}")

            while self.running:
                try:
                    client, addr = s.accept()
                    client.setblocking(True)
                    conn = ConnectionHandler(client, self, addr)
                    conn.start()
                    with self.threadsLock:
                        self.threads.append(conn)
                except socket.timeout:
                    continue

    def printLog(self, msg):
        with self.logLock:
            print(msg)

    def removeConn(self, conn):
        with self.threadsLock:
            if conn in self.threads:
                self.threads.remove(conn)

    def close(self):
        self.running = False
        with self.threadsLock:
            for c in self.threads:
                c.close()


class ConnectionHandler(threading.Thread):
    def __init__(self, client, server, addr):
        super().__init__(daemon=True)
        self.client = client
        self.server = server
        self.addr = addr
        self.clientClosed = False
        self.targetClosed = True
        self.log = f"Connection: {addr}"
        self.client_buffer = b''

    def close(self):
        for sock, closed_attr in [(self.client, 'clientClosed'), (getattr(self, 'target', None), 'targetClosed')]:
            if sock and not getattr(self, closed_attr):
                try:
                    sock.shutdown(socket.SHUT_RDWR)
                    sock.close()
                except:
                    pass
                setattr(self, closed_attr, True)

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.get_header(b'X-Real-Host') or DEFAULT_HOST.encode()
            passwd = self.get_header(b'X-Pass')

            if PASS and passwd.decode() != PASS:
                self.client.send(b'HTTP/1.1 400 WrongPass!\r\n\r\n')
            elif hostPort.startswith(b'127.0.0.1') or hostPort.startswith(b'localhost') or not PASS:
                self.handle_connect(hostPort.decode())
            else:
                self.client.send(b'HTTP/1.1 403 Forbidden!\r\n\r\n')
        except Exception as e:
            self.server.printLog(f"{self.log} - error: {e}")
        finally:
            self.close()
            self.server.removeConn(self)

    def get_header(self, header):
        idx = self.client_buffer.find(header + b': ')
        if idx == -1: return b''
        start = idx + len(header) + 2
        end = self.client_buffer.find(b'\r\n', start)
        return self.client_buffer[start:end] if end != -1 else b''

    def connect_target(self, host):
        if ':' in host:
            host, port = host.split(':')
            port = int(port)
        else:
            port = 443
        self.target = socket.create_connection((host, port))
        self.targetClosed = False

    def handle_connect(self, hostPort):
        self.log += f" - CONNECT {hostPort}"
        self.connect_target(hostPort)
        self.client.sendall(RESPONSE)
        self.server.printLog(self.log)
        self.forward_loop()

    def forward_loop(self):
        sel = selectors.DefaultSelector()
        sel.register(self.client, selectors.EVENT_READ, self.target)
        sel.register(self.target, selectors.EVENT_READ, self.client)
        count = 0
        while count < TIMEOUT:
            events = sel.select(timeout=3)
            if not events:
                count += 1
                continue
            for key, _ in events:
                try:
                    data = key.fileobj.recv(BUFLEN)
                    if not data:
                        return
                    key.data.sendall(data)
                    count = 0
                except:
                    return


def parse_args(argv):
    global LISTENING_ADDR, LISTENING_PORT
    try:
        opts, args = getopt.getopt(argv, "hb:p:", ["bind=", "port="])
    except getopt.GetoptError:
        usage(); sys.exit(2)
    for opt, arg in opts:
        if opt == '-h': usage(); sys.exit()
        elif opt in ("-b", "--bind"): LISTENING_ADDR = arg
        elif opt in ("-p", "--port"): LISTENING_PORT = int(arg)

def usage():
    print("Usage: proxy.py -p <port>")
    print("       proxy.py -b <bindAddr> -p <port>")

def main():
    print(f"\n:-------PythonProxy-------:\nListening addr: {LISTENING_ADDR}\nListening port: {LISTENING_PORT}\n")
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    try:
        while True: time.sleep(2)
    except KeyboardInterrupt:
        print("Stopping...")
        server.close()

if __name__ == "__main__":
    parse_args(sys.argv[1:])
    main()
