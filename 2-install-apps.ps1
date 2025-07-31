# Install specific versions (for update testing)
choco install googlechrome -y
choco install powerbi --version=2.141.1754.0 -y
choco install sql-server-management-studio --version=20.1.10 -y

# OR install latest versions (uncomment if preferred)
# choco install googlechrome -y
# choco install powerbi -y
# choco install sql-server-management-studio -y

# Verify installed versions
choco list