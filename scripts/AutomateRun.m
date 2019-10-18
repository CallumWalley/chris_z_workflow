function [DATA] = AutomateRun(file, row)
%% output DATA should contain 19+12=31 fields;
    inputObject = matfile(file);
    DATA=inputObject.DATA(1,row);
    %% calling the main function
    [LinkBID, LinkASK, RunsBid, RunsAsk] = StrategicRuns_v2(DATA);
    %% repeat the above algorithm with RunsBid & RunsAsk
    % 1. First make the structure and the field name of RunsBid & RunsAsk
    %    consistent with the LinkBID & LinkASK
    [RunsBid.Linked_Messages] = RunsBid.LinkedMessages; RunsBid = orderfields(RunsBid,[1:1,3,2:2]); RunsBid = rmfield(RunsBid,'LinkedMessages');
    [RunsAsk.Linked_Messages] = RunsAsk.LinkedMessages; RunsAsk = orderfields(RunsAsk,[1:1,3,2:2]); RunsAsk = rmfield(RunsAsk,'LinkedMessages');
    [LinkBID, LinkASK] = roload(DATA);
    %%
    B=[];
    for s=1:length(RunsBid)
        L=RunsBid(s).Linked_Messages;
        top=L(1);
        B=[B;top];
    end
    BB=[];
    for s=1:length(LinkBID)
        L=LinkBID(s).Linked_Messages;
        Top=L(1);
        BB=[BB;Top];
    end
    COORDINATE=[];
    for j=1:length(B)
        coordinate=find(BB(:,1)==B(j));
        COORDINATE=[COORDINATE;coordinate];
    end
    % merge BidID into RunsBid
    for p=1:length(RunsBid)
        coor=COORDINATE(p);
        RunsBid(p).BidID=LinkBID(coor).BidID;
    end
    %% Ask side
    B=[];
    for s=1:length(RunsAsk)
        L=RunsAsk(s).Linked_Messages;
        top=L(1);
        B=[B;top];
    end
    BB=[];
    for s=1:length(LinkASK)
        L=LinkASK(s).Linked_Messages;
        Top=L(1);
        BB=[BB;Top];
    end
    COORDINATE=[];
    for j=1:length(B)
        coordinate=find(BB(:,1)==B(j));
        COORDINATE=[COORDINATE;coordinate];
    end
    % merge BidID into RunsBid
    for p=1:length(RunsAsk)
        coor=COORDINATE(p);
        RunsAsk(p).AskID=LinkASK(coor).AskID;
    end
    %% 2. Identify how many inferred links does each row contain
    % BID SIDE
    numlink=[];
    for k=1:length(RunsBid)
        linkedmessages=RunsBid(k).Linked_Messages;
        bidid=DATA(1).BID_ID;
        BIDID=[];
        for j=1:length(linkedmessages)
            bid=bidid(linkedmessages(j));
            BIDID=[BIDID;bid];
        end
        num=length(unique(BIDID));
        numlink=[numlink;num];
    end
    if length(numlink)==length(RunsBid)
        for z=1:length(RunsBid)
            RunsBid(z).numlink=numlink(z);
        end
    end
    % ASK SIDE
    numlink=[];
    for k=1:length(RunsAsk)
        linkedmessages=RunsAsk(k).Linked_Messages;
        askid=DATA(1).ASK_ID;
        ASKID=[];
        for j=1:length(linkedmessages)
            ask=askid(linkedmessages(j));
            ASKID=[ASKID;ask];
        end
        num=length(unique(ASKID));
        numlink=[numlink;num];
    end
    if length(numlink)==length(RunsAsk)
        for z=1:length(RunsAsk)
            RunsAsk(z).numlink=numlink(z);
        end
    end
    %% clear redundant variables;
    clearvars -except DATA RunsAsk RunsBid row;
    %% 3. change the name of RunsBid to LinkBID and RunsAsk to LinkASK
    LinkBID = RunsBid; LinkASK = RunsAsk;
    clearvars RunsAsk RunsBid;
    %% 4. run the second stage run filter
    [RunsBid, RunsAsk] = RunSecondStage_v2(DATA, LinkBID, LinkASK);
    %%
    while ((length(LinkASK)-length(RunsAsk)~=1) || (length(LinkBID)-length(RunsBid)~=1))
        %% repeat the above algorithm with RunsBid & RunsAsk
        % 1. First make the structure and the field name of RunsBid & RunsAsk
        %    consistent with the LinkBID & LinkASK
        [RunsBid.Linked_Messages] = RunsBid.LinkedMessages; RunsBid = orderfields(RunsBid,[1:1,3,2:2]); RunsBid = rmfield(RunsBid,'LinkedMessages');
        [RunsAsk.Linked_Messages] = RunsAsk.LinkedMessages; RunsAsk = orderfields(RunsAsk,[1:1,3,2:2]); RunsAsk = rmfield(RunsAsk,'LinkedMessages');
        [LinkBID, LinkASK] = roload(DATA);
        %%
        B=[];
        for s=1:length(RunsBid)
            L=RunsBid(s).Linked_Messages;
            top=L(1);
            B=[B;top];
        end
        BB=[];
        for s=1:length(LinkBID)
            L=LinkBID(s).Linked_Messages;
            Top=L(1);
            BB=[BB;Top];
        end
        COORDINATE=[];
        for j=1:length(B)
            coordinate=find(BB(:,1)==B(j));
            COORDINATE=[COORDINATE;coordinate];
        end
        % merge BidID into RunsBid
        for p=1:length(RunsBid)
            coor=COORDINATE(p);
            RunsBid(p).BidID=LinkBID(coor).BidID;
        end
        %% Ask side
        B=[];
        for s=1:length(RunsAsk)
            L=RunsAsk(s).Linked_Messages;
            top=L(1);
            B=[B;top];
        end
        BB=[];
        for s=1:length(LinkASK)
            L=LinkASK(s).Linked_Messages;
            Top=L(1);
            BB=[BB;Top];
        end
        COORDINATE=[];
        for j=1:length(B)
            coordinate=find(BB(:,1)==B(j));
            COORDINATE=[COORDINATE;coordinate];
        end
        % merge BidID into RunsBid
        for p=1:length(RunsAsk)
            coor=COORDINATE(p);
            RunsAsk(p).AskID=LinkASK(coor).AskID;
        end
        %% 2. Identify how many inferred links does each row contain
        % BID SIDE
        numlink=[];
        for k=1:length(RunsBid)
            linkedmessages=RunsBid(k).Linked_Messages;
            bidid=DATA(1).BID_ID;
            BIDID=[];
            for j=1:length(linkedmessages)
                bid=bidid(linkedmessages(j));
                BIDID=[BIDID;bid];
            end
            num=length(unique(BIDID));
            numlink=[numlink;num];
        end
        if length(numlink)==length(RunsBid)
            for z=1:length(RunsBid)
                RunsBid(z).numlink=numlink(z);
            end
        end
        % ASK SIDE
        numlink=[];
        for k=1:length(RunsAsk)
            linkedmessages=RunsAsk(k).Linked_Messages;
            askid=DATA(1).ASK_ID;
            ASKID=[];
            for j=1:length(linkedmessages)
                ask=askid(linkedmessages(j));
                ASKID=[ASKID;ask];
            end
            num=length(unique(ASKID));
            numlink=[numlink;num];
        end
        if length(numlink)==length(RunsAsk)
            for z=1:length(RunsAsk)
                RunsAsk(z).numlink=numlink(z);
            end
        end
        %% clear redundant variables;
        clearvars -except DATA RunsAsk RunsBid row;
        %% 3. change the name of RunsBid to LinkBID and RunsAsk to LinkASK
        LinkBID = RunsBid; LinkASK = RunsAsk;
        clearvars RunsAsk RunsBid;
        %% 4. keep running the second stage run filter
        [RunsBid, RunsAsk] = RunSecondStage_v2(DATA, LinkBID, LinkASK);
    end
    %% this is the time to trigger the finalstage run;
    [RunsBid, RunsAsk] = RunFinalStage_v2(DATA, LinkBID, LinkASK);
    while ((length(LinkASK)-length(RunsAsk)~=1) || (length(LinkBID)-length(RunsBid)~=1))
        %% repeat the above algorithm with RunsBid & RunsAsk
        % 1. First make the structure and the field name of RunsBid & RunsAsk
        %    consistent with the LinkBID & LinkASK
        [RunsBid.Linked_Messages] = RunsBid.LinkedMessages; RunsBid = orderfields(RunsBid,[1:1,3,2:2]); RunsBid = rmfield(RunsBid,'LinkedMessages');
        [RunsAsk.Linked_Messages] = RunsAsk.LinkedMessages; RunsAsk = orderfields(RunsAsk,[1:1,3,2:2]); RunsAsk = rmfield(RunsAsk,'LinkedMessages');
        [LinkBID, LinkASK] = roload(DATA);
        %%
        B=[];
        for s=1:length(RunsBid)
            L=RunsBid(s).Linked_Messages;
            top=L(1);
            B=[B;top];
        end
        BB=[];
        for s=1:length(LinkBID)
            L=LinkBID(s).Linked_Messages;
            Top=L(1);
            BB=[BB;Top];
        end
        COORDINATE=[];
        for j=1:length(B)
            coordinate=find(BB(:,1)==B(j));
            COORDINATE=[COORDINATE;coordinate];
        end
        % merge BidID into RunsBid
        for p=1:length(RunsBid)
            coor=COORDINATE(p);
            RunsBid(p).BidID=LinkBID(coor).BidID;
        end
        %% Ask side
        B=[];
        for s=1:length(RunsAsk)
            L=RunsAsk(s).Linked_Messages;
            top=L(1);
            B=[B;top];
        end
        BB=[];
        for s=1:length(LinkASK)
            L=LinkASK(s).Linked_Messages;
            Top=L(1);
            BB=[BB;Top];
        end
        COORDINATE=[];
        for j=1:length(B)
            coordinate=find(BB(:,1)==B(j));
            COORDINATE=[COORDINATE;coordinate];
        end
        % merge BidID into RunsBid
        for p=1:length(RunsAsk)
            coor=COORDINATE(p);
            RunsAsk(p).AskID=LinkASK(coor).AskID;
        end
        %% 2. Identify how many inferred links does each row contain
        % BID SIDE
        numlink=[];
        for k=1:length(RunsBid)
            linkedmessages=RunsBid(k).Linked_Messages;
            bidid=DATA(1).BID_ID;
            BIDID=[];
            for j=1:length(linkedmessages)
                bid=bidid(linkedmessages(j));
                BIDID=[BIDID;bid];
            end
            num=length(unique(BIDID));
            numlink=[numlink;num];
        end
        if length(numlink)==length(RunsBid)
            for z=1:length(RunsBid)
                RunsBid(z).numlink=numlink(z);
            end
        end
        % ASK SIDE
        numlink=[];
        for k=1:length(RunsAsk)
            linkedmessages=RunsAsk(k).Linked_Messages;
            askid=DATA(1).ASK_ID;
            ASKID=[];
            for j=1:length(linkedmessages)
                ask=askid(linkedmessages(j));
                ASKID=[ASKID;ask];
            end
            num=length(unique(ASKID));
            numlink=[numlink;num];
        end
        if length(numlink)==length(RunsAsk)
            for z=1:length(RunsAsk)
                RunsAsk(z).numlink=numlink(z);
            end
        end
        %% clear redundant variables;
        clearvars -except DATA RunsAsk RunsBid row;
        %% 3. change the name of RunsBid to LinkBID and RunsAsk to LinkASK
        LinkBID = RunsBid; LinkASK = RunsAsk;
        clearvars RunsAsk RunsBid;
        %% 4. keep running the final stage run filter
        [RunsBid, RunsAsk] = RunFinalStage_v2(DATA, LinkBID, LinkASK);
    end
    %% get indicator of whether each row belongs to a LLorders;
        [RunsBid.Linked_Messages] = RunsBid.LinkedMessages; RunsBid = orderfields(RunsBid,[1:1,3,2:2]); RunsBid = rmfield(RunsBid,'LinkedMessages');
        [RunsAsk.Linked_Messages] = RunsAsk.LinkedMessages; RunsAsk = orderfields(RunsAsk,[1:1,3,2:2]); RunsAsk = rmfield(RunsAsk,'LinkedMessages');
        [LinkBID, LinkASK] = roload(DATA);
        %%
        B=[];
        for s=1:length(RunsBid)
            L=RunsBid(s).Linked_Messages;
            top=L(1);
            B=[B;top];
        end
        BB=[];
        for s=1:length(LinkBID)
            L=LinkBID(s).Linked_Messages;
            Top=L(1);
            BB=[BB;Top];
        end
        COORDINATE=[];
        for j=1:length(B)
            coordinate=find(BB(:,1)==B(j));
            COORDINATE=[COORDINATE;coordinate];
        end
        % merge BidID into RunsBid
        for p=1:length(RunsBid)
            coor=COORDINATE(p);
            RunsBid(p).BidID=LinkBID(coor).BidID;
        end
        %% Ask side
        B=[];
        for s=1:length(RunsAsk)
            L=RunsAsk(s).Linked_Messages;
            top=L(1);
            B=[B;top];
        end
        BB=[];
        for s=1:length(LinkASK)
            L=LinkASK(s).Linked_Messages;
            Top=L(1);
            BB=[BB;Top];
        end
        COORDINATE=[];
        for j=1:length(B)
            coordinate=find(BB(:,1)==B(j));
            COORDINATE=[COORDINATE;coordinate];
        end
        % merge BidID into RunsBid
        for p=1:length(RunsAsk)
            coor=COORDINATE(p);
            RunsAsk(p).AskID=LinkASK(coor).AskID;
        end
        %% 2. Identify how many inferred links does each row contain
        % BID SIDE
        numlink=[];
        for k=1:length(RunsBid)
            linkedmessages=RunsBid(k).Linked_Messages;
            bidid=DATA(1).BID_ID;
            BIDID=[];
            for j=1:length(linkedmessages)
                bid=bidid(linkedmessages(j));
                BIDID=[BIDID;bid];
            end
            num=length(unique(BIDID));
            numlink=[numlink;num];
        end
        if length(numlink)==length(RunsBid)
            for z=1:length(RunsBid)
                RunsBid(z).numlink=numlink(z);
            end
        end
        % ASK SIDE
        numlink=[];
        for k=1:length(RunsAsk)
            linkedmessages=RunsAsk(k).Linked_Messages;
            askid=DATA(1).ASK_ID;
            ASKID=[];
            for j=1:length(linkedmessages)
                ask=askid(linkedmessages(j));
                ASKID=[ASKID;ask];
            end
            num=length(unique(ASKID));
            numlink=[numlink;num];
        end
        if length(numlink)==length(RunsAsk)
            for z=1:length(RunsAsk)
                RunsAsk(z).numlink=numlink(z);
            end
        end
    %%
    % now save linked messgaes into DATA;
        DATA.RunsAsk=RunsAsk;
        DATA.RunsBid=RunsBid;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Separate HFT from nHFT orders (ask side);
    % 1. All rows where numlink>1 contained "Strategic Runs", we identify them.
    LLORD_A=[];
    I=[];
    for i=1:length(RunsAsk)
        if RunsAsk(i).numlink>1
            I=[I;i];
            LLORD_A=[LLORD_A;RunsAsk(i).Linked_Messages];
        end
    end
    RunsAsk(I)=[];
    
    LLORD_B=[];
    K=[];
    for k=1:length(RunsAsk)
        Messages=RunsAsk(k).Linked_Messages;
        % Find the record types of the messages
        TYPE=DATA(1).Type;
        TIMESTAMP=DATA(1).MILLISECONDS;
        Type=TYPE(Messages);
        timestamp=TIMESTAMP(Messages);
        index=find(Type(:,1)==4 | Type(:,1)==6);% find trade records
        % In this case there is no trade records, and there are more than 1 message so we can calculate latency;
        if (Type(1)==1) && (isempty(index)) && (length(Messages)>1)
            latency=diff(timestamp);
            if ~isempty(latency)
                idx=find(latency(:,1)<=100); % time differences between messages is within 100ms, indication of low latency;
                if ~isempty(idx)
                    K=[K;k];
                    LLORD_B=[LLORD_B;RunsAsk(k).Linked_Messages];
                end
            end
            % In this case there are one or more trade records;
        elseif (Type(1)==1) && (~isempty(index)) && (length(Messages)>1)
            timestamp(index)=[];
            latency=diff(timestamp);
            if ~isempty(latency)
                idx=find(latency(:,1)<=100); % time differences between messages is within 100ms, indication of low latency;
                if ~isempty(idx)
                    K=[K;k];
                    LLORD_B=[LLORD_B;RunsAsk(k).Linked_Messages];
                end
            end
        end
    end
    LLORDASK=[LLORD_A;LLORD_B];
    RunsAsk(K)=[];
    clearvars -except DATA LLORDASK row RunsAsk RunsBid;
    %% Do the same on the Bid side
    LLORD_A=[];
    I=[];
    for i=1:length(RunsBid)
        if RunsBid(i).numlink>1
            I=[I;i];
            LLORD_A=[LLORD_A;RunsBid(i).Linked_Messages];
        end
    end
    RunsBid(I)=[];
    
    LLORD_B=[];
    K=[];
    for k=1:length(RunsBid)
        Messages=RunsBid(k).Linked_Messages;
        % Find the record types of the messages
        TYPE=DATA(1).Type;
        TIMESTAMP=DATA(1).MILLISECONDS;
        Type=TYPE(Messages);
        timestamp=TIMESTAMP(Messages);
        index=find(Type(:,1)==4 | Type(:,1)==6);% find trade records
        % In this case there is no trade records, and there are more than 1 message so we can calculate latency;
        if (Type(1)==1) && (isempty(index)) && (length(Messages)>1)
            latency=diff(timestamp);
            if ~isempty(latency)
                idx=find(latency(:,1)<=100); % time differences between messages is within 100ms, indication of low latency;
                if ~isempty(idx)
                    K=[K;k];
                    LLORD_B=[LLORD_B;RunsBid(k).Linked_Messages];
                end
            end
            % In this case there are one or more trade records;
        elseif (Type(1)==1) && (~isempty(index)) && (length(Messages)>1)
            timestamp(index)=[];
            latency=diff(timestamp);
            if ~isempty(latency)
                idx=find(latency(:,1)<=100); % time differences between messages is within 100ms, indication of low latency;
                if ~isempty(idx)
                    K=[K;k];
                    LLORD_B=[LLORD_B;RunsBid(k).Linked_Messages];
                end
            end
        end
    end
    LLORDBID=[LLORD_A;LLORD_B];
    RunsBid(K)=[];
    clearvars -except DATA LLORDASK LLORDBID row;
    %% percentage of low latency orders on both sides
    [LinkBID, LinkASK] = roload(DATA);
    LenAsk=[];
    for i=1:length(LinkASK)
        LenAsk=[LenAsk;LinkASK(i).Linked_Messages];
    end
    LenBid=[];
    for i=1:length(LinkBID)
        LenBid=[LenBid;LinkBID(i).Linked_Messages];
    end
    percentageBid=length(LLORDBID)/length(LenBid);
    percentageAsk=length(LLORDASK)/length(LenAsk);
    % save percentage of LL orders on both sides;
    DATA.LLORDASK=LLORDASK;
    DATA.LLORDBID=LLORDBID;
    DATA.percentageAsk=percentageAsk;
    DATA.percentageBid=percentageBid;
    %% filter out non-low-latency order
    LenAsk=[];
    for i=1:length(LinkASK)
        LenAsk=[LenAsk;LinkASK(i).Linked_Messages];
    end
    LenAsk=sort(LenAsk);
    ID=[];
    for c=1:length(LLORDASK)
        id=find(LenAsk(:,1)==LLORDASK(c));
        ID=[ID;id];
    end
    LenAsk(ID)=[];
    %% bid side
    LenBid=[];
    for i=1:length(LinkBID)
        LenBid=[LenBid;LinkBID(i).Linked_Messages];
    end
    LenBid=sort(LenBid);
    ID=[];
    for c=1:length(LLORDBID)
        id=find(LenBid(:,1)==LLORDBID(c));
        ID=[ID;id];
    end
    LenBid(ID)=[];
    % save nLLorders on both sides;
    DATA.nLLORDASK=LenAsk;
    DATA.nLLORDBID=LenBid;
    %% check whether order has Qualifier "OB0", which means they are not in the LOB and should be removed
    QUALIFIERS=DATA(1).Qualifiers;
    for g=1:length(LinkASK)
        First=LinkASK(g).Linked_Messages(1);
        LinkASK(g).Qualifier=QUALIFIERS(First);
    end
    LLORDASK=sort(LLORDASK);
    REMOVE=[];
    for w=1:length(LLORDASK)
        for v=1:length(LinkASK)
            if ((ismember(LLORDASK(w),LinkASK(v).Linked_Messages)) && (LinkASK(v).Qualifier==3333))
                REMOVE=[REMOVE;LinkASK(v).Linked_Messages];
            end
        end
        disp(['Completed: ', num2str(w), ' out of ', num2str(length(LLORDASK))]);
    end
    REMOVE=unique(REMOVE);
    IDXREMOVE=[];
    for x=1:length(REMOVE)
        idxremove=find(LLORDASK(:,1)==REMOVE(x));
        IDXREMOVE=[IDXREMOVE;idxremove];
    end
    LLORDASK(IDXREMOVE)=[];
    DATA.no0B0LLORDASK=LLORDASK;
    %% BidSide
    QUALIFIERS=DATA(1).Qualifiers;
    for g=1:length(LinkBID)
        First=LinkBID(g).Linked_Messages(1);
        LinkBID(g).Qualifier=QUALIFIERS(First);
    end
    LLORDBID=sort(LLORDBID);
    REMOVE=[];
    for w=1:length(LLORDBID)
        for v=1:length(LinkBID)
            if ((ismember(LLORDBID(w),LinkBID(v).Linked_Messages)) && (LinkBID(v).Qualifier==3333))
                REMOVE=[REMOVE;LinkBID(v).Linked_Messages];
            end
        end
        disp(['Completed: ', num2str(w), ' out of ', num2str(length(LLORDBID))]);
    end
    REMOVE=unique(REMOVE);
    IDXREMOVE=[];
    for x=1:length(REMOVE)
        idxremove=find(LLORDBID(:,1)==REMOVE(x));
        IDXREMOVE=[IDXREMOVE;idxremove];
    end
    LLORDBID(IDXREMOVE)=[];
    DATA.no0B0LLORDBID=LLORDBID;
    %% Do the same for non-LL orders
    QUALIFIERS=DATA(1).Qualifiers;
    for g=1:length(LinkASK)
        First=LinkASK(g).Linked_Messages(1);
        LinkASK(g).Qualifier=QUALIFIERS(First);
    end
    LenAsk=sort(LenAsk);
    REMOVE=[];
    for w=1:length(LenAsk)
        for v=1:length(LinkASK)
            if ((ismember(LenAsk(w),LinkASK(v).Linked_Messages)) && (LinkASK(v).Qualifier==3333))
                REMOVE=[REMOVE;LinkASK(v).Linked_Messages];
            end
        end
        disp(['Completed: ', num2str(w), ' out of ', num2str(length(LenAsk))]);
    end
    REMOVE=unique(REMOVE);
    IDXREMOVE=[];
    for x=1:length(REMOVE)
        idxremove=find(LenAsk(:,1)==REMOVE(x));
        IDXREMOVE=[IDXREMOVE;idxremove];
    end
    LenAsk(IDXREMOVE)=[];
    DATA.no0B0nLLORDASK=LenAsk;
    %% Bidside
    QUALIFIERS=DATA(1).Qualifiers;
    for g=1:length(LinkBID)
        First=LinkBID(g).Linked_Messages(1);
        LinkBID(g).Qualifier=QUALIFIERS(First);
    end
    LenBid=sort(LenBid);
    REMOVE=[];
    for w=1:length(LenBid)
        for v=1:length(LinkBID)
            if ((ismember(LenBid(w),LinkBID(v).Linked_Messages)) && (LinkBID(v).Qualifier==3333))
                REMOVE=[REMOVE;LinkBID(v).Linked_Messages];
            end
        end
        disp(['Completed: ', num2str(w), ' out of ', num2str(length(LenBid))]);
    end
    REMOVE=unique(REMOVE);
    IDXREMOVE=[];
    for x=1:length(REMOVE)
        idxremove=find(LenBid(:,1)==REMOVE(x));
        IDXREMOVE=[IDXREMOVE;idxremove];
    end
    LenBid(IDXREMOVE)=[];
    DATA.no0B0nLLORDBID=LenBid;
end