#!/bin/bash

# Define help function
Print_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -a <articleName>   Create a new article with the specified name"
  echo "  -u                 Insert a timestamped idea into the specified file"
  echo "  -e                 Toggle English mode (used with -u): 2026-01-11-TalkPal记录.md"
  echo "  -f <fileName>      Specify the file name to be used for content replacement"
  echo "  -i <imageFolder>   Specify the image folder for content replacement"
  echo "  -c <comments>      Submit a git commit with the specified comments"
  echo "  -v, -vscode        In vscode, the image path is different with IDEA"
  echo "  -h, -help          Display this help message"
}

Create_article(){
    # 获取当前日期和时间
    current_date=$(date '+%Y-%m-%d')
    current_time=$(date '+%Y-%m-%d %H:%M:%S')

    # 设置文件名和路径
    baseDir="_posts"
    currentDirectory=$(pwd)
    fullFileName="${current_date}-$articleName.md"
    targetPath="$currentDirectory/$baseDir/$fullFileName"

    content="--- \ntitle: $articleName\ndate: $current_time\ncategories:\n- \n---\n\n# 前言 \n\n# Reference"

    touch "$targetPath"
    echo -e "$content" >> "$targetPath"
    echo "[Completed] Article created: $fullFileName"
}

Insert_idea() {
  baseDir="_posts"
  currentDirectory=$(pwd)
  current_date=$(date '+%Y-%m-%d')

  # 根据 -e 参数决定文件名
  if [[ "$isEnglish" == "true" ]]; then
    # 模式：2026-01-11-TalkPal记录.md
    fileName="2026-01-11-TalkPal记录.md"
  else
    # 默认模式
    fileName="2030-12-05-想法.md"
  fi

  fullFilePath="$currentDirectory/$baseDir/$fileName"

  # 获取当前时间（中国时区）
  CURRENT_TIME=$(TZ='Asia/Shanghai' date '+%Y/%m/%d %H:%M')

  # 定义要插入的内容
  TEXT_TO_INSERT="\n## $CURRENT_TIME\n"

  # 如果文件不存在则先创建（防止报错）
  if [[ ! -f "$fullFilePath" ]]; then
      touch "$fullFilePath"
      echo "[Info] Created new file: $fileName"
  fi

  # 向文件末尾追加内容
  echo -e "$TEXT_TO_INSERT" >> "$fullFilePath"
  echo "[Completed] Inserted timestamp into $fileName"
}

# Define function to replace content
Replace_Content() {
    # Construct markdown file path
    baseFilePath="_posts/"
    currentDirectory=$(pwd)
    fullFilePath="$currentDirectory/$baseFilePath"
    matchingFiles=$(find "$fullFilePath" -type f -name "*$fileName*")

    if [[ $(echo "$matchingFiles" | wc -l) -eq 0 ]]; then
        echo "No matching files found."
        return
    elif [[ $(echo "$matchingFiles" | wc -l) -gt 1 ]]; then
        echo "Multiple matching files found."
        return
    fi

    actualFileName=$(basename "$matchingFiles")
    fullFilePath="$currentDirectory/$baseFilePath$actualFileName"
    echo "the full file name is: $fullFilePath"
    echo "the file name is: $actualFileName"

    # Construct replacement content
    newContent="(https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/main/pic/$imageFolder/$dateString/${oldText:1}"

    # Ensure file exists
    if [[ ! -f "$fullFilePath" ]]; then
        echo "[Error] File $fullFilePath doesn't exist!"
        return
    fi

    # Read file content and replace text
    echo "Old content: $oldText"
    echo "New content: $newContent"

    fileContent=$(<"$fullFilePath")
    occurrencesCount=$(expr $(echo "$fileContent" | grep -o -F "$oldText" | wc -l) - 1)

    # 使用 sed 命令进行文本替换
    fileContent=$(echo "$fileContent" | sed "s/$oldText/${newContent//\//\\/}/g")

    # 写入修改后的内容到文件
    echo "$fileContent" > "$fullFilePath"
    echo "[Completed] [$actualFileName] contains [$occurrencesCount] of [$oldText], has been replaced"
}

# Define function to move images to folder
Move_Images_To_Folder() {
    baseDir="_posts"
    currentDirectory=$(pwd)
    baseDir="$currentDirectory/$baseDir"

    picDir="$baseDir/pic"
    targetDir="$picDir/$imageFolder/$dateString"

    if [[ ! -d "$targetDir" ]]; then
        mkdir -p "$targetDir"
        echo "[Completed] created directory $targetDir"
    fi

    pngFiles=$(find "$baseDir" -maxdepth 1 -type f -name "*.png")

    for file in $pngFiles; do
        targetFile="$targetDir/$(basename "$file")"
        if [[ -e "$targetFile" ]]; then
            echo "[Warning] =====$targetFile is existing, please move it manually===="
            continue
        fi
        mv "$file" "$targetFile"
    done

    imageCount=$(echo "$pngFiles" | grep -v '^$' | wc -l)
    echo "[Completed] moving [$imageCount] pictures to pic/$imageFolder"
}

# Define function to submit commit
Submit_Commit() {
    git add .
    git commit -m "$comments"
    git push
    echo "[Completed] Pushed with comments: $comments"
}

# --- Main Script Start ---

# Initialize variables
fileName=""
articleName=""
imageFolder=""
comments=""
oldText="(img"
isEnglish="false"
dateString=$(date +"%Y%m%d%H%M%S")

# Parse command line options
while getopts ":f:i:c:vuea:h" opt; do
  case ${opt} in
    a )
      articleName="$OPTARG"
      ;;
    u )
      idea="insert idea"
      ;;
    e )
      isEnglish="true"
      ;;
    v )
      oldText="(image"
      ;;
    f )
      fileName="$OPTARG"
      ;;
    i )
      imageFolder="$OPTARG"
      ;;
    c )
      comments="$OPTARG"
      ;;
    h )
      Print_help
      exit 0
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Option -$OPTARG requires an argument." 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Execution Logic
if [[ ! -z "$fileName" && ! -z "$imageFolder" ]]; then
    echo "===arguments==="
    echo "Filename: $fileName"
    echo "Image Folder: $imageFolder"
    echo "Date String: $dateString"
    echo ""

    echo "===move images==="
    Move_Images_To_Folder
    echo ""

    echo "===replace content==="
    Replace_Content
    echo ""
fi

if [[ ! -z "$comments" ]]; then
    echo "===git push==="
    Submit_Commit
    echo ""
fi

if [[ ! -z "$idea" ]]; then
    echo "===insert idea time stamp==="
    Insert_idea
    echo ""
fi

if [[ ! -z "$articleName" ]]; then
    echo "===create new article==="
    Create_article
    echo ""
fi