"""
創建 MySQL 資料庫的腳本
"""
import mysql.connector
import time

try:
    # 連接到 MySQL (不指定資料庫)    print("嘗試連接到 MySQL...")
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password=""
    )

    cursor = connection.cursor()

    # 創建資料庫
    print("創建資料庫...")
    cursor.execute("CREATE DATABASE IF NOT EXISTS heartbeat_db")

    print("資料庫 'heartbeat_db' 已創建或已存在")

    # 關閉連接
    cursor.close()
    connection.close()
    
except Exception as e:
    print(f"發生錯誤: {e}")

# 等待幾秒鐘，這樣我們可以看到輸出
print("腳本執行完畢，5秒後關閉...")
time.sleep(5)
