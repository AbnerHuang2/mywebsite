# hugo
    版本    0.123.8
# 主题
    "name": "hugo-congo-theme",
    "version": "2.8.1"
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


# 评论系统 utterances
在theme/congo/layouts/partials/sharing-links.html 添加了一段脚本（api：https://utteranc.es/）
```javascript
<script src="https://utteranc.es/client.js"
        repo="AbnerHuang2/mywebsite"
        issue-term="pathname"
        theme="gruvbox-dark"
        crossorigin="anonymous"
        async>
</script>
```


# 看板娘 live2d
在theme/congo/layouts/partials/footer.html 添加了一段脚本
更多选项 ： https://github.com/stevenjoezhang/live2d-widget
```javascript
//live2d
<!-- Live2D，网页上的小人，可以修改live2d_config.js来修改模型，模型都在static/live2d_models里面 -->
<!-- 你也可以把js文件下载下来，放到static/js/目录下，就不依赖别人的服务了 -->
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/live2d-widget@3.1.4/lib/L2Dwidget.min.js"></script>
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/live2d-widget@3.1.4/lib/L2Dwidget.0.min.js"></script>

<script type="text/javascript">
    L2Dwidget.init({
        model: {
            scale: 1,
            hHeadPos: 0.5,
            vHeadPos: 0.618,
            jsonPath: 'https://cdn.jsdelivr.net/npm/live2d-widget-model-koharu/assets/koharu.model.json',       // xxx.model.json 的路径,换人物修改这个
            //'https://cdn.jsdelivr.net/npm/live2d-widget-model-hijiki/assets/hijiki.model.json' 小猫咪
        },
        display: {
            superSample: 1,     // 超采样等级
            width: 120,         // canvas的宽度
            height: 300,        // canvas的高度
            position: 'right',   // 显示位置：左或右
            hOffset: 0,         // canvas水平偏移
            vOffset: 0,         // canvas垂直偏移
        },
        mobile: {
            show: true,         // 是否在移动设备上显示
            scale: 1,           // 移动设备上的缩放
            motion: true,       // 移动设备是否开启重力感应
        },
        react: {
            opacityDefault: 0.8,  // 默认透明度
            opacityOnHover: 1,  // 鼠标移上透明度
        },
     });
</script>
```

# 聊天 chatra
footer.html添加脚本

```javascript
<script>
    (function(d, w, c) {
        w.ChatraID = 'your ChatraID'; //配置你自己的chatraID
        var s = d.createElement('script');
        w[c] = w[c] || function() {
            (w[c].q = w[c].q || []).push(arguments);
        };
        s.async = true;
        s.src = 'https://call.chatra.io/chatra.js';
        if (d.head) d.head.appendChild(s);
    })(document, window, 'Chatra');
</script>
```

# 网易云音乐
找个合适的页面添加iframe
```javascript
<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=100% height=450 src="//music.163.com/outchain/player?type=0&id=7179117219&auto=1&height=430"></iframe>
```

# 图片放大
footer.html增加 
```javascript
<script src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.min.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/fancyapps/fancybox@3.5.7/dist/jquery.fancybox.min.css" />
<script src="https://cdn.jsdelivr.net/gh/fancyapps/fancybox@3.5.7/dist/jquery.fancybox.min.js"></script>
```

render-image.html 对所有的img标签加上 下面这段代码
```javascript
<div class="post-img-view">
    <a data-fancybox="gallery" href="{{ .Destination | safeURL }}">
        <!-- img 标签 -->
    </a>
</div>
```

# 修复中文字数显示问题
config.toml 文件languages配置下面添加 hasCJKLanguage = true 