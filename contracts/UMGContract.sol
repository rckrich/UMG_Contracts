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

    constructor() payable ERC721('Unicorn Motorcycle Gang', 'UNICORN') RandomlyAssigned(MAX_SUPPLY, NUMBER_OF_RESERVED_UNICORNS){

	}

    // ======================================================== Owner Functions

	function circuitBreaker() public onlyOwner {
		if (contractPaused == false) { 
			contractPaused = true; 
		}else{ 
			contractPaused = false; 
		}
	}

	function setMintPrice(uint256 _mintPrice)
		external
		onlyOwner
		checkIfPaused()
	{
		mintPrice = _mintPrice;
	}

    function toggleIsMintEnabled() external onlyOwner{
        isMintEnabled = !isMintEnabled;
    }

	function addAddresToWhiteList(address[] memory _whiteList)
		external
		onlyOwner
		checkIfPaused()
	{
		for (uint256 i; i < _whiteList.length; i++) {
			whiteList[whiteListCounter] = _whiteList[i];
			whiteListCounter++;
		}
	}

	function claimReservedTokens(address to, uint256[] memory tokensId) 
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

    function makePaymentTo(address address_, uint256 amt_) private {
		(bool success, ) = address_.call{value: amt_}('');
		require(success, 'Transfer failed.');
	}

	// ======================================================== External Functions

	function whiteListMint(uint256 count) 
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

	function _mintRandomId(address to) private {
        uint256 tokenId = nextToken();
        assert(tokenId > NUMBER_OF_RESERVED_UNICORNS && tokenId <= MAX_SUPPLY);
        _safeMint(to, tokenId);
    }

	function _searchInWhiteList(address to) private view returns(bool) {
		
		for (uint256 i; i < whiteList.length; i++) {
			if(whiteList[i] == to)
			return true;
		}

		return false;
	}

// ======================================================== Modifiers

	modifier validateEthPayment(uint256 count) {
		require(
			mintPrice * count == msg.value,
			'Ether value sent is not correct'
		);
		_;
	}

	modifier checkIfPaused() {
		require(contractPaused == false);
		_;
	}

}