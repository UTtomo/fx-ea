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
input int    ProfitRange = 10;
extern int pre_time;

int OnInit(){
   pre_time = Time[0];
}

   
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
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=OrdersHistoryTotal();     //アカウント履歴の決済済みのポジション数をordersに格納
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);//少数桁現在アカウントの余剰証拠金に色々掛けて、小数点１位で四捨五入したものをlotに代入
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
  pre_time = Time[0];
     // 転換線
   double tenkan0 = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, 0);
   double tenkan25 = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, 24);

   // 基準線
   double kijun0 = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, 0);
   double kijun25 = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, 24);


   // 先行スパンA
   double spana = iIchimoku(NULL, 0, 9, 26, 52, MODE_SENKOUSPANA, 0);
   // 先行スパンB
   double spanb = iIchimoku(NULL, 0, 9, 26, 52, MODE_SENKOUSPANB, 0);
   // 遅行線
   double chikou = iIchimoku(NULL, 0, 9, 26, 52, MODE_CHINKOUSPAN, 0);
   
   double tenkan[9],kijun[9];
   int demo;
  
   for(int i=0; i <=8; i++){
       tenkan[i] = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, i);
       kijun[i] = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, i);
   }
   
       
   double ma;
   int    res;

   
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   int    compare_tenkan_higher=0;
   int    compare_tenkan_lower=0;
   int    compare_kijun_higher=0;
   int    compare_kijun_lower=0;

      for(int k=0;k<=8;k++){
         if(tenkan[k]>=Close[k]){
            compare_tenkan_higher++;
            
         }
         else {
            compare_tenkan_lower++;
         }
         if(kijun[k]>=Close[k]){
            compare_kijun_higher++;
            
         }
         else {
            compare_kijun_lower++;
             
         }
      }
      
//--- sell conditions
   if(tenkan[0] = kijun[0] || tenkan[1] > kijun[1] && tenkan[0] < kijun[0]){
   if(compare_kijun_lower==9 && compare_kijun_lower==9 && tenkan25>Close[24] && kijun25>Close[24])
     {
      printf(compare_kijun_lower);
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
     
      return;
     }
   }
//--- buy conditions


   if(tenkan[0] = kijun[0] || tenkan[1] < kijun[1] && tenkan[0] > kijun[0]){
   if(compare_tenkan_higher==9 && compare_kijun_higher==9 && tenkan25>Close[24] && kijun25>Close[24])
     {
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
   else{
      return;
   }
   }
//---
   }
  
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   int   count_bars=0; 
   double low;
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
         if(Close[0]<=High[0]-ProfitRange)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(Close[0]<=Low[0]-ProfitRange)
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
