import sounddevice as sd
import numpy as np
import scipy.signal as sp
import math as math
import matplotlib.pyplot as plt

# ---------------------------------------------Properties---------------------------------------------------------------
fs = 204000                                                 # Sample rate
fs2 = 44100                                                 # testrate
Tw = 4                                                      # Fensterlänge
N = fs * Tw                                                 # Samples

S = 20                                                      # Skalierungsfaktor
T_geschaetzt = 0.8                                          # Nachhallzeit im Orig. Maßstab
T_start = T_geschaetzt / (S * 2)                            # Einschwingungsvorgang
k = 1.2                                                     # Sicherheitsfaktor
Navg = 2                                                    # Anzahl Mittlungen
t = 0.5                                                     # Zeit des Rauschens

Nullvektor = np.random.normal(0.0, 0.0001, int(N * t))      # erzeugt Weißes Rauschen

abstand = 0.80                                              # Abstand Schallquelle in m
temperatur = 22                                             # Raumtemperatur in Grad Celsius
vschall = 20.08 * math.sqrt(temperatur + 273)               # Schallgeschwindigkeit
verzoegerung = (abstand / vschall) * fs                     # Verzögerung Direktschall

s = 20                                                      # Skalierungsfaktor
fm_okt_o = 4000 * s
fm_okt_u = 125 * s
fo_Sweep = 90000
fu_sweep = fm_okt_u/math.sqrt(20)
time_sweep = np.arange(0, Tw, 1/fs2)

fu1 = 300
fu = fm_okt_u / math.sqrt(4)
fo = 85000
lower = fu / (fs / 2)
lower1 = fu1 / (fs / 2)
upper = fo / (fs / 2)

# ---------------------------------------------Filter-------------------------------------------------------------------

# bandpass = sp.firwin(800, [lower, upper], pass_zero=False)
# highpass = sp.firwin(1001, lower1, pass_zero=False)

# ---------------------------------------------Setup Interface----------------------------------------------------------

list_devices = sd.query_devices(device=None, kind=None)
sd.default.device = 'Focusrite USB ASIO'                         # Soundkarte Auswählen
sd.default.samplerate = fs                                  # Samplerate
Input = 1                                                   # Input an den das Mic angeschlossen ist

Count = 0

for Count in np.arange(Count, Navg):

    #Output_Signal = np.transpose(np.random.normal(0.0, 2.0, int(N * t)))               # erzeugt Weißes Rauschen
    Output_Signal = sp.chirp(time_sweep, 20, Tw, 20000, method='linear')      # erzeugt einen Sinussweep

    Noise_rec = np.append(Output_Signal, Nullvektor)

    recording = sd.playrec(Noise_rec, fs2, channels=2)                      # Start Wiedergabe + recording
    sd.wait()                                                               # Wartet bis Wiedergabe beendet
    recording = recording[:, Input-1]                                       # Nimmt die erste Spalte der Werte (Input 1)
    recording = recording[int(verzoegerung):int(N+verzoegerung)]            # Schneidet Einschwingvorgang heraus
    #recording = sp.lfilter(bandpass, 1, recording)
    #recording = sp.lfilter(highpass, 1, recording)

    Noise_rec = Noise_rec[int(verzoegerung):int(N+verzoegerung)]
    #Noise_rec = sp.lfilter(bandpass, 1, Output_Signal)
    #Noise_rec = sp.lfilter(highpass, 1, Output_Signal)
    plt.figure(1)
    plt.plot(recording)
    plt.show()

    # --------------------------------------------Kreuzkorrelation------------------------------------------------------

    if Count > 0:
        korrelation1 = sp.correlate(recording, Noise_rec)
        korrelation1 = np.add(korrelation1, korrelation)
        korrelation2 = np.divide(korrelation1, 2)
    else:
        korrelation = sp.correlate(recording, Noise_rec)

    Count = Count + 1

korrelation_final = np.divide(korrelation2, Navg)

#plt.figure(2)
#plt.plot(korrelation_final)
#plt.title('Kreuzkorrelation mit Sin Sweep 400Hz-80kHz')
#plt.xlabel('Samples')
#plt.ylabel('Schalldruck in Pa')
#plt.show()

#Impulsantwort = korrelation[int(verzoegerung*N):int(N*t)]

#plt.figure(3)
#plt.plot(Impulsantwort)
#plt.title('Kreuzkorrelation mit Sin Sweep 400Hz-80kHz')
#plt.xlabel('Samples')
#plt.ylabel('Schalldruck in Pa')
#plt.show()

time = np.linspace(0,Tw,len(recording))
Impulsantwort = korrelation_final[int(len(korrelation_final)/2):int((len(korrelation_final))/(T_geschaetzt/(0.56*T_geschaetzt)))]
time2 = time[0:len(Impulsantwort)]
Impulsantwort = Impulsantwort/900



plt.rcParams['date.converter'] = 'concise'


plt.figure(2, figsize=(20,15))
plt.rc('axes', titlesize=35) #fontsize of the title
plt.rc('axes', labelsize=30) #fontsize of the x and y labels
plt.rc('xtick', labelsize=30) #fontsize of the x tick labels
plt.rc('ytick', labelsize=30) #fontsize of the y tick labels
plt.grid(True)
plt.ylabel('Schalldruck in Pa')
plt.xlabel('Samples')
plt.plot(korrelation_final/14)
plt.show()


plt.figure(3,figsize=(30,22))
plt.grid()
plt.ylabel('Schalldruck in Pa')
plt.xlabel('t in s')
plt.title('Impulsantwort')
plt.plot(time2, Impulsantwort)
plt.show()


Druckmax = np.max(Impulsantwort)
print(Druckmax)
print("------------- \n")

import math
Pegel = 20*(math.log((Druckmax/(2*10**-5)), 10))
print(Pegel)
