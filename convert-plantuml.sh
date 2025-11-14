#!/bin/bash

# PlantUML 代码块转换脚本
# 将 Markdown 中的 ```plantuml 代码块转换为 Hugo shortcode

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
BACKUP_FILE="${INPUT_FILE}.backup"
cp "$INPUT_FILE" "$BACKUP_FILE"
echo "已创建备份: $BACKUP_FILE"

# 使用 awk 进行转换
awk '
BEGIN {
    in_plantuml = 0
}
{
    if ($0 ~ /^```plantuml/) {
        # 开始 plantuml 代码块
        print "{{< plantuml >}}"
        in_plantuml = 1
    } else if (in_plantuml && $0 ~ /^```/) {
        # 结束 plantuml 代码块
        print "{{< /plantuml >}}"
        in_plantuml = 0
    } else {
        # 普通行，直接输出
        print $0
    }
}
' "$BACKUP_FILE" > "$INPUT_FILE"

echo "转换完成！"
echo "原文件: $INPUT_FILE"
echo "备份文件: $BACKUP_FILE"
echo ""
echo "请检查转换结果，如果有问题可以从备份恢复:"
echo "  mv $BACKUP_FILE $INPUT_FILE"

