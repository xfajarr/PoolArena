# PoolArena Contract Deployment and Interaction Script
# This script demonstrates the full workflow of the PoolArena contract

param(
    [string]$Action = "help",
    [string]$Network = "unichain-sepolia"
)

# Configuration
$FOUNDRY_PROFILE = "default"
$DEPLOYMENT_SCRIPT = "script/DeployPoolArena.s.sol:DeployPoolArena"
$INTERACTION_SCRIPT = "script/InteractWithPoolArena.s.sol:InteractWithPoolArena"

# Network configurations
$NETWORKS = @{
    "unichain-sepolia" = @{
        "rpc" = "https://sepolia.unichain.org"
        "explorer" = "https://unichain-sepolia.blockscout.com"
        "chainId" = "1301"
    }
    "localhost" = @{
        "rpc" = "http://localhost:8545"
        "explorer" = "http://localhost:8545"
        "chainId" = "31337"
    }
}

function Show-Help {
    Write-Host "PoolArena Contract Deployment and Interaction Tool" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\deploy-and-interact.ps1 -Action <action> [-Network <network>]"
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Yellow
    Write-Host "  setup        - Install dependencies and setup environment"
    Write-Host "  deploy       - Deploy PoolArena contracts to the network"
    Write-Host "  interact     - Run the full contract interaction demo"
    Write-Host "  test         - Run contract tests"
    Write-Host "  verify       - Verify deployed contracts on block explorer"
    Write-Host "  status       - Check deployment status and contract addresses"
    Write-Host "  clean        - Clean build artifacts"
    Write-Host ""
    Write-Host "Networks:" -ForegroundColor Yellow
    Write-Host "  unichain-sepolia  - Unichain Sepolia testnet (default)"
    Write-Host "  localhost         - Local development network"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\deploy-and-interact.ps1 -Action setup"
    Write-Host "  .\deploy-and-interact.ps1 -Action deploy -Network unichain-sepolia"
    Write-Host "  .\deploy-and-interact.ps1 -Action interact"
    Write-Host "  .\deploy-and-interact.ps1 -Action test"
}

function Setup-Environment {
    Write-Host "Setting up development environment..." -ForegroundColor Green
    
    # Check if forge is installed
    try {
        $forgeVersion = forge --version
        Write-Host "✓ Foundry is installed: $forgeVersion" -ForegroundColor Green
    } catch {
        Write-Host "✗ Foundry is not installed. Please install from https://getfoundry.sh/" -ForegroundColor Red
        return
    }
    
    # Install dependencies
    Write-Host "Installing forge dependencies..."
    forge install
    
    # Build contracts
    Write-Host "Building contracts..."
    forge build
    
    # Create .env file if it doesn't exist
    if (!(Test-Path ".env")) {
        Write-Host "Creating .env file template..."
        @"
# Private key for deployment (DO NOT commit this to git!)
PRIVATE_KEY=0x1234567890123456789012345678901234567890123456789012345678901234

# Network RPC URLs
UNICHAIN_SEPOLIA_RPC=https://sepolia.unichain.org
LOCALHOST_RPC=http://localhost:8545

# Block explorer API keys (optional, for contract verification)
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Test user private keys (for interaction script)
USER1_PRIVATE_KEY_OR_DEFAULT=1001
USER2_PRIVATE_KEY_OR_DEFAULT=1002
USER3_PRIVATE_KEY_OR_DEFAULT=1003
"@ | Out-File -FilePath ".env" -Encoding UTF8
        
        Write-Host "⚠️  Created .env file. Please update it with your private keys!" -ForegroundColor Yellow
    } else {
        Write-Host "✓ .env file already exists" -ForegroundColor Green
    }
    
    Write-Host "✓ Environment setup complete!" -ForegroundColor Green
}

function Deploy-Contracts {
    param([string]$NetworkName)
    
    Write-Host "Deploying PoolArena contracts to $NetworkName..." -ForegroundColor Green
    
    if (!$NETWORKS.ContainsKey($NetworkName)) {
        Write-Host "✗ Unknown network: $NetworkName" -ForegroundColor Red
        return
    }
    
    $network = $NETWORKS[$NetworkName]
    $rpcUrl = $network["rpc"]
    
    Write-Host "Using RPC URL: $rpcUrl"
    
    # Check if .env file exists
    if (!(Test-Path ".env")) {
        Write-Host "✗ .env file not found. Run 'setup' action first." -ForegroundColor Red
        return
    }
    
    try {
        Write-Host "Deploying contracts..."
        $deployOutput = forge script $DEPLOYMENT_SCRIPT --rpc-url $rpcUrl --broadcast --verify 2>&1
        
        Write-Host "Deployment output:"
        Write-Host $deployOutput
        
        if (Test-Path "deployment-addresses.env") {
            Write-Host "✓ Deployment successful!" -ForegroundColor Green
            Write-Host "Contract addresses saved to deployment-addresses.env"
            
            # Show deployment addresses
            Get-Content "deployment-addresses.env" | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Cyan
            }
            
            $explorerUrl = $network["explorer"]
            Write-Host ""
            Write-Host "View contracts on block explorer: $explorerUrl" -ForegroundColor Yellow
        } else {
            Write-Host "⚠️  Deployment completed but addresses file not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Deployment failed: $_" -ForegroundColor Red
    }
}

