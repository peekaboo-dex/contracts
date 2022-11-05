
import sympy
from sympy.ntheory.primetest import is_gaussian_prime




# `security` is the security parameter. I believe it is OAEP.
#            https://en.wikipedia.org/wiki/Optimal_asymmetric_encryption_padding
#            https://en.wikipedia.org/wiki/Security_parameter  # From this I think it's just random text...
#            Ah yes - "Security parameters are usually..."
#            So it's just a string of 1's of length kappa
#            https://pycryptodome.readthedocs.io/en/latest/src/cipher/oaep.html#Crypto.Cipher.PKCS1_OAEP.new
#            
def generate(kappa, time):
    p = 1
    q = 1
    # Pick two primes between 1..kappa/2
    while p == q:
        # The function prime(j) on lines 3 and 4 is the Miller-Rabin Monte Carlo algorithm to generate kappa/2 gaussian primes
        # https://mathworld.wolfram.com/GaussianPrime.html 
        #   Gaussian primes - https://pypi.org/project/gaussianprimes/ 
        # https://docs.sympy.org/latest/modules/ntheory.html 
        p = sympy.randprime(0, kappa / 2)
        if not is_gaussian_prime(p):
            continue
        q = sympy.randprime(0, kappa / 2)
        if not is_gaussian_prime(q):
            continue

    print("p: ", p, "; q: ", q)

    N = p * q

    # Next we want to compute Jacobi Symbol 
    jacobi_symbol_px = sympy.ntheory.residue_ntheory.jacobi_symbol(p, x)
    jacobi_symbol_qx = sympy.ntheory.residue_ntheory.jacobi_symbol(q, x)




if __name__ == '__main__':
    generate(1000000, 7)