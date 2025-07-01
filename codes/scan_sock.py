import socks
import socket
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import defaultdict

socks.set_default_proxy(socks.SOCKS5, "127.0.0.1", 1080)
socket.socket = socks.socksocket

PORTS = [20, 21, 22, 80, 53, 443, 445, 3389, 8080, 25, 110, 143, 5985, 5986, 88, 464, 389, 636]
TIMEOUT = 5

def scan_port(ip, port):
    try:
        s = socket.socket()
        s.settimeout(TIMEOUT)
        s.connect((ip, port))
        s.close()
        return port
    except:
        return None

def read_targets(file_path):
    try:
        targets = []
        with open(file_path, "r") as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) >= 2:
                    ip, hostname = parts[0], parts[1]
                elif len(parts) == 1:
                    ip, hostname = parts[0], parts[0]
                else:
                    continue
                targets.append((ip, hostname))
        return targets
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)

def scan_host(ip, hostname):
    open_ports = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(scan_port, ip, port): port for port in PORTS}
        for future in as_completed(futures):
            port = future.result()
            if port:
                open_ports.append(port)

    open_ports.sort()
    print(f"{ip} - {hostname}")
    if open_ports:
        print(f"open : {','.join(map(str, open_ports))}")
    else:
        print("open : none")

def main():
    if len(sys.argv) != 2:
        print("Usage: python scan2.py targets.txt")
        sys.exit(1)

    file_path = sys.argv[1]
    targets = read_targets(file_path)

    for ip, hostname in targets:
        scan_host(ip, hostname)

if __name__ == "__main__":
    main()
