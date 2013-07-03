function out = TSTL_predict(y, plen, NNR, stepsize, pmode, embedparams)
% Uses TSTOOL code 'predict', which does local constant iterative
% prediction for scalar data using fast nearest neighbour searching. There
% are four modes available for the prediction output
% INPUTS:
% y: scalar column vector time series
% plen: prediction length in samples or as proportion of time series length
% NNR: number of nearest neighbours
% stepsize: number of samples to step for each prediction
% pmode: prediction mode, several options:--
%           (i) 0 -- output vectors are means of images of nearest neighbours
%          (ii) 1 -- output vectors are distance-weighted means of images
%                     nearest neighbours
%         (iii) 2 -- output vectors are calculated using local flow and the
%                    mean of the images of the neighbours
%          (iv) 3 -- output vectors are calculated using local flow and the
%                    weighted mean of the images of the neighbours
% embedparams: as usual to feed into benembed, except that now you can set
%              to zero to not embed.
% It's a bit rubbish in that the output is not directly correlated to the
% input...?
% adapted by Ben Fulcher November 2009


doplot = 0;

%% Foreplay
N = length(y);

% (*) Prediction length, plen (the length of the output time series)
if nargin < 2 || isempty(plen)
    plen = 1; % output the same length (proportion)
end
% (proportion set after embedding, as the embedding will lose points
% according to the dimension of the space)

% (*) number of neighest neighbours, NNR
if nargin < 3 || isempty(NNR)
    NNR = 1; % use 1 nearest neighbour
end

% (*) stepsize (in samples)
if nargin < 4 || isempty(stepsize)
    stepsize = 2;
end

% (*) prediction mode, pmode:
if nargin < 5 || isempty(pmode)
    pmode = 0; % output vectors are means of the images of nearest neighbours
end

% (*) embedparams
if nargin < 6 || isempty(embedparams)
    embedparams = {'ac','cao'};
    fprintf(1,'Using default embedding using autocorrelation and cao\n')
end


%% Embed the scalar time series by time-delay method
% embedpn = benembed(y,embedparams{1},embedparams{2},2);
% delay = embedpn(1);
% dim = embedpn(2);
if iscell(embedparams)
    s = benembed(y,embedparams{1},embedparams{2},1);
elseif embedparams == 0
    s = signal(y);
end
% convert the time series to a signal class for use with TSTOOL methods

if ~strcmp(class(s),'signal')
    out = NaN; return
end

Ns = length(data(s));
if Ns < 50
    error('too short')
end
y = y(1:Ns); % for statistical purposes...
if plen > 0 && plen <= 1
    plen = floor(plen*Ns); % specify a proportion of the time series length
end

%% Run the code
% have to call TSTOOLpredict because predict is now a built-in Matlab function
rs = TSTOOLpredict(s, plen, NNR, stepsize, pmode);

y_pred = data(rs); % convert signal back to vector data
y_pred1 = y_pred(:,1); % for this embedding dimension (?)

if doplot % plot the output
    figure('color','w')
    hold off; plot(y,'k'), hold on; plot(y_pred1,'m'), hold off;
    view(rs);
end

%% Compare the output to the properties of the true time series

% actual basic statistical properties
out.pred1mean = mean(y_pred1);
out.pred1std = std(y_pred1);
out.pred1maxc = abs(max(y_pred1)-max(y));
out.pred1maxc = abs(max(y_pred(:))-max(y));
out.pred1minc = abs(min(y_pred1)-min(y));
out.predminc = abs(min(y_pred(:))-min(y));
out.pred1rangec = abs(range(y_pred1)/range(y)-1);

% look at structure in cross correlation function, xcf
% (requires that prediction length the same as the time series itself)
[xcf lags]=xcorr(y,y_pred1,'coeff');
% plot(lags,xcf);

out.maxabsxcf = max(abs(xcf)); % maximum of cross-correlation function; where it occurs
out.maxabsxcflag = lags(find(abs(xcf)==out.maxabsxcf,1,'first'));
out.maxxcf = max(xcf); % maximum positive cross-correlation
out.maxxcflag = lags(find(xcf==out.maxxcf,1,'first'));
out.meanxcf = mean(xcf);
out.minxcf = min(xcf);
out.stdxcf = std(xcf);


out.pred1_ac1 = CO_autocorr(y_pred1,1); % autocorrelation at lag one of prediction
out.pred1ac1diff = abs(out.pred1_ac1 - CO_autocorr(y,1)); % difference in autocorrelations of prediction and original
out.pred1_ac2 = CO_autocorr(y_pred1,2); % autocorrelation at lag one of prediction
out.pred1ac2diff = abs(out.pred1_ac2 - CO_autocorr(y,2)); % difference in autocorrelations of prediction and original
out.pred_tau_comp = CO_fzcac(y_pred1)/CO_fzcac(y); % difference in first zero crossing of autocorrelation function

% autocorrelation structure
acs_y = CO_autocorr(y,1:10);
acs_y_pred1 = CO_autocorr(y_pred1,1:10);
out.acs1_10_sumabsdiffpred1 = sum(abs(acs_y - acs_y_pred1));

% mean square residuals: this will likely be a bad measure (as may be out
% of sync)
out.pred1rmsres = sqrt(mean((y-y_pred1).^2));

% align at best positive cross-correlation and then look at residuals
if out.maxxcflag>0
    y_lagged = y(out.maxxcflag:end);
    Nlag = length(y_lagged);
    y_pred1_lagged = y_pred1(1:Nlag);
elseif out.maxxcflag==0
    y_lagged = y;
    y_pred1_lagged = y;
    Nlag = length(y);
else % negative
    y_pred1_lagged = y_pred1(-out.maxxcflag:end);
    Nlag = length(y_pred1_lagged);
    y_lagged = y(1:Nlag);
end

% hold off; plot(y_pred1_lagged);
% hold on; plot(y_lagged,'r');
out.Nlagxcorr = Nlag;
res = y_lagged - y_pred1_lagged;
out.bestpred1rmsres = sqrt(mean(res.^2)); % rms residuals
out.ac1bestres = CO_autocorr(res,1); % autocorrelation of residuals

% now look at fraction of points that are within a threshold of each
% other...
out.fracres005 = sum(abs(res)<0.05)/Nlag;
out.fracres01 = sum(abs(res)<0.1)/Nlag;
out.fracres02 = sum(abs(res)<0.2)/Nlag;
out.fracres03 = sum(abs(res)<0.3)/Nlag;
out.fracres05 = sum(abs(res)<0.5)/Nlag;

% now look at fraction of points within a circle of (time-measurement) radius
% near a real point in the time series
% this could be done using the closest neighbour of the simulation to the
% real time series


% Could compare different dimensions rather than just the first... find the
% best... etc.

% There are heaps of metrics you could use to compare... Ultimately may be
% able to implement model outputs as rows so as to compare across many
% measures...


end