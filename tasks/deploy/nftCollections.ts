import { HardhatEthersHelpers } from "@nomiclabs/hardhat-ethers/types";
import { ethers } from "ethers";

type Ethers = typeof ethers & HardhatEthersHelpers;

export const deployNFTCollectionsContract = async (ethers: Ethers) => {
  const nftCollectionsContractFactory = await ethers.getContractFactory(
    "NFTCollections"
  );
  const nftCollectionsContract = await nftCollectionsContractFactory.deploy();

  await nftCollectionsContract.deployed();

  console.log("NFTCollections deployed to:", nftCollectionsContract.address);

  return {
    nftCollectionsContract,
  };
};
