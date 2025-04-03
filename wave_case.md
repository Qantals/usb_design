# receive - RX

## crc5_r

- case 0: TOKEN (IN) + HANDSHAKE (ACK)
- case 1: TOKEN (OUT) + DATA0
- case 2: HANDSHAKE (ACK)
- case 3: DATA0

## crc16_r

- case 0: (NONE)
- case 1: TOKEN (OUT) + DATA0
- case 2: (NONE)
- case 3: DATA0


# send - TX

## crc5_t

- case 0: NONE
- case 1: HANDSHAKE (ACK)
- case 2: TOKEN (OUT)
- case 3: TOKEN (IN), HANDSHAKE (ACK)

## control_t

- case 0: **DATA0**
- case 1: HANDSHAKE (ACK)
- case 2: TOKEN (OUT) + **DATA0**
- case 3: TOKEN (IN), HANDSHAKE (ACK)


# compose - link_control

- IN transaction
    - case 0 (slave): rx: TOKEN (IN), tx: DATA0, rx: HANDSHAKE (ACK)
    - case 3 (master): tx: TOKEN (IN), rx: DATA0, tx: HANDSHAKE (ACK)
- OUT transaction
    - case 1 (slave): rx: TOKEN (OUT), rx: DATA0, tx: HANDSHAKE (ACK)
    - case 2 (master): tx: TOKEN (OUT), tx: DATA0, rx: HANDSHAKE (ACK)
