// hardhat-ignition/modules/DeploySavingsChallenge.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("SavingsChallengeModule", (m) => {
  // Deploy tokens
  const assetToken = m.contract("MockUSDT", []); // Mock USDT for testing
  const rewardToken = m.contract("SaveUpToken", []);

  // Deploy strategies
//   const strategyAave = m.contract("AaveV3Strategy", []);
//   const strategySecond = m.contract("MockStrategy", [assetToken, challengeVault]); // Replace with actual strategy if available

  // Deploy vault with asset and reward tokens
  const challengeVault = m.contract("SaveUpVault", [
    assetToken,
    rewardToken
  ]);

  // Add strategies to vault after deployment
//   m.call(challengeVault, "addStrategy", [strategyAave]);
//   m.call(challengeVault, "addStrategy", [strategySecond]);


//   // Grant MINTER role to ChallengeManager for RewardToken
//   const minterRole = m.staticCall(rewardToken, "MINTER_ROLE", []);
//   m.call(rewardToken, "grantRole", [
//     minterRole, // The role hash
//     challengeManager // Contract reference is automatically resolved to address
//   ]);

  return { rewardToken,   challengeVault };
});
