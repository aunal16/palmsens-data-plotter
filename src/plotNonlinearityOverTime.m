% Asks user the PSTrace-generated .mat file and plots them.

% Clear the workspace
clear; clc; close all;

% Adjustable variables
figW = 1200; % figure window width
figH = 600; % figure window height
figFontSize = 16;
lgdFontSize = 16;
lgdColSize = 1;
bipot = true; % if bipot used (two sets of data)
xTit = "Measurement Number";
yTit = "med❨ y - y_{fit line} ❩";
yTit2= "Current Difference";
VFixed = 0;
isVFixedLim = true; % indicate if VFixed is a limit value
sweepDir = "double"; % double or single
tdaeAdditionMeas = 99;

% Ask and read the file
dialogBoxInitAddress = "C:\Users\Work\OneDrive - University of Cambridge\PhD - Cam\Sirringhaus\lab\PalmSens\20240702";

[finName, finLoc] = uigetfile("*.mat", "Choose the .mat file", dialogBoxInitAddress);

data = importMatFile(strcat(finLoc, finName));

if bipot
    numPlots = size(data, 2) / 2;
else
    numPlots = size(data, 2);
end

%% FIGURE WINDOW
tit = "V_{DS} change over consecutive measurements at V_{GS} = " + VFixed + " V";
f = figure(Name = strcat("PStrace Data Plot", " - ", finName),...
    NumberTitle = "off",...
    Units = "pixels",...
    Position = [50, 50, figW, figH]);
ax = axes(f);

xlabel(ax, xTit);
ylabel(ax, yTit);

set(ax,FontSize=figFontSize);
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

lineFullFitCheckbox = uicontrol(f, Style='checkbox', ...
    String='Differential', ...
    Units='pixels', ...
    Position=[100,0,110,20],...
    FontSize=figFontSize, ...
    Value=0);

%% COLLECT DATA!
xArrays = cell(1, numPlots);
yArrays = cell(1, numPlots);

xMin = Inf;
xMax = -Inf;

xPlt = 1:numPlots;
yPlt = zeros(1, numPlots);

for i = 1:numPlots
    scan = data(:, i);
    % typical scan name is c0000_CVBipotcurrentScan1
    scanName = split(scan.Properties.VariableNames, '_');
    scanName = scanName{end};
    x_y = scan.Variables;
    x = x_y(:, 1);
    y = x_y(:, 2);

    % Save individual x, y pairs for later line fitting into cell arrays
    xArrays{i} = x;
    yArrays{i} = y;

    % obtain the real max and min of each plot and compare to global values
    if max(x) > xMax, xMax = max(x); end
    if min(x) < xMin, xMin = min(x); end

    % Non-linear part
    yFit = fitLine(x, y);
    yNonlinear = y - yFit;
    yPlt(i) = median(yNonlinear);
end

%% plot
% yyaxis left
plot(ax, xPlt, yPlt, 'o-', DisplayName="G0", Tag="dataline");
xlim(ax, [1, numPlots]);

xline(tdaeAdditionMeas, "k--", "TDAE", fontsize=lgdFontSize, displayName="TDAE addition", Tag="xlineTDAE");

% % yyaxis right
% % h = 1;           % step size
% % xd1 = mean([xPlt(1:end-1); xPlt(2:end)]);
% % % xd1 = mean([xd1(1:end-1); xd1(2:end)]);
% % yd1 = diff(yPlt) / h;
% % % yd2 = gradient(yPlt, h);
% % plot(xd1,yd1,'r', DisplayName="Current Difference", Tag="derivative");
% % % plot(xPlt(:,1:length(yd2)),yd2,'r');
% % ylabel(ax, yTit2);


% Reshape figure according to legend
au = 'on'; % legend autoupdate
reshape_and_legend(ax, au, lgdFontSize, lgdColSize);

%% CALLBACKS
showAllButton.Callback = {@(~, ~)set(ax.Children, "Visible", "on")};

hideAllButton.Callback = {@(~, ~)set(ax.Children, "Visible", "off")};

lineFullFitCheckbox.Callback = {@LineFullButtonCb, ax, xArrays, yArrays};

%% HELPERS
function reshape_and_legend(ax, au, lgdFontSize, lgdColSize)
    hL = legend(ax, Location="southwest", ...
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

function LineFullButtonCb(src, ~, ax, xArrays, yArrays)
% To plot the line connecting end points

    if src.Value
    % Fit line to the visible dataline objects       
        curAx = gca;
        idxs = [];
        for i=1:length(curAx.Children)
            if (curAx.Children(i).Tag == "dataline") && curAx.Children(i).Visible == "on"
                idxs(end+1) = i;
            end
        end
        
        xs = {};
        y_fits = {};
        ms = {};
        for i=1:length(idxs)
            x = curAx.Children(idxs(i)).XData;
            y = curAx.Children(idxs(i)).YData;

            [y_fit, m] = fitLine(x,y);

            xs{end+1} = x;
            y_fits{end+1} = y_fit;
            ms{end+1} = m;
        end
        for i=1:length(idxs)
            plot(ax, xs{i}, y_fits{i}, Color='k', ...
                Displayname=sprintf("slope=%.2e", ms{i}),...
                Tag="fitline");
        end

    else
    % Delete fitted line
        curAx = gca;
        idxs = [];
        for i=1:length(curAx.Children)
            if curAx.Children(i).Tag == "fitline"
                idxs(end+1) = i;
            end
        end
        delete(curAx.Children(idxs));
    end
end

function [y_fit, slope] = fitLine(x,y)
% fits a line between the end points
    M = []; % list to hold maximum x values' indices
    m = []; % list to hold minimum x values' indices
    
    x_max = max(x);
    x_min = min(x);
    
    j = 1;
    for k=1:length(x)
        i = x(k);
        if i==x_max
            M(end+1) = j;
        elseif i==x_min
            m(end+1) = j;
        end
        j = j+1;
    end
    
    y_max_avg = 0;
    for k=1:length(M)
        i = M(k);
        y_max_avg = y_max_avg + y(i);
    end
    y_max_avg = y_max_avg/length(M);
    
    y_min_avg = 0;
    for k=1:length(m)
        i = m(k);
        y_min_avg = y_min_avg + y(i);
    end
    y_min_avg = y_min_avg/length(m);
    
    x_delta = x_max - x_min;
    y_delta = y_max_avg - y_min_avg;
    slope = y_delta / x_delta;

    c = y_max_avg - slope * x_max;

    y_fit = slope * x + c;
end