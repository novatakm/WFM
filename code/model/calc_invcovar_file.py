import numpy as np
import argparse

parser = argparse.ArgumentParser(
    description='caluculate the inverse matrix of a covariance matrix')
parser.add_argument(
    'cov_file', help='text file that contains covariance matrix elements')
parser.add_argument(
    'cov_inv_file', help='text file to which the inverse covar matrx elements are dumped')
args = parser.parse_args()


def main():
    cov = np.loadtxt(args.cov_file, delimiter=" ", skiprows=1)
    cov_inv = np.linalg.inv(cov)
    # np.dot(cov, cov_inv))
    np.savetxt(args.cov_inv_file, cov_inv, delimiter=" ")


if __name__ == '__main__':
    main()
