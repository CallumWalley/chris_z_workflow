function [DATA] = BidSideVariables(file, row)
inputObject = matfile(file);
DATA=inputObject.DATA(1,row);

TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDBID=DATA(1).no0B0LLORDBID;  % ASK - HFT
LLORDBID=sort(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDBID);
% Normal trading hour overlapping periods in two markets in AEDT:
% 10:10AM - 2:35PM

index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((14*60*60)+(35*60))*1000));
LLORDBID=LLORDBID(index); % all orders on the Ask side that are within the overlapping periods;

%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDBID);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(LLORDBID);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(LLORDBID);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(LLORDBID);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDBID);

%% Construct explanatory variables;
   % Each message is matched against the LOB on the corresponding side.

   % As the LOB is updated upon each message arrival, so such match can be
   % done specifically by matching the timestamp of each message against
   % the timestamp of each LOB update. In cases where there are multiple
   % same timestamps for various updates in LOB, which is caused by
   % messages coming at the same time (at least from the data recording
   % perspective), the matching is done by using the chornological sequence
   % of messages with the same timestamps.

%% Variable definitions:
%TRADE VARIABLES:
% 1. HFT signed aggressive $ volume: HFT buy-initiated trade - HFT sell-initiated trade.
% 2. nHFT signed aggressive $ volume: nHFT buy-initiated trade - nHFT sell-initiated trade.
% 3. HFT signed passive $ volume: HFT passive buy - HFT passive sell.
% 4. nHFT signed passive $ volume: nHFT passive buy - nHFT passive sell.
%QUOTE VARIABLES:
% 5. orders that improve NBBO
%    cancels that worsen NBBO
% 6. orders @ NBBO
%    cancels @ NBBO
% 7. orders beyond NBBO
%    cancels beyond NBBO
BidLL = cell2table(cell(0,13), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'nLL_signed_volume', 'LL_passive_signed_volume', 'nLL_passive_signed_volume', 'Improving_Bid', 'Worsening_BidCancel', 'NBO_Bid', 'NBO_BidCancel', 'DeepinBook_Bid', 'DeepinBook_BidCancel'});
BidLL.TICKER=num2str(BidLL.TICKER);
% Update the variables in the AskLL upon each order, which is matched
% against the LOB;
LLORDBID=sort(LLORDBID);
for k=1:length(LLORDBID) % # of updates;
    BidLL.TICKER(k,1:3)=TICKER;BidLL.DATE(k)=DATE;
    BidLL.Time(k)=MILLISECONDS(k);
