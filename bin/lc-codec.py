#!/usr/bin/env python3
"""
Standalone encoder/decoder for LoanConnect V2 IDs (LCCrypt / libsodium).

Mirrors app/Helpers/LCCrypt.php. No Laravel, no DB — pure libsodium.

Usage:
    lc-codec.py decode <hex_ciphertext>
    lc-codec.py encode <plain_id>
    echo <value> | lc-codec.py {decode|encode} -

Install once:  pip install pynacl
"""

import sys
from nacl.secret import SecretBox
from nacl.exceptions import CryptoError

# Must match app/Helpers/LCCrypt.php exactly.
# If these change upstream, update here.
NONCE = bytes.fromhex("4963853a82ba8a54c6b778c41373566aae568ccf2ec05336")
KEY = bytes.fromhex(
    "d39a61e43aee890330294bf01a93442a8170aa6bd216b15b05a5ff6e56ee2758"
)


def decode(hex_ciphertext: str) -> str:
    """Mirror of LCCrypt::decrypt — hex in, UTF-8 plaintext out."""
    hex_ciphertext = hex_ciphertext.strip()
    if not all(c in "0123456789abcdefABCDEF" for c in hex_ciphertext):
        raise ValueError("input is not hex")
    if len(hex_ciphertext) % 2 != 0:
        raise ValueError("hex length must be even")

    ct = bytes.fromhex(hex_ciphertext)
    pt = SecretBox(KEY).decrypt(ct, NONCE)
    return pt.decode("utf-8")


def encode(plaintext: str) -> str:
    """Mirror of LCCrypt::encrypt — UTF-8 in, hex ciphertext out."""
    ct_obj = SecretBox(KEY).encrypt(plaintext.encode("utf-8"), NONCE)
    return ct_obj.ciphertext.hex()


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ("encode", "decode"):
        print(__doc__.strip(), file=sys.stderr)
        return 2

    op = sys.argv[1]
    val = sys.argv[2] if len(sys.argv) > 2 else "-"
    if val == "-":
        val = sys.stdin.read().strip()

    try:
        print(encode(val) if op == "encode" else decode(val))
    except (CryptoError, ValueError, UnicodeDecodeError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
