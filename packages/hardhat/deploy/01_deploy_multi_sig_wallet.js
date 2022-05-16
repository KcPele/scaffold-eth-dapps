const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  await deploy("MultiSigWallet", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: ["0xf4030DdD79fc7Fd49b25C976C5021D07568B4F91"],
    log: true,
  });

  const multiSigWallet = await ethers.getContract("MultiSigWallet", deployer);

  // ToDo: Verify your contract with Etherscan for public chains
if (chainId !== "31337") {
    try {
      console.log(" 🎫 Verifing Contract on Etherscan... ");
      await sleep(5000); // wait 5 seconds for deployment to propagate
      await run("verify:verify", {
        contract: "contracts/MultiSig.sol:MultiSigWallet",
        contractArguments: [multiSigWallet.address],
      });
    } catch (e) {
      console.log(" ⚠️ Failed to verify contract on Etherscan ");
    }
  }

};

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports.tags = ["MultiSigWallet"];
