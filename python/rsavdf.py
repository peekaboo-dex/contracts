#Use Python3.8
#Gen as subroutine of Setup

import math
import time
import random
import numpy as np
from Crypto.Util import number
from Crypto.Hash import SHAKE256

#Verifier Setup - Setup the modulus a Blum Integer
def Setup(x, bits, t):
    def genPrime(bits):
        potential_prime = 1
        while potential_prime % 4 == 1:
            potential_prime = number.getPrime(bits)
        return potential_prime

    x = 0
    while x <1: 
        p = genPrime(bits)
        q = genPrime(bits)
        if p != q and q % 4 != 1:
            N = p * q
            pp = N
        x += 1

    def Gen(pp,t):
        N = pp
        J_p, J_q = 1, 1
        while not  (J_p == 1 and J_q != 1) and not (J_q == 1 and J_p != 1):
            x = random.randrange(2,N)
            J_p = pow(x,(p-1)//2,p)             #Always == 1 or == p-1, use Euler's Criterion
            J_q = pow(x,(q-1)//2,q)             #Always == 1 or == q-1, use Euler's Criterion
        x_0 = pow(x,2,N)

        #now generate x_minus_t
        omega_p = (p + 1) // 4  #Tonelli Shanks, need p = 3 mod 4, Extend Eulers Criterion for proof
        omega_q = (q + 1) // 4  #Tonelli Shanks, need q = 3 mod 4, Extend Eulers Criterion for proof
        alpha_p = pow(x_0, pow(omega_p,t,p-1), p) #reduce mod p-1 is Eulers Theorem
        alpha_q = pow(x_0, pow(omega_q,t,q-1), q) #reduce mod p-1 is Eulers Theorem
        x_minus_t = ((alpha_p * q * pow(q,-1,p)) + (alpha_q * p * pow(p,-1,q))) % N #Chinese Remainder Theorem to find Mod N. 
        C = (x, x_0, x_minus_t)
        return C, t
    #t = 1000000
    C, t = Gen(pp, t)
    return pp, C, t

#Verifier Encrypt
def Enc(m, pp, e): #e is typically 65537, the most common RSA exponent due to low Hamming weight
    N = pp
    c = pow(m, e, N) #textbook RSA, no OEAP padding https://en.wikipedia.org/wiki/Optimal_asymmetric_encryption_paddingj
    return c

#Prover Eval
def Eval(pp, C, t):
    x = C[0]
    x_0 = C[1]
    x_minus_t = C[2]
    N = pp
    #evaluation of VDF here
    x_prime = pow(x_minus_t, pow(2,t-1), N) #hard work here

    #now use EEA to find the factors of N
    factor1 = math.gcd(x-x_prime, N)
    #factor2 = math.gcd(x+x_prime, N) #O(M(N)logN)
    factor2 = N//factor1 #O(M(N)), so logN better than finding gcd
    y = (factor1, factor2)
    return y


#Prover Decrypt
def Dec(C, y, c, pp, e):
    N = pp
    p = y[0]
    q = y[1]
    carmichael = np.lcm.reduce([p - 1, q - 1])
    d = pow(e, -1, carmichael) #RSA secret key
    print("d: ", d)
    m = pow(c, d, N) #textbook RSA decrypt no OAEP padding
    return m

# run functions

if __name__ == '__main__':
    t = 100 # 10000000
    bid = 4729473984237489237429

    start_time = time.time()
    pp, C, t = Setup(1,128,t)
    print('\n')
    print('len(N)', len(bin(pp)) - 2)
    #print('N:', pp, '\nC:',  C,  '\nt:', t)
    print('Set:' , round(time.time() - start_time , 4), 'seconds')

    start_time = time.time()
    c = Enc(bid, pp, 65537) #change first parameter if you want a different message to be Enc
    print('c:', c)
    print('Enc:' , round(time.time() - start_time , 4), 'seconds')

    start_time = time.time()
    y = Eval(pp, C, t)
    print("p: ", y[0], ", q: ", y[1])
    print('Eva:' , round(time.time() - start_time , 4), 'seconds')

    start_time = time.time()
    m = Dec(C, y, c, pp, 65537)
    print('m:', m)
    print('Dec:' , round(time.time() - start_time , 4), 'seconds')