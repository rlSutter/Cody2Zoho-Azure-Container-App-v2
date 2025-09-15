# Scripts Documentation

## Overview

This document provides comprehensive documentation for all utility scripts in the `scripts/` folder. These scripts handle local development, environment setup, and application execution for the Cody2Zoho project.

## Script Categories

### **Application Launch Scripts**
Scripts for running the application locally in different environments.

### **Environment Setup Scripts**
Scripts for setting up and activating the development environment.

### **Documentation Files**
Markdown files documenting script usage and fixes.

---

## Application Launch Scripts

### 1. `run_local.py` ⭐ **RECOMMENDED**
**Status**: **Current** - Main Python application launcher  
**Purpose**: Run Cody2Zoho application locally without Docker  
**Size**: 5.7KB, 181 lines  

**Key Features**:
- Environment validation and setup
- Dependency checking
- Application startup with error handling
- Health monitoring and status checking
- Graceful shutdown handling
- Cross-platform compatibility

**Prerequisites**:
- Python 3.11+
- `.env` file with proper configuration
- Redis server (optional - uses in-memory fallback)

**Usage**:
```bash
# Direct execution
python scripts/run_local.py

# With virtual environment
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate     # Windows
python scripts/run_local.py
```

**Features**:
- **Environment Validation**: Checks Python version, dependencies, and `.env` file
- **Dependency Management**: Validates required packages are installed
- **Configuration Loading**: Loads and validates environment variables
- **Health Monitoring**: Monitors application health during runtime
- **Error Handling**: Comprehensive error handling with helpful messages
- **Graceful Shutdown**: Handles Ctrl+C and system signals properly

**Error Handling**:
- Missing Python version → Clear upgrade instructions
- Missing dependencies → Installation commands
- Missing `.env` file → Setup instructions
- Invalid configuration → Validation errors
- Runtime errors → Detailed error messages

---

### 2. `run_local.sh` **CURRENT**
**Status**: **Current** - Unix/Linux shell script launcher  
**Purpose**: Shell script for running the application on Unix/Linux systems  
**Size**: 2.2KB, 75 lines  

**Key Features**:
- Virtual environment activation
- Dependency installation
- Application execution
- Error handling for Unix/Linux systems

**Usage**:
```bash
# Make executable (first time only)
chmod +x scripts/run_local.sh

# Run the application
./scripts/run_local.sh
```

**Features**:
- **Environment Detection**: Automatically detects and activates virtual environment
- **Dependency Installation**: Installs missing dependencies if needed
- **Cross-Platform**: Works on Linux, macOS, and other Unix-like systems
- **Error Handling**: Provides clear error messages for common issues

**Prerequisites**:
- Bash shell
- Python 3.11+
- Virtual environment (`.venv` folder)

---

### 3. `run_local.bat` **CURRENT**
**Status**: **Current** - Windows batch script launcher  
**Purpose**: Batch script for running the application on Windows systems  
**Size**: 1.7KB, 64 lines  

**Key Features**:
- Virtual environment activation
- Dependency installation
- Application execution
- Error handling for Windows systems

**Usage**:
```cmd
# Run the application
scripts\run_local.bat
```

**Features**:
- **Windows Compatibility**: Optimized for Windows Command Prompt
- **Environment Detection**: Automatically detects and activates virtual environment
- **Dependency Installation**: Installs missing dependencies if needed
- **Error Handling**: Provides clear error messages for Windows-specific issues

**Prerequisites**:
- Windows Command Prompt or PowerShell
- Python 3.11+
- Virtual environment (`.venv` folder)

---

## Environment Setup Scripts

### 4. `activate_cody2zoho.ps1` **CURRENT**
**Status**: **Current** - PowerShell environment activator  
**Purpose**: PowerShell script to activate the virtual environment  
**Size**: 790B, 18 lines  

**Key Features**:
- Virtual environment detection
- PowerShell-compatible activation
- Error reporting and handling

**Usage**:
```powershell
# Activate virtual environment
.\scripts\activate_cody2zoho.ps1

# Or with execution policy bypass
powershell -ExecutionPolicy Bypass -File scripts\activate_cody2zoho.ps1
```

**Features**:
- **Environment Detection**: Automatically finds the `.venv` folder
- **PowerShell Integration**: Uses PowerShell-specific activation commands
- **Error Handling**: Reports activation failures clearly
- **Cross-Platform**: Works on Windows PowerShell and PowerShell Core

**Prerequisites**:
- PowerShell 5.1+ or PowerShell Core
- Virtual environment (`.venv` folder)

---

### 5. `activate_cody2zoho.bat` **CURRENT**
**Status**: **Current** - Windows batch environment activator  
**Purpose**: Batch script to activate the virtual environment on Windows  
**Size**: 596B, 18 lines  

**Key Features**:
- Virtual environment detection
- Windows Command Prompt compatibility
- Error reporting and handling

**Usage**:
```cmd
# Activate virtual environment
scripts\activate_cody2zoho.bat
```

**Features**:
- **Environment Detection**: Automatically finds the `.venv` folder
- **Windows Integration**: Uses Windows-specific activation commands
- **Error Handling**: Reports activation failures clearly
- **Command Prompt Compatible**: Works with Windows Command Prompt

