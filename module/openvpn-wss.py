#!/usr/bin/python3
import socket, threading, select, sys, time, getopt

LISTENING_ADDR = "0.0.0.0"
LISTENING_PORT = 900

PASS = ""

BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = "127.0.0.1:109"
RESPONSE = (
    b"HTTP/1.1 200 Connection Established\r\n"
    b"Proxy-Agent: NexusTunnelPro-Proxy\r\n\r\n"
)


class Server(threading.Thread):
    def __init__(self, host, port):
        super().__init__()
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)

        try:
            self.soc.bind((self.host, int(self.port)))
        except OSError as e:
            self.printLog(f"[ERROR] Could not bind {self.host}:{self.port} - {e}")
            return

        self.soc.listen(100)
        self.running = True
        self.printLog(f"[OK] Listening on {self.host}:{self.port}")

        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(True)
                except socket.timeout:
                    continue
                except Exception as e:
                    self.printLog(f"[ACCEPT ERROR] {e}")
                    continue

                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()

    def printLog(self, log):
        with self.logLock:
            print(log)

    def addConn(self, conn):
        with self.threadsLock:
            if self.running:
                self.threads.append(conn)

    def removeConn(self, conn):
        with self.threadsLock:
            if conn in self.threads:
                self.threads.remove(conn)

    def close(self):
        self.running = False
        with self.threadsLock:
            for c in list(self.threads):
                c.close()


class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        super().__init__()
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = b""
        self.server = server
        self.log = f"[NEW] Connection from {addr}"

    def close(self):
        if not self.clientClosed:
            try:
                self.client.shutdown(socket.SHUT_RDWR)
            except:
                pass
            self.client.close()
            self.clientClosed = True

        if not self.targetClosed:
            try:
                self.target.shutdown(socket.SHUT_RDWR)
            except:
                pass
            self.target.close()
            self.targetClosed = True

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            client_buffer_str = self.client_buffer.decode("latin-1", errors="ignore")

            hostPort = self.findHeader(client_buffer_str, "X-Real-Host") or DEFAULT_HOST

            if self.findHeader(client_buffer_str, "X-Split"):
                self.client.recv(BUFLEN)

            if hostPort:
                passwd = self.findHeader(client_buffer_str, "X-Pass")

                if PASS and passwd != PASS:
                    self.client.send(b"HTTP/1.1 400 WrongPass!\r\n\r\n")
                elif hostPort.startswith("127.0.0.1") or hostPort.startswith("localhost") or not PASS:
                    self.method_CONNECT(hostPort)
                else:
                    self.server.printLog("[BLOCKED] No X-Real-Host")
                    self.client.send(b"HTTP/1.1 403 Forbidden!\r\n\r\n")
            else:
                self.server.printLog("[ERROR] Missing X-Real-Host header")
                self.client.send(b"HTTP/1.1 400 Bad Request!\r\n\r\n")

        except Exception as e:
            self.server.printLog(f"{self.log} - error: {e}")
        finally:
            self.close()
            self.server.removeConn(self)

    def findHeader(self, head, header):
        start = head.find(header + ": ")
        if start == -1:
            return ""
        end = head.find("\r\n", start)
        return head[start + len(header) + 2 : end]

    def connect_target(self, host):
        if ":" in host:
            h, p = host.split(":")
            port = int(p)
        else:
            h, port = host, 443

        addr_info = socket.getaddrinfo(h, port, socket.AF_UNSPEC, socket.SOCK_STREAM)
        self.target = socket.socket(*addr_info[0][:3])
        self.target.connect(addr_info[0][4])
        self.targetClosed = False

    def method_CONNECT(self, path):
        self.log += f" - CONNECT {path}"
        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = b""
        self.server.printLog(self.log)
        self.doCONNECT()

    def doCONNECT(self):
        socs = [self.client, self.target]
        idle = 0

        while True:
            recv, _, err = select.select(socs, [], socs, 3)
            if err:
                break
            if recv:
                for s in recv:
                    try:
                        data = s.recv(BUFLEN)
                        if not data:
                            return
                        if s is self.target:
                            self.client.sendall(data)
                        else:
                            self.target.sendall(data)
                        idle = 0
                    except Exception as e:
                        self.server.printLog(f"[DATA ERROR] {e}")
                        return
            idle += 1
            if idle >= TIMEOUT:
                return


def print_usage():
    print("Usage: proxy.py -p <port>")
    print("       proxy.py -b <bindAddr> -p <port>")


def parse_args(argv):
    global LISTENING_ADDR, LISTENING_PORT
    opts, _ = getopt.getopt(argv, "hb:p:", ["bind=", "port="])
    for opt, arg in opts:
        if opt in ("-b", "--bind"):
            LISTENING_ADDR = arg
        elif opt in ("-p", "--port"):
            LISTENING_PORT = int(arg)


def main():
    parse_args(sys.argv[1:])
    print("\n--- Nexus Tunnel Pro Python Proxy ---")
    print(f"Listening addr: {LISTENING_ADDR}")
    print(f"Listening port: {LISTENING_PORT}\n")
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()

    try:
        while server.running:
            time.sleep(2)
    except KeyboardInterrupt:
        print("Stopping...")
        server.close()


if __name__ == "__main__":
    main()
