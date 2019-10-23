function merge(indir, outdir)
    size = length(dir([indir,'/*.mat']));
    DATA=[];
    for i=1:size
        file=dir([indir, '/*-', num2str(i),'.mat']);
        lmat=struct2cell(load([file.folder,'/', file.name]));   
        DATA=[DATA lmat{1}];
    end
    save(outdir, 'DATA', 'v7.3');
end