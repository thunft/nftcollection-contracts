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
    PaymentInfo paymentInfo;
    string[] tags;
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

  struct PaymentInfo {
    string paymentPlan;
    bool isVariablePaymentPlan;
  }

  struct MarketplaceInfo {
    string openseaURL;
  }

  struct PaymentPlanHistory {
    uint256 startDate;
    string paymentPlan;
    string paymentTxHash;
  }

  mapping(uint256 => CollectionData) collections;
  mapping(address => bool) hasCollection;
  mapping(uint256 => PaymentPlanHistory[]) paymentPlanHistory;

  event PaymentPlanHistoryAdded(
    uint256 collectionId, 
    uint256 startDate, 
    string paymentPlan,
    string paymentTxHash
  );

  event CollectionCreated(
    address owner,
    uint256 id,
    string name,
    string description,
    string imageURI,
    string blockchain,
    uint256 totalSupply,
    uint256 mintDate,
    uint256 price
  );

  event CollectionContactCreated(
    uint256 id,
    string websiteURL,
    string twitter,
    string discord,
    string email,
    string openseaURL,
    string[] tags,
    string paymentPlan,
    bool isVariablePaymentPlan,
    uint256 status
  );

  event CollectionUpdated(
    uint256 id,
    string name, 
    string description, 
    string imageURI,
    string blockchain,
    uint256 totalSupply, 
    uint256 mintDate, 
    uint256 price,
    string[] contactData,
    string[] marketplaceData,
    string[] tags
  );

  event CollectionPublished(
    uint256 id,
    string paymentPlan,
    uint256 status
  );

  event CollectionCancelled(
    uint256 id,
    uint256 status
  );

  event CollectionRequestPlanUpgrade(
    uint256 id, 
    string paymentPlan,
    uint256 status
  );

  event StartVariablePaymentPlan(
    uint256 id,
    bool isVariablePaymentPlan
  );

  event EndVariablePaymentPlan(
    uint256 id,
    bool isVariablePaymentPlan
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
    string[] memory _paymentInfo
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
      PaymentInfo(
        _paymentInfo[0],
        false
      ),
      _tags,
      0
    );

    collections[_collectionIds.current()] = collectionData;
    hasCollection[msg.sender] = true;

    PaymentPlanHistory memory _paymentPlanHistory = PaymentPlanHistory(
      0,
      _paymentInfo[0],
      _paymentInfo[1]
    );
    paymentPlanHistory[_collectionIds.current()].push(_paymentPlanHistory);

    emit PaymentPlanHistoryAdded(_collectionIds.current(), 0, _paymentInfo[0], _paymentInfo[1]);

    emit CollectionCreated(
      msg.sender,
      _collectionIds.current(),
      _name,
      _description,
      _imageURI,
      _blockchain,
      _totalSupply,
      _mintDate,
      _price
    );

    emit CollectionContactCreated(
      _collectionIds.current(),
      _contactData[0],
      _contactData[1],
      _contactData[2],
      _contactData[3],
      _marketplaceData[0],
      _tags,
      _paymentInfo[0],
      false,
      0
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
      _collectionId,
      _name,
      _description,
      _imageURI,
      _blockchain,
      _totalSupply,
      _mintDate,
      _price,
      _contactData,
      _marketplaceData,
      _tags
    );
  }

  function upgradePlan(uint256 _collectionId, string memory _paymentPlan, string memory _paymentTxHash) public onlyOwnerOfCollection(_collectionId) {
    CollectionData memory collectionData = collections[_collectionId];
    PaymentPlanHistory memory _paymentPlanHistory = PaymentPlanHistory(
      0,
      _paymentPlan,
      _paymentTxHash
    );
    paymentPlanHistory[_collectionId].push(_paymentPlanHistory);
    collectionData.status = 3;
    collections[_collectionId] = collectionData;

    emit PaymentPlanHistoryAdded(_collectionId, 0, _paymentPlan, _paymentTxHash);

    emit CollectionRequestPlanUpgrade(
      _collectionId,
      _paymentPlan,
      3
    );
  }

  function publishCollection(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].startDate = block.timestamp;
    if (!collectionData.paymentInfo.isVariablePaymentPlan) {
      collectionData.paymentInfo.paymentPlan = paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].paymentPlan;
    }
    collectionData.status = 1;
    collections[_collectionId] = collectionData;

    emit PaymentPlanHistoryAdded(
      _collectionId, 
      block.timestamp, 
      paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].paymentPlan,
      paymentPlanHistory[_collectionId][paymentPlanHistory[_collectionId].length - 1].paymentTxHash
    );

    emit CollectionPublished(
      _collectionId,
      collectionData.paymentInfo.paymentPlan,
      1
    );
  }

  function cancelCollection(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.status = 2;
    collections[_collectionId] = collectionData;

    emit CollectionCancelled(
      _collectionId,
      2
    );
  }

  function startVariablePaymentPlan(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.paymentInfo.isVariablePaymentPlan = true;
    collections[_collectionId] = collectionData;

    emit StartVariablePaymentPlan(
      _collectionId,
      true
    );
  }

  function endVariablePaymentPlan(uint256 _collectionId) public onlyOwner {
    CollectionData memory collectionData = collections[_collectionId];
    collectionData.paymentInfo.isVariablePaymentPlan = false;
    collections[_collectionId] = collectionData;

    emit EndVariablePaymentPlan(
      _collectionId,
      false
    );
  }
}