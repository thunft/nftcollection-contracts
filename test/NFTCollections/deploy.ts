import { ethers } from "hardhat";
import { deployNFTCollectionsContract } from "../../tasks/deploy/nftCollections";

describe("NFTCollections - Deploy", function () {
  it("Should deploy contract", async function () {
    await deployNFTCollectionsContract(ethers);
  });
});
