import numpy as np
import pandas as pd
from scipy import integrate
import matplotlib
matplotlib.use('PS')
import matplotlib.pyplot as plt

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


wls_m = np.arange(1e-6, 10e-6, 1e-6)
intensity6000 = planck(wls_m, 6000)
intensity1200 = planck(wls_m, 1200)
intensity800 = planck(wls_m, 800)
intensity600 = planck(wls_m, 600)
intensity300 = planck(wls_m, 300)

plt.plot(wls_m*1e-6, intensity1200, 'y-')
plt.plot(wls_m*1e-6, intensity800, 'r-')
plt.plot(wls_m*1e-6, intensity600, 'g-')
plt.plot(wls_m*1e-6, intensity300, 'b-')
plt.savefig('baka.ps')
plt.show()

# def main():
#     rsrf = pd.read_csv('~/Respfuncs/L8/L8B6.csv')
#     wl_nm = np.array(rsrf['Wavelength'])
#     rsr = np.array(rsrf['BA RSR [watts]'])
#     radiance = B_rsr(wl_nm*1e-9, rsr, 800)
#     print(radiance)

#     wls_m = np.arrange(1e-9, 10e-6, 1e-9)
#     intensity6000 = planck(wls_m, 6000)
#     intensity1200 = planck(wls_m, 1200)
#     intensity800 = planck(wls_m, 800)
#     intensity600 = planck(wls_m, 600)
#     intensity300 = planck(wls_m, 300)

#     plt.plot(wls_m*1e-6, intensity1200, 'y-')
#     plt.plot(wls_m*1e-6, intensity800, 'r-')
#     plt.plot(wls_m*1e-6, intensity600, 'g-')
#     plt.plot(wls_m*1e-6, intensity300, 'b-')
#     plt.savefig('baka.jpg')
#     plt.show()


# if __name__ == '__main__':
#     main()
