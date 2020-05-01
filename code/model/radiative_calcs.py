import numpy as np
import pandas as pd
from scipy import integrate
from scipy import optimize
# import matplotlib
# matplotlib.use('PS')
# from matplotlib import pyplot as plt
import argparse

h = 6.626e-34
c = 3.0e+8
k = 1.38e-23


def planck(wl, T):
    a = 2.0*h*c**2
    b = h*c/(wl*k*T)
    intensity = a/((wl**5) * (np.exp(b) - 1.0))
    return intensity


def B_rsr(wl, rsr, T):
    weighted_intensity = rsr*planck(wl, T)
    integd_intensity = integrate.trapz(weighted_intensity, wl)
    return integd_intensity


def main():
    rsrf = pd.read_csv('~/Respfuncs/L8/L8B6.csv')
    wl_nm = np.array(rsrf['Wavelength'])
    rsr = np.array(rsrf['BA RSR [watts]'])
    radiance = B_rsr(wl_nm*1e-9, rsr, 800)
    print(radiance)


if __name__ == '__main__':
    main()
