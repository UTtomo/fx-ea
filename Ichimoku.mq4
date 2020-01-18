//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Average sample expert advisor"

#define MAGICMA  20131111
//--- 表示入力するパラメータ
input double Lots          =0.1;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
input int    MovingPeriod  =12;
input int    MovingShift   =6;
input int    nyan   =6;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break; //保有中のポジションが無いときブレイク
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
      //ポジションを持つ通貨ペアとチャートの通貨ペアが同じ時かつこのプログラムと同じMNを持つとき
        {
         if(OrderType()==OP_BUY)  buys++;//buyのときbuysを１プラス
         if(OrderType()==OP_SELL) sells++;//sellのときsellsを１プラス
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }

//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
     // 転換線
   double tenkan0 = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, 0);
   double tenkan1 = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, 1);
   // 基準線
   double kijun0 = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, 0);
   double kijun1 = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, 1);
   // 先行スパンA
   double spana = iIchimoku(NULL, 0, 9, 26, 52, MODE_SENKOUSPANA, 0);
   // 先行スパンB
   double spanb = iIchimoku(NULL, 0, 9, 26, 52, MODE_SENKOUSPANB, 0);
   // 遅行線
   double chikou = iIchimoku(NULL, 0, 9, 26, 52, MODE_CHINKOUSPAN, 0);
   
   double tenkan[];
   
   for (int k = 0; k<8 ; k++){
      tenkan[k] = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, k);
       Print("tenkan");
       Print(tenkan[k]);
       }
       
   double ma;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell conditions
   if(Open[1]>ma && Close[1]<ma)
     {
      res=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"",MAGICMA,0,Red);
      return;
     }
//--- buy conditions
   if(Open[1]<ma && Close[1]>ma)
     {
      res=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double ma;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(Open[1]>ma && Close[1]<ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(Open[1]<ma && Close[1]>ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| start function                                                  |
//+------------------------------------------------------------------+
void start()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
//---
  }
//+------------------------------------------------------------------+
