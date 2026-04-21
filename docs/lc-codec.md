# LoanConnect ID Codec (`lc-cyber` / `lc-codec`)

Self-contained encoder/decoder for LoanConnect's obfuscated IDs, integrated into
this Neovim config. No dependency on external repos — **Rijndael-256 (V1) is
vendored inline** in the PHP backend, and **libsodium (V2)** comes from PHP's
native `sodium` extension.

## Files

| Path | Role |
|------|------|
| `bin/lc-codec.php` | Backend. V1 + V2 with auto-detection on decode. |
| `bin/lc-codec.py` | Python port, V2 only. Requires `pip install pynacl`. Not wired up — kept for reference. |
| `lua/lc-cyber.lua` | Neovim wrapper. Shells out to `bin/lc-codec.php` via `vim.fn.stdpath('config')`. |

## Encoding versions

| Version | Format | Primitive | Example input |
|---------|--------|-----------|---------------|
| **V1** | URL-safe base64 (43–44 chars) | Rijndael-256 ECB, 16-byte key derived via `str_rot13('bqDBPj6m9jLRCgU2')` | `qXJwAF2j9Q1LEmahTtSjBmTZ66XCQ7UYD01UEMrhQ4c` |
| **V2** | Hex string (even length) | libsodium `crypto_secretbox` (XSalsa20-Poly1305), fixed 32-byte key + 24-byte nonce | `8c53ce1b9de6b55e1dbe2116dcca2f7c82f6fad858a544` |

Auto-detection: V2 is tried first (hex + authenticated decryption fails cleanly
on wrong input); V1 is the fallback. Rijndael-ECB has no MAC and will "decrypt"
garbage, so V1-first would produce false positives.

## Default keymaps

Defined in `lua/lc-cyber.lua`:

| Keys | Mode | Action |
|------|------|--------|
| `<leader>cd` | normal | Decode word under cursor; result shown in echo area, stored in register `@c`. Smart extraction of base64url-encoded IDs. |
| `<leader>cy` | normal | Same as above, also copies to system clipboard (`+` register). |
| `<leader>ce` | normal | Encode word under cursor. |
| `<leader>cd` | visual | Decode selection. |
| `<leader>cy` | visual | Decode selection, copy to clipboard. |

## Output contract (CRITICAL)

The Lua wrapper uses `2>&1` to merge stderr into stdout before parsing. This
means **the PHP backend MUST NOT write anything to stderr on success** — any
stderr noise would corrupt the decoded result.

- **stdout** = decoded/encoded value only
- **stderr** = errors only (nothing on success)
- exit code: `0` success, `1` decode failure, `2` usage error

This was a real bug during development: an earlier version printed
`(decoded as V1)` to stderr as a diagnostic, which broke the wrapper. If you add
debug output, route it through `2>/dev/null` at the Lua side or add a quiet
flag.

## Updating keys / nonces

The constants are at the top of `bin/lc-codec.php`. If upstream rotates them,
update:

- `LC_V2_KEY_HEX` and `LC_V2_NONCE_HEX` — match `app/Helpers/LCCrypt.php` in the
  services repo
- V1 key — derived at runtime from `str_rot13('bqDBPj6m9jLRCgU2')`; change the
  literal if that rotates (unlikely — V1 is legacy)

## Quick verification

```bash
# Should print 1163150, zero bytes on stderr
~/.config/nvim/bin/lc-codec.php decode 'qXJwAF2j9Q1LEmahTtSjBmTZ66XCQ7UYD01UEMrhQ4c'

# Round-trip test
id=1163150
enc=$(~/.config/nvim/bin/lc-codec.php encode "$id" 2)  # 2 = V2 (default)
~/.config/nvim/bin/lc-codec.php decode "$enc"          # → 1163150
```

## Why the PHP backend (not Python or pure Lua)

- **PHP 7.2+** ships `sodium` as a built-in extension — no pip/npm/cargo needed,
  just the php binary.
- **Rijndael-256 port**: LoanConnect's `LegacyCyber.php` was already a hand-port
  of a JS Rijndael implementation. Lifting it into a standalone CLI was ~200
  lines; porting to Python would have required the same effort (pycryptodome
  removed Rijndael-256 in favor of AES only).
- **Pure Lua**: would require implementing XSalsa20-Poly1305 *and* Rijndael-256
  in Lua — thousands of lines, slow, and reinventing wheels.

## Historical context

- `~/bin/lc-cyber` is an older Python tool that supports additional formats
  (`lcso` — gzip+base64+rot13 JSON blobs, `cyber-old` — Rijndael with the
  revoked key). It shells out to the CakePHP repo (`loanconnect/app/Lib/Cyber.php`)
  for the Rijndael step, which is the dependency this codec eliminates.
- The Neovim config used to call `~/bin/lc-cyber` via the Lua wrapper
  (`script_path = vim.fn.expand '~/bin/lc-cyber'`). As of 2026-04-21 it points
  at the self-contained `bin/lc-codec.php` instead.
- If you need `lcso` or `cyber-old` decoding, either call `~/bin/lc-cyber`
  directly, or vendor those formats into `bin/lc-codec.php` (both are
  pure-PHP-doable, no external crypto needed).

## Related

- `lua/lc-cyber.lua` — the wrapper, including the smart cursor-word extraction
  logic for base64url IDs embedded in URLs (`?id=...&`)
- `bin/lc-codec.php` — vendored Rijndael-256 port begins at the `rijndael` class
