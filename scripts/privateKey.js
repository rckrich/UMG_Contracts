async function main() {
    const { privateToAddress } = require("ethereumjs-utils");
    const { ethers } = require("ethers");
    const crypto = require("crypto");
    const pvtKey = crypto.randomBytes(32);
    const pvtKeyString = pvtKey.toString("hex");
    const signerAddress = ethers.utils.getAddress(
    privateToAddress(pvtKey).toString("hex"));
    console.log({ signerAddress, pvtKeyString });
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });