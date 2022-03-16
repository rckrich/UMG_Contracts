// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RandomlyAssigned.sol";

contract UMGContract is ERC721, Ownable, RandomlyAssigned {

    /*
    * Private Variables
    */
    uint256 private constant NUMBER_OF_RESERVED_UNICORNS = 20;
    uint256 private constant MAX_SUPPLY = 100;
	uint256 private constant MAX_MINTS_PER_WALLET = 10;

	enum SalePhase {
		Locked,
		PreSale,
		PublicSale
	}

	/*
	 * Public Variables
	 */
    uint256 public mintPrice = 0.05 ether;
    uint256 public tokensMinted;
	uint256 public reservedTokensMinted;
	uint256 public whiteListCounter;

	SalePhase public phase = SalePhase.Locked;
	
	bool public contractPaused = false;
    bool public isMintEnabled = false;

	address[] public whiteList;

    mapping(address => uint256) public mintedWallets;

	/*
	 * Constructor
	 */
    constructor() payable ERC721('Unicorn Motorcycle Gang', 'UNICORN') RandomlyAssigned(MAX_SUPPLY, NUMBER_OF_RESERVED_UNICORNS){

	}

    // ======================================================== Owner Functions

	/// Breaks and pauses contract interaction
	/// @dev modifies the state of the `contractPaused` variable
	function circuitBreaker() public onlyOwner {
		if (contractPaused == false) { 
			contractPaused = true; 
		}else{ 
			contractPaused = false; 
		}
	}

	// Adjust the mint price
	/// @dev modifies the state of the `mintPrice` variable
	/// @notice sets the price for minting a token
	/// @param _newPrice The new price for minting
	function adjustMintPrice(uint256 _newPrice)
		external
		onlyOwner
		checkIfPaused()
	{
		mintPrice = _newPrice;
	}

	/// Activate or deactivate minting
	/// @dev set the state of `isMintEnabled` variable to true or false
	/// @notice Activate or deactivate the minting event
    function toggleIsMintEnabled() external onlyOwner{
        isMintEnabled = !isMintEnabled;
    }

	/// Advance Phase
	/// @dev Advance the sale phase state
	/// @notice Advances sale phase state incrementally
	function enterPhase(SalePhase _phase) external onlyOwner {
		require(uint8(_phase) != uint8(phase), 'Can only change phases');
		phase = _phase;
	}

	/// Adds addresses to white list
	/// @dev Adds addresses to an internal list
	/// @notice Adds a number of addresses to an internal white list.
	/// @param _addedAddressesList The new addresses that wants to be added to the white list
	function addAddressesToWhiteList(address[] memory _addedAddressesList)
		external
		onlyOwner
		checkIfPaused()
	{
		for (uint256 i; i < _addedAddressesList.length; i++) {
			whiteList[whiteListCounter] = _addedAddressesList[i];
			whiteListCounter++;
		}
	}

	/// Adds an array of tokens to an address
	/// @dev Adds reserved tokens to an address that has been reserved
	/// @notice Adds reserved tokens to an address
	/// @param to recipient address
	/// @param tokensId The reserved tokens that will be added to the address
	function claimReservedTokens(
		address to,
		uint256[] memory tokensId
	) 
		external 
		onlyOwner 
		ensureAvailabilityFor(tokensId.length)
		checkIfPaused()
	{
		require(isMintEnabled, 'Minting not enabled');
		require(tokensId.length + mintedWallets[to] <= MAX_MINTS_PER_WALLET, 'Exceeds number of earned Tokens');
		require(NUMBER_OF_RESERVED_UNICORNS > reservedTokensMinted, 'Reserved tokens sold out');
        require(NUMBER_OF_RESERVED_UNICORNS >= reservedTokensMinted + tokensId.length, 'Exceeds reserved maximum supply');

		mintedWallets[to] += tokensId.length;
		reservedTokensMinted += tokensId.length;
		
		for (uint256 i; i < tokensId.length; i++) {
			uint256 tokenId = tokensId[i];
			assert(tokenId <= NUMBER_OF_RESERVED_UNICORNS);
			_safeMint(to, tokenId);
		}
	}

	/// Disburse payments
	/// @dev transfers amounts that correspond to addresses passeed in as args
	/// @param payees_ recipient addresses
	/// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
    function disbursePayments(
		address[] memory payees_,
		uint256[] memory amounts_
	) 
		external
	 	onlyOwner 
		checkIfPaused()
	{
		require(
			payees_.length == amounts_.length,
			'Payees and amounts length mismatch'
		);
		for (uint256 i; i < payees_.length; i++) {
			makePaymentTo(payees_[i], amounts_[i]);
		}
	}

	/// Make a payment
	/// @dev internal function called by `disbursePayments` to send Ether to an address
    function makePaymentTo(address address_, uint256 amt_) private {
		(bool success, ) = address_.call{value: amt_}('');
		require(success, 'Transfer failed.');
	}

	// ======================================================== External Functions

	/// Mint during presale
	/// @dev mints by addresses validated using the internal white list
	/// @notice mints tokens with randomized token IDs to addresses eligible for presale
	/// @param count number of tokens to mint in transaction
	function mintPresale(uint256 count) 
		external 
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count)
		checkIfPaused()
	{
		require(phase == SalePhase.PreSale, 'Not presale');
        require(isMintEnabled, 'Minting not enabled');
        require(count > 0, 'Count is 0 or below');
        require(mintedWallets[msg.sender] + count <= MAX_MINTS_PER_WALLET, 'Exceeds max per wallet');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS > tokensMinted, 'Sold out');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS >= tokensMinted + count, 'Exceeds maximum supply');
        require(count <=  MAX_MINTS_PER_WALLET, 'You only can mint a maximum of 10');
		require(_searchInWhiteList(msg.sender), 'Address not in white list');

        mintedWallets[msg.sender] += count;
        tokensMinted += count;

        for(uint256 i; i < count; i++){
		    _mintRandomId(msg.sender);
        }
    }

	/// Public minting open to all
	/// @dev mints tokens during public sale, limited by `MAX_MINTS_PER_WALLET`
	/// @notice mints tokens with randomized IDs to the sender's address
	/// @param count number of tokens to mint in transaction
    function mint(uint256 count) 
		external 
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count)
		checkIfPaused()
	{
		require(phase == SalePhase.PublicSale, "Not public sale");
        require(isMintEnabled, 'Minting not enabled');
        require(count > 0, 'Count is 0 or below');
        require(mintedWallets[msg.sender] + count <= MAX_MINTS_PER_WALLET, 'Exceeds max per wallet');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS > tokensMinted, 'Sold out');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS >= tokensMinted + count, 'Exceeds maximum supply');
        require(count <=  MAX_MINTS_PER_WALLET, 'You only can mint a maximum of 10');

        mintedWallets[msg.sender] += count;
        tokensMinted += count;

        for(uint256 i; i < count; i++){
		    _mintRandomId(msg.sender);
        }
    }

// ======================================================== Internal Functions

	/// @dev internal check to ensure a ID outside of the collection, doesn't get minted
	function _mintRandomId(address to) private {
        uint256 tokenId = nextToken();
        assert(tokenId > NUMBER_OF_RESERVED_UNICORNS && tokenId <= MAX_SUPPLY);
        _safeMint(to, tokenId);
    }

	/// @dev internal check to ensure an address is in the white list
	function _searchInWhiteList(address to) private view returns(bool) {
		
		for (uint256 i; i < whiteList.length; i++) {
			if(whiteList[i] == to)
			return true;
		}

		return false;
	}

// ======================================================== Modifiers

	/// Modifier to validate Eth payments on payable functions
	/// @dev compares the product of the state variable `mintPrice` and supplied `count` to msg.value
	/// @param count factor to multiply by
	modifier validateEthPayment(uint256 count) {
		require(
			mintPrice * count == msg.value,
			'Ether value sent is not correct'
		);
		_;
	}

	/// Modifier to validate that the contract is not puased
	/// @dev compares state of the variable `contractPaused` to ensure it is false
	modifier checkIfPaused() {
		require(contractPaused == false);
		_;
	}

}