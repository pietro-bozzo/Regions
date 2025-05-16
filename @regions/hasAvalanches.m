function value = hasAvalanches(this)
% hasAvalanches Return true iff avalanches have already been computed or set

if isempty(this.aval_window)
  value = false;
else
  value = true;
end