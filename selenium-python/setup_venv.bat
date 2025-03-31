@echo off
echo Creating virtual environment...

:: Create the virtual environments directory if it doesn't exist
if not exist "C:\virtualenvironments" mkdir "C:\virtualenvironments"

:: Set default venv name
set "venv_name=db_scraper_venv"
set "venv_path=C:\virtualenvironments\%venv_name%"

:: Check if venv already exists
:check_venv
if exist "%venv_path%" (
    echo Virtual environment "%venv_name%" already exists!
    set /p "venv_name=Please enter a different name for the virtual environment: "
    set "venv_path=C:\virtualenvironments\%venv_name%"
    goto check_venv
)

:: Create a new virtual environment
echo Creating new virtual environment "%venv_name%"...
python -m venv "%venv_path%"

:: Activate the virtual environment
call "%venv_path%\Scripts\activate.bat"

:: Upgrade pip
python -m pip install --upgrade pip

:: Install requirements
pip install -r requirements.txt

echo Virtual environment setup complete!
echo To activate the virtual environment, run:
echo %venv_path%\Scripts\activate.bat 