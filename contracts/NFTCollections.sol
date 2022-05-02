//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollections is Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _collectionIds;

  // Status of a collection (0: created, 1: published, 2: cancelled, 3: requestPlanUpgrade)

  struct CollectionData {
    CollectionInfo collectionInfo;
    MintingInfo mintingInfo;
    ContactData contactData;
    MarketplaceInfo marketplaceInfo;
    string[] tags;
    string paymentPlan;
    bool isVariablePaymentPlan;
    uint256 status;
  }

  struct CollectionInfo {
    address owner;
    uint256 id;
    string name;
    string description;
    string imageURI;
    string blockchain;
    uint256 totalSupply;
  }

  struct MintingInfo {
    uint256 mintDate;
    uint256 price;
  }

  struct ContactData {
    string websiteURL;
    string twitter;
    string discord;
    string email;
  }

  struct MarketplaceInfo {
    string openseaURL;
  }

  struct PaymentPlanHistory {
    uint256 startDate;
    string paymentPlan;
  }

  mapping(uint256 => CollectionData) collections;
  mapping(address => bool) hasCollection;
  mapping(uint256 => PaymentPlanHistory[]) paymentPlanHistory;

  event CollectionCreated(
    address owner,
    uint256 collectionId, 
    string name
  );

  event CollectionUpdated(
    address owner,
    uint256 collectionId, 
    string name
  );

  event CollectionPublished(
    address owner,
    uint256 collectionId, 
    string name
  );

  event CollectionCancelled(
    address owner,
    uint256 collectionId, 
    string name
  );

  event CollectionRequestPlanUpgrade(
    address owner,
    uint256 collectionId, 
    string name
  );

  modifier onlyOneCollectionByWallet() {
    require(hasCollection[msg.sender] == false, "Only one collection can be created per wallet");
    _;
  }

  modifier onlyOwnerOfCollection(uint256 _collectionId) {
    require(collections[_collectionId].collectionInfo.owner == msg.sender, "Only the owner of the collection can perform this action");
    _;
  }

  function createCollection(
    string memory _name, 
    string memory _description, 
    string memory _imageURI,
    string memory _blockchain,
    uint256 _totalSupply, 
    uint256 _mintDate, 
    uint256 _price,
    string[] memory _contactData,
    string[] memory _marketplaceData,
    string[] memory _tags,
    string memory _paymentPlan
  ) public onlyOneCollectionByWallet {
    _collectionIds.increment();

    CollectionData memory collectionData = CollectionData(
      CollectionInfo(
        msg.sender,
        _collectionIds.current(),
        _name,
        _description,
        _imageURI,
        _blockchain,
        _totalSupply
      ),
      MintingInfo(
        _mintDate,
        _price
      ),
      ContactData(
        _contactData[0],
        _contactData[1],
        _contactData[2],
        _contactData[3]
      ),
      MarketplaceInfo(
        _marketplaceData[0]
      ),
      _tags,
      _paymentPlan,
      false,
      0
    );

    collections[_collectionIds.current()] = collectionData;
    hasCollection[msg.sender] = true;

    PaymentPlanHistory memory _paymentPlanHistory = PaymentPlanHistory(
      0,
      _paymentPlan
    );
    paymentPlanHistory[_collectionIds.current()].push(_paymentPlanHistory);

    emit CollectionCreated(
      msg.sender,
      _collectionIds.current(),
      _name
    );
  }

  function editCollection(
    uint256 _collectionId,
    string memory _name, 
    string memory _description, 
    string memory _imageURI,
    string memory _blockchain,
    uint256 _totalSupply, 
    uint256 _mintDate, 
    uint256 _price,
    string[] memory _contactData,
    string[] memory _marketplaceData,
    string[] memory _tags
  ) public onlyOwnerOfCollection(_collectionId) {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.collectionInfo.name = _name;
    collectionData.collectionInfo.description = _description;
    collectionData.collectionInfo.imageURI = _imageURI;
    collectionData.collectionInfo.blockchain = _blockchain;
    collectionData.collectionInfo.totalSupply = _totalSupply;
    collectionData.mintingInfo.mintDate = _mintDate;
    collectionData.mintingInfo.price = _price;
    collectionData.contactData.websiteURL = _contactData[0];
    collectionData.contactData.twitter = _contactData[1];
    collectionData.contactData.discord = _contactData[2];
    collectionData.contactData.email = _contactData[3];
    collectionData.marketplaceInfo.openseaURL = _marketplaceData[0];
    collectionData.tags = _tags;
    collections[_collectionId] = collectionData;

    emit CollectionUpdated(
      msg.sender,
      _collectionId,
      _name
    );
  }

  function upgradePlan(uint256 _collectionId, string memory _paymentPlan) public onlyOwnerOfCollection(_collectionId) {
    CollectionData memory collectionData = collections[_collectionId];
    PaymentPlanHistory memory _paymentPlanHistory = PaymentPlanHistory(
      0,
      _paymentPlan
    );
    paymentPlanHistory[_collectionId].push(_paymentPlanHistory);
    collectionData.status = 3;
    collections[_collectionId] = collectionData;

    emit CollectionRequestPlanUpgrade(
      msg.sender,
      _collectionId,
      collectionData.collectionInfo.name
    );
  }

  function publishCollection(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].startDate = block.timestamp;
    if (!collectionData.isVariablePaymentPlan) {
      collectionData.paymentPlan = paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].paymentPlan;
    }
    collectionData.status = 1;
    collections[_collectionId] = collectionData;

    emit CollectionPublished(
      msg.sender,
      _collectionId,
      collectionData.collectionInfo.name
    );
  }

  function cancelCollection(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.status = 2;
    collections[_collectionId] = collectionData;

    emit CollectionCancelled(
      msg.sender,
      _collectionId,
      collectionData.collectionInfo.name
    );
  }

  function startVariablePlan(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.isVariablePaymentPlan = true;
    collections[_collectionId] = collectionData;
  }

  function endVariablePlan(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.isVariablePaymentPlan = false;
    collections[_collectionId] = collectionData;
  }
}