%% The next step is to figure out which row to look at from the LOB in
%  order to figure out the aggressiveness of orders and therefore the
%  construction of the variables;
%% Recall that in the ReConstructLOB function, the LOB is updated based on
%  the LLORDASK, which is renamed "noOB0ASK(noOB0BID)", we therefore find
%  it useful to use noOB0ASK(noOB0BID) to find the correct row;
noOB0BID=DATA(1).noOB0BID;
noOB0BID=sort(noOB0BID);
BidLOB=DATA(1).Bid;
idx=find(noOB0BID(:,1)==LLORDBID(k));
if (Type(k)==1 || Type(k)==3) % when the incoming order is ENTER or AMEND
    Price=PRICE(k); % price of the incoming order(ENTER/AMEND);
    % price of the incoming order(ENTER/AMEND) is lower than the prevailing
    % inside ask, meaning that it improves the ask.
    if Price>BidLOB.Bid_L1(idx-1)
        BidLL.Improving_Bid(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % price of the incoming order(ENTER/AMEND) is at the prevailing inside
    % ask, meaning that it stays @ NBO;
    elseif Price==BidLOB.Bid_L1(idx-1)
        BidLL.NBO_Bid(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % price of the incoming order(ENTER/AMEND) is beyond the prevailing
    % inside ask, meaning that it happens deep in th book;
    elseif Price<BidLOB.Bid_L1(idx-1)
        BidLL.DeepinBook_Bid(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    end
elseif Type(k)==2 % when the incoming order is DELETE
    % the incoming DELETE order worsens the inside ask, which means that
    % the current Ask is higher than the previous one.
    if BidLOB.Bid_L1(idx-1)>BidLOB.Bid_L1(idx)
        BidLL.Worsening_BidCancel(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % the incoming DELETE order happens @ NBO but does not worsen the
    % inside ask.
    elseif (BidLOB.Bid_L1(idx-1)==BidLOB.Bid_L1(idx)) && (BidLOB.Bid_Size1(idx-1)>BidLOB.Bid_Size1(idx))
        BidLL.NBO_BidCancel(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % the incoming DELETE order happens beyond the prevailing inside ask,
    % meaning that it happens deep in the book;
    elseif (BidLOB.Bid_L1(idx-1)==BidLOB.Bid_L1(idx)) && (BidLOB.Bid_Size1(idx-1)==BidLOB.Bid_Size1(idx))
        BidLL.DeepinBook_BidCancel(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    end
elseif Type(k)==4 % when the incoming order is TRADE
    % only consider non-off-market & non-dark trades:
    % buy-initiated trade
    if Qualifiers(k)==1
        BidLL.LL_signed_volume(k)=PRICE(k)*VOLUME(k);
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % sell-initiated trade
    elseif Qualifiers(k)==-1
        BidLL.LL_passive_signed_volume(k)=PRICE(k)*VOLUME(k);
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % unsigned, meaning its either dark trading or off-market trading
    else
        BidLL.LL_signed_volume(k)=0;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    end
elseif Type(k)==6 % when the incoming order is OFFTR
    BidLL.LL_signed_volume(k)=0;
    disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
end
end
DATA.BidLL=BidLL;
clearvars -except DATA;

TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDBID=DATA(1).no0B0nLLORDBID;  % ASK - nHFT
LLORDBID=sort(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDBID);
% Normal trading hour overlapping periods in two markets in AEDT:
% 10:10AM - 2:35PM

index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((14*60*60)+(35*60))*1000));
LLORDBID=LLORDBID(index); % all orders on the Ask side that are within the overlapping periods;

%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDBID);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(LLORDBID);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(LLORDBID);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(LLORDBID);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDBID);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BidnLL = cell2table(cell(0,13), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'nLL_signed_volume', 'LL_passive_signed_volume', 'nLL_passive_signed_volume', 'Improving_Bid', 'Worsening_BidCancel', 'NBO_Bid', 'NBO_BidCancel', 'DeepinBook_Bid', 'DeepinBook_BidCancel'});
BidnLL.TICKER=num2str(BidnLL.TICKER);
% Update the variables in the AsknLL upon each order, which is matched
% against the LOB;
LLORDBID=sort(LLORDBID);
for k=1:length(LLORDBID) % # of updates;
    BidnLL.TICKER(k,1:3)=TICKER;BidnLL.DATE(k)=DATE;
    BidnLL.Time(k)=MILLISECONDS(k);
%% The next step is to figure out which row to look at from the LOB in
%  order to figure out the aggressiveness of orders and therefore the
%  construction of the variables;
%% Recall that in the ReConstructLOB function, the LOB is updated based on
%  the LLORDASK, which is renamed "noOB0ASK(noOB0BID)", we therefore find
%  it useful to use noOB0ASK(noOB0BID) to find the correct row;
noOB0BID=DATA(1).noOB0BID;
noOB0BID=sort(noOB0BID);
BidLOB=DATA(1).Bid;
idx=find(noOB0BID(:,1)==LLORDBID(k));
if (Type(k)==1 || Type(k)==3) % when the incoming order is ENTER or AMEND
    Price=PRICE(k); % price of the incoming order(ENTER/AMEND);
    % price of the incoming order(ENTER/AMEND) is lower than the prevailing
    % inside ask, meaning that it improves the ask.
    if Price>BidLOB.Bid_L1(idx-1)
        BidnLL.Improving_Bid(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % price of the incoming order(ENTER/AMEND) is at the prevailing inside
    % ask, meaning that it stays @ NBO;
    elseif Price==BidLOB.Bid_L1(idx-1)
        BidnLL.NBO_Bid(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % price of the incoming order(ENTER/AMEND) is beyond the prevailing
    % inside ask, meaning that it happens deep in th book;
    elseif Price<BidLOB.Bid_L1(idx-1)
        BidnLL.DeepinBook_Bid(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    end
elseif Type(k)==2 % when the incoming order is DELETE
    % the incoming DELETE order worsens the inside ask, which means that
    % the current Ask is higher than the previous one.
    if BidLOB.Bid_L1(idx-1)>BidLOB.Bid_L1(idx)
        BidnLL.Worsening_BidCancel(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % the incoming DELETE order happens @ NBO but does not worsen the
    % inside ask.
    elseif (BidLOB.Bid_L1(idx-1)==BidLOB.Bid_L1(idx)) && (BidLOB.Bid_Size1(idx-1)>BidLOB.Bid_Size1(idx))
        BidnLL.NBO_BidCancel(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % the incoming DELETE order happens beyond the prevailing inside ask,
    % meaning that it happens deep in the book;
    elseif (BidLOB.Bid_L1(idx-1)==BidLOB.Bid_L1(idx)) && (BidLOB.Bid_Size1(idx-1)==BidLOB.Bid_Size1(idx))
        BidnLL.DeepinBook_BidCancel(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    end
elseif Type(k)==4 % when the incoming order is TRADE
    % only consider non-off-market & non-dark trades:
    % buy-initiated trade
    if Qualifiers(k)==1
        BidnLL.nLL_signed_volume(k)=PRICE(k)*VOLUME(k);
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % sell-initiated trade
    elseif Qualifiers(k)==-1
        BidnLL.nLL_passive_signed_volume(k)=PRICE(k)*VOLUME(k);
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    % unsigned, meaning its either dark trading or off-market trading
    else
        BidnLL.nLL_signed_volume(k)=0;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
    end
elseif Type(k)==6 % when the incoming order is OFFTR
    BidnLL.nLL_signed_volume(k)=0;
    disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDBID))]);
end
end
DATA.BidnLL=BidnLL;
clearvars -except DATA;

%% This part only extracts the trade information
TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDBID=DATA(1).LLORDBID;
LLORDBID=sort(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDBID);
% Normal trading hour overlapping periods in two markets in AEDT:
% 10:10AM - 2:35PM

index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((14*60*60)+(35*60))*1000));
LLORDBID=LLORDBID(index); % all orders on the Ask side that are within the overlapping periods;
%% Extract trade informaiiton, where trades are happening in the lit market;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDBID);
id=find(Type(:,1)==4);
LLORDBID=LLORDBID(id);
Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDBID);
idx=find(Qualifiers(:,1)==1 | Qualifiers(:,1)==-1); % these idx indicates only trades at lit markets (no CX trade, no off-market trades etc);
LLORDBID=LLORDBID(idx);

