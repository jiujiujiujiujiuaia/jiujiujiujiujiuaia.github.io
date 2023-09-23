param(
    [Alias('f')] [string]$filename,
    [string]$oldText = "(img",
    [Alias('image')] [string]$imageFolder,
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
        Write-Error "File $filePath doesn't exist!"
        return
    }

    # 读取文件内容并替换文本
    Write-Output "Old content: $oldText"
    Write-Output "New content: $newText"

    $fileContent = Get-Content $filePath -Raw -Encoding utf8
    $fileContent = $fileContent.Replace($oldText, $newText)

    # 写入修改后的内容回文件
    $fileContent | Set-Content $filePath -Encoding utf8

    Write-Output "File $filePath has been replaced!"
}

function Submit-Commit {
    param(
        [Alias('c')] [string]$comments
    )

    git add .
    git commit -m $comments
    git push
    Write-Output "Pushed with comments: $comments"
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
if ($filename -ne "") {
    Replace-Content -filePath $fullFilePath -oldText $oldText -newText $newContent
}

# 如果comments变量不为空，执行提交commit函数
if ($comments -ne "") {
    Submit-Commit -comments $comments
}
