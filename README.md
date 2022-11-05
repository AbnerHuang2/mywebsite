# 使用
1. git clone项目到本地， 后面记得增加参数 --recurse-submodules ，用于初始化子模块（git clone git@github.com:AbnerHuang2/mywebsite.git --recurse-submodules）
2. git checkout master (master才是工作分支， gh-pages是部署分支)
2. hugo server -D
3. 写博客 hugo new posts/your-post-name.md
4. 部署 git 推送代码即可（git add . & git commit & git push）
# 工作机制
1. git push到master之后，会触发github actions构建部署静态页面到gh-pages分支
2. gh-pages分支被更新后，会触发vercel的hook，重新构建部署到vercel上。