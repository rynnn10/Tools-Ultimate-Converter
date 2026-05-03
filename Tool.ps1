# Konfigurasi Folder Kerja
$workDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$hasilDir = Join-Path $workDir "Hasil"
$alatBantuDir = Join-Path $workDir "ALAT BANTU"
$proyekDir = Join-Path $workDir "PROJECT"

# Memaksa Terminal menggunakan Encoding UTF-8 (agar teks rapi)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Membuat folder utama jika belum ada
if (-not (Test-Path $hasilDir)) { New-Item -ItemType Directory -Path $hasilDir -Force | Out-Null }
if (-not (Test-Path $alatBantuDir)) { New-Item -ItemType Directory -Path $alatBantuDir -Force | Out-Null }
if (-not (Test-Path $proyekDir)) { New-Item -ItemType Directory -Path $proyekDir -Force | Out-Null }

# --- LOGIKA OTOMATIS PINDAH FILE KE FOLDER PROYEK ---
$currentScript = Split-Path -Leaf $MyInvocation.MyCommand.Definition
$filesToMove = Get-ChildItem -Path $workDir -File | Where-Object {
    $_.Name -ne $currentScript -and $_.Extension -notmatch "(?i)\.(bat|ps1|ini)$"
}

if ($filesToMove) {
    Write-Host "`n[*] Memindahkan file bahan ke folder 'PROJECT'..." -ForegroundColor Yellow
    foreach ($file in $filesToMove) {
        Move-Item -Path $file.FullName -Destination $proyekDir -Force
        Write-Host "    -> $($file.Name) dipindahkan." -ForegroundColor Cyan
    }
    Start-Sleep -Seconds 1
}

# --- FUNGSI ANIMASI LOADING BAR ---
function Tampilkan-Progress {
    param([int]$Current, [int]$Total, [string]$Pesan)
    if ($Total -eq 0) { return }
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 25
    $filledLength = [math]::Floor(($percent / 100) * $barLength)
    $emptyLength = $barLength - $filledLength
    
    $bar = ("#" * $filledLength) + ("-" * $emptyLength)
    
    $textOutput = "[*] $Pesan [$bar] $percent% "
    Write-Host "`r$($textOutput.PadRight(110))" -NoNewline -ForegroundColor Cyan
    
    if ($Current -eq $Total) { Write-Host "`n[v] Selesai!`n" -ForegroundColor Green }
}

