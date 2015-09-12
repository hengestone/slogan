Disclaimer: This library is not battle-tested. Use at your own risk.

The Crypto library implements various symmetric and public-key cryptographic algorithms.
The core algorithms are implemented in C and is based on the code from "Implementing SSL / TLS Using Cryptography and PKI" by Joshua Davies.
(See: http://as.wiley.com/WileyCDA/WileyTitle/productCd-0470920416.html).
In the long-term the `crypto` library should move to a robust backend like OpenSSL.

Building the library
====================

Export the environment variable `SLOGAN_ROOT` to point to the Slogan parent directory.
Build the shared library by running the `build` script in this folder.

Load and initialize the crypto-library
======================================

````
load "$SLOGAN_ROOT/lib/crypto/crypto";

// Do crypto-stuff here

````

Hashing
=======

````
load "$SLOGAN_ROOT/lib/crypto/digest";
import crypto_digest as digest;

// MD5 and SHA-n hash functions
digest_hash(string_to_u8array("abc"), !md5);
digest_hash(string_to_u8array("abc"), !sha1);
digest_hash(string_to_u8array("abc"), !sha256);

// HMAC
digest_hmac(string_to_u8array("pass"), string_to_u8array("hello world"), !md5);
digest_hmac(string_to_u8array("pass"), string_to_u8array("hello world"), !sha1);
````

Symmetric-key algorithms
========================

DES
---

````
load "$SLOGAN_ROOT/lib/crypto/des";
import crypto_des as des;

define key = "password";
define iv = "12345678";
define e = des_encrypt(key, iv, string_to_u8array("abcdefgh"));
define d = des_decrypt(key, iv, e);
u8array_to_string(d);

// A 24 byte key will perform 3DES encryption:
key = "123456789012345678901234";
define e = des_encrypt(key, iv, string_to_u8array("abcdefgh"));
define d = des_decrypt(key, iv, e);
u8array_to_string(d);
````


AES
---

````
load "$SLOGAN_ROOT/lib/crypto/aes";
import crypto_aes as aes;

define key = "0123456789abcdef";
define iv = "AAAAAAAAAAAAAAAA";
define e = aes_encrypt(key, iv, string_to_u8array("abcdefghabcdefgh"));
define d = aes_decrypt(key, iv, e);
u8array_to_string(d);

// A 32 byte key will perform AES-256 encryption:
key = "12345678901234567890123456789012";
define e = aes_encrypt(key, iv, string_to_u8array("abcdefghabcdefgh"));
define d = aes_decrypt(key, iv, e);
u8array_to_string(d);
````

RC4
---

````
load "$SLOGAN_ROOT/lib/crypto/rc4";
import crypto_rc4 as rc4;

define a = rc4_encrypt_40("password", string_to_u8array("hello"));
u8array_to_string(rc4_decrypt_40("password", a));
define a = rc4_encrypt_128("password", string_to_u8array("hello"));
u8array_to_string(rc4_decrypt_128("password", a));
````

RSA
---

````
load "$SLOGAN_ROOT/lib/crypto/rsa";
import crypto_rsa as rsa;

define modulus = #u8[0xC4, 0xF8, 0xE9, 0xE1, 0x5D, 0xCA, 0xDF, 0x2B,
                     0x96, 0xC7, 0x63, 0xD9, 0x81, 0x00, 0x6A, 0x64,
                     0x4F, 0xFB, 0x44, 0x15, 0x03, 0x0A, 0x16, 0xED,
                     0x12, 0x83, 0x88, 0x33, 0x40, 0xF2, 0xAA, 0x0E,
                     0x2B, 0xE2, 0xBE, 0x8F, 0xA6, 0x01, 0x50, 0xB9,
                     0x04, 0x69, 0x65, 0x83, 0x7C, 0x3E, 0x7D, 0x15,
                     0x1B, 0x7D, 0xE2, 0x37, 0xEB, 0xB9, 0x57, 0xC2,
                     0x06, 0x63, 0x89, 0x82, 0x50, 0x70, 0x3B, 0x3F];
                     
