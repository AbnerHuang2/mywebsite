#!/bin/bash

# PlantUML 图表对比度增强脚本
# 在图表中添加高对比度样式设置

set -e

if [ $# -eq 0 ]; then
    echo "用法: $0 <markdown文件路径>"
    echo "示例: $0 content/posts/Go语言GMP调度器详解.md"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "错误: 文件不存在: $FILE"
    exit 1
fi

# 创建备份
BACKUP="${FILE}.backup-contrast"
cp "$FILE" "$BACKUP"
echo "✅ 已创建备份: $BACKUP"

# 使用 perl 进行多行替换
# 在每个 @startuml 后添加高对比度样式（如果还没有的话）
perl -i -0pe 's/(@startuml\n)(?!skinparam ArrowThickness|skinparam defaultFontStyle)/
$1skinparam defaultFontStyle bold
skinparam ArrowThickness 3
skinparam sequenceArrowThickness 3
skinparam ArrowColor #000000
skinparam BorderColor #000000
skinparam defaultFontSize 13

/g' "$FILE"

echo "✅ 已优化 PlantUML 图表对比度"
echo ""
echo "📋 优化内容："
echo "  - 字体加粗 (defaultFontStyle bold)"
echo "  - 线条加粗 (ArrowThickness 3)"
echo "  - 深色线条和边框 (#000000)"
echo "  - 字体大小增加 (13)"
echo ""
echo "💡 提示："
echo "  1. 请检查修改效果"
echo "  2. 如果需要恢复，使用备份文件: $BACKUP"
echo "  3. 刷新浏览器查看效果"

