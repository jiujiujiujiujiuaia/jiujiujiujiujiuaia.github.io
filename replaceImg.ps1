param(
    [string]$filename,    # 给定文件的文件名
    [string]$oldText = "(img",        # 目标替换的字符
    [string]$imageFolder,      # 替换的字符
    [string]$comments = ""
)

TODO 1.把所有img移动到一个新的目录 2.更新本地的时间或者文件的时间 3.脚本有多个模式 提交代码 替换图片 替换文章时间等等模块，可以自由的组合

# 基础路径
$baseFilePath = "\_posts\"
$currentDirectory = $pwd.Path
$fullFilePath = Join-Path $currentDirectory $baseFilePath
# 构造完整文件路径
$fullFilePath = Join-Path $fullFilePath $filename

# 确保文件存在
if (-not (Test-Path $fullFilePath)) {
    Write-Error "file $fullFilePath doesn't exsit!"
    exit
}

# 替换 {placeholder} 变量
$templateUrl = "(https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/{placeholder}/img"
$content = $templateUrl.Replace("{placeholder}", $imageFolder)

# 读取文件内容并替换文本
$fileContent = Get-Content $fullFilePath -Raw -Encoding utf8
$fileContent = $fileContent.Replace($oldText, $content)

# 写入修改后的内容回文件
$fileContent | Set-Content $fullFilePath -Encoding utf8

Write-Output "file $fullFilePath has been replaced!"

if ($comments -ne "") {
   git add .
   git commit -m $comments
   git push
   Write-Output "push with $comments"
}


