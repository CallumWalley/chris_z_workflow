function [DATA] = AskSideVariables(file, row)
inputObject = matfile(file);
DATA=inputObject.DATA(1,row);

TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDASK=DATA(1).no0B0LLORDASK;  % ASK - HFT
LLORDASK=sort(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDASK);
% Normal trading hour overlapping periods in two markets in AEDT:
% 10:10AM - 2:35PM

index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((14*60*60)+(35*60))*1000));
LLORDASK=LLORDASK(index); % all orders on the Ask side that are within the overlapping periods;

%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDASK);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(LLORDASK);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(LLORDASK);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(LLORDASK);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDASK);

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
AskLL = cell2table(cell(0,13), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'nLL_signed_volume', 'LL_passive_signed_volume', 'nLL_passive_signed_volume', 'Improving_Ask', 'Worsening_AskCancel', 'NBO_Ask', 'NBO_AskCancel', 'DeepinBook_Ask', 'DeepinBook_AskCancel'});
AskLL.TICKER=num2str(AskLL.TICKER);
% Update the variables in the AskLL upon each order, which is matched
% against the LOB;
LLORDASK=sort(LLORDASK);
for k=1:length(LLORDASK) % # of updates;
    AskLL.TICKER(k,1:3)=TICKER;AskLL.DATE(k)=DATE;
    AskLL.Time(k)=MILLISECONDS(k);
