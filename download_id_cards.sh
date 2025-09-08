#!/bin/bash

# 身份证图片下载脚本
# 用法: ./download_id_cards.sh
# 自动检测当前文件夹中的CSV文件
# CSV格式: 工号,姓名,图片地址

echo "========================================"
echo "身份证图片下载脚本"
echo "========================================"

# 查找当前目录下的CSV文件
CSV_FILES=(*.csv)
CSV_COUNT=0

# 检查CSV文件
for file in "${CSV_FILES[@]}"; do
    if [ -f "$file" ]; then
        ((CSV_COUNT++))
    fi
done

# 检查是否找到CSV文件
if [ $CSV_COUNT -eq 0 ]; then
    echo "错误: 当前目录下没有找到CSV文件"
    echo "请确保当前目录下有CSV文件"
    exit 1
fi

# 显示找到的CSV文件
if [ $CSV_COUNT -eq 1 ]; then
    echo "找到1个CSV文件: ${CSV_FILES[0]}"
else
    echo "找到${CSV_COUNT}个CSV文件: ${CSV_FILES[*]}"
fi

# 创建输出目录
OUTPUT_DIR="id_cards_download"
mkdir -p "$OUTPUT_DIR"

echo "开始批量处理CSV文件"
echo "输出目录: $OUTPUT_DIR"
echo

# 检查curl命令是否可用
if ! command -v curl &> /dev/null; then
    echo "错误: 系统中未找到curl命令"
    echo "请安装curl: brew install curl (macOS) 或 apt-get install curl (Ubuntu)"
    exit 1
fi

# 处理CSV文件的函数
process_csv() {
    local current_csv="$1"
    echo "========================================"
    echo "正在处理CSV文件: $current_csv"
    echo "========================================"
    
    # 首先读取CSV文件的表头来获取图片类型名称
    IFS=',' read -r header1 header2 header3 < "$current_csv"
    
    # 清理表头中的引号和空格
    header1=$(echo "$header1" | sed 's/^[[:space:]]*"*//;s/"*[[:space:]]*$//')
    header2=$(echo "$header2" | sed 's/^[[:space:]]*"*//;s/"*[[:space:]]*$//')
    header3=$(echo "$header3" | sed 's/^[[:space:]]*"*//;s/"*[[:space:]]*$//')
    
    echo "检测到的列名: $header1, $header2, $header3"
    echo
    
    # 处理CSV文件，跳过第一行标题行
    local line_num=0
    tail -n +2 "$current_csv" | while IFS=',' read -r job_id name image_url; do
        ((line_num++))
        
        # 去除字段两端的空格和引号
        job_id=$(echo "$job_id" | sed 's/^[[:space:]]*"*//;s/"*[[:space:]]*$//')
        name=$(echo "$name" | sed 's/^[[:space:]]*"*//;s/"*[[:space:]]*$//')
        image_url=$(echo "$image_url" | sed 's/^[[:space:]]*"*//;s/"*[[:space:]]*$//')
        
        # 跳过空行
        if [ -z "$name" ]; then
            continue
        fi
        
        echo "处理: $name (工号: $job_id)"
        
        # 创建以工号_姓名命名的文件夹
        person_dir="$OUTPUT_DIR/${job_id}_${name}"
        mkdir -p "$person_dir"
        
        # 下载图片
        if [ -n "$image_url" ]; then
            echo "  下载${header3}..."
            
            # 获取文件扩展名
            img_ext=$(echo "$image_url" | sed 's/.*\.//')
            if [[ ! "$img_ext" =~ ^(jpg|jpeg|png|gif|bmp)$ ]]; then
                img_ext="jpg"
            fi
            
            img_filename="${name}_${header3}.${img_ext}"
            if curl -L -o "$person_dir/$img_filename" "$image_url" 2>/dev/null; then
                echo "    ✓ ${header3}下载成功: $img_filename"
            else
                echo "    ✗ ${header3}下载失败: $image_url"
            fi
        else
            echo "    - ${header3}URL为空，跳过"
        fi
        
        echo
    done
    
    echo "CSV文件 $current_csv 处理完成！"
    echo
}

# 循环处理所有CSV文件
for csv_file in *.csv; do
    if [ -f "$csv_file" ]; then
        process_csv "$csv_file"
    fi
done

echo "========================================"
echo "所有CSV文件处理完成！文件已保存到 $OUTPUT_DIR 目录中"
echo "========================================"