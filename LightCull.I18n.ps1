# LightCull bilingual strings — PowerShell 5.1 compatible, UTF-8 with BOM.
# Translation placeholders use .NET String.Format: {0}, {1}, ...
$script:TextCatalog = @{
  zh = @{
    windowTitle = '轻选 LightCull · JPG / RAW 联动选片'
    brand = '轻选'
    open = '打开照片文件夹'
    reload = '重新扫描'
    retry = '硬盘恢复后重试预览'
    noFolder = '尚未打开文件夹'
    languageLabel = '语言'
    browseLabel = '浏览方式'
    modeAll = '全部照片（按文件名）'
    modeTime = '连拍分组（按时间）'
    modeSimilar = '相近画面（实验性）'
    maxGap = '最大间隔'
    gapSeconds = '{0} 秒'
    applyGroups = '应用分组'
    autoAdvance = '标记后自动下一张'
    rejectButton = 'X  标为废片'
    keepButton = 'K  保留'
    deleteMarked = '废片批量移入回收站'
    groupsHeader = '分组 / 页'
    groupsHintDefault = '选择左侧组快速切换'
    groupsHintAll = '全部照片按文件名排序，每页最多 64 张。'
    groupsHintTime = '按 EXIF 拍摄时间间隔分组；EXIF 缺失时使用文件修改时间。'
    groupsHintSimilar = '实验功能：连续两张照片须时间接近、差异哈希相近。大文件夹可能较慢。'
    photosHeader = '照片'
    prevPage = '‹ 上一页'
    nextPage = '下一页 ›'
    deleteSelected = 'Delete 删除选中（含 RAW）'
    zoomIn = '100% 放大'
    zoomOut = '适应窗口'
    previewTitleEmpty = '选择一张照片'
    emptyStart = '打开文件夹后即可选片'
    emptyLoading = '正在加载预览…'
    emptyPaused = '硬盘读取已暂停，重连后点击顶部「重试预览」'
    emptyFail = '预览失败，请查看底部提示或解码日志'
    help = '快捷键：← / → 切换 · X 废片 · K 保留 · Space 放大 · Delete 删除选中'
    initialStatus = '只处理当前文件夹；删除操作始终送入 Windows 回收站，不做永久删除。'
    stateRejected = '✕ 待剔除'
    stateKept = '✓ 保留'
    counters = 'JPG {0} 张  ·  配对 RAW {1} 组  ·  待剔除 {2} 张 / {3} 个文件'
    pageTitle = '第 {0} 页 · {1} 张'
    groupKindBurst = '连拍'
    groupKindSimilar = '相似'
    groupKindSingle = '单张'
    groupTitle = '{0} {1:D3} · {2} 张 · {3}'
    groupInfo = '第 {0} 组 · {1} 张'
    noRaw = '无同名 RAW'
    previewState = '状态：{0} · RAW：{1}{2}'
    markRejected = '待剔除'
    markKept = '保留'
    groupDone = '已建立 {0} 组。X 标为废片，K 取消标记。'
    groupDoneReport = '已建立 {0} 组；{1}。X 标废片，K 保留。'
    groupFailure = '分组失败：{0}'
    groupStartFailure = '启动时间分组失败：{0}'
    cachedTime = '拍摄时间已缓存，直接分组'
    exifStart = '正在后台读取 JPEG 文件头 EXIF：0 / {0}（界面仍可浏览）'
    exifRunning = '后台读取 EXIF：{0} / {1}（不解码照片画面）'
    exifTimeReport = 'EXIF 读取 {0} 张，耗时 {1} 秒'
    exifStopped = 'EXIF 扫描因设备读取暂停已中止，请恢复连接后重试分组。'
    visualProgress = '相近画面分析：{0} / {1}（实验模式，可能较慢）'
    pausedGroup = '磁盘读取已暂停，请恢复连接后重新分组。'
    storagePause = '硬盘读取异常，已暂停照片加载和删除。请检查 USB/供电，安全重新连接后点击「硬盘恢复后重试预览」。'
    decodeUnknown = '未知的图片解码错误'
    decodeError = 'JPG 解码失败：{0}（详细原因：%TEMP%\LightCull_decode_errors.log）'
    driveUnavailable = '磁盘当前不可用：{0}'
    deleteWhileBusy = '正在分组，完成后才能执行删除操作。'
    preflightAfterFault = '曾发生磁盘读取错误。请先恢复硬盘，并重新扫描验证配对后再删除。'
    preflightNoFolder = '未选择文件夹。'
    preflightDriveChanged = '盘符对应的磁盘信息发生变化，已取消删除。请重新打开照片文件夹。'
    preflightJpgMissing = '源 JPG 已不存在：{0}；已取消本次删除。'
    preflightJpgChanged = '源 JPG 已发生变化：{0}；请重新扫描后再删除。'
    preflightRawCount = '当前 RAW 数量与扫描时不一致：{0}；已取消删除。'
    preflightPairChanged = 'RAW 配对已改变：{0}；已取消本次删除。'
    preflightAccessFailed = '磁盘访问失败，已取消删除：{0}'
    deleteSafetyFailed = '删除安全检查未通过'
    deleteSafetyChanged = '磁盘状态已变化，删除被阻止'
    deleteConfirmTitle = '确认删除配对文件'
    deleteConfirmBody = '准备移入 Windows 回收站：\n\nJPG：{0} 张\n同名 RAW 配对：{1} 组\n实际文件数：{2} 个\n\n仅操作当前文件夹中同名的 JPG/RAW，不碰 XMP 等其他文件。\n回收站不可用时不会改为永久删除。\n\n继续吗？'
    deleteDisappeared = '{0} 在操作期间消失。'
    deleteStopped = '已移入回收站 {0} 个文件，但操作被中止。\n{1}\n\n请检查回收站与原文件夹，恢复稳定后重新扫描。'
    deleteStoppedTitle = '删除中断：请检查 JPG / RAW 配对'
    deleteStoppedStatus = '删除中断：已处理 {0} 个文件；已锁定后续删除，等待重新扫描。'
    deleteDone = '已将 {0} 个文件移入回收站；可通过 Windows 回收站恢复。'
    scanning = '正在扫描当前文件夹中的 JPG / RAW…'
    scanFailed = '扫描失败：{0}\n\n原有选片状态仍然保留。'
    noJpgTitle = '没有找到 JPG / JPEG'
    noJpgDetail = '请确认文件夹中有 JPG 或 JPEG 文件；不会扫描子文件夹。'
    noJpgStatus = '没有找到 JPG / JPEG。支持同名 CR3 / CR2 / ARW / NEF / RAF / DNG 等 RAW。'
    folderDialog = '选择包含 JPG 和同名 RAW 的文件夹（不递归子文件夹）'
    rescanConfirmTitle = '确认重新扫描'
    rescanConfirm = '目前有 {0} 张待剔除。重新扫描将尝试保留 JPG 大小、修改时间和 RAW 配对均未变化的标记，变化的文件不保留标记。继续？'
    retryDriveChanged = '磁盘卷信息与上次扫描不一致。为避免操作错误磁盘，请重新打开文件夹。'
    retryNoJpg = '没有可供测试的 JPG。'
    retryDecodeEmpty = 'JPG 测试解码没有返回图像。'
    retryRestored = '硬盘当前可读取，已恢复预览。为安全起见，删除仍被锁定；请点击「重新扫描」验证 JPG/RAW。'
    retryFailed = '重试失败：{0}'
    retryFailedTitle = '仍无法读取硬盘'
    noMarked = '尚未标记废片。按 X 标记后再批量删除。'
    helperMissing = '缺少辅助源码文件：{0}。请完整解压压缩包。'
    frameworkMissing = '系统 .NET 程序集不存在：{0}'
  }
  en = @{
    windowTitle = 'LightCull · JPG / RAW Photo Culling'
    brand = 'LightCull'
    open = 'Open Photo Folder'
    reload = 'Rescan'
    retry = 'Retry After Drive Reconnect'
    noFolder = 'No folder opened'
    languageLabel = 'Language'
    browseLabel = 'View'
    modeAll = 'All photos (filename)'
    modeTime = 'Burst groups (by time)'
    modeSimilar = 'Similar frames (experimental)'
    maxGap = 'Max gap'
    gapSeconds = '{0} sec'
    applyGroups = 'Apply Groups'
    autoAdvance = 'Auto-advance after marking'
    rejectButton = 'X  Reject'
    keepButton = 'K  Keep'
    deleteMarked = 'Recycle Rejected Photos'
    groupsHeader = 'Groups / Pages'
    groupsHintDefault = 'Choose a group to jump between photos.'
    groupsHintAll = 'Sorted by filename; up to 64 photos per page.'
    groupsHintTime = 'Grouped by EXIF capture time; uses file modification time if EXIF is missing.'
    groupsHintSimilar = 'Experimental: adjacent frames must be close in time and image hash. May be slow for large folders.'
    photosHeader = 'Photos'
    prevPage = '‹ Previous'
    nextPage = 'Next ›'
    deleteSelected = 'Delete Selected (+ RAW)'
    zoomIn = '100% Zoom'
    zoomOut = 'Fit to Window'
    previewTitleEmpty = 'Select a photo'
    emptyStart = 'Open a folder to start culling'
    emptyLoading = 'Loading preview…'
    emptyPaused = 'Drive I/O paused. Reconnect, then choose Retry above.'
    emptyFail = 'Preview failed; see the status bar or decode log.'
    help = 'Keys: ← / → Navigate · X Reject · K Keep · Space Zoom · Delete Recycle selected'
    initialStatus = 'Current folder only. Deleted files go to the Windows Recycle Bin; never permanently deleted.'
    stateRejected = '✕ Rejected'
    stateKept = '✓ Keep'
    counters = 'JPG: {0}  ·  RAW pairs: {1}  ·  Rejected: {2} photos / {3} files'
    pageTitle = 'Page {0} · {1} photos'
    groupKindBurst = 'Burst'
    groupKindSimilar = 'Similar'
    groupKindSingle = 'Single'
    groupTitle = '{0} {1:D3} · {2} photos · {3}'
    groupInfo = 'Group {0} · {1} photos'
    noRaw = 'No matching RAW'
    previewState = 'Status: {0} · RAW: {1}{2}'
    markRejected = 'Rejected'
    markKept = 'Keep'
    groupDone = 'Created {0} groups. X to reject, K to keep.'
    groupDoneReport = 'Created {0} groups; {1}. X to reject, K to keep.'
    groupFailure = 'Grouping failed: {0}'
    groupStartFailure = 'Could not start grouping: {0}'
    cachedTime = 'Capture times cached; grouping without rereading files'
    exifStart = 'Reading JPEG EXIF headers in background: 0 / {0} (UI remains responsive)'
    exifRunning = 'Reading EXIF: {0} / {1} (no full image decoding)'
    exifTimeReport = 'Read EXIF for {0} files in {1} sec'
    exifStopped = 'EXIF scan stopped after a drive I/O error. Reconnect, then retry grouping.'
    visualProgress = 'Analyzing similar frames: {0} / {1} (experimental, may be slow)'
    pausedGroup = 'Drive I/O is paused. Reconnect and regroup.'
    storagePause = 'Drive read error. Photo loading and deletion have been paused. Check USB/power, reconnect safely, then click Retry.'
    decodeUnknown = 'Unknown image decode error'
    decodeError = 'JPG decode failed: {0} (details: %TEMP%\LightCull_decode_errors.log)'
    driveUnavailable = 'Drive unavailable: {0}'
    deleteWhileBusy = 'Grouping in progress. Finish grouping before deleting.'
    preflightAfterFault = 'A disk read error occurred. Reconnect the drive and rescan to verify RAW pairs before deleting.'
    preflightNoFolder = 'No folder selected.'
    preflightDriveChanged = 'Drive identification changed. Deletion canceled; reopen the photo folder.'
    preflightJpgMissing = 'Source JPG missing: {0}. Deletion canceled.'
    preflightJpgChanged = 'Source JPG changed: {0}. Rescan before deletion.'
    preflightRawCount = 'RAW count differs from original scan for {0}. Deletion canceled.'
    preflightPairChanged = 'RAW pair changed for {0}. Deletion canceled.'
    preflightAccessFailed = 'Disk access failed. Deletion canceled: {0}'
    deleteSafetyFailed = 'Delete safety check failed'
    deleteSafetyChanged = 'Drive state changed: deletion blocked'
    deleteConfirmTitle = 'Confirm paired-file deletion'
    deleteConfirmBody = 'Move these files to the Windows Recycle Bin?\n\nJPG photos: {0}\nMatching RAW pairs: {1}\nTotal files: {2}\n\nOnly matching JPG/RAW files in the current folder will be affected; XMP sidecars are excluded.\nIf the Recycle Bin is unavailable, permanent deletion will NOT be used.\n\nContinue?'
    deleteDisappeared = '{0} disappeared during deletion.'
    deleteStopped = '{0} files moved to the Recycle Bin, but the operation stopped.\n{1}\n\nCheck the Recycle Bin and original folder; rescan once the drive is stable.'
    deleteStoppedTitle = 'Delete interrupted: check JPG / RAW pairs'
    deleteStoppedStatus = 'Delete interrupted: {0} files processed. Further deletion is locked until a rescan.'
    deleteDone = 'Moved {0} files to the Recycle Bin. You can restore them from Windows.'
    scanning = 'Scanning current folder for JPG / RAW files…'
    scanFailed = 'Scan failed: {0}\n\nYour existing selection is still preserved.'
    noJpgTitle = 'No JPG / JPEG files found'
    noJpgDetail = 'Please select a folder containing JPG/JPEG files. Subfolders are not scanned.'
    noJpgStatus = 'No JPG / JPEG found. Matching RAW formats include CR3, CR2, ARW, NEF, RAF, DNG, and more.'
    folderDialog = 'Choose a folder containing JPG and matching RAW files (no subfolders)'
    rescanConfirmTitle = 'Confirm rescan'
    rescanConfirm = '{0} photos are marked for rejection. Rescanning will preserve marks only if JPG size, modification time, and RAW pairs remain unchanged. Continue?'
    retryDriveChanged = 'Drive volume details differ from the previous scan. Reopen the folder to avoid acting on the wrong disk.'
    retryNoJpg = 'No JPG available for a read test.'
    retryDecodeEmpty = 'Test JPG decoding returned no image.'
    retryRestored = 'Drive readable again; previews restored. For safety, deletion stays locked until you rescan to verify JPG/RAW pairs.'
    retryFailed = 'Retry failed: {0}'
    retryFailedTitle = 'Drive still unreadable'
    noMarked = 'No rejected photos. Press X on a photo before recycling marked items.'
    helperMissing = 'Helper source is missing: {0}. Extract the entire ZIP.'
    frameworkMissing = 'Required .NET Framework assembly not found: {0}'
  }
}

function T([string]$key) {
  $table = $script:TextCatalog[$script:Language]
  if ($null -ne $table -and $table.ContainsKey($key)) { return [string]$table[$key] }
  return [string]$script:TextCatalog['zh'][$key]
}

function TF([string]$key, [object[]]$values = @()) {
  $format = (T $key).Replace('\n', [Environment]::NewLine)
  return [string]::Format([Globalization.CultureInfo]::InvariantCulture, $format, $values)
}

function Set-LStatus([string]$key, [object[]]$values = @()) {
  $script:StatusKey = $key
  $script:StatusArgs = @($values)
  $script:LastStatus = TF $key $values
  $StatusLabel.Text = $script:LastStatus
}

function Save-LanguagePreference {
  try {
    $directory = [IO.Path]::GetDirectoryName($script:SettingsPath)
    if (-not [IO.Directory]::Exists($directory)) { [void][IO.Directory]::CreateDirectory($directory) }
    $json = @{ language = $script:Language } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($script:SettingsPath, $json, [Text.UTF8Encoding]::new($false))
  } catch { # Read-only profiles still support session-only switching.
  }
}

function Set-EmptyMessage([string]$key) {
  $script:EmptyMessageKey = $key
  $EmptyPreview.Text = T $key
}

function Refresh-GroupTitles {
  if ($script:Groups.Count -eq 0) { return }
  for ($i = 0; $i -lt $script:Groups.Count; $i++) {
    $g = $script:Groups[$i]
    if ($script:DisplayMode -eq 0) {
      $g.Title = TF 'pageTitle' @(($i+1),$g.Members.Count)
    } else {
      $kind = if ($g.Members.Count -eq 1) { T 'groupKindSingle' } elseif ($script:DisplayMode -eq 2) { T 'groupKindSimilar' } else { T 'groupKindBurst' }
      $time = $g.Members[0].CaptureTime.ToString('HH:mm:ss')
      $g.Title = TF 'groupTitle' @($kind, ($i+1), $g.Members.Count, $time)
    }
  }
  if ($null -ne $GroupsList -and $GroupsList.Items.Count -gt 0) { $GroupsList.Items.Refresh() }
}

