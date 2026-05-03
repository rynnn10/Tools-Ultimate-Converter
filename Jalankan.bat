@echo off
title Ultimate Converter & Merger V4
echo Memulai aplikasi, mohon tunggu sebentar...

:: Menjalankan PowerShell dengan ukuran standar (tidak dipaksa Maximized)
:: agar tidak berat dan scroll/copy berfungsi normal.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tool.ps1"