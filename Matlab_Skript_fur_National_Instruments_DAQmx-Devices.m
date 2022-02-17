clc;
clear all;
close all;

fs = 44100;                  %Abtastrate
Tw = 4;                       %Fensterlaenge 
Navg = 2;                    %Anzahl der Mittelungen
S = 20;                       %Skalierungsfaktor
% fm_okt = 125*S;               %Mittefrequenz der zu untersuchenden Oktave
fm_okt_u = 125*S;
fm_okt_o = 4000*S;
N = (Tw)*fs;                    %Anzahl der Abtastwerte

Tgeschaetzt = 2;              %Nachhallzeit im Originalbereich 
Tstart = Tgeschaetzt/(S*2);   %Startverzoegerung fuer Einschwingvorgang
k = 1.3;                      %Sicherheitsfaktor

DeltaTs = 1/fs;

time_sweep = 0 : 1/fs : Tw; 
DeltaTs = 1/fs;


% fo_Sweep = fm_okt*sqrt(2.5)    %obere Frequenz des Sweeps mal einem Sicherheitsfaktor nach DIN EN ISO 3382
% fu_Sweep = fm_okt/sqrt(20)     %untere Frequenz des Sweeps durch einem Sicherheitsfaktor wegen Latenzzeit, nach DIN EN ISO 3382
fo_Sweep = 90000;
fu_Sweep = fm_okt_u/sqrt(20)

fu1 = 300;                     
% fu =  fm_okt/sqrt(4);
% fo =  fm_okt*sqrt(2.5);
fu =  fm_okt_u/sqrt(4);
fo =  85000;

lower = fu / (fs/2);
lower1 = fu1 / (fs/2);
upper = fo / (fs/0.2);

bandpass = fir1 ( 800, [lower upper]);
highpass = fir1 ( 1000, lower1, 'high');
% 
devices = daqvendorlist;
s = daq("ni"); 
t = daq("ni");
t.Rate = fs;              %sample rate der Aufnahme
s.Rate = fs;              %sample rate der Wiedergabe  
addoutput(s,"Dev2","ao0","Voltage")
        %Analoger Ausgang an der Session 's' von der PXI Karte 'Dev2' 
        %Ausgang '0' und 'Voltage' als Ausgabe eingestellt   
addinput(t,"Dev1","ai0","Voltage")
addinput(t,"Dev1","ai1","Voltage")

j = 1;

for j = j:Navg;                     %Beginn Mittelungsschleife

outputSingleValue = 2;              %Amplitude des Ausgangssignals
        %leider bei Aenderung keine Auswirkung beim Signal erkennbar
%  outputSignal =  wgn((N*k)+(fs*Tstart),1,2); 
   outputSignal = 3*chirp(time_sweep , fu_Sweep , Tw , fo_Sweep); 
%outputSignal = chirp(time_sweep , fu_Sweep , Tw*k , fo_Sweep,'logarithmic',90); 
     outputSignal = outputSignal';
      %Matrix mit stochastischen Werten generiert,(white gaussian noise)
write(s,outputSignal);    %Werte fuer Wiedergabe bereitgestellt
t.Channels;

start(s);
%preload(t,outputSignal) = Tw;    %Dauer der einzelnen Aufnahmen
D = ['Start recording: ',num2str(j),' of ',num2str(Navg),];
disp(D);
[captured_data] = read(t,seconds(Tw)); 
D1 =['End of ',num2str(j),' of ',num2str(Navg),];
disp(D1);
        %Aufnahme von beiden Kanaelen wird gestartet

aufnahme = captured_data(1:Tw*fs,1);
aufnahme=captured_data.Dev1_ai0(1:Tw*fs);
        %aus erster Spalte relevante Werte ausgeschnitten (Mikrofon)
 aufnahme = filter(bandpass,1,aufnahme);  
 aufnahme = filter(highpass,1,aufnahme); 
rauschen = captured_data(1:Tw*fs,2);
rauschen = captured_data.Dev1_ai1(1:Tw*fs); 
%aus zweiter Spalte relevante Werte ausgeschnitten (output) 
  rauschen = filter(bandpass,1,rauschen);  
  rauschen = filter(highpass,1,rauschen); 

 time= captured_data.Time(1:Tw*fs);
 if j>1
     
     korrelation1 = xcorr(aufnahme,rauschen);
     korrelation2 = korrelation1 + korrelation;
     korrelation = korrelation2./2;
     aufnahme1 = (aufnahme1 + aufnahme)./2;
     rauschen1 = (rauschen1 + rauschen)./2;
 else 
     korrelation = xcorr(aufnahme,rauschen);
      aufnahme1 = aufnahme;
      rauschen1 = rauschen;
 end
 %wait(s)
j = j+1;
end


aufnahme1 = aufnahme1';

% timeFFT = time(1:length(aufnahme1));
% figure(11), plot(timeFFT,aufnahme1);
% xlabel ('Time [s]');
% ylabel ('Schalldruck in Pa ')
% title ('Schalldruckverlauf Aufnahme Sin-Sweep');
% 
% figure(12), plot (timeFFT,rauschen1);
% set(gca,'Fontsize',14);
% xlabel ('Time [s]');
% ylabel ('Schalldruck in Pa ');
% title ('Schalldruckverlauf des generierten Sin Sweep ');


