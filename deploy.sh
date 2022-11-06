#!/bin/bash

export ETH_RPC_URL='https://eth-goerli.g.alchemy.com/v2/k-jYAANHqECw4itc_Y8Hn1f7XRXhr86K'
forge create Exchange --private-key "$1" --constructor-args 0 # 0 for demo 60