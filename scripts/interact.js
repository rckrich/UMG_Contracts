// interact.js

const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;

const contract = require("../artifacts/contracts/UMGContract.sol/UMGContract.json");

// provider - Alchemy
const alchemyProvider = new ethers.providers.AlchemyProvider(network="ropsten", API_KEY);

// signer - you
const signer = new ethers.Wallet(PRIVATE_KEY, alchemyProvider);

// contract instance
const umg_contract = new ethers.Contract(CONTRACT_ADDRESS, contract.abi, signer);

// ======================================================== Interact Internal Functions

//Test - Change 'contractPaused' bool
async function InteractCircuitBreaker(){
    console.log("Pausing contract...");
    const fn = await umg_contract.circuitBreaker();
    await fn.wait();
    GetContractPaused();
}

//Test - Change 'mintPrice' uint256
async function InteractAdjustMintPrice(_newPrice){
    console.log("Changing mint price...");
    const fn = await umg_contract.adjustMintPrice(_newPrice);
    await fn.wait();
    GetMintPrice();
}

//Test - Toggle 'isMintEnabled' bool
async function InteractToggleIsMintEnabled(){
    console.log("Changing isMintEnabled...");
    const fn = await umg_contract.toggleIsMintEnabled();
    await fn.wait();
    GetIsMintEnabled();
}

//Test - Change sale phase uint256
async function InteractEnterPhase(phase){
    console.log("Changing sale phase...");
    const fn = await umg_contract.enterPhase(phase);
    await fn.wait();
    GetPhase();
}

//Test - Add addresses to white list
async function InteractAddAddressesToWhiteList(address){
    console.log("Setting address to be in white list...");
    const fn = await umg_contract.addAddressesToWhiteList(address);
    await fn.wait();
    IsInWhiteList(address);
}

//Test - Claim Reserved Tokens to an address
async function InteractClaimReservedTokens(address, tokensId){
    console.log("Claiming tokens to an address...");
    const fn = await umg_contract.claimReservedTokens(address, tokensId);
    await fn.wait();
}

//Test - Claim Reserved Tokens to an address
async function InteractDisbursePayments(addresses, amounts){
    console.log("Claiming tokens to an address...");
    const fn = await umg_contract.disbursePayments(addresses, amounts);
    await fn.wait();
}

// ======================================================== Interact External Functions

//Test - Mint Presale
async function InteractPresaleMint(addresses, amounts){
    console.log("Presale minting...");
    const fn = await umg_contract.mintPresale(1);
    await fn.wait();
}

//Test - Mint
async function InteractMint(addresses, amounts){
    console.log("Minting...");
    const fn = await umg_contract.mint(1);
    await fn.wait();
}

// ======================================================== Interact Getters Functions

//Test - Get 'mintPrice' uint256
async function GetMintPrice(){
    const mintPrice = await umg_contract.mintPrice();
    console.log("The mint price is: " + mintPrice); 
}

//Test - Get 'reservedTokensMinted' uint256
async function GetReservedTokensMinted(){
    const reservedTokensMinted = await umg_contract.reservedTokensMinted();
    console.log("The reserved tokens minted is: " + reservedTokensMinted); 
}

//Test - Get 'reservedTokensMinted' uint256
async function GetWhiteListCounter(){
    const whiteListCounter = await umg_contract.whiteListCounter();
    console.log("The white list counter is: " + whiteListCounter); 
}

//Test - Get 'reservedTokensMinted' uint256
async function GetPhase(){
    const phase = await umg_contract.phase();
    console.log("The current phase is: " + phase); 
}

//Test - Get 'contractPaused' bool
async function GetContractPaused(){
    const contractPaused = await umg_contract.contractPaused();
    console.log("The contract is paused? " + contractPaused); 
}

//Test - Get 'isMintEnabled' bool
async function GetIsMintEnabled(){
    const isMintEnabled = await umg_contract.isMintEnabled();
    console.log("Is mint enabled? " + isMintEnabled); 
}

//Test - Get '_isInWhiteList' bool from an address
async function IsInWhiteList(address){
    const wallets = await umg_contract.wallets();
    console.log("Is in white list? " + wallets[address]._isInWhiteList); 
}

//Test - Get '_numberOfMintsByAddress' uint256 from an address
async function GetNumberOfMintsByAddress(address){
    const wallets = await umg_contract.wallets();
    console.log("The number of mints this wallet has made is " + wallets[address]._numberOfMintsByAddress); 
}

async function main() {
    const fn = await GetContractPaused();
}

main();