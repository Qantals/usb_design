# receive - `rx`

## crc5_r

- case 0: TOKEN + HANDSHAKE
- case 1: TOKEN + DATA
- case 2: HANDSHAKE
- case 3: DATA

## crc16_r

literally same as `crc5_r`.

- case 0: (NONE)
- case 1: TOKEN + DATA
- case 2: (NONE)
- case 3: DATA


# send - `tx`

## crc5_t

- case 0: NONE
- case 1: HANDSHAKE (ACK)
- case 2: TOKEN (OUT)
- case 3: TOKEN (IN), HANDSHAKE (ACK)

