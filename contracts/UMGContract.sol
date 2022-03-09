// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RandomlyAssigned.sol";

contract UMGContract is ERC721, Ownable, RandomlyAssigned {


    /*
    * Private Variables
    */
    uint256 private constant NUMBER_OF_RESERVED_UNICORNS = 2;
    uint256 private constant MAX_SUPPLY = 10;

    //Price that the mint will be costing to the consumers
    uint256 public mintPrice = 0.05 ether;
    //Determines the number of tokens that have been minted
    uint256 public totalSupply;
    //Determines the maximum amount of tokens that can be minted
    //uint256 public maxSupply = 10;
    //Determines the maximum number that a wallet can mint
    uint256 public maxMintingPerWallet = 10;
    //Toggle that determines consumers can mint the NFTs
    bool public isMintEnabled;
    //Dictionary-like object that keeps track of the number of mints that each wallet has done
    mapping(address => uint256) public mintedWallets;

    constructor() payable ERC721('Unicorn Motorcycle Gang', 'UNICORN') RandomlyAssigned(MAX_SUPPLY, NUMBER_OF_RESERVED_UNICORNS){
        //maxSupply = 10;
    }

    function toggleIsMintEnabled() external onlyOwner{
        isMintEnabled = !isMintEnabled;
    }

    function setMaxMintingPerWallet(uint256 _maxMintingPerWallet) external onlyOwner{
        maxMintingPerWallet = _maxMintingPerWallet;
    }

/*
    function setMaxSupply(uint256 _maxSupply) external onlyOwner{
        maxSupply = _maxSupply;
    }
*/

    function mint(uint256 num) external payable{
        //Checks if mint is enabled
        require(isMintEnabled, 'minting not enabled');
        //Checks number of mints per NFT
        require(mintedWallets[msg.sender] < 1, 'exceeds max per wallet');
        //Checks if the value of price that the costumer calling thins function is the same as the nft
        require(msg.value == mintPrice * num, 'wrong value');
        //Checks if there's still nft supply
        //require(maxSupply > totalSupply, 'sold out');
        require(MAX_SUPPLY > totalSupply, 'sold out');
        //Checks if it exceeds supply
        //require(maxSupply > totalSupply + num, 'exceeds maximum supply');
        require(MAX_SUPPLY > totalSupply + num, 'exceeds maximum supply');
        //Checks if the number of nfts to mint are not above the permited treshold
        require(num <  maxMintingPerWallet, 'You can mint a maximum of 10');

        //Saves number of mints per wallet
        mintedWallets[msg.sender] = num;
        //Increases the number of how many mints have been done
        totalSupply += num;

        /*
        //Local variable to save gas on the totalSupply change of value
        uint256 tokenId = totalSupply;
        //Hanldes the minting of the nft
        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, tokenId + i );
        }
        */

        //Hanldes the minting of the nft
        for(uint256 i; i < num; i++){
            //_safeMint( msg.sender, tokenId + i );
            uint256 tokenId = nextToken();
		    //assert(tokenId > NUMBER_OF_RESERVED_UNICORNS && tokenId <= maxSupply);
            assert(tokenId > NUMBER_OF_RESERVED_UNICORNS && tokenId <= MAX_SUPPLY);
		    _safeMint(msg.sender, tokenId);
        }
    }
}