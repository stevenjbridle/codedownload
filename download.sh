#!/bin/bash

# Define download URLs and output file names for each software

# SQL Server Management Studio (SSMS)
SSMS_DOWNLOAD_URL="https://aka.ms/ssmsfullsetup"
SSMS_OUTPUT_FILE="SSMS-Setup-ENU.exe"

# Power BI Desktop
# Microsoft provides different download options for Power BI Desktop.
# The 'aka.ms/pbiadb' link usually points to the 64-bit installer directly.
PBI_DOWNLOAD_URL="https://aka.ms/pbiadb"
PBI_OUTPUT_FILE="PowerBI_Desktop_Setup.exe"

# Google Chrome (for Windows)
# This link is for the stable 64-bit standalone installer for Windows.
CHROME_DOWNLOAD_URL="https://dl.google.com/chrome/install/standalonesetup64.exe"
CHROME_OUTPUT_FILE="GoogleChromeStandaloneEnterprise64.exe"

echo "Starting download process for multiple software installers..."
echo "---------------------------------------------------------"

# Function to download a file
download_file() {
    local url="$1"
    local output_file="$2"
    local software_name="$3"

    echo "Attempting to download $software_name installer..."
    echo "  Download URL: $url"
    echo "  Output file: $output_file"

    curl -L "$url" -o "$output_file"

    if [ $? -eq 0 ]; then
        echo "  $software_name download completed successfully!"
        echo "  File saved as: $output_file"
    else
        echo "  Error: Failed to download $software_name installer."
        echo "  Please check your internet connection and the download URL."
    fi
    echo "" # Add a newline for better readability between downloads
}

# Download SSMS
download_file "$SSMS_DOWNLOAD_URL" "$SSMS_OUTPUT_FILE" "SQL Server Management Studio (SSMS)"

# Download Power BI Desktop
download_file "$PBI_DOWNLOAD_URL" "$PBI_OUTPUT_FILE" "Power BI Desktop"

# Download Google Chrome
download_file "$CHROME_DOWNLOAD_URL" "$CHROME_OUTPUT_FILE" "Google Chrome"

echo "---------------------------------------------------------"
echo "All download attempts completed."
echo "Remember: These are Windows executable files (.exe) and are intended for installation on a Windows operating system."
echo "You can now transfer these files to a Windows machine and run them to install the software."