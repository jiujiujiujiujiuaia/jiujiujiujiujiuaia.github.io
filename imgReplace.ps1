param(
    [Alias('f')] [string]$filename,
    [string]$oldText = "(img",
    [Alias('i')] [string]$imageFolder,
    [Alias('c')] [string]$comments = ""
)

# TODO file name只需要写部分文件名，就可以补全整个文件 2）代码格式写的更好一些 都封装成函数

function Replace-Content {
    param(
        [string]$fileName,
        [string]$imageFolder,
        [string]$dateString,
        [string]$oldText
    )

    # 构造markdown file路径
    $baseFilePath = "_posts\"
    $currentDirectory = $pwd.Path
    $fullFilePath = Join-Path $currentDirectory $baseFilePath
    $matchingFiles = Get-ChildItem -Path $fullFilePath -Filter "*$fileName*"

    if ($matchingFiles.Count -eq 0) {
        Write-Error "No matching files found."
        return
    }elseif ($matchingFiles.Count -gt 1) {
         Write-Error "Multiple matching files found."
         return
    }

    $fileName = $matchingFiles.Name
    $fullFilePath = Join-Path $fullFilePath $fileName
    Write-Host "the file name is:" $fileName

    # 构造替换内容
    $templateUrl = "(https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/main/pic/{placeholder}/{datetime}/img"
    $newContent = $templateUrl.Replace("{placeholder}", $imageFolder)
    $newText = $newContent.Replace("{datetime}", $dateString)

    # 确保文件存在
    if (-not (Test-Path $fullFilePath)) {
        Write-Error "[Error]File $fullFilePath doesn't exist!"
        return
    }

    # 读取文件内容并替换文本
    Write-Output "Old content: $oldText"
    Write-Output "New content: $newText"

    # 使用正则表达式查找 $oldText 在 $fileContent 中出现的次数
    $fileContent = Get-Content $fullFilePath -Raw -Encoding utf8
    $matches = [System.Text.RegularExpressions.Regex]::Matches($fileContent, [regex]::Escape($oldText))
    $occurrencesCount = $matches.Count

    # 替换
    $fileContent = $fileContent.Replace($oldText, $newText)

    # 写入修改后的内容回文件
    $fileContent | Set-Content $fullFilePath -Encoding utf8

    Write-Output "[Completed] [$fileName] contains [$occurrencesCount] of [$oldText], has been replaced"
}

function Move-ImagesToFolder {
    param(
        [string]$imageFolder,
        [string]$dateString
    )

    # 确定基础路径
    $baseDir = "_posts"
    $currentDirectory = $pwd.Path
    $baseDir = Join-Path $currentDirectory $baseDir

    $picDir = Join-Path $baseDir "pic"
    $targetDir = Join-Path $picDir $imageFolder
    $targetDir = Join-Path $targetDir $dateString

    # 检查目标文件夹是否存在，如果不存在则创建
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir  > $null
        Write-Output "[Completed] created directory $targetDir"
    }

    # 查找所有 png 图片
    $pngFiles = Get-ChildItem -Path $baseDir -Filter *.png

    foreach ($file in $pngFiles) {
        # 构建目标文件路径
        $targetFile = Join-Path $targetDir $file.Name

        # 检查目标文件夹中是否存在同名文件
        if (Test-Path $targetFile) {
            Write-Output "[Warning] =====$targetFile is existing, please move it manually===="
            continue
        }

        # 移动图片到目标文件夹
        Move-Item -Path $file.FullName -Destination $targetFile
    }

    $imageCount = $pngFiles.Count
    Write-Output "[Completed] moving [$imageCount] pictures to pic\$imageFolder"
}


function Submit-Commit {
    param(
        [Alias('c')] [string]$comments
    )

    git add .
    git commit -m $comments
    git push
    Write-Output "[Completed] Pushed with comments: $comments"
}

# 获取当前时间
$currentDate = Get-Date

# 格式化时间为 "yyyyMMddHHmmss" 格式
$dateString = $currentDate.ToString("yyyyMMddHHmmss")

# 如果filename不为空，执行字符替换函数
if ($filename -ne "" -and $imageFolder -ne "") {
    Move-ImagesToFolder -imageFolder $imageFolder -dateString $dateString
    Replace-Content -FileName $filename -oldText $oldText -dateString $dateString -imageFolder $imageFolder
}

# 如果comments变量不为空，执行提交commit函数
if ($comments -ne "") {
    Submit-Commit -comments $comments
}
