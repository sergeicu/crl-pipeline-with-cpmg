function batch_fmri(seqname)
    clear jobs;
    spm('Defaults','fMRI');
    
    p = dir('fmri_*.nii');
    p = struct2cell(p);


    
     jobs{1}.spatial{1}.realign{1}.estwrite.data{1} = p(1,:);
     jobs{1}.spatial{1}.realign{1}.estwrite.eoptions.quality = 0.9;
     jobs{1}.spatial{1}.realign{1}.estwrite.eoptions.sep = 4;
     jobs{1}.spatial{1}.realign{1}.estwrite.eoptions.fwhm = 5;
     jobs{1}.spatial{1}.realign{1}.estwrite.eoptions.rtm = 1;
     jobs{1}.spatial{1}.realign{1}.estwrite.eoptions.interp = 2;
     jobs{1}.spatial{1}.realign{1}.estwrite.eoptions.wrap = [0 0 0];
     jobs{1}.spatial{1}.realign{1}.estwrite.eoptions.weight = {};
     jobs{1}.spatial{1}.realign{1}.estwrite.roptions.which = [2 1];
     jobs{1}.spatial{1}.realign{1}.estwrite.roptions.interp = 4;
     jobs{1}.spatial{1}.realign{1}.estwrite.roptions.wrap = [0 0 0];
     jobs{1}.spatial{1}.realign{1}.estwrite.roptions.mask = 1;
     
    r=strcat('r',p(1,:));
    sr=strcat('sr',p(1,:));
     
     jobs{1}.spatial{2}.smooth.data = r(1,:);
     jobs{1}.spatial{2}.smooth.fwhm = [6 6 6];
     jobs{1}.spatial{2}.smooth.dtype = 0;

    if strncmpi(seqname,'fmri_finger',11) == 1

      !echo "PROCESSING FINGER"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Left';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([0 60 120 180],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Right';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([20 80 140 200],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).name = 'Rest';
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).onset = reshape([40 100 160 220],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'Left';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '1 0 -1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{2}.tcon.name = 'Right';
        jobs{2}.stats{3}.con.consess{2}.tcon.convec = '0 1 -1';
        jobs{2}.stats{3}.con.consess{2}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{3}.tcon.name = 'Left and Right';
        jobs{2}.stats{3}.con.consess{3}.tcon.convec = '0.5 0.5 -1';
        jobs{2}.stats{3}.con.consess{3}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;

    end

    if strncmpi(seqname,'fmri_toe',8) == 1

      !echo "PROCESSING TOE"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Left';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([0 60 120 180],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Right';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([20 80 140 200],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).name = 'Rest';
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).onset = reshape([40 100 160 220],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'Left';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '1 0 -1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{2}.tcon.name = 'Right';
        jobs{2}.stats{3}.con.consess{2}.tcon.convec = '0 1 -1';
        jobs{2}.stats{3}.con.consess{2}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{3}.tcon.name = 'Left and Right';
        jobs{2}.stats{3}.con.consess{3}.tcon.convec = '0.5 0.5 -1';
        jobs{2}.stats{3}.con.consess{3}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;

    end


    if strncmpi(seqname,'fmri_flash',10) == 1

      !echo "PROCESSING FLASH"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Flash1';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([0 60 120 180],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Flash2';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([20 80 140 200],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).name = 'Rest';
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).onset = reshape([40 100 160 220],[4 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'flash1';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '1 0 -1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{2}.tcon.name = 'flash2';
        jobs{2}.stats{3}.con.consess{2}.tcon.convec = '0 1 -1';
        jobs{2}.stats{3}.con.consess{2}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;

    end



    if strncmpi(seqname,'fmri_obj',8) == 1

      !echo "PROCESSING OBJ"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Objects';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([10 18 25 34 38	51 55 65 69 72 82 87 95	99 106 116 119 137 140 145 155 160 170 178 184 196 212 216 248 266 271 280 286 300 309],[35 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'Objects';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '1 0';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;


    end



    if strncmpi(seqname,'fmri_ant_v',10) == 1

      !echo "PROCESSING ANT_V"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Antonyms';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([10 21 26 30 36 48 52 60 64 84 88 97 109 126 137 144 153 159 162 172 186 196 200 204 216 219 233 240 248 266 271 276 280 291],[34 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'Antonyms';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '1 0';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;


    end


    if strncmpi(seqname,'fmri_narr5',10) == 1

      !echo "PROCESSING NARR5"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Narr';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([0 60 120 180 240],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Rest';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([40 100 160 220 280],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'narr5';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '1 -1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{2}.tcon.name = 'narr5_0';
        jobs{2}.stats{3}.con.consess{2}.tcon.convec = '1 0';
        jobs{2}.stats{3}.con.consess{2}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;


    end



    if strncmpi(seqname,'fmri_narr10',11) == 1

      !echo "PROCESSING NARR10"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Narr';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([0 60 120 180 240 300 360 420 480 540],[10 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Rest';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([40 100 160 220 280 340 400 460 520 580],[10 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'narr10';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '1 -1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{2}.tcon.name = 'narr10_0';
        jobs{2}.stats{3}.con.consess{2}.tcon.convec = '1 0';
        jobs{2}.stats{3}.con.consess{2}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;


    end



    if strncmpi(seqname,'fmri_addt',9) == 1

      !echo "PROCESSING ADDT"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Baseline';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([0 60 120 180 240],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 30;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Decision';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([30 90 150 210 270],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 30;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'addt';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '-1 1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;



    end





    if strncmpi(seqname,'fmri_ant_a',10) == 1

      !echo "PROCESSING ANT_A"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Antonyms';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([10 19 26 44 50 61 65 88 91 102 107 114 119 127 140 152 162 171 177 181 184 195 201 204 208 226 229 234 237 244 249 257 265 268 276 280 288 292 298],[39 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'Antonyms';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '1 0';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;


    end




    if strncmpi(seqname,'fmri_passive',12) == 1

      !echo "PROCESSING PASSIVE"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';

        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Baseline';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([0 90 180 270 360],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 30;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);

        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Rest';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([30 120 210 300 390],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 30;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);

        jobs{2}.stats{1}.fmri_spec.sess.cond(3).name = 'Narrative';
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).onset = reshape([60 150 240 330 420],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).duration = 30;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).pmod = struct([]);

        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'Narrative-R';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '0 -1 1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;

        jobs{2}.stats{3}.con.consess{2}.tcon.name = 'Narrative-B';
        jobs{2}.stats{3}.con.consess{2}.tcon.convec = '-1 0 1';
        jobs{2}.stats{3}.con.consess{2}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;

        jobs{2}.stats{3}.con.consess{3}.tcon.name = 'Baseline-R';
        jobs{2}.stats{3}.con.consess{3}.tcon.convec = '1 -1 0';
        jobs{2}.stats{3}.con.consess{3}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;



    end



    if strncmpi(seqname,'fmri_visual',11) == 1

      !echo "PROCESSING VISUAL"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Fixation';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([40 140 200 280 360],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Whole';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([0 100 220 300 380],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).name = 'Right';
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).onset = reshape([20 80 180 240 340],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(3).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(4).name = 'Left';
        jobs{2}.stats{1}.fmri_spec.sess.cond(4).onset = reshape([60 120 160 260 320],[5 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(4).duration = 20;
        jobs{2}.stats{1}.fmri_spec.sess.cond(4).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(4).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'Left';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '-1 0 0 1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{2}.tcon.name = 'Right';
        jobs{2}.stats{3}.con.consess{2}.tcon.convec = '-1 0 1 0';
        jobs{2}.stats{3}.con.consess{2}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{3}.tcon.name = 'Whole';
        jobs{2}.stats{3}.con.consess{3}.tcon.convec = '-1 1 0 0';
        jobs{2}.stats{3}.con.consess{3}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;

    end





    if strncmpi(seqname,'fmri_wraml',10) == 1

      !echo "PROCESSING WRAML"

        jobs{2}.stats{1}.fmri_spec.dir{1} = '.';
        jobs{2}.stats{1}.fmri_spec.timing.units = 'secs';
        jobs{2}.stats{1}.fmri_spec.timing.RT = 2.5;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_r = 16;
        jobs{2}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
        jobs{2}.stats{1}.fmri_spec.sess.scans = sr(1,:)';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).name = 'Novel';
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).onset = reshape([10 20.5 23 35.5 38.5 52 56 62 71 73.5 79 91 97.5 101 104 113 120 123.5 132 137 143 150.5 153 164.5 173 175.5 192 202.5 208 215.5 222 227.5 234 240 247 252.5 257 267.5 273 279 286 293.5 301 303.5 317.5 322 331.5 337 342.5 346.5],[50 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).duration = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(1).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).name = 'Repeated';
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).onset = reshape([13.5 17.5 26.5 29 32.5 42 46 48.5 58.5 66 68.5 76.5 82.5 86 95 106.5 110 117 127 129.5 134.5 140 147 158 161 170.5 178 185 195.5 205.5 213 219.5 225 231.5 237 243.5 250 260.5 264.5 275.5 288.5 291 298.5 307 310.5 314 326.5 329 334.5 340],[50 1]);
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).duration = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).tmod = 0;
        jobs{2}.stats{1}.fmri_spec.sess.cond(2).pmod = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.regress = struct([]);
        jobs{2}.stats{1}.fmri_spec.sess.multi_reg{1} = '';
        jobs{2}.stats{1}.fmri_spec.sess.hpf = 128;
        jobs{2}.stats{1}.fmri_spec.fact = struct([]);
        jobs{2}.stats{1}.fmri_spec.bases.hrf.derivs = [0 0];                                                               
        jobs{2}.stats{1}.fmri_spec.volt = 1;
        jobs{2}.stats{1}.fmri_spec.global = 'None';
        jobs{2}.stats{1}.fmri_spec.mask{1} = '';
        jobs{2}.stats{1}.fmri_spec.cvi = 'AR(1)';
    
        jobs{2}.stats{2}.fmri_est.spmmat{1} = './SPM.mat';
        jobs{2}.stats{2}.fmri_est.method.Classical = 1;
    
        jobs{2}.stats{3}.con.spmmat{1} = './SPM.mat';
        jobs{2}.stats{3}.con.consess{1}.tcon.name = 'Repeated > Novel';
        jobs{2}.stats{3}.con.consess{1}.tcon.convec = '-1 1';
        jobs{2}.stats{3}.con.consess{1}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;
        jobs{2}.stats{3}.con.consess{2}.tcon.name = 'Repeated';
        jobs{2}.stats{3}.con.consess{2}.tcon.convec = '0 1';
        jobs{2}.stats{3}.con.consess{2}.tcon.sessrep = 'none';
        jobs{2}.stats{3}.con.delete = 0;


    end




    
    %spm_jobman('interactive',jobs);
    spm_jobman('run',jobs);
end