%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDBID);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(LLORDBID);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(LLORDBID);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(LLORDBID);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDBID);
%% construct transaction data;

BuyLL = cell2table(cell(0,7), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'nLL_signed_volume', 'LL_passive_signed_volume', 'nLL_passive_signed_volume'});
BuyLL.TICKER=num2str(BuyLL.TICKER);
% Update the variables in the AskLL upon each order, which is matched
% against the LOB;
LLORDBID=sort(LLORDBID);
for s=1:length(LLORDBID) % # of updates;
    BuyLL.TICKER(s,1:3)=TICKER;BuyLL.DATE(s)=DATE;
    BuyLL.Time(s)=MILLISECONDS(s);
    % buy-initiated trade
    if Qualifiers(s)==1
        BuyLL.LL_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(LLORDBID))]);
    % sell-initiated trade
    elseif Qualifiers(s)==-1
        BuyLL.LL_passive_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(LLORDBID))]);
    end
end
DATA.BuyLL=BuyLL;
clearvars -except DATA;
%%
TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDBID=DATA(1).nLLORDBID;
LLORDBID=sort(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDBID);
% Normal trading hour overlapping periods in two markets in AEDT:
% 10:10AM - 2:35PM

index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((14*60*60)+(35*60))*1000));
LLORDBID=LLORDBID(index); % all orders on the Ask side that are within the overlapping periods;
%% Extract trade informaiiton, where trades are happening in the lit market;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDBID);
id=find(Type(:,1)==4);
LLORDBID=LLORDBID(id);
Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDBID);
idx=find(Qualifiers(:,1)==1 | Qualifiers(:,1)==-1); % these idx indicates only trades at lit markets (no CX trade, no off-market trades etc);
LLORDBID=LLORDBID(idx);

%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDBID);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(LLORDBID);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(LLORDBID);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(LLORDBID);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDBID);
%% construct transaction data;

BuynLL = cell2table(cell(0,7), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'nLL_signed_volume', 'LL_passive_signed_volume', 'nLL_passive_signed_volume'});
BuynLL.TICKER=num2str(BuynLL.TICKER);
% Update the variables in the AskLL upon each order, which is matched
% against the LOB;
LLORDBID=sort(LLORDBID);
for s=1:length(LLORDBID) % # of updates;
    BuynLL.TICKER(s,1:3)=TICKER;BuynLL.DATE(s)=DATE;
    BuynLL.Time(s)=MILLISECONDS(s);
    % buy-initiated trade
    if Qualifiers(s)==1
        BuynLL.nLL_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(LLORDBID))]);
    % sell-initiated trade
    elseif Qualifiers(s)==-1
        BuynLL.nLL_passive_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(LLORDBID))]);
    end
end
DATA.BuynLL=BuynLL;
clearvars -except DATA;
end