define privatekey = #u8[0x8a, 0x7e, 0x79, 0xf3, 0xfb, 0xfe, 0xa8, 0xeb,
                        0xfd, 0x18, 0x35, 0x1c, 0xb9, 0x97, 0x91, 0x36,
                        0xf7, 0x05, 0xb4, 0xd9, 0x11, 0x4a, 0x06, 0xd4,
                        0xaa, 0x2f, 0xd1, 0x94, 0x38, 0x16, 0x67, 0x7a,
                        0x53, 0x74, 0x66, 0x18, 0x46, 0xa3, 0x0c, 0x45,
                        0xb3, 0x0a, 0x02, 0x4b, 0x4d, 0x22, 0xb1, 0x5a,
                        0xb3, 0x23, 0x62, 0x2b, 0x2d, 0xe4, 0x7b, 0xa2,
                        0x91, 0x15, 0xf0, 0x6e, 0xe4, 0x2c, 0x41];
                        
define publickey = #u8[0x01, 0x00, 0x01];

function mkkey(m, k) (u8array_length(m) : m) : (u8array_length(k) : k);

define e = rsa_encrypt(mkkey(modulus, publickey), string_to_u8array("abc"));
define d = rsa_decrypt(mkkey(modulus, privatekey), e);
u8array_to_string(d);
````

DSA
---

````
load "$SLOGAN_ROOT/lib/crypto/dsa";
import crypto_dsa as dsa;

define priv = #u8[0x53, 0x61, 0xae, 0x4f, 0x6f, 0x25, 0x98, 0xde, 0xc4, 0xbf, 0x0b, 0xbe, 0x09, 
                  0x5f, 0xdf,  0x90, 0x2f, 0x4c, 0x8e, 0x09];
define pub = #u8[0x1b, 0x91, 0x4c, 0xa9, 0x73, 0xdc, 0x06, 0x0d, 0x21, 0xc6, 0xff, 0xab, 0xf6, 
                 0xad, 0xf4, 0x11, 0x97, 0xaf, 0x23, 0x48, 0x50, 0xa8, 0xf3, 0xdb, 0x2e, 0xe6, 
                 0x27, 0x8c, 0x40, 0x4c,  0xb3, 0xc8, 0xfe, 0x79, 0x7e, 0x89, 0x48, 0x90, 0x27, 
                 0x92, 0x6f, 0x5b, 0xc5, 0xe6, 0x8f,  0x91, 0x4c, 0xe9, 0x4f, 0xed, 0x0d, 0x3c, 
                 0x17, 0x09, 0xeb, 0x97, 0xac, 0x29, 0x77, 0xd5,  0x19, 0xe7, 0x4d, 0x17];
define P = #u8[0x00, 0x9c, 0x4c, 0xaa, 0x76, 0x31, 0x2e, 0x71, 0x4d, 0x31, 0xd6, 0xe4, 0xd7, 
               0xe9, 0xa7,  0x29, 0x7b, 0x7f, 0x05, 0xee, 0xfd, 0xca, 0x35, 0x14, 0x1e, 0x9f, 
               0xe5, 0xc0, 0x2a, 0xe0,  0x12, 0xd9, 0xc4, 0xc0, 0xde, 0xcc, 0x66, 0x96, 0x2f, 
               0xf1, 0x8f, 0x1a, 0xe1, 0xe8, 0xbf,  0xc2, 0x29, 0x0d, 0x27, 0x07, 0x48, 0xb9, 
               0x71, 0x04, 0xec, 0xc7, 0xf4, 0x16, 0x2e, 0x50,  0x8d, 0x67, 0x14, 0x84, 0x7b];
define Q = #u8[0x00, 0xac, 0x6f, 0xc1, 0x37, 0xef, 0x16, 0x74, 0x52, 0x6a, 0xeb, 0xc5, 0xf8, 
               0xf2, 0x1f,  0x53, 0xf4, 0x0f, 0xe0, 0x51, 0x5f];
