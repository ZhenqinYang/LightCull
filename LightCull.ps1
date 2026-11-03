# LightCull / 轻选 v0.2.7
# Windows 10/11, Windows PowerShell 5.1, no third-party dependencies.
# Deliberately never permanently deletes files: all deletion goes to Recycle Bin.
param([string]$InitialFolder = '')

# UI language preference is stored outside the photo folder; no images are modified.
$script:SettingsPath = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'LightCull\settings.json'
$script:Language = 'zh'
try {
  if ([IO.File]::Exists($script:SettingsPath)) {
    $prefs = [IO.File]::ReadAllText($script:SettingsPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($prefs.language -eq 'en') { $script:Language = 'en' }
  }
} catch { $script:Language = 'zh' }
. (Join-Path $PSScriptRoot 'LightCull.I18n.ps1')

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic
# C# code runs the JPEG-header metadata scan and bitmap decoding on background threads.
# No .NET SDK / Python / third-party packages are required by the user.
$helperSource = Join-Path $PSScriptRoot 'LightCull.Core.cs'
# Windows PowerShell 5.1's C# compiler does not consistently resolve short WPF
# assembly filenames (e.g. PresentationCore.dll). Reference the *actual loaded*
# .NET Framework assembly locations instead. These are local framework files,
# so no DLL downloads, .NET SDK, or administrator rights are needed.
$referencePaths = @(
  [System.Object].Assembly.Location
  [System.ComponentModel.INotifyPropertyChanged].Assembly.Location
  [System.Linq.Enumerable].Assembly.Location
  [System.Windows.Media.Imaging.BitmapSource].Assembly.Location
  [System.Windows.Threading.Dispatcher].Assembly.Location
  [System.Windows.Markup.XamlReader].Assembly.Location
  [System.Xaml.XamlServices].Assembly.Location
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
if (-not (Test-Path -LiteralPath $helperSource -PathType Leaf)) {
  throw (TF 'helperMissing' @($helperSource))
}
foreach ($referencePath in $referencePaths) {
  if (-not (Test-Path -LiteralPath $referencePath -PathType Leaf)) {
    throw (TF 'frameworkMissing' @($referencePath))
  }
}
Add-Type -Path $helperSource -ReferencedAssemblies ([string[]]$referencePaths) -ErrorAction Stop

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="轻选 LightCull · JPG / RAW 联动选片" Width="1420" Height="850"
        MinWidth="1050" MinHeight="670" WindowStartupLocation="CenterScreen"
        Background="#10141C" Foreground="#E7ECF4" FontFamily="Microsoft YaHei UI" FontSize="13">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Background" Value="#293344"/>
      <Setter Property="Foreground" Value="#F4F6FA"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding" Value="13,8"/>
      <Setter Property="Margin" Value="0,0,8,0"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
    <Style TargetType="ComboBox">
      <Setter Property="Background" Value="#E8EDF7"/>
      <Setter Property="Foreground" Value="#162031"/>
      <Setter Property="Height" Value="32"/>
      <Setter Property="Margin" Value="0,0,9,0"/>
    </Style>
    <Style TargetType="ListBox">
      <Setter Property="Background" Value="#171D28"/>
      <Setter Property="Foreground" Value="#E7ECF4"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Disabled"/>
    </Style>
    <Style TargetType="TextBox">
      <Setter Property="Background" Value="#E8EDF7"/>
      <Setter Property="Foreground" Value="#162031"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding" Value="6,5"/>
    </Style>
  </Window.Resources>

  <Grid Margin="16">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <DockPanel Grid.Row="0" Margin="0,0,0,14" LastChildFill="True">
      <StackPanel DockPanel.Dock="Left" Orientation="Horizontal" VerticalAlignment="Center">
        <TextBlock x:Name="AppBrandLabel" Text="轻选" FontSize="25" FontWeight="Bold" Foreground="#93C5FD" VerticalAlignment="Center" Margin="0,0,14,0"/>
        <Button x:Name="OpenFolderButton" Content="打开照片文件夹" Background="#2563EB" FontWeight="Bold"/>
        <Button x:Name="ReloadButton" Content="重新扫描"/>
        <Button x:Name="RetryDriveButton" Content="硬盘恢复后重试预览" IsEnabled="False" Background="#7C4A12"/>
      </StackPanel>
      <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center" Margin="12,0,0,0">
        <TextBlock x:Name="LanguageLabel" Text="语言" VerticalAlignment="Center" Margin="0,0,7,0" Foreground="#A8B6CA"/>
        <ComboBox x:Name="LanguageBox" Width="112" SelectedIndex="0" Margin="0">
          <ComboBoxItem Tag="zh" Content="简体中文"/>
          <ComboBoxItem Tag="en" Content="English"/>
        </ComboBox>
      </StackPanel>
      <TextBlock x:Name="FolderLabel" Text="尚未打开文件夹" Foreground="#A7B5CA"
                 VerticalAlignment="Center" TextTrimming="CharacterEllipsis" Margin="6,0,0,0"/>
    </DockPanel>

    <Border Grid.Row="1" Background="#1A2230" CornerRadius="7" Padding="11" Margin="0,0,0,12">
      <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
        <TextBlock x:Name="BrowseLabel" Text="浏览方式" VerticalAlignment="Center" Margin="0,0,7,0"/>
        <ComboBox x:Name="ModeBox" Width="205" SelectedIndex="0">
          <ComboBoxItem Content="全部照片（按文件名）"/>
          <ComboBoxItem Content="连拍分组（按时间）"/>
          <ComboBoxItem Content="相近画面（实验性）"/>
        </ComboBox>
        <TextBlock x:Name="MaxGapLabel" Text="最大间隔" VerticalAlignment="Center" Margin="2,0,7,0"/>
        <ComboBox x:Name="GapBox" Width="78" SelectedIndex="2">
          <ComboBoxItem Content="0.5 秒" Tag="0.5"/>
          <ComboBoxItem Content="1 秒" Tag="1"/>
          <ComboBoxItem Content="2 秒" Tag="2"/>
          <ComboBoxItem Content="3 秒" Tag="3"/>
          <ComboBoxItem Content="5 秒" Tag="5"/>
          <ComboBoxItem Content="10 秒" Tag="10"/>
        </ComboBox>
        <Button x:Name="GroupButton" Content="应用分组"/>
        <CheckBox x:Name="AutoAdvanceCheck" Content="标记后自动下一张" IsChecked="True" VerticalAlignment="Center" Margin="5,0,17,0"/>
        <Button x:Name="RejectButton" Content="X  标为废片" Background="#69404B"/>
        <Button x:Name="KeepButton" Content="K  保留" Background="#245F4B"/>
        <Button x:Name="DeleteMarkedButton" Content="废片批量移入回收站" Background="#A23640"/>
      </WrapPanel>
    </Border>

    <Grid Grid.Row="2">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="210"/>
        <ColumnDefinition Width="425" MinWidth="315"/>
        <ColumnDefinition Width="*" MinWidth="330"/>
      </Grid.ColumnDefinitions>

      <Border Grid.Column="0" Background="#171D28" CornerRadius="7" Margin="0,0,10,0" Padding="8">
        <DockPanel>
          <TextBlock x:Name="GroupsHeaderLabel" DockPanel.Dock="Top" Text="分组 / 页" FontWeight="Bold" Foreground="#A8B6CA" Margin="8,7,0,10"/>
          <TextBlock DockPanel.Dock="Bottom" x:Name="GroupsHint" Text="选择左侧组快速切换" TextWrapping="Wrap"
                     Foreground="#7F91A8" FontSize="11" Margin="8,10,8,4"/>
          <ListBox x:Name="GroupsList" DisplayMemberPath="Title" FontSize="12"/>
        </DockPanel>
      </Border>

      <Border Grid.Column="1" Background="#171D28" CornerRadius="7" Margin="0,0,10,0" Padding="8">
        <DockPanel>
          <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="4,4,0,8">
            <TextBlock x:Name="PhotosHeaderLabel" Text="照片" FontWeight="Bold" Foreground="#A8B6CA" VerticalAlignment="Center"/>
            <TextBlock x:Name="GroupInfo" Text="" Foreground="#7F91A8" FontSize="11"
                       VerticalAlignment="Center" Margin="10,0,0,0"/>
          </StackPanel>
          <StackPanel DockPanel.Dock="Bottom" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,9,0,2">
            <Button x:Name="PrevPageButton" Content="‹ 上一页"/>
            <TextBlock x:Name="PageLabel" Text="0 / 0" VerticalAlignment="Center" Margin="8,0,15,0"/>
            <Button x:Name="NextPageButton" Content="下一页 ›"/>
          </StackPanel>
          <ListBox x:Name="ThumbList" SelectionMode="Single" Padding="2" ScrollViewer.VerticalScrollBarVisibility="Auto">
            <ListBox.ItemsPanel>
              <ItemsPanelTemplate><WrapPanel IsItemsHost="True"/></ItemsPanelTemplate>
            </ListBox.ItemsPanel>
          </ListBox>
        </DockPanel>
      </Border>

      <Border Grid.Column="2" Background="#171D28" CornerRadius="7" Padding="12">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <DockPanel Grid.Row="0" Margin="0,0,0,10">
            <Button DockPanel.Dock="Right" x:Name="DeleteSelectedButton" Content="Delete 删除选中（含 RAW）" Background="#69404B"/>
            <Button DockPanel.Dock="Right" x:Name="ZoomButton" Content="100% 放大"/>
            <TextBlock x:Name="PreviewTitle" Text="选择一张照片" FontSize="15" FontWeight="Bold"
                       VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
          </DockPanel>
          <Grid Grid.Row="1" Background="#0C1017" ClipToBounds="True">
            <Image x:Name="PreviewFit" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality"/>
            <ScrollViewer x:Name="ZoomScroll" Visibility="Collapsed"
                          HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">
              <Image x:Name="PreviewZoom" Stretch="None" HorizontalAlignment="Left" VerticalAlignment="Top"/>
            </ScrollViewer>
            <TextBlock x:Name="EmptyPreview" Text="打开文件夹后即可选片" Foreground="#64748B" FontSize="16"
                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Grid>
          <StackPanel Grid.Row="2" Margin="2,10,0,0">
            <TextBlock x:Name="PreviewDetails" Foreground="#B1BED1" TextWrapping="Wrap" FontSize="12"/>
            <TextBlock x:Name="HelpLabel" Text="快捷键：← / → 切换 · X 废片 · K 保留 · Space 放大 · Delete 删除选中"
                       FontSize="11" Foreground="#7D90AA" Margin="0,6,0,0" TextWrapping="Wrap"/>
          </StackPanel>
        </Grid>
      </Border>
    </Grid>

    <Border Grid.Row="3" Background="#1A2230" CornerRadius="7" Margin="0,12,0,0" Padding="11,9">
      <DockPanel LastChildFill="True">
        <TextBlock x:Name="CountersLabel" DockPanel.Dock="Right" Text="0 张照片" Foreground="#93C5FD" Margin="18,0,0,0"/>
        <TextBlock x:Name="StatusLabel" Text="只处理当前文件夹；删除操作始终送入 Windows 回收站，不做永久删除。"
                   Foreground="#A8B6CA" TextTrimming="CharacterEllipsis"/>
      </DockPanel>
    </Border>
  </Grid>
</Window>
'@

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$names = @('AppBrandLabel','LanguageLabel','LanguageBox','BrowseLabel','MaxGapLabel','GroupsHeaderLabel','PhotosHeaderLabel','HelpLabel','OpenFolderButton','ReloadButton','RetryDriveButton','FolderLabel','ModeBox','GapBox','GroupButton',
  'AutoAdvanceCheck','RejectButton','KeepButton','DeleteMarkedButton','GroupsList','GroupsHint',
  'GroupInfo','PrevPageButton','PageLabel','NextPageButton','ThumbList',
  'DeleteSelectedButton','ZoomButton','PreviewTitle','PreviewFit','PreviewZoom',
  'ZoomScroll','EmptyPreview','PreviewDetails','CountersLabel','StatusLabel')
foreach ($n in $names) { Set-Variable -Scope Script -Name $n -Value $window.FindName($n) }

# Keep the binding template simple; no UI dependency packages.
$thumbnailXaml = @'
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
  <Border Width="176" Height="151" Margin="3" Padding="6" Background="#232C3B" CornerRadius="5">
    <StackPanel>
      <Grid Width="164" Height="109" Background="#0B111A">
        <Image Source="{Binding Thumbnail}" Stretch="Uniform" RenderOptions.BitmapScalingMode="LowQuality"/>
        <Border Background="#23354C" HorizontalAlignment="Right" VerticalAlignment="Top" Padding="4,2" Opacity="0.93">
          <TextBlock Text="{Binding PairLabel}" Foreground="#DBEAFE" FontSize="10"/>
        </Border>
      </Grid>
      <TextBlock Text="{Binding Name}" Foreground="#E2E8F0" FontSize="11" TextTrimming="CharacterEllipsis"/>
      <TextBlock Text="{Binding StateText}" Foreground="{Binding StatusColor}" FontSize="11"/>
    </StackPanel>
  </Border>
</DataTemplate>
'@
$ThumbList.ItemTemplate = [Windows.Markup.XamlReader]::Parse($thumbnailXaml)

$script:RootFolder = ''
$script:AllItems = New-Object System.Collections.ArrayList
$script:Groups = New-Object System.Collections.ArrayList
$script:ShownItems = @()
$script:CurrentGroup = -1
$script:CurrentPage = 0
$script:PageSize = 64
$script:Busy = $false
$script:Rebuilding = $false
$script:Zoomed = $false
$script:ThumbQueue = [System.Collections.Generic.Queue[object]]::new()
$script:LastStatus = ''
$script:TimeJob = $null
$script:TimePending = @()
$script:TimeMode = 0
$script:TimeGap = 2.0
$script:TimeWatch = $null
$script:TimeReport = ''
$script:TimeReportKey = ''
$script:TimeReportArgs = @()
$script:PageGeneration = 0
$script:PreviewGeneration = 0
$script:ImageLoader = [LightCullFast.AsyncImageLoader]::new()
$script:DecodeErrors = @{}
$script:DecodeLog = Join-Path ([IO.Path]::GetTempPath()) 'LightCull_decode_errors.log'
$script:DriveFault = $false
$script:NeedsRescanForDelete = $false
$script:DriveSignature = ''
$script:DisplayMode = 0
$script:StatusKey = 'initialStatus'
$script:StatusArgs = @()
$script:EmptyMessageKey = 'emptyStart'
$script:LanguageChanging = $true

function Get-DriveSignature([string]$path) {
  $rootPath = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($path))
  $drive = [IO.DriveInfo]::new($rootPath)
  if (-not $drive.IsReady) { throw (TF 'driveUnavailable' @($rootPath)) }
  return ('{0}|{1}|{2}|{3}' -f $rootPath.ToUpperInvariant(),
     [string]$drive.VolumeLabel, [string]$drive.TotalSize, [string]$drive.DriveType)
}

function Invoke-StoragePause([string]$path, [string]$detail) {
  $script:DriveFault = $true
  $script:NeedsRescanForDelete = $true
  $script:ImageLoader.Pause($path, $detail)
  if ($null -ne $script:TimeJob) { $script:TimeJob.Cancel() }
  $RetryDriveButton.IsEnabled = $true
  $DeleteMarkedButton.IsEnabled = $false
  $DeleteSelectedButton.IsEnabled = $false
  Set-LStatus 'storagePause'
}



function Report-DecodeFailure([string]$path, [string]$detail) {
  if ([string]::IsNullOrEmpty($detail)) { $detail = T 'decodeUnknown' }
  if (-not $script:DecodeErrors.ContainsKey($path)) {
    $script:DecodeErrors[$path] = $detail
    try {
      $line = ('[{0}] {1}: {2}{3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $path, $detail, [Environment]::NewLine)
      [IO.File]::AppendAllText($script:DecodeLog, $line, [Text.Encoding]::UTF8)
    } catch { }
  }
  if ($script:ImageLoader.IsPaused) {
    Invoke-StoragePause $path $detail
  } else {
    Set-LStatus 'decodeError' @([IO.Path]::GetFileName($path))
  }
}

function Get-Thumb([string]$path, [int]$width) {
  try {
    # Same stream-based decoder as the background workers; orientation on UI thread.
    $bitmap = [LightCullFast.JpegDecoder]::Decode($path, $width)
    return [LightCullFast.ImageOrientation]::Apply(
      $bitmap, [LightCullFast.FastExif]::ReadOrientation($path))
  } catch {
    if ([LightCullFast.StorageFaults]::IsIoFailure($_.Exception)) {
      Invoke-StoragePause $path $_.Exception.Message
    } else { Report-DecodeFailure $path $_.Exception.Message }
    return $null
  }
}

function Set-ItemLabel($item) {
  if ($item.Rejected) {
    $item.StateText = T 'stateRejected'
    $item.StatusColor = '#FDA4AF'
  } else {
    $item.StateText = T 'stateKept'
    $item.StatusColor = '#86EFAC'
  }
}

function Update-Counters {
  $total = $script:AllItems.Count
  $pairs = 0
  $marked = 0
  $files = 0
  foreach ($item in $script:AllItems) {
    if ($item.RawPaths.Count -gt 0) { $pairs++ }
    if ($item.Rejected) {
      $marked++
      $files += 1 + $item.RawPaths.Count
    }
  }
  $CountersLabel.Text = TF 'counters' @($total,$pairs,$marked,$files)
}

# A compact 9x8 difference hash, only computed in experimental visual grouping mode.
# Not a neural embedding: comparisons are limited to nearby shots in time.
function Read-DHash($item) {
  if ($item.HashLoaded) { return $item.Hash }
  $bitmap = $null
  $small = $null
  $g = $null
  $value = ''
  try {
    $bitmap = [System.Drawing.Image]::FromFile($item.Path)
    $small = [System.Drawing.Bitmap]::new(9, 8)
    $g = [System.Drawing.Graphics]::FromImage($small)
    $g.DrawImage($bitmap, 0, 0, 9, 8)
    $sb = New-Object System.Text.StringBuilder
    for ($y = 0; $y -lt 8; $y++) {
      for ($x = 0; $x -lt 8; $x++) {
        $a = $small.GetPixel($x,$y)
        $b = $small.GetPixel(($x+1),$y)
        $left = 299*$a.R + 587*$a.G + 114*$a.B
        $right = 299*$b.R + 587*$b.G + 114*$b.B
        if ($left -gt $right) { [void]$sb.Append('1') } else { [void]$sb.Append('0') }
      }
    }
    $value = $sb.ToString()
  } catch {
    if ([LightCullFast.StorageFaults]::IsIoFailure($_.Exception)) {
      Invoke-StoragePause $item.Path $_.Exception.Message
    }
    $value = ''
  }
  finally {
    if ($null -ne $g) { $g.Dispose() }
    if ($null -ne $small) { $small.Dispose() }
    if ($null -ne $bitmap) { $bitmap.Dispose() }
  }
  $item.Hash = $value
  $item.HashLoaded = $true
  return $value
}

function Test-Similar([string]$a, [string]$b) {
  if ($a.Length -ne 64 -or $b.Length -ne 64) { return $false }
  $distance = 0
  for ($i = 0; $i -lt 64; $i++) {
    if ($a[$i] -ne $b[$i]) { $distance++ }
    if ($distance -gt 18) { return $false }
  }
  return $true
}

function New-Group([string]$title) {
  return [pscustomobject]@{
    Title = $title
    Members = (New-Object System.Collections.ArrayList)
  }
}

function Set-GroupingControls([bool]$enabled) {
  $OpenFolderButton.IsEnabled = $enabled
  $ReloadButton.IsEnabled = $enabled
  $GroupButton.IsEnabled = $enabled
  $ModeBox.IsEnabled = $enabled
  $GapBox.IsEnabled = $enabled
  $canDelete = $enabled -and (-not $script:DriveFault) -and (-not $script:NeedsRescanForDelete)
  $DeleteMarkedButton.IsEnabled = $canDelete
  $DeleteSelectedButton.IsEnabled = $canDelete
}

function Finish-Groups([int]$mode, [double]$gap) {
  # All expensive EXIF reads have already completed off the UI thread.
  $script:Rebuilding = $true
  $script:Groups = New-Object System.Collections.ArrayList
  try {
    if ($mode -eq 0) {
      $n = 0
      $page = 1
      $g = New-Group (TF 'pageTitle' @($page,0))
      foreach ($item in $script:AllItems) {
        if ($n -ge $script:PageSize) {
          $g.Title = TF 'pageTitle' @($page,$g.Members.Count)
          [void]$script:Groups.Add($g)
          $page++
          $g = New-Group (TF 'pageTitle' @($page,0))
          $n = 0
        }
        [void]$g.Members.Add($item)
        $n++
      }
      if ($g.Members.Count -gt 0) {
        $g.Title = TF 'pageTitle' @($page,$g.Members.Count)
        [void]$script:Groups.Add($g)
      }
      $GroupsHint.Text = T 'groupsHintAll'
    } else {
      # PowerShell sorts the already-cached DateTime values, no JPEG decoding.
      $ordered = @($script:AllItems | Sort-Object -Property CaptureTime, Name)
      $last = $null
      $lastHash = ''
      $g = $null
      $done = 0
      foreach ($item in $ordered) {
        $done++
        if ($script:DriveFault) { throw (T 'pausedGroup') }
        if ($mode -eq 2 -and ($done % 40) -eq 0) {
          Set-LStatus 'visualProgress' @($done,$ordered.Count)
          [void]$window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        }
        $startNew = $true
        if ($null -ne $last) {
          $delta = ($item.CaptureTime - $last.CaptureTime).TotalSeconds
          if ($delta -ge 0 -and $delta -le $gap) {
            if ($mode -eq 1) {
              $startNew = $false
            } else {
              $hash = Read-DHash $item
              $startNew = -not (Test-Similar $lastHash $hash)
            }
          }
        }
        if ($startNew) {
          if ($null -ne $g) { [void]$script:Groups.Add($g) }
          $g = New-Group ''
        }
        [void]$g.Members.Add($item)
        $last = $item
        if ($mode -eq 2) { $lastHash = Read-DHash $item }
      }
      if ($null -ne $g) { [void]$script:Groups.Add($g) }
      for ($i = 0; $i -lt $script:Groups.Count; $i++) {
        $group = $script:Groups[$i]
        $timeText = $group.Members[0].CaptureTime.ToString('HH:mm:ss')
        $kind = if ($group.Members.Count -eq 1) { T 'groupKindSingle' } elseif ($mode -eq 2) { T 'groupKindSimilar' } else { T 'groupKindBurst' }
        $group.Title = TF 'groupTitle' @($kind,($i+1),$group.Members.Count,$timeText)
      }
      if ($mode -eq 1) {
        $GroupsHint.Text = T 'groupsHintTime'
      } else {
        $GroupsHint.Text = T 'groupsHintSimilar'
      }
    }
    $GroupsList.ItemsSource = $null
    $GroupsList.ItemsSource = @($script:Groups.ToArray())
    $script:CurrentGroup = -1
    $script:CurrentPage = 0
  } catch {
    [System.Windows.MessageBox]::Show((TF 'groupFailure' @($_.Exception.Message)), (T 'brand'), 'OK', 'Error') | Out-Null
  } finally {
    $script:DisplayMode = $mode
    $script:Rebuilding = $false
    $script:Busy = $false
    Set-GroupingControls $true
  }
  if ($script:Groups.Count -gt 0) {
    $GroupsList.SelectedIndex = 0
    if ($script:TimeReport -and $mode -eq 1) {
      Set-LStatus 'groupDoneReport' @($script:Groups.Count,$script:TimeReport)
    } else {
      Set-LStatus 'groupDone' @($script:Groups.Count)
    }
  }
}

function Build-Groups {
  if ($script:Busy -or $script:AllItems.Count -eq 0) { return }
  $mode = [int]$ModeBox.SelectedIndex
  $gap = [double]::Parse([string]$GapBox.SelectedItem.Tag,
    [System.Globalization.CultureInfo]::InvariantCulture)
  $script:Busy = $true
  $script:TimeReport = ''
  $script:TimeReportKey = ''
  $script:TimeReportArgs = @()
  Set-GroupingControls $false
  if ($mode -eq 0) {
    Finish-Groups $mode $gap
    return
  }
  $need = @($script:AllItems | Where-Object { -not $_.TimeLoaded })
  if ($need.Count -eq 0) {
    $script:TimeReportKey = 'cachedTime'
    $script:TimeReport = T 'cachedTime'
    Finish-Groups $mode $gap
    return
  }
  try {
    $paths = New-Object 'string[]' $need.Count
    $fallbacks = New-Object 'DateTime[]' $need.Count
    for ($i = 0; $i -lt $need.Count; $i++) {
      $paths[$i] = $need[$i].Path
      $fallbacks[$i] = $need[$i].FileTime
    }
    $script:TimePending = $need
    $script:TimeMode = $mode
    $script:TimeGap = $gap
    $script:TimeWatch = [Diagnostics.Stopwatch]::StartNew()
    $script:TimeJob = [LightCullFast.MetadataBatch]::new($paths, $fallbacks)
    Set-LStatus 'exifStart' @($need.Count)
  } catch {
    $script:TimeJob = $null
    $script:Busy = $false
    Set-GroupingControls $true
    [System.Windows.MessageBox]::Show((TF 'groupStartFailure' @($_.Exception.Message)), (T 'brand'), 'OK', 'Error') | Out-Null
  }
}

function Show-CurrentPage([int]$selectIndex = 0) {
  if ($script:CurrentGroup -lt 0 -or $script:CurrentGroup -ge $script:Groups.Count) { return }
  $g = $script:Groups[$script:CurrentGroup]
  $pages = [int][Math]::Ceiling($g.Members.Count / [double]$script:PageSize)
  if ($script:CurrentPage -lt 0) { $script:CurrentPage = 0 }
  if ($script:CurrentPage -ge $pages) { $script:CurrentPage = $pages - 1 }
  $start = $script:CurrentPage * $script:PageSize
  $end = [Math]::Min($start + $script:PageSize, $g.Members.Count)
  # New groups/page invalidate queued thumbs from previous pages.
  $script:PageGeneration++
  $script:ImageLoader.SetPageGeneration($script:PageGeneration)
  $shown = New-Object System.Collections.ArrayList
  for ($i = $start; $i -lt $end; $i++) {
    $item = $g.Members[$i]
    if ($null -eq $item.Thumbnail -and -not $script:DriveFault) {
      $item.ThumbPending = $true
      $script:ImageLoader.RequestThumbnail([int]$item.Id, $item.Path, $script:PageGeneration)
    }
    [void]$shown.Add($item)
  }
  $script:ShownItems = @($shown.ToArray())
  $ThumbList.ItemsSource = $null
  $ThumbList.ItemsSource = $script:ShownItems
  $PageLabel.Text = '{0} / {1}' -f ($script:CurrentPage + 1), $pages
  $GroupInfo.Text = TF 'groupInfo' @(($script:CurrentGroup+1),$g.Members.Count)
  $PrevPageButton.IsEnabled = ($script:CurrentPage -gt 0)
  $NextPageButton.IsEnabled = ($script:CurrentPage -lt ($pages - 1))
  if ($script:ShownItems.Count -gt 0) {
    $ThumbList.SelectedIndex = [Math]::Min([Math]::Max(0,$selectIndex), $script:ShownItems.Count-1)
    $ThumbList.ScrollIntoView($ThumbList.SelectedItem)
  } else {
    $PreviewFit.Source = $null
    $PreviewZoom.Source = $null
  }
}

function Render-Selection {
  $item = $ThumbList.SelectedItem
  if ($null -eq $item) { return }
  $PreviewTitle.Text = $item.Name
  $EmptyPreview.Visibility = 'Collapsed'
  # Asynchronous preview decoding: rapidly selecting 100MP JPGs does not block UI.
  $script:PreviewGeneration++
  $script:ImageLoader.SetPreviewGeneration($script:PreviewGeneration)
  $PreviewFit.Source = $null
  Set-EmptyMessage 'emptyLoading'
  $EmptyPreview.Visibility = 'Visible'
  if (-not $script:DriveFault) {
    $script:ImageLoader.RequestPreview([int]$item.Id, $item.Path, $script:PreviewGeneration)
  } else { Set-EmptyMessage 'emptyPaused' }
  $PreviewZoom.Source = $null
  $ZoomScroll.Visibility = 'Collapsed'
  $PreviewFit.Visibility = 'Visible'
  $ZoomButton.Content = T 'zoomIn'
  $script:Zoomed = $false
  Update-PreviewDetails $item
}

function Select-Group([int]$groupIndex, [int]$indexInPage = 0) {
  if ($groupIndex -lt 0 -or $groupIndex -ge $script:Groups.Count) { return }
  if ($GroupsList.SelectedIndex -ne $groupIndex) {
    $GroupsList.SelectedIndex = $groupIndex
  } else {
    $script:CurrentGroup = $groupIndex
    Show-CurrentPage $indexInPage
  }
}

function Step-Selection([int]$delta) {
  if ($script:CurrentGroup -lt 0 -or $script:ShownItems.Count -eq 0) { return }
  $idx = $ThumbList.SelectedIndex + $delta
  if ($idx -ge 0 -and $idx -lt $script:ShownItems.Count) {
    $ThumbList.SelectedIndex = $idx
    $ThumbList.ScrollIntoView($ThumbList.SelectedItem)
    return
  }
  if ($idx -ge $script:ShownItems.Count) {
    $g = $script:Groups[$script:CurrentGroup]
    if ((($script:CurrentPage+1) * $script:PageSize) -lt $g.Members.Count) {
      $script:CurrentPage++
      Show-CurrentPage 0
    } elseif ($script:CurrentGroup + 1 -lt $script:Groups.Count) {
      Select-Group ($script:CurrentGroup + 1) 0
    }
  } elseif ($idx -lt 0) {
    if ($script:CurrentPage -gt 0) {
      $script:CurrentPage--
      Show-CurrentPage ([Math]::Min($script:PageSize-1, $script:Groups[$script:CurrentGroup].Members.Count-1 - $script:CurrentPage*$script:PageSize))
    } elseif ($script:CurrentGroup -gt 0) {
      $previousGroup = $script:CurrentGroup - 1
      Select-Group $previousGroup
      $g = $script:Groups[$previousGroup]
      $script:CurrentPage = [int][Math]::Floor(($g.Members.Count-1) / [double]$script:PageSize)
      Show-CurrentPage (($g.Members.Count - 1) % $script:PageSize)
    }
  }
}

function Mark-Selection([bool]$reject) {
  $item = $ThumbList.SelectedItem
  if ($null -eq $item) { return }
  $item.Rejected = $reject
  Set-ItemLabel $item
  Update-Counters
  Update-PreviewDetails $item
  if ($AutoAdvanceCheck.IsChecked -eq $true) { Step-Selection 1 }
}

function Toggle-Zoom {
  $item = $ThumbList.SelectedItem
  if ($null -eq $item) { return }
  if (-not $script:Zoomed) {
    # Decode original resolution only on demand. No image-file handles remain open.
    $PreviewZoom.Source = Get-Thumb $item.Path 0
    if ($null -eq $PreviewZoom.Source) { return }
    $PreviewFit.Visibility = 'Collapsed'
    $ZoomScroll.Visibility = 'Visible'
    $ZoomButton.Content = T 'zoomOut'
    $script:Zoomed = $true
  } else {
    $ZoomScroll.Visibility = 'Collapsed'
    $PreviewFit.Visibility = 'Visible'
    $PreviewZoom.Source = $null
    $ZoomButton.Content = T 'zoomIn'
    $script:Zoomed = $false
  }
}

function Test-DeletePreflight([object[]]$selected) {
  if ($script:DriveFault -or $script:NeedsRescanForDelete -or $script:ImageLoader.IsPaused) {
    return (T 'preflightAfterFault')
  }
  if ([string]::IsNullOrEmpty($script:RootFolder)) { return (T 'preflightNoFolder') }
  try {
    if ((Get-DriveSignature $script:RootFolder) -ne $script:DriveSignature) {
      return (T 'preflightDriveChanged')
    }
    $present = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($f in [IO.Directory]::GetFiles($script:RootFolder)) { [void]$present.Add($f) }
    $rawExts = @('.arw','.cr2','.cr3','.nef','.nrw','.raf','.orf','.rw2','.dng','.pef',
       '.srw','.3fr','.fff','.iiq','.mos','.erf','.k25','.kdc','.mrw','.mef','.raw','.rwl','.x3f','.bay')
    $currentRaws = @{}
    foreach ($file in $present) {
      if ($rawExts -contains ([IO.Path]::GetExtension($file).ToLowerInvariant())) {
        $stemNow = [IO.Path]::GetFileNameWithoutExtension($file)
        if (-not $currentRaws.ContainsKey($stemNow)) { $currentRaws[$stemNow] = New-Object System.Collections.ArrayList }
        [void]$currentRaws[$stemNow].Add($file)
      }
    }
    foreach ($item in $selected) {
      if (-not $present.Contains($item.Path)) {
        return (TF 'preflightJpgMissing' @($item.Name))
      }
      $info = [IO.FileInfo]::new($item.Path)
      if ($info.Length -ne $item.JpgSize -or $info.LastWriteTime.Ticks -ne $item.FileTime.Ticks) {
        return (TF 'preflightJpgChanged' @($item.Name))
      }
      $stem = [IO.Path]::GetFileNameWithoutExtension($item.Path)
      $rawCountNow = if ($currentRaws.ContainsKey($stem)) { $currentRaws[$stem].Count } else { 0 }
      if ($rawCountNow -ne $item.RawPaths.Count) {
        return (TF 'preflightRawCount' @($item.Name))
      }
      foreach ($raw in $item.RawPaths) {
        if ([IO.Path]::GetDirectoryName($raw) -ne $script:RootFolder -or
            [IO.Path]::GetFileNameWithoutExtension($raw) -ne $stem -or
            -not $present.Contains($raw)) {
          return (TF 'preflightPairChanged' @($item.Name))
        }
      }
    }
    return ''
  } catch {
    return (TF 'preflightAccessFailed' @($_.Exception.Message))
  }
}

function Send-ToRecycleBin([object[]]$selected) {
  if ($script:Busy) {
    Set-LStatus 'deleteWhileBusy'
    return
  }
  if ($selected.Count -eq 0) { return }
  $check = Test-DeletePreflight $selected
  if ($check) {
    $script:NeedsRescanForDelete = $true
    $DeleteMarkedButton.IsEnabled = $false
    $DeleteSelectedButton.IsEnabled = $false
    [System.Windows.MessageBox]::Show($check, (T 'deleteSafetyFailed'), 'OK', 'Warning') | Out-Null
    return
  }
  $fileCount = 0
  $paired = 0
  foreach ($item in $selected) {
    $fileCount += 1 + $item.RawPaths.Count
    if ($item.RawPaths.Count -gt 0) { $paired++ }
  }
  $message = TF 'deleteConfirmBody' @($selected.Count,$paired,$fileCount)
  $answer = [System.Windows.MessageBox]::Show($message, (T 'deleteConfirmTitle'), 'YesNo', 'Warning')
  if ($answer -ne 'Yes') { return }
  $check = Test-DeletePreflight $selected
  if ($check) {
    $script:NeedsRescanForDelete = $true
    [System.Windows.MessageBox]::Show($check, (T 'deleteSafetyChanged'), 'OK', 'Warning') | Out-Null
    return
  }
  $success = 0
  $failures = New-Object System.Collections.ArrayList
  $stopNow = $false
  foreach ($item in $selected) {
    $targets = @($item.Path) + @($item.RawPaths)
    foreach ($path in $targets) {
      if (-not [IO.File]::Exists($path)) {
        [void]$failures.Add((TF 'deleteDisappeared' @($path)))
        $stopNow = $true
        break
      }
      try {
        # Always use Recycle Bin; never fall back to permanent deletion.
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
          $path,
          [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
          [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin,
          [Microsoft.VisualBasic.FileIO.UICancelOption]::ThrowException)
        $success++
      } catch {
        [void]$failures.Add("$([IO.Path]::GetFileName($path)): $($_.Exception.Message)")
        $stopNow = $true
        break
      }
    }
    if ($stopNow) { break }
  }
  if ($failures.Count -gt 0) {
    # A Recycle Bin action on a pair is not atomic. Stop on first failure and
    # never continue deleting unrelated photos after device instability.
    $script:NeedsRescanForDelete = $true
    $DeleteMarkedButton.IsEnabled = $false
    $DeleteSelectedButton.IsEnabled = $false
    $examples = (@($failures | Select-Object -First 4) -join "`n")
    [System.Windows.MessageBox]::Show(
      (TF 'deleteStopped' @($success,$examples)),
      (T 'deleteStoppedTitle'), 'OK', 'Warning') | Out-Null
    Set-LStatus 'deleteStoppedStatus' @($success)
    return
  }
  # Successful deletion only: rescan with remaining rejection marks preserved.
  $savedFolder = $script:RootFolder
  Scan-Folder $savedFolder $true
  Set-LStatus 'deleteDone' @($success)
}

function Scan-Folder([string]$folder, [bool]$preserveMarks = $false) {
  if ([string]::IsNullOrWhiteSpace($folder)) { return }
  if ($script:Busy) { return }
  $script:Busy = $true
  try {
    Set-LStatus 'scanning'
    $oldMarks = @{}
    if ($preserveMarks) {
      foreach ($old in $script:AllItems) {
        if ($old.Rejected) {
          $rawKey = (@($old.RawPaths | Sort-Object) -join '|')
          $oldMarks[$old.Path] = [pscustomobject]@{ Size=$old.JpgSize; Ticks=$old.FileTime.Ticks; Raws=$rawKey }
        }
      }
    }
    $rawExtensions = @{}
    foreach ($ext in @('.arw','.cr2','.cr3','.nef','.nrw','.raf','.orf','.rw2','.dng','.pef',
         '.srw','.3fr','.fff','.iiq','.mos','.erf','.k25','.kdc','.mrw','.mef','.raw','.rwl','.x3f','.bay')) {
      $rawExtensions[$ext] = $true
    }
    $signature = Get-DriveSignature $folder
    $rawIndex = @{}
    $jpegs = New-Object System.Collections.ArrayList
    foreach ($path in [IO.Directory]::GetFiles($folder)) {
      $ext = [IO.Path]::GetExtension($path).ToLowerInvariant()
      if ($ext -eq '.jpg' -or $ext -eq '.jpeg') {
        [void]$jpegs.Add($path)
      } elseif ($rawExtensions.ContainsKey($ext)) {
        $name = [IO.Path]::GetFileNameWithoutExtension($path)
        if (-not $rawIndex.ContainsKey($name)) { $rawIndex[$name] = New-Object System.Collections.ArrayList }
        [void]$rawIndex[$name].Add($path)
      }
    }
    $nextItems = New-Object System.Collections.ArrayList
    foreach ($path in ($jpegs | Sort-Object { [IO.Path]::GetFileName($_) })) {
      $stem = [IO.Path]::GetFileNameWithoutExtension($path)
      $raws = @()
      if ($rawIndex.ContainsKey($stem)) { $raws = @($rawIndex[$stem].ToArray()) }
      $fileInfo = [IO.FileInfo]::new($path)
      $item = [LightCullFast.PhotoItem]::new($path, [string[]]$raws, $fileInfo.LastWriteTime)
      $item.JpgSize = $fileInfo.Length
      $item.Id = $nextItems.Count
      if ($preserveMarks -and $oldMarks.ContainsKey($path)) {
        $oldMark = $oldMarks[$path]
        if ($oldMark.Size -eq $item.JpgSize -and
            $oldMark.Ticks -eq $item.FileTime.Ticks -and
            $oldMark.Raws -eq (@($item.RawPaths | Sort-Object) -join '|')) {
          $item.Rejected = $true
          Set-ItemLabel $item
        }
      }
      Set-ItemLabel $item
      [void]$nextItems.Add($item)
    }
    # Commit only after the whole directory was read successfully.

    $script:RootFolder = [IO.Path]::GetFullPath($folder)
    if ($script:RootFolder.Length -gt [IO.Path]::GetPathRoot($script:RootFolder).Length) {
      $script:RootFolder = $script:RootFolder.TrimEnd('\')
    }
    $FolderLabel.Text = $script:RootFolder
    $script:DriveSignature = $signature
    $script:AllItems = $nextItems
    $script:PageGeneration++
    $script:PreviewGeneration++
    $script:ImageLoader.SetPageGeneration($script:PageGeneration)
    $script:ImageLoader.SetPreviewGeneration($script:PreviewGeneration)
    $script:ThumbQueue.Clear()
    $script:DecodeErrors.Clear()
    $script:ImageLoader.Resume()
    $script:DriveFault = $false
    $script:NeedsRescanForDelete = $false
    $RetryDriveButton.IsEnabled = $false
  } catch {
    $message = $_.Exception.Message
    if ($script:RootFolder) { Invoke-StoragePause $folder $message }
    [System.Windows.MessageBox]::Show((TF 'scanFailed' @($message)), (T 'brand'), 'OK', 'Error') | Out-Null
    return
  } finally { $script:Busy = $false }
  Update-Counters
  if ($script:AllItems.Count -eq 0) {
    $script:Groups.Clear()
    $GroupsList.ItemsSource = $null
    $ThumbList.ItemsSource = $null
    $PreviewFit.Source = $null
    $PreviewZoom.Source = $null
    $EmptyPreview.Visibility = 'Visible'
    $PreviewTitle.Text = T 'noJpgTitle'
    $PreviewDetails.Text = T 'noJpgDetail'
    $GroupInfo.Text = ''
    $PageLabel.Text = '0 / 0'
    Set-LStatus 'noJpgStatus'
    return
  }
  Build-Groups
}

# Poll background jobs on the UI thread; bitmap objects are frozen before delivery.
$script:PollTimer = [System.Windows.Threading.DispatcherTimer]::new()
$script:PollTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$script:PollTimer.Add_Tick({
  if (-not $script:DriveFault -and $script:ImageLoader.IsPaused) {
    Invoke-StoragePause $script:ImageLoader.FaultPath $script:ImageLoader.FaultMessage
  }
  if ($null -ne $script:TimeJob) {
    $job = $script:TimeJob
    if (-not $job.Finished) {
      Set-LStatus 'exifRunning' @($job.Done,$script:TimePending.Count)
    } else {
      $script:TimeJob = $null
      $script:TimeWatch.Stop()
      for ($i = 0; $i -lt $job.Done; $i++) {
        $script:TimePending[$i].CaptureTime = $job.Results[$i]
        $script:TimePending[$i].TimeLoaded = $true
      }
      if ($null -ne $job.Error -or $script:DriveFault -or $job.Done -lt $script:TimePending.Count) {
        $script:Busy = $false
        Set-GroupingControls $true
        if ($null -ne $job.Error) {
          Invoke-StoragePause $job.FaultPath $job.Error.Message
        } else { Set-LStatus 'exifStopped' }
      } else {
        $script:TimeReportKey = 'exifTimeReport'
        $script:TimeReportArgs = @($script:TimePending.Count,[Math]::Round($script:TimeWatch.Elapsed.TotalSeconds,2))
        $script:TimeReport = TF $script:TimeReportKey $script:TimeReportArgs
        Finish-Groups $script:TimeMode $script:TimeGap
      }
    }
  }
  $result = $null
  $count = 0
  while ($count -lt 32 -and $script:ImageLoader.TryGetResult([ref]$result)) {
    $count++
    if ($result.IsPreview) {
      if ($result.Generation -eq $script:PreviewGeneration -and
          $ThumbList.SelectedItem -ne $null -and
          $ThumbList.SelectedItem.Path -eq $result.Path) {
        if ($null -ne $result.Image) {
          # Applying WPF transforms on the UI thread avoids cross-thread WPF errors.
          $PreviewFit.Source = [LightCullFast.ImageOrientation]::Apply($result.Image, $result.Orientation)
          $EmptyPreview.Visibility = 'Collapsed'
        } else {
          $PreviewFit.Source = $null
          Set-EmptyMessage 'emptyFail'
          $EmptyPreview.Visibility = 'Visible'
          Report-DecodeFailure $result.Path $result.Error
        }
      }
    } else {
      if ($result.Generation -eq $script:PageGeneration -and
          $result.ItemId -ge 0 -and $result.ItemId -lt $script:AllItems.Count) {
        $item = $script:AllItems[$result.ItemId]
        if ($item.Path -eq $result.Path) {
          if ($null -ne $result.Image) {
            $item.Thumbnail = [LightCullFast.ImageOrientation]::Apply($result.Image, $result.Orientation)
            $script:ThumbQueue.Enqueue($item)
            if ($script:ThumbQueue.Count -gt 300) {
              $evict = $script:ThumbQueue.Dequeue()
              $evict.Thumbnail = $null
            }
          } else {
            $item.Thumbnail = $null
            Report-DecodeFailure $result.Path $result.Error
          }
          $item.ThumbPending = $false
        }
      }
    }
  }
})
$script:PollTimer.Start()
$window.Add_Closed({
  $script:PollTimer.Stop()
  $script:ImageLoader.Dispose()
})

$OpenFolderButton.Add_Click({
  $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
  $dialog.Description = T 'folderDialog'
  $dialog.ShowNewFolderButton = $false
  if ($script:RootFolder -and [IO.Directory]::Exists($script:RootFolder)) { $dialog.SelectedPath = $script:RootFolder }
  if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Scan-Folder $dialog.SelectedPath }
  $dialog.Dispose()
})
$ReloadButton.Add_Click({
  if (-not $script:RootFolder) { return }
  $markedCount = @($script:AllItems | Where-Object { $_.Rejected }).Count
  if ($markedCount -gt 0) {
    $rescanAnswer = [System.Windows.MessageBox]::Show(
      (TF 'rescanConfirm' @($markedCount)),
      (T 'rescanConfirmTitle'), 'YesNo', 'Warning')
    if ($rescanAnswer -ne 'Yes') { return }
  }
  Scan-Folder $script:RootFolder $true
})
$RetryDriveButton.Add_Click({
  if (-not $script:RootFolder) { return }
  try {
    if ((Get-DriveSignature $script:RootFolder) -ne $script:DriveSignature) {
      throw (T 'retryDriveChanged')
    }
    # Small JPEG decode probes device and codec without modifying the source.
    $item = $ThumbList.SelectedItem
    if ($null -eq $item -and $script:AllItems.Count -gt 0) { $item = $script:AllItems[0] }
    if ($null -eq $item) { throw (T 'retryNoJpg') }
    $testBitmap = [LightCullFast.JpegDecoder]::Decode($item.Path, 160)
    if ($null -eq $testBitmap) { throw (T 'retryDecodeEmpty') }
    $script:ImageLoader.Resume()
    $script:DriveFault = $false
    $RetryDriveButton.IsEnabled = $false
    $script:PageGeneration++
    $script:PreviewGeneration++
    $script:ImageLoader.SetPageGeneration($script:PageGeneration)
    $script:ImageLoader.SetPreviewGeneration($script:PreviewGeneration)
    foreach ($itemInPage in $script:ShownItems) { $itemInPage.ThumbPending = $false }
    Show-CurrentPage ([Math]::Max(0,$ThumbList.SelectedIndex))
    Set-LStatus 'retryRestored'
  } catch {
    Invoke-StoragePause $script:RootFolder $_.Exception.Message
    [System.Windows.MessageBox]::Show((TF 'retryFailed' @($_.Exception.Message)), (T 'retryFailedTitle'), 'OK', 'Warning') | Out-Null
  }
})
$GroupButton.Add_Click({ Build-Groups })
$GroupsList.Add_SelectionChanged({
  if ($script:Rebuilding) { return }
  if ($GroupsList.SelectedIndex -ge 0) {
    $script:CurrentGroup = $GroupsList.SelectedIndex
    $script:CurrentPage = 0
    Show-CurrentPage 0
  }
})
$ThumbList.Add_SelectionChanged({ Render-Selection })
$PrevPageButton.Add_Click({
  if ($script:CurrentPage -gt 0) { $script:CurrentPage--; Show-CurrentPage 0 }
})
$NextPageButton.Add_Click({
  if ($script:CurrentGroup -ge 0 -and (($script:CurrentPage+1)*$script:PageSize) -lt $script:Groups[$script:CurrentGroup].Members.Count) {
    $script:CurrentPage++; Show-CurrentPage 0
  }
})
$RejectButton.Add_Click({ Mark-Selection $true })
$KeepButton.Add_Click({ Mark-Selection $false })
$ZoomButton.Add_Click({ Toggle-Zoom })
$DeleteSelectedButton.Add_Click({
  $item = $ThumbList.SelectedItem
  if ($null -ne $item) { Send-ToRecycleBin @($item) }
})
$DeleteMarkedButton.Add_Click({
  $marked = @($script:AllItems | Where-Object { $_.Rejected })
  if ($marked.Count -eq 0) {
    [System.Windows.MessageBox]::Show((T 'noMarked'),(T 'brand'),'OK','Information') | Out-Null
  } else { Send-ToRecycleBin $marked }
})
$window.Add_PreviewKeyDown({
  param($sender,$e)
  $focused = [System.Windows.Input.Keyboard]::FocusedElement
  if ($focused -is [System.Windows.Controls.TextBox] -or $focused -is [System.Windows.Controls.ComboBox]) { return }
  if ($e.Key -eq [System.Windows.Input.Key]::Right) { Step-Selection 1; $e.Handled = $true }
  elseif ($e.Key -eq [System.Windows.Input.Key]::Left) { Step-Selection -1; $e.Handled = $true }
  elseif ($e.Key -eq [System.Windows.Input.Key]::X) { Mark-Selection $true; $e.Handled = $true }
  elseif ($e.Key -eq [System.Windows.Input.Key]::K) { Mark-Selection $false; $e.Handled = $true }
  elseif ($e.Key -eq [System.Windows.Input.Key]::Space) { Toggle-Zoom; $e.Handled = $true }
  elseif ($e.Key -eq [System.Windows.Input.Key]::Delete) {
    $item = $ThumbList.SelectedItem
    if ($null -ne $item) { Send-ToRecycleBin @($item) }
    $e.Handled = $true
  }
})

$LanguageBox.Add_SelectionChanged({
  if ($script:LanguageChanging) { return }
  $chosen = [string]$LanguageBox.SelectedItem.Tag
  if (($chosen -eq 'zh' -or $chosen -eq 'en') -and $chosen -ne $script:Language) {
    $script:Language = $chosen
    Refresh-Language
    Save-LanguagePreference
  }
})
$script:LanguageChanging = $true
$LanguageBox.SelectedIndex = if ($script:Language -eq 'en') { 1 } else { 0 }
$script:LanguageChanging = $false
Refresh-Language

if ($InitialFolder -and [IO.Directory]::Exists($InitialFolder)) { Scan-Folder $InitialFolder }
[void]$window.ShowDialog()
