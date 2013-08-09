% NL_TSTL_TakensEstimator
% 
% Implements the Taken's estimator for correlation dimension using the
% TSTOOL code takens_estimator.
%
% cf. "Detecting strange attractors in turbulence", F. Takens.
% Lect. Notes Math. 898 p366 (1981)
% 
% TSTOOL: http://www.physik3.gwdg.de/tstool/
% 
% INPUTS:
% y, the input time series
% Nref, the number of reference points (can be -1 to use all points)
% rad, the maximum search radius (as a proportion of the attractor size)
% past, the Theiler window
% embedparams, the embedding parameters for BF_embed, in the form {tau,m}
% 
% The output of this operation is simply the Taken's estimator of the correlation
% dimension, d2.
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

function out = NL_TSTL_TakensEstimator(y, Nref, rad, past, embedparams)
% Ben Fulcher, 14/11/2009

%% Check inputs
N = length(y); % time-series length

% 1) Nref
if nargin < 2 || isempty(Nref) 
    Nref = -1; % use all points
end

% 2) Maximum search radius (as proportion of attractor size)
if nargin < 3 || isempty(rad)
    rad = 0.05;
end

% 3) Theiler window
if nargin < 4 || isempty(past)
    past = 1; % just exclude current point
end
if (past > 0) && (past < 1)
    past = floor(N*past); % specify a fraction of the time series length...
end

% 4) Embedding parameters
if nargin < 5 || isempty(embedparams)
    embedparams = {'ac','cao'};
    fprintf(1,'Using default time-delay embedding using autocorrelation and cao\n')
else
    if length(embedparams) ~= 2
        error('Embedding parameters are incorrectly formatted, we need {tau,m}')
    end
end

%% Embed the signal
% convert to embedded signal object for TSTOOL
s = BF_embed(y,embedparams{1},embedparams{2},1);

if ~strcmp(class(s),'signal') && isnan(s); % embedding failed
    error('Embedding failed')
    % out = NaN; return
end


%% Run the TSTOOL Taken's estimation code
D2 = takens_estimator(s, Nref, rad, past);

out = D2;

end