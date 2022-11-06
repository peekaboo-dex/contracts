<img src="https://github.com/peekaboo-dex/contracts/blob/main/peekaboo.png" width="35%" height="35%"/>

# Summary
Peekaboo is a blind auction for NFTs that improves upon existing mechanisms, like the ENS auction. Sealed bids are encrypted using assymetric (RSA) encryption, where the secret key is revealed only after a verifiable-delay function (VDF) is solved. The secret key is used to reveal all bids are  simultaneously as soon as the auction is closed. Only one reveal is required on-chain, which is to declare the winning bid. Our auction has a lower amortized cost and more seamless user-experience than existing NFT auctions on Ethereum. This is made possible by the novel 2021 <a href="https://eprint.iacr.org/2021/1293.pdf" target="_blank">TIDE Encryption Scheme</a>, which we adapted to Ethereum by decrypting in a smart contract. 

# How it Works






# Dev
#### Python Dependencies for Demo and Cryptography library
```
pip3 install sympy
pip3 install gaussianprimes
pip3 uninstall pycrypto # Ensure this is not installed
pip3 install pycryptodome
pip3 install w3
pip3 install web3
```




1. Auctioneer generates a VDF and sends it to us privately (off-chain)
2. Bidder wants to create a bid, they would have to send their bid to us and we would generate the sealed for them, which they would publish on-chain
3. 



--------

1. Generate a ZKP with the VDF

