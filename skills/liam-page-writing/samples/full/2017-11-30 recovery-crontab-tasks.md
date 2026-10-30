---
title: "crontab 任务误删恢复"
url: https://liam.page/2017/11/30/recovery-crontab-tasks/
date: 2017-11-30
categories: ["Computer Skills"]
tags: ["Crontab", "Recovery"]
---

这是一篇简短的记录。

某台服务器某账号的 crontab 任务被清空，原因不明。同时，该服务器上的 crontab 任务备份未开启。故思考如何恢复 crontab 任务。

经查，CentOS 系统的 crontab 任务的日志，打印在 /var/log/cron 之中。考虑过滤日志：

```bash
cat /var/log/cron* | grep CMD | awk -F'CMD' '{print $2}' | awk -F'[(|)]' '{print $2}' | sort -u
```

由此得到系统记录过的 crontab 执行命令，过滤其他账号的命令后即可追回目标账号的 crontab 任务。

此外，考虑备份 crontab；脚本如下：

```bash
#!/usr/bin/env bash

BACKUP_DIRECTORY="${HOME}/crontab_backup"

if [ ! -e "${BACKUP_DIRECTORY}" ]; then
        mkdir -p ${BACKUP_DIRECTORY}
fi

crontab -l > ${BACKUP_DIRECTORY}/$(date '+%Y%m%d').txt
```