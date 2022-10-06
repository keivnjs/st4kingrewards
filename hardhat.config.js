require('@nomicfoundation/hardhat-toolbox');
require('@nomiclabs/hardhat-etherscan');
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.17',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/bdbe66fbcc554f12b7a2fd9cdfec6598',
      accounts: [process.env.PRIVATE_KEY],
    },
    bsctest: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      accounts: [process.env.PRIVATE_KEY],
    },
    mainnet: {
      url: 'https://bsc-dataseed.binance.org/',
      accounts: [process.env.PRIVATE_KEY],
    },

  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    apiKey: process.env.BSC_API_KEY,
  },
};
