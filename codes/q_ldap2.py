import socks
import socket
from ldap3 import Server, Connection, SUBTREE, ALL
from ldap3.core.exceptions import LDAPException

# === SOCKS CONFIG (Optional) ===
# Uncomment if you're tunneling via SOCKS5 (like chisel, proxychains)
# SOCKS_PROXY_HOST = '127.0.0.1'
# SOCKS_PROXY_PORT = 1080
# socks.set_default_proxy(socks.SOCKS5, SOCKS_PROXY_HOST, SOCKS_PROXY_PORT)
# socket.socket = socks.socksocket

# === LDAP CONFIG ===
LDAP_HOST = 'dc09.gotham.local'
BASE_DN = 'dc=gotham,dc=local'
USERNAME = 'GOTHAM\\alfred'
PASSWORD = 'P@ssw0rd'

server = Server(LDAP_HOST, get_info=ALL, use_ssl=False)

try:
    # ----- Simple bind with credentials
    conn = Connection(server, user=USERNAME, password=PASSWORD, auto_bind=True)
    # ----- Use GSSAPI (Kerberos) auth, assumes valid TGT (via kinit or OS login)
    # conn = Connection(server, authentication=SASL, sasl_mechanism=GSSAPI, auto_bind=True)

    # LDAP Search for all user accounts and their group memberships
    conn.search(
        search_base=BASE_DN,
        search_filter='(objectClass=user)',
        search_scope=SUBTREE,
        attributes=['sAMAccountName', 'memberOf']
    )

    # Print each user and their groups
    for entry in conn.entries:
        user = str(entry.sAMAccountName)
        print(f"\n[+] User: {user}")

        if 'memberOf' in entry and entry.memberOf:
            for group in entry.memberOf:
                print(f"    Group: {group}")
        else:
            print("    Group: (none)")

    conn.unbind()

except LDAPException as e:
    print(f"[!] LDAP error occurred: {e}")
except Exception as e:
    print(f"[!] Unexpected error: {e}")
