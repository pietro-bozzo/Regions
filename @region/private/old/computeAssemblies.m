function this = computeAssemblies(this,opt)
      arguments
        this (1,1) region
        opt.time_window (1,1) double {mustBeNonnegative} = 0
        opt.load (1,1) {mustBeLogical} = false
        opt.save (1,1) {mustBeLogical} = false
      end
      if opt.time_window ~= 0
        this.time_window = opt.time_window;
      end
      % set up file to load and save assemblies
      asmb_file = append(this.basename,'.asb.',num2str(this.id,'%02d'));
      if ~strcmp(this.state,"all")
        asmb_file = append(asmb_file,'.',this.state);
      end
      asmb_path = append(this.path,'/Assemblies/',asmb_file);
      % compute assemblies
      if opt.load
        try % try loading assemblies
          this.assemblies = readmatrix(asmb_path,FileType='text');
          this.asmb_sizes = sum(this.assemblies,2);
        catch except
          if strcmp(except.identifier,'MATLAB:textio:textio:FileNotFound')
            opt.load = false; % flag for failed loading, to enable saving if required
            if opt.save
              fprintf(1,append('Unable to load ',asmb_file,', it will be computed and saved.\n'));
            else
              save = input(append('Unable to load ',asmb_file,', it will be computed. Save it? [y,n]: '),'s');
              switch save
                case 'y', opt.save = true;
                case 'n'
                otherwise, fprintf(1,'Unrecognized input, assemblies won''t be saved.\n');
              end
            end
            [this.assemblies,this.asmb_sizes] = callISAC(this.spikes,time_window=this.time_window);
          else
            throw(except);
          end
        end
      else
        [this.assemblies,this.asmb_sizes] = callISAC(this.spikes,time_window=this.time_window);
      end
      if isempty(this.assemblies) % no assemblies detected, adjust n of columns to match n of neurons
        this.assemblies = zeros(0,length(unique(this.spikes(:,2))));
      end
      if ~opt.load && opt.save
        writematrix(this.assemblies,asmb_path,FileType='text');
      end
    end