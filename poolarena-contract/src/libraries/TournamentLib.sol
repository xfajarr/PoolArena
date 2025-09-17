// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@fhenix/FHE.sol";

library TournamentLib {
    /// @notice Precision constants for calculations
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant PERCENTAGE_BASE = 10000; // 100% = 10000
    uint256 internal constant SCORE_MULTIPLIER = 1e12; // For score calculations

    /// @notice Weight constants for score calculation
    uint256 internal constant PNL_WEIGHT = 7000; // 70% weight for PnL
    uint256 internal constant FEES_WEIGHT = 3000; // 30% weight for fees earned

    /// @notice Calculate encrypted PnL percentage
    /// @param currentValue Current position value
    /// @param initialValue Initial position value
    /// @return encryptedPnL Encrypted PnL percentage (scaled by PERCENTAGE_BASE)
    function calculateEncryptedPnL(
        uint256 currentValue,
        uint256 initialValue
    ) internal returns (euint64) {
        require(initialValue > 0, "Initial value cannot be zero");
        
        // Convert to encrypted values
        euint64 encCurrentValue = FHE.asEuint64(currentValue);
        euint64 encInitialValue = FHE.asEuint64(initialValue);
        euint64 encPercentageBase = FHE.asEuint64(PERCENTAGE_BASE);
        
        // Calculate PnL: ((current - initial) / initial) * PERCENTAGE_BASE
        euint64 valueDiff = FHE.sub(encCurrentValue, encInitialValue);
        euint64 pnlPercentage = FHE.div(
            FHE.mul(valueDiff, encPercentageBase),
            encInitialValue
        );
        
        return pnlPercentage;
    }

    /// @notice Calculate encrypted fees percentage
    /// @param feesEarned Total fees earned
    /// @param initialValue Initial position value for normalization
    /// @return encryptedFeesPercentage Encrypted fees as percentage of initial value
    function calculateEncryptedFeesPercentage(
        uint256 feesEarned,
        uint256 initialValue
    ) internal returns (euint64) {
        require(initialValue > 0, "Initial value cannot be zero");
        
        euint64 encFeesEarned = FHE.asEuint64(feesEarned);
        euint64 encInitialValue = FHE.asEuint64(initialValue);
        euint64 encPercentageBase = FHE.asEuint64(PERCENTAGE_BASE);
        
        // Calculate fees percentage: (fees / initial) * PERCENTAGE_BASE
        euint64 feesPercentage = FHE.div(
            FHE.mul(encFeesEarned, encPercentageBase),
            encInitialValue
        );
        
        return feesPercentage;
    }

    /// @notice Calculate combined encrypted score
    /// @param pnlPercentage Encrypted PnL percentage
    /// @param feesPercentage Encrypted fees percentage
    /// @return totalScore Weighted encrypted total score
    function calculateTotalScore(
        euint64 pnlPercentage,
        euint64 feesPercentage
    ) internal returns (euint64) {
        euint64 encPnlWeight = FHE.asEuint64(PNL_WEIGHT);
        euint64 encFeesWeight = FHE.asEuint64(FEES_WEIGHT);
        euint64 encPercentageBase = FHE.asEuint64(PERCENTAGE_BASE);
        
        // Weighted score: (PnL * PNL_WEIGHT + Fees * FEES_WEIGHT) / PERCENTAGE_BASE
        euint64 weightedPnl = FHE.mul(pnlPercentage, encPnlWeight);
        euint64 weightedFees = FHE.mul(feesPercentage, encFeesWeight);
        euint64 totalWeighted = FHE.add(weightedPnl, weightedFees);
        
        euint64 totalScore = FHE.div(totalWeighted, encPercentageBase);
        
        return totalScore;
    }

    /// @notice Calculate prize distribution amounts
    /// @param prizePool Total prize pool
    /// @param distribution Array of percentages [70%, 20%, 10%] * 100
    /// @return prizes Array of prize amounts for top 3
    function calculatePrizes(
        uint256 prizePool,
        uint256[3] memory distribution
    ) internal pure returns (uint256[3] memory prizes) {
        for (uint i = 0; i < 3; i++) {
            prizes[i] = (prizePool * distribution[i]) / PERCENTAGE_BASE;
        }
        return prizes;
    }

    /// @notice Validate tournament configuration
    /// @param entryFee Entry fee amount
    /// @param maxParticipants Maximum number of participants
    /// @param duration Tournament duration in seconds
    /// @param treasuryFee Treasury fee percentage
    /// @param prizeDistribution Prize distribution array
    function validateTournamentConfig(
        uint256 entryFee,
        uint256 maxParticipants,
        uint256 duration,
        uint256 treasuryFee,
        uint256[3] memory prizeDistribution
    ) internal pure {
        require(entryFee > 0, "Entry fee must be positive");
        require(maxParticipants >= 3, "Need at least 3 participants");
        require(maxParticipants <= 50, "Too many participants");
        require(duration >= 1 hours, "Duration too short");
        require(duration <= 30 days, "Duration too long");
        require(treasuryFee <= 1000, "Treasury fee too high"); // Max 10%
        
        // Validate prize distribution sums to 100%
        uint256 totalDistribution = prizeDistribution[0] + 
                                   prizeDistribution[1] + 
                                   prizeDistribution[2];
        require(totalDistribution == PERCENTAGE_BASE, "Prize distribution must sum to 100%");
    }

    /// @notice Calculate entry fee distribution
    /// @param entryFee Total entry fee
    /// @param treasuryFee Treasury fee percentage (basis points)
    /// @return treasuryAmount Amount going to treasury
    /// @return prizeAmount Amount going to prize pool
    function calculateFeeDistribution(
        uint256 entryFee,
        uint256 treasuryFee
    ) internal pure returns (uint256 treasuryAmount, uint256 prizeAmount) {
        treasuryAmount = (entryFee * treasuryFee) / PERCENTAGE_BASE;
        prizeAmount = entryFee - treasuryAmount;
    }

    /// @notice Create default tournament configuration
    /// @return entryFee Default entry fee
    /// @return maxParticipants Default max participants
    /// @return duration Default duration
    /// @return treasuryFee Default treasury fee
    /// @return prizeDistribution Default prize distribution
    function getDefaultTournamentConfig() internal pure returns (
        uint256 entryFee,
        uint256 maxParticipants,
        uint256 duration,
        uint256 treasuryFee,
        uint256[3] memory prizeDistribution
    ) {
        entryFee = 0.002 ether; // 0.002 ETH
        maxParticipants = 12;
        duration = 7 days; // 1 week tournament
        treasuryFee = 100; // 1% treasury fee
        prizeDistribution = [uint256(7000), uint256(2000), uint256(1000)]; // 70%, 20%, 10%
    }

    /// @notice Compare encrypted scores for ranking (returns ebool)
    /// @param scoreA First encrypted score
    /// @param scoreB Second encrypted score
    /// @return isAGreater Encrypted boolean indicating if scoreA > scoreB
    function compareScores(
        euint64 scoreA,
        euint64 scoreB
    ) internal returns (ebool) {
        return FHE.gt(scoreA, scoreB);
    }

    /// @notice Safe subtraction for encrypted values with zero floor
    /// @param a First value
    /// @param b Second value
    /// @return result Max(a - b, 0)
    function safeSubtract(euint64 a, euint64 b) internal returns (euint64) {
        ebool aGeB = FHE.gte(a, b);
        euint64 zero = FHE.asEuint64(0);
        euint64 difference = FHE.sub(a, b);
        
        return FHE.select(aGeB, difference, zero);
    }

    /// @notice Calculate tournament status based on timing
    /// @param startTime Tournament start timestamp
    /// @param endTime Tournament end timestamp
    /// @param currentTime Current block timestamp
    /// @return isActive True if tournament is currently active
    /// @return hasEnded True if tournament has ended
    function getTournamentStatus(
        uint256 startTime,
        uint256 endTime,
        uint256 currentTime
    ) internal pure returns (bool isActive, bool hasEnded) {
        isActive = currentTime >= startTime && currentTime < endTime;
        hasEnded = currentTime >= endTime;
    }
}
