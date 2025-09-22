@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 身份证图片下载脚本
:: 用法: download_id_cards.bat
:: 自动检测当前文件夹中的CSV文件
:: CSV格式: 工号,姓名,图片地址

echo ========================================
echo 身份证图片下载脚本
echo ========================================

:: 查找当前目录下的CSV文件
set csv_count=0
set csv_files=

for %%f in (*.csv) do (
    set /a csv_count+=1
    if "!csv_files!" equ "" (
        set csv_files=%%f
    ) else (
        set csv_files=!csv_files! %%f
    )
)

:: 检查是否找到CSV文件
if !csv_count! equ 0 (
    echo 错误: 当前目录下没有找到CSV文件
    echo 请确保当前目录下有CSV文件
    pause
    exit /b 1
)

:: 显示找到的CSV文件
if !csv_count! equ 1 (
    echo 找到1个CSV文件: !csv_files!
else (
    echo 找到!csv_count!个CSV文件: !csv_files!
)

:: 创建输出目录
set output_dir=id_cards_download
if not exist "!output_dir!" mkdir "!output_dir!"

echo 开始批量处理CSV文件
echo 输出目录: !output_dir!
echo.

:: 检查curl命令是否可用
curl --version > nul 2>&1
if errorlevel 1 (
    echo 错误: 系统中未找到curl命令
    echo 请确保Windows 10版本1803及以上，或手动安装curl
    pause
    exit /b 1
)

:: 循环处理所有CSV文件
for %%f in (*.csv) do (
    call :process_csv "%%f"
)

echo ========================================
echo 所有CSV文件处理完成！文件已保存到 !output_dir! 目录中
echo ========================================
pause
goto :eof

:process_csv
set current_csv=%~1
echo ========================================
echo 正在处理CSV文件: !current_csv!
echo ========================================

:: 首先读取CSV文件的表头来获取图片类型名称
set header_line=
for /f "usebackq tokens=1-3 delims=," %%a in ("!current_csv!") do (
    set header1=%%a
    set header2=%%b
    set header3=%%c
    goto :break_header
)
:break_header

:: 清理表头中的引号和空格
set header1=!header1:"=!
set header1=!header1: =!
set header2=!header2:"=!
set header2=!header2: =!
set header3=!header3:"=!
set header3=!header3: =!

echo 检测到的列名: !header1!, !header2!, !header3!
echo.

:: 处理CSV文件，跳过第一行标题行
set line_num=0
for /f "usebackq skip=1 tokens=1-3 delims=," %%a in ("!current_csv!") do (
    set /a line_num+=1
    
    :: 去除引号和空格
    set job_id=%%a
    set name=%%b
    set image_url=%%c
    
    :: 清理字段中的引号和空格
    set job_id=!job_id:"=!
    set job_id=!job_id: =!
    set name=!name:"=!
    set name=!name: =!
    set image_url=!image_url:"=!
    
    :: 跳过空行
    if "!name!" neq "" (
        echo 处理: !name! ^(工号: !job_id!^)
        
        :: 创建以工号_姓名命名的文件夹
        set person_dir=!output_dir!\!job_id!_!name!
        if not exist "!person_dir!" mkdir "!person_dir!"
        
        :: 下载文件
        if "!image_url!" neq "" (
            echo   下载!header3!...
            
            :: 获取文件扩展名
            for %%x in (!image_url!) do (
                set temp_ext=%%~xx
                set temp_ext=!temp_ext:~1!
            )
            rem 如果 URL 没有扩展名，就默认用 bin
            if "!temp_ext!"=="" set "temp_ext=bin"
            set img_filename=!name!_!header3!.!temp_ext!
            curl -L -o "!person_dir!\!img_filename!" "!image_url!" > nul 2>&1
            if !errorlevel! equ 0 (
                echo     ✓ !header3!下载成功: !img_filename!
            ) else (
                echo     ✗ !header3!下载失败: !image_url!
            )
        ) else (
            echo     - !header3!URL为空，跳过
        )
        
        echo.
    )
)

echo CSV文件 !current_csv! 处理完成！
echo.
goto :eof