% ------------------------------------------------------------------------------
% CO_f1ecac
% ------------------------------------------------------------------------------
% 
% Finds where autocorrelation function first crosses 1/e, the 1/e correlation
% length
% 
%---INPUTS:
% y, the input time series
% 
%---HISTORY:
% Ben Fulcher, 2008
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

function out = CO_f1ecac(y)
  
N = length(y); % time-series length
oone = 1/exp(1); % 1/e

for i = 1:N-1
    a(i) = CO_AutoCorr(y,i);
    if (i > 1) && ((a(i-1)-oone)*(a(i)-oone) < 0)
        % Crossed the 1/e line
        out = i;
        return
    end
end

% If no minimum in entire spectrum return the maximum value
out = N;

end