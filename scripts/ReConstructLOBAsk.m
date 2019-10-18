function [DATA] = ReConstructLOBAsk(file, row)
    inputObject = matfile(file);
    DATA=inputObject.DATA(1,row);
%% Extract linked messages from the Order Book
[LinkBID, LinkASK] = roload(DATA);
clearvars LinkBID;
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
%% Extract all the Ask side messages from the Order Book
LenAsk=[];
for i=1:length(LinkASK)
    LenAsk=[LenAsk;LinkASK(i).Linked_Messages];
end
LenAsk=sort(LenAsk);
%% Infer the correct volume and price corresponding to each message
Price_Volume=[];
for i=1:length(LinkASK)
    PRICE=DATA(1).PRICE;
    VOLUME=DATA(1).VOLUME;
    SEQUENCE=DATA(1).SEQUENCE;
    Type=DATA(1).Type;
    Linked_Messages=LinkASK(i).Linked_Messages;
    PRICE=PRICE(Linked_Messages);
    VOLUME=VOLUME(Linked_Messages);
    SEQUENCE=SEQUENCE(Linked_Messages);
    Type=Type(Linked_Messages);
    id=find(Type(:,1)==1);
    Price=[];
    Volume=[];
    % sometimes there are more than one ENTER in directly linked messages,
    % this is due to data outage where multiple order entries are assigned
    % the same bid/askid. In this case, we need to use SEQUENCE to sort out
    % orders;
    % there is only 1 ENTER or no ENTER (all TRADES)
    if length(id)<=1
        for j=1:length(Linked_Messages)
            % message is ENTER, the valid price and volume is the corresponding
            % price and volume;
            if Type(j)==1
                price=PRICE(j);
                volume=VOLUME(j);
                Price=[Price;price];
                Volume=[Volume;volume];
            % message is DELETE, the valid price and volume is the price and
            % volume immediately before the DELETE;
            elseif Type(j)==2
                price=Price(j-1);
                volume=Volume(j-1);
                Price=[Price;price];
                Volume=[Volume;volume];
            % message is AMEND, the valid price and volume is the corresponding
            % price and volume;
            elseif Type(j)==3
                price=PRICE(j);
                volume=VOLUME(j);
                Price=[Price;price];
                Volume=[Volume;volume];
            % message is TRADE, the valid price is the price immediately before
            % the TRADE and the valid volume is the difference between the
            % prevailing volume and volume that is executed;
            elseif (Type(j)==4 || Type(j)==6)
                % there is a TRADE(OFFTR) record and the TRADE is not the first
                % message;
                if (length(unique(Type))>1)
                    price=Price(j-1);
                    volume=Volume(j-1)-VOLUME(j);
                    Price=[Price;price];
                    Volume=[Volume;volume];
                % there is only one message and is TRADE or multiple messages
                % starting with TRADE;
                elseif (unique(Type)==4 || unique(Type)==6)
                    price=PRICE(j);
                    volume=VOLUME(j);
                    Price=[Price;price];
                    Volume=[Volume;volume];
                end
            end
        end
    % possible data outage due to multiple streams of order flows being
    % assigned the same ids. In this case, we need to use the SEQUENCE in
    % the dataset to sort the data into correct order;
    elseif length(id)>1
% % % %         sequence=unique(SEQUENCE);
% % % %         P=[];
% % % %         V=[];
% % % %         T=[];
% % % %         for m=1:length(sequence)
% % % %             indx=find(SEQUENCE(:,1)==sequence(m));
% % % %             p=PRICE(indx);
% % % %             v=VOLUME(indx);
% % % %             t=Type(indx);
% % % %             P=[P;p];
% % % %             V=[V;v];
% % % %             T=[T;t];
% % % %         end
% % % %         PRICE=P;
% % % %         VOLUME=V;
% % % %         Type=T;
        %%%%%%
        a=unique(Type);
        if ((length(a)==2) && (a(1)==1) && (a(2)==4))
            SEQUENCE=SEQUENCE(id);
            sequence=SEQUENCE;
            P=[];
            V=[];
            T=[];
            for m=1:length(sequence)
                ID=find(SEQUENCE(:,1)==sequence(m));
                v=VOLUME(id(ID));
                IDx=find(VOLUME(:,1)==v);
                if length(IDx)==2
                    if IDx(1)==id(ID)
                        p=PRICE(IDx);
                        v=VOLUME(IDx);
                        t=Type(IDx);
                        P=[P;p];
                        V=[V;v];
                        T=[T;t];
                    elseif IDx(2)==id(ID)
                        p=[PRICE(IDx(2));PRICE(IDx(1))];
                        v=[VOLUME(IDx(2));VOLUME(IDx(1))];
                        t=[Type(IDx(2));Type(IDx(1))];
                        P=[P;p];
                        V=[V;v];
                        T=[T;t];
                    end
                elseif ((length(IDx)>2) && (mod(length(IDx),2)==0))
                    p=[PRICE(id(ID));PRICE(id(ID))];
                    v=[VOLUME(id(ID));VOLUME(id(ID))];
                    t=[1;4];
                    P=[P;p];
                    V=[V;v];
                    T=[T;t];
                elseif length(IDx)<2
                    error(' length in corrupted data is less than 2 !');
                end
            end
            PRICE=P;
            VOLUME=V;
            Type=T;
        elseif length(a)~=2
            error('message contains more than just ENTER and TRADE, error occured !');
        end
        %%%%%%
        for j=1:length(Linked_Messages)
            % message is ENTER, the valid price and volume is the corresponding
            % price and volume;
            if Type(j)==1
                price=PRICE(j);
                volume=VOLUME(j);
                Price=[Price;price];
                Volume=[Volume;volume];
            % message is DELETE, the valid price and volume is the price and
            % volume immediately before the DELETE;
            elseif Type(j)==2
                price=Price(j-1);
                volume=Volume(j-1);
                Price=[Price;price];
                Volume=[Volume;volume];
            % message is AMEND, the valid price and volume is the corresponding
            % price and volume;
            elseif Type(j)==3
                price=PRICE(j);
                volume=VOLUME(j);
                Price=[Price;price];
                Volume=[Volume;volume];
            % message is TRADE, the valid price is the price immediately before
            % the TRADE and the valid volume is the difference between the
            % prevailing volume and volume that is executed;
            elseif (Type(j)==4 || Type(j)==6)
                % there is a TRADE(OFFTR) record and the TRADE is not the first
                % message;
                if (length(unique(Type))>1)
                    price=Price(j-1);
                    volume=Volume(j-1)-VOLUME(j);
                    Price=[Price;price];
                    Volume=[Volume;volume];
                % there is only one message and is TRADE or multiple messages
                % starting with TRADE;
                elseif (unique(Type)==4 || unique(Type)==6)
                    price=PRICE(j);
                    volume=VOLUME(j);
                    Price=[Price;price];
                    Volume=[Volume;volume];
                end
            end
        end
        %%%%%%
    end
    str=struct('Valid_Price', Price, 'Valid_Volume',Volume);
    Price_Volume=[Price_Volume str];
    disp(['Day Completed: ', num2str(i), ' out of ', num2str(length(LinkASK))]);
end
%% merge Price_Volume with LinkASK
for pp=1:length(LinkASK)
    LinkASK(pp).Valid_Price=Price_Volume(pp).Valid_Price;
    LinkASK(pp).Valid_Volume=Price_Volume(pp).Valid_Volume;
end
%% clear redundant variables
clearvars -except DATA LenAsk LinkASK;
%% Double Check
k=1;
M=[];
for i=1:length(LinkASK)
    x=length(LinkASK(i).Linked_Messages);
    y=length(LinkASK(i).Valid_Price);
    z=length(LinkASK(i).Valid_Volume);
    M(k,:)=[x, y, z];
    k=k+1;
end
AVERAGE=[];
for k=1:size(M,1)
    average=mean(M(k,:));
    AVERAGE=[AVERAGE;average];
end
M=[M AVERAGE];
INDEX=find(M(:,1)~=M(:,end)); % INDEX should be an empty set
disp(['Length of INDEX: ', num2str(length(INDEX))]);
%% clear redundant variables
clearvars -except DATA LenAsk LinkASK;
LLORDASK = LenAsk;
clearvars LenAsk;
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
%% clear redundant variables
clearvars -except DATA LLORDASK LinkASK;

%% check all volume is non-negative
L=[]; % L should be an empty set;
for l=1:length(LinkASK)
    Volume=LinkASK(l).Valid_Volume;
    idex=find(Volume(:,1)<0);
    if ~isempty(idex)
        L=[L;l];
    end
end
disp(['Length of L: ', num2str(length(L))]);
%% If there are some errors, L is not an empty set, we remove the corresponding row from the LinkASK.
DELETEMESSAGE=[];
DELETEROW=[];
if ~isempty(L)
    for q=1:length(L)
        DELETEMESSAGE=[DELETEMESSAGE;LinkASK(L(q)).Linked_Messages];
        DELETEROW=[DELETEROW;L(q)];
    end
end
% Now remove the wrong data.
LinkASK(DELETEROW)=[];
INDX=[];
for xx=1:length(DELETEMESSAGE)
    indx=find(LLORDASK(:,1)==DELETEMESSAGE(xx));
    INDX=[INDX;indx];
end
LLORDASK(INDX)=[];
%% 
ORIGINAL_LLORDASK=DATA(1).LLORDASK;
ORIGINAL_nLLORDASK=DATA(1).nLLORDASK;
ORIGINAL_no0B0LLORDASK=DATA(1).no0B0LLORDASK;
ORIGINAL_no0B0nLLORDASK=DATA(1).no0B0nLLORDASK;
INDEX1=[];
for aa=1:length(DELETEMESSAGE)
    index1=find(ORIGINAL_LLORDASK(:,1)==DELETEMESSAGE(aa));
    INDEX1=[INDEX1;index1];
