#!/usr/bin/env php
<?php

/**
 * Standalone encoder/decoder for LoanConnect IDs — BOTH V1 and V2.
 *
 * Part of the Neovim config. No dependency on the services or loanconnect
 * repos — Rijndael-256 (V1) is vendored below; libsodium (V2) is a native
 * PHP extension (PHP 7.2+).
 *
 * V2 (hex input)       = libsodium crypto_secretbox (XSalsa20-Poly1305)
 * V1 (base64-ish)      = Rijndael-256 ECB with URL-safe base64 wrap
 *
 * Source refs (update these constants if they ever rotate upstream):
 *   V2 key/nonce: app/Helpers/LCCrypt.php in the services repo
 *   V1 key:       app/Classes/LegacyCyber.php (str_rot13 of 'bqDBPj6m9jLRCgU2')
 *
 * Usage:
 *   lc-codec.php decode <encoded>       # auto-detects V1 vs V2
 *   lc-codec.php encode <id> [1|2]      # 2 = default (V2). Pass "1" for V1.
 *   echo <value> | lc-codec.php {encode|decode} -
 *
 * Output contract (important for programmatic callers):
 *   stdout: decoded/encoded value only
 *   stderr: errors only (nothing on success)
 *   exit 0 on success, 1 on failure, 2 on usage error
 */
if (! function_exists('sodium_crypto_secretbox')) {
    fwrite(STDERR, "error: sodium extension not available. Install php-sodium.\n");
    exit(1);
}

// ========================================================================
// CONFIG — must mirror app/Helpers/LCCrypt.php and app/Classes/LegacyCyber.php
// ========================================================================

const LC_V2_NONCE_HEX = '4963853a82ba8a54c6b778c41373566aae568ccf2ec05336';
const LC_V2_KEY_HEX = 'd39a61e43aee890330294bf01a93442a8170aa6bd216b15b05a5ff6e56ee2758';
// V1 key is derived at runtime from str_rot13('bqDBPj6m9jLRCgU2').

// ========================================================================
// V2 — libsodium crypto_secretbox
// ========================================================================

function lc_v2_decode(string $hex): string|false
{
    if (! ctype_xdigit($hex) || strlen($hex) % 2 !== 0) {
        return false;
    }
    $result = sodium_crypto_secretbox_open(
        hex2bin($hex),
        hex2bin(LC_V2_NONCE_HEX),
        hex2bin(LC_V2_KEY_HEX),
    );

    return $result === false ? false : $result;
}

function lc_v2_encode(string $pt): string
{
    return bin2hex(sodium_crypto_secretbox(
        $pt,
        hex2bin(LC_V2_NONCE_HEX),
        hex2bin(LC_V2_KEY_HEX),
    ));
}

// ========================================================================
// V1 — Rijndael-256 ECB + URL-safe base64
// Ported inline from app/Classes/LegacyCyber.php. Log::error calls
// replaced with fwrite(STDERR). Behavior is otherwise identical.
// ========================================================================

function lc_v1_safe_b64decode(string $s): string
{
    $data = strtr($s, '-_', '+/');
    $mod4 = strlen($data) % 4;
    if ($mod4) {
        $data .= substr('====', $mod4);
    }

    return base64_decode($data);
}

function lc_v1_safe_b64encode(string $s): string
{
    return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($s));
}

function lc_v1_decode(string $value): string|false
{
    if ($value === '') {
        return false;
    }
    $key = str_rot13('bqDBPj6m9jLRCgU2');  // = 'odQOCw6z9wYEPtH2'
    $crypttext = lc_v1_safe_b64decode($value);
    if ($crypttext === '') {
        return false;
    }
    $iv = '';
    try {
        $plain = lc_mcrypt::decrypt('rijndael-256', $key, $crypttext, 'ecb', $iv);
    } catch (\Throwable $e) {
        return false;
    }

    return trim((string) $plain);
}

function lc_v1_encode(string $value): string|false
{
    if ($value === '') {
        return false;
    }
    $key = str_rot13('bqDBPj6m9jLRCgU2');
    $iv = '';
    try {
        $crypttext = lc_mcrypt::encrypt('rijndael-256', $key, $value, 'ecb', $iv);
    } catch (\Throwable $e) {
        return false;
    }

    return lc_v1_safe_b64encode($crypttext);
}

// ---- rijndael cipher (ported from LegacyCyber.php) ----
class rijndael
{
    private static $sizes = [16, 24, 32];

    private static $rounds = [[10, 12, 14], [12, 12, 14], [14, 14, 14]];

