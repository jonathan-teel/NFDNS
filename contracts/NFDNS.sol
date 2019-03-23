// @title NFDNS - Non Fungible DNS
// @author Jonathan Teel 
// @dev Manage NF tokens (edoms) like a DNS

pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract ERC20 {
  function transfer(address _to, uint256 _amount) public returns (bool success);
  function balanceOf(address tokenOwner) public view returns (uint balance);
}


contract NFDNS is ERC721Metadata, Ownable {

  address public marketAddress;

  uint256 public edomMaxLength;
  uint256 public edomMinLength;
  uint256 public edomMaxAmount;
  uint256 public edomMaxFree;
  uint256 public edomCurrentTotal;

  string public baseUrl = "";

  mapping(string=>bool) edomOwnership;
  mapping(address=>uint256) edomOwnerAmount;
  mapping(string=>uint256) edomNameToId;
  mapping(string=>address) edomNameToAddress;

  struct EDom {
    string edomName;
    uint256 timeAlive;
    uint256 timeLastMove;
    address prevOwner;
    string edomLink;
  }

  EDom[] public edoms;

  modifier isMarketAddress() {
    require(msg.sender == marketAddress);
    _;
  }

  event edomMinted(address edomOwner, uint256 edomId, string edomName);
  event edomSlotPurchase(address edomOwner, uint256 amt);
  event edomCostUpdated(uint256 cost);
  event edomLengthReqChange(uint256 edomMinLength, uint256 edomMaxLength);
  event edomMaxAmountChange(uint256 edomMaxAmount);

  constructor() public ERC721Metadata("NFDNS", "NFDNS") {
    edomMaxLength = 16;
    edomMinLength = 2;
    edomMaxAmount = 100;
  }

  function edomMint(string calldata _edomName, string calldata _edomUri) external returns (string memory) {
    string memory sn = edomitize(_edomName);
    EDom memory s = EDom({
        edomName: sn,
        timeAlive: block.timestamp,
        timeLastMove: block.timestamp,
        prevOwner: msg.sender,
        edomLink: _edomUri
    });
    uint256 edomId = edoms.push(s).sub(1);
    edomOwnership[sn] = true;
    _edomMint(edomId, msg.sender, _edomUri, sn);
    return sn;
  }

  function getedomOwner(uint256 _edomId) public view returns (address) {
    return ownerOf(_edomId);
  }

  function getedomIdFromName(string memory _edomName) public view returns (uint256) {
    return edomNameToId[_edomName];
  }

  function getedomName(uint256 _edomId) public view returns (string memory) {
    return edoms[_edomId].edomName;
  }

  function getedomLink(uint256 _edomId) public view returns (string memory) {
    return edoms[_edomId].edomLink;
  }

  function getedomTimeAlive(uint256 _edomId) public view returns (uint256) {
    return edoms[_edomId].timeAlive;
  }

  function getedomTimeLastMove(uint256 _edomId) public view returns (uint256) {
    return edoms[_edomId].timeLastMove;
  }

  function getedomPrevOwner(uint256 _edomId) public view returns (address) {
    return edoms[_edomId].prevOwner;
  }

  function getAddressFromedom(string memory _edomName) public view returns (address) {
    return edomNameToAddress[_edomName];
  }

  // used for initial check to not waste gas
  function getedomitized(string calldata _edomName) external view returns (string memory) {
    return edomitize(_edomName);
  }

  function marketSale(uint256 _edomId, string calldata _edomName, address _prevOwner, address _newOwner) external isMarketAddress {
    EDom storage s = edoms[_edomId];
    s.prevOwner = _prevOwner;
    s.timeLastMove = block.timestamp;
    edomNameToAddress[_edomName] = _newOwner;
    edomOwnerAmount[_prevOwner] = edomOwnerAmount[_prevOwner].sub(1);
    edomOwnerAmount[_newOwner] = edomOwnerAmount[_newOwner].add(1);
  }

  function() external payable { revert(); }

  // OWNER FUNCTIONS

  function setedomLength(uint256 _length, uint256 _pos) external onlyOwner {
    require(_length > 0);
    if(_pos == 0) edomMinLength = _length;
    else edomMaxLength = _length;
    emit edomLengthReqChange(edomMinLength, edomMaxLength);
  }

  function setedomMaxAmount(uint256 _amount) external onlyOwner {
    edomMaxAmount = _amount;
    emit edomMaxAmountChange(edomMaxAmount);
  }

  function setedomMaxFree(uint256 _edomMaxFree) external onlyOwner {
    edomMaxFree = _edomMaxFree;
  }

  function setMarketAddress(address _marketAddress) public onlyOwner {
    marketAddress = _marketAddress;
  }

  function setBaseUrl(string memory _baseUrl) public onlyOwner {
    baseUrl = _baseUrl;
  }

  function updateTokenUri(uint256 _edomId, string memory _newUri) public onlyOwner {
    EDom storage s = edoms[_edomId];
    s.edomLink = _newUri;
    _setTokenURI(_edomId, strConcat(baseUrl, _newUri));
  }

  function specialedomMint(string calldata _edomName, string calldata _edomageUri, address _address) external onlyOwner returns (string memory) {
    EDom memory s = EDom({
        edomName: _edomName,
        timeAlive: block.timestamp,
        timeLastMove: block.timestamp,
        prevOwner: _address,
        edomLink: _edomageUri
    });
    uint256 edomId = edoms.push(s).sub(1);
    _edomMint(edomId, _address, _edomageUri, _edomName);
    return _edomName;
  }

  // INTERNAL FUNCTIONS

  function edomitize(string memory _edomName) internal view returns(string memory) {
    string memory sn = edomToLower(_edomName);
    require(isValidedom(sn), "edom is not valid");
    require(!edomOwnership[sn], "edom is not unique");
    return sn;
  }

  function _edomMint(uint256 _edomId, address _owner, string memory _edomageUri, string memory _edomName) internal {
    require(edomOwnerAmount[_owner] < edomMaxAmount, "max edom owned");
    edomNameToId[_edomName] = _edomId;
    edomNameToAddress[_edomName] = _owner;
    edomOwnerAmount[_owner] = edomOwnerAmount[_owner].add(1);
    edomCurrentTotal = edomCurrentTotal.add(1);
    _mint(_owner, _edomId);
    _setTokenURI(_edomId, strConcat(baseUrl, _edomageUri));
    emit edomMinted(_owner, _edomId, _edomName);
  }

  // Valid edom is [ANY].[ANY] at minLength < edom.length < maxLength
  function isValidedom(string memory _edomName) internal view returns(bool) {
    bytes memory wb = bytes(_edomName);
    uint slen = wb.length;
    if (slen > edomMaxLength || slen <= edomMinLength) return false;
    bytes1 space = bytes1(0x20);
    bytes1 period = bytes1(0x2E);
    // edom can not end in .eth 
    bytes1 e = bytes1(0x65);
    bytes1 t = bytes1(0x74);
    bytes1 h = bytes1(0x68);
    uint256 dCount = 0;
    uint256 eCount = 0;
    uint256 eth = 0;
    for(uint256 i = 0; i < slen; i++) {
        if(wb[i] == space) return false;
        else if(wb[i] == period) {
          dCount = dCount.add(1);
          if(dCount > 1) return false;
          eCount = 1;
        } else if(eCount > 0 && eCount < 5) {
          if(eCount == 1) if(wb[i] == e) eth = eth.add(1);
          if(eCount == 2) if(wb[i] == t) eth = eth.add(1);
          if(eCount == 3) if(wb[i] == h) eth = eth.add(1);
          eCount = eCount.add(1);
        }
    }
    if(dCount == 0) return false;
    if((eth == 3 && eCount == 4) || eCount == 1) return false;
    return true;
  }

  function edomToLower(string memory _edomName) internal pure returns(string memory) {
    bytes memory b = bytes(_edomName);
    for(uint256 i = 0; i < b.length; i++) {
      b[i] = byteToLower(b[i]);
    }
    return string(b);
  }

  function byteToLower(bytes1 _b) internal pure returns(bytes1) {
    if(_b >= bytes1(0x41) && _b <= bytes1(0x5A))
      return bytes1(uint8(_b) + 32);
    return _b;
  }

  function strConcat(string memory _a, string memory _b) internal pure returns(string memory) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length.add(_bb.length));
    bytes memory bab = bytes(ab);
    uint256 k = 0;
    for (uint256 i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
    for (uint256 i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
    return string(bab);
  }

}
