@echo off
echo Stopping Redis container for Cody2Zoho development...
echo.

REM Stop Redis container
echo Stopping Redis container...
docker-compose -f docker-compose.dev.yml down

if %errorlevel% equ 0 (
    echo.
    echo Redis container stopped successfully!
    echo.
) else (
    echo.
    echo WARNING: There was an issue stopping the Redis container.
    echo You may need to stop it manually in Docker Desktop.
    echo.
)

pause
