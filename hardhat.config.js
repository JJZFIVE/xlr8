require("@nomiclabs/hardhat-waffle");

const projectId = "";
const privateKey = "";

// I'd try and use Typescript, it integrates well with Hardhat
// It's a bit more tedious but will make testing a lot more seamless
// Shameless plug: https://github.com/djh58/hardhat-deploy-ts-template

module.exports = {
  solidity: "0.8.10",
  networks: {
    hardhat: {
      chainId: 1337,
    },
  },
};
