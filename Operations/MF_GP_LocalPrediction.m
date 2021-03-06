% ------------------------------------------------------------------------------
% MF_GP_LocalPrediction
% ------------------------------------------------------------------------------
% 
% Fits a given Gaussian Process model to a section of the time series and uses
% it to predict to the subsequent datapoint.
% 
% % Uses GP fitting code from the gpml toolbox, which is available here:
% http://gaussianprocess.org/gpml/code.
% 
%---INPUTS:
% y, the input time series
% 
% covfunc, covariance function in the standard form for the gpml package.
%           E.g., covfunc = {'covSum', {'covSEiso','covNoise'}} combines squared 
%           exponential and noise terms
%           
% ntrain, the number of training samples (for each iteration)
% 
% ntest, the number of testing samples (for each interation)
% 
% npreds, the number of predictions to make
% 
% pmode, the prediction mode:
%       (i) 'beforeafter': predicts the preceding time series values by training
%                           on the following values,
%       (ii) 'frombefore': predicts the following values of the time series by
%                    training on preceding values, and
%       (iii) 'randomgap': predicts random values within a segment of time
%                    series by training on the other values in that segment.
% 
% 
%---OUTPUTS: summaries of the quality of predictions made, the mean and
% spread of obtained hyperparameter values, and marginal likelihoods.
% 
% ------------------------------------------------------------------------------
% Copyright (C) 2013,  Ben D. Fulcher <ben.d.fulcher@gmail.com>,
% <http://www.benfulcher.com>
%
% If you use this code for your research, please cite:
% B. D. Fulcher, M. A. Little, N. S. Jones, "Highly comparative time-series
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

function out = MF_GP_LocalPrediction(y,covfunc,ntrain,ntest,npreds,pmode)
% Ben Fulcher, 20/1/2010

%% Preliminaries
doplot = 0; % plot outputs
N = length(y); % time-series length

%% Check Inputs
if size(y,2) > size(y,1)
    y = y'; % ensure a column vector input
end
if nargin < 2 || isempty(covfunc),
    fprintf(1,'Using a default covariance function: sum of squared exponential and noise\n')
    covfunc = {'covSum', {'covSEiso','covNoise'}};
end

if nargin < 3 || isempty(ntrain)
    ntrain = 20; % 20 previous data points to predict the next
end

if nargin < 4 || isempty(ntest)
    ntest = 5; % test on 5 data points into the future
end

if nargin < 5 || isempty(npreds) % number of predictions
    npreds = 10; % do it 10 times (equally-spaced) through the time series
end

if nargin < 6 || isempty(pmode)
    pmode = 'frombefore'; % predicts from previous ntrain datapoints
    % can also be 'randomgap' -- fills in random gaps in the middle of a string of
    % data
end

%% Set up loop
if ismember(pmode,{'frombefore','randomgap'})
    spns = floor(linspace(1,N-(ntest+ntrain),npreds)); % starting positions
elseif strcmp(pmode,'beforeafter')
    spns = floor(linspace(1,N-(ntest+ntrain*2),npreds)); % starting positions
end

mus = zeros(ntest,npreds); % predicted values
stderrs = zeros(ntest,npreds); % standard errors on predictions
yss = zeros(ntest,npreds); % test values
mlikelihoods = zeros(npreds,1); % marginal likelihoods of model

nhps = eval(feval(covfunc{:})); % number of hyperparameters
loghypers = zeros(nhps,npreds); % loghyperparameters

