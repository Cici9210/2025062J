"""
資料庫建立腳本 (setup_db.sql)
功能: 建立MySQL資料庫和所需表格
執行方式: mysql -u [使用者名稱] -p < setup_db.sql
"""
-- 創建資料庫
CREATE DATABASE IF NOT EXISTS heartbeat_db;
USE heartbeat_db;

-- 創建使用者表
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 創建裝置表
CREATE TABLE IF NOT EXISTS devices (
    id INT PRIMARY KEY AUTO_INCREMENT,
    device_uid VARCHAR(64) UNIQUE NOT NULL,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 創建互動記錄表
CREATE TABLE IF NOT EXISTS interactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    pressure_level FLOAT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 創建心跳日誌表
CREATE TABLE IF NOT EXISTS heartbeat_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    device_id INT,
    bpm INT,
    temperature FLOAT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id)
);

-- 創建配對關係表
CREATE TABLE IF NOT EXISTS pairings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id_1 INT,
    user_id_2 INT,
    status VARCHAR(20) NOT NULL, -- "pending", "active", "rejected"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id_1) REFERENCES users(id),
    FOREIGN KEY (user_id_2) REFERENCES users(id)
);

-- 創建好友關係表
CREATE TABLE IF NOT EXISTS friendships (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id_1 INT,
    user_id_2 INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id_1) REFERENCES users(id),
    FOREIGN KEY (user_id_2) REFERENCES users(id)
);
