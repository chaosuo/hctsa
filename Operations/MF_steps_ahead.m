% MF_steps_ahead
% 
% Given a model, characterizes the variation in goodness of model predictions
% across a range of prediction lengths, l, which is made to vary from
% 1-step ahead to maxsteps steps-ahead predictions.
% 
% Models are fit using code from Matlab's System Identification Toolbox:
% (i) AR models using the ar function,
% (ii) ARMA models using armax code, and
% (iii) state-space models using n4sid code.
% 
% The model is fitted on the full time series and then used to predict the same
% data.
% 
% INPUTS:
% y, the input time series
% 
% model, the time-series model to fit: 'ar', 'arma', or 'ss'
% 
% order, the order of the model to fit
% 
% maxsteps, the maximum number of steps ahead to predict
% 
% Outputs include the errors, for prediction lengths l = 1, 2, ..., maxsteps,
% returned for each model relative to the best performance from basic null
% predictors, including sliding 1- and 2-sample mean predictors and simply
% predicting each point as the mean of the full time series. Additional outputs
% quantify how the errors change as the prediction length increases from l = 1,
% ..., maxsteps (relative to a simple predictor).
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

function out = MF_steps_ahead(y,model,order,maxsteps)
% Ben Fulcher, 17/2/2010

%% Preliminaries
N = length(y); % length of the input time series

%% Inputs
% y, column vector of equally-spaced time series measurements
y = iddata(y,[],1); % Convert y to time series object

% model, a string specifying the model type to fit
if nargin < 2 || isempty(model)
    model = 'ar'; % use an AR model as default
end

% order, an extra parameter specific to the model choice specifying
% additional parameters, typically an integer or set of integers indicating
% the 'order' of the model.
if nargin < 3 || isempty(order)
    order = 2; % hopefully this is meaningful!
end

% maxsteps, maximum number of steps ahead for prediction
if nargin < 4 || isempty(maxsteps)
    maxsteps = 6; % compare up to 5 steps ahead by default
end

%% Set up test and training sets
ytrain = y; % the whole time series
ytest = y; % the whole time series

%% Fit the model
switch model
    case 'ar' % AR model
        if strcmp(order,'best') % fit 'best' AR model; by sbc
            % Use arfit software to retrieve the optimum ar order by some
            % criterion (Schwartz's Bayesian Criterion, SBC)
            % Uses Matlab code from ARfit
            % http://www.gps.caltech.edu/~tapio/arfit/
            [west, Aest, Cest, SBC, FPE, th] = ARFIT_arfit(ytrain.y, 1, 10, 'sbc', 'zero');
            order = length(Aest); 
        end
        m = ar(ytrain,order);
        
    case 'arma'
        m = armax(ytrain,order);
        
    case 'ss'
        m = n4sid(ytrain,order);
        
    otherwise
        error('Unknown model ''%s''',model);
end


%% Do the model and dumb predictions
yy = y.y;
steps = 1:maxsteps;

% Initialize statistic vectors
% ((-)) mf structure: for the model fit
mf.rmserrs = zeros(maxsteps,1);
mf.mabserrs = zeros(maxsteps,1);
mf.ac1s = zeros(maxsteps,1);

% ((-)) sliding mean 1
sm1.rmserrs = zeros(maxsteps,1);
sm1.mabserrs = zeros(maxsteps,1);
sm1.ac1s = zeros(maxsteps,1);

% ((-)) sliding mean 2
sm2.rmserrs = zeros(maxsteps,1);
sm2.mabserrs = zeros(maxsteps,1);
sm2.ac1s = zeros(maxsteps,1);

for i = 1:maxsteps
    % (1) *** Model m ***
    yp = predict(m, ytest, steps(i)); % across test set

    % Get statistics on residuals
    mres = yp.y - ytest.y;
    mres = mres(i:end);
    
    mf.rmserrs(i) = sqrt(mean(mres.^2));
    mf.mabserrs(i) = mean(abs(mres));
    mf.ac1s(i) = CO_AutoCorr(mres,1);
    
    % (2) *** Sliding mean 1 ***
    % A sliding mean of length 1
    % for n-step-ahead prediction, will predict using the value n steps
    % before it.
    mres = yy(i+1:end)-yy(1:N-i);
    
    sm1.rmserrs(i) = sqrt(mean(mres.^2));
    sm1.mabserrs(i) = mean(abs(mres));
    sm1.ac1s(i) = CO_AutoCorr(mres,1);
    
    % (3) *** Sliding mean 2 ***
    % A sliding mean of length 2
    sm2p = zeros(N-i-1,1);
    for j = 1:N-i-1
        seeds = yy(j:j+1);
        for k=1:i % average with itself this many times
            p = mean(seeds);
            seeds = [seeds(2),p];
        end
        sm2p(j) = p;
    end
    mres = yy(i+2:end) - sm2p;
    
    sm2.rmserrs(i) = sqrt(mean(mres.^2));
    sm2.mabserrs(i) = mean(abs(mres));
    sm2.ac1s(i) = CO_AutoCorr(mres,1);
end

% % (3) SMINF
% % sample mean predictor
sminf.res = yy - mean(yy);
sminf.rmserr = sqrt(mean(sminf.res.^2));
sminf.mabserr = mean(abs(sminf.res));
sminf.ac1 = CO_AutoCorr(sminf.res,1);


%% Get some output statistics
% note that num2str loses precision, but I don't care so much about this --
% I don't think we need such precision, anyway.

% bestdumbrms = min([sm1.rmserr,sm2.rmserr,sminf.rmserr]);
% bestdumbmabs = min([sm1.mabserr,sm2.mabserr,sminf.mabserr]);
% bestdumbac1 = min(abs([sm1.ac1,sm2.ac1,sminf.ac1]));


for i = 1:maxsteps
    % all relative to best dumb
    mirms = mf.rmserrs(i)/min([sm1.rmserrs(i), sm2.rmserrs(i), sminf.rmserr]); % rms error
    miabs = mf.mabserrs(i)/min([sm1.mabserrs(i), sm2.mabserrs(i), sminf.mabserr]); % absolute error

    eval(sprintf('out.rmserr_%u = mirms;',i));
    eval(sprintf('out.mabserr_%u = miabs;',i));
    
    % raw ac1 values -- ratios don't really make sense
    makeitso = abs(mf.ac1s(i));
    eval(sprintf('out.ac1_%u = makeitso;',i));
end

out.meandiffrmsabs = abs(mean(mf.rmserrs-mf.mabserrs));

% Try to quickly quantify shape   
% Other than being a boring increasing curve
out.meandiffrms = mean(diff(mf.rmserrs));
out.maxdiffrms = max(diff(mf.rmserrs));
out.stddiffrms = std(diff(mf.rmserrs));
out.ndown = sum(diff(mf.rmserrs)<0);

end