    private static $rowshifts = [[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 3, 4]];

    private static $Sbox = [
        99, 124, 119, 123, 242, 107, 111, 197, 48, 1, 103, 43, 254, 215, 171, 118,
        202, 130, 201, 125, 250, 89, 71, 240, 173, 212, 162, 175, 156, 164, 114, 192,
        183, 253, 147, 38, 54, 63, 247, 204, 52, 165, 229, 241, 113, 216, 49, 21,
        4, 199, 35, 195, 24, 150, 5, 154, 7, 18, 128, 226, 235, 39, 178, 117,
        9, 131, 44, 26, 27, 110, 90, 160, 82, 59, 214, 179, 41, 227, 47, 132,
        83, 209, 0, 237, 32, 252, 177, 91, 106, 203, 190, 57, 74, 76, 88, 207,
        208, 239, 170, 251, 67, 77, 51, 133, 69, 249, 2, 127, 80, 60, 159, 168,
        81, 163, 64, 143, 146, 157, 56, 245, 188, 182, 218, 33, 16, 255, 243, 210,
        205, 12, 19, 236, 95, 151, 68, 23, 196, 167, 126, 61, 100, 93, 25, 115,
        96, 129, 79, 220, 34, 42, 144, 136, 70, 238, 184, 20, 222, 94, 11, 219,
        224, 50, 58, 10, 73, 6, 36, 92, 194, 211, 172, 98, 145, 149, 228, 121,
        231, 200, 55, 109, 141, 213, 78, 169, 108, 86, 244, 234, 101, 122, 174, 8,
        186, 120, 37, 46, 28, 166, 180, 198, 232, 221, 116, 31, 75, 189, 139, 138,
        112, 62, 181, 102, 72, 3, 246, 14, 97, 53, 87, 185, 134, 193, 29, 158,
        225, 248, 152, 17, 105, 217, 142, 148, 155, 30, 135, 233, 206, 85, 40, 223,
        140, 161, 137, 13, 191, 230, 66, 104, 65, 153, 45, 15, 176, 84, 187, 22,
    ];

    private static $ShiftRowTab;

    private static $ShiftRowTab_Inv;

    private static $Sbox_Inv;

    private static $xtime;

    private static function init()
    {
        static::$ShiftRowTab = array_fill(0, 3, 0);
        static::$ShiftRowTab_Inv = array_fill(0, 3, 0);
        static::$Sbox_Inv = array_fill(0, 256, 0);
        static::$xtime = array_fill(0, 256, 0);
        for ($i = 0; $i < 3; $i++) {
            static::$ShiftRowTab[$i] = array_fill(0, static::$sizes[$i], 0);
            for ($j = static::$sizes[$i]; $j >= 0; $j--) {
                static::$ShiftRowTab[$i][$j] = ($j + (static::$rowshifts[$i][$j & 3] << 2)) % static::$sizes[$i];
            }
        }
        for ($i = 0; $i < 256; $i++) {
            static::$Sbox_Inv[static::$Sbox[$i]] = $i;
        }
        for ($i = 0; $i < 3; $i++) {
            static::$ShiftRowTab_Inv[$i] = array_fill(0, static::$sizes[$i], 0);
            for ($j = static::$sizes[$i]; $j >= 0; $j--) {
                static::$ShiftRowTab_Inv[$i][static::$ShiftRowTab[$i][$j]] = $j;
            }
        }
        for ($i = 0; $i < 128; $i++) {
            static::$xtime[$i] = $i << 1;
            static::$xtime[128 + $i] = ($i << 1) ^ 0x1B;
        }
    }

    private static function expandKey($key)
    {
        $Rcon = 1;
        $ks = 15 << 5;
        $keyA = $key;
        $kl = count($keyA);
        for ($i = $kl; $i < $ks; $i += 4) {
            $temp = array_values(array_slice($keyA, $i - 4, $i));
            if ($i % $kl == 0) {
                $temp = [static::$Sbox[$temp[1]] ^ $Rcon, static::$Sbox[$temp[2]], static::$Sbox[$temp[3]], static::$Sbox[$temp[0]]];
                if (($Rcon <<= 1) >= 256) {
                    $Rcon ^= 0x11B;
                }
            } elseif (($kl > 24) && ($i % $kl == 16)) {
                $temp = [static::$Sbox[$temp[0]], static::$Sbox[$temp[1]], static::$Sbox[$temp[2]], static::$Sbox[$temp[3]]];
            }
            for ($j = 0; $j < 4; $j++) {
                $keyA[$i + $j] = $keyA[$i + $j - $kl] ^ $temp[$j];
            }
        }

        return $keyA;
    }