%% The next step is to figure out which row to look at from the LOB in
%  order to figure out the aggressiveness of orders and therefore the
%  construction of the variables;
%% Recall that in the ReConstructLOB function, the LOB is updated based on
%  the LLORDASK, which is renamed "noOB0ASK(noOB0BID)", we therefore find
%  it useful to use noOB0ASK(noOB0BID) to find the correct row;
noOB0ASK=DATA(1).noOB0ASK;
noOB0ASK=sort(noOB0ASK);
AskLOB=DATA(1).Ask;
idx=find(noOB0ASK(:,1)==LLORDASK(k));
if (Type(k)==1 || Type(k)==3) % when the incoming order is ENTER or AMEND
    Price=PRICE(k); % price of the incoming order(ENTER/AMEND);
    % price of the incoming order(ENTER/AMEND) is lower than the prevailing
    % inside ask, meaning that it improves the ask.
    if Price<AskLOB.Ask_L1(idx-1)
        AskLL.Improving_Ask(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % price of the incoming order(ENTER/AMEND) is at the prevailing inside
    % ask, meaning that it stays @ NBO;
    elseif Price==AskLOB.Ask_L1(idx-1)
        AskLL.NBO_Ask(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % price of the incoming order(ENTER/AMEND) is beyond the prevailing
    % inside ask, meaning that it happens deep in th book;
    elseif Price>AskLOB.Ask_L1(idx-1)
        AskLL.DeepinBook_Ask(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    end
elseif Type(k)==2 % when the incoming order is DELETE
    % the incoming DELETE order worsens the inside ask, which means that
    % the current Ask is higher than the previous one.
    if AskLOB.Ask_L1(idx-1)<AskLOB.Ask_L1(idx)
        AskLL.Worsening_AskCancel(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % the incoming DELETE order happens @ NBO but does not worsen the
    % inside ask.
    elseif (AskLOB.Ask_L1(idx-1)==AskLOB.Ask_L1(idx)) && (AskLOB.Ask_Size1(idx-1)>AskLOB.Ask_Size1(idx))
        AskLL.NBO_AskCancel(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % the incoming DELETE order happens beyond the prevailing inside ask,
    % meaning that it happens deep in the book;
    elseif (AskLOB.Ask_L1(idx-1)==AskLOB.Ask_L1(idx)) && (AskLOB.Ask_Size1(idx-1)==AskLOB.Ask_Size1(idx))
        AskLL.DeepinBook_AskCancel(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    end
elseif Type(k)==4 % when the incoming order is TRADE
    % only consider non-off-market & non-dark trades:
    % buy-initiated trade
    if Qualifiers(k)==1
        AskLL.LL_passive_signed_volume(k)=PRICE(k)*VOLUME(k)*(-1);
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % sell-initiated trade
    elseif Qualifiers(k)==-1
        AskLL.LL_signed_volume(k)=PRICE(k)*VOLUME(k)*(-1);
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % unsigned, meaning its either dark trading or off-market trading
    else
        AskLL.LL_signed_volume(k)=0;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    end
elseif Type(k)==6 % when the incoming order is OFFTR
    AskLL.LL_signed_volume(k)=0;
    disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
end
end
DATA.AskLL=AskLL;
clearvars -except DATA;

TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDASK=DATA(1).no0B0nLLORDASK;  % ASK - nHFT
LLORDASK=sort(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDASK);
% Normal trading hour overlapping periods in two markets in AEDT:
% 10:10AM - 2:35PM

index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((14*60*60)+(35*60))*1000));
LLORDASK=LLORDASK(index); % all orders on the Ask side that are within the overlapping periods;

%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDASK);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(LLORDASK);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(LLORDASK);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(LLORDASK);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDASK);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AsknLL = cell2table(cell(0,13), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'nLL_signed_volume', 'LL_passive_signed_volume', 'nLL_passive_signed_volume', 'Improving_Ask', 'Worsening_AskCancel', 'NBO_Ask', 'NBO_AskCancel', 'DeepinBook_Ask', 'DeepinBook_AskCancel'});
AsknLL.TICKER=num2str(AsknLL.TICKER);
% Update the variables in the AsknLL upon each order, which is matched
% against the LOB;
LLORDASK=sort(LLORDASK);
for k=1:length(LLORDASK) % # of updates;
    AsknLL.TICKER(k,1:3)=TICKER;AsknLL.DATE(k)=DATE;
    AsknLL.Time(k)=MILLISECONDS(k);
%% The next step is to figure out which row to look at from the LOB in
%  order to figure out the aggressiveness of orders and therefore the
%  construction of the variables;
%% Recall that in the ReConstructLOB function, the LOB is updated based on
%  the LLORDASK, which is renamed "noOB0ASK(noOB0BID)", we therefore find
%  it useful to use noOB0ASK(noOB0BID) to find the correct row;
noOB0ASK=DATA(1).noOB0ASK;
noOB0ASK=sort(noOB0ASK);
AskLOB=DATA(1).Ask;
idx=find(noOB0ASK(:,1)==LLORDASK(k));
if (Type(k)==1 || Type(k)==3) % when the incoming order is ENTER or AMEND
    Price=PRICE(k); % price of the incoming order(ENTER/AMEND);
    % price of the incoming order(ENTER/AMEND) is lower than the prevailing
    % inside ask, meaning that it improves the ask.
    if Price<AskLOB.Ask_L1(idx-1)
        AsknLL.Improving_Ask(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % price of the incoming order(ENTER/AMEND) is at the prevailing inside
    % ask, meaning that it stays @ NBO;
    elseif Price==AskLOB.Ask_L1(idx-1)
        AsknLL.NBO_Ask(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % price of the incoming order(ENTER/AMEND) is beyond the prevailing
    % inside ask, meaning that it happens deep in th book;
    elseif Price>AskLOB.Ask_L1(idx-1)
        AsknLL.DeepinBook_Ask(k)=-1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    end
elseif Type(k)==2 % when the incoming order is DELETE
    % the incoming DELETE order worsens the inside ask, which means that
    % the current Ask is higher than the previous one.
    if AskLOB.Ask_L1(idx-1)<AskLOB.Ask_L1(idx)
        AsknLL.Worsening_AskCancel(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % the incoming DELETE order happens @ NBO but does not worsen the
    % inside ask.
    elseif (AskLOB.Ask_L1(idx-1)==AskLOB.Ask_L1(idx)) && (AskLOB.Ask_Size1(idx-1)>AskLOB.Ask_Size1(idx))
        AsknLL.NBO_AskCancel(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % the incoming DELETE order happens beyond the prevailing inside ask,
    % meaning that it happens deep in the book;
    elseif (AskLOB.Ask_L1(idx-1)==AskLOB.Ask_L1(idx)) && (AskLOB.Ask_Size1(idx-1)==AskLOB.Ask_Size1(idx))
        AsknLL.DeepinBook_AskCancel(k)=1;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    end
elseif Type(k)==4 % when the incoming order is TRADE
    % only consider non-off-market & non-dark trades:
    % buy-initiated trade
    if Qualifiers(k)==1
        AsknLL.nLL_passive_signed_volume(k)=PRICE(k)*VOLUME(k)*(-1);
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % sell-initiated trade
    elseif Qualifiers(k)==-1
        AsknLL.nLL_signed_volume(k)=PRICE(k)*VOLUME(k)*(-1);
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    % unsigned, meaning its either dark trading or off-market trading
    else
        AsknLL.nLL_signed_volume(k)=0;
        disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
    end
elseif Type(k)==6 % when the incoming order is OFFTR
    AsknLL.nLL_signed_volume(k)=0;
    disp(['Completed: ', num2str(k), ' out of ', num2str(length(LLORDASK))]);
end
end
DATA.AsknLL=AsknLL;
clearvars -except DATA;

%% This part only extracts the trade information
TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDASK=DATA(1).LLORDASK;
LLORDASK=sort(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDASK);
% Normal trading hour overlapping periods in two markets in AEDT:
% 10:10AM - 2:35PM

index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((14*60*60)+(35*60))*1000));
LLORDASK=LLORDASK(index); % all orders on the Ask side that are within the overlapping periods;
%% Extract trade informaiiton, where trades are happening in the lit market;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDASK);
id=find(Type(:,1)==4);
LLORDASK=LLORDASK(id);
Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDASK);
idx=find(Qualifiers(:,1)==1 | Qualifiers(:,1)==-1); % these idx indicates only trades at lit markets (no CX trade, no off-market trades etc);
LLORDASK=LLORDASK(idx);

%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDASK);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(LLORDASK);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(LLORDASK);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(LLORDASK);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDASK);
%% construct transaction data;

