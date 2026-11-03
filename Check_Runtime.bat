@echo off
setlocal
echo Checking Windows PowerShell and .NET Framework WPF assemblies...
powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName PresentationFramework; Add-Type -AssemblyName PresentationCore; Add-Type -AssemblyName WindowsBase; [System.Windows.Media.Imaging.BitmapSource].Assembly.Location; [System.Windows.Threading.Dispatcher].Assembly.Location; [System.Linq.Enumerable].Assembly.Location"
echo.
echo If paths are shown without errors, the WPF assemblies are available.
pause
endlocal
