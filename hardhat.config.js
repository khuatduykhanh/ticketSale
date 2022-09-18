require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version:  "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000,
        details: {
          yul: true,
          yulDetails: {
            stackAllocation: true,
            optimizerSteps: "dhfoDgvulfnTUtnIf"
          }
        }
      }
    },
  },
  paths: {
    artifacts: "./src/artifacts",
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
  //   kovan: {
  //     url: "https://eth-kovan.alchemyapi.io/v2/2ltPxjNf2rh4dAiXvo8NcI6jt62jnCsD",
  //     accounts: ["0xd67e3685dfe7d23ae09de01fac32da53c58ae72a3d4f1a55fb0ef99b58d81907"],
  //   },
  //   local: {
  //     url: `http://127.0.0.1:8545/`,
  //     accounts: ["0xd67e3685dfe7d23ae09de01fac32da53c58ae72a3d4f1a55fb0ef99b58d81907"],
  //   },
    },
    
};
