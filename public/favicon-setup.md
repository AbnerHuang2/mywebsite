# Favicon 设置说明

## 快速设置（推荐）

### 方法1：使用在线工具（最简单）

1. 访问 https://favicon.io/favicon-converter/
2. 上传你的 KH 图片
3. 下载生成的 favicon 包
4. 解压后，将所有文件复制到 `static/` 目录
5. 完成！

需要的文件：
```
static/
├── android-chrome-192x192.png
├── android-chrome-512x512.png
├── apple-touch-icon.png
├── favicon-16x16.png
├── favicon-32x32.png
├── favicon.ico
└── site.webmanifest
```

### 方法2：手动转换（macOS）

1. 将图片保存为 `static/favicon-original.png`
2. 运行以下命令：

```bash
cd static

# 生成各种尺寸
sips -z 180 180 favicon-original.png --out apple-touch-icon.png
sips -z 32 32 favicon-original.png --out favicon-32x32.png
sips -z 16 16 favicon-original.png --out favicon-16x16.png
sips -z 192 192 favicon-original.png --out android-chrome-192x192.png
sips -z 512 512 favicon-original.png --out android-chrome-512x512.png
```

3. 创建 `site.webmanifest` 文件（见下方）
4. favicon.ico 需要在线转换

### site.webmanifest 内容

创建 `static/site.webmanifest` 文件，内容如下：

```json
{
  "name": "",
  "short_name": "",
  "icons": [
    {
      "src": "/android-chrome-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/android-chrome-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "theme_color": "#ffffff",
  "background_color": "#ffffff",
  "display": "standalone"
}
```

## 验证

设置完成后：
1. 运行 `hugo server -D`
2. 打开浏览器，查看标签页图标
3. 提交到 Git 并部署

## 删除说明文件

确认 favicon 正常显示后，可以删除本说明文件。

