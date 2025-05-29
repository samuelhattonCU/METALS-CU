@echo off
echo [Setup] Starting environment setup...

where python
IF %ERRORLEVEL% NEQ 0 (
    echo [Error] Python not found. Please install Python 3.8+ and try again.
    exit /b 1
)

REM Create virtual environment
python -m venv venv
call venv\Scripts\activate

REM Upgrade pip
python -m pip install --upgrade pip

REM Install requirements
pip install -r requirements.txt

echo [Setup] Done! Activate with: venv\Scripts\activate
