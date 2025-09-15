@echo off
REM Cody2Zoho Custom Activation Script (Batch Version)
REM This script activates the virtual environment and changes to the correct directory

REM Change to the Cody2Zoho directory
cd /d "{cody direction}"

REM Activate the virtual environment
call .venv\Scripts\activate.bat

REM Display success message
echo Virtual environment activated and changed to Cody2Zoho directory
echo Current directory: %CD%
echo Python environment: %VIRTUAL_ENV%

REM Keep the command prompt open
cmd /k
