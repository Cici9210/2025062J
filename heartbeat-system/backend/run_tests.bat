@echo off
echo 運行心臟壓感互動系統後端測試...

REM 確保虛擬環境已啟用（如果使用虛擬環境）
REM 如果需要啟用虛擬環境，請取消下一行的註釋
REM call venv\Scripts\activate

REM 安裝測試依賴項（如果尚未安裝）
pip install -r requirements.txt

REM 運行測試
pytest -xvs tests/

echo 測試完成！