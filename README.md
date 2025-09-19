# PoolArena - Gamified LP Trading Tournaments

PoolArena is a innovative DeFi gaming platform that transforms liquidity provision into competitive tournaments. Users compete with their Uniswap V4 LP NFTs in skill-based tournaments with prize pools distributed to top performers.

## 🏆 Overview

PoolArena gamifies decentralized finance by creating competitive tournaments where participants use their Uniswap V4 LP (Liquidity Provider) NFT positions to compete for prizes. The platform combines the yield generation of liquidity provision with the excitement of competitive gaming.

### Key Features

- **🎮 Tournament System**: Create and join time-limited tournaments with entry fees
- **💎 NFT-Based Participation**: Use Uniswap V4 LP NFTs as tournament entries
- **🏅 Prize Distribution**: Automated prize distribution (50%, 30%, 20% for top 3)
- **🔒 Secure Smart Contracts**: Full test coverage with security validations
- **⚡ Uniswap V4 Integration**: Custom hooks for enhanced functionality
- **📊 Real-time Tracking**: Performance monitoring with Pyth price feeds

## 🏗️ Architecture

### Smart Contracts

1. **PoolArena.sol** - Main tournament contract
   - Tournament lifecycle management
   - NFT custody and prize distribution
   - Access control and security features

2. **PoolArenaHook.sol** - Uniswap V4 hook integration
   - Liquidity tracking and validation
   - Swap fee monitoring
   - Position performance calculation

3. **Mock Contracts** - Testing infrastructure
   - MockPositionManager.sol
   - MockPyth.sol
   - MockPoolArenaHook.sol

### Project Structure

```
PoolArena/
├── poolarena-contract/          # Smart contracts (Foundry)
│   ├── src/                     # Contract source files
│   ├── test/                    # Test suites
│   ├── script/                  # Deployment scripts
│   └── lib/                     # Dependencies
├── demo-ui/                     # Frontend demo (HTML/CSS/JS)
├── README.md                    # This file
└── DEPLOYMENT.md                # Deployment guide
```

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Ethereum development toolkit
- [Node.js](https://nodejs.org/) - For frontend demo
- Windows PowerShell or Bash - For automation scripts

### Quick Demo

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd PoolArena
   ```

2. **Run the demo (Windows)**
   ```powershell
   cd poolarena-contract
   ./demo-test-results.ps1
   ```

3. **Run tests**
   ```bash
   cd poolarena-contract
   forge test
   ```

4. **View demo UI**
   ```bash
   cd demo-ui
   # Open index.html in browser
   ```

## 🧪 Testing

The project includes comprehensive test coverage with 19+ test cases covering:

- ✅ Tournament lifecycle management
- ✅ NFT transfer security
- ✅ Prize distribution mechanics
- ✅ Access control validation
- ✅ Hook integration functionality
- ✅ Error handling and edge cases
- ✅ Gas optimization verification

Run tests with detailed output:
```bash
forge test -vvv
```

## 🎯 Tournament Flow

1. **Create Tournament**: Admin creates tournament with entry fee and participant limit
2. **Join Tournament**: Users join with LP NFTs and pay entry fees
3. **Auto-Start**: Tournament begins when full or manually started
4. **Competition**: Participants' LP performance tracked via hooks
5. **Finish**: Tournament ends, prizes distributed to top performers
6. **Claim**: Winners receive prizes and NFTs returned

## 🔧 Deployment

### Local Testing
```bash
# Start local node
anvil

# Deploy contracts
forge script script/DeployPoolArena.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Testnet Deployment
```bash
# Deploy to Unichain Sepolia
forge script script/DeployPoolArena.s.sol --rpc-url $UNICHAIN_SEPOLIA_RPC --broadcast --verify
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

## 🛡️ Security

- **Reentrancy Protection**: All external calls secured
- **Access Control**: Owner-only admin functions
- **Input Validation**: Comprehensive parameter checking
- **Safe Transfers**: ERC721 compliance with safety checks
- **Error Handling**: Robust error messages and state validation

## 📈 Gas Optimization

- **Efficient Storage**: Optimized struct packing
- **Batch Operations**: Reduced transaction costs
- **Hook Integration**: Minimal gas overhead
- **Smart Caching**: Reduced redundant calculations

Average gas costs:
- Tournament Creation: ~82K gas
- Join Tournament: ~169K gas
- Finish Tournament: ~344K gas

## 🎨 Demo UI

Interactive web interface showcasing:
- Tournament creation and joining
- Real-time status updates
- Prize distribution visualization
- Gas cost estimation
- Contract interaction examples

## 🔗 Integration Points

### Uniswap V4 Integration
- **Position Manager**: LP NFT handling and validation
- **Hook System**: Custom PoolArenaHook for tournament logic
- **Pool Factory**: Hook address calculation with permissions

### Price Feeds
- **Pyth Network**: Real-time price data for performance calculation
- **Oracle Integration**: Secure price feed validation

## 📊 Tournament Types

Currently supported:
- **Standard Tournaments**: Fixed duration, entry fee based
- **Quick Tournaments**: Shorter duration for rapid competition

Future implementations:
- **Tiered Tournaments**: Multiple skill/stake levels
- **Team Tournaments**: Collaborative competition
- **Seasonal Leagues**: Long-term competition series

## 🏆 Prize Structure

- **1st Place**: 50% of prize pool
- **2nd Place**: 30% of prize pool  
- **3rd Place**: 20% of prize pool
- **Platform Fee**: 1% of entry fees

---

*PoolArena - Where DeFi meets competitive gaming* 🎮⚡