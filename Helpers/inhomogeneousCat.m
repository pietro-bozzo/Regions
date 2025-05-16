function c = inhomogeneousCat(a,b,dim)
% inhomogeneousHorzcat Concatenate two arrays along given dimension, truncating the longest one if necessary
%
% arguments:
%     a      (a1,a2)
%     b      (b1,b2)
%     dim    double, dimension along which to operate
%
% output:
%     c      (c1,c2) double, concatenation result; let dim = i, then
%              ci = min(ai,bi) and for all j ~= i, cj = aj + bj
%              if any input is empty, the other is returned unmodified

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  a (:,:)
  b (:,:)
  dim (1,1) {mustBeInteger,mustBePositive} % mustBeNumeric,
end

if isempty(a)
  c = b;
elseif isempty(b)
  c = a ;
else
  ind_a = cell(ndims(a),1);
  ind_b = cell(ndims(b),1);
  for i = 1 : ndims(a) % CHECK THAT IS SAME AS ndims(b)
    if i ~= dim
      min_len = min(size(a,i),size(b,i));
      ind_a{i} = [true(min_len,1); false(size(a,i)-min_len,1)];
      ind_b{i} = [true(min_len,1); false(size(b,i)-min_len,1)];
    else
      ind_a{i} = true(size(a,i),1);
      ind_b{i} = true(size(b,i),1);
    end
  end
  c = cat(dim,a(ind_a{:}),b(ind_b{:}));
end