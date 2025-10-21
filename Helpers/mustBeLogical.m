function mustBeLogical(A)
%MUSTBELOGICAL Validate that value is logical
%   MUSTBELOGICAL(A) throws an error if A contains values different from 0 and 1.

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

if (~isnumeric(A)&&~islogical(A)) || ~all(A(A~=0)==1)
    error('mustBeLogical:notLogical','Value must be logical.')
end