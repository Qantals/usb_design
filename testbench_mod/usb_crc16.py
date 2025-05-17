def crc16_usb(data):
    """
    计算USB协议DATA0数据包的CRC16校验码
    
    参数:
        data (bytes或list): 输入数据，每个元素为一个字节(0-255)
    
    返回:
        bytes: 2字节的CRC16校验码
    """
    # 初始化CRC值为0xFFFF
    crc = 0xFFFF
    # USB CRC16多项式: 0x8005 (x^16 + x^15 + x^2 + 1)
    polynomial = 0x8005
    
    # 按位反转每个输入字节
    reversed_data = [reverse_bits(byte) for byte in data]
    
    # 对每个字节进行处理
    for byte in reversed_data:
        # 将当前字节与CRC的高8位异或
        crc ^= (byte << 8)
        
        # 对每个位进行处理
        for _ in range(8):
            if crc & 0x8000:
                crc = (crc << 1) ^ polynomial
            else:
                crc <<= 1
        
        # 确保CRC保持在16位范围内
        crc &= 0xFFFF
    
    # 按位取反
    crc ^= 0xFFFF
    
    # 按位反转CRC结果
    crc = reverse_bits(crc, 16)
    
    # 转换为大端字节序的2字节序列（修改点）
    return crc.to_bytes(2, 'big')

def reverse_bits(value, width=8):
    """按位反转一个数值"""
    result = 0
    for _ in range(width):
        result = (result << 1) | (value & 1)
        value >>= 1
    return result

# 示例使用
if __name__ == "__main__":
    test_cases = [
        # bytes([0x01, 0x02, 0x03, 0x04, 0x05]),
        # bytes([0x82, 0x65, 0x90, 0x16]),
        bytes([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d])
    ]
    
    for data_packet in test_cases:
        # 计算CRC16校验码
        crc = crc16_usb(data_packet)
        
        print(f"输入数据: {data_packet.hex()}")
        print(f"CRC16校验码: {crc.hex()}")
        print()    