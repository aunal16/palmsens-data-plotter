% Asks user the PSTrace-generated .mat file and plots them.

% Clear the workspace
clear; clc; close all;

% Adjustable variables
figW = 1200; % figure window width
figH = 800; % figure window height
figFontSize = 14;
lgdFontSize = 6;
lgdColSize = 4;
bipot = true; % if bipot used (two sets of data)
xlimPadder = 0.001;

% Ask and read the file
dialogBoxInitAddress = "C:\Users\Work\OneDrive - University of Cambridge\PhD - Cam\Sirringhaus\lab\PalmSens\20240526";

[finName, finLoc] = uigetfile("*.mat", "Choose the .mat file", dialogBoxInitAddress);

data = importMatFile(strcat(finLoc, finName));

if bipot
    numPlots = size(data, 2) / 2;
else
    numPlots = size(data, 2);
end

%% FIGURE WINDOW
tit = "Transfer Curve at Low Doping Level (V_{DS} = ";
f = figure(Name = strcat("PStrace Data Plot", " - ", finName),...
    NumberTitle = "off",...
    Units = "pixels",...
    Position = [50, 50, figW, figH]);
ax = axes(f);
hold(ax, "on");

%% FIGURE BUTTONS
% Add show/hide all buttons and click on the legend to appear/disappear
% feature
showAllButton = uicontrol(f, Style="pushbutton",...
    String="Show all",...
    Units="Pixels",...
    Position=[0,0,100,25],...
    FontSize=figFontSize);

hideAllButton = uicontrol(f, Style="pushbutton",...
    String="Hide all",...
    Units="Pixels",...
    Position=[0,25,100,25],...
    FontSize=figFontSize);

%% CALLBACKS
showAllButton.Callback = {@(~, ~)set(ax.Children, "Visible", "on")};
hideAllButton.Callback = {@(~, ~)set(ax.Children, "Visible", "off")};

%% PLOT DATA!
plotLabels = cell(1, numPlots);
xMin = Inf;
xMax = -Inf;
for i = 1:numPlots
    scan = data(:, i);
    % typical scan name is c0000_CVBipotcurrentScan1
    scanName = split(scan.Properties.VariableNames, '_');
    scanName = scanName{end};
    x_y = scan.Variables;
    x = x_y(:, 1);
    y = x_y(:, 2);

    if max(x) > xMax, xMax = max(x); end
    if min(x) < xMin, xMin = min(x); end

    plot(ax, x, y, 'o-', DisplayName=scanName);
    plotLabels{i} = get(gca, "Children").DisplayName;
end
xlim(ax, [xMin - xlimPadder, xMax + xlimPadder]);


% Reshape figure according to legend
au = 'on'; % legend autoupdate
reshape_and_legend(ax, au, lgdFontSize, lgdColSize);

%% HELPERS
function reshape_and_legend(ax, au, lgdFontSize, lgdColSize)
    hL = legend(ax, Location="northeastoutside", ...
        NumColumns=lgdColSize, AutoUpdate=au,...
        ItemHitFcn=@LegendCb,...
        FontSize=lgdFontSize);
    set(hL, 'LimitMaxLegendEntries', false, 'NumColumns', lgdColSize); % by def limited to 50
end

function LegendCb(~, event)
    if strcmp(event.Peer.Visible,'on')
        event.Peer.Visible = 'off';
    else 
        event.Peer.Visible = 'on';
    end
end