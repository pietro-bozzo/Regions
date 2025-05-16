function c = inhomogeneousHorzcat(a,b)
% inhomogeneousHorzcat Horizontally concatenate two arrays, truncating the longest one if they differ in the first dimension
%
% arguments:
%     a    (a1,a2) double
%     b    (b1,b2) double
%
% output:
%     c    (min(a1,b1),a2+b2) double, concatenation result; if any input is empty, the other is returned unmodified

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

if isempty(a)
  c = b;
elseif isempty(b)
  c = a ;
else
  min_len = min(size(a,1),size(b,1));
  c = [a(1:min_len,:),b(1:min_len,:)];
end