# Scripts Documentation

## Overview

This directory contains utility scripts for running, managing, and activating the Cody2Zoho application in different environments.

## Scripts

### Application Runners

#### `run_local.py`
**Purpose**: Cross-platform local development runner
**Features**:
- Cross-platform compatibility (Windows, Linux, macOS)
- Environment validation
- Dependency checking
- Error handling
- Graceful shutdown

**Usage**:
```bash
# Direct execution
python scripts/run_local.py

# With specific Python interpreter
python3 scripts/run_local.py
```

#### `run_local.sh`
**Purpose**: Unix/Linux/macOS local runner
**Features**:
- Unix-specific environment setup
- Shell script compatibility
- Error handling
- Process management

**Usage**:
```bash
# Make executable
chmod +x scripts/run_local.sh

# Run
./scripts/run_local.sh
```

#### `run_local.bat`
**Purpose**: Windows batch local runner
**Features**:
- Windows-specific environment setup
- Batch script compatibility
- Error handling
- Process management

**Usage**:
```cmd
# Run from command prompt
scripts\run_local.bat

# Run from PowerShell
.\scripts\run_local.bat
```

### Environment Activation

#### `activate_cody2zoho.ps1`
**Purpose**: PowerShell environment activation
**Features**:
- PowerShell-specific environment setup
- Virtual environment activation
- Path configuration
- Environment variable setup

**Usage**:
```powershell
# Activate environment
.\scripts\activate_cody2zoho.ps1

# Source in current session
. .\scripts\activate_cody2zoho.ps1
```

#### `activate_cody2zoho.bat`
**Purpose**: Windows batch environment activation
**Features**:
- Batch-specific environment setup
- Virtual environment activation
- Path configuration
- Environment variable setup

**Usage**:
```cmd
# Activate environment
scripts\activate_cody2zoho.bat

# Call from other batch files
call scripts\activate_cody2zoho.bat
```

## Script Features

### Cross-Platform Compatibility

All scripts are designed to work across different operating systems:

- **Windows**: Uses `.bat` and `.ps1` scripts
- **Linux/macOS**: Uses `.sh` scripts
- **Python**: Uses `.py` scripts for universal compatibility

### Environment Management

Scripts handle environment setup automatically:

1. **Virtual Environment**: Activates Python virtual environment
2. **Path Configuration**: Sets up Python path and dependencies
3. **Environment Variables**: Loads configuration from `.env` file
4. **Dependency Checking**: Validates required packages

### Error Handling

All scripts include comprehensive error handling:

- **Dependency Validation**: Checks for required tools and packages
- **Environment Validation**: Verifies configuration and setup
- **Graceful Failure**: Provides clear error messages and exit codes
- **Recovery Options**: Suggests solutions for common issues

### Process Management

Scripts manage application processes properly:

- **Signal Handling**: Responds to SIGTERM/SIGINT signals
- **Graceful Shutdown**: Properly closes connections and saves state
- **Resource Cleanup**: Releases resources and closes files
- **Status Reporting**: Provides clear status messages

## Usage Examples

### Local Development

#### Windows PowerShell
```powershell
# Activate environment
.\scripts\activate_cody2zoho.ps1

# Run application
python scripts\run_local.py
```

#### Windows Command Prompt
```cmd
# Activate environment
scripts\activate_cody2zoho.bat

# Run application
python scripts\run_local.py
```

#### Linux/macOS
```bash
# Make scripts executable
chmod +x scripts/run_local.sh
chmod +x scripts/activate_cody2zoho.sh

# Activate environment
source scripts/activate_cody2zoho.sh

# Run application
./scripts/run_local.sh
```

### Cross-Platform Development
```bash
# Universal Python runner
python scripts/run_local.py
```

## Environment Setup

### Prerequisites

All scripts require the following prerequisites:

1. **Python 3.11+**: Installed and available in PATH
2. **Virtual Environment**: Created and activated
3. **Dependencies**: Installed via `pip install -r requirements.txt`
4. **Configuration**: `.env` file created from `env.template`

### Configuration

Scripts automatically handle configuration:

1. **Environment Variables**: Loaded from `.env` file
2. **Python Path**: Configured for proper imports
3. **Working Directory**: Set to project root
4. **Logging**: Configured for appropriate output

## Troubleshooting

### Common Issues

1. **Python Not Found**
   - Ensure Python is installed and in PATH
   - Use `python --version` to verify
   - Check virtual environment activation

2. **Import Errors**
   - Verify virtual environment is activated
   - Check `requirements.txt` installation
   - Validate Python path configuration

3. **Configuration Errors**
   - Ensure `.env` file exists and is properly formatted
   - Check environment variable values
   - Validate file paths and permissions

4. **Permission Errors**
   - Make scripts executable: `chmod +x scripts/*.sh`
   - Run with appropriate permissions
   - Check file ownership and access rights

### Debug Commands

```bash
# Check Python installation
python --version
which python

# Check virtual environment
echo $VIRTUAL_ENV
pip list

# Check configuration
cat .env
python -c "import src.config; print(src.config.settings)"

# Test script execution
python scripts/run_local.py --help
```

## Best Practices

1. **Always use virtual environments**
2. **Keep scripts executable and up-to-date**
3. **Use appropriate script for your platform**
4. **Check prerequisites before running**
5. **Handle errors gracefully**
6. **Document any customizations**

## Script Maintenance

### Adding New Scripts

When adding new scripts:

1. **Follow naming conventions**: Use descriptive names with appropriate extensions
2. **Include error handling**: Always handle errors gracefully
3. **Add documentation**: Document purpose, usage, and features
4. **Test cross-platform**: Ensure compatibility across operating systems
5. **Update this README**: Add new scripts to the documentation

### Updating Existing Scripts

When updating scripts:

1. **Maintain backward compatibility**: Don't break existing usage
2. **Update documentation**: Reflect changes in this README
3. **Test thoroughly**: Verify functionality across platforms
4. **Version control**: Use meaningful commit messages
5. **Error handling**: Ensure robust error handling

## Integration with Other Tools

### IDE Integration

Scripts can be integrated with IDEs:

- **VS Code**: Use as launch configurations
- **PyCharm**: Configure as run configurations
- **Vim/Emacs**: Use as external tools

### CI/CD Integration

Scripts can be used in CI/CD pipelines:

- **GitHub Actions**: Use in workflow steps
- **Azure DevOps**: Use in build/release pipelines
- **Jenkins**: Use in build scripts

### Docker Integration

Scripts work with Docker:

- **Development**: Use for local development
- **Testing**: Use for test environment setup
- **Debugging**: Use for container debugging
