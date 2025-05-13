// // hardhat-ignition/modules/DeploySavingsChallenge.ts
// import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// export default buildModule("SavingsChallengeModule", (m) => {
//   const rewardToken = m.contract("SaveUpRewardToken", []);

//   const strategyAave = m.contract("AaveV3Strategy", []);
//   const strategySecond = m.contract("MockYieldStrategy", []); // Replace with actual strategy if available

//   const challengeVault = m.contract("SaveUpVault", [
//     rewardToken,
//     [strategyAave, strategySecond] // Array of yield strategies
//   ]);

//   const challengeManager = m.contract("SaveUpChallengeManager", [
//     rewardToken,
//     challengeVault
//   ]);

//   // Grant MINTER role to ChallengeManager for RewardToken
//   m.call(rewardToken, "grantRole", [
//     m.call(rewardToken, "MINTER_ROLE"),
//     challengeManager
//   ]);

//   return { rewardToken, strategyAave, strategySecond, challengeVault, challengeManager };
// });
