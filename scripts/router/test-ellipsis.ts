import { ethers } from "hardhat";

async function main() {
  // We get the contract to deploy
  const instance = await ethers.getContractAt(
    "EllipsisARTHRouter",
    "0xEf30166866f12552F00DDdb29BbfAE21FE400f25"
  );

  // await approve(
  //   "0xb69a424df8c737a122d0e60695382b3eec07ff4b",
  //   "3000000000000000000000000",
  //   instance.address
  // );

  // await approve(
  //   "0xb38b49bae104bbb6a82640094fd61b341a858f78",
  //   "3000000000000000000000000",
  //   instance.address
  // );

  console.log("swapping 2 arth for 1 usdt and 3 busd");

  const tx = await instance.test(
    "100000000000000000", // uint256 amountArthInMax,
    "10000000000000000", // uint256 amountUSDTOut,
    "10000000000000000", // uint256 amountUSDCOut,
    "20000000000000000", // uint256 amountBUSDOut,
    "0x5C0c3270CF60CaC4d2D8845e4AF6f9f7F3b6B308", // address to,
    Math.floor(Date.now() / 1000) + 3600 // uint256 deadline
  );

  console.log("swap", tx.hash);
}

const approve = async (addr: string, amount: string, whom: string) => {
  const erc20 = await ethers.getContractAt("ERC20", addr);
  const tx = await erc20.approve(whom, amount);
  console.log("approve", addr, tx.hash);
  await tx.wait(3);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
