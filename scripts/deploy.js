async function main() {
   const UMGContract = await ethers.getContractFactory("UMGContractTest");

   // Start deployment, returning a promise that resolves to a contract object
   const umg_contract = await UMGContract.deploy("ipfs://QmcYgAUZuL9HLLF7SYmRgzN1idmCX4AStxcksNE5QAntZq/");   
   console.log("Contract deployed to address:", umg_contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });