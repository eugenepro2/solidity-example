// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract GPU is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IERC20 public immutable dealToken;

    address constant USDC = 0xB57ee0797C3fc0205714a577c02F7205bB89dF30;
    uint32 [] public upgradableList = [100, 250, 500, 750, 990];

    struct Upgradable {
        uint32 value;
        uint256 priceInMNB;
    }

    struct Rarity {
        uint256 priceInUsd;
        uint8 level;
        uint32 power;
    }

    struct Token {
        uint8 rarity; //from 1 to 10
        uint32 createTimestamp;
        uint32 durability; // 100, 250, 500, 750, 900 - by default is 100
        uint32 efficiency; // 100, 250, 500, 750, 900 - by default is 100
        uint32 power; 
        bool isBroken;
        bool stakeFreeze; //Freeze token when staking
    }

    struct TokensViewFront {
        uint tokenId;
        uint8 rarity;
        address tokenOwner;
        uint32 durability;
        uint32 efficiency;
        uint32 power;
        uint32 createTimestamp;
        bool stakeFreeze;
        bool isBroken;
        string uri;
    }

    Rarity[] public rarityList;
    // Upgradable[] private _upgradableList;
    mapping(uint => Token) private _tokens; // TokenId => Token

    constructor() ERC721("GPU", "GPU") {
        _tokenIdCounter.increment();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        dealToken = IERC20(USDC);

        rarityList.push(Rarity({level: 1, priceInUsd: 100 ether, power: 50}));
        rarityList.push(Rarity({level: 2, priceInUsd: 200 ether, power: 100}));
        rarityList.push(Rarity({level: 3, priceInUsd: 300 ether, power: 150}));
        rarityList.push(Rarity({level: 4, priceInUsd: 400 ether, power: 200}));
        rarityList.push(Rarity({level: 5, priceInUsd: 500 ether, power: 250}));
        rarityList.push(Rarity({level: 6, priceInUsd: 600 ether, power: 300}));
        rarityList.push(Rarity({level: 7, priceInUsd: 700 ether, power: 350}));
        rarityList.push(Rarity({level: 8, priceInUsd: 800 ether, power: 400}));
        rarityList.push(Rarity({level: 9, priceInUsd: 900 ether, power: 450}));
        rarityList.push(Rarity({level: 10, priceInUsd: 1000 ether, power: 500}));

        _upgradableList.push(Upgradable({value: 250, priceInMNB: 200 ether}));
        _upgradableList.push(Upgradable({value: 500, priceInMNB: 400 ether}));
        _upgradableList.push(Upgradable({value: 750, priceInMNB: 800 ether}));
        _upgradableList.push(Upgradable({value: 990, priceInMNB: 1600 ether}));

    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.tokens.com/";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _getRarityObject(uint id) private view returns (Rarity memory) {
        return rarityList[id-1];
    }

    function safeMint(address to, uint8 rarity) public {
        // dealToken.transferFrom(msg.sender, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, _getRarityObject(rarity).priceInUsd);


        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();


        _tokens[tokenId].rarity = rarity;
        _tokens[tokenId].power = _getRarityObject(rarity).power;
        _tokens[tokenId].durability = 100;
        _tokens[tokenId].efficiency = 100;
        _tokens[tokenId].createTimestamp = uint32(block.timestamp);
        _safeMint(to, tokenId);
    }

    function getToken(uint _tokenId) public view returns (TokensViewFront memory) {
        require(_exists(_tokenId), "ERC721: token does not exist");
        Token memory token = _tokens[_tokenId];
        TokensViewFront memory tokenReturn;
        tokenReturn.tokenId = _tokenId;
        tokenReturn.rarity = token.rarity;
        tokenReturn.power = token.power;
        tokenReturn.tokenOwner = ownerOf(_tokenId);
        tokenReturn.durability = token.durability;
        tokenReturn.efficiency = token.efficiency;
        tokenReturn.stakeFreeze = token.stakeFreeze;
        tokenReturn.isBroken = token.isBroken;
        tokenReturn.createTimestamp = token.createTimestamp;
        tokenReturn.uri = tokenURI(_tokenId);
        return (tokenReturn);
    }

    function durabilityIncrease(uint _tokenId) public {
        require(_exists(_tokenId), "ERC721: token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not owner of token");
        require(!_tokens[_tokenId].stakeFreeze, "ERC721: Token frozen");
        require(!(_tokens[_tokenId].durability == upgradableList[4]), "Max upgrade");

        Token storage curToken = _tokens[_tokenId];
        curToken.durability = _nextLevel(curToken.durability);
    }

    function efficiencyIncrease(uint _tokenId) public {
        require(_exists(_tokenId), "ERC721: token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not owner of token");
        require(!_tokens[_tokenId].stakeFreeze, "ERC721: Token frozen");
        require(!(_tokens[_tokenId].efficiency == upgradableList[4]), "Max upgrade");

        Token storage curToken = _tokens[_tokenId];
        curToken.efficiency = _nextLevel(curToken.efficiency);
    }

    function _nextLevel(uint32 prevValue) internal returns (uint32){
        for (uint i = 0; i < upgradableList.length; i++) {
            if(upgradableList[i] == prevValue) {
                return upgradableList[i+1];
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
