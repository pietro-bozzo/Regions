function c = inhomogeneousVertcat(a,b,opt)
% inhomogeneousVertcat Vertically concatenate two arrays; if their second dimensions differ, either truncate
% the longest one or pad the shortest one with a chosen value
%
% arguments:
%     a      (a1,a2)
%     b      (b1,b2)
%     pad    string = 'NaN', used to choose concatenation mode; can be:
%              'None', for truncate mode
%              'value', for pad mode, where 'value' is casted to the same type of the input arrays
%
% output:
%     c      concatenation result;
%            c is either:
%                          (a1+b1,min(a2,b2)), in truncate mode
%                          (a1+b1,max(a2,b2)), in pad mode

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  a (:,:)
  b (:,:)
  opt.pad (1,1) string = 'NaN'
end

if opt.pad == "None"
  min_len = min(size(a,2),size(b,2));
  c = [a(:,1:min_len);b(:,1:min_len)];
else
  % cast pad value to type of a, if necessary
  if ~isa(opt.pad,class(a))
    opt.pad = cast(opt.pad,'like',a);
  end
  max_len = max(size(a,2),size(b,2));
  c = [ [a,repmat(opt.pad,size(a,1),max_len-size(a,2))]
        [b,repmat(opt.pad,size(b,1),max_len-size(b,2))] ];
end