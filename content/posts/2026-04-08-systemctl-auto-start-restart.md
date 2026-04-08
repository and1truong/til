---
date: '2026-04-08T00:00:00+10:00'
draft: false
title: 'systemctl can auto-start and restart services'
tags: ['linux']
---

Create a `.service` file, then symlink it into systemd:

```bash
sudo ln -s /path/to/myservice.service /etc/systemd/system/myservice.service
sudo systemctl daemon-reload
sudo systemctl enable myservice   # auto-start on boot
sudo systemctl start myservice    # start now
```

After editing the service file, reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart myservice
```
