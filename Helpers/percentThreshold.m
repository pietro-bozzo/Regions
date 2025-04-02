function [a,threshold] = percentThreshold(a,threshold)
% percentThreshold Threshold a trace using a percentile of its values
%
% arguments:
%     a            (n_samples,1) double, trace
%     threshold    double, percentile of a, must be in [0,100]
%
% output:
%     a            (n_samples,1) double, thresholded trace
%     threshold    double, threshold value computed from a

% Copyright (C) 2025 by Pietro Bozzo
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

arguments
  a (:,1) double
  threshold (1,1) double {mustBeNonnegative,mustBeLessThanOrEqual(threshold,100)}
end

threshold = prctile(a,threshold) % ADD OPTION FOR DOUBLE SIDE THRESHOLDING TO INCREASE GENERALITY
a = a - threshold;
a(a<0) = 0;