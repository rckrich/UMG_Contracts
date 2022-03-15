async function main() {
    const {
        keccak256,
        toBuffer,
        ecsign,
        bufferToHex,
      } = require("ethereumjs-utils");
      const { ethers } = require('ethers');
    
      // create an object to match the contracts struct
      const CouponTypeEnum = {
        Genesis: 0,
        Author: 1,
        Presale: 2,
      };
    
      let coupons = {};
    
      for (let i = 0; i < presaleAddresses.length; i++) {
        const userAddress = ethers.utils.getAddress(presaleAddresses[i]);
        const hashBuffer = generateHashBuffer(
          ["uint256", "address"],
          [CouponTypeEnum["Presale"], userAddress]
        );
        const coupon = createCoupon(hashBuffer, signerPvtKey);
        
        coupons[userAddress] = {
          coupon: serializeCoupon(coupon)
        };
      }
}

// HELPER FUNCTIONS
function createCoupon(hash, signerPvtKey) {
    return ecsign(hash, signerPvtKey);
}

function generateHashBuffer(typesArray, valueArray) {
    return keccak256(
    toBuffer(ethers.utils.defaultAbiCoder.encode(typesArray,
    valueArray))
    );
}

function serializeCoupon(coupon) {
    return {
    r: bufferToHex(coupon.r),
    s: bufferToHex(coupon.s),
    v: coupon.v,
    };
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });