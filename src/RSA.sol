// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RSA {

    uint256 constant RSA_EXPONENT = 65537;

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

    // https://gist.github.com/3esmit/8c0a63f17f2f2448cc1576eb27fe5910
    function _gcd(uint256 a, uint256 b) 
        internal
        pure 
        returns (uint256)
    {
        uint256 _a = a;
        uint256 _b = b;
        uint256 temp;
        while (_b > 0) {
            temp = _b;
            _b = _a % _b; // % is remainder
            _a = temp;
        }
        return _a;
    }

    // https://gist.github.com/3esmit/8c0a63f17f2f2448cc1576eb27fe5910
    function _lcm(uint256 a, uint256 b) 
        internal 
        pure
        returns (uint256)
    {
        return a * (b / _gcd(a, b));
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

    // secret key = (p,q)
    // rsa secret key = d
    // cipher text = c
    function decrypt(uint256 p, uint256 q, uint256 d, uint256 c) public view returns (uint256) {
        uint256 carmichael = _lcm(p-1, q-1);
        assertRSASecretKey(d, RSA_EXPONENT, carmichael);
        uint256 decryptedMsg = modexp(c, d, p * q);
        return decryptedMsg;
    }

    function test() external view {
        uint256 p = 318569511894869251183365247322746989427;
        uint256 q = 229368935536892518030042944070649018591;
        uint256 c = 53629025865139430364679661915032900130265525417328715334434279225847008244318;
        uint256 d = 30606828630747341320342876325314558354488034112734631821521054984032893479203;
        uint256 m = RSA(address(this)).decrypt(p,q,d,c);
        require(m == 4909101704780246817740844133125094986488746117432125378220703890793963498682, "Wrong msg!");
    }

    function test2() external view {
        uint256 p = 321468120460269735254387428377211480759;
        uint256 q = 249505636633195575851927474697079280003;
        uint256 c = 78655559279021081942405596879468611893634002148506921947911073772838248057208;
        uint256 d = 3022463304970956127216097266318907794410855742140214400938844241971289520253;
        uint256 m = RSA(address(this)).decrypt(p,q,d,c);
        require(m == 4729473984237489237429, "Wrong msg!");
    }
}