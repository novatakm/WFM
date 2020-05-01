import numpy as np
import itertools
import argparse

parser = argparse.ArgumentParser(
    description='caluculate the inverse matrix of a covariance matrix')
parser.add_argument(
    '--cov_list', nargs='*', help='covariance matrix elements as list. elements are arranged from top-left to bottom-right on the matrix')
parser.add_argument(
    '--dim', help='the dimention of the cov-matrx')
args = parser.parse_args()


def main():
    dim = int(args.dim)
    cov = np.array(args.cov_list, dtype=np.float64)
    cov = cov.reshape(dim, dim)
    cov_inv = np.linalg.inv(cov)

    for i, j in itertools.product(range(dim), range(dim)):
        print(cov_inv[i][j], end=" ")


if __name__ == '__main__':
    main()
