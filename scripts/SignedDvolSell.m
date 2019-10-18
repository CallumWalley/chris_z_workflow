function [DATA] = SignedDvolSell(file, row)
inputObject = matfile(file);
DATA=inputObject.DATA(1,row);
%% This part only extracts the trade information
TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDASK=DATA(1).LLORDASK;
LLORDASK=sort(LLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDASK);
% Normal trading hour of ASX:
% 10:10AM - 15:50PM
index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((15*60*60)+(50*60))*1000));
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
SellLL = cell2table(cell(0,17), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'KI_signed_volume', 'Pri_signed_volume', 'Int_signed_volume', 'Mixed_signed_volume', 'Clear_signed_volume', 'Unknown_signed_volume', 'LL_passive_signed_volume', 'KI_passive_signed_volume', 'Pri_passive_signed_volume', 'Int_passive_signed_volume', 'Mixed_passive_signed_volume', 'Clear_passive_signed_volume', 'Unknown_passive_signed_volume'});
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

nLLORDASK=DATA(1).nLLORDASK;
nLLORDASK=sort(nLLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(nLLORDASK);
% Normal trading hour of ASX:
% 10:10AM - 15:50PM
index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((15*60*60)+(50*60))*1000));
nLLORDASK=nLLORDASK(index); % all orders on the Ask side that are within the overlapping periods;
%% Extract trade informaiiton, where trades are happening in the lit market;
Type=DATA(1).Type;  % order type;
Type=Type(nLLORDASK);
id=find(Type(:,1)==4);
nLLORDASK=nLLORDASK(id);
Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(nLLORDASK);
idx=find(Qualifiers(:,1)==1 | Qualifiers(:,1)==-1); % these idx indicates only trades at lit markets (no CX trade, no off-market trades etc);
nLLORDASK=nLLORDASK(idx);
%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(nLLORDASK);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(nLLORDASK);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(nLLORDASK);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(nLLORDASK);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(nLLORDASK);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(nLLORDASK);

BUYERTYPE=DATA(1).BUYERTYPE; % Buyer identity
BUYERTYPE=BUYERTYPE(nLLORDASK);

SELLERTYPE=DATA(1).SELLERTYPE; % Seller identity
SELLERTYPE=SELLERTYPE(nLLORDASK);
%% construct transaction data;
SellnLL = cell2table(cell(0,17), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'KI_signed_volume', 'Pri_signed_volume', 'Int_signed_volume', 'Mixed_signed_volume', 'Clear_signed_volume', 'Unknown_signed_volume', 'LL_passive_signed_volume', 'KI_passive_signed_volume', 'Pri_passive_signed_volume', 'Int_passive_signed_volume', 'Mixed_passive_signed_volume', 'Clear_passive_signed_volume', 'Unknown_passive_signed_volume'});
SellnLL.TICKER=num2str(SellnLL.TICKER);
% Update the variables in the AskLL upon each order, which is matched
% against the LOB;
nLLORDASK=sort(nLLORDASK);
for s=1:length(nLLORDASK) % # of updates;
    SellnLL.TICKER(s,1:3)=TICKER;SellnLL.DATE(s)=DATE;
    SellnLL.Time(s)=MILLISECONDS(s);
    % buy-initiated trade
    if Qualifiers(s)==1 && BUYERTYPE(s)==11
        SellnLL.KI_passive_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==22
        SellnLL.Pri_passive_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==33
        SellnLL.Int_passive_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==44
        SellnLL.Mixed_passive_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==55
        SellnLL.Clear_passive_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==66
        SellnLL.Unknown_passive_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    % sell-initiated trade
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==11
        SellnLL.KI_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==22
        SellnLL.Pri_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==33
        SellnLL.Int_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==44
        SellnLL.Mixed_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==55
        SellnLL.Clear_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==66
        SellnLL.Unknown_signed_volume(s)=PRICE(s)*VOLUME(s)*(-1);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDASK))]);
    end
end
DATA.SellnLL=SellnLL;
clearvars -except DATA;
end