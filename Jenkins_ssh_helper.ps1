# Jenkins Docker 容器SSH配置工具

# 获取Jenkins容器名称
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
    Pause-Script
    return $containerName
}
function Install-OpenSSH {
    Write-Host "`n正在安装 OpenSSH 客户端和 netcat..."
    docker exec -u root -it $JENKINS_CONTAINER sh -c "apt-get update && apt-get install -y openssh-client netcat-openbsd"
    Write-Host "OpenSSH 客户端和 netcat 安装完成"
    Pause-Script
}

function Generate-SSHKey {
    Write-Host "`n正在生成 SSH 密钥对..."
    docker exec -u root -it $JENKINS_CONTAINER sh -c "mkdir -p /var/jenkins_home/.ssh"
    docker exec -u root -it $JENKINS_CONTAINER sh -c "ssh-keygen -t rsa -b 4096 -f /var/jenkins_home/.ssh/id_rsa -N ''"
    Write-Host "SSH 密钥对生成完成"
    Pause-Script
}

function Set-SSHPermissions {
    Write-Host "`n正在设置 SSH 目录权限..."
    # First set the correct ownership
    docker exec -u root -it $JENKINS_CONTAINER sh -c "chown -R jenkins:jenkins /var/jenkins_home/.ssh"    
    # Then set the correct permissions
    docker exec -u root -it $JENKINS_CONTAINER sh -c "chmod 700 /var/jenkins_home/.ssh && \
        chmod 600 /var/jenkins_home/.ssh/id_rsa && \
        chmod 644 /var/jenkins_home/.ssh/id_rsa.pub && \
        chmod 644 /var/jenkins_home/.ssh/known_hosts"    
    # Verify the permissions
    docker exec -u root -it $JENKINS_CONTAINER sh -c "ls -la /var/jenkins_home/.ssh/"    
    Write-Host "SSH 目录权限设置完成"
    Pause-Script
}

function Show-PublicKey {
    Write-Host "`nSSH 公钥内容："
    docker exec -u root -it $JENKINS_CONTAINER cat /var/jenkins_home/.ssh/id_rsa.pub
    Pause-Script
}

function Show-PrivateKey {
    Write-Host "`nSSH 私钥内容："
    docker exec -u root -it $JENKINS_CONTAINER cat /var/jenkins_home/.ssh/id_rsa
    Pause-Script
}

function Add-GitHubHostKey {
    Write-Host "`n正在获取 GitHub 主机密钥..."
    
    # 检查网络连接
    Write-Host "检查与 GitHub 的网络连接..." -ForegroundColor Yellow
    $netcatResult = docker exec -u root -it $JENKINS_CONTAINER sh -c "nc -zv github.com 22 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "警告：无法连接到 GitHub SSH 端口，请检查网络连接。" -ForegroundColor Red
        Write-Host "错误信息：$netcatResult" -ForegroundColor Red
        Pause-Script
        return
    }
    Write-Host "网络连接正常" -ForegroundColor Green
    
    # 创建.ssh目录并设置权限
    docker exec -u root -it $JENKINS_CONTAINER sh -c "mkdir -p /var/jenkins_home/.ssh && chmod 700 /var/jenkins_home/.ssh"
    
    # 使用重试机制获取主机密钥
    Write-Host "尝试获取 GitHub 主机密钥..." -ForegroundColor Yellow
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        $retryCount++
        Write-Host "尝试 $retryCount/$maxRetries..." -ForegroundColor Yellow
        
        # 获取主机密钥
        $keyscanResult = docker exec -u root -it $JENKINS_CONTAINER sh -c "ssh-keyscan -H github.com 2>/dev/null"
        
        if ($keyscanResult) {
            # 更新known_hosts文件
            docker exec -u root -it $JENKINS_CONTAINER sh -c "echo '$keyscanResult' > /var/jenkins_home/.ssh/known_hosts"
            $success = $true
        } else {
            Write-Host "获取主机密钥失败，等待5秒后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $success) {
        Write-Host "错误：无法获取 GitHub 主机密钥，请稍后重试。" -ForegroundColor Red
        Pause-Script
        return
    }
    
    # 添加SSH配置文件
    Write-Host "配置 SSH 设置..." -ForegroundColor Yellow
    docker exec -u root -it $JENKINS_CONTAINER sh -c "printf 'Host github.com\nIdentityFile ~/.ssh/id_rsa\nUser git\nStrictHostKeyChecking no\nConnectTimeout 30\n' > /var/jenkins_home/.ssh/config"
    
    # 设置文件权限
    docker exec -u root -it $JENKINS_CONTAINER sh -c "chmod 644 /var/jenkins_home/.ssh/known_hosts && chmod 600 /var/jenkins_home/.ssh/config && chown -R jenkins:jenkins /var/jenkins_home/.ssh"
    
    Write-Host "GitHub 主机密钥和SSH配置文件已更新" -ForegroundColor Green
    Write-Host "提示：请确保已将SSH公钥添加到GitHub账户中" -ForegroundColor Cyan
    Pause-Script
}

