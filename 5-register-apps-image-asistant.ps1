# Register applications with AppStream Image Assistant

image-assistant.exe add-application --name Chrome `
    --display-name Chrome `
    --absolute-app-path "C:\Program Files\Google\Chrome\Application\chrome.exe"

image-assistant.exe add-application --name PowerBIDesktop `
    --display-name PowerBIDesktop `
    --absolute-app-path "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe"

image-assistant.exe add-application --name SQLServerManagementStudio `
    --display-name SQLServerManagementStudio `
    --absolute-app-path "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe"