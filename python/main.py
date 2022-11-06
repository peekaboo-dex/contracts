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
    privateKey = None



def execStartAuction(exchangeAddress, abi):
    ### INSTANTIATE WEB3
    privateKey = "0x2b479a94b50a0d4f445f0c9344586e977f8f57fb39428dcdcb32db3d116cd63f"
    account = Account.from_key(privateKey)
    w3 = Web3(Web3.WebsocketProvider("wss://eth-goerli.g.alchemy.com/v2/k-jYAANHqECw4itc_Y8Hn1f7XRXhr86K"))
   
    # The NFT
    tokenAddress = "0xf5de760f2e916647fd766B4AD9E85ff943cE3A2b"
    tokenId = 2090420
    tokenAbi = json.load(open("out/ERC721.sol/ERC721.json"))["abi"]

    token = w3.eth.contract(address=tokenAddress, abi=tokenAbi)
    tx = token.functions.approve(exchangeAddress, tokenId).buildTransaction({
        'from': account.address,
        'nonce': w3.eth.get_transaction_count(account.address)
    })
    signedTx = w3.eth.account.sign_transaction(tx, privateKey)
    txHash = w3.eth.send_raw_transaction(signedTx.rawTransaction)
    txReceipt = w3.eth.wait_for_transaction_receipt(txHash)
    print(txReceipt)
    exit(1)
    
    transact({'from': account.address})

    #.build_transaction({'nonce': web3.eth.get_transaction_count('0xF5...')})

    print("Approving NFT on Exchange (%s)"%txHash)
   

    

     
    exchange = w3.eth.contract(address=exchangeAddress, abi=abi["abi"])
    txHash = exchange.functions.createAuction(tokenAddress, tokenId, 0, "0x1234").transact({'from': account.address})
    #print(txHash)



'''

def execCommitBid():


def execRevealBid():

def execFinalizeAuction():

def 
'''


demo_description = """
Runs Demo
"""
@click.command(help=demo_description)
@click.option('--contract', type=str, default="", help='Exchange contract address')
def demo(contract):
    ### Read ABI
    abi = json.load(open("out/Exchange.sol/Exchange.json"))
    execStartAuction(contract, abi)

    '''

    #### First thing we do is setup the auction puzzle
    t = 10000
    publicKey, puzzle, _ = rsavdf.Setup(1, 128, t)

    ### Hex encode the puzzle for Ethereum
    hexEncodedPuzzle = hexEncodePuzzle(puzzle)

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