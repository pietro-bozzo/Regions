function this = computeICA(this,opt)
% computeNetworkAval Compute avalanches using IC activity from each region

arguments
  this (1,1) regions
  opt.window (1,1) double {mustBePositive} = 0.01
  opt.save (1,1) {mustBeLogical} = false % SAVE ICA, TO IMPLEMENT (MAYBE, IF SLOW)
end

f = waitbar(0,'Please wait...');

num_states = numel(this.states);
num_ids = numel(this.ids);

% Time estimation setup
total_iterations = num_states * num_ids;
updateWaitBar(f, total_iterations, true);
q = parallel.pool.DataQueue;
afterEach(q, @(k) updateWaitBar(f, total_iterations, false));

IC_weights = cell(1, num_ids*num_states);
IC_activity = cell(1, num_ids*num_states);
time = cell(1, num_ids*num_states);

regions_array = transpose(this.regions_array);
regions_array = regions_array(:);
window = opt.window;

parfor k = 1 : num_states*num_ids
    region = regions_array(k);
    if region.id ~= 0
      spikes = region.spikes;
      [w,~,ic,t] = getICActivity(spikes,windowsize=window);
      IC_weights{k} = w;
      IC_activity{k}=ic;
      time{k} = t;
    end
    send(q, k);
end
close(f);

for i = 1 : num_states
    IC_w = IC_weights((i-1)*num_ids + 1:i*num_ids);
    IC_a = IC_activity((i-1)*num_ids + 1:i*num_ids);
    IC = homogeneousICS(IC_a);
    t = time{(i-1)*num_ids+1};
    this.brain_array(i,1) = brain(this.basename,this.session_path,IC_w,opt.window, t(1:size(IC,1)), IC, state=this.states(i));
end

for k = 1 : num_states*num_ids
    region = regions_array(k);
    id = region.id;
    if id ~= 0
        idRegion = find(this.ids == id);
        idState = find(strcmp(this.states, region.state));
        w = IC_weights{k};
        ic = IC_activity{k};
        t = time{k};
        this.regions_array(idState, idRegion) = region.setICComponents(w, opt.window, t, ic);
    end
end
end

function ICS = homogeneousICS(IC_activity)
    n = size(IC_activity, 2);
    lens = cellfun(@(x) size(x, 1), IC_activity);
    lens = lens(lens > 0);
    len = min(lens);
    ICS = [];
    for i = 1:n
        ic = IC_activity{i};
        if isempty(ic)
            ics = NaN(len, 1);
        else
            ics = ic(1:len,:);
        end
        ICS = [ICS, ics];
    end
end

function updateWaitBar(f, total_iterations, reset)
    persistent iter;
    if isempty(iter) || reset
        iter = 0;
    else
        iter = iter + 1;
    end
    waitbar(iter / total_iterations, f, sprintf('Computing (%d/%d)', iter, total_iterations)); % Update waitbar; change 1000 to N if necessary
end