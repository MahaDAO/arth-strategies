import { AbiCoder } from "ethers/lib/utils";
import hre, { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { wait } from "../../utils";

async function main() {
  // deploy libraries
  console.log("deploying LeverageLibraryBSC");
  const leverageLibraryAddress = "0x36F3ab22614927605b52d3abaea8Fa9f852Cc1fF";
  const LeverageLibraryBSC = await ethers.getContractFactory("LeverageLibraryBSC");
  const leverageLibrary = leverageLibraryAddress
    ? await ethers.getContractAt("LeverageLibraryBSC", leverageLibraryAddress)
    : await LeverageLibraryBSC.deploy();
  console.log("LeverageLibraryBSC at", leverageLibrary.address);
  leverageLibraryAddress == null && (await wait(15 * 1000)); // wait 15 sec

  // deploy libraries
  console.log("deploying TroveLibrary");
  const troveLibaryAddress = "0x016084191E5FD9F8250EA43261ec7B44DD10beb2";
  const TroveLibrary = await ethers.getContractFactory("TroveLibrary");
  const troveLibrary = troveLibaryAddress
    ? await ethers.getContractAt("TroveLibrary", troveLibaryAddress)
    : await TroveLibrary.deploy();
  console.log("TroveLibrary at", troveLibrary.address);
  troveLibaryAddress == null && (await wait(15 * 1000)); // wait 15 sec

  console.log("deploying ApeSwapExposureUSDT");

  // We get the contract to deploy
  const ApeSwapExposureUSDT = await ethers.getContractFactory("ApeSwapExposureUSDT", {
    libraries: {
      LeverageLibraryBSC: leverageLibrary.address,
      TroveLibrary: troveLibrary.address
    }
  });

  const args1 = [
    "0x91aBAa2ae79220f68C0C76Dd558248BA788A71cD", // address _flashloan,
    "0xb69a424df8c737a122d0e60695382b3eec07ff4b", // address _arth,
    "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", // address _usdc,
    "0xe9e7cea3dedca5984780bafc599bd69add087d56", // address _busd,
    "0x603c7f932ed1fc6575303d8fb018fdcbb0f39a95", // address _rewardToken,
    "0xf808ecc6d51FA40Af5b1C3Dadf6c366e5cD943ec", // address _ellipsis,
    "0x88fd584df3f97c64843cd474bdc6f78e398394f4", // address _arthUsd,
    "0xcf0febd3f17cef5b47b0cd257acf6025c5bff3b7" // address _uniswapRouter
  ];

  const args2 = [
    "0x3f3cdCC49599600EeaF7c6e11Da2E377BDEE95cA", // address _borrowerOperations,
    "0x0F7e695770E1bC16a9A899580828e22B16d93314", // address _troveManager,
    "0x9c66D9475e8492963F98c8B2642C8e5F50EE695f", // address _priceFeed,
    "0xBb9858603B1FB9375f6Df972650343e985186Ac5", // address _stakingWrapper,
    "0x3A076D0EBF9ff41473071864bf23Afdbd77A253E" // address _accountRegistry
  ];

  const encoder = new AbiCoder();
  const data1 = encoder.encode(
    ["address", "address", "address", "address", "address", "address", "address", "address"],
    args1
  );
  const data2 = encoder.encode(["address", "address", "address", "address", "address"], args2);

  const instance = await ApeSwapExposureUSDT.deploy(data1, data2);

  await instance.deployed();
  console.log("ApeSwapExposureUSDT deployed to:", instance.address);

  await wait(20 * 1000); // wait for 20s

  await hre.run("verify:verify", {
    address: leverageLibrary.address
  });

  await hre.run("verify:verify", {
    address: troveLibrary.address
  });

  await hre.run("verify:verify", {
    address: instance.address,
    constructorArguments: [data1, data2]
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});

// import hre, { ethers } from "hardhat";
// // eslint-disable-next-line node/no-missing-import
// import { wait } from "../../utils";

// async function main() {
//   console.log("deploying ApeSwapExposure");

//   // We get the contract to deploy
//   const QuickSwapExposure = await ethers.getContractFactory("ApeSwapExposureUSDT");
//   const instance = await QuickSwapExposure.deploy(
//     "0x91aBAa2ae79220f68C0C76Dd558248BA788A71cD", // address _flashloan,
//     "0xb69a424df8c737a122d0e60695382b3eec07ff4b", // address _arth,
//     "0x55d398326f99059ff775485246999027b3197955", // address _usdt,
//     "0xe9e7cea3dedca5984780bafc599bd69add087d56", // address _busd,
//     "0x603c7f932ed1fc6575303d8fb018fdcbb0f39a95", // address _rewardToken,
//     "0xf808ecc6d51FA40Af5b1C3Dadf6c366e5cD943ec", // address _ellipsis,
//     "0x88fd584df3f97c64843cd474bdc6f78e398394f4", // address _arthUsd,
//     "0xcf0febd3f17cef5b47b0cd257acf6025c5bff3b7" // address _uniswapRouter
//   );

//   await instance.deployed();
//   console.log("ApeSwapExposure deployed to:", instance.address);

//   await instance.init(
//     "0xE4E773433Be8cc3ABDa9Bb5393C97336F27AE76b", // address _borrowerOperations,
//     "0x7A535496c5a0eF6A9B014A01e1aB9d7493F503ea", // address _troveManager,
//     "0xD23d824A9938DC490075CeAc311820312267A517", // address _priceFeed,
//     "0xc5FB6476a6518dd35687e0Ad2670CB8Ab5a0D4C5", // address _stakingWrapper,
//     "0x3A076D0EBF9ff41473071864bf23Afdbd77A253E" // address _accountRegistry
//   );

//   console.log("done init");

//   await wait(20 * 1000); // wait for a minute

//   await hre.run("verify:verify", {
//     address: instance.address,
//     constructorArguments: [
//       "0x91aBAa2ae79220f68C0C76Dd558248BA788A71cD", // address _flashloan,
//       "0xb69a424df8c737a122d0e60695382b3eec07ff4b", // address _arth,
//       "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", // address _usdc,
//       "0xe9e7cea3dedca5984780bafc599bd69add087d56", // address _busd,
//       "0x603c7f932ed1fc6575303d8fb018fdcbb0f39a95", // address _rewardToken,
//       "0xf808ecc6d51FA40Af5b1C3Dadf6c366e5cD943ec", // address _ellipsis,
//       "0x88fd584df3f97c64843cd474bdc6f78e398394f4", // address _arthUsd,
//       "0xcf0febd3f17cef5b47b0cd257acf6025c5bff3b7" // address _uniswapRouter
//     ]
//   });
// }

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main().catch(error => {
//   console.error(error);
//   process.exitCode = 1;
// });