function Add-GitLabHostKey {
    Write-Host "`n正在获取 GitLab 主机密钥..."
    
    # 检查网络连接
    Write-Host "检查与 GitLab 的网络连接..." -ForegroundColor Yellow
    $netcatResult = docker exec -u root -it $JENKINS_CONTAINER sh -c "nc -zv gitlab.com 22 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "警告：无法连接到 GitLab SSH 端口，请检查网络连接。" -ForegroundColor Red
        Write-Host "错误信息：$netcatResult" -ForegroundColor Red
        Pause-Script
        return
    }
    Write-Host "网络连接正常" -ForegroundColor Green
    
    # 创建.ssh目录并设置权限
    docker exec -u root -it $JENKINS_CONTAINER sh -c "mkdir -p /var/jenkins_home/.ssh && chmod 700 /var/jenkins_home/.ssh"
    
    # 使用重试机制获取主机密钥
    Write-Host "尝试获取 GitLab 主机密钥..." -ForegroundColor Yellow
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        $retryCount++
        Write-Host "尝试 $retryCount/$maxRetries..." -ForegroundColor Yellow
        
        # 获取主机密钥
        $keyscanResult = docker exec -u root -it $JENKINS_CONTAINER sh -c "ssh-keyscan -H gitlab.com 2>/dev/null"
        
        if ($keyscanResult) {
            # 更新known_hosts文件
            docker exec -u root -it $JENKINS_CONTAINER sh -c "echo '$keyscanResult' > /var/jenkins_home/.ssh/known_hosts"
            $success = $true
        } else {
            Write-Host "获取主机密钥失败，等待5秒后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $success) {
        Write-Host "错误：无法获取 GitLab 主机密钥，请稍后重试。" -ForegroundColor Red
        Pause-Script
        return
    }
    
    # 添加SSH配置文件
    Write-Host "配置 SSH 设置..." -ForegroundColor Yellow
    docker exec -u root -it $JENKINS_CONTAINER sh -c "printf 'Host gitlab.com\nIdentityFile ~/.ssh/id_rsa\nUser git\nStrictHostKeyChecking no\nConnectTimeout 30\n' >> /var/jenkins_home/.ssh/config"
    
    # 设置文件权限
    docker exec -u root -it $JENKINS_CONTAINER sh -c "chmod 644 /var/jenkins_home/.ssh/known_hosts && chmod 600 /var/jenkins_home/.ssh/config && chown -R jenkins:jenkins /var/jenkins_home/.ssh"
    
    Write-Host "GitLab 主机密钥和SSH配置文件已更新" -ForegroundColor Green
    Write-Host "提示：请确保已将SSH公钥添加到GitLab账户中" -ForegroundColor Cyan
    Pause-Script
}

function Pause-Script {
    Write-Host "`n按任意键返回主菜单..." -NoNewline
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Connect-DockerDesktopSSH {
    Write-Host "`n正在连接到 Docker Desktop SSH..."
    docker exec -it -u root $JENKINS_CONTAINER /bin/bash
    if ($LASTEXITCODE -ne 0) {
        Write-Host "SSH 连接失败" -ForegroundColor Red
    }
    Pause-Script
}

function Test-GitHubConnection {
    Write-Host "`n测试 GitHub 连接性..."
    # 测试端口连通性
    Write-Host "正在测试到 GitHub 的端口连通性..." -ForegroundColor Yellow
    docker exec -u root -it $JENKINS_CONTAINER sh -c "nc -zv github.com 22"
    
    # 检查SSH配置文件权限
    Write-Host "`n检查SSH配置文件权限..." -ForegroundColor Yellow
    docker exec -u root -it $JENKINS_CONTAINER sh -c "ls -la /var/jenkins_home/.ssh/"
    
    # 测试SSH连接（自动接受主机密钥）
    Write-Host "`n测试SSH连接..." -ForegroundColor Yellow
    docker exec -u jenkins -it $JENKINS_CONTAINER sh -c "ssh -o StrictHostKeyChecking=no -T git@github.com"
    
    Write-Host "`n如果连接被拒绝，请确保：" -ForegroundColor Cyan
    Write-Host "1. SSH公钥已添加到GitHub账户" -ForegroundColor Cyan
    Write-Host "2. SSH配置文件权限正确" -ForegroundColor Cyan
    Write-Host "3. 确认GitHub账户状态正常" -ForegroundColor Cyan
    Pause-Script
}

function Show-Menu {
    Clear-Host
    Write-Host "========== Jenkins Docker SSH配置工具 ==========`n"
    Write-Host "1. 安装 OpenSSH 客户端"
    Write-Host "2. 生成新的 SSH 密钥对"
    Write-Host "3. 设置 SSH 目录权限"
    Write-Host "4. 显示 SSH 公钥"
    Write-Host "5. 显示 SSH 私钥"
    Write-Host "6. 添加 GitHub 主机密钥"
    Write-Host "7. 添加 GitLab 主机密钥"
    Write-Host "8. 连接到 Docker Desktop SSH"
    Write-Host "9. 测试 GitHub 连接"
    Write-Host "0. 退出程序`n"
    Write-Host "请输入选项编号 (0-9): " -NoNewline
}


# 获取Jenkins容器名称并存储在变量中
$JENKINS_CONTAINER = Get-JenkinsContainer
if (-not $JENKINS_CONTAINER) {
    Write-Host "无法找到Jenkins容器，请确保Jenkins容器正在运行。" -ForegroundColor Red
    Write-Host "按任意键退出..." -NoNewline
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

# 主程序循环
do {
    Show-Menu
    $choice = Read-Host

    switch ($choice) {
        '1' { Install-OpenSSH }
        '2' { Generate-SSHKey }
        '3' { Set-SSHPermissions }
        '4' { Show-PublicKey }
        '5' { Show-PrivateKey }
        '6' { Add-GitHubHostKey }
        '7' { Add-GitLabHostKey }
        '8' { Connect-DockerDesktopSSH }
        '9' { Test-GitHubConnection }
        '0' {
            exit
        }
        default {
            Write-Host "`n无效的选项，请重试"
            Pause-Script
        }
    }
} while ($true)