    private static function subBytes(&$state, $sbox)
    {
        for ($i = count($state) - 1; $i >= 0; $i--) {
            $state[$i] = $sbox[$state[$i]];
        }
    }

    private static function addRoundKey(&$state, $rkey)
    {
        for ($i = count($state) - 1; $i >= 0; $i--) {
            $state[$i] ^= $rkey[$i];
        }
    }

    private static function shiftRows(&$state, $shifttab)
    {
        $h = $state;
        for ($i = count($state) - 1; $i >= 0; $i--) {
            $state[$i] = $h[$shifttab[$i]];
        }
    }

    private static function mixColumns(&$state)
    {
        for ($i = count($state) - 4; $i >= 0; $i -= 4) {
            $s0 = $state[$i + 0];
            $s1 = $state[$i + 1];
            $s2 = $state[$i + 2];
            $s3 = $state[$i + 3];
            $h = $s0 ^ $s1 ^ $s2 ^ $s3;
            $state[$i + 0] ^= $h ^ static::$xtime[$s0 ^ $s1];
            $state[$i + 1] ^= $h ^ static::$xtime[$s1 ^ $s2];
            $state[$i + 2] ^= $h ^ static::$xtime[$s2 ^ $s3];
            $state[$i + 3] ^= $h ^ static::$xtime[$s3 ^ $s0];
        }
    }

    private static function mixColumns_Inv(&$state)
    {
        for ($i = count($state) - 4; $i >= 0; $i -= 4) {
            $s0 = $state[$i + 0];
            $s1 = $state[$i + 1];
            $s2 = $state[$i + 2];
            $s3 = $state[$i + 3];
            $h = $s0 ^ $s1 ^ $s2 ^ $s3;
            $xh = static::$xtime[$h];
            $h1 = static::$xtime[static::$xtime[$xh ^ $s0 ^ $s2]] ^ $h;
            $h2 = static::$xtime[static::$xtime[$xh ^ $s1 ^ $s3]] ^ $h;
            $state[$i + 0] ^= $h1 ^ static::$xtime[$s0 ^ $s1];
            $state[$i + 1] ^= $h2 ^ static::$xtime[$s1 ^ $s2];
            $state[$i + 2] ^= $h1 ^ static::$xtime[$s2 ^ $s3];
            $state[$i + 3] ^= $h2 ^ static::$xtime[$s3 ^ $s0];
        }
    }

    private static function crypt(&$block, $key, $encrypt)
    {
        static::init();
        $bB = count($block);
        $kB = count($key);
        $bBi = 0;
        $kBi = 0;
        switch ($bB) {
            case 32: $bBi++;
            case 24: $bBi++;
            case 16: break;
            default: fwrite(STDERR, "Rijndael: unsupported block size $bB\n");

                return;
        }
        switch ($kB) {
            case 32: $kBi++;
            case 24: $kBi++;
            case 16: break;
            default: fwrite(STDERR, "Rijndael: unsupported key size $kB\n");

                return;
        }
        $r = static::$rounds[$bBi][$kBi];
        $key = static::expandKey($key);
        $end = $r * $bB;
        if ($encrypt) {
            static::addRoundKey($block, array_values(array_slice($key, 0, $bB)));
            $SRT = static::$ShiftRowTab[$bBi];
            for ($i = $bB; $i < $end; $i += $bB) {
                static::subBytes($block, static::$Sbox);
                static::shiftRows($block, $SRT);
                static::mixColumns($block);
                static::addRoundKey($block, array_values(array_slice($key, $i, $i + $bB)));
            }
            static::subBytes($block, static::$Sbox);
            static::shiftRows($block, $SRT);
            static::addRoundKey($block, array_values(array_slice($key, $i, $i + $bB)));
        } else {
            static::addRoundKey($block, array_values(array_slice($key, $end, $end + $bB)));
            $SRT = static::$ShiftRowTab_Inv[$bBi];
            static::shiftRows($block, $SRT);
            static::subBytes($block, static::$Sbox_Inv);
            for ($i = $end - $bB; $i >= $bB; $i -= $bB) {
                static::addRoundKey($block, array_values(array_slice($key, $i, $i + $bB)));
                static::mixColumns_Inv($block);
                static::shiftRows($block, $SRT);
                static::subBytes($block, static::$Sbox_Inv);
            }
            static::addRoundKey($block, array_values(array_slice($key, 0, $bB)));
        }
    }

