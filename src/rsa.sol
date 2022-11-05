// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
library rsa {

    // Baseline: calling EIP-198 precompile
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
    // The precompile is located at the address 0x00......05
    // and has inputs of the following format
    // <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>
    function modexp(uint256 b, uint256 e, uint256 N) internal view returns (uint256 xx) {
        assembly {
            let freemem := mload(0x40)
            // length_of_BASE: 32 bytes
            mstore(freemem, 0x20)
            // length_of_EXPONENT: 32 bytes
            mstore(add(freemem, 0x20), 0x20)
            // length_of_MODULUS: 32 bytes
            mstore(add(freemem, 0x40), 0x20)
            // BASE: The input x
            mstore(add(freemem, 0x60), b)
            // EXPONENT: (N + 1) / 4 = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52
            mstore(add(freemem, 0x80), e)
            // MODULUS: N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(add(freemem, 0xA0), N)
            let success := staticcall(
                sub(gas(), 2000),
                // call the address 0x00......05
                5,
                // loads the 6 * 32 bytes inputs from <freemem>
                freemem,
                0xC0,
                // stores the 32 bytes return at <freemem>
                freemem,
                0x20
            )
            xx := mload(freemem)
        }
    }

    // d is secret key
    function assertRSASecretKey(uint256 d, uint256 e, uint256 carmichael) internal pure {
        // To compute the RSA key, we would do:
        //       d = pow(e, -1, carmichael)
        // Note that:
        //       d * e [is congruent to] 1 (mod charmichael)
        // We can thus sanity check as follows:
        require(mulmod(d, e, carmichael) == 1, "Bad RSA Secret Key");
    }


    // function doit(uint256 p, uint256 q, uint256 lcm_pq, uint256 d, uint256 e) external {
    function doit() external pure returns (uint256) {

        // https://math.stackexchange.com/questions/586595/finding-modular-of-a-fraction
        // 1 / e % lcm_pq
        // Verify d
        // require(d * e == 1 % lcm_pq, "Invalid d");
        // d = pow()

        /* 

        c:  53629025865139430364679661915032900130265525417328715334434279225847008244318
        N:  73069949837833579517014046071513039757139829296612665023572018121217403437357
        p:  318569511894869251183365247322746989427
        q:  229368935536892518030042944070649018591
        carmichael:  36534974918916789758507023035756519878295945424590451627179304964912003714670
        e:  65537
        d:  30606828630747341320342876325314558354488034112734631821521054984032893479203
        m:  4909101704780246817740844133125094986488746117432125378220703890793963498682

        */

        uint256 c = 53629025865139430364679661915032900130265525417328715334434279225847008244318;
        uint256 d = 30606828630747341320342876325314558354488034112734631821521054984032893479203;
        uint256 N = 73069949837833579517014046071513039757139829296612665023572018121217403437357;
        uint256 e = 65537;
        uint256 carmichael = 36534974918916789758507023035756519878295945424590451627179304964912003714670;

        // Sanity check RSA secret key
        assertRSASecretKey(d, e, carmichael);


        // Last Check
        //uint256 decryptedMsg = modexp(c, d, N);
        //return decryptedMsg;


        //return (c ** d) % N;
    }
}
