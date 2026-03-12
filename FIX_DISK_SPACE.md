# Fix Disk Space Error for Flutter

## Error
```
FileSystemException: writeFrom failed, path = 'C:\Users\...\Temp\flutter_tools...\app.dill.sources' 
(OS Error: There is not enough space on the disk., errno = 112)
```

## Solution Steps

### 1. ✅ Clean Flutter Build Files (Already Done)
```bash
cd "bidmaster flutter"
flutter clean
```

### 2. Clean Temp Files
```bash
# Clean Flutter temp files
Remove-Item "$env:LOCALAPPDATA\Temp\flutter_tools.*" -Recurse -Force
Remove-Item "$env:TEMP\flutter_*" -Recurse -Force
```

### 3. Free Up Disk Space

#### Option A: Clean Windows Temp Files
```powershell
# Clean Windows temp files
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
```

#### Option B: Clean Flutter Cache
```bash
flutter pub cache clean
```

#### Option C: Clean Build Folders
```bash
# In project root
Remove-Item "bidmaster flutter\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "bidmaster flutter\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
```

### 4. Check Disk Space
```powershell
# Check free space on C: drive
[math]::Round((Get-PSDrive C).Free/1GB, 2)
```

### 5. If Still Low on Space

#### Free Up More Space:
1. **Delete old Flutter projects** (if any)
2. **Empty Recycle Bin**
3. **Run Disk Cleanup** (Windows built-in tool)
4. **Uninstall unused programs**
5. **Move files to another drive** (D: drive if available)

### 6. Try Building Again
```bash
cd "bidmaster flutter"
flutter pub get
flutter run
```

## Quick Fix Script

Run this PowerShell script to clean everything:

```powershell
# Clean Flutter
cd "D:\New folder\Main folder\bidmaster flutter"
flutter clean
flutter pub cache clean

# Clean temp files
Remove-Item "$env:LOCALAPPDATA\Temp\flutter_tools.*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\flutter_*" -Recurse -Force -ErrorAction SilentlyContinue

# Clean build folders
Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "✅ All cleaned! Try running 'flutter pub get' and 'flutter run' again"
```

## Minimum Space Required

- **Flutter SDK**: ~2-3 GB
- **Build files**: ~500 MB - 2 GB
- **Temp files**: ~500 MB - 1 GB
- **Total recommended**: At least **5-10 GB free space** on C: drive

## Alternative: Use D: Drive

If C: drive is full, you can:
1. Move Flutter SDK to D: drive
2. Set `PUB_CACHE` environment variable to D: drive
3. Build on D: drive instead

```powershell
# Set Flutter cache to D: drive
$env:PUB_CACHE = "D:\flutter_cache"
[System.Environment]::SetEnvironmentVariable("PUB_CACHE", "D:\flutter_cache", "User")
```

