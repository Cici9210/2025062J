-- 更新 devices 表結構
ALTER TABLE devices ADD COLUMN IF NOT EXISTS name VARCHAR(100) DEFAULT 'Unnamed Device';
ALTER TABLE devices ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_active TIMESTAMP NULL;

-- 創建 pressure_data 表
CREATE TABLE IF NOT EXISTS pressure_data (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    device_id INTEGER NOT NULL,
    pressure_value FLOAT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
);

-- 創建 pairing_queue 表
CREATE TABLE IF NOT EXISTS pairing_queue (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

SELECT 'Database schema updated successfully' AS message;
