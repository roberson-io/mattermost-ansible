#! /usr/bin/env python3

import secrets
import sys


def generate_secret(length=64):
    return secrets.token_urlsafe(length)


if __name__ == "__main__":

    length = 64
    if len(sys.argv) > 1:
        try:
            length = int(sys.argv[1])
        except ValueError:
            print("Invalid length argument, using default length of 64.")
    print(generate_secret(length))
    sys.exit(0)
