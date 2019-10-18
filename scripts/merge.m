function merge(indir, outdir)
size = length(dir([indir,'/*.mat']));
output_mat=[];
for i=1:size
    file=dir([indir, '/*-', num2str(i),'.mat']);
    disp(file);
    lmat=struct2cell(load([file.folder,'/', file.name]));   
    output_mat=[output_mat lmat{1}];
end
save(outdir, 'output_mat');
end