# --- FUNGSI DOWNLOAD DEPENDENSI ---
function Siapkan-FFmpeg {
    $ffmpegPath = Join-Path $alatBantuDir "ffmpeg.exe"
    if (-not (Test-Path $ffmpegPath)) {
        Write-Host "`n[!] FFmpeg belum terinstal. Sedang mengunduh mesin media (Hanya 1x)..." -ForegroundColor Cyan
        $zipUrl = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
        $zipPath = Join-Path $alatBantuDir "ffmpeg_temp.zip"
        $extPath = Join-Path $alatBantuDir "ffmpeg_ext"
        try {
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
            Expand-Archive -Path $zipPath -DestinationPath $extPath -Force
            $exe = Get-ChildItem -Path $extPath -Filter "ffmpeg.exe" -Recurse | Select-Object -First 1
            Move-Item -Path $exe.FullName -Destination $ffmpegPath -Force
            Remove-Item -Path $zipPath -Force
            Remove-Item -Path $extPath -Recurse -Force
        } catch {
            Write-Host "[x] Gagal mengunduh FFmpeg. Cek internet Anda." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "`n[v] Mesin FFmpeg sudah tersedia di ALAT BANTU." -ForegroundColor Green
    }
    return $true
}

function Siapkan-iTextSharp {
    $dllPath = Join-Path $alatBantuDir "itextsharp.dll"
    $bcPath = Join-Path $alatBantuDir "BouncyCastle.Crypto.dll"
    
    $butuhDownload = $false
    if (-not (Test-Path $dllPath) -or (Get-Item $dllPath).Length -lt 100KB) { $butuhDownload = $true }
    if (-not (Test-Path $bcPath) -or (Get-Item $bcPath).Length -lt 100KB) { $butuhDownload = $true }

    if ($butuhDownload) {
        Write-Host "`n[!] Komponen PDF belum lengkap. Sedang mengunduh iTextSharp & BouncyCastle (Hanya 1x)..." -ForegroundColor Cyan
        $nupkgUrl = "https://www.nuget.org/api/v2/package/iTextSharp/5.5.13.3"
        $zipPath = Join-Path $alatBantuDir "itextsharp_temp.zip"
        $extPath = Join-Path $alatBantuDir "itextsharp_ext"

        $bcUrl = "https://www.nuget.org/api/v2/package/BouncyCastle/1.8.9"
        $bcZipPath = Join-Path $alatBantuDir "bc_temp.zip"
        $bcExtPath = Join-Path $alatBantuDir "bc_ext"

        try {
            if (-not (Test-Path $dllPath)) {
                Invoke-WebRequest -Uri $nupkgUrl -OutFile $zipPath -UseBasicParsing
                Expand-Archive -Path $zipPath -DestinationPath $extPath -Force
                $dll = Get-ChildItem -Path $extPath -Filter "itextsharp.dll" -Recurse | Select-Object -First 1
                Move-Item -Path $dll.FullName -Destination $dllPath -Force
                Remove-Item -Path $zipPath -Force
                Remove-Item -Path $extPath -Recurse -Force
            }
            if (-not (Test-Path $bcPath)) {
                Invoke-WebRequest -Uri $bcUrl -OutFile $bcZipPath -UseBasicParsing
                Expand-Archive -Path $bcZipPath -DestinationPath $bcExtPath -Force
                $bcDll = Get-ChildItem -Path $bcExtPath -Filter "BouncyCastle.Crypto.dll" -Recurse | Select-Object -First 1
                Move-Item -Path $bcDll.FullName -Destination $bcPath -Force
                Remove-Item -Path $bcZipPath -Force
                Remove-Item -Path $bcExtPath -Recurse -Force
            }
        } catch {
            Write-Host "[x] Gagal mengunduh komponen PDF. Cek internet Anda." -ForegroundColor Red
            return $false
        }
    } else {
         Write-Host "`n[v] Komponen PDF (iTextSharp) sudah tersedia di ALAT BANTU." -ForegroundColor Green
    }
    return $true
}

# --- FUNGSI PEMILIHAN FILE ---
function Pilih-File {
    param($FileList, [string]$Jenis)
    if ($FileList.Count -eq 0) {
        Write-Host "`n[x] Tidak ada file $Jenis di folder 'PROJECT'!" -ForegroundColor Red
        return $null
    }
    Write-Host "`n=== DAFTAR FILE $Jenis ===" -ForegroundColor Yellow
    for ($i = 0; $i -lt $FileList.Count; $i++) { Write-Host "[$($i+1)] $($FileList[$i].Name)" -ForegroundColor Cyan }
    Write-Host "[A] Pilih Semua File" -ForegroundColor Green
    Write-Host "[0] Batal / Kembali" -ForegroundColor Red
    
    $pilihan = Read-Host "`nKetik angka (contoh: 1,3) atau A"
    if ($pilihan -eq '0') { return $null }
    if ($pilihan -match 'a|A') { return $FileList }
    
    $selectedFiles = @()
    foreach ($index in ($pilihan -split ',')) {
        $idx = [int]$index.Trim() - 1
        if ($idx -ge 0 -and $idx -lt $FileList.Count) { $selectedFiles += $FileList[$idx] }
    }
    return $selectedFiles
}

# ==========================================
# 1. FITUR KONVERSI OFFICE KE PDF
# ==========================================
function Convert-WordToPDF {
    $files = @(Get-ChildItem -Path $proyekDir -Filter *.docx -File)
    $targetFiles = Pilih-File -FileList $files -Jenis "Word (.docx)"
    if (-not $targetFiles) { return }
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0 
    
    for ($i = 0; $i -lt $targetFiles.Count; $i++) {
        $file = $targetFiles[$i]
        $outPath = [string](Join-Path $hasilDir ($file.BaseName + ".pdf"))
        Tampilkan-Progress -Current ($i+1) -Total $targetFiles.Count -Pesan "Mengonversi Word: $($file.Name)"
        $doc = $word.Documents.Open($file.FullName, $false, $false)
        $doc.SaveAs2($outPath, 17)
        $doc.Close()
    }
    $word.Quit()
}

function Convert-PPTToPDF {
    $files = @(Get-ChildItem -Path $proyekDir -Filter *.pptx -File)
    $targetFiles = Pilih-File -FileList $files -Jenis "PPT (.pptx)"
    if (-not $targetFiles) { return }
    $ppt = New-Object -ComObject PowerPoint.Application
    
    for ($i = 0; $i -lt $targetFiles.Count; $i++) {
        $file = $targetFiles[$i]
        $outPath = Join-Path $hasilDir ($file.BaseName + ".pdf")
        Tampilkan-Progress -Current ($i+1) -Total $targetFiles.Count -Pesan "Mengonversi PPT: $($file.Name)"
        $presentation = $ppt.Presentations.Open($file.FullName, $null, $null, $false)
        $presentation.SaveAs($outPath, 32)
        $presentation.Close()
    }
    $ppt.Quit()
}

function Convert-ExcelToPDF {
    $files = @(Get-ChildItem -Path $proyekDir -Filter *.xlsx -File)
    $targetFiles = Pilih-File -FileList $files -Jenis "Excel (.xlsx)"
    if (-not $targetFiles) { return }
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    
    for ($i = 0; $i -lt $targetFiles.Count; $i++) {
        $file = $targetFiles[$i]
        $outPath = Join-Path $hasilDir ($file.BaseName + ".pdf")
        Tampilkan-Progress -Current ($i+1) -Total $targetFiles.Count -Pesan "Mengonversi Excel: $($file.Name)"
        $wb = $excel.Workbooks.Open($file.FullName)
        $wb.ExportAsFixedFormat(0, $outPath)
        $wb.Close($false)
    }
    $excel.Quit()
}

function Convert-FotoToPDF {
    $files = @(Get-ChildItem -Path $proyekDir -File | Where-Object { $_.Extension -match "(?i)\.(jpg|jpeg|png|bmp|gif|tiff)$" })
    $targetFiles = Pilih-File -FileList $files -Jenis "Gambar (Multi-Format)"
    if (-not $targetFiles) { return }
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    
    for ($i = 0; $i -lt $targetFiles.Count; $i++) {
        $file = $targetFiles[$i]
        $outPath = [string](Join-Path $hasilDir ("Foto_" + $file.BaseName + ".pdf"))
        Tampilkan-Progress -Current ($i+1) -Total $targetFiles.Count -Pesan "Mengonversi Gambar: $($file.Name)"
        $doc = $word.Documents.Add()
        $selection = $word.Selection
        $selection.InlineShapes.AddPicture($file.FullName) | Out-Null
        $doc.SaveAs2($outPath, 17)
        $doc.Close($false)
    }
    $word.Quit()
}

# ==========================================
# 2. FITUR PDF KE WORD, GABUNG & PISAH PDF
# ==========================================
function Convert-PDFToWord {
    $files = @(Get-ChildItem -Path $proyekDir -Filter *.pdf -File)
    $targetFiles = Pilih-File -FileList $files -Jenis "PDF (.pdf)"
    if (-not $targetFiles) { return }
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0 
    
    for ($i = 0; $i -lt $targetFiles.Count; $i++) {
        $file = $targetFiles[$i]
        $outPath = [string](Join-Path $hasilDir ($file.BaseName + ".docx"))
        Tampilkan-Progress -Current ($i+1) -Total $targetFiles.Count -Pesan "Mengonversi PDF: $($file.Name)"
        $doc = $word.Documents.Open($file.FullName, $false, $false)
        $doc.SaveAs2($outPath, 16)
        $doc.Close()
    }
    $word.Quit()
}

function Gabung-Word {
    $files = @(Get-ChildItem -Path $proyekDir -Filter *.docx -File | Sort-Object Name)
    $targetFiles = Pilih-File -FileList $files -Jenis "Word (.docx) untuk Digabung"
    if (-not $targetFiles -or $targetFiles.Count -lt 2) { 
        Write-Host "`n[!] Minimal butuh 2 file." -ForegroundColor Red; return 
    }

    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $outPath = Join-Path $hasilDir ("Gabungan_Word_$((Get-Date).ToString('HHmmss')).docx")
    Copy-Item $targetFiles[0].FullName $outPath
    $doc = $word.Documents.Open($outPath)
    $selection = $word.Selection

    for ($i = 1; $i -lt $targetFiles.Count; $i++) {
        Tampilkan-Progress -Current $i -Total ($targetFiles.Count - 1) -Pesan "Menyambungkan: $($targetFiles[$i].Name)"
        $selection.EndKey(6) | Out-Null
        $selection.InsertBreak(7) | Out-Null
        $selection.InsertFile($targetFiles[$i].FullName) | Out-Null
    }
    $doc.Save()
    $doc.Close()
    $word.Quit()
}

function Gabung-PPT {
    $files = @(Get-ChildItem -Path $proyekDir -Filter *.pptx -File | Sort-Object Name)
    $targetFiles = Pilih-File -FileList $files -Jenis "PPT (.pptx) untuk Digabung"
    if (-not $targetFiles -or $targetFiles.Count -lt 2) { 
        Write-Host "`n[!] Minimal butuh 2 file." -ForegroundColor Red; return 
    }

    $ppt = New-Object -ComObject PowerPoint.Application
    $outPath = Join-Path $hasilDir ("Gabungan_PPT_$((Get-Date).ToString('HHmmss')).pptx")
    Copy-Item $targetFiles[0].FullName $outPath
    $presentation = $ppt.Presentations.Open($outPath, $null, $null, $false)

    for ($i = 1; $i -lt $targetFiles.Count; $i++) {
        Tampilkan-Progress -Current $i -Total ($targetFiles.Count - 1) -Pesan "Menyambungkan: $($targetFiles[$i].Name)"
        $presentation.Slides.InsertFromFile($targetFiles[$i].FullName, $presentation.Slides.Count) | Out-Null
    }
    $presentation.Save()
    $presentation.Close()
    $ppt.Quit()
}

function Gabung-PDF {
    $files = @(Get-ChildItem -Path $proyekDir -Filter *.pdf -File | Sort-Object Name)
    $targetFiles = Pilih-File -FileList $files -Jenis "PDF (.pdf) untuk Digabung"
    if (-not $targetFiles -or $targetFiles.Count -lt 2) {
        Write-Host "`n[!] Minimal butuh 2 file PDF." -ForegroundColor Red; return
    }

    if (-not (Siapkan-iTextSharp)) { return }

    $dllPath = Join-Path $alatBantuDir "itextsharp.dll"
    $bcPath  = Join-Path $alatBantuDir "BouncyCastle.Crypto.dll"
    
    try {
        Unblock-File -Path $bcPath -ErrorAction SilentlyContinue
        $bcBytes = [System.IO.File]::ReadAllBytes($bcPath)
        [System.Reflection.Assembly]::Load($bcBytes) | Out-Null

        Unblock-File -Path $dllPath -ErrorAction SilentlyContinue
        $dllBytes = [System.IO.File]::ReadAllBytes($dllPath)
        [System.Reflection.Assembly]::Load($dllBytes) | Out-Null
    } 
    catch { 
        Write-Host "`n[x] Gagal memuat DLL. Hapus file itextsharp.dll dan BouncyCastle.Crypto.dll lalu jalankan ulang." -ForegroundColor Red
        return 
    }

    $outPath = Join-Path $hasilDir ("Gabungan_PDF_$((Get-Date).ToString('HHmmss')).pdf")
    
    $fileStream = New-Object System.IO.FileStream($outPath, [System.IO.FileMode]::Create)
    $document = New-Object iTextSharp.text.Document
    $pdfCopy = New-Object iTextSharp.text.pdf.PdfCopy($document, $fileStream)
    $document.Open()

    for ($i = 0; $i -lt $targetFiles.Count; $i++) {
        Tampilkan-Progress -Current ($i+1) -Total $targetFiles.Count -Pesan "Menggabungkan: $($targetFiles[$i].Name)"
        $reader = New-Object iTextSharp.text.pdf.PdfReader($targetFiles[$i].FullName)
        $pdfCopy.AddDocument($reader)
        $reader.Close()
    }

    $pdfCopy.Close()
    $document.Close()
    $fileStream.Close()
}

function Pisah-PDF {
    $files = @(Get-ChildItem -Path $proyekDir -Filter *.pdf -File)
    $targetFiles = Pilih-File -FileList $files -Jenis "PDF (.pdf) untuk Dipisah"
    if (-not $targetFiles) { return }

    if (-not (Siapkan-iTextSharp)) { return }

    $dllPath = Join-Path $alatBantuDir "itextsharp.dll"
    $bcPath  = Join-Path $alatBantuDir "BouncyCastle.Crypto.dll"
    
    try {
        Unblock-File -Path $bcPath -ErrorAction SilentlyContinue
        $bcBytes = [System.IO.File]::ReadAllBytes($bcPath)
        [System.Reflection.Assembly]::Load($bcBytes) | Out-Null

        Unblock-File -Path $dllPath -ErrorAction SilentlyContinue
        $dllBytes = [System.IO.File]::ReadAllBytes($dllPath)
        [System.Reflection.Assembly]::Load($dllBytes) | Out-Null
    } 
    catch { 
        Write-Host "`n[x] Gagal memuat DLL. Hapus file itextsharp.dll dan BouncyCastle.Crypto.dll lalu jalankan ulang." -ForegroundColor Red
        return 
    }

    foreach ($file in $targetFiles) {
        $reader = New-Object iTextSharp.text.pdf.PdfReader($file.FullName)
        $totalPages = $reader.NumberOfPages

        Write-Host "`n=== PROSES PISAH: $($file.Name) ===" -ForegroundColor Yellow
        Write-Host "Total Halaman: $totalPages" -ForegroundColor Cyan
        
        $pagesInput = Read-Host "Masukkan halaman (contoh: 1,3,5-10) atau ketik '0' untuk Batal"
        if ($pagesInput -eq '0' -or [string]::IsNullOrWhiteSpace($pagesInput)) { 
            $reader.Close(); continue 
        }

        $pageList = @()
        foreach ($part in ($pagesInput -split ',')) {
            $part = $part.Trim()
            if ($part -match '^(\d+)-(\d+)$') {
                $start = [int]$matches[1]; $end = [int]$matches[2]
                if ($start -le $end) { for ($p = $start; $p -le $end; $p++) { $pageList += $p } }
                else { for ($p = $start; $p -ge $end; $p--) { $pageList += $p } }
            } elseif ($part -match '^\d+$') {
                $pageList += [int]$part
            }
        }

        $pageList = $pageList | Where-Object { $_ -ge 1 -and $_ -le $totalPages } | Select-Object -Unique

        if ($pageList.Count -eq 0) { 
            Write-Host "[!] Format halaman tidak valid atau di luar jangkauan." -ForegroundColor Red
            $reader.Close(); continue 
        }

        $outPath = Join-Path $hasilDir ("Pisahan_$($file.BaseName)_$((Get-Date).ToString('HHmmss')).pdf")
        $fileStream = New-Object System.IO.FileStream($outPath, [System.IO.FileMode]::Create)
        $document = New-Object iTextSharp.text.Document
        $pdfCopy = New-Object iTextSharp.text.pdf.PdfCopy($document, $fileStream)
        $document.Open()

        for ($i = 0; $i -lt $pageList.Count; $i++) {
            Tampilkan-Progress -Current ($i+1) -Total $pageList.Count -Pesan "Mengekstrak Halaman $($pageList[$i])"
            $importedPage = $pdfCopy.GetImportedPage($reader, $pageList[$i])
            $pdfCopy.AddPage($importedPage)
        }

        $pdfCopy.Close()
        $document.Close()
        $fileStream.Close()
        $reader.Close()
    }
}

# ==========================================
# 3. FITUR MEDIA (MULTI-FORMAT & FIXED DETEKSI)
# ==========================================
function Convert-VideoToAudio {
    $files = @(Get-ChildItem -Path $proyekDir -File | Where-Object { $_.Extension -match "(?i)\.(mp4|mkv|avi|mov|wmv|flv|webm)$" })
    $targetFiles = Pilih-File -FileList $files -Jenis "Video (Multi-Format)"
    if (-not $targetFiles -or -not (Siapkan-FFmpeg)) { return }
    $ffmpegExe = Join-Path $alatBantuDir "ffmpeg.exe"
    
    for ($i = 0; $i -lt $targetFiles.Count; $i++) {
        $file = $targetFiles[$i]
        $outPath = Join-Path $hasilDir ($file.BaseName + ".mp3")
        Tampilkan-Progress -Current ($i+1) -Total $targetFiles.Count -Pesan "Mengekstrak suara: $($file.Name)"
        Start-Process $ffmpegExe -ArgumentList "-y -i `"$($file.FullName)`" -q:a 0 -map a `"$outPath`"" -NoNewWindow -Wait
    }
}

function Convert-AudioToVideo {
    $files = @(Get-ChildItem -Path $proyekDir -File | Where-Object { $_.Extension -match "(?i)\.(mp3|wav|aac|acc|flac|ogg|m4a|wma)$" })
    $targetFiles = Pilih-File -FileList $files -Jenis "Audio (Multi-Format)"
    if (-not $targetFiles -or -not (Siapkan-FFmpeg)) { return }
    $ffmpegExe = Join-Path $alatBantuDir "ffmpeg.exe"
    
    for ($i = 0; $i -lt $targetFiles.Count; $i++) {
        $file = $targetFiles[$i]
        $outPath = Join-Path $hasilDir ("Video_" + $file.BaseName + ".mp4")
        Tampilkan-Progress -Current ($i+1) -Total $targetFiles.Count -Pesan "Membuat Video: $($file.Name)"
        Start-Process $ffmpegExe -ArgumentList "-y -f lavfi -i color=c=black:s=1280x720 -i `"$($file.FullName)`" -c:v libx264 -c:a aac -shortest `"$outPath`"" -NoNewWindow -Wait
    }
}

function Gabung-Media {
    param([string]$TipeMedia)
    if ($TipeMedia -eq "Video") {
        $files = @(Get-ChildItem -Path $proyekDir -File | Where-Object { $_.Extension -match "(?i)\.(mp4|mkv|avi|mov|wmv|flv|webm)$" } | Sort-Object Name)
        $targetFiles = Pilih-File -FileList $files -Jenis "Video (Multi-Format) untuk Digabung"
        $ext = ".mp4"
    } else {
        $files = @(Get-ChildItem -Path $proyekDir -File | Where-Object { $_.Extension -match "(?i)\.(mp3|wav|aac|acc|flac|ogg|m4a|wma)$" } | Sort-Object Name)
        $targetFiles = Pilih-File -FileList $files -Jenis "Audio (Multi-Format) untuk Digabung"
        $ext = ".mp3"
    }
    
    if (-not $targetFiles -or $targetFiles.Count -lt 2) { 
        Write-Host "`n[!] Minimal butuh 2 file untuk digabung." -ForegroundColor Red; return 
    }
    if (-not (Siapkan-FFmpeg)) { return }

    $listPath = Join-Path $proyekDir "list.txt"
    $outPath = Join-Path $hasilDir ("Gabungan_$((Get-Date).ToString('HHmmss'))$ext")
    
    Clear-Content $listPath -ErrorAction SilentlyContinue
    foreach ($file in $targetFiles) { Add-Content -Path $listPath -Value "file '$($file.Name)'" }

    if ($TipeMedia -eq "Video") {
        $ffmpegArgs = "-y -f concat -safe 0 -i `"$listPath`" -c copy `"$outPath`""
    } else {
        $ffmpegArgs = "-y -f concat -safe 0 -i `"$listPath`" -c:a libmp3lame -b:a 192k `"$outPath`""
    }

    Write-Host "`n[*] Sedang menggabungkan mesin render (FFmpeg sedang bekerja, mohon tunggu)..." -ForegroundColor Cyan
    $ffmpegExe = Join-Path $alatBantuDir "ffmpeg.exe"
    Start-Process $ffmpegExe -ArgumentList $ffmpegArgs -NoNewWindow -Wait
    Remove-Item $listPath
    Write-Host "[v] Selesai! Hasil ada di folder 'Hasil'`n" -ForegroundColor Green
}

# --- MENU UTAMA ---
while ($true) {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "   ULTIMATE CONVERTER & MERGER V11      " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Folder Output: $hasilDir"
    Write-Host "Folder Bahan : $proyekDir"
    Write-Host "  -- KONVERSI DOKUMEN & FOTO --"
    Write-Host "  1. Word ke PDF"
    Write-Host "  2. PPT ke PDF"
    Write-Host "  3. Excel ke PDF"
    Write-Host "  4. Semua Gambar ke PDF"
    Write-Host "  5. PDF ke Word (Edit PDF)"
    Write-Host "  -- GABUNG & PISAH DOKUMEN --"
    Write-Host "  6. Gabungkan Word"
    Write-Host "  7. Gabungkan PPT"
    Write-Host "  8. Gabungkan PDF"
    Write-Host "  9. Pisah PDF (Ambil Halaman Tertentu)"
    Write-Host "  -- MEDIA (AUDIO/VIDEO) --"
    Write-Host " 10. Semua Video ke Suara (MP3)"
    Write-Host " 11. Semua Suara ke Video (MP4)"
    Write-Host " 12. Gabungkan Suara"
    Write-Host " 13. Gabungkan Video"
    Write-Host "  0. Keluar"
    Write-Host "========================================" -ForegroundColor Yellow
    
    $pilihan = Read-Host "Masukkan pilihan Anda (0-13)"

    switch ($pilihan) {
        '1' { Convert-WordToPDF; pause }
        '2' { Convert-PPTToPDF; pause }
        '3' { Convert-ExcelToPDF; pause }
        '4' { Convert-FotoToPDF; pause }
        '5' { Convert-PDFToWord; pause }
        '6' { Gabung-Word; pause }
        '7' { Gabung-PPT; pause }
        '8' { Gabung-PDF; pause }
        '9' { Pisah-PDF; pause }
        '10' { Convert-VideoToAudio; pause }
        '11' { Convert-AudioToVideo; pause }
        '12' { Gabung-Media -TipeMedia "Audio"; pause }
        '13' { Gabung-Media -TipeMedia "Video"; pause }
        '0' { exit }
        default { Write-Host "Pilihan tidak valid!" -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
}