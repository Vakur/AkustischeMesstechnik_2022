clc
clear

%%-------------------------------------------------------------------------
%Festlegung Parameter fuer Messung:
%Anzahl Mittelung
anz = 4;
%Abtatsfrequenz
fs = 48000;
%Zeitvektor
T = 1/fs;
t = [0:T:1];

%Variablendeklaration
korr = 0;
i = 1;

Tgeschaetzt = 0.8;  
Tstart = Tgeschaetzt/2;

%%-------------------------------------------------------------------------
%Signalerzeugung: Erzeugen weißes Rauschen
N_Win_M = fs*Tgeschaetzt;           
N = N_Win_M*anz;  
N_ges = 4*fs+N; 
x1 = wgn(1, N_ges, 0)*.2; 
x1 = x1';

%%-------------------------------------------------------------------------
%Beginn der Berechnung:
for i = i : anz 
%Initialisierung Wiedergabe    
    player = audioplayer(x1, fs, 24, 3);
%Start Wiedergabe    
    playblocking(player);
%Initialisierung Aufnahme    
    recorder = audiorecorder(fs, 24, 2, 1)
%Start Aufnahme
    recordblocking(recorder, length(x1)/fs);

%Beginn Mittelungsschleife
%Unterteilung fuer anz  gleich 1 und groeßer 1
    if anz == 1
%Daten aus Aufnahmevariable recorder auslesen        
        y = getaudiodata(recorder);
%Zuweisung der Aufnahmekanäle auf Mess- und Referenzsignal        
        x_meas = y(:,1);
        y_ref = y(:,2);

%Berechnung Kreukorrelation
        korr1 = xcorr(x_meas, y_ref);
    else
%Daten aus Aufnahmevariable recorder auslesen              
        y = getaudiodata(recorder);
%Zuweisung der Aufnahmekanäle auf Mess- und Referenzsignal        
        x_meas = y(:,1);
        y_ref = y(:,2);

%Berechnung der Kreuzkorrelation        
        korr1 = xcorr(x_meas, y_ref);
%Addition der berechneten Kreuzkorrelation zur Kreuzkorrelation aus vorhergehendem Schleifendurchlauf        
        korr = korr1 + korr;
    end
%Erhoehung Zaehlvariable um 1    
    i = i + 1;
end

%Berechnung der mittleren Kreuzkorrelation
korr_avg = korr./anz;

x_meas = x_meas';
y_ref = y_ref';
t = ((0:length(x_meas)-1)*T);

impulsa = korr_avg(N:(Tstart*fs)+N-1);

%Drehen der Impulsantwort
impulsa_gedreht = flipud(impulsa);
%Quadrierung der Impulsantwort
impulsa_qua = impulsa_gedreht.^2;
%Integralbildung
Erg_int = cumsum(impulsa_qua);
Erg_int = flipud(Erg_int);
%Berechnung der Early-Decay-Curve
edc = 10*log10(Erg_int);

%%-------------------------------------------------------------------------
%Darstellung:
%Darstellung der Zeitsignale
figure(4)
subplot(3, 1, 1)
plot(t, x1)
subplot(3, 1, 2)
plot(t, x_meas)
subplot(3, 1, 3)
plot(t, y_ref)

%Darstellung Kreuzkorrelationsfunktion
figure(1)
plot(korr_avg);
title('Kreuzkorrelationsfunktion')
xlabel('Samples')
ylabel('Schalldruck (Pa)')

%Darstellung Impulsantwort
figure(2)
plot(impulsa);
title('Impulsantwort skaliert')
xlabel('t (s)')
ylabel('Schalldruck (Pa)')

%Darstellung Early-Decay-Curve
figure(3)
plot(edc);
title('Nachhallzeit nach Schroeder mit weißem Rauschen')
xlabel('t (s)')
ylabel('L_P (dB)')
