% Asks user the PSTrace-generated .mat file and plots them.

% Clear the workspace
clear; clc; close all;

% Ask and read the file
dialogBoxInitAddress = "C:\Users\Work\OneDrive - University of Cambridge\PhD - Cam\Sirringhaus\lab\PalmSens\20240526";

[finName, finLoc] = uigetfile("*.mat", "Choose the .mat file", dialogBoxInitAddress);

data = importMatFile(strcat(finLoc, finName));