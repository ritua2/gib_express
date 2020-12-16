"""
BASICS

Computes the SHA256 checksum of a file
"""



import hashlib



# Computes the SHA 256 checksum of a file given its name
# Based on https://gist.github.com/rji/b38c7238128edf53a181
def sha256_checksum(filename, block_size=65536):
    sha256 = hashlib.sha256()
    with open(filename, 'rb') as f:
        for block in iter(lambda: f.read(block_size), b''):
            sha256.update(block)
    return sha256.hexdigest()
