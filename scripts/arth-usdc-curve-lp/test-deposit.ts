/* eslint-disable node/no-missing-import */
import hre, { ethers } from "hardhat";
import { BigNumber } from "ethers";
import * as config from "./constants";
import { deployOrLoadAndVerify } from "../utils";

async function main() {
    const deployer = (await ethers.getSigners())[0];

    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: ["0xf977814e90da44bfa03b6295a0616a897441acec"] // impersonate binance wallet for now; has 1bn USDC
    });

    const e18 = BigNumber.from(10).pow(18);
    const e6 = BigNumber.from(10).pow(6);

    const whale = await ethers.getSigner("0xf977814e90da44bfa03b6295a0616a897441acec");

    console.log("Deploying USDCCurveLogic...");
    const USDCCurveLogic = await deployOrLoadAndVerify("USDCCurveLogic", "USDCCurveLogic", []);
    const USDCCurveStrategy = await ethers.getContractFactory("USDCCurveStrategy", {
        libraries: { USDCCurveLogic: USDCCurveLogic.address }
    });

    console.log("Deploying contract");
    const instance = await USDCCurveStrategy.deploy();
    console.log("Tx submitted");
    await instance.deployed();
    console.log("USDCCurveStrategy deployed to:", instance.address);

    console.log("Initializing...");
    (
        await instance.initialize(
            config.usdcAddr, // address _usdc,
            config.arthAddr, // address _arth,
            config.mahaAddr, // address _maha,
            config.curveLp,
            config.varDebtArth,
            config.lendingPoolAddr, // address _lendingPool,
            config.stableSwapAddr, // address _liquidityPool,
            86400 * 30, // uint256 _rewardsDuration,
            config.priceFeedAddr, // address _priceFeed,
            config.treasury, // address _treasury,
            deployer.address // address _owner
        )
    ).wait();

    const usdc = await ethers.getContractAt("IERC20", config.usdcAddr);
    const arth = await ethers.getContractAt("IERC20", config.arthAddr);
    const lp = await ethers.getContractAt("IERC20", config.curveLp);

    await usdc.connect(whale).approve(instance.address, e18);
    console.log("usdc bal whale", await usdc.balanceOf(whale.address));

    console.log("seeding LP", whale.address);
    await instance.connect(whale).seedLP(e6.mul(100));
    console.log("LP bal contract", await lp.balanceOf(instance.address));

    console.log("opening position", whale.address);
    await instance.connect(whale).deposit(e6.mul(100), 0);

    console.log(
        "minLiquidityReceived",
        await instance.minLiquidityReceived(e6.mul(100), e18.mul(208).div(100))
    );
    console.log("position", await instance.positions(whale.address));
    console.log("usdc bal whale", await usdc.balanceOf(whale.address));
    console.log("LP bal contract", await lp.balanceOf(instance.address));

    console.log("closing position", whale.address);
    await instance.connect(whale).withdraw();

    console.log("position", await instance.positions(whale.address));
    console.log("LP bal contract", await lp.balanceOf(instance.address));
    console.log("arth bal contract", await arth.balanceOf(instance.address));
    console.log("usdc bal contract", await usdc.balanceOf(instance.address));
    console.log("usdc bal treasury", await usdc.balanceOf(config.treasury));
    console.log("usdc bal whale", await usdc.balanceOf(whale.address));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
