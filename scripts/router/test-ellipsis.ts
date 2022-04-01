import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  // We get the contract to deploy
  const instance = await ethers.getContractAt(
    "EllipsisARTHRouter",
    "0x16f3022DD080FeCDf0C02D4F793838f7a698599a"
  );

  await approve(
    "0xb69a424df8c737a122d0e60695382b3eec07ff4b",
    "3000000000000000000000000",
    instance.address
  );

  // await approve(
  //   "0xe9e7cea3dedca5984780bafc599bd69add087d56", // busd
  //   "3000000000000000000000000",
  //   instance.address
  // );
  // await approve(
  //   "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", // usdc
  //   "3000000000000000000000000",
  //   instance.address
  // );
  // await approve(
  //   "0x55d398326f99059ff775485246999027b3197955", // usdt
  //   "3000000000000000000000000",
  //   instance.address
  // );

  // // await approve(
  //   "0xb38b49bae104bbb6a82640094fd61b341a858f78",
  //   "3000000000000000000000000",
  //   instance.address
  // );

  console.log("i am", owner.address);
  console.log("swapping 2 arth for 1 usdt and 3 busd");

  const tx = await instance.sellARTHForExact(
    "210000000000000000", // uint256 amountArthInMax,
    "100000000000000000", // uint256 amountBUSDOut,
    "0", // uint256 amountUSDCOut,
    "100000000000000000", // uint256 amountUSDTOut,
    owner.address, // address to,
    Math.floor(Date.now() / 1000) + 3600 // uint256 deadline
  );
  console.log("swap", tx.hash);

  const tx2 = await instance.buyARTHForExact(
    "10000000000000000", // uint256 amountBUSDIn,
    "10000000000000000", // uint256 amountUSDCIn,
    "10000000000000000", // uint256 amountUSDTIn,
    10000000000000000 * 0.99, // uint256 amountARTHOutMin,
    owner.address, // address to,
    Math.floor(Date.now() / 1000) + 3600 // uint256 deadline
  );

  console.log("swap", tx2.hash);
}

// eslint-disable-next-line no-unused-vars
const approve = async (addr: string, amount: string, whom: string) => {
  const erc20 = await ethers.getContractAt("ERC20", addr);
  const tx = await erc20.approve(whom, amount);
  console.log("approve", addr, tx.hash);
  await tx.wait(2);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});