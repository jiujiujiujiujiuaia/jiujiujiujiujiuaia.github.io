#!/bin/bash

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

    fileName=$(basename "$matchingFiles")
    fullFilePath="$fullFilePath$fileName"
    echo "the full file name is: $fullFilePath"
    echo "the file name is: $fileName"

    # Construct replacement content
    newContent="(https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/$imageFolder/$dateString/img"

    # Ensure file exists
    if [[ ! -f "$fullFilePath" ]]; then
        echo "[Error]File $fullFilePath doesn't exist!"
        return
    fi

    # Read file content and replace text
    echo "Old content: $oldText"
    echo "New content: $newContent"

    # 读取文件内容
    fileContent=$(<"$fullFilePath")

    # 使用 grep 命令统计匹配次数
    occurrencesCount=$(echo "$fileContent" | grep -o -F "$oldText" | wc -l )

    # 使用 sed 命令进行文本替换
    fileContent=$(echo "$fileContent" | sed "s/$oldText/${newContent//\//\\/}/g")

    # 写入修改后的内容到文件
    echo "$fileContent" > "$fullFilePath"
    echo "[Completed] [$fileName] contains [$occurrencesCount] of [$oldText], has been replaced"


}

# Define function to move images to folder
Move_Images_To_Folder() {

    # Determine base path
    baseDir="_posts"
    currentDirectory=$(pwd)
    baseDir="$currentDirectory/$baseDir"

    picDir="$baseDir/pic"
    targetDir="$picDir/$imageFolder/$dateString"

    # Check if target directory exists, if not, create it
    if [[ ! -d "$targetDir" ]]; then
        mkdir -p "$targetDir"
        echo "[Completed] created directory $targetDir"
    fi

    # Find all PNG images
    pngFiles=$(find "$baseDir" -maxdepth 1 -type f -name "*.png")

    for file in $pngFiles; do
        echo "$pngFiles"
        # Build target file path
        targetFile="$targetDir/$(basename "$file")"

        # Check if file already exists in target directory
        if [[ -e "$targetFile" ]]; then
            echo "[Warning] =====$targetFile is existing, please move it manually===="
            continue
        fi

        # Move image to target directory
        mv "$file" "$targetFile"
    done

    imageCount=$(echo -n "$pngFiles" | wc -l )
    echo "[Completed] moving [$imageCount] pictures to pic/$imageFolder"
}

# Define function to submit commit
Submit_Commit() {
    git add .
    git commit -m "$comments"
    git push
    echo "[Completed] Pushed with comments: $comments"
}

# Get current date



#!/bin/bash

# Initialize variables with default values
fileName=""
imageFolder=""
comments=""
oldText="(img"
dateString=$(date +"%Y%m%d%H%M%S")

# Parse command line options
while getopts ":f:i:c:" opt; do
  case ${opt} in
    f )
      fileName="$OPTARG"
      ;;
    i )
      imageFolder="$OPTARG"
      ;;
    c )
      comments="$OPTARG"
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

# Now you can use $filename and $imageFolder variables in your script
echo "===arguments==="
echo "Filename: $fileName"
echo "Image Folder: $imageFolder"
echo "$dateString"
echo ""


# If filename and imageFolder are not empty, execute Replace_Content function
if [[ ! -z "$fileName" && ! -z "$imageFolder" ]]; then
    echo "===move images==="
    Move_Images_To_Folder
    echo ""

    echo "===replace content==="
    Replace_Content
    echo ""
fi

# If comments variable is not empty, execute Submit_Commit function
if [[ ! -z "$comments" ]]; then
    echo "===replace content==="
    Submit_Commit "$comments"
    echo ""
fi

