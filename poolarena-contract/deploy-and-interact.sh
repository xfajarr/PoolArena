#!/bin/bash

# PoolArena Contract Deployment and Interaction Script
# This script demonstrates the full workflow of the PoolArena contract

# Configuration
ACTION=${1:-"help"}
NETWORK=${2:-"unichain-sepolia"}
FOUNDRY_PROFILE="default"
DEPLOYMENT_SCRIPT="script/DeployPoolArena.s.sol:DeployPoolArena"
INTERACTION_SCRIPT="script/InteractWithPoolArena.s.sol:InteractWithPoolArena"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Network configurations
declare -A RPCS=(
    ["unichain-sepolia"]="https://sepolia.unichain.org"
    ["localhost"]="http://localhost:8545"
)

declare -A EXPLORERS=(
    ["unichain-sepolia"]="https://unichain-sepolia.blockscout.com"
    ["localhost"]="http://localhost:8545"
)

declare -A CHAIN_IDS=(
    ["unichain-sepolia"]="1301"
    ["localhost"]="31337"
)

show_help() {
    echo -e "${GREEN}PoolArena Contract Deployment and Interaction Tool${NC}"
    echo -e "${GREEN}=================================================${NC}"
    echo ""
    echo "Usage: ./deploy-and-interact.sh <action> [network]"
    echo ""
    echo -e "${YELLOW}Actions:${NC}"
    echo "  setup        - Install dependencies and setup environment"
    echo "  deploy       - Deploy PoolArena contracts to the network"
    echo "  interact     - Run the full contract interaction demo"
    echo "  test         - Run contract tests"
    echo "  verify       - Verify deployed contracts on block explorer"
    echo "  status       - Check deployment status and contract addresses"
    echo "  clean        - Clean build artifacts"
    echo ""
    echo -e "${YELLOW}Networks:${NC}"
    echo "  unichain-sepolia  - Unichain Sepolia testnet (default)"
    echo "  localhost         - Local development network"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  ./deploy-and-interact.sh setup"
    echo "  ./deploy-and-interact.sh deploy unichain-sepolia"
    echo "  ./deploy-and-interact.sh interact"
    echo "  ./deploy-and-interact.sh test"
}

setup_environment() {
    echo -e "${GREEN}Setting up development environment...${NC}"
    
    # Check if forge is installed
    if command -v forge >/dev/null 2>&1; then
        FORGE_VERSION=$(forge --version)
        echo -e "${GREEN}✓ Foundry is installed: $FORGE_VERSION${NC}"
    else
        echo -e "${RED}✗ Foundry is not installed. Please install from https://getfoundry.sh/${NC}"
        return 1
    fi
    
    # Install dependencies
    echo "Installing forge dependencies..."
    forge install
    
    # Build contracts
    echo "Building contracts..."
    forge build
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        echo "Creating .env file template..."
        cat > .env << 'EOF'
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
EOF
        echo -e "${YELLOW}⚠️  Created .env file. Please update it with your private keys!${NC}"
    else
        echo -e "${GREEN}✓ .env file already exists${NC}"
    fi
    
    echo -e "${GREEN}✓ Environment setup complete!${NC}"
}

deploy_contracts() {
    local network_name=$1
    echo -e "${GREEN}Deploying PoolArena contracts to $network_name...${NC}"
    
    if [ -z "${RPCS[$network_name]}" ]; then
        echo -e "${RED}✗ Unknown network: $network_name${NC}"
        return 1
    fi
    
    local rpc_url="${RPCS[$network_name]}"
    echo "Using RPC URL: $rpc_url"
    
    # Check if .env file exists
    if [ ! -f ".env" ]; then
        echo -e "${RED}✗ .env file not found. Run 'setup' action first.${NC}"
        return 1
    fi
    
    # Load environment variables
    source .env
    
    echo "Deploying contracts..."
    if forge script "$DEPLOYMENT_SCRIPT" --rpc-url "$rpc_url" --broadcast --verify; then
        if [ -f "deployment-addresses.env" ]; then
            echo -e "${GREEN}✓ Deployment successful!${NC}"
            echo "Contract addresses saved to deployment-addresses.env"
            
            # Show deployment addresses
            while IFS= read -r line; do
                echo -e "  ${CYAN}$line${NC}"
            done < deployment-addresses.env
            
            local explorer_url="${EXPLORERS[$network_name]}"
            echo ""
            echo -e "${YELLOW}View contracts on block explorer: $explorer_url${NC}"
        else
            echo -e "${YELLOW}⚠️  Deployment completed but addresses file not found${NC}"
        fi
    else
        echo -e "${RED}✗ Deployment failed${NC}"
        return 1
    fi
}

