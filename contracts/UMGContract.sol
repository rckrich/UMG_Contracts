// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RandomlyAssigned.sol";

contract UMGContract is ERC721, Ownable, RandomlyAssigned {

    /*
    * Private Variables
    */
    uint256 private constant NUMBER_OF_RESERVED_UNICORNS = 2;
    uint256 private constant MAX_SUPPLY = 10;
	uint256 private constant MAX_MINTS_PER_WALLET = 2;

	/*
	 * Public Variables
	 */
    uint256 public mintPrice = 0.05 ether;
    uint256 public totalSupply;

    bool public isMintEnabled;

    mapping(address => uint256) public mintedWallets;

    constructor() payable ERC721('Unicorn Motorcycle Gang', 'UNICORN') RandomlyAssigned(MAX_SUPPLY, NUMBER_OF_RESERVED_UNICORNS){

	}

    // ======================================================== Owner Functions

    function toggleIsMintEnabled() external onlyOwner{
        isMintEnabled = !isMintEnabled;
    }

    function disbursePayments(
		address[] memory payees_,
		uint256[] memory amounts_
	) external onlyOwner {
		require(
			payees_.length == amounts_.length,
			'Payees and amounts length mismatch'
		);
		for (uint256 i; i < payees_.length; i++) {
			makePaymentTo(payees_[i], amounts_[i]);
		}
	}

    function makePaymentTo(address address_, uint256 amt_) private {
		(bool success, ) = address_.call{value: amt_}('');
		require(success, 'Transfer failed.');
	}

	// ======================================================== External Functions

    function mint(uint256 count) 
		external 
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count)
	{
        require(isMintEnabled, 'minting not enabled');
        require(count > 0, 'num is 0 or below');
        require(mintedWallets[msg.sender] + count <= MAX_MINTS_PER_WALLET, 'exceeds max per wallet');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS > totalSupply, 'sold out');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS >= totalSupply + count, 'exceeds maximum supply');
        require(count <=  MAX_MINTS_PER_WALLET, 'You only can mint a maximum of 10');

        mintedWallets[msg.sender] += count;
        totalSupply += count;

        for(uint256 i; i < count; i++){
		    _mintRandomId(msg.sender);
        }
    }

// ======================================================== Internal Functions

	function _mintRandomId(address to) private {
        uint256 tokenId = nextToken();
        assert(tokenId > NUMBER_OF_RESERVED_UNICORNS && tokenId <= MAX_SUPPLY);
        _safeMint(to, tokenId);
    }

// ======================================================== Modifiers

	modifier validateEthPayment(uint256 count) {
		require(
			mintPrice * count == msg.value,
			'Ether value sent is not correct'
		);
		_;
	}

}