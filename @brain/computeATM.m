function this = computeATM(this) % SHOULD THE COMPUTED P BE ADJUSTED FOR AVAL SIZE?
% computeATM Compute Avalanche Transition Matrix

arguments
  this (1,1) brain
end

% binarized IC activity
Z = (abs(zscore(this.ICs_activity)) > this.aval_threshold).';
% columns 2 to end of Z
X = reshape(Z(:,2:end),size(Z,1),1,size(Z,2)-1);
% columns 1 to end - 1 of Z
Y = reshape(Z(:,1:end-1),1,size(Z,1),size(Z,2)-1);
% Aijt = 1 iff Zi(t+1) = 1 and Zjt = 1
At = X.*Y;
% avalanches profile
profile = sum(Z,1).';
start = find([profile(1)~=0;profile(2:end)~=0&profile(1:end-1)==0]);
stop =  find([profile(2:end)==0&profile(1:end-1)~=0;profile(end)~=0]);
A = zeros(size(At,1),size(At,2),numel(start));
for i = 1 : numel(start)
  % Aijk: n of times Zi(t+1) = 1 when Zjt = 1 in aval k
  A(:,:,i) = sum(At(:,:,start(i):stop(i)-1),3);
  % Bj: number of times when Zjt = 1
  Bj = sum(Z(:,start(i):stop(i)-1),2).';
  A(:,:,i) = A(:,:,i) ./ repmat(Bj,numel(Bj),1);
end
this.ATM = mean(A,3,"omitnan");

% MAYBE FASTER METHOD, REQUIRES IMPLEMENTING ACCUMARRAY IN 3D
%profile = sum(Z,2); % avalanches profile  % CHECK DIM
%ind = [true;profile(2:end)~=0|profile(1:end-1)~=0]; % ind(i) = 0 if i is repeated zero
%A_clean = At(:,:,ind); % remove repeated zeros
% Aijk: n of times Zi(t+1) = 1 when Zjt = 1 in aval k
%A = accumarray(cumsum(A_clean==0)+(profile(1)~=0),A_clean);