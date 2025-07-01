from ansible.parsing.dataloader import DataLoader
from ansible.parsing.vault import VaultSecret
from ansible.constants import DEFAULT_VAULT_ID_MATCH
import getpass

password_input = getpass.getpass("Vault Password: ")
vault_password = password_input.encode()

loader = DataLoader()
loader.set_vault_secrets([(DEFAULT_VAULT_ID_MATCH, VaultSecret(vault_password))])

vault_file_path = 'secret.yml'

try:
    data = loader.load_from_file(vault_file_path)
    print(data)
except Exception as e:
    print(f"[!] Failed to decrypt vault file: {e}")

