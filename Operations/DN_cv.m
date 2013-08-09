% DN_cv
% 
% Calculates the coefficient of variation, sigma^k / mu^k, of order k
% 
% INPUTS:
% 
% x, the input time series
% 
% k, the order of coefficient of variation (k = 1 is usual)
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

function out = DN_cv(x,k)
% Ben Fulcher, 2009

% Check inputs
if nargin < 2 || isempty(k)
    k = 1; % Do standard CV by default
end
if (rem(k,1) ~= 0) || (k < 0)
    warning('k should probably be a positive integer');
    % Carry on with just this warning, though
end

out = (std(x))^k / (mean(x))^k;

end