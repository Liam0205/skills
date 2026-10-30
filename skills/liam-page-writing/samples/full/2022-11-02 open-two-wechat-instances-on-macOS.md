---
title: "在 macOS 上双开微信"
url: https://liam.page/2022/11/02/open-two-wechat-instances-on-macOS/
date: 2022-11-02
categories: ["Computer Skills"]
tags: ["WeChat", "macOS"]
---

特点：

- 不安装第三方插件，无封号之虞。

- 双击即可启动。

- 启动后不需要维持「终端」；事实上它会自动关闭。

解法：

- 打开终端，执行下列代码，而后在桌面双击 WeChat.command 即可。

```shell
# 将启动命令写入桌面上的文件 WeChat.command；如果已有重名文件，请注意修改。
echo "nohup /Applications/WeChat.app/Contents/MacOS/WeChat >/dev/null 2>&1 &" > ~/Desktop/WeChat.command

# 赋予其可执行属性
chmod +x ~/Desktop/WeChat.command
```