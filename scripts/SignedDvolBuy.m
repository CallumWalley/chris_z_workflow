function [DATA] = SignedDvolBuy(file, row)
inputObject = matfile(file);
DATA=inputObject.DATA(1,row);
%% This part only extracts the trade information
TICKER=DATA(1).TICKER;
DATE=DATA(1).DATE;

LLORDBID=DATA(1).LLORDBID;
LLORDBID=sort(LLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(LLORDBID);
% Normal trading hour of ASX:
% 10:10AM - 15:50PM
index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((15*60*60)+(50*60))*1000));
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
BuyLL = cell2table(cell(0,17), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'KI_signed_volume', 'Pri_signed_volume', 'Int_signed_volume', 'Mixed_signed_volume', 'Clear_signed_volume', 'Unknown_signed_volume', 'LL_passive_signed_volume', 'KI_passive_signed_volume', 'Pri_passive_signed_volume', 'Int_passive_signed_volume', 'Mixed_passive_signed_volume', 'Clear_passive_signed_volume', 'Unknown_passive_signed_volume'});
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

nLLORDBID=DATA(1).nLLORDBID;
nLLORDBID=sort(nLLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS;
MILLISECONDS=MILLISECONDS(nLLORDBID);
% Normal trading hour of ASX:
% 10:10AM - 15:50PM
index=find((MILLISECONDS(:,1)>=((10*60*60)+(10*60))*1000) & (MILLISECONDS(:,1)<=((15*60*60)+(50*60))*1000));
nLLORDBID=nLLORDBID(index); % all orders on the Ask side that are within the overlapping periods;
%% Extract trade informaiiton, where trades are happening in the lit market;
Type=DATA(1).Type;  % order type;
Type=Type(nLLORDBID);
id=find(Type(:,1)==4);
nLLORDBID=nLLORDBID(id);
Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(nLLORDBID);
idx=find(Qualifiers(:,1)==1 | Qualifiers(:,1)==-1); % these idx indicates only trades at lit markets (no CX trade, no off-market trades etc);
nLLORDBID=nLLORDBID(idx);
%% Get all properties of the above order LLORDASK;
Type=DATA(1).Type;  % order type;
Type=Type(nLLORDBID);

PRICE=DATA(1).PRICE; % price of the order;
PRICE=PRICE(nLLORDBID);

VOLUME=DATA(1).VOLUME; % size of the order;
VOLUME=VOLUME(nLLORDBID);

MILLISECONDS=DATA(1).MILLISECONDS; % timestamp of the order;
MILLISECONDS=MILLISECONDS(nLLORDBID);

Direction=DATA(1).Direction; % direction of the order: a BID or ASK order;
Direction=Direction(nLLORDBID);

Qualifiers=DATA(1).Qualifiers; % direction of the Trade: a BUY or SELL;
Qualifiers=Qualifiers(nLLORDBID);

BUYERTYPE=DATA(1).BUYERTYPE; % Buyer identity
BUYERTYPE=BUYERTYPE(nLLORDBID);

SELLERTYPE=DATA(1).SELLERTYPE; % Seller identity
SELLERTYPE=SELLERTYPE(nLLORDBID);
%% construct transaction data;
BuynLL = cell2table(cell(0,17), 'VariableNames', {'TICKER', 'DATE', 'Time', 'LL_signed_volume', 'KI_signed_volume', 'Pri_signed_volume', 'Int_signed_volume', 'Mixed_signed_volume', 'Clear_signed_volume', 'Unknown_signed_volume', 'LL_passive_signed_volume', 'KI_passive_signed_volume', 'Pri_passive_signed_volume', 'Int_passive_signed_volume', 'Mixed_passive_signed_volume', 'Clear_passive_signed_volume', 'Unknown_passive_signed_volume'});
BuynLL.TICKER=num2str(BuynLL.TICKER);
% Update the variables in the AskLL upon each order, which is matched
% against the LOB;
nLLORDBID=sort(nLLORDBID);
for s=1:length(nLLORDBID) % # of updates;
    BuynLL.TICKER(s,1:3)=TICKER;BuynLL.DATE(s)=DATE;
    BuynLL.Time(s)=MILLISECONDS(s);
    % buy-initiated trade
    if Qualifiers(s)==1 && BUYERTYPE(s)==11
        BuynLL.KI_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==22
        BuynLL.Pri_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==33
        BuynLL.Int_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==44
        BuynLL.Mixed_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==55
        BuynLL.Clear_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==1 && BUYERTYPE(s)==66
        BuynLL.Unknown_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    % sell-initiated trade
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==11
        BuynLL.KI_passive_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==22
        BuynLL.Pri_passive_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==33
        BuynLL.Int_passive_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==44
        BuynLL.Mixed_passive_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==55
        BuynLL.Clear_passive_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    elseif Qualifiers(s)==-1 && SELLERTYPE(s)==66
        BuynLL.Unknown_passive_signed_volume(s)=PRICE(s)*VOLUME(s);
        disp(['Completed: ', num2str(s), ' out of ', num2str(length(nLLORDBID))]);
    end
end
DATA.BuynLL=BuynLL;
clearvars -except DATA;
end