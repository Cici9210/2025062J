"""
更新 devices 表結構 - 添加缺少的欄位
"""
import mysql.connector
from mysql.connector import Error

def update_devices_table():
    try:
        # 連接到資料庫
        connection = mysql.connector.connect(
            host='localhost',
            database='heartbeat_db',
            user='root',
            password='10856045'
        )
        
        if connection.is_connected():
            cursor = connection.cursor()
            print("成功連接到 MySQL 資料庫")
            
            # 檢查並添加 name 欄位
            try:
                cursor.execute("""
                    ALTER TABLE devices 
                    ADD COLUMN name VARCHAR(100) DEFAULT '未命名裝置'
                """)
                print("✓ 已添加 devices.name 欄位")
            except Error as e:
                if "Duplicate column name" in str(e):
                    print("  devices.name 欄位已存在")
                else:
                    print(f"  添加 name 欄位時出錯: {e}")
            
            # 檢查並添加 is_online 欄位
            try:
                cursor.execute("""
                    ALTER TABLE devices 
                    ADD COLUMN is_online BOOLEAN DEFAULT 0
                """)
                print("✓ 已添加 devices.is_online 欄位")
            except Error as e:
                if "Duplicate column name" in str(e):
                    print("  devices.is_online 欄位已存在")
                else:
                    print(f"  添加 is_online 欄位時出錯: {e}")
            
            # 檢查並添加 last_active 欄位
            try:
                cursor.execute("""
                    ALTER TABLE devices 
                    ADD COLUMN last_active TIMESTAMP NULL DEFAULT NULL
                """)
                print("✓ 已添加 devices.last_active 欄位")
            except Error as e:
                if "Duplicate column name" in str(e):
                    print("  devices.last_active 欄位已存在")
                else:
                    print(f"  添加 last_active 欄位時出錯: {e}")
            
            # 檢查並添加 created_at 欄位
            try:
                cursor.execute("""
                    ALTER TABLE devices 
                    ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                """)
                print("✓ 已添加 devices.created_at 欄位")
            except Error as e:
                if "Duplicate column name" in str(e):
                    print("  devices.created_at 欄位已存在")
                else:
                    print(f"  添加 created_at 欄位時出錯: {e}")
            
            connection.commit()
            print("\n資料庫更新完成!")
            
            # 顯示當前 devices 表結構
            cursor.execute("DESCRIBE devices")
            print("\n當前 devices 表結構:")
            for row in cursor.fetchall():
                print(f"  {row[0]}: {row[1]}")
            
    except Error as e:
        print(f"錯誤: {e}")
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("\nMySQL 連接已關閉")

if __name__ == "__main__":
    update_devices_table()