end
ORIGINAL_LLORDASK(INDEX1)=[];
DATA.LLORDASK=ORIGINAL_LLORDASK;
INDEX2=[];
for aa=1:length(DELETEMESSAGE)
    index1=find(ORIGINAL_nLLORDASK(:,1)==DELETEMESSAGE(aa));
    INDEX2=[INDEX2;index1];
end
ORIGINAL_nLLORDASK(INDEX2)=[];
DATA.nLLORDASK=ORIGINAL_nLLORDASK;
INDEX3=[];
for aa=1:length(DELETEMESSAGE)
    index1=find(ORIGINAL_no0B0LLORDASK(:,1)==DELETEMESSAGE(aa));
    INDEX3=[INDEX3;index1];
end
ORIGINAL_no0B0LLORDASK(INDEX3)=[];
DATA.no0B0LLORDASK=ORIGINAL_no0B0LLORDASK;
INDEX4=[];
for aa=1:length(DELETEMESSAGE)
    index1=find(ORIGINAL_no0B0nLLORDASK(:,1)==DELETEMESSAGE(aa));
    INDEX4=[INDEX4;index1];
end
ORIGINAL_no0B0nLLORDASK(INDEX4)=[];
DATA.no0B0nLLORDASK=ORIGINAL_no0B0nLLORDASK;
%% Reconstruct Limit Order Book
LLORDASK=sort(LLORDASK);
noOB0ASK=LLORDASK;
noOB0ASK=sort(noOB0ASK);
%%
TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;
MILLISECONDS=DATA(1).MILLISECONDS;
PRICE=DATA(1).PRICE;
VOLUME=DATA(1).VOLUME;
SEQUENCE=DATA(1).SEQUENCE;
BUYERID=DATA(1).BUYERID;
SELLERID=DATA(1).SELLERID;
ASK_ID=DATA(1).ASK_ID;
Type=DATA(1).Type;
Direction=DATA(1).Direction;
Qualifiers=DATA(1).Qualifiers;
%%
MILLISECONDS=MILLISECONDS(LLORDASK);
PRICE=PRICE(LLORDASK);
VOLUME=VOLUME(LLORDASK);
SEQUENCE=SEQUENCE(LLORDASK);
BUYERID=BUYERID(LLORDASK);
SELLERID=SELLERID(LLORDASK);
ASK_ID=ASK_ID(LLORDASK);
Type=Type(LLORDASK);
Direction=Direction(LLORDASK);
Qualifiers=Qualifiers(LLORDASK);
%% Reconstruct the LOB (ASK SIDE)
Ask = cell2table(cell(0,11), 'VariableNames', {'TICKER', 'DATE', 'Time', 'Ask_L1', 'Ask_Size1', 'Ask_L2', 'Ask_Size2','Ask_L3', 'Ask_Size3','Ask_L4', 'Ask_Size4'});
Ask.TICKER=num2str(Ask.TICKER);
% Each order event will lead to a change in the state of the LOB, update in a choronological order.
for k=1:length(LLORDASK) % # of LOB updates;
    if (k==1 && Type(k)==1) % the first message is almost certainly an ENTER;
        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
        Ask.Time(k)=MILLISECONDS(k);
        Ask.Ask_L1(k)=PRICE(k);Ask.Ask_Size1(k)=VOLUME(k);
    elseif (k>=2)
        % if the next message is also an ENTER, we need to compare the price with existing LOB price levels;
        if Type(k)==1
            % Price of incoming order matches the existing best ask, so the only thing that changes in LOB is the size at best ask;
            if PRICE(k)==Ask.Ask_L1(k-1)
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1)+VOLUME(k);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
            % Price of incoming order is LESS than the current best ask. A more aggressive order occurs and so the LOB price levels
            % and size shifts with this incoming order;
            elseif PRICE(k)<Ask.Ask_L1(k-1) || Ask.Ask_L1(k-1)==0
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=PRICE(k);       Ask.Ask_Size1(k)=VOLUME(k);
                Ask.Ask_L2(k)=Ask.Ask_L1(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L2(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L3(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size3(k-1);
            % Price of incoming order is HIGHER than the current best ask,
            % but LESS than the L2 best ask price. So the LOB from Level2
            % is updated by this incoming order;
            elseif ((PRICE(k)>Ask.Ask_L1(k-1) && PRICE(k)<Ask.Ask_L2(k-1)) || (PRICE(k)>Ask.Ask_L1(k-1) && Ask.Ask_L2(k-1)==0))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=PRICE(k);       Ask.Ask_Size2(k)=VOLUME(k);
                Ask.Ask_L3(k)=Ask.Ask_L2(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L3(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size3(k-1);
            % Price of incoming order matches the existing L2 ask, so the only thing that changes in LOB is the size at L2 ask;
            elseif (PRICE(k)==Ask.Ask_L2(k-1))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1)+VOLUME(k);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
            % Price of incoming order is HIGHER than the L2 ask, but LESS
            % than the L3 best ask price. So the LOB from Level3 is updated;
            elseif ((PRICE(k)>Ask.Ask_L2(k-1) && PRICE(k)<Ask.Ask_L3(k-1)) || (PRICE(k)>Ask.Ask_L2(k-1) && Ask.Ask_L3(k-1)==0))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=PRICE(k);       Ask.Ask_Size3(k)=VOLUME(k);
                Ask.Ask_L4(k)=Ask.Ask_L3(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size3(k-1);
            % Price of incoming order matches the existing L3 ask, so the only thing that changes in LOB is the size at L3 ask;
            elseif (PRICE(k)==Ask.Ask_L3(k-1))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1)+VOLUME(k);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
            % Price of incoming order is HIGHER than the L3 ask, but LESS
            % than the L4 best ask price. So the LOB from Level4 is updated;
            elseif ((PRICE(k)>Ask.Ask_L3(k-1) && PRICE(k)<Ask.Ask_L4(k-1)) || (PRICE(k)>Ask.Ask_L3(k-1) && Ask.Ask_L4(k-1)==0))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=PRICE(k);       Ask.Ask_Size4(k)=VOLUME(k);
            % Price of incoming order matches the existing L4 ask, so the only thing that changes in LOB is the size at L4 ask;
            elseif (PRICE(k)==Ask.Ask_L4(k-1))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1)+VOLUME(k);
            % Price of incoming order is HIGHER than the L4 ask, which is
            % beyond the price levels we are interested in, ignore them.
            elseif ((PRICE(k)>Ask.Ask_L4(k-1)) && (Ask.Ask_L4(k-1)~=0))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                disp('Price is higher than the first 4 Ask price levels, ignore !');
            end
        % if the next message is an DELETE, we need to trace back to the
        % original order to see what is the valid price and volume
        % immediately before that DELETE;
        elseif Type(k)==2
            % we need to trace back to its origin from dataset called
            % "LinkASK" to figure out what the new information (price and
            % volume) we should add to LOB and old information (price and
            % volume) we should remove from the LOB;
            % THIS CAN BE DONE BY TRACKING THE UNIQUE ASK_ID ASSIGNED BY
            % THE MATCHING ENGINE;
            ASKID=[];
            for s=1:length(LinkASK)
                askid=LinkASK(s).AskID;
                ASKID=[ASKID;askid];
            end
            % idx is the index to track the order from the original dataset
            % containing linked messages;
            idx=find(ASKID(:,1)==ASK_ID(k));
            Linked_Messages=LinkASK(idx).Linked_Messages;
            Valid_Price=LinkASK(idx).Valid_Price;
            Valid_Volume=LinkASK(idx).Valid_Volume;
            % next figure out what valid price and volume that particular
            % message corresponds to;
            idx1=find(Linked_Messages(:,1)==LLORDASK(k));
            % below is the price and volume that the DELELE message is
            % intended to remove from the LOB;
            price=Valid_Price(idx1);
            volume=Valid_Volume(idx1);
            % find these price in the prevailing LOB and remove them;
            % COMPARE THE DELETED PRICE WITH THE FIRST FOUR LEVELS OF
            % PRICES;
            % DELETE is happening at the best Ask but the quantity being
            % deleted is less than the prevailing depth, the only thing
            % that changes in the LOB is the depth at best Ask;
            if ((price==Ask.Ask_L1(k-1)) && (volume<Ask.Ask_Size1(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1)-volume;
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
            % DELETE is happening at the best Ask and the quantity being
            % deleted is equal to the prevailing depth, so the LOB price
            % level shifts. L2 ask becomes the L1 ask, and so forth.
            elseif ((price==Ask.Ask_L1(k-1)) && (volume==Ask.Ask_Size1(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L2(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L3(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%               Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                llordask=LLORDASK(1:k-1,1);
                type=Type(1:k-1,1);
                idprice=find(type(:,1)==1);
                % row number of each order ENTER;
                llordask=llordask(idprice);
                ALLENTER=[];
                for z=1:length(LinkASK)
                    enter=LinkASK(z).Linked_Messages(1);
                    ALLENTER=[ALLENTER;enter];
                end
                INDEX=[];
                for s=1:length(llordask)
                    index=find(ALLENTER(:,1)==llordask(s));
                    INDEX=[INDEX;index];
                end
                ALL_PRICE_IN_LOB=[];
                ALL_VOLUM_IN_LOB=[];
                for t=1:length(INDEX)
                    linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                    validprice=LinkASK(INDEX(t)).Valid_Price;
                    validvolume=LinkASK(INDEX(t)).Valid_Volume;
                    % find the prevailing price and volume at the time in which we want to
                    % update the LOB (i.e., before the k-th message in LLORDASK);
                    badid=find(linkedorder(:,1)>=LLORDASK(k));
                    linkedorder(badid)=[];
                    validprice(badid)=[];
                    validvolume(badid)=[];
                    TYpe=DATA(1).Type;
                    TYpe=TYpe(linkedorder);
                    isdelete=find(TYpe(:,1)==2);
                    % ignore if message is deleted;
                    if ~isempty(isdelete)
                        disp('the order is deleted before the k-th message is entered, ignore !');
                    % the message is still in the LOB, figure out the valid price and
                    % volume immediately before the k-th message is entered;
                    elseif isempty(isdelete)
                        % valid price and volume depends on the last order type, this is
                        % already given in the validprice and validvolume. the only
                        % exception is when the last message is a TRADE and the
                        % corresponding validvolume is 0, in which case all the volume has
                        % been executed;
                        if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                            disp('the order is fully executed before the k-th message is entered, ignore !');
                        else
                            ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                            ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                        end
                    end
                end
                % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                % note that there might be repeatitive prices due to multiple orders
                % revising toward the same price, aggregate them;
                all=sort(ALL_PRICE_IN_LOB);
                if Ask.Ask_L3(k)~=0
                    IDprice=find(all(:,1)>Ask.Ask_L3(k));
                    if ~isempty(IDprice)
                        all=all(IDprice(1));
                        ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                        vol=ALL_VOLUM_IN_LOB(ID);
                        vol=sum(vol);
                        Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                    elseif isempty(IDprice)
                        Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                    end
                elseif Ask.Ask_L3(k)==0
                    Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                end
            % DELETE is happening at the L2 Ask but the quantity being
            % deleted is less than the prevailing depth, the only thing
            % that changes in the LOB is the depth at L2 Ask;
            elseif ((price==Ask.Ask_L2(k-1)) && (volume<Ask.Ask_Size2(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1)-volume;
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
            % DELETE is happening at the L2 Ask and the quantity being
            % deleted is equal to the prevailing depth, so the LOB price
            % level shifts from L2 onward. L3 becomes L2 Ask, and so on.
            elseif ((price==Ask.Ask_L2(k-1)) && (volume==Ask.Ask_Size2(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L3(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%               Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                llordask=LLORDASK(1:k-1,1);
                type=Type(1:k-1,1);
                idprice=find(type(:,1)==1);
                % row number of each order ENTER;
                llordask=llordask(idprice);
                ALLENTER=[];
                for z=1:length(LinkASK)
                    enter=LinkASK(z).Linked_Messages(1);
                    ALLENTER=[ALLENTER;enter];
                end
                INDEX=[];
                for s=1:length(llordask)
                    index=find(ALLENTER(:,1)==llordask(s));
                    INDEX=[INDEX;index];
                end
                ALL_PRICE_IN_LOB=[];
                ALL_VOLUM_IN_LOB=[];
                for t=1:length(INDEX)
                    linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                    validprice=LinkASK(INDEX(t)).Valid_Price;
                    validvolume=LinkASK(INDEX(t)).Valid_Volume;
                    % find the prevailing price and volume at the time in which we want to
                    % update the LOB (i.e., before the k-th message in LLORDASK);
                    badid=find(linkedorder(:,1)>=LLORDASK(k));
                    linkedorder(badid)=[];
                    validprice(badid)=[];
                    validvolume(badid)=[];
                    TYpe=DATA(1).Type;
                    TYpe=TYpe(linkedorder);
                    isdelete=find(TYpe(:,1)==2);
                    % ignore if message is deleted;
                    if ~isempty(isdelete)
                        disp('the order is deleted before the k-th message is entered, ignore !');
                    % the message is still in the LOB, figure out the valid price and
                    % volume immediately before the k-th message is entered;
                    elseif isempty(isdelete)
                        % valid price and volume depends on the last order type, this is
                        % already given in the validprice and validvolume. the only
                        % exception is when the last message is a TRADE and the
                        % corresponding validvolume is 0, in which case all the volume has
                        % been executed;
                        if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                            disp('the order is fully executed before the k-th message is entered, ignore !');
                        else
                            ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                            ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                        end
                    end
                end
                % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                % note that there might be repeatitive prices due to multiple orders
                % revising toward the same price, aggregate them;
                all=sort(ALL_PRICE_IN_LOB);
                if Ask.Ask_L3(k)~=0
                    IDprice=find(all(:,1)>Ask.Ask_L3(k));
                    if ~isempty(IDprice)
                        all=all(IDprice(1));
                        ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                        vol=ALL_VOLUM_IN_LOB(ID);
                        vol=sum(vol);
                        Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                    elseif isempty(IDprice)
                        Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                    end
                elseif Ask.Ask_L3(k)==0
                    Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                end
            % DELETE is happening at the L3 Ask but the quantity being
            % deleted is less than the prevailing depth, the only thing
            % that changes in the LOB is the depth at L3 Ask;
            elseif ((price==Ask.Ask_L3(k-1)) && (volume<Ask.Ask_Size3(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1)-volume;
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
            % DELETE is happening at the L3 ASK and the quantity being
            % deleted is equal to the prevailing depth, so the LOB price
            % level shifts from L3 onward, L4 becomes L3 Ask, and so on.
            elseif ((price==Ask.Ask_L3(k-1)) && (volume==Ask.Ask_Size3(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%               Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                llordask=LLORDASK(1:k-1,1);
                type=Type(1:k-1,1);
                idprice=find(type(:,1)==1);
                % row number of each order ENTER;
                llordask=llordask(idprice);
                ALLENTER=[];
                for z=1:length(LinkASK)
                    enter=LinkASK(z).Linked_Messages(1);
                    ALLENTER=[ALLENTER;enter];
                end
                INDEX=[];
                for s=1:length(llordask)
                    index=find(ALLENTER(:,1)==llordask(s));
                    INDEX=[INDEX;index];
                end
                ALL_PRICE_IN_LOB=[];
                ALL_VOLUM_IN_LOB=[];
                for t=1:length(INDEX)
                    linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                    validprice=LinkASK(INDEX(t)).Valid_Price;
                    validvolume=LinkASK(INDEX(t)).Valid_Volume;
                    % find the prevailing price and volume at the time in which we want to
                    % update the LOB (i.e., before the k-th message in LLORDASK);
                    badid=find(linkedorder(:,1)>=LLORDASK(k));
                    linkedorder(badid)=[];
                    validprice(badid)=[];
                    validvolume(badid)=[];
                    TYpe=DATA(1).Type;
                    TYpe=TYpe(linkedorder);
                    isdelete=find(TYpe(:,1)==2);
                    % ignore if message is deleted;
                    if ~isempty(isdelete)
                        disp('the order is deleted before the k-th message is entered, ignore !');
                    % the message is still in the LOB, figure out the valid price and
                    % volume immediately before the k-th message is entered;
                    elseif isempty(isdelete)
                        % valid price and volume depends on the last order type, this is
                        % already given in the validprice and validvolume. the only
                        % exception is when the last message is a TRADE and the
                        % corresponding validvolume is 0, in which case all the volume has
                        % been executed;
                        if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                            disp('the order is fully executed before the k-th message is entered, ignore !');
                        else
                            ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                            ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                        end
                    end
                end
                % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                % note that there might be repeatitive prices due to multiple orders
                % revising toward the same price, aggregate them;
                all=sort(ALL_PRICE_IN_LOB);
                if Ask.Ask_L3(k)~=0
                    IDprice=find(all(:,1)>Ask.Ask_L3(k));
                    if ~isempty(IDprice)
                        all=all(IDprice(1));
                        ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                        vol=ALL_VOLUM_IN_LOB(ID);
                        vol=sum(vol);
                        Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                    elseif isempty(IDprice)
                        Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                    end
                elseif Ask.Ask_L3(k)==0
                    Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                end
            % DELETE is happening at the L4 Ask but the quantity being
            % deleted is less than the prevailing depth, the only thing
            % that changes in the LOB is the depth at L4 Ask; 
            elseif ((price==Ask.Ask_L4(k-1)) && (volume<Ask.Ask_Size4(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1)-volume;
            % DELETE is happening at the L4 ASK and the quantity being
            % deleted is equal to the prevailing depth, so the LOB price
            % level shifts from L4 onward, L5 becomes L4 Ask, and so on.
            elseif ((price==Ask.Ask_L4(k-1)) && (volume==Ask.Ask_Size4(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
%               Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                llordask=LLORDASK(1:k-1,1);
                type=Type(1:k-1,1);
                idprice=find(type(:,1)==1);
                % row number of each order ENTER;
                llordask=llordask(idprice);
                ALLENTER=[];
                for z=1:length(LinkASK)
                    enter=LinkASK(z).Linked_Messages(1);
                    ALLENTER=[ALLENTER;enter];
                end
                INDEX=[];
                for s=1:length(llordask)
                    index=find(ALLENTER(:,1)==llordask(s));
                    INDEX=[INDEX;index];
                end
                ALL_PRICE_IN_LOB=[];
                ALL_VOLUM_IN_LOB=[];
                for t=1:length(INDEX)
                    linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                    validprice=LinkASK(INDEX(t)).Valid_Price;
                    validvolume=LinkASK(INDEX(t)).Valid_Volume;
                    % find the prevailing price and volume at the time in which we want to
                    % update the LOB (i.e., before the k-th message in LLORDASK);
                    badid=find(linkedorder(:,1)>=LLORDASK(k));
                    linkedorder(badid)=[];
                    validprice(badid)=[];
                    validvolume(badid)=[];
                    TYpe=DATA(1).Type;
                    TYpe=TYpe(linkedorder);
                    isdelete=find(TYpe(:,1)==2);
                    % ignore if message is deleted;
                    if ~isempty(isdelete)
                        disp('the order is deleted before the k-th message is entered, ignore !');
                    % the message is still in the LOB, figure out the valid price and
                    % volume immediately before the k-th message is entered;
                    elseif isempty(isdelete)
                        % valid price and volume depends on the last order type, this is
                        % already given in the validprice and validvolume. the only
                        % exception is when the last message is a TRADE and the
                        % corresponding validvolume is 0, in which case all the volume has
                        % been executed;
                        if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                            disp('the order is fully executed before the k-th message is entered, ignore !');
                        else
                            ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                            ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                        end
                    end
                end
                % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                % note that there might be repeatitive prices due to multiple orders
                % revising toward the same price, aggregate them;
                all=sort(ALL_PRICE_IN_LOB);
                if Ask.Ask_L4(k-1)~=0
                    IDprice=find(all(:,1)>Ask.Ask_L4(k-1));
                    if ~isempty(IDprice)
                        all=all(IDprice(1));
                        ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                        vol=ALL_VOLUM_IN_LOB(ID);
                        vol=sum(vol);
                        Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                    elseif isempty(IDprice)
                        Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                    end
                elseif Ask.Ask_L4(k-1)==0
                    Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                end
            elseif ((price>Ask.Ask_L4(k-1)) && (Ask.Ask_L4(k-1)~=0))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                disp('Price is higher than the first 4 Ask price levels, ignore !');
            end
        % if the next message is an AMEND, we need to trace back to the
        % original order to see what old price and volume immediately
        % before that AMEND we need to remove and what new price and volume
        % we need to add to the LOB;
        elseif Type(k)==3
            % we need to trace back to its origin from dataset called
            % "LinkASK" to figure out what the new information (price and
            % volume) we should add to LOB and old information (price and
            % volume) we should remove from the LOB;
            % THIS CAN BE DONE BY TRACKING THE UNIQUE ASK_ID ASSIGNED BY
            % THE MATCHING ENGINE;
            ASKID=[];
            for s=1:length(LinkASK)
                askid=LinkASK(s).AskID;
                ASKID=[ASKID;askid];
            end
            % idx is the index to track the order from the original dataset
            % containing linked messages;
            idx=find(ASKID(:,1)==ASK_ID(k));
            Linked_Messages=LinkASK(idx).Linked_Messages;
            Valid_Price=LinkASK(idx).Valid_Price;
            Valid_Volume=LinkASK(idx).Valid_Volume;
            % next figure out what valid price and volume that particular
            % message corresponds to;
            idx1=find(Linked_Messages(:,1)==LLORDASK(k));
            % below is the new price and volume that the AMEND message is
            % intended to add to the LOB;
            newprice=Valid_Price(idx1);
            newvolume=Valid_Volume(idx1);
            % below is the old price and volume that the AMEND message is
            % intended to modify, therefore needs to be removed from LOB;
            oldprice=Valid_Price(idx1-1);
            oldvolume=Valid_Volume(idx1-1);
            % First remove the oldprice and oldvolume from the prevailing
            % LOB before new informaiton is added in;
            if ((oldprice==Ask.Ask_L1(k-1)) && (oldvolume<Ask.Ask_Size1(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1)-oldvolume;
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            elseif ((oldprice==Ask.Ask_L1(k-1)) && (oldvolume==Ask.Ask_Size1(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L2(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L3(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%               Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                llordask=LLORDASK(1:k-1,1);
                type=Type(1:k-1,1);
                idprice=find(type(:,1)==1);
                % row number of each order ENTER;
                llordask=llordask(idprice);
                ALLENTER=[];
                for z=1:length(LinkASK)
                    enter=LinkASK(z).Linked_Messages(1);
                    ALLENTER=[ALLENTER;enter];
                end
                INDEX=[];
                for s=1:length(llordask)
                    index=find(ALLENTER(:,1)==llordask(s));
                    INDEX=[INDEX;index];
                end
                ALL_PRICE_IN_LOB=[];
                ALL_VOLUM_IN_LOB=[];
                for t=1:length(INDEX)
                    linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                    validprice=LinkASK(INDEX(t)).Valid_Price;
                    validvolume=LinkASK(INDEX(t)).Valid_Volume;
                    % find the prevailing price and volume at the time in which we want to
                    % update the LOB (i.e., before the k-th message in LLORDASK);
                    badid=find(linkedorder(:,1)>=LLORDASK(k));
                    linkedorder(badid)=[];
                    validprice(badid)=[];
                    validvolume(badid)=[];
                    TYpe=DATA(1).Type;
                    TYpe=TYpe(linkedorder);
                    isdelete=find(TYpe(:,1)==2);
                    % ignore if message is deleted;
                    if ~isempty(isdelete)
                        disp('the order is deleted before the k-th message is entered, ignore !');
                    % the message is still in the LOB, figure out the valid price and
                    % volume immediately before the k-th message is entered;
                    elseif isempty(isdelete)
                        % valid price and volume depends on the last order type, this is
                        % already given in the validprice and validvolume. the only
                        % exception is when the last message is a TRADE and the
                        % corresponding validvolume is 0, in which case all the volume has
                        % been executed;
                        if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                            disp('the order is fully executed before the k-th message is entered, ignore !');
                        else
                            ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                            ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                        end
                    end
                end
                % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                % note that there might be repeatitive prices due to multiple orders
                % revising toward the same price, aggregate them;
                all=sort(ALL_PRICE_IN_LOB);
                if Ask.Ask_L3(k)~=0
                    IDprice=find(all(:,1)>Ask.Ask_L3(k));
                    if ~isempty(IDprice)
                        all=all(IDprice(1));
                        ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                        vol=ALL_VOLUM_IN_LOB(ID);
                        vol=sum(vol);
                        Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                    elseif isempty(IDprice)
                        Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                    end
                elseif Ask.Ask_L3(k)==0
                    Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                end
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            elseif ((oldprice==Ask.Ask_L2(k-1)) && (oldvolume<Ask.Ask_Size2(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1)-oldvolume;
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            elseif ((oldprice==Ask.Ask_L2(k-1)) && (oldvolume==Ask.Ask_Size2(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L3(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%               Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                llordask=LLORDASK(1:k-1,1);
                type=Type(1:k-1,1);
                idprice=find(type(:,1)==1);
                % row number of each order ENTER;
                llordask=llordask(idprice);
                ALLENTER=[];
                for z=1:length(LinkASK)
                    enter=LinkASK(z).Linked_Messages(1);
                    ALLENTER=[ALLENTER;enter];
                end
                INDEX=[];
                for s=1:length(llordask)
                    index=find(ALLENTER(:,1)==llordask(s));
                    INDEX=[INDEX;index];
                end
                ALL_PRICE_IN_LOB=[];
                ALL_VOLUM_IN_LOB=[];
                for t=1:length(INDEX)
                    linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                    validprice=LinkASK(INDEX(t)).Valid_Price;
                    validvolume=LinkASK(INDEX(t)).Valid_Volume;
                    % find the prevailing price and volume at the time in which we want to
                    % update the LOB (i.e., before the k-th message in LLORDASK);
                    badid=find(linkedorder(:,1)>=LLORDASK(k));
                    linkedorder(badid)=[];
                    validprice(badid)=[];
                    validvolume(badid)=[];
                    TYpe=DATA(1).Type;
                    TYpe=TYpe(linkedorder);
                    isdelete=find(TYpe(:,1)==2);
                    % ignore if message is deleted;
                    if ~isempty(isdelete)
                        disp('the order is deleted before the k-th message is entered, ignore !');
                    % the message is still in the LOB, figure out the valid price and
                    % volume immediately before the k-th message is entered;
                    elseif isempty(isdelete)
                        % valid price and volume depends on the last order type, this is
                        % already given in the validprice and validvolume. the only
                        % exception is when the last message is a TRADE and the
                        % corresponding validvolume is 0, in which case all the volume has
                        % been executed;
                        if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                            disp('the order is fully executed before the k-th message is entered, ignore !');
                        else
                            ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                            ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                        end
                    end
                end
                % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                % note that there might be repeatitive prices due to multiple orders
                % revising toward the same price, aggregate them;
                all=sort(ALL_PRICE_IN_LOB);
                if Ask.Ask_L3(k)~=0
                    IDprice=find(all(:,1)>Ask.Ask_L3(k));
                    if ~isempty(IDprice)
                        all=all(IDprice(1));
                        ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                        vol=ALL_VOLUM_IN_LOB(ID);
                        vol=sum(vol);
                        Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                    elseif isempty(IDprice)
                        Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                    end
                elseif Ask.Ask_L3(k)==0
                    Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                end
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            elseif ((oldprice==Ask.Ask_L3(k-1)) && (oldvolume<Ask.Ask_Size3(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1)-oldvolume;
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            elseif ((oldprice==Ask.Ask_L3(k-1)) && (oldvolume==Ask.Ask_Size3(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%               Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                llordask=LLORDASK(1:k-1,1);
                type=Type(1:k-1,1);
                idprice=find(type(:,1)==1);
                % row number of each order ENTER;
                llordask=llordask(idprice);
                ALLENTER=[];
                for z=1:length(LinkASK)
                    enter=LinkASK(z).Linked_Messages(1);
                    ALLENTER=[ALLENTER;enter];
                end
                INDEX=[];
                for s=1:length(llordask)
                    index=find(ALLENTER(:,1)==llordask(s));
                    INDEX=[INDEX;index];
                end
                ALL_PRICE_IN_LOB=[];
                ALL_VOLUM_IN_LOB=[];
                for t=1:length(INDEX)
                    linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                    validprice=LinkASK(INDEX(t)).Valid_Price;
                    validvolume=LinkASK(INDEX(t)).Valid_Volume;
                    % find the prevailing price and volume at the time in which we want to
                    % update the LOB (i.e., before the k-th message in LLORDASK);
                    badid=find(linkedorder(:,1)>=LLORDASK(k));
                    linkedorder(badid)=[];
                    validprice(badid)=[];
                    validvolume(badid)=[];
                    TYpe=DATA(1).Type;
                    TYpe=TYpe(linkedorder);
                    isdelete=find(TYpe(:,1)==2);
                    % ignore if message is deleted;
                    if ~isempty(isdelete)
                        disp('the order is deleted before the k-th message is entered, ignore !');
                    % the message is still in the LOB, figure out the valid price and
                    % volume immediately before the k-th message is entered;
                    elseif isempty(isdelete)
                        % valid price and volume depends on the last order type, this is
                        % already given in the validprice and validvolume. the only
                        % exception is when the last message is a TRADE and the
                        % corresponding validvolume is 0, in which case all the volume has
                        % been executed;
                        if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                            disp('the order is fully executed before the k-th message is entered, ignore !');
                        else
                            ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                            ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                        end
                    end
                end
                % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                % note that there might be repeatitive prices due to multiple orders
                % revising toward the same price, aggregate them;
                all=sort(ALL_PRICE_IN_LOB);
                if Ask.Ask_L3(k)~=0
                    IDprice=find(all(:,1)>Ask.Ask_L3(k));
                    if ~isempty(IDprice)
                        all=all(IDprice(1));
                        ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                        vol=ALL_VOLUM_IN_LOB(ID);
                        vol=sum(vol);
                        Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                    elseif isempty(IDprice)
                        Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                    end
                elseif Ask.Ask_L3(k)==0
                    Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                end
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            elseif ((oldprice==Ask.Ask_L4(k-1)) && (oldvolume<Ask.Ask_Size4(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1)-oldvolume;
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            elseif ((oldprice==Ask.Ask_L4(k-1)) && (oldvolume==Ask.Ask_Size4(k-1)))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
%               Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                llordask=LLORDASK(1:k-1,1);
                type=Type(1:k-1,1);
                idprice=find(type(:,1)==1);
                % row number of each order ENTER;
                llordask=llordask(idprice);
                ALLENTER=[];
                for z=1:length(LinkASK)
                    enter=LinkASK(z).Linked_Messages(1);
                    ALLENTER=[ALLENTER;enter];
                end
                INDEX=[];
                for s=1:length(llordask)
                    index=find(ALLENTER(:,1)==llordask(s));
                    INDEX=[INDEX;index];
                end
                ALL_PRICE_IN_LOB=[];
                ALL_VOLUM_IN_LOB=[];
                for t=1:length(INDEX)
                    linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                    validprice=LinkASK(INDEX(t)).Valid_Price;
                    validvolume=LinkASK(INDEX(t)).Valid_Volume;
                    % find the prevailing price and volume at the time in which we want to
                    % update the LOB (i.e., before the k-th message in LLORDASK);
                    badid=find(linkedorder(:,1)>=LLORDASK(k));
                    linkedorder(badid)=[];
                    validprice(badid)=[];
                    validvolume(badid)=[];
                    TYpe=DATA(1).Type;
                    TYpe=TYpe(linkedorder);
                    isdelete=find(TYpe(:,1)==2);
                    % ignore if message is deleted;
                    if ~isempty(isdelete)
                        disp('the order is deleted before the k-th message is entered, ignore !');
                    % the message is still in the LOB, figure out the valid price and
                    % volume immediately before the k-th message is entered;
                    elseif isempty(isdelete)
                        % valid price and volume depends on the last order type, this is
                        % already given in the validprice and validvolume. the only
                        % exception is when the last message is a TRADE and the
                        % corresponding validvolume is 0, in which case all the volume has
                        % been executed;
                        if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                            disp('the order is fully executed before the k-th message is entered, ignore !');
                        else
                            ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                            ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                        end
                    end
                end
                % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                % note that there might be repeatitive prices due to multiple orders
                % revising toward the same price, aggregate them;
                all=sort(ALL_PRICE_IN_LOB);
                if Ask.Ask_L4(k-1)~=0
                    IDprice=find(all(:,1)>Ask.Ask_L4(k-1));
                    if ~isempty(IDprice)
                        all=all(IDprice(1));
                        ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                        vol=ALL_VOLUM_IN_LOB(ID);
                        vol=sum(vol);
                        Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                    elseif isempty(IDprice)
                        Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                    end
                elseif Ask.Ask_L4(k-1)==0
                    Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                end
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            elseif ((oldprice>Ask.Ask_L4(k-1)) && (Ask.Ask_L4(k-1)~=0))
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                % now add new price and volume into LOB;
                if newprice==Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k)+newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif newprice<Ask.Ask_L1(k)
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=newprice;     Ask.Ask_Size1(k+1)=newvolume;
                    Ask.Ask_L2(k+1)=Ask.Ask_L1(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L1(k) && newprice<Ask.Ask_L2(k)) || (newprice>Ask.Ask_L1(k) && Ask.Ask_L2(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=newprice;     Ask.Ask_Size2(k+1)=newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L2(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L2(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k)+newvolume;
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L2(k) && newprice<Ask.Ask_L3(k)) || (newprice>Ask.Ask_L2(k) && Ask.Ask_L3(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=newprice;     Ask.Ask_Size3(k+1)=newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L3(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size3(k);
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L3(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k)+newvolume;
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L3(k) && newprice<Ask.Ask_L4(k)) || (newprice>Ask.Ask_L3(k) && Ask.Ask_L4(k)==0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=newprice;     Ask.Ask_Size4(k+1)=newvolume;
                    Ask(k,:)=[];
                elseif (newprice==Ask.Ask_L4(k))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k)+newvolume;
                    Ask(k,:)=[];
                elseif ((newprice>Ask.Ask_L4(k)) && (Ask.Ask_L4(k)~=0))
                    Ask.TICKER(k+1,1:3)=TICKER;Ask.DATE(k+1)=DATE;
                    Ask.Time(k+1)=MILLISECONDS(k);
                    Ask.Ask_L1(k+1)=Ask.Ask_L1(k);Ask.Ask_Size1(k+1)=Ask.Ask_Size1(k);
                    Ask.Ask_L2(k+1)=Ask.Ask_L2(k);Ask.Ask_Size2(k+1)=Ask.Ask_Size2(k);
                    Ask.Ask_L3(k+1)=Ask.Ask_L3(k);Ask.Ask_Size3(k+1)=Ask.Ask_Size3(k);
                    Ask.Ask_L4(k+1)=Ask.Ask_L4(k);Ask.Ask_Size4(k+1)=Ask.Ask_Size4(k);
                    Ask(k,:)=[];
                    disp('New price is higher than the first 4 Ask price levels, ignore !');
                end
            end   
        % if the next message is a TRADE;
        elseif (Type(k)==4 || Type(k)==6)
            ASKID=[];
            for s=1:length(LinkASK)
                askid=LinkASK(s).AskID;
                ASKID=[ASKID;askid];
            end
            % idx is the index to track the order from the original dataset
            % containing linked messages;
            idx=find(ASKID(:,1)==ASK_ID(k));
            Linked_Messages=LinkASK(idx).Linked_Messages;
            Valid_Price=LinkASK(idx).Valid_Price;
            Valid_Volume=LinkASK(idx).Valid_Volume;
            % next figure out what valid price and volume that particular
            % message corresponds to;
            idx1=find(Linked_Messages(:,1)==LLORDASK(k));
            % below is the valid price and volume that the should enter the
            % LOB upon the TRADE;
            price=Valid_Price(idx1);
            volume=Valid_Volume(idx1);
            % check that the messages do not contain only TRADES;
            TYPE=DATA(1).Type;
            if (length(unique(TYPE(Linked_Messages)))>1)
                % check that the volume is not fully executed, in which
                % case the only thing that is updated is the depth at the
                % corresponding price level;
                if price==Ask.Ask_L1(k-1)
                    if ((Ask.Ask_Size1(k-1)>Valid_Volume(idx1-1)) || ((Ask.Ask_Size1(k-1)==Valid_Volume(idx1-1)) && (volume~=0)))
                        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                        Ask.Time(k)=MILLISECONDS(k);
                        Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1)-Valid_Volume(idx1-1)+volume;
                        Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                        Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                        Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                    elseif (Ask.Ask_Size1(k-1)==Valid_Volume(idx1-1) && volume==0)
                        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                        Ask.Time(k)=MILLISECONDS(k);
                        Ask.Ask_L1(k)=Ask.Ask_L2(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size2(k-1);
                        Ask.Ask_L2(k)=Ask.Ask_L3(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size3(k-1);
                        Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%                       Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                        llordask=LLORDASK(1:k-1,1);
                        type=Type(1:k-1,1);
                        idprice=find(type(:,1)==1);
                        % row number of each order ENTER;
                        llordask=llordask(idprice);
                        ALLENTER=[];
                        for z=1:length(LinkASK)
                            enter=LinkASK(z).Linked_Messages(1);
                            ALLENTER=[ALLENTER;enter];
                        end
                        INDEX=[];
                        for s=1:length(llordask)
                            index=find(ALLENTER(:,1)==llordask(s));
                            INDEX=[INDEX;index];
                        end
                        ALL_PRICE_IN_LOB=[];
                        ALL_VOLUM_IN_LOB=[];
                        for t=1:length(INDEX)
                            linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                            validprice=LinkASK(INDEX(t)).Valid_Price;
                            validvolume=LinkASK(INDEX(t)).Valid_Volume;
                            % find the prevailing price and volume at the time in which we want to
                            % update the LOB (i.e., before the k-th message in LLORDASK);
                            badid=find(linkedorder(:,1)>=LLORDASK(k));
                            linkedorder(badid)=[];
                            validprice(badid)=[];
                            validvolume(badid)=[];
                            TYpe=DATA(1).Type;
                            TYpe=TYpe(linkedorder);
                            isdelete=find(TYpe(:,1)==2);
                            % ignore if message is deleted;
                            if ~isempty(isdelete)
                                disp('the order is deleted before the k-th message is entered, ignore !');
                            % the message is still in the LOB, figure out the valid price and
                            % volume immediately before the k-th message is entered;
                            elseif isempty(isdelete)
                                % valid price and volume depends on the last order type, this is
                                % already given in the validprice and validvolume. the only
                                % exception is when the last message is a TRADE and the
                                % corresponding validvolume is 0, in which case all the volume has
                                % been executed;
                                if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                                    disp('the order is fully executed before the k-th message is entered, ignore !');
                                else
                                    ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                                    ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                                end
                            end
                        end
                        % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                        % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                        % note that there might be repeatitive prices due to multiple orders
                        % revising toward the same price, aggregate them;
                        all=sort(ALL_PRICE_IN_LOB);
                        if Ask.Ask_L3(k)~=0
                            IDprice=find(all(:,1)>Ask.Ask_L3(k));
                            if ~isempty(IDprice)
                                all=all(IDprice(1));
                                ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                                vol=ALL_VOLUM_IN_LOB(ID);
                                vol=sum(vol);
                                Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                            elseif isempty(IDprice)
                                Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                            end
                        elseif Ask.Ask_L3(k)==0
                            Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                        end
                    end
                elseif price==Ask.Ask_L2(k-1)
                    if ((Ask.Ask_Size2(k-1)>Valid_Volume(idx1-1)) || ((Ask.Ask_Size2(k-1)==Valid_Volume(idx1-1)) && (volume~=0)))
                        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                        Ask.Time(k)=MILLISECONDS(k);
                        Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                        Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1)-Valid_Volume(idx1-1)+volume;
                        Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                        Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                    elseif (Ask.Ask_Size2(k-1)==Valid_Volume(idx1-1) && volume==0)
                        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                        Ask.Time(k)=MILLISECONDS(k);
                        Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                        Ask.Ask_L2(k)=Ask.Ask_L3(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size3(k-1);
                        Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%                       Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                        llordask=LLORDASK(1:k-1,1);
                        type=Type(1:k-1,1);
                        idprice=find(type(:,1)==1);
                        % row number of each order ENTER;
                        llordask=llordask(idprice);
                        ALLENTER=[];
                        for z=1:length(LinkASK)
                            enter=LinkASK(z).Linked_Messages(1);
                            ALLENTER=[ALLENTER;enter];
                        end
                        INDEX=[];
                        for s=1:length(llordask)
                            index=find(ALLENTER(:,1)==llordask(s));
                            INDEX=[INDEX;index];
                        end
                        ALL_PRICE_IN_LOB=[];
                        ALL_VOLUM_IN_LOB=[];
                        for t=1:length(INDEX)
                            linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                            validprice=LinkASK(INDEX(t)).Valid_Price;
                            validvolume=LinkASK(INDEX(t)).Valid_Volume;
                            % find the prevailing price and volume at the time in which we want to
                            % update the LOB (i.e., before the k-th message in LLORDASK);
                            badid=find(linkedorder(:,1)>=LLORDASK(k));
                            linkedorder(badid)=[];
                            validprice(badid)=[];
                            validvolume(badid)=[];
                            TYpe=DATA(1).Type;
                            TYpe=TYpe(linkedorder);
                            isdelete=find(TYpe(:,1)==2);
                            % ignore if message is deleted;
                            if ~isempty(isdelete)
                                disp('the order is deleted before the k-th message is entered, ignore !');
                            % the message is still in the LOB, figure out the valid price and
                            % volume immediately before the k-th message is entered;
                            elseif isempty(isdelete)
                                % valid price and volume depends on the last order type, this is
                                % already given in the validprice and validvolume. the only
                                % exception is when the last message is a TRADE and the
                                % corresponding validvolume is 0, in which case all the volume has
                                % been executed;
                                if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                                    disp('the order is fully executed before the k-th message is entered, ignore !');
                                else
                                    ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                                    ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                                end
                            end
                        end
                        % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                        % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                        % note that there might be repeatitive prices due to multiple orders
                        % revising toward the same price, aggregate them;
                        all=sort(ALL_PRICE_IN_LOB);
                        if Ask.Ask_L3(k)~=0
                            IDprice=find(all(:,1)>Ask.Ask_L3(k));
                            if ~isempty(IDprice)
                                all=all(IDprice(1));
                                ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                                vol=ALL_VOLUM_IN_LOB(ID);
                                vol=sum(vol);
                                Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                            elseif isempty(IDprice)
                                Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                            end
                        elseif Ask.Ask_L3(k)==0
                            Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                        end
                    end
                elseif price==Ask.Ask_L3(k-1)
                    if ((Ask.Ask_Size3(k-1)>Valid_Volume(idx1-1)) || ((Ask.Ask_Size3(k-1)==Valid_Volume(idx1-1)) && (volume~=0)))
                        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                        Ask.Time(k)=MILLISECONDS(k);
                        Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                        Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                        Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1)-Valid_Volume(idx1-1)+volume;
                        Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                    elseif (Ask.Ask_Size3(k-1)==Valid_Volume(idx1-1) && volume==0) 
                        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                        Ask.Time(k)=MILLISECONDS(k);
                        Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                        Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                        Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
%                       Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                        llordask=LLORDASK(1:k-1,1);
                        type=Type(1:k-1,1);
                        idprice=find(type(:,1)==1);
                        % row number of each order ENTER;
                        llordask=llordask(idprice);
                        ALLENTER=[];
                        for z=1:length(LinkASK)
                            enter=LinkASK(z).Linked_Messages(1);
                            ALLENTER=[ALLENTER;enter];
                        end
                        INDEX=[];
                        for s=1:length(llordask)
                            index=find(ALLENTER(:,1)==llordask(s));
                            INDEX=[INDEX;index];
                        end
                        ALL_PRICE_IN_LOB=[];
                        ALL_VOLUM_IN_LOB=[];
                        for t=1:length(INDEX)
                            linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                            validprice=LinkASK(INDEX(t)).Valid_Price;
                            validvolume=LinkASK(INDEX(t)).Valid_Volume;
                            % find the prevailing price and volume at the time in which we want to
                            % update the LOB (i.e., before the k-th message in LLORDASK);
                            badid=find(linkedorder(:,1)>=LLORDASK(k));
                            linkedorder(badid)=[];
                            validprice(badid)=[];
                            validvolume(badid)=[];
                            TYpe=DATA(1).Type;
                            TYpe=TYpe(linkedorder);
                            isdelete=find(TYpe(:,1)==2);
                            % ignore if message is deleted;
                            if ~isempty(isdelete)
                                disp('the order is deleted before the k-th message is entered, ignore !');
                            % the message is still in the LOB, figure out the valid price and
                            % volume immediately before the k-th message is entered;
                            elseif isempty(isdelete)
                                % valid price and volume depends on the last order type, this is
                                % already given in the validprice and validvolume. the only
                                % exception is when the last message is a TRADE and the
                                % corresponding validvolume is 0, in which case all the volume has
                                % been executed;
                                if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                                    disp('the order is fully executed before the k-th message is entered, ignore !');
                                else
                                    ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                                    ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                                end
                            end
                        end
                        % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                        % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                        % note that there might be repeatitive prices due to multiple orders
                        % revising toward the same price, aggregate them;
                        all=sort(ALL_PRICE_IN_LOB);
                        if Ask.Ask_L3(k)~=0
                            IDprice=find(all(:,1)>Ask.Ask_L3(k));
                            if ~isempty(IDprice)
                                all=all(IDprice(1));
                                ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                                vol=ALL_VOLUM_IN_LOB(ID);
                                vol=sum(vol);
                                Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                            elseif isempty(IDprice)
                                Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                            end
                        elseif Ask.Ask_L3(k)==0
                            Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                        end
                    end
                elseif price==Ask.Ask_L4(k-1)
                    if ((Ask.Ask_Size4(k-1)>Valid_Volume(idx1-1)) || ((Ask.Ask_Size4(k-1)==Valid_Volume(idx1-1)) && (volume~=0)))
                        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                        Ask.Time(k)=MILLISECONDS(k);
                        Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                        Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                        Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                        Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1)-Valid_Volume(idx1-1)+volume;
                    elseif (Ask.Ask_Size4(k-1)==Valid_Volume(idx1-1) && volume==0)
                        Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                        Ask.Time(k)=MILLISECONDS(k);
                        Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                        Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                        Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
%                       Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
                        llordask=LLORDASK(1:k-1,1);
                        type=Type(1:k-1,1);
                        idprice=find(type(:,1)==1);
                        % row number of each order ENTER;
                        llordask=llordask(idprice);
                        ALLENTER=[];
                        for z=1:length(LinkASK)
                            enter=LinkASK(z).Linked_Messages(1);
                            ALLENTER=[ALLENTER;enter];
                        end
                        INDEX=[];
                        for s=1:length(llordask)
                            index=find(ALLENTER(:,1)==llordask(s));
                            INDEX=[INDEX;index];
                        end
                        ALL_PRICE_IN_LOB=[];
                        ALL_VOLUM_IN_LOB=[];
                        for t=1:length(INDEX)
                            linkedorder=LinkASK(INDEX(t)).Linked_Messages;
                            validprice=LinkASK(INDEX(t)).Valid_Price;
                            validvolume=LinkASK(INDEX(t)).Valid_Volume;
                            % find the prevailing price and volume at the time in which we want to
                            % update the LOB (i.e., before the k-th message in LLORDASK);
                            badid=find(linkedorder(:,1)>=LLORDASK(k));
                            linkedorder(badid)=[];
                            validprice(badid)=[];
                            validvolume(badid)=[];
                            TYpe=DATA(1).Type;
                            TYpe=TYpe(linkedorder);
                            isdelete=find(TYpe(:,1)==2);
                            % ignore if message is deleted;
                            if ~isempty(isdelete)
                                disp('the order is deleted before the k-th message is entered, ignore !');
                            % the message is still in the LOB, figure out the valid price and
                            % volume immediately before the k-th message is entered;
                            elseif isempty(isdelete)
                                % valid price and volume depends on the last order type, this is
                                % already given in the validprice and validvolume. the only
                                % exception is when the last message is a TRADE and the
                                % corresponding validvolume is 0, in which case all the volume has
                                % been executed;
                                if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
                                    disp('the order is fully executed before the k-th message is entered, ignore !');
                                else
                                    ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
                                    ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
                                end
                            end
                        end
                        % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
                        % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
                        % note that there might be repeatitive prices due to multiple orders
                        % revising toward the same price, aggregate them;
                        all=sort(ALL_PRICE_IN_LOB);
                        if Ask.Ask_L4(k-1)~=0
                            IDprice=find(all(:,1)>Ask.Ask_L4(k-1));
                            if ~isempty(IDprice)
                                all=all(IDprice(1));
                                ID=find(ALL_PRICE_IN_LOB(:,1)==all);
                                vol=ALL_VOLUM_IN_LOB(ID);
                                vol=sum(vol);
                                Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
                            elseif isempty(IDprice)
                                Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                            end
                        elseif Ask.Ask_L4(k-1)==0
                            Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
                        end
                    end
                elseif (price>Ask.Ask_L4(k-1) && Ask.Ask_L4(k-1)~=0)
                    Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                    Ask.Time(k)=MILLISECONDS(k);
                    Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                    Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                    Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                    Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                    disp('Price is higher than the first 4 Ask price levels, ignore !');
                end
            % messages contain only a TRADE or multiple TRADES;
            elseif (length(unique(TYPE(Linked_Messages)))==1)
                Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
                Ask.Time(k)=MILLISECONDS(k);
                Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
                Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
                Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
                Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
                disp('the trade is happening at the center point or off-market, so no change should happen at LOB !');
                % in this case, price and volume are no longer the valid
                % price and volume that should enter the LOB, but the price
                % and volume that should be executed and therefore removed
                % from the LOB (see ValidPrice_Volume_for_each_message for
                % detail);
% %                 if price==Ask.Ask_L1(k-1)
% %                     if Ask.Ask_Size1(k-1)>volume
% %                         Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                         Ask.Time(k)=MILLISECONDS(k);
% %                         Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1)-volume;
% %                         Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
% %                         Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
% %                         Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
% %                     elseif Ask.Ask_Size1(k-1)==volume
% %                         Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                         Ask.Time(k)=MILLISECONDS(k);
% %                         Ask.Ask_L1(k)=Ask.Ask_L2(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size2(k-1);
% %                         Ask.Ask_L2(k)=Ask.Ask_L3(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size3(k-1);
% %                         Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
% % %                       Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
% %                         llordask=LLORDASK(1:k-1,1);
% %                         type=Type(1:k-1,1);
% %                         idprice=find(type(:,1)==1);
% %                         % row number of each order ENTER;
% %                         llordask=llordask(idprice);
% %                         ALLENTER=[];
% %                         for z=1:length(LinkASK)
% %                             enter=LinkASK(z).Linked_Messages(1);
% %                             ALLENTER=[ALLENTER;enter];
% %                         end
% %                         INDEX=[];
% %                         for s=1:length(llordask)
% %                             index=find(ALLENTER(:,1)==llordask(s));
% %                             INDEX=[INDEX;index];
% %                         end
% %                         ALL_PRICE_IN_LOB=[];
% %                         ALL_VOLUM_IN_LOB=[];
% %                         for t=1:length(INDEX)
% %                             linkedorder=LinkASK(INDEX(t)).Linked_Messages;
% %                             validprice=LinkASK(INDEX(t)).Valid_Price;
% %                             validvolume=LinkASK(INDEX(t)).Valid_Volume;
% %                             % find the prevailing price and volume at the time in which we want to
% %                             % update the LOB (i.e., before the k-th message in LLORDASK);
% %                             badid=find(linkedorder(:,1)>=LLORDASK(k));
% %                             linkedorder(badid)=[];
% %                             validprice(badid)=[];
% %                             validvolume(badid)=[];
% %                             TYpe=DATA(1).Type;
% %                             TYpe=TYpe(linkedorder);
% %                             isdelete=find(TYpe(:,1)==2);
% %                             % ignore if message is deleted;
% %                             if ~isempty(isdelete)
% %                                 disp('the order is deleted before the k-th message is entered, ignore !');
% %                             % the message is still in the LOB, figure out the valid price and
% %                             % volume immediately before the k-th message is entered;
% %                             elseif isempty(isdelete)
% %                                 % valid price and volume depends on the last order type, this is
% %                                 % already given in the validprice and validvolume. the only
% %                                 % exception is when the last message is a TRADE and the
% %                                 % corresponding validvolume is 0, in which case all the volume has
% %                                 % been executed;
% %                                 if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
% %                                     disp('the order is fully executed before the k-th message is entered, ignore !');
% %                                 else
% %                                     ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
% %                                     ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
% %                                 end
% %                             end
% %                         end
% %                         % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
% %                         % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
% %                         % note that there might be repeatitive prices due to multiple orders
% %                         % revising toward the same price, aggregate them;
% %                         all=sort(ALL_PRICE_IN_LOB);
% %                         if Ask.Ask_L3(k)~=0
% %                             IDprice=find(all(:,1)>Ask.Ask_L3(k));
% %                             if ~isempty(IDprice)
% %                                 all=all(IDprice(1));
% %                                 ID=find(ALL_PRICE_IN_LOB(:,1)==all);
% %                                 vol=ALL_VOLUM_IN_LOB(ID);
% %                                 vol=sum(vol);
% %                                 Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
% %                             elseif isempty(IDprice)
% %                                 Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
% %                             end
% %                         elseif Ask.Ask_L3(k)==0
% %                             Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
% %                         end
% %                     end
% %                 elseif price==Ask.Ask_L2(k-1)
% %                     if Ask.Ask_Size2(k-1)>volume
% %                         Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                         Ask.Time(k)=MILLISECONDS(k);
% %                         Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
% %                         Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1)-volume;
% %                         Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
% %                         Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
% %                     elseif Ask.Ask_Size2(k-1)==volume
% %                         Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                         Ask.Time(k)=MILLISECONDS(k);
% %                         Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
% %                         Ask.Ask_L2(k)=Ask.Ask_L3(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size3(k-1);
% %                         Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
% % %                       Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
% %                         llordask=LLORDASK(1:k-1,1);
% %                         type=Type(1:k-1,1);
% %                         idprice=find(type(:,1)==1);
% %                         % row number of each order ENTER;
% %                         llordask=llordask(idprice);
% %                         ALLENTER=[];
% %                         for z=1:length(LinkASK)
% %                             enter=LinkASK(z).Linked_Messages(1);
% %                             ALLENTER=[ALLENTER;enter];
% %                         end
% %                         INDEX=[];
% %                         for s=1:length(llordask)
% %                             index=find(ALLENTER(:,1)==llordask(s));
% %                             INDEX=[INDEX;index];
% %                         end
% %                         ALL_PRICE_IN_LOB=[];
% %                         ALL_VOLUM_IN_LOB=[];
% %                         for t=1:length(INDEX)
% %                             linkedorder=LinkASK(INDEX(t)).Linked_Messages;
% %                             validprice=LinkASK(INDEX(t)).Valid_Price;
% %                             validvolume=LinkASK(INDEX(t)).Valid_Volume;
% %                             % find the prevailing price and volume at the time in which we want to
% %                             % update the LOB (i.e., before the k-th message in LLORDASK);
% %                             badid=find(linkedorder(:,1)>=LLORDASK(k));
% %                             linkedorder(badid)=[];
% %                             validprice(badid)=[];
% %                             validvolume(badid)=[];
% %                             TYpe=DATA(1).Type;
% %                             TYpe=TYpe(linkedorder);
% %                             isdelete=find(TYpe(:,1)==2);
% %                             % ignore if message is deleted;
% %                             if ~isempty(isdelete)
% %                                 disp('the order is deleted before the k-th message is entered, ignore !');
% %                             % the message is still in the LOB, figure out the valid price and
% %                             % volume immediately before the k-th message is entered;
% %                             elseif isempty(isdelete)
% %                                 % valid price and volume depends on the last order type, this is
% %                                 % already given in the validprice and validvolume. the only
% %                                 % exception is when the last message is a TRADE and the
% %                                 % corresponding validvolume is 0, in which case all the volume has
% %                                 % been executed;
% %                                 if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
% %                                     disp('the order is fully executed before the k-th message is entered, ignore !');
% %                                 else
% %                                     ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
% %                                     ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
% %                                 end
% %                             end
% %                         end
% %                         % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
% %                         % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
% %                         % note that there might be repeatitive prices due to multiple orders
% %                         % revising toward the same price, aggregate them;
% %                         all=sort(ALL_PRICE_IN_LOB);
% %                         if Ask.Ask_L3(k)~=0
% %                             IDprice=find(all(:,1)>Ask.Ask_L3(k));
% %                             if ~isempty(IDprice)
% %                                 all=all(IDprice(1));
% %                                 ID=find(ALL_PRICE_IN_LOB(:,1)==all);
% %                                 vol=ALL_VOLUM_IN_LOB(ID);
% %                                 vol=sum(vol);
% %                                 Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
% %                             elseif isempty(IDprice)
% %                                 Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
% %                             end
% %                         elseif Ask.Ask_L3(k)==0
% %                             Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
% %                         end
% %                     end
% %                 elseif price==Ask.Ask_L3(k-1)
% %                     if Ask.Ask_Size3(k-1)>volume
% %                         Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                         Ask.Time(k)=MILLISECONDS(k);
% %                         Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
% %                         Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
% %                         Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1)-volume;
% %                         Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
% %                     elseif Ask.Ask_Size3(k-1)==volume
% %                         Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                         Ask.Time(k)=MILLISECONDS(k);
% %                         Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
% %                         Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
% %                         Ask.Ask_L3(k)=Ask.Ask_L4(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size4(k-1);
% % %                       Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
% %                         llordask=LLORDASK(1:k-1,1);
% %                         type=Type(1:k-1,1);
% %                         idprice=find(type(:,1)==1);
% %                         % row number of each order ENTER;
% %                         llordask=llordask(idprice);
% %                         ALLENTER=[];
% %                         for z=1:length(LinkASK)
% %                             enter=LinkASK(z).Linked_Messages(1);
% %                             ALLENTER=[ALLENTER;enter];
% %                         end
% %                         INDEX=[];
% %                         for s=1:length(llordask)
% %                             index=find(ALLENTER(:,1)==llordask(s));
% %                             INDEX=[INDEX;index];
% %                         end
% %                         ALL_PRICE_IN_LOB=[];
% %                         ALL_VOLUM_IN_LOB=[];
% %                         for t=1:length(INDEX)
% %                             linkedorder=LinkASK(INDEX(t)).Linked_Messages;
% %                             validprice=LinkASK(INDEX(t)).Valid_Price;
% %                             validvolume=LinkASK(INDEX(t)).Valid_Volume;
% %                             % find the prevailing price and volume at the time in which we want to
% %                             % update the LOB (i.e., before the k-th message in LLORDASK);
% %                             badid=find(linkedorder(:,1)>=LLORDASK(k));
% %                             linkedorder(badid)=[];
% %                             validprice(badid)=[];
% %                             validvolume(badid)=[];
% %                             TYpe=DATA(1).Type;
% %                             TYpe=TYpe(linkedorder);
% %                             isdelete=find(TYpe(:,1)==2);
% %                             % ignore if message is deleted;
% %                             if ~isempty(isdelete)
% %                                 disp('the order is deleted before the k-th message is entered, ignore !');
% %                             % the message is still in the LOB, figure out the valid price and
% %                             % volume immediately before the k-th message is entered;
% %                             elseif isempty(isdelete)
% %                                 % valid price and volume depends on the last order type, this is
% %                                 % already given in the validprice and validvolume. the only
% %                                 % exception is when the last message is a TRADE and the
% %                                 % corresponding validvolume is 0, in which case all the volume has
% %                                 % been executed;
% %                                 if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
% %                                     disp('the order is fully executed before the k-th message is entered, ignore !');
% %                                 else
% %                                     ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
% %                                     ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
% %                                 end
% %                             end
% %                         end
% %                         % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
% %                         % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
% %                         % note that there might be repeatitive prices due to multiple orders
% %                         % revising toward the same price, aggregate them;
% %                         all=sort(ALL_PRICE_IN_LOB);
% %                         if Ask.Ask_L3(k)~=0
% %                             IDprice=find(all(:,1)>Ask.Ask_L3(k));
% %                             if ~isempty(IDprice)
% %                                 all=all(IDprice(1));
% %                                 ID=find(ALL_PRICE_IN_LOB(:,1)==all);
% %                                 vol=ALL_VOLUM_IN_LOB(ID);
% %                                 vol=sum(vol);
% %                                 Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
% %                             elseif isempty(IDprice)
% %                                 Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
% %                             end
% %                         elseif Ask.Ask_L3(k)==0
% %                             Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
% %                         end
% %                     end
% %                 elseif price==Ask.Ask_L4(k-1)
% %                     if Ask.Ask_Size4(k-1)>volume
% %                         Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                         Ask.Time(k)=MILLISECONDS(k);
% %                         Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
% %                         Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
% %                         Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
% %                         Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1)-volume;
% %                     elseif Ask.Ask_Size4(k-1)==volume
% %                         Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                         Ask.Time(k)=MILLISECONDS(k);
% %                         Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
% %                         Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
% %                         Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
% % %                       Ask.Ask_L4(k)=0;              Ask.Ask_Size4(k)=0;
% %                         llordask=LLORDASK(1:k-1,1);
% %                         type=Type(1:k-1,1);
% %                         idprice=find(type(:,1)==1);
% %                         % row number of each order ENTER;
% %                         llordask=llordask(idprice);
% %                         ALLENTER=[];
% %                         for z=1:length(LinkASK)
% %                             enter=LinkASK(z).Linked_Messages(1);
% %                             ALLENTER=[ALLENTER;enter];
% %                         end
% %                         INDEX=[];
% %                         for s=1:length(llordask)
% %                             index=find(ALLENTER(:,1)==llordask(s));
% %                             INDEX=[INDEX;index];
% %                         end
% %                         ALL_PRICE_IN_LOB=[];
% %                         ALL_VOLUM_IN_LOB=[];
% %                         for t=1:length(INDEX)
% %                             linkedorder=LinkASK(INDEX(t)).Linked_Messages;
% %                             validprice=LinkASK(INDEX(t)).Valid_Price;
% %                             validvolume=LinkASK(INDEX(t)).Valid_Volume;
% %                             % find the prevailing price and volume at the time in which we want to
% %                             % update the LOB (i.e., before the k-th message in LLORDASK);
% %                             badid=find(linkedorder(:,1)>=LLORDASK(k));
% %                             linkedorder(badid)=[];
% %                             validprice(badid)=[];
% %                             validvolume(badid)=[];
% %                             TYpe=DATA(1).Type;
% %                             TYpe=TYpe(linkedorder);
% %                             isdelete=find(TYpe(:,1)==2);
% %                             % ignore if message is deleted;
% %                             if ~isempty(isdelete)
% %                                 disp('the order is deleted before the k-th message is entered, ignore !');
% %                             % the message is still in the LOB, figure out the valid price and
% %                             % volume immediately before the k-th message is entered;
% %                             elseif isempty(isdelete)
% %                                 % valid price and volume depends on the last order type, this is
% %                                 % already given in the validprice and validvolume. the only
% %                                 % exception is when the last message is a TRADE and the
% %                                 % corresponding validvolume is 0, in which case all the volume has
% %                                 % been executed;
% %                                 if ((TYpe(end)==4 || TYpe(end)==6) && (validvolume(end)==0))
% %                                     disp('the order is fully executed before the k-th message is entered, ignore !');
% %                                 else
% %                                     ALL_PRICE_IN_LOB=[ALL_PRICE_IN_LOB;validprice(end)];
% %                                     ALL_VOLUM_IN_LOB=[ALL_VOLUM_IN_LOB;validvolume(end)];
% %                                 end
% %                             end
% %                         end
% %                         % NOW FIND THE LOWEST PRICE IN "ALL_PRICE_IN_LOB" THAT IS HIGHER THAN
% %                         % Ask.Ask_L3(k), WHICH WILL BE Ask.Ask_L4(k);
% %                         % note that there might be repeatitive prices due to multiple orders
% %                         % revising toward the same price, aggregate them;
% %                         all=sort(ALL_PRICE_IN_LOB);
% %                         if Ask.Ask_L4(k-1)~=0
% %                             IDprice=find(all(:,1)>Ask.Ask_L4(k-1));
% %                             if ~isempty(IDprice)
% %                                 all=all(IDprice(1));
% %                                 ID=find(ALL_PRICE_IN_LOB(:,1)==all);
% %                                 vol=ALL_VOLUM_IN_LOB(ID);
% %                                 vol=sum(vol);
% %                                 Ask.Ask_L4(k)=all;Ask.Ask_Size4(k)=vol;
% %                             elseif isempty(IDprice)
% %                                 Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
% %                             end
% %                         elseif Ask.Ask_L4(k-1)==0
% %                             Ask.Ask_L4(k)=0;Ask.Ask_Size4(k)=0;
% %                         end
% %                     end
% %                 elseif price>Ask.Ask_L4(k-1)
% %                     Ask.TICKER(k,1:3)=TICKER;Ask.DATE(k)=DATE;
% %                     Ask.Time(k)=MILLISECONDS(k);
% %                     Ask.Ask_L1(k)=Ask.Ask_L1(k-1);Ask.Ask_Size1(k)=Ask.Ask_Size1(k-1);
% %                     Ask.Ask_L2(k)=Ask.Ask_L2(k-1);Ask.Ask_Size2(k)=Ask.Ask_Size2(k-1);
% %                     Ask.Ask_L3(k)=Ask.Ask_L3(k-1);Ask.Ask_Size3(k)=Ask.Ask_Size3(k-1);
% %                     Ask.Ask_L4(k)=Ask.Ask_L4(k-1);Ask.Ask_Size4(k)=Ask.Ask_Size4(k-1);
% %                     disp('Price is higher than the first 4 Ask price levels, ignore !');
% %                 end
            end
        end
    end
    disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
end
DATA.noOB0ASK=noOB0ASK;
DATA.Ask=Ask;
end