#!/bin/bash

echo "🎨 Favicon 生成工具"
echo "=================="
echo ""

# 检查原始图片
if [ ! -f "static/favicon-original.png" ]; then
    echo "❌ 错误：找不到 static/favicon-original.png"
    echo ""
    echo "请先保存图片："
    echo "  1. 将 KH 图片保存为 static/favicon-original.png"
    echo "  2. 再次运行此脚本：./generate-favicons.sh"
    echo ""
    exit 1
fi

echo "✅ 找到原始图片"
echo ""
echo "🔄 开始生成各种尺寸..."

cd static

# 生成不同尺寸
sips -z 180 180 favicon-original.png --out apple-touch-icon.png 2>/dev/null
echo "  ✓ apple-touch-icon.png (180x180)"

sips -z 32 32 favicon-original.png --out favicon-32x32.png 2>/dev/null
echo "  ✓ favicon-32x32.png (32x32)"

sips -z 16 16 favicon-original.png --out favicon-16x16.png 2>/dev/null
echo "  ✓ favicon-16x16.png (16x16)"

sips -z 192 192 favicon-original.png --out android-chrome-192x192.png 2>/dev/null
echo "  ✓ android-chrome-192x192.png (192x192)"

sips -z 512 512 favicon-original.png --out android-chrome-512x512.png 2>/dev/null
echo "  ✓ android-chrome-512x512.png (512x512)"

cd ..

echo ""
echo "✅ PNG 文件生成完成！"
echo ""
echo "⚠️  还需要 favicon.ico 文件："
echo "  1. 访问 https://favicon.io/favicon-converter/"
echo "  2. 上传 static/favicon-original.png"
echo "  3. 下载生成的 favicon.ico"
echo "  4. 将 favicon.ico 放到 static/ 目录"
echo ""
echo "✅ site.webmanifest 已经创建好了"
echo ""
echo "🎉 完成后运行 hugo server -D 查看效果！"

