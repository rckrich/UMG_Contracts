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
    uint256 private constant MAX_TEAM_UNICORNS = 5;
    uint256 private constant MAX_SUPPLY = 10;
    uint256 private constant MAX_MINTS_PER_WALLET = 2;
    uint256 private constant MAX_PRESALE_MINTS_PER_WALLET = 2;

    struct MintTypes {
		uint256 _numberOfAuthorMintsByAddress;
		uint256 _numberOfMintsByAddress;
	}

    struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

	enum CouponType {
		Author,
		Presale
	}

	enum SalePhase {
		Locked,
		PreSale,
		PublicSale
	}

    address private immutable _adminSigner;

	/*
	 * Public Variables
	 */
    uint256 public mintPrice = 0.05 ether;
    uint256 public tokensMinted;
    uint256 public teamTokensMinted;

    bool public isMintEnabled;

    SalePhase public phase = SalePhase.Locked;

    mapping(address => MintTypes) public mintedWallets;

    constructor(address adminSigner) payable 
		ERC721('Unicorn Motorcycle Gang', 'UNICORN') 
		RandomlyAssigned(MAX_SUPPLY, NUMBER_OF_RESERVED_UNICORNS)
	{
        _adminSigner = adminSigner;
    }

    // ======================================================== Owner Functions

    function toggleIsMintEnabled() external onlyOwner{
        isMintEnabled = !isMintEnabled;
    }

	function enterPhase(SalePhase phase_) external onlyOwner {
		require(uint8(phase_) > uint8(phase), 'can only advance phases');
		phase = phase_;
	}

/*
    function setMaxSupply(uint256 _maxSupply) external onlyOwner{
        maxSupply = _maxSupply;
    }
*/

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

    function claimAuthorTokens(
		uint256 count,
		uint256 allotted,
		Coupon memory coupon
	) public ensureAvailabilityFor(count) {
		require(isMintEnabled, 'Claim event is not active');
		bytes32 digest = keccak256(
			abi.encode(CouponType.Author, allotted, msg.sender)
		);
		require(_isVerifiedCoupon(digest, coupon), 'Invalid coupon');
		require(
			count + mintedWallets[msg.sender]._numberOfAuthorMintsByAddress <=
				allotted,
			'Exceeds number of earned Tokens'
		);
		mintedWallets[msg.sender]._numberOfAuthorMintsByAddress += count;
		for (uint256 i; i < count; i++) {
			_mintRandomId(msg.sender);
		}
	}

	function mintPresale(uint256 count, Coupon memory coupon)
		external
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count)
	{
		require(isMintEnabled, 'minting not enabled');
		require(phase == SalePhase.PreSale, 'Presale event is not active');
		require(
			count + mintedWallets[msg.sender]._numberOfMintsByAddress <=
				MAX_PRESALE_MINTS_PER_WALLET,
			'Exceeds number of presale mints allowed'
		);
		bytes32 digest = keccak256(abi.encode(CouponType.Presale, msg.sender));
		require(_isVerifiedCoupon(digest, coupon), 'Invalid coupon');

		mintedWallets[msg.sender]._numberOfMintsByAddress += count;

		for (uint256 i; i < count; i++) {
			_mintRandomId(msg.sender);
		}
	}

    function mint(uint256 count) 
		external 
		payable 
		ensureAvailabilityFor(count)
		validateEthPayment(count)
	{
        require(isMintEnabled, 'minting not enabled');
		require(phase == SalePhase.PublicSale, 'Public sale is not active');
        require(count > 0, 'num is 0 or below');
        require(mintedWallets[msg.sender]._numberOfMintsByAddress + count <= MAX_MINTS_PER_WALLET, 'exceeds max per wallet');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS > tokensMinted, 'sold out');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS >= tokensMinted + count, 'exceeds maximum supply');
        require(count <=  MAX_MINTS_PER_WALLET, 'You only can mint a maximum of 10');

        mintedWallets[msg.sender]._numberOfMintsByAddress += count;
        tokensMinted += count;

        for(uint256 i; i < count; i++){
            _mintRandomId(msg.sender);
        }
        
    }

    // ======================================================== Internal Functions

	function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
		internal
		view
		returns (bool)
	{
		address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
		require(signer != address(0), 'ECDSA: invalid signature'); // Added check for zero address
		return signer == _adminSigner;
	}

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