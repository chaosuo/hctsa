% SB_BinaryStretch
% 
% Measures the longest stretch of consecutive zeros or ones in a symbolized time
% series as a proportion of the time-series length.
% 
% The time series is symbolized to a binary string by whether it's above (1) or
% below (0) its mean.
% 
% It doesn't actually measure this correctly, due to an error in the code, but
% it's still kind of an interesting operation...?!
% 
% INPUTS:
% x, the input time series
% stretchwhat, (i) 'lseq1', measures something related to consecutive 1s
%              (ii) 'lseq0', measures something related to consecutive 0s
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

function out = SB_BinaryStretch(x,stretchwhat)
% Ben Fulcher, 2009

if nargin < 2 || isempty(stretchwhat)
    stretchwhat = 'lseq1'; % by default
end

N = length(x); % length of the time series
x(x > 0) = 1;
x(x <= 0) = 0;

switch stretchwhat
    case 'lseq1'
        % longest stretch of 1s (this doesn't actually measure this!)
        out = max(diff(BF_sgnchange(diff(find(x == 1))-1.5,1)))/N;
    case 'lseq0'
        % longest stretch of 0s (this doesn't actualy measure this!)
        out = max(diff(BF_sgnchange(diff(find(x == 0))-1.5,1)))/N;
    otherwise
        error('Unknown input %s',stretchwhat)
end

if isempty(out)
    out = 0;
end

end