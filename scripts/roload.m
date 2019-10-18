function [LinkBID, LinkASK] = roload(DATA)
LinkBID=[];
for s=1:length(DATA)
    Bid=DATA(s).BID_ID;
    B=[];
    for kk=1:length(Bid)
        if ~isnan(Bid(kk))
            if kk==1
                link=find(Bid(:,1)==Bid(kk));
                str=struct('Date',DATA(s).DATE, 'BidID', Bid(kk), 'Linked_Messages', link);
                LinkBID=[LinkBID str];
                disp('Useful BidID, keep it');
            elseif (kk>=2) && (isempty(intersect(Bid(kk),B)))
                link=find(Bid(:,1)==Bid(kk));
                str=struct('Date', DATA(s).DATE, 'BidID', Bid(kk), 'Linked_Messages', link);
                LinkBID=[LinkBID str];
                disp('Useful BidID, keep it');
            elseif (kk>=2) && (~isempty(intersect(Bid(kk),B)))
                    disp('This BidID is already contained in the previous links, ignore it !');
            end
        end
        disp(['Completed: ', num2str(kk), ' out of ', num2str(length(Bid))]);
        B=[B;Bid(kk)];
    end
    disp(['Day Completed: ', num2str(s), ' out of ', num2str(length(DATA))]);
end
%% a2. FOR EACH STOCK-DAY, FILTER OUT "DIRECTLY LINKED" ORDER MESSAGES BASED ON THE AskID
LinkASK=[];
for s=1:length(DATA)
    Ask=DATA(s).ASK_ID;
    A=[];
    for kk=1:length(Ask)
        if ~isnan(Ask(kk))
            if kk==1
                link=find(Ask(:,1)==Ask(kk));
                str=struct('Date',DATA(s).DATE, 'AskID', Ask(kk), 'Linked_Messages', link);
                LinkASK=[LinkASK str];
                disp('Useful AskID, keep it');
            elseif (kk>=2) && (isempty(intersect(Ask(kk),A)))
                link=find(Ask(:,1)==Ask(kk));
                str=struct('Date', DATA(s).DATE, 'AskID', Ask(kk), 'Linked_Messages', link);
                LinkASK=[LinkASK str];
                disp('Useful AskID, keep it');
            elseif (kk>=2) && (~isempty(intersect(Ask(kk),A)))
                    disp('This AskID is already contained in the previous links, ignore it !');
            end
        end
        disp(['Completed: ', num2str(kk), ' out of ', num2str(length(Ask))]);
        A=[A;Ask(kk)];
    end
    disp(['Day Completed: ', num2str(s), ' out of ', num2str(length(DATA))]);
end
%% Remove useless Linked_Messages
% messages that start with AMEND/DELETE are dodgy, should start with ENTER,
% remove them so aviod errors.
M=[];
for m=1:length(LinkASK)
    L_M=LinkASK(m).Linked_Messages;
    TYPe=DATA(1).Type;
    if (length(L_M)==1 && (TYPe(L_M)==2 || TYPe(L_M)==3))
        M=[M;m];
    elseif (length(L_M)>1 && (TYPe(L_M(1))==3 || TYPe(L_M(1))==2))
        M=[M;m];
    end
end
LinkASK(M)=[];
%% Remove useless Linked_Messages
% messages that start with AMEND/DELETE are dodgy, should start with ENTER,
% remove them so aviod errors.
M=[];
for m=1:length(LinkBID)
    L_M=LinkBID(m).Linked_Messages;
    TYPe=DATA(1).Type;
    if (length(L_M)==1 && (TYPe(L_M)==2 || TYPe(L_M)==3))
        M=[M;m];
    elseif (length(L_M)>1 && (TYPe(L_M(1))==3 || TYPe(L_M(1))==2))
        M=[M;m];
    end
end
LinkBID(M)=[];
end