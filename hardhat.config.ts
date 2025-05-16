import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";


const liveDeploymentAccount = {
  mnemonic: vars.has("MNEMONIC") ? vars.get("MNEMONIC") : "test test test test test test test test test test test junk",
  // accountsBalance: "990000000000000000000",
}

const SEPOLIA_PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");
console.log("SEPOLIA_PRIVATE_KEY", SEPOLIA_PRIVATE_KEY);

const BASE_PRIVATE_KEY = vars.get("BASE_PRIVATE_KEY");
console.log("BASE_PRIVATE_KEY", BASE_PRIVATE_KEY);

const config: HardhatUserConfig = {
  etherscan: {
    apiKey: '9SYCE94JFK2K1S8NC2KPI3FUIGHVH7NS5I'
  },
  solidity: "0.8.28",
  networks: {
    hardhat: {
      // forking: {
      //   enabled: process.env.FORKING === "true",
      //   url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      // },
      
      
    },

		base_t: { //Base test
			url: "https://sepolia.base.org",
			accounts:  [SEPOLIA_PRIVATE_KEY],
			chainId: 84532 ,
			// gasPrice: 350000000,
			
			
		},
    base: { //Base
			url: "https://mainnet.base.org",
			accounts: [BASE_PRIVATE_KEY],
			chainId: 8453 ,
			// gasPrice: 350000000,		
			
		},
    
  },
  ignition: { 
    
  },
};

export default config;
