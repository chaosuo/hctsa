% DN_RemovePoints
% 
% Analyze how some time-series properties function changes as points are removed
% from a time series.
% 
% A proportion, p, of points are removed from the time series according to some
% rule, and a set of statistics are computed before and after the change.
% 
% INPUTS:
% y, the input time series
% howtorem, how to remove points from the time series:
%               (i) 'absclose': those that are the closest to the mean,
%               (ii) 'absfar': those that are the furthest from the mean,
%               (iii) 'min': the lowest values,
%               (iv) 'max': the highest values,
%               (v) 'random': at random.
%               
% p, the proportion of points to remove
% 
% Output statistics include the change in autocorrelation, time scales, mean,
% spread, and skewness.
% 
% Note that this is a similar idea to that implemented in DN_OutlierInclude.
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

function out = DN_RemovePoints(y,howtorem,p)
% Ben Fulcher, September 2009

%% Preliminaries
N = length(y); % time-series length
doplot = 0; % plot output

%% Check inputs
if nargin < 2 || isempty(howtorem)
    howtorem = 'absfar'; % default
end
if nargin < 3 || isempty(p)
    p = 0.1; % 10%
end

switch howtorem
    case 'absclose' % remove a proportion p of points closest to the mean
        [~, is] = sort(abs(y),'descend');
    case 'absfar' % remove a proportion p of points furthest from the mean
        [~, is] = sort(abs(y),'ascend');
    case 'min'
        [~, is] = sort(y,'ascend');
    case 'max'
        [~, is] = sort(y,'descend');
    case 'random'
        is = randperm(N);
    otherwise
        error('Unknwon method ''%s''',howtorem);
end

rkeep = sort(is(1:round(N*(1-p))),'ascend');
y_trim = y(rkeep);

if doplot
    figure('color','w')
    hold off
    plot(y,'ok');
    hold on;
    plot(rkeep,y_trim,'.r')
    hold off;
    hist(y_trim,50)
end

acf_y = SUB_acf(y,8);
acf_y_trim = SUB_acf(y_trim,8);

if doplot
    figure('color','w')
    hold off;
    plot(acf_y,':b'); hold on;
    plot(acf_y_trim,':r');
end

%% Compute output statistics
out.fzcacrat = CO_FirstZero(y_trim,'ac')/CO_FirstZero(y,'ac');
out.ac2rat = acf_y_trim(2)/acf_y(2); % includes the sign
out.ac2diff = abs(acf_y_trim(2)-acf_y(2));
out.ac3rat = acf_y_trim(3)/acf_y(3); % includes the sign
out.ac3diff = abs(acf_y_trim(3)-acf_y(3));
out.sumabsacfdiff = sum(abs(acf_y_trim-acf_y));
out.mean = mean(y_trim);
out.median = median(y_trim);
out.std = std(y_trim);
out.skewnessrat = skewness(y_trim)/skewness(y); % Statistics Toolbox
out.kurtosisrat = kurtosis(y_trim)/kurtosis(y); % Statistics Toolbox


function acf = SUB_acf(x,n)
    % computes autocorrelation of the input sequence, x, up to a maximum time
    % lag, n
    acf = zeros(n,1);
    for i = 1:n
        acf(i) = CO_AutoCorr(x,i-1);
    end
end

end