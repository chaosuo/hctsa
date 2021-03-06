% ------------------------------------------------------------------------------
% SQL_TableCreateString
% ------------------------------------------------------------------------------
% 
% Determines the appropriate mySQL CREATE TABLE statement to use to create a given
% table, identified by the input string, WhatTable
% 
% Ben Fulcher, May 2013.
% ------------------------------------------------------------------------------
% Copyright (C) 2013,  Ben D. Fulcher <ben.d.fulcher@gmail.com>,
% <http://www.benfulcher.com>
% 
% If you use this code for your research, please cite:
% B. D. Fulcher, M. A. Little, N. S. Jones, "Highly comparative time-series
% analysis: the empirical structure of time series and their methods",
% J. Roy. Soc. Interface 10(83) 20130048 (2010). DOI: 10.1098/rsif.2013.0048
% 
% This work is licensed under the Creative Commons
% Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of
% this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send
% a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View,
% California, 94041, USA.
% ------------------------------------------------------------------------------

function CreateString = SQL_TableCreateString(WhatTable)

switch WhatTable
case 'Operations'
    CreateString = ['CREATE TABLE Operations ' ...
        '(op_id INTEGER NOT NULL AUTO_INCREMENT, ' ... % Unique integer identifier
        'OpName VARCHAR(255), ' ... % Unique name for the operation
        'Code VARCHAR(255), ' ... % Code to execute, or Master to retrieve from
        'Keywords VARCHAR(255), ' ... % Comma separated keyword metadata ...
        'MasterLabel VARCHAR(255), ' ... % Label of master code ...
        'mop_id INTEGER, ' ... % m_op id
        'LastModified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, ' ... % Last modified
        'PRIMARY KEY (op_id), ' ...  % sets primary key as op_id
        'FOREIGN KEY (mop_id) REFERENCES MasterOperations(mop_id) ON DELETE CASCADE ON UPDATE CASCADE)'];

case 'OperationCode'
    CreateString = ['CREATE TABLE OperationCode ' ...
        '(c_id INTEGER NOT NULL AUTO_INCREMENT, ' ...
        'CodeName VARCHAR(255), ' ...
        'Description TEXT, ' ...
        'LicenseType INTEGER UNSIGNED, ' ...
        'PRIMARY KEY (c_id))'];

case 'TimeSeries'
    CreateString = ['CREATE TABLE TimeSeries ' ...
        '(ts_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, ' ... % Unique integer identifier
        'Filename VARCHAR(255) NOT NULL, ' ... % FileName of the time series
        'Keywords VARCHAR(255), ' ... % Comma-delimited keywords assigned to the time series
        'Length INTEGER UNSIGNED, ' ... % Length of the time series
        'Data MEDIUMTEXT, ' ... % Add data into database :-O
        'LastModified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)']; % Time stamp of when the time series was last modified/inserted
        % 'Quantity VARCHAR(255), ' ... % The quantity measured across time
        % 'Unit VARCHAR(50), ' ... % The physical unit of the quantity measured
        % 'SamplingRate VARCHAR(50), ' ... % Sampling rate of the time series
        % 'Description TEXT, ' ... % More information about this specific time series

case 'MasterOperations'
    CreateString = ['CREATE TABLE MasterOperations ' ...
        '(mop_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, ' ... % Unique integer identifier
        'MasterLabel VARCHAR(255), ' ... % Name given to master code file
        'MasterCode VARCHAR(255), ' ... % Code to execute
        'NPointTo INTEGER UNSIGNED, ' ... % Number of children
        'LastModified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)']; % Time stamp of when entry was last modified
        
case 'OperationKeywords'
    CreateString = ['CREATE TABLE OperationKeywords ' ...
        '(opkw_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, ' ...
        'Keyword VARCHAR(255), ' ...
        'NumOccur INTEGER)'];
        % ', ' ...
%         'PercentageCalculated FLOAT, ' ...
%         'PercentageGood FLOAT, ' ...
%         'MeanCalcTime FLOAT)'];
        
case 'OpKeywordsRelate'
    CreateString = ['CREATE TABLE OpKeywordsRelate ' ...
        '(op_id INTEGER,' ...
        'opkw_id INTEGER, '  ...
        'FOREIGN KEY (opkw_id) REFERENCES OperationKeywords (opkw_id) ON DELETE CASCADE ON UPDATE CASCADE, ' ...
        'FOREIGN KEY (op_id) REFERENCES Operations (op_id) ON DELETE CASCADE ON UPDATE CASCADE)'];
        
case 'TimeSeriesKeywords'
    CreateString = ['CREATE TABLE TimeSeriesKeywords ' ...
        '(tskw_id INTEGER AUTO_INCREMENT PRIMARY KEY, ' ... % Unique identifier for each keyword
        'Keyword varchar(50), ' ... % The keyword
        'NumOccur INTEGER UNSIGNED, ' ... % Number of time series with this keyword
        'LastModified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)'];
    
case 'TsKeywordsRelate'
    CreateString = ['CREATE TABLE TsKeywordsRelate ' ...
        '(ts_id INTEGER, ' ...
        'tskw_id INTEGER, ' ...
        'FOREIGN KEY (tskw_id) REFERENCES TimeSeriesKeywords(tskw_id) ON DELETE CASCADE ON UPDATE CASCADE, ' ...
        'FOREIGN KEY (ts_id) REFERENCES TimeSeries(ts_id) ON DELETE CASCADE ON UPDATE CASCADE)'];
    
case 'Results'
    CreateString = ['CREATE TABLE Results ' ...
        '(ts_id integer, ' ...
        'op_id INTEGER, ' ...
        'Output DOUBLE, ' ...
        'QualityCode INTEGER UNSIGNED, ' ...
        'CalculationTime FLOAT, ' ...
        'LastModified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, ' ...
        'FOREIGN KEY (ts_id) REFERENCES TimeSeries(ts_id) ON DELETE CASCADE ON UPDATE CASCADE, ' ...
        'FOREIGN KEY (op_id) REFERENCES Operations(op_id) ON DELETE CASCADE ON UPDATE CASCADE, '...
        'PRIMARY KEY(ts_id,op_id))'];

otherwise
    error('Unknown table ''%s''',WhatTable)
    
end

end