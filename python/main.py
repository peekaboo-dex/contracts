import click 
import rsavdf
import time
from web3 import Web3
from eth_account import Account
import json


def hexEncodePuzzle(C):
    if len(C) != 3:
        raise Exception("Expected puzzle of length 3")
    puzzleComponents = ["0x{:064x}".format(entry) for entry in C]
    puzzle = "0x%s%s%s"%(puzzleComponents[0][2:], puzzleComponents[1][2:], puzzleComponents[2][2:])
    if len(puzzle) != 64*3 + 2:
        print(C)
        print(puzzleComponents)
        print(puzzle)
        raise Exception("Bad encoding of puzzle!")

    #print(C)
    return puzzle

def hexDecodePuzzle(puzzle):
    if puzzle[0:2] != "0x":
        raise Exception("Puzzle must be hex")
    elif len(puzzle) != (64 * 3) + 2:
        raise Exception("Puzzle malformed.")

    C = [
        int('0x%s'%(puzzle[2:][:64]), base=16),
        int('0x%s'%(puzzle[2:][64:128]), base=16),
        int('0x%s'%(puzzle[2:][128:192]), base=16)
    ]

    return C


@click.group()
def messages():
  pass

setup_description = """
Setup a Public Key and Puzzle to solve for a Secret Key.
"""
@click.command(help=setup_description)
@click.option('--bits', type=int, default="", help='How many bits of encryption.')
@click.option('--t', type=int, help='Difficulty of puzzle. This is input to a t-squarings VDF. ')
def setup(bits, t):
    pp, C, _ = rsavdf.Setup(1, bits, t)
    print({
        "publicKey": pp,
        "puzzle": hexEncodePuzzle(C)
    })

solve_description = """
Solves an input puzzle
"""
@click.command(help=solve_description)
@click.option('--public-key', type=int, default="", help='A public key')
@click.option('--puzzle', type=str, help='A puzzle')
@click.option('--t', type=int, help='Difficulty of the puzzle')
def solve(public_key, puzzle, t):
    start_time = time.time()
    y = rsavdf.Eval(public_key, hexDecodePuzzle(puzzle), t)
    delay = round(time.time() - start_time , 4)
    print({
        "p": y[0],
        "q": y[1],
        "delay": delay
    })




# https://web3py.readthedocs.io/en/stable/contracts.html
# ACCOUNTS - https://eth-account.readthedocs.io/en/latest/eth_account.html#eth_account.account.Account.create_with_mnemonic
# https://web3py.readthedocs.io/en/stable/contracts.html?highlight=transact#web3.contract.ContractFunction.transact
# https://docs.moonbeam.network/builders/build/eth-api/libraries/web3py/

class Actor(object):
    tokenAddress = "0xf5de760f2e916647fd766B4AD9E85ff943cE3A2b"
    tokenId = 2090417
    tokenAbi = None
    exchangeAbi = None
    privateKey = None
    exchangeAddress = None
    account = None
    w3 = None
    token = None

    def __init__(self, privateKey, exchangeAddress):
        self.privateKey = privateKey
        self.account = Account.from_key(privateKey)
        print("address = ", self.account.address)
        self.w3 = Web3(Web3.WebsocketProvider("wss://eth-goerli.g.alchemy.com/v2/k-jYAANHqECw4itc_Y8Hn1f7XRXhr86K"))
        self.exchangeAddress = exchangeAddress
        self.tokenAbi = json.load(open("out/ERC721.sol/ERC721.json"))["abi"]
        self.token =  self.w3.eth.contract(address=self.tokenAddress, abi=self.tokenAbi)
        self.exchangeAbi = json.load(open("out/Exchange.sol/Exchange.json"))["abi"]
        self.exchange = self.w3.eth.contract(address=exchangeAddress, abi=self.exchangeAbi)

    def call(self, fn):
        print(fn.call())

    def exec(self, fn, value = 0):
        tx = fn.buildTransaction({
            'from': self.account.address,
            'nonce': self.w3.eth.get_transaction_count(self.account.address),
            'value': value
        })
        signedTx = self.w3.eth.account.sign_transaction(tx, self.privateKey)
        txHash = self.w3.eth.send_raw_transaction(signedTx.rawTransaction)
        txReceipt = self.w3.eth.wait_for_transaction_receipt(txHash)
        return txReceipt

    def setApproval(self):
        print("Setting approval to %s for %d"%(self.exchangeAddress, self.tokenId))
        self.exec(self.token.functions.approve(self.exchangeAddress, self.tokenId))

    def startAuction(self, publicKey, puzzle):
        print("Auctioning token id = ", self.tokenId)
        fn = self.exchange.functions.createAuction(self.tokenAddress, self.tokenId, publicKey, puzzle)
        auctionId = fn.call({'from': self.address()})
        self.exec(fn)
        return auctionId

    def commitBid(self, auctionId, sealedBid, ethToSend):
        self.exec(self.exchange.functions.commitBid(auctionId, sealedBid), ethToSend)

    def revealBid(self, auctionId, bidder):
        self.exec(self.exchange.functions.revealBid(auctionId, bidder))

    def closeAuction(self, auctionId, p, q, d):
        self.exec(self.exchange.functions.closeAuction(auctionId, p, q, d))

    def finalizeAuction(self, auctionId):
        self.exec(self.exchange.functions.finalizeAuction(auctionId))

    def readSealedBid(self, auctionId, bidder):
        return self.call(self.exchange.functions.sealedBids(auctionId, bidder))

    def address(self):
        return self.account.address



