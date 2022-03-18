async function main() {
   const UMGContract = await ethers.getContractFactory("UMGContract");

   // Start deployment, returning a promise that resolves to a contract object
   const umg_contract = await UMGContract.deploy();   
   console.log("Contract deployed to address:", umg_contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });