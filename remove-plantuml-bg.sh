#!/bin/bash

# 移除 PlantUML 图表中的背景色定义
# 将 backgroundColor 改为 transparent

INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ]; then
    echo "使用方法: $0 <markdown文件路径>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 文件不存在: $INPUT_FILE"
    exit 1
fi

# 创建备份
BACKUP_FILE="${INPUT_FILE}.bak"
cp "$INPUT_FILE" "$BACKUP_FILE"
echo "已创建备份: $BACKUP_FILE"

# 替换背景色为透明
sed -i '' 's/skinparam backgroundColor #[A-Fa-f0-9]*/skinparam backgroundColor transparent/g' "$INPUT_FILE"

echo "完成！已将所有 backgroundColor 改为 transparent"
echo ""
echo "如需恢复，运行: mv $BACKUP_FILE $INPUT_FILE"

