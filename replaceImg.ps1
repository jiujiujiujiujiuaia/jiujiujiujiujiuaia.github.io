param(
    [Alias('f')] [string]$filename,
    [string]$oldText = "(img",
    [Alias('i')] [string]$imageFolder,
    [Alias('c')] [string]$comments = ""
)

function Replace-Content {
    param(
        [string]$filePath,
        [string]$oldText,
        [string]$newText
    )

    # 确保文件存在
    if (-not (Test-Path $filePath)) {
        Write-Error "[Error]File $filePath doesn't exist!"
        return
    }

    # 读取文件内容并替换文本
    Write-Output "Old content: $oldText"
    Write-Output "New content: $newText"

    $fileContent = Get-Content $filePath -Raw -Encoding utf8
    $fileContent = $fileContent.Replace($oldText, $newText)

    # 写入修改后的内容回文件
    $fileContent | Set-Content $filePath -Encoding utf8

    Write-Output "[Completed] File $filePath has been replaced!"
}

function Move-ImagesToFolder {
    param(
        [string]$imageFolder
    )

    # 确定基础路径
    $baseDir = "_posts"
    $currentDirectory = $pwd.Path
    $baseDir = Join-Path $currentDirectory $baseDir

    $picDir = Join-Path $baseDir "pic"
    $targetDir = Join-Path $picDir $imageFolder

    # 检查目标文件夹是否存在，如果不存在则创建
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir
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

    Write-Output "[Completed] moving pictures to pic\$imageFolder"
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

# 基础路径
$baseFilePath = "_posts\"
$currentDirectory = $pwd.Path
$fullFilePath = Join-Path $currentDirectory $baseFilePath
$fullFilePath = Join-Path $fullFilePath $filename

# 构造替换内容
$templateUrl = "(https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/{placeholder}/img"
$newContent = $templateUrl.Replace("{placeholder}", $imageFolder)

# 如果filename不为空，执行字符替换函数
if ($filename -ne "" -and $imageFolder -ne "") {
    Move-ImagesToFolder -imageFolder $imageFolder
    Replace-Content -filePath $fullFilePath -oldText $oldText -newText $newContent
}

# 如果comments变量不为空，执行提交commit函数
if ($comments -ne "") {
    Submit-Commit -comments $comments
}
