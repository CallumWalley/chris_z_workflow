function [RunsBid, RunsAsk] = RunSecondStage_v2(DATA, LinkBID, LinkASK)
% This function repeats the main routine "StrategicRuns_v2"
% algorithm in order to further filter out runs that are omitted
% in the initial stage (some directly linked messages are removed
% in the main routine during the first run filter and as a
% result, there might be some runs unable to be captured. To
% capture all runs, this function conducts the second stage
% filter to capture the missing runs from the first stage.
%% SAVE DATE TO A SEPARATE DATASET FOR LATER USE.
DATE=[];
for l=1:length(DATA)
    date=DATA(l).DATE;
    DATE=[DATE;date];
end
%%
D=zeros(length(LinkBID),2);
for o=1:length(LinkBID)
    Date=LinkBID(o).Date;
    BidID=LinkBID(o).BidID;
    D(o,:)=[Date,BidID];
end
%% Inferring the link. Start the searching process from the first message submitted with Type ENTER

% 1. FIRST LOCATE STRATEGIC RUNS ON THE BID SIDE
RunsBid=[];
m=0;
while length(LinkBID)>=2
    if LinkBID(1).numlink==1
        InferredLink=[];
        TreatedLink=LinkBID(1).Linked_Messages;
        TreatedLink=sort(TreatedLink);
        END=TreatedLink(end); % This is the end of the previous linked messages

        % If the previous linked messages ended up with DELETE (cancellation),
        % then we follow Hasbrouck & Saar (2013) to impute a link by DIRECTION,
        % SIZE, and TIMING.
        id=find(DATE(:,1)==LinkBID(1).Date);
        Type=DATA(id).Type;
        Volume=DATA(id).VOLUME;
        time=DATA(id).MILLISECONDS;
        Direction=DATA(id).Direction;
        % Only impute a link if the previous linked messages ended up with
        % DELETE.
        if Type(END)==2
            % If the previous linked messages ended up with DELETE, then the
            % end of the previous messages reports a NaN in the field VOLUME,
            % find the valid Volume for this particular linked message series.
            Vol=Volume(TreatedLink);
            % From Vol we infer the valid volume in order to impute the link
            Dir=Direction(TreatedLink);
            % First check there are no TRADEs within the linked messages.
            RecordType=Type(TreatedLink);
            index=find(RecordType(:,1)==4); % recall that 4 represents TRADE
            if isempty(index) && length(unique(RecordType))>1
                % Find the non-NaN Volume as the valid share size for this
                % particular link.
                idx1=find(RecordType(:,1)==3); % find AMENDs
                idx2=find(RecordType(:,1)==1); % find ENTER
                if isempty(idx1)
                    % In this case, the treated link have NOT experienced order
                    % AMENDs, nor are they TRADEd. But they ended up with being
                    % DELETEd, so the valid volume to impute a link is the
                    % volume from the first ENTER.
                    size=Vol(idx2);
                    dir=Dir(idx2);
                elseif ~isempty(idx1)
                    % In this case, the series of linked messages have
                    % experienced some order AMENDs, but are not TRADEd. They
                    % also ended up being DELETEd, so the valid volome is the
                    % volume from the last AMEND.
                    idx3=idx1(end);
                    size=Vol(idx3);
                    dir=Dir(idx3);
                end
                InferredLinkID=D(1,2);
                InferredLink=TreatedLink;
                for k=2:length(LinkBID)
                    NextLink=LinkBID(k).Linked_Messages;
                    Start=NextLink(1); % This is the start of the next linked messages
                    ID=find(DATE(:,1)==LinkBID(k).Date);
                    % Do not link messages across days
                    if ID==id
                        % Impute a link according to direction(Bid/Ask), size(Volume), and timing (time elapsed)
                        if (Type(Start)==1 && Volume(Start)== size && Direction(Start) == dir && ((time(Start)-time(END))<=100) && ((time(Start)-time(END))>=0))
                            % If the subsequent (k-th) order submission (ENTER)
                            % is of the same size and direction as the previous
                            % cancelled (DELETE) link and is within 100
                            % milliseconds, we infer a linked strategic run.

                            % RECORD THE ID OF IMPUTED LINKS AND REMOVE THESE
                            % FROM THE 'LinkBID' BEFORE IMPUTING THE NEXT RUN.
                            InferredLinkid=D(k,2);
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            % THESE ARE THE LINKED MESSAGES
                            InferredLink=[InferredLink;NextLink];
                            disp('linked messages found');
                        elseif (Type(Start)~=1 || Volume(Start)~= size || ((time(Start)-time(END))>100) || Direction(Start) ~= dir)
                            InferredLinkid=[];
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            InferredLink=[InferredLink;[]];
                            disp('linked messages not found');
                        end
                    else
                        disp('The next message is from a different day, stop processing !');
                    end
                end
                str=struct('Date', LinkBID(1).Date, 'LinkedMessages', InferredLink);
                RunsBid=[RunsBid str];
                % If part of the order is executed (TRADEd) and the remainder
                % is cancelled (DELETEd), follow the same steps as above, but
                % for the cancelled quantity.
                elseif ~isempty(index)
                    % The linked messages have some TRADEs in it but ended up
                    % with DELETE. That means the original order is partially
                    % executed with the remaining quantities being cancelled.
                    % We redo the above procedure, based on the cancelled
                    % quantity.
                    idx1=find(RecordType(:,1)==3); % find AMENDs
                    idx2=find(RecordType(:,1)==1); % find ENTER
                    % 1. There are NO AMENDs in the linked messages, so the
                    % cancelled quantity is the difference between the ENTER
                    % and the sum of all TRADEs.
                    if (RecordType(end)==2 && isempty(idx1))
                        V=[];
                        for a=1:length(index)
                          v=Vol(index(a));
                          V=[V;v];
                        end
                        % Next we calculate the cancelled quantity.
                        CancelVol=Vol(idx2)-sum(V);
                        dir=Dir(idx2);
                    % 2. There are order AMENDs in the linked messages, the
                    % cancelled quantity depends on the order of messages.
                    elseif (RecordType(end)==2 && ~isempty(idx1))
                        % 2.1. If the last message before DELETE in the end is
                        % AMEND, then the cancelled quantity is the last AMEND
                        % quantity.
                        if RecordType(end-1)==3
                            idx3=idx1(end);
                            CancelVol=Vol(idx3);
                            dir=Dir(idx3);
                        % 2.2. If the last message before DELETE in the end is
                        % TRADE, and the immediate message before that TRADE is
                        % AMEND, then the cancelled quantity is the difference
                        % between the last AMEND and the last TRADE.
                        elseif RecordType(end-1)==4
                            idx3=idx1(end); % last AMEND
                            if idx3==(length(RecordType)-2)
                                CancelVol=Vol(idx3)-Vol(end-1);
                                dir=Dir(idx3);
                            % If the last message before DELETE in the end is
                            % TRADE, and the immediate message before that
                            % TRADE is NOT AMEND(i.e., is another TRADE), then
                            % the cancelled quantity is the difference between
                            % the last AMEND and all the TRADEs after the last
                            % AMEND.
                            elseif idx3<(length(RecordType)-2)
                                V=[];
                                for a=1:(length(RecordType)-1-idx3)
                                    v=Vol(idx3+a);
                                    V=[V;v];
                                end
                                CancelVol=Vol(idx3)-sum(V);
                                dir=Dir(idx3);
                            end
                        end
                    end
                    % Knowing the cancelled quantity, we next impute the link
                    % following the same procedure.
                    InferredLinkID=D(1,2);
                    InferredLink=TreatedLink;
                    for k=2:length(LinkBID)
                        NextLink=LinkBID(k).Linked_Messages;
                        Start=NextLink(1); % This is the start of the next linked messages
                        ID=find(DATE(:,1)==LinkBID(k).Date);
                        % Do not link messages across days
                        if ID==id
                            % Impute a link according to direction(Bid/Ask),
                            % size(Volume), and timing(time elapsed).
                            if (Type(Start)==1 && Volume(Start)== CancelVol && Direction(Start) == dir && ((time(Start)-time(END))<=100) && ((time(Start)-time(END))>=0))
                                % If the subsequent (k-th) order submission
                                % (ENTER) is of the same size and direction as
                                % the previous partially cancelled quantity and
                                % is within 100 milliseconds, we infer a run.

                                % RECORD THE ID OF IMPUTED LINKS AND REMOVE
                                % THESE FROM THE 'LinkBID' BEFORE IMPUTING THE
                                % NEXT RUN.
                                InferredLinkid=D(k,2);
                                InferredLinkID=[InferredLinkID;InferredLinkid];
                                % THESE ARE THE LINKED MESSAGES
                                InferredLink=[InferredLink;NextLink];
                                disp('linked messages found');
                            elseif (Type(Start)~=1 || Volume(Start)~= CancelVol || ((time(Start)-time(END))>100) || Direction(Start) ~= dir)
                                InferredLinkid=[];
                                InferredLinkID=[InferredLinkID;InferredLinkid];
                                InferredLink=[InferredLink;[]];
                                disp('linked messages not found');
                            end
                        else
                            disp('The next message is from a different day, stop processing !');
                        end
                    end
                    str=struct('Date', LinkBID(1).Date, 'LinkedMessages', InferredLink);
                    RunsBid=[RunsBid str];
            elseif length(unique(RecordType))==1
                InferredLinkID=D(1,2);
                InferredLink=[InferredLink;TreatedLink];
                str=struct('Date', LinkBID(1).Date, 'LinkedMessages', InferredLink);
                RunsBid=[RunsBid str];
                disp('The message was dodgy and possibly due to data errors, ignore it !');
            end
        % For linked messages not ended up with DELETE, we do not impute a
        % indirect link. Instead, just keep the original 'directly linked'
        % messages.
           % THIS MIGHT OCCUR FOR THE FOLLOWING REASONS:
             % 1. The order is entered but not traded or active and expires at
             % the end of the day.

             % 2. The order starts with a TRADE, but qualifiers indicate "CX",
             %    this is a trade in the ASX Centre Point (dark pool) reported
             %    to the CLOB. Since we do not observe submission and
             %    cancellation of non-displayed non-marketable limit orders in
             %    the anonymous crossing networks, there is no clear-cut way to
             %    infer a run.
        elseif Type(END)~=2
            InferredLinkID=D(1,2);
            InferredLink=[InferredLink;TreatedLink];
            str=struct('Date', LinkBID(1).Date, 'LinkedMessages', InferredLink);
            RunsBid=[RunsBid str];
            disp('The message was not cancelled, so it is either traded or expires at the end of day');
        end
        % Remove tagged messages so that they are not reused in the next run.
        INDEX=[];
        for p=1:length(InferredLinkID)
            Index=find((D(:,1)==LinkBID(1).Date) & (D(:,2)==InferredLinkID(p)));
            INDEX=[INDEX;Index];
        end
        LinkBID(INDEX)=[];
        D(INDEX,:)=[];
        m=m+1;
        disp(['Indicate number: ',num2str(m)]);
    elseif LinkBID(1).numlink>=2
        % As this is the second stage run, so the function inputs LinkBID & LinkASK
        % may contain multiple groups of directly linked messages. For
        % instance, one row of Linked_Messages can be:
        % [1;2;6;8;13;14], where [1;2], [6;8], and [13;14] are three separate
        % groups of messages that are directly linked through unique BID/ASKIDs
        % and they are further inferred to be part of the same strategic run as
        % per Hasbrouck & Saar (2013).
        
        % The point of the second stage run is to capture the inferred
        % links that are unable to be detected in the initial stage since
        % in the initial stage many rows of directly linked messages are
        % deleted in each loop.
        
        % If one particular row of Linked_Messages has more than 1 group of
        % directly linked messages (via BidID/AskID), then these groups of
        % messages are inferred to be part of the same strategic run. In
        % other words, group number 2 to the end (e.g., [6;8], and
        % [13;14]) are removed and there might be some missing links as a
        % result.
        
        % We reiterate the first stage strategic run procedure for all such
        % groups of messages that are removed in the initial stage.
        Infer=[];
        InferID=[];
        for s=2:LinkBID(1).numlink
            InferredLink=[];
            TreatedLink=LinkBID(1).Linked_Messages;
            TreatedLink=sort(TreatedLink);
            bidid=DATA(1).BID_ID;
            bidid=bidid(TreatedLink);
            BID=unique(bidid);
            idx= bidid(:,1)==BID(s);
            TreatedLink=TreatedLink(idx);
            END=TreatedLink(end); % This is the end of the s-th directly linked messages
        % If the previous linked messages ended up with DELETE (cancellation),
        % then we follow Hasbrouck & Saar (2013) to impute a link by DIRECTION,
        % SIZE, and TIMING.
            id=find(DATE(:,1)==LinkBID(1).Date);
            Type=DATA(id).Type;
            Volume=DATA(id).VOLUME;
            time=DATA(id).MILLISECONDS;
            Direction=DATA(id).Direction;
        % Only impute a link if the previous linked messages ended up with
        % DELETE.
        if Type(END)==2
            % If the previous linked messages ended up with DELETE, then the
            % end of the previous messages reports a NaN in the field VOLUME,
            % find the valid Volume for this particular linked message series.
            Vol=Volume(TreatedLink);
            % From Vol we infer the valid volume in order to impute the link
            Dir=Direction(TreatedLink);
            % First check there are no TRADEs within the linked messages.
            RecordType=Type(TreatedLink);
            index=find(RecordType(:,1)==4); % recall that 4 represents TRADE
            if isempty(index)
                % Find the non-NaN Volume as the valid share size for this
                % particular link.
                idx1=find(RecordType(:,1)==3); % find AMENDs
                idx2=find(RecordType(:,1)==1); % find ENTER
                if isempty(idx1)
                    % In this case, the treated link have NOT experienced order
                    % AMENDs, nor are they TRADEd. But they ended up with being
                    % DELETEd, so the valid volume to impute a link is the
                    % volume from the first ENTER.
                    size=Vol(idx2);
                    dir=Dir(idx2);
                elseif ~isempty(idx1)
                    % In this case, the series of linked messages have
                    % experienced some order AMENDs, but are not TRADEd. They
                    % also ended up being DELETEd, so the valid volome is the
                    % volume from the last AMEND.
                    idx3=idx1(end);
                    size=Vol(idx3);
                    dir=Dir(idx3);
                end
                InferredLinkID=D(1,2);
                InferredLink=LinkBID(1).Linked_Messages;
                for k=2:length(LinkBID)
                    NextLink=LinkBID(k).Linked_Messages;
                    Start=NextLink(1); % This is the start of the next linked messages
                    ID=find(DATE(:,1)==LinkBID(k).Date);
                    % Do not link messages across days
                    if ID==id
                        % Impute a link according to direction(Bid/Ask), size(Volume), and timing (time elapsed)
                        if (Type(Start)==1 && Volume(Start)== size && Direction(Start) == dir && ((time(Start)-time(END))<=100) && ((time(Start)-time(END))>=0))
                            % If the subsequent (k-th) order submission (ENTER)
                            % is of the same size and direction as the previous
                            % cancelled (DELETE) link and is within 100
                            % milliseconds, we infer a linked strategic run.

                            % RECORD THE ID OF IMPUTED LINKS AND REMOVE THESE
                            % FROM THE 'LinkBID' BEFORE IMPUTING THE NEXT RUN.
                            InferredLinkid=D(k,2);
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            % THESE ARE THE LINKED MESSAGES
                            InferredLink=[InferredLink;NextLink];
                            disp('linked messages found');
                        elseif (Type(Start)~=1 || Volume(Start)~= size || ((time(Start)-time(END))>100) || Direction(Start) ~= dir)
                            InferredLinkid=[];
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            InferredLink=[InferredLink;[]];
                            disp('linked messages not found');
                        end
                    else
                        disp('The next message is from a different day, stop processing !');
                    end
                end
                Infer=[Infer;InferredLink];
                InferID=[InferID;InferredLinkID];
                % If part of the order is executed (TRADEd) and the remainder
                % is cancelled (DELETEd), follow the same steps as above, but
                % for the cancelled quantity.
                elseif ~isempty(index)
                    % The linked messages have some TRADEs in it but ended up
                    % with DELETE. That means the original order is partially
                    % executed with the remaining quantities being cancelled.
                    % We redo the above procedure, based on the cancelled
                    % quantity.
                    idx1=find(RecordType(:,1)==3); % find AMENDs
                    idx2=find(RecordType(:,1)==1); % find ENTER
                    % 1. There are NO AMENDs in the linked messages, so the
                    % cancelled quantity is the difference between the ENTER
                    % and the sum of all TRADEs.
                    if (RecordType(end)==2 && isempty(idx1))
                        V=[];
                        for a=1:length(index)
                          v=Vol(index(a));
                          V=[V;v];
                        end
                        % Next we calculate the cancelled quantity.
                        CancelVol=Vol(idx2)-sum(V);
                        dir=Dir(idx2);
                    % 2. There are order AMENDs in the linked messages, the
                    % cancelled quantity depends on the order of messages.
                    elseif (RecordType(end)==2 && ~isempty(idx1))
                        % 2.1. If the last message before DELETE in the end is
                        % AMEND, then the cancelled quantity is the last AMEND
                        % quantity.
                        if RecordType(end-1)==3
                            idx3=idx1(end);
                            CancelVol=Vol(idx3);
                            dir=Dir(idx3);
                        % 2.2. If the last message before DELETE in the end is
                        % TRADE, and the immediate message before that TRADE is
                        % AMEND, then the cancelled quantity is the difference
                        % between the last AMEND and the last TRADE.
                        elseif RecordType(end-1)==4
                            idx3=idx1(end); % last AMEND
                            if idx3==(length(RecordType)-2)
                                CancelVol=Vol(idx3)-Vol(end-1);
                                dir=Dir(idx3);
                            % If the last message before DELETE in the end is
                            % TRADE, and the immediate message before that
                            % TRADE is NOT AMEND(i.e., is another TRADE), then
                            % the cancelled quantity is the difference between
                            % the last AMEND and all the TRADEs after the last
                            % AMEND.
                            elseif idx3<(length(RecordType)-2)
                                V=[];
                                for a=1:(length(RecordType)-1-idx3)
                                    v=Vol(idx3+a);
                                    V=[V;v];
                                end
                                CancelVol=Vol(idx3)-sum(V);
                                dir=Dir(idx3);
                            end
                        end
                    end
                    % Knowing the cancelled quantity, we next impute the link
                    % following the same procedure.
                    InferredLinkID=D(1,2);
                    InferredLink=LinkBID(1).Linked_Messages;
                    for k=2:length(LinkBID)
                        NextLink=LinkBID(k).Linked_Messages;
                        Start=NextLink(1); % This is the start of the next linked messages
                        ID=find(DATE(:,1)==LinkBID(k).Date);
                        % Do not link messages across days
                        if ID==id
                            % Impute a link according to direction(Bid/Ask),
                            % size(Volume), and timing(time elapsed).
                            if (Type(Start)==1 && Volume(Start)== CancelVol && Direction(Start) == dir && ((time(Start)-time(END))<=100) && ((time(Start)-time(END))>=0))
                                % If the subsequent (k-th) order submission
                                % (ENTER) is of the same size and direction as
                                % the previous partially cancelled quantity and
                                % is within 100 milliseconds, we infer a run.

                                % RECORD THE ID OF IMPUTED LINKS AND REMOVE
                                % THESE FROM THE 'LinkBID' BEFORE IMPUTING THE
                                % NEXT RUN.
                                InferredLinkid=D(k,2);
                                InferredLinkID=[InferredLinkID;InferredLinkid];
                                % THESE ARE THE LINKED MESSAGES
                                InferredLink=[InferredLink;NextLink];
                                disp('linked messages found');
                            elseif (Type(Start)~=1 || Volume(Start)~= CancelVol || ((time(Start)-time(END))>100) || Direction(Start) ~= dir)
                                InferredLinkid=[];
                                InferredLinkID=[InferredLinkID;InferredLinkid];
                                InferredLink=[InferredLink;[]];
                                disp('linked messages not found');
                            end
                        else
                            disp('The next message is from a different day, stop processing !');
                        end
                    end
                    Infer=[Infer;InferredLink];
                    InferID=[InferID;InferredLinkID];
            end
        % For linked messages not ended up with DELETE, we do not impute a
        % indirect link. Instead, just keep the original 'directly linked'
        % messages.
           % THIS MIGHT OCCUR FOR THE FOLLOWING REASONS:
             % 1. The order is entered but not traded or active and expires at
             % the end of the day.

             % 2. The order starts with a TRADE, but qualifiers indicate "CX",
             %    this is a trade in the ASX Centre Point (dark pool) reported
             %    to the CLOB. Since we do not observe submission and
             %    cancellation of non-displayed non-marketable limit orders in
             %    the anonymous crossing networks, there is no clear-cut way to
             %    infer a run.
        elseif Type(END)~=2
            % This means that this particular group of directly linked
            % messages are fully traded or not active, so there is no need
            % to impute any link for them.
            InferredLinkID=D(1,2);
            InferredLink=[InferredLink;LinkBID(1).Linked_Messages];
            Infer=[Infer;InferredLink];
            InferID=[InferID;InferredLinkID];
            disp('The message was not cancelled, so it is either traded or expires at the end of day');
        end
        end
        % There can be some repeated index numbers due to looping, so 
        InferID=unique(InferID);
        Infer=unique(Infer);
        
        str=struct('Date', LinkBID(1).Date, 'LinkedMessages', Infer);
        RunsBid=[RunsBid str];
        
        INDEX=[];
        for p=1:length(InferID)
            Index=find((D(:,1)==LinkBID(1).Date) & (D(:,2)==InferID(p)));
            INDEX=[INDEX;Index];
        end
        LinkBID(INDEX)=[];
        D(INDEX,:)=[];
        m=m+1;
        disp(['Indicate number: ',num2str(m)]);
    end
end
% Now the LinkBID has only one observation, i.e.,the last 'directly linked'
% messages, if we cannot infer the link between the last and the
% second-last observation.

%%
D=zeros(length(LinkASK),2);
for o=1:length(LinkASK)
    Date=LinkASK(o).Date;
    AskID=LinkASK(o).AskID;
    D(o,:)=[Date,AskID];
end
%% Inferring the link. Start the searching process from the first message submitted with Type ENTER
% 2. THEN LOCATE STRATEGIC RUNS ON THE ASK SIDE

RunsAsk=[];
m=0;
while length(LinkASK)>=2
    if LinkASK(1).numlink==1
        InferredLink=[];
        TreatedLink=LinkASK(1).Linked_Messages;
        TreatedLink=sort(TreatedLink);
        END=TreatedLink(end); % This is the end of the previous linked messages
        
        % If the previous linked messages ended up with DELETE (cancellation),
        % the we follow Hasbrouck & Saar (2013) to impute a link by DIRECTION,
        % SIZE, and TIMING.
        id=find(DATE(:,1)==LinkASK(1).Date);
        Type=DATA(id).Type;
        Volume=DATA(id).VOLUME;
        time=DATA(id).MILLISECONDS;
        Direction=DATA(id).Direction;
        % Only impute a link if the previous linked messages ended up with
        % DELETE.
        if Type(END)==2
            % If the previous linked messages ended up with DELETE, then the
            % end of the previous messages reports a NaN in the column VOLUME,
            % find the valid Volume for this particular linked message series.
            Vol=Volume(TreatedLink);
            % From Vol we infer the valid volume in order to impute the link
            Dir=Direction(TreatedLink);
            % First check there are no TRADEs within the linked messages.
            RecordType=Type(TreatedLink);
            index=find(RecordType(:,1)==4); % recall that 4 represents TRADE
            if isempty(index) && length(unique(RecordType))>1
                % Find the last non-NaN Volume as the valid share size for this
                % particular link.
                idx1=find(RecordType(:,1)==3); % find AMENDs
                idx2=find(RecordType(:,1)==1); % find ENTER
                if isempty(idx1)
                    % In this case, the treated link have NOT experienced order
                    % AMENDs, nor are they TRADEd. But they ended up with being
                    % DELETEd, so the valid volume to impute a link is the
                    % volume from the first ENTER.
                    size=Vol(idx2);
                    dir=Dir(idx2);
                elseif ~isempty(idx1)
                    % In this case, the series of linked messages have
                    % experienced some order AMENDs, but are not TRADEd. They
                    % also ended up being DELETEd, so the valid volome is the
                    % volume from the last AMEND.
                    idx3=idx1(end);
                    size=Vol(idx3);
                    dir=Dir(idx3);
                end
                InferredLinkID=D(1,2);
                InferredLink=TreatedLink;
                for k=2:length(LinkASK)
                    NextLink=LinkASK(k).Linked_Messages;
                    Start=NextLink(1); % This is the start of the next linked messages
                    ID=find(DATE(:,1)==LinkASK(k).Date);
                    % Do not link messages across days
                    if ID==id
                        % Impute a link according to direction(Bid/Ask), size(Volume), and timing (time elapsed)
                        if (Type(Start)==1 && Volume(Start)== size && Direction(Start) == dir && ((time(Start)-time(END))<=100) && ((time(Start)-time(END))>=0))
                            % If the subsequent (k-th) order submission (ENTER)
                            % is of the same size and direction as the previous
                            % cancelled (DELETE) link and is within 100
                            % milliseconds, we infer a linked strategic run.
                            
                            % RECORD THE ID OF IMPUTED LINKS AND REMOVE THESE
                            % FROM THE 'LinkASK' BEFORE IMPUTING THE NEXT RUN.
                            InferredLinkid=D(k,2);
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            % THESE ARE THE LINKED MESSAGES
                            InferredLink=[InferredLink;NextLink];
                            disp('linked messages found');
                        elseif (Type(Start)~=1 || Volume(Start)~= size || ((time(Start)-time(END))>100) || Direction(Start) ~= dir)
                            InferredLinkid=[];
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            InferredLink=[InferredLink;[]];
                            disp('linked messages not found');
                        end
                    else
                        disp('The next message is from a different day, stop processing !');
                    end
                end
                str=struct('Date', LinkASK(1).Date, 'LinkedMessages', InferredLink);
                RunsAsk=[RunsAsk str];
                % If part of the order is executed (TRADEd) and the remainder
                % is cancelled (DELETEd), follow the same steps as above, but
                % for the cancelled quantity.
            elseif ~isempty(index)
                % The linked messages have some TRADEs in it but ended up
                % with DELETE. That means the original order is partially
                % executed with the remaining quantities being cancelled.
                % We redo the above procedure, based on the cancelled
                % quantity.
                idx1=find(RecordType(:,1)==3); % find AMENDs
                idx2=find(RecordType(:,1)==1); % find ENTER
                % 1. There are NO AMENDs in the linked messages, so the
                % cancelled quantity is the difference between the ENTER
                % and the sum of all TRADEs.
                if (RecordType(end)==2 && isempty(idx1))
                    V=[];
                    for a=1:length(index)
                        v=Vol(index(a));
                        V=[V;v];
                    end
                    % Next we calculate the cancelled quantity.
                    CancelVol=Vol(idx2)-sum(V);
                    dir=Dir(idx2);
                    % 2. There are order AMENDs in the linked messages, the
                    % cancelled quantity depends on the order of messages.
                elseif (RecordType(end)==2 && ~isempty(idx1))
                    % 2.1. If the last message before DELETE in the end is
                    % AMEND, then the cancelled quantity is the last AMEND
                    % quantity.
                    if RecordType(end-1)==3
                        idx3=idx1(end);
                        CancelVol=Vol(idx3);
                        dir=Dir(idx3);
                        % 2.2. If the last message before DELETE in the end is
                        % TRADE, and the immediate message before that TRADE is
                        % AMEND, then the cancelled quantity is the difference
                        % between the last AMEND and the last TRADE.
                    elseif RecordType(end-1)==4
                        idx3=idx1(end); % last AMEND
                        if idx3==(length(RecordType)-2)
                            CancelVol=Vol(idx3)-Vol(end-1);
                            dir=Dir(idx3);
                            % If the last message before DELETE in the end is
                            % TRADE, and the immediate message before that
                            % TRADE is NOT AMEND(i.e., is another TRADE), then
                            % the cancelled quantity is the difference between
                            % the last AMEND and all the TRADEs after the last
                            % AMEND.
                        elseif idx3<(length(RecordType)-2)
                            V=[];
                            for a=1:(length(RecordType)-1-idx3)
                                v=Vol(idx3+a);
                                V=[V;v];
                            end
                            CancelVol=Vol(idx3)-sum(V);
                            dir=Dir(idx3);
                        end
                    end
                end
                % Knowing the cancelled quantity, we next impute the link
                % following the same procedure.
                InferredLinkID=D(1,2);
                InferredLink=TreatedLink;
                for k=2:length(LinkASK)
                    NextLink=LinkASK(k).Linked_Messages;
                    Start=NextLink(1); % This is the start of the next linked messages
                    ID=find(DATE(:,1)==LinkASK(k).Date);
                    % Do not link messages across days
                    if ID==id
                        % Impute a link according to direction(Bid/Ask),
                        % size(Volume), and timing(time elapsed).
                        if (Type(Start)==1 && Volume(Start)== CancelVol && Direction(Start) == dir && ((time(Start)-time(END))<=100) && ((time(Start)-time(END))>=0))
                            % If the subsequent (k-th) order submission
                            % (ENTER) is of the same size and direction as
                            % the previous partially cancelled quantity and
                            % is within 100 milliseconds, we infer a run.
                            
                            % RECORD THE ID OF IMPUTED LINKS AND REMOVE
                            % THESE FROM THE 'LinkASK' BEFORE IMPUTING THE
                            % NEXT RUN.
                            InferredLinkid=D(k,2);
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            % THESE ARE THE LINKED MESSAGES
                            InferredLink=[InferredLink;NextLink];
                            disp('linked messages found');
                        elseif (Type(Start)~=1 || Volume(Start)~= CancelVol || ((time(Start)-time(END))>100) || Direction(Start) ~= dir)
                            InferredLinkid=[];
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            InferredLink=[InferredLink;[]];
                            disp('linked messages not found');
                        end
                    else
                        disp('The next message is from a different day, stop processing !');
                    end
                end
                str=struct('Date', LinkASK(1).Date, 'LinkedMessages', InferredLink);
                RunsAsk=[RunsAsk str];
            elseif length(unique(RecordType))==1
                InferredLinkID=D(1,2);
                InferredLink=[InferredLink;TreatedLink];
                str=struct('Date', LinkASK(1).Date, 'LinkedMessages', InferredLink);
                RunsAsk=[RunsAsk str];
                disp('The message was dodgy and possibly due to data errors, ignore it !');
            end
            % For linked messages not ended up with DELETE, we do not impute a
            % indirect link. Instead, just keep the original 'directly linked'
            % messages.
            % THIS MIGHT OCCUR FOR THE FOLLOWING REASONS:
            % 1. The order is entered but not traded or active and expires at
            % the end of the day.
            
            % 2. The order starts with a TRADE, but qualifiers indicate "CX",
            %    this is a trade in the ASX Centre Point (dark pool) reported
            %    to the CLOB. Since we do not observe submission and
            %    cancellation of non-displayed non-marketable limit orders in
            %    the anonymous crossing networks, there is no clear-cut way to
            %    infer a run.
        elseif Type(END)~=2
            InferredLinkID=D(1,2);
            InferredLink=[InferredLink;TreatedLink];
            str=struct('Date', LinkASK(1).Date, 'LinkedMessages', InferredLink);
            RunsAsk=[RunsAsk str];
            disp('The message was not cancelled, so it is either traded or expires at the end of day');
        end
        % Remove tagged messages so that they are not reused in the next run.
        INDEX=[];
        for p=1:length(InferredLinkID)
            Index=find((D(:,1)==LinkASK(1).Date) & (D(:,2)==InferredLinkID(p)));
            INDEX=[INDEX;Index];
        end
        LinkASK(INDEX)=[];
        D(INDEX,:)=[];
        m=m+1;
        disp(['Indicate number: ',num2str(m)]);
    elseif LinkASK(1).numlink>=2
        % As this is the second stage run, so the function inputs LinkBID & LinkASK
        % may contain multiple groups of directly linked messages. For
        % instance, one row of Linked_Messages can be:
        % [1;2;6;8;13;14], where [1;2], [6;8], and [13;14] are three separate
        % groups of messages that are directly linked through unique BID/ASKIDs
        % and they are further inferred to be part of the same strategic run as
        % per Hasbrouck & Saar (2013).
        
        % The point of the second stage run is to capture the inferred
        % links that are unable to be detected in the initial stage since
        % in the initial stage many rows of directly linked messages are
        % deleted in each loop.
        
        % If one particular row of Linked_Messages has more than 1 group of
        % directly linked messages (via BidID/AskID), then these groups of
        % messages are inferred to be part of the same strategic run. In
        % other words, group number 2 to the end (e.g., [6;8], and
        % [13;14]) are removed and there might be some missing links as a
        % result.
        
        % We reiterate the first stage strategic run procedure for all such
        % groups of messages that are removed in the initial stage.
        Infer=[];
        InferID=[];
        for s=2:LinkASK(1).numlink
            InferredLink=[];
            TreatedLink=LinkASK(1).Linked_Messages;
            TreatedLink=sort(TreatedLink);
            askid=DATA(1).ASK_ID;
            askid=askid(TreatedLink);
            ASK=unique(askid);
            idx= askid(:,1)==ASK(s);
            TreatedLink=TreatedLink(idx);
            END=TreatedLink(end); % This is the end of the s-th directly linked messages
        % If the previous linked messages ended up with DELETE (cancellation),
        % then we follow Hasbrouck & Saar (2013) to impute a link by DIRECTION,
        % SIZE, and TIMING.
            id=find(DATE(:,1)==LinkASK(1).Date);
            Type=DATA(id).Type;
            Volume=DATA(id).VOLUME;
            time=DATA(id).MILLISECONDS;
            Direction=DATA(id).Direction;
        % Only impute a link if the previous linked messages ended up with
        % DELETE.
        if Type(END)==2
            % If the previous linked messages ended up with DELETE, then the
            % end of the previous messages reports a NaN in the field VOLUME,
            % find the valid Volume for this particular linked message series.
            Vol=Volume(TreatedLink);
            % From Vol we infer the valid volume in order to impute the link
            Dir=Direction(TreatedLink);
            % First check there are no TRADEs within the linked messages.
            RecordType=Type(TreatedLink);
            index=find(RecordType(:,1)==4); % recall that 4 represents TRADE
            if isempty(index)
                % Find the non-NaN Volume as the valid share size for this
                % particular link.
                idx1=find(RecordType(:,1)==3); % find AMENDs
                idx2=find(RecordType(:,1)==1); % find ENTER
                if isempty(idx1)
                    % In this case, the treated link have NOT experienced order
                    % AMENDs, nor are they TRADEd. But they ended up with being
                    % DELETEd, so the valid volume to impute a link is the
                    % volume from the first ENTER.
                    size=Vol(idx2);
                    dir=Dir(idx2);
                elseif ~isempty(idx1)
                    % In this case, the series of linked messages have
                    % experienced some order AMENDs, but are not TRADEd. They
                    % also ended up being DELETEd, so the valid volome is the
                    % volume from the last AMEND.
                    idx3=idx1(end);
                    size=Vol(idx3);
                    dir=Dir(idx3);
                end
                InferredLinkID=D(1,2);
                InferredLink=LinkASK(1).Linked_Messages;
                for k=2:length(LinkASK)
                    NextLink=LinkASK(k).Linked_Messages;
                    Start=NextLink(1); % This is the start of the next linked messages
                    ID=find(DATE(:,1)==LinkASK(k).Date);
                    % Do not link messages across days
                    if ID==id
                        % Impute a link according to direction(Bid/Ask), size(Volume), and timing (time elapsed)
                        if (Type(Start)==1 && Volume(Start)== size && Direction(Start) == dir && ((time(Start)-time(END))<=100) && ((time(Start)-time(END))>=0))
                            % If the subsequent (k-th) order submission (ENTER)
                            % is of the same size and direction as the previous
                            % cancelled (DELETE) link and is within 100
                            % milliseconds, we infer a linked strategic run.

                            % RECORD THE ID OF IMPUTED LINKS AND REMOVE THESE
                            % FROM THE 'LinkBID' BEFORE IMPUTING THE NEXT RUN.
                            InferredLinkid=D(k,2);
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            % THESE ARE THE LINKED MESSAGES
                            InferredLink=[InferredLink;NextLink];
                            disp('linked messages found');
                        elseif (Type(Start)~=1 || Volume(Start)~= size || ((time(Start)-time(END))>100) || Direction(Start) ~= dir)
                            InferredLinkid=[];
                            InferredLinkID=[InferredLinkID;InferredLinkid];
                            InferredLink=[InferredLink;[]];
                            disp('linked messages not found');
                        end
                    else
                        disp('The next message is from a different day, stop processing !');
                    end
                end
                Infer=[Infer;InferredLink];
                InferID=[InferID;InferredLinkID];
                % If part of the order is executed (TRADEd) and the remainder
                % is cancelled (DELETEd), follow the same steps as above, but
                % for the cancelled quantity.
                elseif ~isempty(index)
                    % The linked messages have some TRADEs in it but ended up
                    % with DELETE. That means the original order is partially
                    % executed with the remaining quantities being cancelled.
                    % We redo the above procedure, based on the cancelled
                    % quantity.
                    idx1=find(RecordType(:,1)==3); % find AMENDs
                    idx2=find(RecordType(:,1)==1); % find ENTER
                    % 1. There are NO AMENDs in the linked messages, so the
                    % cancelled quantity is the difference between the ENTER
                    % and the sum of all TRADEs.
                    if (RecordType(end)==2 && isempty(idx1))
                        V=[];
                        for a=1:length(index)
                          v=Vol(index(a));
                          V=[V;v];
                        end
                        % Next we calculate the cancelled quantity.
                        CancelVol=Vol(idx2)-sum(V);
                        dir=Dir(idx2);
                    % 2. There are order AMENDs in the linked messages, the
                    % cancelled quantity depends on the order of messages.
                    elseif (RecordType(end)==2 && ~isempty(idx1))
                        % 2.1. If the last message before DELETE in the end is
                        % AMEND, then the cancelled quantity is the last AMEND
                        % quantity.
                        if RecordType(end-1)==3
                            idx3=idx1(end);
                            CancelVol=Vol(idx3);
                            dir=Dir(idx3);
                        % 2.2. If the last message before DELETE in the end is
                        % TRADE, and the immediate message before that TRADE is
                        % AMEND, then the cancelled quantity is the difference
                        % between the last AMEND and the last TRADE.
                        elseif RecordType(end-1)==4
                            idx3=idx1(end); % last AMEND
                            if idx3==(length(RecordType)-2)
                                CancelVol=Vol(idx3)-Vol(end-1);
                                dir=Dir(idx3);
                            % If the last message before DELETE in the end is
                            % TRADE, and the immediate message before that
                            % TRADE is NOT AMEND(i.e., is another TRADE), then
                            % the cancelled quantity is the difference between
                            % the last AMEND and all the TRADEs after the last
                            % AMEND.
                            elseif idx3<(length(RecordType)-2)
                                V=[];
                                for a=1:(length(RecordType)-1-idx3)
                                    v=Vol(idx3+a);
                                    V=[V;v];
                                end
                                CancelVol=Vol(idx3)-sum(V);
                                dir=Dir(idx3);
                            end
                        end
                    end
                    % Knowing the cancelled quantity, we next impute the link
                    % following the same procedure.
                    InferredLinkID=D(1,2);
                    InferredLink=LinkASK(1).Linked_Messages;
                    for k=2:length(LinkASK)
                        NextLink=LinkASK(k).Linked_Messages;
                        Start=NextLink(1); % This is the start of the next linked messages
                        ID=find(DATE(:,1)==LinkASK(k).Date);
                        % Do not link messages across days
                        if ID==id
                            % Impute a link according to direction(Bid/Ask),
                            % size(Volume), and timing(time elapsed).
                            if (Type(Start)==1 && Volume(Start)== CancelVol && Direction(Start) == dir && ((time(Start)-time(END))<=100) && ((time(Start)-time(END))>=0))
                                % If the subsequent (k-th) order submission
                                % (ENTER) is of the same size and direction as
                                % the previous partially cancelled quantity and
                                % is within 100 milliseconds, we infer a run.

                                % RECORD THE ID OF IMPUTED LINKS AND REMOVE
                                % THESE FROM THE 'LinkBID' BEFORE IMPUTING THE
                                % NEXT RUN.
                                InferredLinkid=D(k,2);
                                InferredLinkID=[InferredLinkID;InferredLinkid];
                                % THESE ARE THE LINKED MESSAGES
                                InferredLink=[InferredLink;NextLink];
                                disp('linked messages found');
                            elseif (Type(Start)~=1 || Volume(Start)~= CancelVol || ((time(Start)-time(END))>100) || Direction(Start) ~= dir)
                                InferredLinkid=[];
                                InferredLinkID=[InferredLinkID;InferredLinkid];
                                InferredLink=[InferredLink;[]];
                                disp('linked messages not found');
                            end
                        else
                            disp('The next message is from a different day, stop processing !');
                        end
                    end
                    Infer=[Infer;InferredLink];
                    InferID=[InferID;InferredLinkID];
            end
        % For linked messages not ended up with DELETE, we do not impute a
        % indirect link. Instead, just keep the original 'directly linked'
        % messages.
           % THIS MIGHT OCCUR FOR THE FOLLOWING REASONS:
             % 1. The order is entered but not traded or active and expires at
             % the end of the day.

             % 2. The order starts with a TRADE, but qualifiers indicate "CX",
             %    this is a trade in the ASX Centre Point (dark pool) reported
             %    to the CLOB. Since we do not observe submission and
             %    cancellation of non-displayed non-marketable limit orders in
             %    the anonymous crossing networks, there is no clear-cut way to
             %    infer a run.
        elseif Type(END)~=2
            % This means that this particular group of directly linked
            % messages are fully traded or not active, so there is no need
            % to impute any link for them.
            InferredLinkID=D(1,2);
            InferredLink=[InferredLink;LinkASK(1).Linked_Messages];
            Infer=[Infer;InferredLink];
            InferID=[InferID;InferredLinkID];
            disp('The message was not cancelled, so it is either traded or expires at the end of day');
        end
        end
        % There can be some repeated index numbers due to looping, so 
        InferID=unique(InferID);
        Infer=unique(Infer);
        
        str=struct('Date', LinkASK(1).Date, 'LinkedMessages', Infer);
        RunsAsk=[RunsAsk str];
        
        INDEX=[];
        for p=1:length(InferID)
            Index=find((D(:,1)==LinkASK(1).Date) & (D(:,2)==InferID(p)));
            INDEX=[INDEX;Index];
        end
        LinkASK(INDEX)=[];
        D(INDEX,:)=[];
        m=m+1;
        disp(['Indicate number: ',num2str(m)]);
    end
end
% Now the LinkASK has only one observation, i.e.,the last 'directly linked'
% messages, if we cannot infer the link between the last and the
% second-last observation.