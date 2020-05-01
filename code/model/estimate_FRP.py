import matplotlib.pyplot as plt
import argparse
import os
import math
import numpy as np
import pandas as pd
from scipy import integrate
from scipy import optimize


h = 6.626e-34
c = 3.0e+8
k = 1.38e-23

sbc = 5.67e-8

DENV_RSRF = os.environ['DENV_RSRF']

parser = argparse.ArgumentParser(description='')
parser.add_argument('-c', '--correction_Pf', type=float,
                    help='correction parameter value for the Pf', required=True)
parser.add_argument('-i', '--inp_data', nargs="+", type=float,
                    help='list of the known parameters of the fire pixel', required=True)
args = parser.parse_args()

rsrf_file_path = "{}/{}"
rsrf_sw03 = pd.read_csv(rsrf_file_path.format(
    DENV_RSRF, "SGLI/RSR_SW03.txt"), sep=" ")
rsrf_sw04 = pd.read_csv(rsrf_file_path.format(
    DENV_RSRF, "SGLI/RSR_SW04.txt"), sep=" ")

# the known parameters of the fire pixel
fp = pd.Series(args.inp_data, index=[
    'lon', 'lat', 'L_sw04', 'Lb_sw04', 'L_sw03', 'Lb_sw03', 'SGLI_obstime', 'Pf'])
# the correction parameter for the Pf
correction_Pf = args.correction_Pf
# SGLI SW03 and SW04 RSRFs(Relative Spectral Response Functions)
wl_sw03 = np.array(rsrf_sw03['WL(nm)'])*1e-9
rsr_sw03 = np.array(rsrf_sw03['RSR_SW03'])
wl_sw04 = np.array(rsrf_sw04['WL(nm)'])*1e-9
rsr_sw04 = np.array(rsrf_sw04['RSR_SW04'])


def main():
    res = optimize.minimize_scalar(SumSqErr, bracket=(200, 2000))
    pixarea = 1e+3 ** 2  # [m^2]
    FRP = calc_FRP(res.x, correction_Pf, fp.Pf, pixarea)  # [MWatts]
    isval_sw04 = (fp.L_sw04 > fp.Lb_sw04)*1
    isval_sw03 = (fp.L_sw03 > fp.Lb_sw03)*1
    print(fp.lon, fp.lat, fp.L_sw04, fp.Lb_sw04, fp.L_sw03, fp.Lb_sw03,
          fp.SGLI_obstime, fp.Pf, correction_Pf, isval_sw04, isval_sw03, res.x, res.fun, res.success, FRP)


# def out_SSE_profile(fp, Tf_min, Tf_max, Tf_spacing, out_file):
#     out_df = pd.DataFrame(columns=['Tf', 'SSE'])
#     for Tf in np.arange(Tf_min, Tf_max, Tf_spacing):
#         out_se = pd.Series([Tf, SumSqErr(Tf, fp)],
#                            index=out_df.columns)
#         out_df = out_df.append(out_se, ignore_index=True)
#     out_df.to_csv(out_file, sep=" ", header=None, index=None)

def calc_FRP(Tf, cp, Pf, pixarea):
    return sbc*math.pow(Tf, 4)*cp*Pf*pixarea*1e-6


def SumSqErr(Tf):
    sse = (fp.L_sw03 - fp.Lb_sw03 - correction_Pf*fp.Pf*(B_rsr(wl_sw03, rsr_sw03, Tf) - fp.Lb_sw03))**2 + \
        (fp.L_sw04 - fp.Lb_sw04 - correction_Pf*fp.Pf *
         (B_rsr(wl_sw04, rsr_sw04, Tf) - fp.Lb_sw04))**2
    return sse


def planck(wl, T):
    a = 2.0*h*c**2
    b = h*c/(wl*k*T)
    intensity = a/((wl**5) * (np.exp(b) - 1.0))
    return intensity


def B_rsr(wl, rsr, T):
    weighted_intensity = rsr*planck(wl, T)
    integd_intensity = integrate.trapz(weighted_intensity, wl)
    return integd_intensity


if __name__ == '__main__':
    main()
