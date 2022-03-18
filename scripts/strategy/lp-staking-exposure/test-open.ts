import { ethers } from "hardhat";

async function main() {
  // We get the contract to deploy
  const instance = await ethers.getContractAt(
    "LPExpsoure",
    "0xB3cBe792f9DB85334C3563d997E1C8b129441FB8"
  );

  // await registerStrategy(instance.address, "0xcC4eB1398E22F1AA799CF30c29B8Be367C77A6Fa");
  // await approve(
  //   "0x54406a69B4c629E4d5711140Faec3221672c71A1",
  //   "3000000000000000000000000",
  //   instance.address
  // );
  // await approve(
  //   "0x3467D9Fea78e9D82728aa6C3011F881ad7300a1e",
  //   "3000000000000000000000000",
  //   instance.address
  // );

  const tx = await instance.openPosition(
    ["1000000000000000000000", "1000000000000000000000"], // uint256[] memory borrowedCollateral,
    ["1000000000000000000000", "1000000000000000000000"], // uint256[] memory principalCollateral,
    ["2000000000000000000000", "2000000000000000000000"], // uint256[] memory minExposure,
    "15000000000000000", // uint256 maxBorrowingFee,

    // "400000000000000000000", // uint256 borrowedCollateral,
    // "300000000000000000000", // uint256 principalCollateral,
    // "600000000000000000000", // uint256 minExposure,
    // "15000000000000000", // uint256 maxBorrowingFee,0xa3ae29fb00d6df4c28c7ddd5937c51bcbbd637aa

    "0x0000000000000000000000000000000000000000", // address upperHint,
    "0x0000000000000000000000000000000000000000", // address lowerHint,
    "0x0000000000000000000000000000000000000000" // address frontEndTag
  );

  console.log(tx);
  console.log("open", tx.hash);
}

const registerStrategy = async (strategy: string, acct: string) => {
  const account = await ethers.getContractAt("LeverageAccount", acct);

  // call the transfer fn on behalf of the account
  const tx = await account.approveStrategy(strategy);
  console.log("registerStrategy", tx.hash);
};

const approve = async (addr: string, amount: string, whom: string) => {
  const erc20 = await ethers.getContractAt("ERC20", addr);
  const tx = await erc20.approve(whom, amount);
  console.log("approve", addr, tx.hash);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
