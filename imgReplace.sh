#!/bin/bash

# Define function to replace content
Replace_Content() {
    local fileName="$1"
    local imageFolder="$2"
    local dateString="$3"
    local oldText="$4"

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
    echo "the file name is: $fileName"

    # Construct replacement content
    templateUrl="(https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/{placeholder}/{datetime}/img"
    newContent=$(echo "$templateUrl" | sed "s/{placeholder}/$imageFolder/g" | sed "s/{datetime}/$dateString/g")

    # Ensure file exists
    if [[ ! -f "$fullFilePath" ]]; then
        echo "[Error]File $fullFilePath doesn't exist!"
        return
    fi

    # Read file content and replace text
    echo "Old content: $oldText"
    echo "New content: $newContent"

    # Replace
    sed -i "s/$(echo "$oldText" | sed 's/[^^]/[&]/g;s/\^/\\^/g')/$newContent/g" "$fullFilePath"

    echo "[Completed] [$fileName] has been replaced"
}

# Define function to move images to folder
Move_Images_To_Folder() {
    local imageFolder="$1"
    local dateString="$2"

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
    pngFiles=$(find "$baseDir" -type f -name "*.png")

    for file in $pngFiles; do
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

    imageCount=$(echo "$pngFiles" | wc -l)
    echo "[Completed] moving [$imageCount] pictures to pic/$imageFolder"
}

# Define function to submit commit
Submit_Commit() {
    local comments="$1"

    git add .
    git commit -m "$comments"
    git push
    echo "[Completed] Pushed with comments: $comments"
}

# Get current date
currentDate=$(date +"%Y%m%d%H%M%S")

# If filename and imageFolder are not empty, execute Replace_Content function
if [[ ! -z "$filename" && ! -z "$imageFolder" ]]; then
    Move_Images_To_Folder "$imageFolder" "$currentDate"
    Replace_Content "$filename" "$imageFolder" "$currentDate" "$oldText"
fi

# If comments variable is not empty, execute Submit_Commit function
if [[ ! -z "$comments" ]]; then
    Submit_Commit "$comments"
fi