define G = #u8[0x7d, 0xcd, 0x66, 0x81, 0x61, 0x52, 0x21, 0x10, 0xf7, 0xa0, 0x83, 0x4c, 0x5f, 
               0xc8, 0x84,  0xca, 0xe8, 0x8a, 0x9b, 0x9f, 0x19, 0x14, 0x8c, 0x7d, 0xd0, 0xee, 
               0x33, 0xce, 0xb4, 0x57,  0x2d, 0x5e, 0x78, 0x3f, 0x06, 0xd7, 0xb3, 0xd6, 0x40, 
               0x70, 0x2e, 0xb6, 0x12, 0x3f, 0x4a,  0x61, 0x38, 0xae, 0x72, 0x12, 0xfb, 0x77, 
               0xde, 0x53, 0xb3, 0xa1, 0x99, 0xd8, 0xa8, 0x19,  0x96, 0xf7, 0x7f, 0x99];

define msg = string_to_u8array("abc123");
define sign = dsa_sign(G, P, Q, priv, msg);
dsa_verify(G, P, Q, pub, sign, msg);
````

ECDSA
-----

````
load "$SLOGAN_ROOT/lib/crypto/ecdsa";
import crypto_ecdsa as ecdsa;

define P = #u8[0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 
               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 
               0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF];
              
define b = #u8[0x5A, 0xC6, 0x35, 0xD8, 0xAA, 0x3A, 0x93, 0xE7, 0xB3, 0xEB, 0xBD, 0x55, 0x76, 
               0x98, 0x86,  0xBC, 0x65, 0x1D, 0x06, 0xB0, 0xCC, 0x53, 0xB0, 0xF6, 0x3B, 0xCE, 
               0x3C, 0x3E, 0x27, 0xD2, 0x60, 0x4B];
define q = #u8[0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 
               0xFF, 0xFF, 0xFF, 0xBC, 0xE6, 0xFA, 0xAD, 0xA7, 0x17, 0x9E, 0x84, 0xF3, 0xB9, 
               0xCA, 0xC2, 0xFC, 0x63, 0x25, 0x51];
define gx = #u8[0x6B, 0x17, 0xD1, 0xF2, 0xE1, 0x2C, 0x42, 0x47, 0xF8, 0xBC, 0xE6, 0xE5, 0x63, 
                0xA4, 0x40, 0xF2, 0x77, 0x03, 0x7D, 0x81, 0x2D, 0xEB, 0x33, 0xA0, 0xF4, 0xA1, 
                0x39, 0x45, 0xD8, 0x98, 0xC2, 0x96];
define gy = #u8[0x4F, 0xE3, 0x42, 0xE2, 0xFE, 0x1A, 0x7F, 0x9B, 0x8E, 0xE7, 0xEB, 0x4A, 0x7C, 
                0x0F, 0x9E, 0x16, 0x2B, 0xCE, 0x33, 0x57, 0x6B, 0x31, 0x5E, 0xCE, 0xCB, 0xB6, 
                0x40, 0x68, 0x37, 0xBF, 0x51, 0xF5];

// key
define w = #u8[0xDC, 0x51, 0xD3, 0x86, 0x6A, 0x15, 0xBA, 0xCD, 0xE3, 
               0x3D, 0x96, 0xF9, 0x92, 0xFC, 0xA9, 0x9D, 0xA7, 0xE6, 0xEF, 0x09, 0x34, 0xE7, 
               0x09, 0x75, 0x59, 0xC2, 0x7F, 0x16, 0x14, 0xC8, 0x8A, 0x7F];

define msg = string_to_u8array("abc");
define sign = ecdsa_sign(P, b, q, gx, gy, w, msg);
ecdsa_verify(P, b, q, gx, gy, w, sign, msg);
````

Certificates
============

Use OpenSSL to generate a sample certificate for testing:

````
$ openssl req -x509 -newkey rsa:512 -keyout key.der -keyform der -out cert.der -outform der
````

Read and parse the certificate from Slogan:

````
load "$SLOGAN_ROOT/lib/crypto/cert";
import crypto_cert as cert;

define cfile = "cert.der";
define p = open_file_input_port(cfile);
define b = read_n_bytes(file_size(cfile), p);
define c1 = cert_asn1_parse(b);
define c2 = cert_x509_parse(b, false);
````