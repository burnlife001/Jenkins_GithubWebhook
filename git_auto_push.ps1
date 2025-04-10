#!/usr/bin/env pwsh
# Auto Git Commit and Push Script
# Function: Commit and push all branches with date-based message

# Get current date and format
$currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitMessage = "Daily backup: $currentDate"

# Output start info
Write-Host "`nStarting auto git commit and push..."
Write-Host "Commit message: $commitMessage"

try {
    # Stage all changes
    Write-Host "`nStaging all changed files..."
    git add -A
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to stage files"
    }
    Write-Host "Files staged successfully" -ForegroundColor Green
    # Create commit
    Write-Host "`nCreating commit..."
    git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create commit"
    }
    Write-Host "Commit created successfully" -ForegroundColor Green

    # Push all branches
    Write-Host "`nPushing all branches to remote..."
    git push --all origin
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push branches"
    }
    Write-Host "Branches pushed successfully" -ForegroundColor Green

    # Record last push time
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "`nAuto git commit and push completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "`nError: $_" -ForegroundColor Red
    Write-Host "Auto git commit and push failed" -ForegroundColor Red
    exit 1
}