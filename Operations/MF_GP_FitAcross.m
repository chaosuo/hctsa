% MF_GP_FitAcross
% 
% Trains a Gaussian Process model on equally-spaced points throughout the time
% series and uses the model to predict its intermediate values.
% 
% Uses GP fitting code from the gpml toolbox, which is available here:
% http://gaussianprocess.org/gpml/code.
% 
% INPUTS:
% y, the input time series
% covfunc, the covariance function (structured in the standard way for the gpml toolbox)
% npoints, the number of points through the time series to fit the GP model to
% 
% Outputs summarize the error and fitted hyperparameters.
% 
% In future could do a better job of the sampling of points -- perhaps to take
% into account the autocorrelation of the time series.
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

function out = MF_GP_FitAcross(y,covfunc,npoints)
% Ben Fulcher, 22/1/2010

doplot = 0; % set to 1 to visualize behavior

% Check inputs

if size(y,2) > size(y,1);
    y = y'; % make sure a column vector
end

if nargin < 2 || isempty(covfunc)
    fprintf(1,'Using default sum of SE and noise covariance function\n')
    covfunc = {'covSum', {'covSEiso','covNoise'}};
end

if nargin < 3 || isempty(npoints)
    npoints = 20;
end

%% Get the points
N = length(y); % time-series length
tt = floor(linspace(1,N,npoints))'; % time range (training)
yt = y(tt);

%% Optimize the GP parameters for the chosen covariance function

% Determine the number of hyperparameters, nhps
s = feval(covfunc{:}); % string in form '2+1', ... tells how many
% hyperparameters for each contribution to the
% covariance function
nhps = eval(s);


covfunc1 = covfunc{1};
covfunc2 = covfunc{2};
if (strcmp(covfunc1,'covSum')) && (strcmp(covfunc2{1},'covSEiso')) && (strcmp(covfunc2{2},'covNoise'))
    init_loghp = ones(3,1)*-1;
    % length parameter is in the ballpark of the difference between time
    % elements
    init_loghp(1) = log(mean(diff(tt)));
else
    init_loghp = ones(nhps,1)*-1;
end

try
    loghyper = MF_GP_LearnHyperp(covfunc,-50,tt,yt,init_loghp);
catch emsg
    error('Error learning hyperparameters for time series')
end
if isnan(loghyper)
    out = NaN;
    return
end

%% Evaluate over the whole space now
% evaluate at test points based on training time/data, predicting for
% test times/data
if N <= 2000
    ts = (1:N)';
else % memory constraints force us to crudely resample
    ts = round(linspace(1,N,2000))';
end
try
    [mu, S2] = gpr(loghyper, covfunc, tt, yt, ts);
catch emsg
    keyboard
    error('Error running Gaussian Process regression on time series: %s',emsg.message);
end


%% For Plotting
if doplot
    xstar = linspace(min(t),max(t),1000)';
    [mu, S2] = gpr(loghyper, covfunc, t, y, ts);
    S2p = S2 - exp(2*loghyper(3)); % remove noise from predictions
    S2p = S2;
    figure('color','w');
    f = [mu+2*sqrt(S2p); flipdim(mu-2*sqrt(S2p),1)];
    fill([ts; flipdim(ts,1)], f, [6, 7, 7]/8, 'EdgeColor', [7, 7, 6]/8);
            % grayscale error bars
    hold on;
    plot(ts,mu,'k-','LineWidth',2); % mean function
    plot(ts,y(ts),'.-k'); % original data
end


%% Outputs
S = sqrt(S2); % standard deviation function, S
% rms error from mean function, mu
out.rmserr = mean(sqrt((y(ts)-mu).^2));
out.meanstderr = mean(abs(y(ts)-mu)./S);
out.stdmu = std(mu);
out.meanS = mean(S);
out.stdS = std(S);

% Marginal Likelihood
try
    out.mlikelihood = - gpr(loghyper, covfunc, ts, y(ts));
catch
    out.mlikelihood = NaN;
end

% Loghyperparameters
for i = 1:nhps
    % set up structure output
    eval(sprintf('out.logh%u = loghyper(%u);',i,i));
end

if strcmp(covfunc1,'covSum') && strcmp(covfunc2{1},'covSEiso') && strcmp(covfunc2{2},'covNoise')
   % Give extra output based on length parameter on length of time series
   out.h_lonN = exp(loghyper(1))/N;
end



%% Subfunctions

%     function loghyper = MF_GP_LearnHyperp(covfunc,nfevals,t,y,init_loghyper)
%         % nfevals--  negative: specifies maximum number of allowed
%         % function evaluations
%         % t: time
%         % y: data
%         
%         if nargin < 5 || isempty(init_loghyper)
%             % Use default starting values for parameters
%             % How many hyperparameters
%             s = feval(covfunc{:}); % string in form '2+1', ... tells how many
%             % hyperparameters for each contribution to the
%             % covariance function
%             nhps = eval(s);
%             init_loghyper = ones(nhps,1)*-1; % Initialize all log hyperparameters at -1
%         end
% %         init_loghyper(1) = log(mean(diff(t)));
%         
%         % Perform the optimization
%         try
%             loghyper = minimize(init_loghyper, 'gpr', nfevals, covfunc, t, y);
%         catch emsg
%             if strcmp(emsg.identifier,'MATLAB:posdef')
%                 fprintf(1,'Error: lack of positive definite matrix for this function');
%                 loghyper = NaN; return
%             elseif strcmp(emsg.identifier,'MATLAB:nomem')
%                 error('Out of memory');
%                 % return as if a fatal error -- come back to this.
%             else
%                 error('Error fitting Gaussian Process to data')
%             end
%         end
%         
%     end


end