    public static function encrypt($block, $key)
    {
        static::crypt($block, $key, true);

        return $block;
    }

    public static function decrypt($block, $key)
    {
        static::crypt($block, $key, false);

        return $block;
    }
}

// ---- lc_mcrypt wrapper (ports LegacyCyber's lc_mcrypt class) ----
class lc_mcrypt
{
    private static $ciphers = [
        'rijndael-128' => ['blockSize' => 16, 'keySize' => 32],
        'rijndael-192' => ['blockSize' => 24, 'keySize' => 32],
        'rijndael-256' => ['blockSize' => 32, 'keySize' => 32],
    ];

    private static function rijndaelCipher(&$block, $key, $encrypt)
    {
        $block = $encrypt ? rijndael::encrypt($block, $key) : rijndael::decrypt($block, $key);

        return $block;
    }

    private static function crypt($encrypt, $text, $IV, $key, $cipher, $mode)
    {
        if (empty($text)) {
            return true;
        }
        $IV = is_scalar($IV) ? array_values(unpack('C*', $IV)) : $IV;
        $key = is_scalar($key) ? array_values(unpack('C*', $key)) : $key;
        $text = is_scalar($text) ? array_values(unpack('C*', $text)) : $text;
        $blockS = static::$ciphers[$cipher]['blockSize'];
        $chunkS = $blockS;
        $iv = [];
        if ($mode !== 'ecb') {
            fwrite(STDERR, "Only ECB mode supported in this standalone port.\n");

            return false;
        }
        $chunks = ceil(count($text) / $chunkS);
        while (count($text) < $chunks * $chunkS) {
            array_push($text, 0);
        }
        $out = [];
        for ($i = 0; $i < $chunks; $i++) {
            for ($j = 0; $j < $chunkS; $j++) {
                $iv[$j] = $text[($i * $chunkS) + $j];
            }
            static::rijndaelCipher($iv, $key, $encrypt);
            for ($j = 0; $j < $chunkS; $j++) {
                array_push($out, $iv[$j]);
            }
            do {
                $last = array_pop($out);
            } while ($last == 0);
            array_push($out, $last);
        }
        $rebuilt = '';
        foreach ($out as $c) {
            $rebuilt .= pack('C', $c);
        }

        return $rebuilt;
    }

    public static function encrypt($cipher, $key, $text, $mode, $iv)
    {
        return static::crypt(true, $text, $iv, $key, $cipher, $mode);
    }

    public static function decrypt($cipher, $key, $text, $mode, $iv)
    {
        return static::crypt(false, $text, $iv, $key, $cipher, $mode);
    }
}

// ========================================================================
// Auto-detect decode / version-aware encode
// ========================================================================

function lc_decode_auto(string $input): array
{
    $input = trim($input);
    if ($input === '' || $input === 'null') {
        return ['version' => 0, 'value' => false];
    }
    // Try V2 first if input looks like hex
    if (ctype_xdigit($input) && strlen($input) % 2 === 0) {
        $r = lc_v2_decode($input);
        if ($r !== false && mb_check_encoding($r, 'UTF-8')) {
            return ['version' => 2, 'value' => $r];
        }
    }
    // Fall back to V1 (Rijndael-256 + URL-safe base64)
    $r = lc_v1_decode($input);
    if ($r !== false && $r !== '' && mb_check_encoding($r, 'UTF-8')) {
        return ['version' => 1, 'value' => $r];
    }

    return ['version' => 0, 'value' => false];
}

// ========================================================================
// CLI
// ========================================================================

$op = $argv[1] ?? null;
$val = $argv[2] ?? '-';
$version = $argv[3] ?? '2';

if (! in_array($op, ['encode', 'decode'], true)) {
    fwrite(STDERR, "usage: lc-codec.php {encode|decode} [value | -] [encode-version 1|2]\n");
    exit(2);
}

if ($val === '-') {
    $val = trim((string) stream_get_contents(STDIN));
}

if ($op === 'decode') {
    $result = lc_decode_auto($val);
    if ($result['version'] === 0) {
        fwrite(STDERR, "error: could not decode as V1 or V2\n");
        exit(1);
    }
    // stdout: decoded value only (contract for programmatic callers)
    echo $result['value'].PHP_EOL;
} else {
    if ($version === '1') {
        $encoded = lc_v1_encode($val);
        if ($encoded === false) {
            fwrite(STDERR, "V1 encode failed\n");
            exit(1);
        }
        echo $encoded.PHP_EOL;
    } else {
        echo lc_v2_encode($val).PHP_EOL;
    }
}