**Prerequisites**:
- Windows Command Prompt
- Virtual environment (`.venv` folder)

---

## 📝 Documentation Files

### 6. `README.md` **CURRENT**
**Status**: **Current** - Scripts overview documentation  
**Purpose**: Comprehensive guide for all scripts in the folder  
**Size**: 3.6KB, 152 lines  

**Content**:
- Scripts index and categorization
- Usage guide for different platforms
- Detailed script descriptions
- Prerequisites and requirements
- Troubleshooting information

**Key Sections**:
- **Scripts Index**: Complete list of all scripts with descriptions
- **Usage Guide**: Platform-specific usage instructions
- **Script Descriptions**: Detailed information about each script
- **Requirements**: Prerequisites and dependencies
- **Troubleshooting**: Common issues and solutions

---

### 7. `RUN_SCRIPTS_FIXES.md` **CURRENT**
**Status**: **Current** - Script fixes documentation  
**Purpose**: Document fixes and improvements made to scripts  
**Size**: 5.6KB, 191 lines  

**Content**:
- Script fixes and improvements
- Bug resolution documentation
- Enhancement history
- Migration guidance

**Key Sections**:
- **Fix History**: Chronological list of fixes applied
- **Bug Resolution**: Detailed bug descriptions and solutions
- **Enhancements**: New features and improvements
- **Migration Notes**: Changes that affect existing usage

---

## 🎯 **Recommended Usage Patterns**

### **For Development (Recommended)**:
```bash
# 1. Activate virtual environment
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate     # Windows

# 2. Run application
python scripts/run_local.py
```

### **For Quick Testing**:
```bash
# Unix/Linux/Mac
./scripts/run_local.sh

# Windows
scripts\run_local.bat
```

### **For PowerShell Users**:
```powershell
# Activate environment
.\scripts\activate_cody2zoho.ps1

# Run application
python scripts\run_local.py
```

### **For Command Prompt Users**:
```cmd
# Activate environment
scripts\activate_cody2zoho.bat

# Run application
python scripts\run_local.py
```

## **Script Requirements**

### **Prerequisites**:
- **Python**: 3.11 or higher
- **Virtual Environment**: `.venv` folder with dependencies installed
- **Dependencies**: All packages from `requirements.txt`
- **Configuration**: Valid `.env` file with required variables

### **Required Environment Variables**:
```bash
# Cody API Configuration
CODY_API_KEY=your_cody_api_key
CODY_API_URL=https://getcody.ai/api/v1

# Zoho API Configuration
ZOHO_ACCESS_TOKEN=your_access_token
ZOHO_REFRESH_TOKEN=your_refresh_token
ZOHO_CLIENT_ID=your_client_id
ZOHO_CLIENT_SECRET=your_client_secret

# Optional Configuration
REDIS_URL=redis://localhost:6379/0  # Optional
ENABLE_GRAYLOG=false                 # Optional
```

## **Common Issues and Solutions**

### **Issue: Python Version Too Old**
```bash
# Error: Python 3.11 or higher is required
# Solution: Upgrade Python
# Windows: Download from python.org
# Linux/Mac: Use pyenv or system package manager
```

### **Issue: Missing Dependencies**
```bash
# Error: Missing required packages
# Solution: Install dependencies
pip install -r requirements.txt
```

### **Issue: Missing .env File**
```bash
# Error: .env file not found
# Solution: Create .env file
cp env.template .env
# Then edit .env with your configuration
```

### **Issue: Virtual Environment Not Found**
```bash
# Error: Virtual environment not found
# Solution: Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate     # Windows
pip install -r requirements.txt
```

### **Issue: Permission Denied (Unix/Linux)**
```bash
# Error: Permission denied when running .sh script
# Solution: Make script executable
chmod +x scripts/run_local.sh
```

### **Issue: Execution Policy (PowerShell)**
```powershell
# Error: Execution policy prevents running scripts
# Solution: Bypass execution policy
powershell -ExecutionPolicy Bypass -File scripts\activate_cody2zoho.ps1
```

## **Script Comparison**

| Script | Platform | Features | Complexity | Recommendation |
|--------|----------|----------|------------|----------------|
| `run_local.py` | All | Full validation, error handling | High | ⭐ **Best** |
| `run_local.sh` | Unix/Linux | Quick execution | Medium | **Good** |
| `run_local.bat` | Windows | Quick execution | Medium | **Good** |
| `activate_cody2zoho.ps1` | PowerShell | Environment activation | Low | **Good** |
| `activate_cody2zoho.bat` | Windows | Environment activation | Low | **Good** |

## **Migration and Updates**

### **Recent Changes**:
- Enhanced error handling in `run_local.py`
- Improved environment detection
- Better cross-platform compatibility
- Added health monitoring features

### **Future Improvements**:
- Automated dependency installation
- Configuration validation enhancements
- Performance monitoring integration
- Docker development environment support

## **Notes**

- All scripts are current and actively maintained
- `run_local.py` is the most comprehensive and recommended option
- Shell scripts provide quick execution for experienced users
- Environment activation scripts are optional but helpful
- Documentation files provide valuable context and troubleshooting

---

*Last Updated: January 2025*
*Script Count: 7 total (all current)*
