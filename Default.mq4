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
input int    ProfitRange = 1;
extern int pre_time;
extern int   count_bars=0; 
extern double high=0;
extern double low = 0;


int OnInit(){
   pre_time = Time[0];
}


   

datetime NewCandleTime=TimeCurrent();



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
   pre_time = Time[0];
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

   
   for (int i = 0; i<8 ; i++){
      tenkan[i] = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, i);
      kijun[i] = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, i);
       
       }
       
   double ma;
   int    res;
   int    compare_tenkan_higher=0;
   int    compare_tenkan_lower=0;
   int    compare_kijun_higher=0;
   int    compare_kijun_lower=0;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   
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
//--- sell conditions

   if(tenkan[0] = kijun[0] || tenkan[1] < kijun[1] && tenkan[0] > kijun[0]){
   if(compare_tenkan_higher==9 && compare_kijun_higher==9 && tenkan25<Close[24] && kijun25<Close[24])
     {
      res=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
 //---
 }
   
   if(tenkan[0] = kijun[0] || tenkan[1] > kijun[1] && tenkan[0] < kijun[0]){
   if(compare_kijun_lower==9 && compare_kijun_lower==9 && tenkan25>Close[24] && kijun25>Close[24])
     {
      
      res=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"",MAGICMA,0,Red);
     
      return;
     }
   }
//--- buy conditions


//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
  printf("Close");
  
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;

//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      
      printf(Close[0]);
      printf(High[0]);
      
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
        high = High[0];
         while(!Close[0]<=high-ProfitRange){printf("waiting buy settlement");}
         if(Close[0]<=High[0]-ProfitRange)
           {
           printf("buy-settlement");
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               printf("Buy-settlement");
               Print("OrderClose error ",GetLastError());
           }
        }
        
      else if(OrderType()==OP_SELL)
        {
        low = Low[0];
        printf("sell-settlement");
        while(!Close[0]>=low-ProfitRange){printf("waiting sell settlement");}
         if(Close[0]>=Low[0]-ProfitRange)
           {
            printf("Sell-settlement");
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               
               Print("OrderClose error ",GetLastError());
           }
        }
     }
//---
  }

bool isNewBar(string symbol, ENUM_TIMEFRAMES tf)
{
   static datetime time = 0;
   if(iTime(symbol, tf, 0) != time)
   {
      time = iTime(symbol, tf, 0);
      return true;
   }
   return false;
}


//+------------------------------------------------------------------+
//| start function                                                  |
//+------------------------------------------------------------------+

  
//+------------------------------------------------------------------+

void start()
{
if(Bars<100 || IsTradeAllowed()==false)
   return;
      
static datetime time = Time[0];

if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
else{
   
   if(Time[0] != time)
   {
   count_bars++;
   printf("count_bar incremented");
   printf("newbar%d",count_bars);
   time = Time[0];
   }
   
   if(count_bars==25){
   CheckForClose();
   count_bars=0;
   }
}
}


//---