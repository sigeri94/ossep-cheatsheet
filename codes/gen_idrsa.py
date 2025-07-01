from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend

private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
    backend=default_backend()
)
password = b"Gotham2024!"  # Must be bytes
pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.TraditionalOpenSSL,  # Produces "BEGIN RSA PRIVATE KEY"
    encryption_algorithm=serialization.BestAvailableEncryption(password)
)
with open("id_rsa", "wb") as f:
    f.write(pem)

print("[+] RSA private key saved to id_rsa")