run_interaction() {
    echo -e "${GREEN}Running PoolArena contract interaction demo...${NC}"
    
    if [ ! -f "deployment-addresses.env" ]; then
        echo -e "${RED}✗ Deployment addresses not found. Deploy contracts first.${NC}"
        return 1
    fi
    
    # Load deployment addresses
    source deployment-addresses.env
    source .env
    
    local rpc_url="${RPCS[$NETWORK]}"
    
    echo "Starting interaction demo..."
    echo "This will demonstrate:"
    echo "  1. Creating a tournament"
    echo "  2. Users joining the tournament"
    echo "  3. Tournament auto-starting when full"
    echo "  4. Finishing the tournament and distributing prizes"
    echo ""
    
    if forge script "$INTERACTION_SCRIPT" --rpc-url "$rpc_url" --broadcast; then
        echo -e "${GREEN}✓ Interaction demo completed!${NC}"
    else
        echo -e "${RED}✗ Interaction failed${NC}"
        return 1
    fi
}

run_tests() {
    echo -e "${GREEN}Running contract tests...${NC}"
    
    if forge test -vv; then
        echo -e "${GREEN}✓ Tests completed!${NC}"
    else
        echo -e "${RED}✗ Tests failed${NC}"
        return 1
    fi
}

verify_contracts() {
    local network_name=$1
    echo -e "${GREEN}Verifying contracts on block explorer...${NC}"
    
    if [ ! -f "deployment-addresses.env" ]; then
        echo -e "${RED}✗ Deployment addresses not found. Deploy contracts first.${NC}"
        return 1
    fi
    
    # This would typically involve using forge verify-contract command
    # Implementation depends on the specific block explorer and API
    echo "Manual verification may be required on the block explorer"
    
    local explorer_url="${EXPLORERS[$network_name]}"
    echo "Block Explorer: $explorer_url"
}

show_status() {
    echo -e "${GREEN}PoolArena Contract Status${NC}"
    echo -e "${GREEN}========================${NC}"
    
    if [ -f "deployment-addresses.env" ]; then
        echo -e "${GREEN}✓ Contracts deployed:${NC}"
        while IFS= read -r line; do
            echo -e "  ${CYAN}$line${NC}"
        done < deployment-addresses.env
    else
        echo -e "${RED}✗ No deployment found${NC}"
    fi
    
    echo ""
    echo "Network: $NETWORK"
    if [ -n "${RPCS[$NETWORK]}" ]; then
        echo "RPC URL: ${RPCS[$NETWORK]}"
        echo "Explorer: ${EXPLORERS[$NETWORK]}"
        echo "Chain ID: ${CHAIN_IDS[$NETWORK]}"
    fi
}

clean_build() {
    echo -e "${GREEN}Cleaning build artifacts...${NC}"
    
    rm -rf out cache broadcast
    
    echo -e "${GREEN}✓ Clean completed!${NC}"
}

# Main script execution
case "$ACTION" in
    "help")
        show_help
        ;;
    "setup")
        setup_environment
        ;;
    "deploy")
        deploy_contracts "$NETWORK"
        ;;
    "interact")
        run_interaction
        ;;
    "test")
        run_tests
        ;;
    "verify")
        verify_contracts "$NETWORK"
        ;;
    "status")
        show_status
        ;;
    "clean")
        clean_build
        ;;
    *)
        echo -e "${RED}Unknown action: $ACTION${NC}"
        echo "Use 'help' for usage information"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}=== PoolArena Contract Workflow ===${NC}"
echo "1. Admin creates tournaments with entry fees and participant limits"
echo "2. Users join tournaments by staking LP NFTs and paying entry fees"
echo "3. Tournaments auto-start when full or can be manually started"
echo "4. During tournaments, users' LP positions generate fees"
echo "5. When tournaments end, winners are determined by fee generation"
echo "6. Prizes are distributed to top 3 performers"
echo "7. LP NFTs are returned to participants"
echo ""
echo -e "${CYAN}The contract integrates with Uniswap V4 hooks to track real-time${NC}"
echo -e "${CYAN}fee generation from LP positions during tournaments!${NC}"