SellLL = cell2table(cell(0,7), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'nLL_signed_volume', 'LL_passive_signed_volume', 'nLL_passive_signed_volume'});
SellLL.TICKER=num2str(SellLL.TICKER);
% Update the variables in the AskLL upon each order, which is matched
% against the LOB;
LLORDASK=sort(LLORDASK);
for s=1:length(LLORDASK) % # of updates;
    SellLL.TICKER(s,1:3)=TICKER;SellLL.DATE(s)=DATE;
    SellLL.Time(s)=MILLISECONDS(s);
    % buy-initiated trade
    if Qualifiers(s)==1
        SellLL.LL_passive_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(LLORDASK))]);
    % sell-initiated trade
    elseif Qualifiers(s)==-1
        SellLL.LL_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(LLORDASK))]);
    end
end
DATA.SellLL=SellLL;
clearvars -except DATA;
%%
TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDASK=DATA(1).nLLORDASK;
LLORDASK=sort(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDASK);
% Normal trading hour overlapping periods in two markets in AEDT:
% 10:10AM - 2:35PM

index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((14*60*60)+(35*60))*1000));
LLORDASK=LLORDASK(index); % all orders on the Ask side that are within the overlapping periods;
%% Extract trade informaiiton, where trades are happening in the lit market;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDASK);
id=find(Type(:,1)==4);
LLORDASK=LLORDASK(id);
Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDASK);
idx=find(Qualifiers(:,1)==1 | Qualifiers(:,1)==-1); % these idx indicates only trades at lit markets (no CX trade, no off-market trades etc);
LLORDASK=LLORDASK(idx);

%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(LLORDASK);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(LLORDASK);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(LLORDASK);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(LLORDASK);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(LLORDASK);
%% construct transaction data;

SellnLL = cell2table(cell(0,7), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'nLL_signed_volume', 'LL_passive_signed_volume', 'nLL_passive_signed_volume'});
SellnLL.TICKER=num2str(SellnLL.TICKER);
% Update the variables in the AskLL upon each order, which is matched
% against the LOB;
LLORDASK=sort(LLORDASK);
for s=1:length(LLORDASK) % # of updates;
    SellnLL.TICKER(s,1:3)=TICKER;SellnLL.DATE(s)=DATE;
    SellnLL.Time(s)=MILLISECONDS(s);
    % buy-initiated trade
    if Qualifiers(s)==1
        SellnLL.nLL_passive_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(LLORDASK))]);
    % sell-initiated trade
    elseif Qualifiers(s)==-1
        SellnLL.nLL_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(LLORDASK))]);
    end
end
DATA.SellnLL=SellnLL;
clearvars -except DATA;
end