---
title: "Python 实现的 HTTP 报文头回声服务"
url: https://liam.page/2018/05/29/Python-HTTP-header-echo-service/
date: 2018-05-29
categories: ["Algorithm and Computer Science"]
tags: ["Python", "HTTP", "Headers"]
---

[前作](/2018/05/29/Fuse-QRCodes-together-Alipay-WeChat-and-QQ-wallet/)实现了收款码多合一的功能，这是基于我们能够正确识别不同 App 的不同 UserAgent 特征字段之上的。前作没有解说我们是如何获取相应 UA 的。通过嗅探抓包当然是一个解决方案，在计算机上运行模拟器也可行。但这些方法都太重量级了。

本文用 Python 实现一个简单的 HTTP 报文头回声服务；这个服务什么也不干，就只是把发向服务的请求中的 HTTP 报文头返回。

## Python 代码

代码位于 [GitHub Repository](https://github.com/Liam0205/Tools/blob/master/Python/HTTP_header_echo_server.py)。核心功能实现在 RequestHandler 类的 do_GET 方法中。该方法将受到的 HTTP 请求的报文头写入响应正文，而后打印在本地标准输出上。此外，HTTP 中其它三种请求方法的处理与 GET 完全相同。可谓一目了然。

实际我们只需执行 python HTTP_header_echo_service.py 即可在 8080 端口运行服务。

```python
#!/usr/bin/env python
# Reflects the requests from HTTP methods GET, POST, PUT, and DELETE
# Author: Liam Huang (Yuuki) <liamhuang0205@gmail.com>

try:
    from http.server import HTTPServer, BaseHTTPRequestHandler
except:
    from BaseHTTPServer import HTTPServer, BaseHTTPRequestHandler
from optparse import OptionParser
import json

class RequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        request_path = self.path

        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        json_string = json.dumps(dict(self.headers))
        self.wfile.write(json_string)

        print('%sBegin of Headers%s' % ('-' * 5, '-' * 5))
        for k, v in self.headers.items():
            print('%s: %s' % (k, v))
        print('%sEnd of Headers%s' % ('-' * 5, '-' * 5))

        return None

    do_POST   = do_GET
    do_PUT    = do_GET
    do_DELETE = do_GET

def main():
    port = 8080
    print('Listening on all interfaces:%s' % port)
    server = HTTPServer(('', port), RequestHandler)
    server.serve_forever()

if __name__ == "__main__":
    parser = OptionParser()
    parser.usage = ("Creates an HTTP-header-echo-server.")
    (options, args) = parser.parse_args()
    main()
```

## 实际运行看看

执行 python HTTP_header_echo_service.py 后，服务会监听本机 8080 端口。在浏览器中访问 http://localhost:8080 得到返回结果：

```json
{
    "accept-language": "zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4",
    "accept-encoding": "gzip, deflate",
    "host": "localhost:8080",
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
    "user-agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36",
    "dnt": "1",
    "connection": "keep-alive",
    "cookie": "cna=k8yHEPvog1oCAdoedAmhk3yz; l=AoGB/bWp8ixmk2ng-8I0OpNAEcebrvWg; __guid=242983815.4140311236197044700.1504064960140.7058; HULK_TD=t%3D1511410881%26s%3D2cb9fedc6e59ac22bbc416f796970add%26a%3D1; HULK_QD=u%3Duhnatpurapurat%26m%3Duhnatpurapurat%2540360.pa%26d%3D%25E9%25BB%2584%25E6%2599%25A8%25E6%2588%2590; TD=t%3D1511410881%26s%3Da97b7edff5f3e6e7a0920ae7ee326d88%26a%3D1; QD=u%3Duhnatpurapurat%26m%3Duhnatpurapurat%2540360.pa; Prif_66de_st_t=0%7C1522123196%7C06e665a5949159cee56367609a66caaf; Prif_66de_auth=ec018ze%2FGmPt4LA3C3BcDLxQ4Pov3O1HlZIv0EnN%2BBthlGx4IKvidZKtxA; Prif_66de_smile=1D1; Prif_66de_lip=10.18.120.109%2C1522123532; Prif_66de_ulastactivity=9b2dELqg1p%2F6AAzSO8dz8XylvfWBBj748PyquvcqvdLlGncXc5Dy; Prif_66de_saltkey=kRuuho96; Prif_66de_lastvisit=1526726055; Prif_66de_st_p=0%7C1527160289%7C7bae096d1c2d9c2271f9ad539cafc6e4; Prif_66de_visitedfid=106; Prif_66de_viewid=tid_30518",
    "upgrade-insecure-requests": "1"
}
```

以内网 IP 192.168.0.101 生成二维码，用微信扫描后，访问得到结果中可见微信的特征字段：「MicroMessenger」。

```json
{
    "accept-language": "zh-cn",
    "accept-encoding": "gzip, deflate",
    "connection": "keep-alive",
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "user-agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E302 MicroMessenger/6.6.6 NetType/WIFI Language/zh_CN",
    "host": "192.168.0.101:8080",
    "upgrade-insecure-requests": "1"
}
```

以上。