# PoolArena Demo Interface

## 🎬 Quick Demo Setup

This is a simple HTML interface to showcase PoolArena's smart contract functionality for hackathon demos.

### Option 1: Static Demo (No Deployment Needed)
1. Open `index.html` in your browser
2. The interface will show in "Demo Mode"
3. All interactions are simulated for demonstration purposes

### Option 2: Connect to Deployed Contracts
1. Deploy your contracts using the deployment script
2. Update the contract addresses in `index.html`:
   ```javascript
   const CONTRACT_CONFIG = {
       POOL_ARENA: '0xYourDeployedPoolArenaAddress',
       HOOK: '0xYourDeployedHookAddress',
       UNICHAIN_SEPOLIA_CHAIN_ID: '0x515' // 1301 in hex
   };
   ```
3. Serve the HTML file (use Live Server in VS Code or any local server)
4. Connect your MetaMask to Unichain Sepolia
5. Interact with real contracts!

## 🎥 Demo Recording Tips

1. **Full Screen**: Use full screen browser mode for clean recording
2. **Dark Mode**: The interface uses dark colors that look good on video
3. **Responsive**: Works on different screen sizes
4. **Activity Log**: Shows all interactions in real-time

## ✨ Features Demonstrated

- Wallet connection to Unichain Sepolia
- Contract deployment status
- Tournament creation interface
- Real-time activity logging
- Professional UI/UX design

Perfect for showcasing your smart contract capabilities even without a full frontend! 🚀