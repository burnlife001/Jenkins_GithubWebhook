# 检查是否以管理员权限运行
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "请以管理员权限运行此脚本！"
    exit 1
}

# 定义 sudoers 文件路径
$sudoersPath = "/etc/sudoers"
$backupPath = "/etc/sudoers.bak"

# SSH 连接信息
$sshHost = "your_jenkins_server"
$sshUser = "your_username"
$sshKeyPath = "path_to_your_private_key"

# 使用 SSH 执行远程命令
$commands = @"
# 检查 sudoers 文件是否存在
if [ ! -f $sudoersPath ]; then
    echo 'Error: sudoers file not found!'
    exit 1
fi

# 创建备份
sudo cp $sudoersPath $backupPath

# 检查是否已存在相同配置
if ! sudo grep -q 'jenkins ALL=(ALL) NOPASSWD: /usr/bin/apt-get' $sudoersPath; then
    # 添加新配置
    echo 'jenkins ALL=(ALL) NOPASSWD: /usr/bin/apt-get' | sudo EDITOR='tee -a' visudo
fi

# 验证 sudoers 文件语法
sudo visudo -c
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