demo_description = """
Runs Demo
"""
@click.command(help=demo_description)
@click.option('--contract', type=str, default="", help='Exchange contract address')
def demo(contract):
    # T-Squarrings!
    t = 13000000

    ### Create Auctioneer and set NFT aproval
    print("******* Setting Approval for NFT")
    auctioneerPrivateKey = "0x2b479a94b50a0d4f445f0c9344586e977f8f57fb39428dcdcb32db3d116cd63f"
    auctioneer = Actor(auctioneerPrivateKey, contract)
    auctioneer.setApproval()

    #### First thing we do is setup the auction puzzle
    print("******* Setting up auction (off-chain)")
    publicKey, puzzle, _ = rsavdf.Setup(1, 128, t)
    hexEncodedPuzzle = hexEncodePuzzle(puzzle)
    print("Public Key: ", publicKey)
    print("hexPuzzle: ", hexEncodedPuzzle)

    ### Start auction
    print("******** Starting Auction (on-chain)")
    auctionId = auctioneer.startAuction(publicKey, hexEncodedPuzzle)
    print("AuctionId=", auctionId)

    ### Send bids
    ### In the demo we want the NFT to cycle back to him so we can demo on loop
    print("******** Submitting bids (on-chain)")
    bid = 1000
    sealedBid = rsavdf.Enc(bid, publicKey, 65537)
    auctioneer.commitBid(auctionId, sealedBid, 1000)
    print("sealedBid = ", sealedBid)


    '''
    ### Send Bids
    bidderPrivateKeys = [
        "0x3b479a94b50a0d4f445f0c9344586e977f8f57fb39428dcdcb32db3d116cd63f", # 0x867Dfc2Db0406451521528BcA135Fb1f772786E3 
        "0x4b479a94b50a0d4f445f0c9344586e977f8f57fb39428dcdcb32db3d116cd63f", # 0xF789F38b269Baf9913e70B6C91f4F622Cb3B47aB
        "0x5b479a94b50a0d4f445f0c9344586e977f8f57fb39428dcdcb32db3d116cd63f", # 0x896789824e8FAfA2372fF418944CD53aAe76aA00
        "0x6b479a94b50a0d4f445f0c9344586e977f8f57fb39428dcdcb32db3d116cd63f", # 0x41D34dd62686bF75b8666150D49D5046C7aAA945
        "0x7b479a94b50a0d4f445f0c9344586e977f8f57fb39428dcdcb32db3d116cd63f"  # 0xa6A8260db44C169Bd94CD7b6809B595382A8F832
    ]
    bidders = [Actor(k, contract) for k in bidderPrivateKeys]
    for bidder in bidders:
        bidder.

    '''


    ### Solve Puzzle
    print("******* Solving Puzzle")
    start_time = time.time()
    y,d = rsavdf.Eval(publicKey, puzzle, t)
    p = y[0]
    q = y[1]
    delay = round(time.time() - start_time , 4)
    print("******* Solved Cryprographic Puzzle in %ds"%delay)
    print("p=", p)
    print("q=", q)
    print("d=", d)

    ### Close the Auction
    print("******* Closing Auction")
    auctioneer.closeAuction(auctionId, p, q, d)

    ### Reveal the bid of winner -- who is the auctioneer, for the purposes of the demo.
    ### (this is so the NFT cycles from auctioneer, to auction, back to auctioneer) and we can restart.
    print("******* Revealing Winning Bid! (Only winner has to be revealed)")
    print("Revealing for winner=", auctioneer.address())
    auctioneer.revealBid(auctionId, auctioneer.address())

    ### 
    print("******* Finalizing Auction (Settlement)")
    auctioneer.finalizeAuction(auctionId)
 

    '''



    ### TODO: Start auction on Ethereum


    sleep 5
    
    ### Start solving puzzle
    


    start_time = time.time()
    y = rsavdf.Eval(public_key, hexDecodePuzzle(puzzle), t)
    delay = round(time.time() - start_time , 4)
    print({
        "p": y[0],
        "q": y[1],
        "delay": delay
    })
    '''





messages.add_command(setup)
messages.add_command(solve)
messages.add_command(demo)
if __name__ == '__main__':
    messages()