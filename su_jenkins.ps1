# 检查是否以管理员权限运行
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "请以管理员权限运行此脚本！"
    exit 1
}

# 定义 sudoers 文件路径
$sudoersPath = "/etc/sudoers"
$backupPath = "/etc/sudoers.bak"

# SSH 连接信息
$sshHost = "http://localhost:8080"
$sshUser = "root"
$sshKeyPath = "/var/jenkins_home/.ssh/id_rsa"

# 使用 SSH 执行远程命令
# 修改 commands 变量，添加用户检查
$commands = @"
# 检查当前用户
echo "Current user: \$(whoami)"

# 检查 sudoers 文件是否存在
if [ ! -f $sudoersPath ]; then
    echo 'Error: sudoers file not found!'
    exit 1
fi

# 创建备份
sudo cp $sudoersPath $backupPath

# 为当前用户添加配置
CURRENT_USER=\$(whoami)
if ! sudo grep -q "\$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/apt-get" $sudoersPath; then
    # 添加新配置
    echo "\$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/apt-get" | sudo EDITOR='tee -a' visudo
fi

# 验证 sudoers 文件语法
sudo visudo -c

# 测试权限
sudo apt-get update --dry-run
"@

# 使用 ssh 执行远程命令
try {
    ssh -i $sshKeyPath "${sshUser}@${sshHost}" $commands
    Write-Host "成功更新 sudoers 文件！" -ForegroundColor Green
}
catch {
    Write-Error "更新 sudoers 文件时发生错误：$($_.Exception.Message)"
    exit 1
}
function Get-JenkinsContainer {
    $containerName = docker ps --format "{{.Names}}\t{{.Image}}" | Where-Object {
        $_ -match '\tjenkins/jenkins([:@]|$)'
    } | Select-Object -First 1 | ForEach-Object {
        ($_ -split '\t')[0]
    }
    if (-not $containerName) {
        Write-Host "错误：未找到基于 'jenkins/jenkins' 镜像的运行中的容器。" -ForegroundColor Red
        return $null # 或者返回 null，让调用者处理
    }
    Write-Host "找到 Jenkins 容器: $containerName" -ForegroundColor Green
    return $containerName
}
# 获取 Jenkins 容器名称
$JENKINS_CONTAINER = Get-JenkinsContainer

# SSH 连接信息
$sshHost = "localhost"  # 移除 http:// 和端口号
$sshUser = "root"
$tempKeyPath = Join-Path $env:TEMP "jenkins_temp_key"  # 使用临时目录

# 从 Jenkins 容器复制私钥到临时目录
try {
    # 确保临时文件不存在
    if (Test-Path $tempKeyPath) {
        Remove-Item $tempKeyPath -Force
    }

    docker cp "${JENKINS_CONTAINER}:/var/jenkins_home/.ssh/id_rsa" $tempKeyPath
    # 设置适当的权限
    icacls $tempKeyPath /inheritance:r
    icacls $tempKeyPath /grant:r "$($env:USERNAME):(F)"  # 给予完全控制权限
    
    # 使用 SSH 执行远程命令（使用特定端口）
    ssh -i $tempKeyPath -p 22 "${sshUser}@${sshHost}" $commands
    Write-Host "成功更新 sudoers 文件！" -ForegroundColor Green
} catch {
    Write-Error "更新 sudoers 文件时发生错误：$($_.Exception.Message)"
    exit 1
} finally {
    # 清理临时密钥文件
    if (Test-Path $tempKeyPath) {
        # 重置文件权限以确保可以删除
        icacls $tempKeyPath /reset
        Remove-Item $tempKeyPath -Force -ErrorAction SilentlyContinue
    }
}