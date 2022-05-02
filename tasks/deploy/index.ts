import { task } from "hardhat/config";
import { deployNFTCollectionsContract } from "./nftCollections";

task("deploy", "Deploy all contracts").setAction(async (taskArgs, hre) => {
  console.log("Deployment...");
  deployNFTCollectionsContract(hre.ethers);
});
