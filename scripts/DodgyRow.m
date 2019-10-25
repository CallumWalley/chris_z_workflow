function [DoubleCheck] = DodgyRow(indirA, indir)
     % indirA contains individual data stored in mat_files from the previous running;
     % indirB contains individual data stored in mat_files from the current running;
     size = length(dir([indirA,'/*.mat']));
     ROW=[];
     for i=1:size
         file=dir([indirA, '/*-', num2str(i),'.mat']);
         lmat=struct2cell(load([file.folder,'/', file.name]));
         lmat=lmat{1};
         if isempty(lmat.LLORDASK) || isempty(lmat.LLORDBID)
             row=i;
             ROW=[ROW;row]; % indicates missing rows that are justifiable
         end
     end
     size2 = length(dir([indirB,'/*.mat']));
     if length(ROW) == size-size2
         DoubleCheck=0;
     else
         DoubleCheck=1;
     end
end