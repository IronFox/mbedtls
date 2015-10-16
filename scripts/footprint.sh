#!/bin/sh

set -eu

doit()
{
    NAME="$1"
    FILE="$2"

    cp include/mbedtls/config.h include/mbedtls/config.h.bak

    cp "$FILE" include/mbedtls/config.h
    echo "$FILE:"

    {
        scripts/config.pl unset MBEDTLS_NET_C || true
        scripts/config.pl unset MBEDTLS_TIMING_C || true
        scripts/config.pl unset MBEDTLS_FS_IO || true
    } >/dev/null 2>&1

    CC=arm-none-eabi-gcc AR=arm-none-eabi-ar LD=arm-none-eabi-ld \
        CFLAGS='-Wa,--noexecstack -Os -march=armv7-m -mthumb -s -DNDEBUG' \
        make clean lib >/dev/null 2>&1

    OUT="size-${NAME}.txt"
    arm-none-eabi-size -t library/libmbed*.a > "$OUT"
    head -n1 "$OUT"
    tail -n1 "$OUT"

    mv include/mbedtls/config.h.bak include/mbedtls/config.h
}

# creates the yotta config
yotta/create-module.sh >/dev/null

doit default    include/mbedtls/config.h.bak
doit yotta      yotta/module/mbedtls/config.h
doit thread     configs/config-ecjpake.h
doit ecc        configs/config-suite-b.h
doit psk        configs/config-ccm-psk-tls1_2.h
