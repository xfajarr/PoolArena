# PoolArena - Private LP Tournament Platform 🏆

A competitive DeFi tournament platform where liquidity providers (LPs) battle using their Uniswap v4 positions. Built with **Fhenix Fully Homomorphic Encryption (FHE)** for privacy and **Uniswap v4 Hooks** for seamless integration.

## 🎯 Overview

PoolArena turns DeFi yield farming into a fun, gamified, and **private** experience. Players compete based on PnL % and fees earned, but exact values remain encrypted during tournaments, preventing copy-trading and "big wallet dominance."

### Key Features

- 🔐 **Privacy-First**: Uses Fhenix FHE to encrypt performance metrics during tournaments
- 🎣 **Uniswap v4 Integration**: Custom hooks track LP performance automatically
- 🏟️ **Tournament System**: Daily/weekly competitions with configurable parameters
- 💰 **Fair Rewards**: Prize pools with configurable distribution (default: 70/20/10%)
- 🔒 **LP NFT Staking**: Secure LP position management during tournaments
- ⚡ **Gas Optimized**: Efficient FHE operations and calldata usage

## 🏗️ Architecture

### Core Contracts

#### 1. **PoolArena.sol** - Main Tournament Manager
- Tournament creation and lifecycle management
- LP NFT staking and reward distribution
- Entry fee handling with treasury integration
- Multi-transaction decryption workflow

#### 2. **PoolArenaHook.sol** - Uniswap v4 Hook
- Implements `BaseHook` with position tracking permissions
- Captures LP performance changes via hook callbacks
- Encrypts PnL and fees data using FHE operations
- Real-time performance calculation and updates

#### 3. **TournamentLib.sol** - FHE Utilities Library
- Encrypted score calculations (70% PnL + 30% fees)
- Tournament configuration validation
- Prize distribution calculations
- FHE-safe mathematical operations

### Key Interfaces

- **IPoolArena**: Tournament management interface
- **IPoolArenaHook**: Hook integration interface

## 🔧 Technical Implementation

### FHE Integration

```solidity
// Encrypted PnL calculation
euint64 encryptedPnL = TournamentLib.calculateEncryptedPnL(currentValue, initialValue);

// Encrypted score composition
euint64 totalScore = TournamentLib.calculateTotalScore(encryptedPnL, encryptedFeesPercentage);

// Proper access control
FHE.allowThis(totalScore);
FHE.allow(totalScore, participant);
```

### Tournament Flow

1. **Tournament Creation**
   ```solidity
   TournamentConfig config = TournamentConfig({
       entryFee: 0.002 ether,
       maxParticipants: 12,
       duration: 7 days,
       treasuryFee: 100, // 1%
       prizeDistribution: [7000, 2000, 1000] // 70%, 20%, 10%
   });
   uint256 tournamentId = poolArena.createTournament(config);
   ```

2. **Joining Tournament**
   ```solidity
   // User stakes LP NFT + pays entry fee
   poolArena.joinTournament{value: 0.002 ether}(tournamentId, lpTokenId);
   ```

3. **Performance Tracking** (via hooks)
   - Hook captures position modifications automatically
   - Encrypts PnL and fees data using FHE
   - Updates tournament scores in real-time

4. **Tournament End & Decryption**
   ```solidity
   // Request decryption (separate transaction)
   poolArena.requestDecryption(tournamentId);
   
   // Finalize tournament with decrypted results
   poolArena.finalizeTournament(tournamentId);
   ```

### Uniswap v4 Hook Integration

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeModifyPosition: true,   // Track position changes
        afterModifyPosition: true,    // Update performance
        afterSwap: true,              // Track fees earned
        // ... other hooks disabled
    });
}
```

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) for development
- Node.js and pnpm for dependencies
- Access to Fhenix testnet

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd poolarena-contract

# Install dependencies
pnpm install
forge install

# Compile contracts
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testCreateTournament
```

### Deployment

#### Local/Testnet with Mocks

```bash
# Set environment variable
export PRIVATE_KEY=<your-private-key>

# Deploy with mock contracts
forge script script/Deploy.s.sol:DeployWithMocks --rpc-url <rpc-url> --broadcast
```

#### Mainnet/Live Network

```bash
# Update addresses in Deploy.s.sol:
# - UNISWAP_V4_POOL_MANAGER
# - LP_NFT_CONTRACT  
# - TREASURY_ADDRESS

forge script script/Deploy.s.sol:DeployScript --rpc-url <rpc-url> --broadcast --verify
```

## 📊 Tournament Configuration

### Default Parameters

- **Entry Fee**: 0.002 ETH
- **Max Participants**: 12 players
- **Duration**: 7 days
- **Treasury Fee**: 1%
- **Prize Distribution**: 70% / 20% / 10%

### Customizable Options

- Entry fees: 0.001 - 10 ETH
- Participants: 3 - 50 players  
- Duration: 1 hour - 30 days
- Treasury fee: 0 - 10%
- Prize distribution: Any combination summing to 100%

## 🔒 Privacy Features

### What's Encrypted (During Tournament)
- ✅ Individual PnL percentages
- ✅ Fees earned amounts  
- ✅ Total performance scores
- ✅ Relative rankings (blurred)

### What's Public
- ✅ Tournament parameters
- ✅ Participant count
- ✅ Prize pool size
- ✅ Tournament state/timing

### Decryption Process
1. Tournament ends
2. Anyone can request decryption (`requestDecryption`)
3. Threshold decryption completes (~1 block)
4. Results finalized and rewards distributed

## 💰 Economic Model

### Fee Structure
- **Entry Fee**: Set per tournament (e.g., 0.002 ETH)
- **Treasury Cut**: 1% of entry fees (configurable)
- **Prize Pool**: 99% of entry fees distributed to top 3

### Example Tournament (12 players × 0.002 ETH)
- Total Collected: 0.024 ETH
- Treasury Fee: 0.00024 ETH (1%)
- Prize Pool: 0.02376 ETH
  - 1st Place: 0.016632 ETH (70%)
  - 2nd Place: 0.004752 ETH (20%)  
  - 3rd Place: 0.002376 ETH (10%)

## 🛡️ Security Features

- **ReentrancyGuard**: Protection against reentrancy attacks
- **Access Control**: Role-based permissions with Ownable
- **FHE Access Management**: Proper encrypted data permissions
- **Input Validation**: Comprehensive parameter validation
- **Safe Math**: Overflow/underflow protection

## 🎮 Usage Examples

### Creating a Tournament

```solidity
IPoolArena.TournamentConfig memory config = IPoolArena.TournamentConfig({
    entryFee: 0.005 ether,        // 0.005 ETH entry
    maxParticipants: 8,           // Smaller tournament
    duration: 3 days,             // 3-day duration
    treasuryFee: 200,             // 2% treasury fee
    prizeDistribution: [6000, 3000, 1000] // 60/30/10 split
});

uint256 tournamentId = poolArena.createTournament(config);
```

### Joining a Tournament

```solidity
// User must own LP NFT and have approved PoolArena contract
uint256 lpTokenId = 123;
poolArena.joinTournament{value: config.entryFee}(tournamentId, lpTokenId);
```

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

We welcome contributions! Feel free to submit issues and pull requests.

---

**Built with ❤️ using Fhenix FHE and Uniswap v4**
