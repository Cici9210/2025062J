"""
代理服務器 (proxy.py)
功能: 為前端提供服務並轉發API請求到後端
相依: Python 3 (http.server, urllib.request)
"""

from http.server import HTTPServer, SimpleHTTPRequestHandler
import urllib.request
import urllib.error
import os
import sys
import json

# 後端API的基礎URL
BACKEND_URL = "http://127.0.0.1:8000"

class ProxyHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        # 如果路徑以/api開頭，轉發請求到後端
        if self.path.startswith('/api/'):
            self.proxy_request('GET')
        else:
            # 否則服務靜態文件
            return SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self):
        # 如果路徑以/api開頭，轉發請求到後端
        if self.path.startswith('/api/'):
            self.proxy_request('POST')
        else:
            self.send_error(404, "File not found")

    def proxy_request(self, method):
        # 從請求中獲取內容長度
        content_length = int(self.headers.get('Content-Length', 0))
        # 讀取請求體
        post_data = self.rfile.read(content_length) if content_length > 0 else None
        
        # 構建到後端的URL
        url = f"{BACKEND_URL}{self.path}"
        print(f"轉發{method}請求到: {url}")
        
        # 創建請求
        req = urllib.request.Request(url, data=post_data, method=method)
        
        # 從原始請求複製頭部信息
        for header_name, header_value in self.headers.items():
            if header_name.lower() in ('content-length', 'host'):
                continue
            req.add_header(header_name, header_value)
        
        try:
            # 發送請求到後端
            with urllib.request.urlopen(req) as response:
                # 設置響應狀態碼
                self.send_response(response.status)
                
                # 複製響應頭部信息
                for header_name, header_value in response.getheaders():
                    if header_name.lower() == 'transfer-encoding':
                        continue
                    self.send_header(header_name, header_value)
                
                # 添加CORS頭部
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                
                # 發送響應體
                response_body = response.read()
                self.wfile.write(response_body)
        except urllib.error.HTTPError as e:
            # 處理HTTP錯誤
            self.send_response(e.code)
            for header_name, header_value in e.headers.items():
                if header_name.lower() == 'transfer-encoding':
                    continue
                self.send_header(header_name, header_value)
            
            # 添加CORS頭部
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            # 發送錯誤響應體
            self.wfile.write(e.read())
        except Exception as e:
            # 處理其他錯誤
            self.send_error(500, f"代理請求錯誤: {str(e)}")

    def do_OPTIONS(self):
        # 處理預檢請求
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()


def run_server(port=8080, directory="build/web"):
    # 切換到指定目錄
    os.chdir(directory)
    
    # 創建服務器
    server_address = ('', port)
    httpd = HTTPServer(server_address, ProxyHandler)
    
    print(f"啟動代理服務器在端口 {port}...")
    httpd.serve_forever()


if __name__ == "__main__":
    # 獲取命令行參數
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    directory = sys.argv[2] if len(sys.argv) > 2 else "build/web"
    
    run_server(port, directory)
