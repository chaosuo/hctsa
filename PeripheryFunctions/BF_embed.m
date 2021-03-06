% ------------------------------------------------------------------------------
% BF_embed
% ------------------------------------------------------------------------------
% 
% Returns a time-delay embedding of the input time series into an m dimensional
% space at a time delay tau.
% 
% Uses the TSTOOL code 'embed'
% 
% TSTOOL: http://www.physik3.gwdg.de/tstool/
% 
%---INPUTS:
% y, univariate scalar time series
% tau, time-delay. Can be a string, 'ac', 'mi', ...
% m, the embedding dimension. Must be a cell specifying method and parameters,
%    e.g., {'fnn',0.1} does fnn method using a threshold of 0.1...
% sig [opt], if 1, uses TSTOOL to embed and returns a signal object.
%           (default = 0, i.e., not to do this and instead return matrix).
%           If 2, returns a vector of [tau m] rather than any explicit embedding
% 
%---OUTPUT:
% A matrix of width m containing the vectors in the new embedding space...
% 
%---HISTORY:
% Ben Fulcher, October 2009
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

function y_embed = BF_embed(y,tau,m,sig)

bevocal = 0; % display information about embedding
N = length(y); % length of the input time series, y

% ------------------------------------------------------------------------------
%% (1) Time-delay, tau
% ------------------------------------------------------------------------------
if nargin < 2 || isempty(tau)
    tau = 1; % default time delay is 1
    sstau = 'to default of 1';
else
    if ischar(tau) % use a routine to inform tau
        switch tau
            case 'mi' % first minimum of mutual information function
                tau = CO_FirstMin(y,'mi');
                sstau = sprintf('by first minimum of mutual information to tau = %u');
            case 'ac' % first zero-crossing of ACF
                tau = CO_FirstZero(y,'ac');
                sstau = sprintf('by first zero crossing of autocorrelation function to tau = %u',tau);
            otherwise
                error('Invalid time-delay method ''%s''.',tau)
        end
    else
        sstau = sprintf('by user to %u',tau);
    end
end
% we now have an integer time delay tau
% explanation stored in string sstau for printing later

% ------------------------------------------------------------------------------
%% Determine the embedding dimension, m
% ------------------------------------------------------------------------------
if nargin < 3 || isempty(m) % set to default value
    m = 2; % embed in 2-dimensional space by default! Probably not a great default!
    ssm = sprintf('to (strange) default of %u',m);
else % use a routine to inform m
    if ~iscell(m), m = {m}; end
    if ischar(m{1})
        switch m{1}
            case 'fnnsmall'
                % uses Michael Small's fnn code
                if length(m) == 1
                    th = 0.01;
                else
                    th = m{2};
                end
                m = MS_unfolding(y,th,1:10,tau);
                ssm = sprintf('by Michael Small''s FNN code with threshold %f to m = %u',th,m);
                
            case 'fnnmar'
                % uses Marwin's fnn code in CRPToolbox
                % should specify threshold for proportion of fnn
                % default is 0.1
                % e.g., {'fnnmar',0.2} would use a threshold of 0.2
                % uses time delay determined above
                if length(m) == 1 % set default threshold 0.1
                    th = 0.1;
                else
                    th = m{2};
                end
                try
                    m = NL_crptool_fnn(y,10,2,tau,th);
                catch
                    fprintf(1,'Error with FNN code')
                    y_embed = NaN;
                    return
                end
                ssm = sprintf('by N. Marwan''s CRPtoolbox ''fnn'' code with threshold %f to m = %u',th,m);
                
            case 'cao'
                % Uses TSTOOL code for cao method to determine optimal
                % embedding dimension
                % max embedding dimension of 10
                % time delay determined by above method
                % 3 nearest neighbours
                % 20% of time series length as reference points
                if length(m) == 1
                    th = 10;
                end
                try
                    m = NL_CaosMethod(y,10,tau,3,0.2,{'mmthresh',th});
                catch
                    fprintf(1,'Call to TSTOOL function ''cao'' failed')
                    y_embed = NaN; return
                end
                ssm = sprintf('by TSTOOL function ''cao'' using ''mmthresh'' with threshold %f to m = %u',th,m);
            otherwise
                error('Embedding dimension, m, incorrectly specified.')
        end
    else
        m = m{1};
        ssm = sprintf('by user to %u',m);
    end
end
% we now have an integral embedding dimension, m

% ------------------------------------------------------------------------------
%% Do the embedding
% ------------------------------------------------------------------------------
if nargin < 4
    sig = 0; % Don't return a signal object, return a matrix
end

if sig == 2 % Just return the embedding parameters
    y_embed = [tau, m];
    return
end

% Use the TSTOOL embed function.
if size(y,2) > size(y,1) % make sure it's a column vector
    y = y';
end
try
    y_embed = embed(signal(y),m,tau);
catch me
    if strcmp(me.message,'Time series to short for chosen embedding parameters')
        fprintf(1,'Time series (N = %u) too short to embed\n',N);
        y_embed = NaN; return
    else
        % Could always try optimizing my own routine (below) so TSTOOL is not required for this step...
        error('Embedding time series using TSTOOL function ''embed'' failed')
    end
end

if ~sig
   y_embed = data(y_embed);
   % this is actually faster than my implementation, which is commented out below
end

if bevocal
    fprintf(1,['Time series embedded successfully: time delay tau = %s, ' ...
                        'embedding dimension m = %s'],sstau,ssm);
end


% if sig
%     y_embed = embed(signal(y),m,tau);
% else
% %     % my own routine
% %     % create matrix of element indicies
% %     % m wide (each embedding vector)
% %     % N-m*tau long (number of embedding vectors)
% %     y_embed = zeros(N-(m-1)*tau,m);
% %     for i=1:m
% %        y_embed(:,i) = (1+(i-1)*tau:1+(i-1)*tau+N-(m-1)*tau-1)';
% %     end
% % %     keyboard
% %     y_embed = arrayfun(@(x)y(x),y_embed); % take these elements of y
%     
%     % Shit, it's actually faster for large time series to use the TSTOOL version!!:
%     y_embed = data(embed(signal(y),m,tau));
%     
% end


end