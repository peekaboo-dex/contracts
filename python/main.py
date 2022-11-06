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
    tokenId = 2090420
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
        self.w3 = Web3(Web3.WebsocketProvider("wss://eth-goerli.g.alchemy.com/v2/k-jYAANHqECw4itc_Y8Hn1f7XRXhr86K"))
        self.exchangeAddress = exchangeAddress
        self.tokenAbi = json.load(open("out/ERC721.sol/ERC721.json"))["abi"]
        self.token =  self.w3.eth.contract(address=self.tokenAddress, abi=self.tokenAbi)
        self.exchangeAbi = json.load(open("out/Exchange.sol/Exchange.json"))["abi"]
        self.exchange = self.w3.eth.contract(address=exchangeAddress, abi=self.exchangeAbi)

    def exec(self, fn):
        tx = fn.buildTransaction({
            'from': self.account.address,
            'nonce': self.w3.eth.get_transaction_count(self.account.address)
        })
        signedTx = self.w3.eth.account.sign_transaction(tx, self.privateKey)
        txHash = self.w3.eth.send_raw_transaction(signedTx.rawTransaction)
        txReceipt = self.w3.eth.wait_for_transaction_receipt(txHash)
        print(txReceipt)

    def setApproval(self):
        self.exec(self.token.functions.approve(self.exchangeAddress, self.tokenId))

    def startAuction(self, publicKey, puzzle):
        self.exec(self.exchange.functions.createAuction(self.tokenAddress, self.tokenId, publicKey, puzzle))



demo_description = """
Runs Demo
"""
@click.command(help=demo_description)
@click.option('--contract', type=str, default="", help='Exchange contract address')
def demo(contract):
    ### Create Auctioneer and set NFT aproval
    print("******* Setting Approval for NFT")
    auctioneerPrivateKey = "0x2b479a94b50a0d4f445f0c9344586e977f8f57fb39428dcdcb32db3d116cd63f"
    auctioneer = Actor(auctioneerPrivateKey, contract)
    auctioneer.setApproval()

    #### First thing we do is setup the auction puzzle
    print("******* Setting up auction (off-chain)")
    t = 10000
    publicKey, puzzle, _ = rsavdf.Setup(1, 128, t)
    hexEncodedPuzzle = hexEncodePuzzle(puzzle)

    ### Start auction
    print("******** Starting Auction (on-chain)")
    auctioneer.startAuction(publicKey, hexEncodedPuzzle)

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