# hugo
    版本    0.152.2
# 主题
    "name": "hugo-congo-theme",
    "version": "2.9.0"
# 使用
1. git clone项目到本地， 后面记得增加参数 --recurse-submodules ，用于初始化子模块（git clone git@github.com:AbnerHuang2/mywebsite.git --recurse-submodules）
2. git checkout master (master才是工作分支， gh-pages是部署分支)
3. git submodule update --remote --merge (更新congo模块)
2. hugo server -D
3. 写博客 hugo new posts/your-post-name.md
4. 部署 git 推送代码即可（git add . & git commit & git push）
# 文档
    https://jpanther.github.io/congo/docs/getting-started/
# 工作机制
1. git push到master之后，会触发github actions构建部署静态页面到gh-pages分支
2. gh-pages分支被更新后，会触发vercel的hook，重新构建部署到vercel上。


# 自定义功能扩展说明

## 📂 项目结构说明

本项目使用 Hugo 的扩展点机制来添加自定义功能，**不修改主题源码**，便于主题升级。

### 自定义文件位置

```
layouts/
├── _default/
│   ├── baseof.html              # 覆盖主题基础模板（修复主题bug）
│   └── _markup/
│       └── render-image.html    # 自定义图片渲染（支持Fancybox放大）
├── partials/
│   ├── comments.html            # 评论系统扩展点
│   └── extend-footer.html       # Footer扩展点（Live2D、Chatra、Fancybox）
└── shortcodes/
    └── figure.html              # 自定义figure shortcode
```

**⚠️ 重要原则**：
- ✅ **只修改 `layouts/` 目录下的文件**
- ❌ **不要修改 `themes/congo/` 目录下的文件**
- ✅ **利用 Hugo 的模板优先级机制**

---

## 🔧 已集成的功能

### 1. 评论系统 (Utterances)
**文件位置**：`layouts/partials/comments.html`

**配置要求**：
- 在 `config/_default/params.toml` 中设置 `showComments = true`

**API 文档**：https://utteranc.es/

**当前配置**：
- 仓库：`AbnerHuang2/mywebsite`
- 主题：`gruvbox-dark`
- 匹配方式：`pathname`

**修改方法**：直接编辑 `layouts/partials/comments.html` 文件

---

### 2. Live2D 看板娘
**文件位置**：`layouts/partials/extend-footer.html`

**更多选项**：https://github.com/stevenjoezhang/live2d-widget

**当前配置**：
- 模型：nito（位于 unpkg.com）
- 位置：右下角
- 尺寸：120x300
- 偏移：水平20px

**修改模型**：编辑 `extend-footer.html` 中的 `jsonPath` 参数
```javascript
// 可选模型：
// 'https://unpkg.com/live2d-widget-model-nito@1.0.5/assets/nito.model.json'
// 'https://cdn.jsdelivr.net/npm/live2d-widget-model-koharu/assets/koharu.model.json'
// 'https://cdn.jsdelivr.net/npm/live2d-widget-model-hijiki/assets/hijiki.model.json'  // 小猫咪
```

---

### 3. Chatra 聊天系统
**文件位置**：`layouts/partials/extend-footer.html`

**当前配置**：
- ChatraID：`H8oixnws8SKYQkjBz`

**修改方法**：编辑 `extend-footer.html` 中的 `ChatraID` 参数

---

### 4. Fancybox 图片放大
**文件位置**：
- `layouts/partials/extend-footer.html`（引入JS/CSS）
- `layouts/_default/_markup/render-image.html`（图片渲染逻辑）

**功能**：点击文章中的图片可放大查看

**版本**：fancybox 3.5.7 + jQuery 3.5.1

---

### 5. 中文字数统计
**文件位置**：`config/_default/config.toml`

**配置**：`hasCJKLanguage = true`

---

## 🎯 如何添加新的自定义功能

### 方法1：使用 Footer 扩展点（推荐）
适用于需要在所有页面添加的脚本和样式

**步骤**：
1. 编辑 `layouts/partials/extend-footer.html`
2. 在文件末尾添加你的脚本
3. 保存后刷新页面即可生效

**示例：添加网易云音乐**
```html
<!-- 网易云音乐 -->
<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" 
        width="100%" height="450" 
        src="//music.163.com/outchain/player?type=0&id=7179117219&auto=1&height=430">
</iframe>
```

### 方法2：使用评论扩展点
适用于文章底部的评论系统

**步骤**：
1. 编辑 `layouts/partials/comments.html`
2. 添加你的评论系统代码
3. 确保 `config/_default/params.toml` 中 `showComments = true`

### 方法3：创建新的 Partial
适用于更复杂的自定义功能

**示例：添加头部扩展**
1. 创建 `layouts/partials/extend-head.html`
2. 添加需要在 `<head>` 中引入的代码

Congo 主题支持的扩展点：
- `extend-head.html` - 在 `</head>` 之前
- `extend-footer.html` - 在 `</body>` 之前
- `comments.html` - 文章底部评论区
- `extend-article-link.html` - 文章链接扩展

---

## ⚠️ 注意事项

1. **主题升级安全**
   - 自定义功能都在 `layouts/` 目录
   - 升级主题不会影响自定义内容
   - 使用 `git checkout v2.x.x` 升级主题版本

2. **文件优先级**
   ```
   项目 layouts/          ← 最高优先级
     ↓
   主题 themes/congo/layouts/  ← 较低优先级
   ```

3. **测试建议**
   - 修改后使用 `hugo server -D` 本地测试
   - 确认功能正常后再提交到 Git
   - 部署到生产环境前检查 GitHub Actions 构建日志

4. **性能优化**
   - 避免引入过多外部脚本
   - 考虑将第三方库下载到 `static/` 目录
   - 使用 CDN 时注意可用性

---

## 📚 参考文档

- Hugo 官方文档：https://gohugo.io/documentation/
- Congo 主题文档：https://jpanther.github.io/congo/docs/
- Hugo 模板查找顺序：https://gohugo.io/templates/lookup-order/ 