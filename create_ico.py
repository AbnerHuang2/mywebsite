#!/usr/bin/env python3
import struct

# 读取PNG文件
with open('static/favicon-32x32.png', 'rb') as f:
    png_data = f.read()

# 创建简单的ICO文件头
ico_header = struct.pack('<HHH', 0, 1, 1)  # Reserved, Type, Count
ico_entry = struct.pack('<BBBBHHII', 32, 32, 0, 0, 1, 32, len(png_data), 22)

# 写入ICO文件
with open('static/favicon.ico', 'wb') as f:
    f.write(ico_header)
    f.write(ico_entry)
    f.write(png_data)

print("✅ favicon.ico 已创建")