for i = 1:npreds
    %% (0) Set up test and training sets
    switch pmode
    case 'frombefore'
        tt = (1:ntrain)'; % times (make from 1)
        rt = spns(i):spns(i)+ntrain-1; % training range
        yt = y(rt); % training data
        
        ts = (ntrain+1 : ntrain+1 + ntest-1)'; % times
        rs = spns(i)+ntrain : spns(i)+ntrain + ntest-1; % test range
        ys = y(rs); % test data
        
    case 'randomgap'
        t = (1:ntrain+ntest)';
        r = randperm(ntrain+ntest);
        yy = y(spns(i):spns(i)+ntrain+ntest-1);
        
        rt = sort(r(1:ntrain),'ascend');
        tt = t(rt);
        yt = yy(rt);
        
        rs = sort(r(ntrain+1:end),'ascend');
        ts = t(rs);
        ys = yy(rs);
        
    case 'beforeafter'
        t = (1:ntrain*2+ntest)';
        r = ntrain+1:ntrain+1 + ntest-1;
        yy = y(spns(i):spns(i)+2*ntrain+ntest-1);
        
        rt = [1:ntrain, ntrain+ntest+1:ntrain*2+ntest];
        tt = t(rt);
        yt = yy(rt);
        
        rs = [ntrain+1 : ntrain+ntest];
        ts = t(rs);
        ys = yy(rs);
        
    otherwise
        error('Unknown prediction mode ''%s''',pmode);
    end
    
    % Process to normalize scales
    ys = (ys-mean(yt))/std(yt); % same transformation as training set
    yt = (yt-mean(yt))/std(yt); % zscore training set
    
    %% (1) Learn hyperparameters from training set (t)
    
    loghyper = MF_GP_LearnHyperp(covfunc,-50,tt,yt);
    
    if isnan(loghyper)
        fprintf(1,'Unable to learn hyperparameters for this time series\n');
        out = NaN; return
    end
    
    loghypers(:,i) = loghyper;
    
    % Get marginal likelihood for this model with hyperparameters optimized
    % over training data
    mlikelihoods(i) = - gpr(loghyper, covfunc, tt, yt);
    
    %% (2) Evaluate at test set (s)
    
    % evaluate at test points based on training time/data, predicting for
    % test times/data
    [mu, S2] = gpr(loghyper, covfunc, tt, yt, ts);
    
    % Compare to actual test data --> store in row of errs
    mus(:,i) = mu; % ~predicted values for time series points
    stderrs(:,i) = 2*sqrt(S2); % ~errors on those predictions
    yss(:,i) = ys;
    
    % Plot
    if doplot
        if strcmp(pmode,'frombefore')
            plot(tt,yt,'.-k');
            hold on;
            plot(ts,ys,'.-b');
            errorbar(ts,mu,2*sqrt(S2),'m');
            hold off;
        else
            plot(tt,yt,'ok');
            hold on;
            plot(ts,ys,'ob');
            errorbar(ts,mu,2*sqrt(S2),'m');
            hold off;
        end
    end

%     for j=1:ntest
%         % set up structure output
%         err = abs(mu(j)-ys(j))/sqrt(S2(j)); % in units of std at this point
%         eval(['out.abserr' num2str(i) '_' num2str(j) ' = err;']);
%     end
    
end

% Ok, we're done.

%% Return statistics on how well it did
%% (1) PREDICTION ERROR MEASURES
allstderrs = abs(mus-yss)./stderrs; % differences between predictions and actual
                              % in units of standard error (95% confidence
                              % interval error bars)
allabserrs = abs(mus-yss);


% largest error:
out.maxstderr = max(allstderrs(:));
out.maxabserr = max(allabserrs(:));
% smallest error:
out.minstderr = min(allstderrs(:));
out.minabserr = min(allabserrs(:));
% mean error (across all):
out.meanstderr = mean(allstderrs(:));
out.meanabserr = mean(allabserrs(:));

% Summary of how it did on each run:
stderr_run = mean(abs(mus-yss)./stderrs); % per run
abserr_run = mean(abs(mus-yss));

% Mean error for a run
out.meanstderr_run = mean(stderr_run);
out.meanabserr_run = mean(abserr_run);

% Max error for a run
out.maxstderr_run = max(stderr_run);
out.maxabserr_run = max(abserr_run);

% Min error for a run
out.minstderr_run = min(stderr_run);
out.minabserr_run = min(abserr_run);

% Error bar stats
out.maxerrbar = max(stderrs(:)); % largest error bar
out.meanerrbar = mean(stderrs(:)); % mean error bar length
out.minerrbar = min(stderrs(:)); % minimum error bar length


%% (2) HYPERPARAMETER MEASURES
% mean and std for each hyperparameter
for i = 1:nhps
    o1 = mean(loghypers(i,:));
    eval(sprintf('out.meanlogh%u = o1;',i));
    o2 = std(loghypers(i,:));
    eval(sprintf('out.stdlogh%u = o2;',i));
end

%% (3) Marginal likelihood measures
% Best marginal neg-log-likelihood attained
% Worst marginal neg-log-likelihood attained
% spread in marginal neg-log-likelihoods

out.maxmlik = max(mlikelihoods);
out.minmlik = min(mlikelihoods);
out.stdmlik = std(mlikelihoods);


end