function Run-Interaction {
    Write-Host "Running PoolArena contract interaction demo..." -ForegroundColor Green
    
    if (!(Test-Path "deployment-addresses.env")) {
        Write-Host "✗ Deployment addresses not found. Deploy contracts first." -ForegroundColor Red
        return
    }
    
    # Load deployment addresses into environment
    Get-Content "deployment-addresses.env" | ForEach-Object {
        $line = $_ -split '=', 2
        if ($line.Count -eq 2) {
            [Environment]::SetEnvironmentVariable($line[0], $line[1], "Process")
        }
    }
    
    $network = $NETWORKS[$Network]
    $rpcUrl = $network["rpc"]
    
    try {
        Write-Host "Starting interaction demo..."
        Write-Host "This will demonstrate:"
        Write-Host "  1. Creating a tournament"
        Write-Host "  2. Users joining the tournament"
        Write-Host "  3. Tournament auto-starting when full"
        Write-Host "  4. Finishing the tournament and distributing prizes"
        Write-Host ""
        
        $interactionOutput = forge script $INTERACTION_SCRIPT --rpc-url $rpcUrl --broadcast 2>&1
        Write-Host $interactionOutput
        
        Write-Host "✓ Interaction demo completed!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Interaction failed: $_" -ForegroundColor Red
    }
}

function Run-Tests {
    Write-Host "Running contract tests..." -ForegroundColor Green
    
    try {
        Write-Host "Running forge tests..."
        forge test -vv
        
        Write-Host "✓ Tests completed!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Tests failed: $_" -ForegroundColor Red
    }
}

function Verify-Contracts {
    param([string]$NetworkName)
    
    Write-Host "Verifying contracts on block explorer..." -ForegroundColor Green
    
    if (!(Test-Path "deployment-addresses.env")) {
        Write-Host "✗ Deployment addresses not found. Deploy contracts first." -ForegroundColor Red
        return
    }
    
    # This would typically involve using forge verify-contract command
    # Implementation depends on the specific block explorer and API
    Write-Host "Manual verification may be required on the block explorer"
    
    $network = $NETWORKS[$NetworkName]
    Write-Host "Block Explorer: $($network["explorer"])"
}

function Show-Status {
    Write-Host "PoolArena Contract Status" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Green
    
    if (Test-Path "deployment-addresses.env") {
        Write-Host "✓ Contracts deployed:" -ForegroundColor Green
        Get-Content "deployment-addresses.env" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Cyan
        }
    } else {
        Write-Host "✗ No deployment found" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Network: $Network"
    if ($NETWORKS.ContainsKey($Network)) {
        $net = $NETWORKS[$Network]
        Write-Host "RPC URL: $($net["rpc"])"
        Write-Host "Explorer: $($net["explorer"])"
        Write-Host "Chain ID: $($net["chainId"])"
    }
}

function Clean-Build {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Green
    
    if (Test-Path "out") { Remove-Item -Recurse -Force "out" }
    if (Test-Path "cache") { Remove-Item -Recurse -Force "cache" }
    if (Test-Path "broadcast") { Remove-Item -Recurse -Force "broadcast" }
    
    Write-Host "✓ Clean completed!" -ForegroundColor Green
}

# Main script execution
switch ($Action.ToLower()) {
    "help" { Show-Help }
    "setup" { Setup-Environment }
    "deploy" { Deploy-Contracts -NetworkName $Network }
    "interact" { Run-Interaction }
    "test" { Run-Tests }
    "verify" { Verify-Contracts -NetworkName $Network }
    "status" { Show-Status }
    "clean" { Clean-Build }
    default { 
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host "Use -Action help for usage information"
    }
}

Write-Host ""
Write-Host "=== PoolArena Contract Workflow ===" -ForegroundColor Green
Write-Host "1. Admin creates tournaments with entry fees and participant limits"
Write-Host "2. Users join tournaments by staking LP NFTs and paying entry fees"
Write-Host "3. Tournaments auto-start when full or can be manually started"
Write-Host "4. During tournaments, users' LP positions generate fees"
Write-Host "5. When tournaments end, winners are determined by fee generation"
Write-Host "6. Prizes are distributed to top 3 performers"
Write-Host "7. LP NFTs are returned to participants"
Write-Host ""
Write-Host "The contract integrates with Uniswap V4 hooks to track real-time"
Write-Host "fee generation from LP positions during tournaments!" -ForegroundColor Cyan