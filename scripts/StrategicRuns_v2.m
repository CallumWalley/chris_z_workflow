function [LinkBID, LinkASK, RunsBid, RunsAsk] = StrategicRuns_v2(DATA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% USER NOTE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % 1. THIS CODE IS PROTOTYPED USING THE AUSTRALIAN EQUITIES ORDER BOOK DATA. IN THIS DATASET, THE BidID/AskID TRACKS THE LIFE OF EACH ORDER,
   %    SIMILAR TO THE NASDAQ ITCH DATA WHERE THE REFERENCE NUMBER IS PROVIDED. HOWEVER, THIS CODE IS FLEXIBLE AS LONG AS THE INPUT DATA STRUCTURE 
   %    IS ORGANIZED ACCORDINGLY AND CAN BE EXTENDED TO ANY MARKET.
   %
   % 2. PLEASE CONTACT THE AUTHOR IF YOU SPOT ANY ERRORS OR BUGS WITHIN THIS CODE. ALL FEEDBACKS ARE WELCOMED ! 
   %    Email: chris.hengbin.zhang@aut.ac.nz
   %           zhenghengbin@gmail.com
   %
   % 3. IF YOU RECYCLE OR USE THIS CODE AS PART OF YOUR OWN PROJECT, PLEASE ACKNOWLEDGE THE AUTHOR.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% USER NOTE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inputs:
        % DATA that comes from a dependent scripts for data preparation.
 % Outputs:
        % LinkBID: All messages that are directly linked through a unique BidID.
        % LinkASK: All messages that are directly linked through a unique AskID.
        % RunsBid: Strategic Runs on the Bid side of the limit order book.
        % RunsAsk: Strategic Runs on the Ask side of the limit order book.
        
%% This function computes the Strategic Runs in the Limit Order Book, as per Hasbrouck and Saar (2013):
   %  "Strategic Run" is a proxy to identify the HFTs (Low Latency Quoting) activities, which is a series of order submissions,
   %  cancellations, and executions that are likely to form an algorithmic strategy. The link between submissions, cancellations, 
   %  and executions are constructed based on the following criterion:
   %
   %  (1). Limit orders with their subsequent cancellations or executions are linked unambiguously by BidID/AskID (19-digit number) as part of
   %       the data. In other words, an individual limit order is linked with its subsequent cancellation or execution via a unique BidID/AskID.
   %
   %  (2). The point of inference comes in deciding whether a cancellation can be linked to either a subsequent order submission of a non-marketable 
   %       limit order or a subsequent execution that occurs when the same order is resent to the market priced to be marketable (a repriced order).
   %
   %
   %  (3). If a limit order is partially executed and the remainder is cancelled, look for a subsequent order resubmission or execution of the cancelled 
   %       quantity while reapplying step (2).
   
   %% This function reconstructs the Hasbrouck & Saar (2013) "Strategic Runs" based on the following steps:
   %
   %  a. Based on the Unique BidID/AskID, filter out for each stock-day all "directly linked" order messages, on both the buy and sell side of the book.
   %
   %  b. For order messages with different ID's. An "inferred linked" order messages are made if:
   %
   %     1. A previous order message series with a different BidID/AskID ended up with DELETE and,
   %
   %     2. A new subsequent limit order resubmission (therefore with different BidID/AskID) occurs within 100 milliseconds, and the
   %        order is of the same size(share volume) and the same direction(bid or ask) as the DELETE order as per 1 or,
   %
   %     3. A new subsequent TRADE message occurs within 100 milliseconds and is of the same size but with opposite direction of the DELETE
   %        order as per 1.
   %
   %  c. If a limit order is partially executed and the remainder is cancelled, reapply step b based on the cancelled quantity.

%% IDENTIFYING THE LOW LATENCY ACTIVITIES

% In the AETH Order Book data, we observe the following messages:
%     ENTER: Entry of a new order into the order book. 
%     DELETE: Deletion of an order from the order book. 
%     AMEND: Modification of existing order. 
%     TRADE: A trade between two orders.

% FOR ORDER MESSAGES THAT ARE 'DIRECTLY LINKED' VIA THE BidID/AskID. WE KNOW THAT THEY ARE A SERIES OF ORDERS WITH THE FOLLOWING SEQUENCE TYPICALLY:
%     ENTER --- AMEND --- ... --- DELETE/TRADE,
% or  ENTER --- DELETE,
% or  ENTER --- TRADE, etc.

% WE KNOW THAT THEY ARE DIRECTLY LINKED THROUGH THE UNIQUE IDENTIFIER (BidID/AskID). IN THE NEXT STEP, WE HAVE TO IMPUTE SUCH A LINK WITH ORDER MESSAGES
% TAGGED WITH DIFFERENT BidID/AskID. DO NOT REUSE MESSAGES WHEN CONSTRUCTING THE RUNS.

% Three key thing are need for such inferences: TIMING, DIRECTION(BID/ASK), VOLUME.
    % Both TIMING and VOLUME are numerical values and is in the dataset already, DIRECTION in the AETH is indicated by a seris of B's or A's.
    % We want to infer if a DELETE can be linked to either a subsequent ENTER of a nomarketable limit order or a subsequent TRADE that occurs when the same
    % order is resent to the market priced to be marketable.

% To help identify different message types, we tranfer each record type to a unique numerical value:
    % if ENTER        then 1;
    % if DELETE       then 2;
    % if AMEND        then 3;
    % if TRADE        then 4;
    % if CANCEL_TRADE then 5;
    % if OFFTR        then 6;
    % if CONTROL      then 7;

% THIS IS DONE IN THE DEPENDENT SCRIPT FILE FOR DATA PREPARATION.

%% a1. FOR EACH STOCK-DAY, FILTER OUT "DIRECTLY LINKED" ORDER MESSAGES BASED ON THE BidID
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
    InferredLink=[];
    TreatedLink=LinkBID(1).Linked_Messages;
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
    InferredLink=[];
    TreatedLink=LinkASK(1).Linked_Messages;
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
end
% Now the LinkASK has only one observation, i.e.,the last 'directly linked'
% messages, if we cannot infer the link between the last and the
% second-last observation.