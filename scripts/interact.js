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

async function InteractCircuitBreaker(){
    console.log("Pausing contract...");
    const fn = await umg_contract.circuitBreaker();
    await fn.wait();
}

async function GetContractPaused(){
    const contractPaused = await umg_contract.contractPaused();
    console.log("The message is: " + contractPaused); 
}

async function main() {
    const fn = await GetContractPaused();
}

main();