korrelation = korrelation./N;
figure (1), plot (korrelation);  
title ('Kreuzkorrelation mit Sin Sweep 400Hz-80kHz');
set(gca,'Fontsize',14);
xlabel ('Samples');
ylabel ('Schalldruck in Pa ');
% RMSRauschen = rauschen1(fs : 2*fs);
% RMS_Signal = rms(RMSRauschen)
% 
% Nb = length(aufnahme1);
% FFTauf = fft(aufnahme1);
% FFTauf = abs(FFTauf)/Nb;
% FFTauf = [FFTauf(1) 2*FFTauf(2:((Nb)/2))];
% freqSkaliert = (0:floor((Nb-2)/2))/(Nb*DeltaTs);
% figure (2), subplot(121);
% bar(freqSkaliert,10*log10(FFTauf.^2 / (2*10^-8).^2));
% title ('FFT Aufnahme');
% ylim([0 110]);
% xlim([0 90000]);
% 
% rauschen1 = rauschen1';
% Nb = length(rauschen1);
% FFTrau = fft(rauschen1);
% FFTrau = abs(FFTrau)/Nb;
% FFTrau = [FFTrau(1) 2*FFTrau(2:((Nb)/2))];
% freqSkaliert = (0:floor((Nb-2)/2))/(Nb*DeltaTs);
% subplot(122);
% bar(freqSkaliert,10*log10(FFTrau.^2 / (2*10^-5).^2));
% title ('FFT Sin Sweep');
% ylim([0 110]);
% xlim([0 90000]);
% 
% % 
Impulsantwort = korrelation(N:(Tstart*fs*4)+N-1);
       
time1 = time(1:(4*fs*Tstart));

% figure (3), plot (time1,Impulsantwort);
% title ('Impulsantwort');
% xlabel ('Zeit in s');
% ylabel ('Schalldruck in Pa ');
 
figure(4), plot (time1.*S,Impulsantwort);
set(gca,'Fontsize',14);
title ('Impulsantwort skaliert');
xlabel ('Zeit in s');
ylabel ('Schalldruck in Pa ');
% 
% kohaerenz = mscohere(aufnahme1, rauschen1);
% figure(5), plot(kohaerenz);
% xlim([0 fs/2]);
% 
% 
% verz = 530;
% C50_ausschnitt = Impulsantwort(verz:verz+(0.05/S)*fs);
% C50 = C50_ausschnitt.^2;
% C50 = sum (C50);
% C50_Rest = Impulsantwort(verz+(0.05/S)*fs:(Tgeschaetzt/S)*fs);
% C50_Rest = C50_Rest.^2;
% C50_Rest = sum (C50_Rest);
% 
% C50 = 10*log10(C50/C50_Rest)
% 
% C80_ausschnitt = Impulsantwort(verz:verz+(0.08/S)*fs);
% C80 = C80_ausschnitt.^2;
% C80 = sum (C80);
% C80_Rest = Impulsantwort(verz+(0.08/S)*fs:(Tgeschaetzt/S)*fs);
% C80_Rest = C80_Rest.^2;
% C80_Rest = sum (C80_Rest);
% 
% C80 = 10*log10(C80/C80_Rest)
% 
Impulsantwort_gedreht=flipud(Impulsantwort);
Impulsantwort_qua=Impulsantwort_gedreht.^2;
Erg_int = cumsum(Impulsantwort_qua);
Erg_int = flipud(Erg_int);
figure (5), plot(time1*S,10*log10(Erg_int));
title('Nachhallzeit nach Schroeder mit Sin Sweep 400Hz-80kHz')
xlabel('Zeit [s]');
ylabel ('Schalldruck [dB]');
% 












% Impulsantwort_C50 = korrelation1 (N+20 : (fs*4*Tstart) + N+19);
% findpeaks ( Impulsantwort_C50, 'threshold' ,2*10^-6);
% [pks,locs] = findpeaks(Impulsantwort_C50,'SortStr','descend','NPeaks',1)
% 
% %Berechnung C50 und C80 im Originalbereich
% C50_ausschnitt = Impulsantwort_C50((locs-5):(locs-5)+(0.05/S)*fs);
% C50 = C50_ausschnitt.^2;
% C50 = sum (C50);
% C50_Rest = Impulsantwort_C50((locs-5)+(0.05/S)*fs:(Tgeschaetzt/S)*fs);
% C50_Rest = C50_Rest.^2;
% C50_Rest = sum (C50_Rest);
% 
% C50 = 10*log10(C50/C50_Rest)
% 
% C80_ausschnitt = Impulsantwort_C50((locs-5):(locs-5)+(0.08/S)*fs);
% C80 = C80_ausschnitt.^2;
% C80 = sum (C80);
% C80_Rest = Impulsantwort_C50((locs-5)+(0.08/S)*fs:(Tgeschaetzt/S)*fs);
% C80_Rest = C80_Rest.^2;
% C80_Rest = sum (C80_Rest);
% 
% C80 = 10*log10(C80/C80_Rest)

% Nachhallzeit nach Schroeder-Rueckwaertsintegration