function Refresh-Language {
  $window.Title = T 'windowTitle'
  $AppBrandLabel.Text = T 'brand'
  $OpenFolderButton.Content = T 'open'
  $ReloadButton.Content = T 'reload'
  $RetryDriveButton.Content = T 'retry'
  $LanguageLabel.Text = T 'languageLabel'
  $BrowseLabel.Text = T 'browseLabel'
  $ModeBox.Items[0].Content = T 'modeAll'
  $ModeBox.Items[1].Content = T 'modeTime'
  $ModeBox.Items[2].Content = T 'modeSimilar'
  $MaxGapLabel.Text = T 'maxGap'
  foreach ($gapEntry in $GapBox.Items) { $gapEntry.Content = TF 'gapSeconds' @([string]$gapEntry.Tag) }
  $GroupButton.Content = T 'applyGroups'
  $AutoAdvanceCheck.Content = T 'autoAdvance'
  $RejectButton.Content = T 'rejectButton'
  $KeepButton.Content = T 'keepButton'
  $DeleteMarkedButton.Content = T 'deleteMarked'
  $GroupsHeaderLabel.Text = T 'groupsHeader'
  $PhotosHeaderLabel.Text = T 'photosHeader'
  $PrevPageButton.Content = T 'prevPage'
  $NextPageButton.Content = T 'nextPage'
  $DeleteSelectedButton.Content = T 'deleteSelected'
  $ZoomButton.Content = if ($script:Zoomed) { T 'zoomOut' } else { T 'zoomIn' }
  $HelpLabel.Text = T 'help'
  if (-not $script:RootFolder) { $FolderLabel.Text = T 'noFolder' }
  if ($script:Groups.Count -eq 0) { $GroupsHint.Text = T 'groupsHintDefault' }
  elseif ($script:DisplayMode -eq 0) { $GroupsHint.Text = T 'groupsHintAll' }
  elseif ($script:DisplayMode -eq 1) { $GroupsHint.Text = T 'groupsHintTime' }
  else { $GroupsHint.Text = T 'groupsHintSimilar' }
  Refresh-GroupTitles
  foreach ($item in $script:AllItems) { Set-ItemLabel $item }
  Update-Counters
  if ($script:CurrentGroup -ge 0 -and $script:CurrentGroup -lt $script:Groups.Count) {
    $g = $script:Groups[$script:CurrentGroup]
    $GroupInfo.Text = TF 'groupInfo' @(($script:CurrentGroup+1),$g.Members.Count)
  }
  $item = $ThumbList.SelectedItem
  if ($null -ne $item) { Update-PreviewDetails $item }
  else {
    $PreviewTitle.Text = T 'previewTitleEmpty'
    if ($script:AllItems.Count -eq 0 -and $script:RootFolder) {
      $PreviewTitle.Text = T 'noJpgTitle'
      $PreviewDetails.Text = T 'noJpgDetail'
    }
  }
  $EmptyPreview.Text = T $script:EmptyMessageKey
  if ($script:TimeReportKey) {
    $script:TimeReport = TF $script:TimeReportKey $script:TimeReportArgs
    if ($script:StatusKey -eq 'groupDoneReport' -and $script:StatusArgs.Count -gt 1) {
      $script:StatusArgs[1] = $script:TimeReport
    }
  }
  if ($script:StatusKey) { $StatusLabel.Text = TF $script:StatusKey $script:StatusArgs }
}

function Update-PreviewDetails($item) {
  $pairText = if ($item.RawPaths.Count -gt 0) {
    ($item.RawPaths | ForEach-Object { [IO.Path]::GetFileName($_) }) -join ', '
  } else { T 'noRaw' }
  $markText = if ($item.Rejected) { T 'markRejected' } else { T 'markKept' }
  $timeText = ''
  if ($item.TimeLoaded) { $timeText = ' · ' + $item.CaptureTime.ToString('yyyy-MM-dd HH:mm:ss.fff') }
  $PreviewDetails.Text = TF 'previewState' @($markText,$pairText,$timeText)
}

