% NL_TSTL_GPCorrSum
% 
% Uses TSTOOL code corrsum (or corrsum2) to compute scaling of the correlation sum for a
% time-delay reconstructed time series by the Grassberger-Proccacia algorithm
% using fast nearest neighbor search.
% 
% cf. "Characterization of Strange Attractors", P. Grassberger and I. Procaccia,
% Phys. Rev. Lett. 50(5) 346 (1983)
% 
% TSTOOL: http://www.physik3.gwdg.de/tstool/
% 
% INPUTS:
% y, column vector of time-series data
% 
% Nref, number of (randomly-chosen) reference points (-1: use all points,
%       if a decimal, then use this fraction of the time series length)
%       
% r, maximum search radius relative to attractor size, 0 < r < 1
% 
% thwin, number of samples to exclude before and after each reference index
%        (~ Theiler window)
% 
% nbins, number of partitioned bins
% 
% embedparams, embedding parameters to feed BF_embed.m for embedding the
%               signal in the form {tau,m}
% 
% dotwo, if this is set to 1, will use corrsum, if set to 2, will use corrsum2.
%           For corrsum2, n specifies the number of pairs per bin. Default is 1,
%           to use corrsum.
% 
% 
% Outputs of this function are basic statistics on the outputs of corrsum,
% including iteratively re-weighted least squares linear fits to log-log plots
% using the robustfit function in Matlab's Statistics Toolbox.
% 
% ------------------------------------------------------------------------------
% Copyright (C) 2013,  Ben D. Fulcher <ben.d.fulcher@gmail.com>,
% <http://www.benfulcher.com>
%
% If you use this code for your research, please cite:
% B. D. Fulcher, M. A. Little, N. S. Jones., "Highly comparative time-series
% analysis: the empirical structure of time series and their methods",
% J. Roy. Soc. Interface 10(83) 20130048 (2010). DOI: 10.1098/rsif.2013.0048
%
% This function is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation, either version 3 of the License, or (at your option) any later
% version.
% 
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
% details.
% 
% You should have received a copy of the GNU General Public License along with
% this program.  If not, see <http://www.gnu.org/licenses/>.
% ------------------------------------------------------------------------------

function out = NL_TSTL_GPCorrSum(y,Nref,r,thwin,nbins,embedparams,dotwo)
% Ben Fulcher, November 2009

%% Preliminaries
doplot = 0; % whether to plot outputs to figure
N = length(y); % length of time series

% (1) Number of reference points, Nref
if nargin < 2 || isempty(Nref)
    Nref = 500; % 500 points
end
if (Nref > 0) && (Nref < 1)
    Nref = round(N*Nref); % specify a proportion of time series length
end
if Nref >= N
    Nref = -1; % Number of reference points capped at time series length
end

% (2) Maximum relative search radius, r
if nargin < 3 || isempty(r)
    r = 0.05; % 5% of attractor radius
end

% (3) Remove spurious correlations of adjacent points, thwin
if nargin < 4 || isempty(thwin)
    thwin = 10; % default window length
end

% (4) Number of bins, nbins
if nargin < 5 || isempty(nbins)
    nbins = 20; % defulat number of bins
end

% (5) Set embedding parameters to defaults
if nargin < 6 || isempty(embedparams)
    embedparams = {'ac','cao'};
else
    if length(embedparams) ~= 2
        error('Embedding parameters are formatted incorrectly -- need {tau,m}')
    end
end

if nargin < 7 || isempty(dotwo)
    dotwo = 1; % use corrsum rather than corrsum2
end

if (Nref == -1) && (dotwo == 2)
    % we need a *number* of pairs for corrsum2, round down from 50% of time series
    % length
    Nref = floor(N*0.5);
end

%% Embed the signal
% convert to embedded signal object for TSTOOL
s = BF_embed(y,embedparams{1},embedparams{2},1);

if ~strcmp(class(s),'signal') && isnan(s); % embedding failed
    error('Embedding failed')
elseif length(data(s)) < thwin
    fprintf(1,'Embedded time series (N = %u, m = %u, tau = %u) too short to do a correlation sum\n',N,embedparams{1},embedparams{2})
    out = NaN; return
end

%% Run
me = []; % error catch
if dotwo == 1 % use corrsum
    try
        rs = corrsum(s,Nref,r,thwin,nbins);
    catch me % DEAL WITH ERROR MESSAGE BELOW
    end
elseif dotwo == 2 % use corrsum2
    try
        rs = corrsum2(s,Nref,r,thwin,nbins);
    catch me
    end
end

if ~isempty(me) && strcmp(me.message,'Maximal search radius must be greater than starting radius')
    fprintf(1,'Max search radius less than starting radius. Returning NaNs.\n')
    out = NaN; return
elseif ~isempty(me) && strcmp(me.message,'Cannot find an interpoint distance greater zero, maybe ill-conditioned data set given')
    fprintf(1,'Cannot find an interpoint distance greater than zero. Returning NaNs.\n')
    out = NaN; return
elseif ~isempty(me) && strcmp(me.message,'Reference indices out of range')
    fprintf(1,'Reference indicies out of range. Returning NaNs.\n')
    out = NaN; return
else
    error('Unknown error %s', me.message);
end

lnr = spacing(rs);
lnCr = data(rs);

if doplot
    figure('color','w'); box('on');
    plot(lnr,lnCr,'.-k');
end

% Contains ln(r) in rows and values are ln(C(r));
% keyboard

%% remove any Infs in lnCr
rgood = (isfinite(lnCr));
if ~any(rgood)
    fprintf(1,'No good outputs obtained from corrsum\n');
    out = NaN; return
end
lnCr = lnCr(rgood);
lnr = lnr(rgood);

%% Output Statistics
% basic
out.minlnr = min(lnr);
out.maxlnr = max(lnr);
out.minlnCr = min(lnCr);
out.maxlnCr = max(lnCr);
out.rangelnCr = range(lnCr);
out.meanlnCr = mean(lnCr);


% fit linear to log-log plot (full range)
enoughpoints = 1;
try
    [a, stats] = robustfit(lnr,lnCr);
catch me
    if strcmp(me.message,'Not enough points to perform robust estimation.')
        enoughpoints = 0;
    end
end

if enoughpoints
    out.robfit_a1 = a(1);
    out.robfit_a2 = a(2);
    out.robfit_sigrat = stats.ols_s/stats.robust_s;
    out.robfit_s = stats.s;
    out.robfit_sea1 = stats.se(1);
    out.robfit_sea2 = stats.se(2);

    fit_lnCr = a(2)*lnr+a(1);
    % hold on;plot(lnr,fit_lnCr,'r');hold off
    res = lnCr-fit_lnCr';
    out.robfitresmeanabs = mean(abs(res));
    out.robfitresmeansq = mean(res.^2);
    out.robfitresac1 = CO_AutoCorr(res,1);
else
    out.robfit_a1 = NaN;
    out.robfit_a2 = NaN;
    out.robfit_sigrat = NaN;
    out.robfit_s = NaN;
    out.robfit_sea1 = NaN;
    out.robfit_sea2 = NaN;
    
    out.robfitresmeanabs = NaN;
    out.robfitresmeansq = NaN;
    out.robfitresac1 = NaN;
end
    

% now non-robust linear fit
% [p, S] = polyfit(lnr',lnCr,1);

end