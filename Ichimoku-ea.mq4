//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2020 Ichimoku-EA"
#property description "Ichimoku indicator expert advisor"
#define MAGICMA  20201111
#property strict

//--- 表示入力するパラメータ(初期値)
//ロット
input double Lots          =0.1;
//トレイリングストップの「一定の幅」の指定
input double ProfitRange = 0.1;
//計測するバーの数
input int count = 9;

// 各種変数の定義
datetime pre_time;
int   count_bars=0; 
double high=0;
double low = 0;
int count_candle = 1;

// 転換線
double tenkan0 = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, 0);
double tenkan25 = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, 24);
// 基準線
double kijun0 = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, 0);
double kijun25 = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, 24);
// 遅行線
double chikou = iIchimoku(NULL, 0, 9, 26, 52, MODE_CHINKOUSPAN, 0);
// 先行スパンA
double spana = iIchimoku(NULL, 0, 9, 26, 52, MODE_SENKOUSPANA, 0);
// 先行スパンB
double spanb = iIchimoku(NULL, 0, 9, 26, 52, MODE_SENKOUSPANB, 0);
   

//+------------------------------------------------------------------+
//|最初に読まれる関数                                  |
//+------------------------------------------------------------------+
void OnInit()
{
// pre_time に　バーが更新されてからたった時間を代入
   pre_time = Time[0];
}






//+------------------------------------------------------------------+
//|オーダーを数える関数                                  |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
   
//---ポジションの数をカウント
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
//| オーダーを出す関数                               |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   pre_time = Time[0];

   
   double tenkan[9]={},kijun[9]={};

   //一目均衡表の転換線や基準線の直近の９本の値を配列に代入
   for (int i = 0; i<count ; i++){
      tenkan[i] = iIchimoku(NULL, 0, 9, 26, 52, MODE_TENKANSEN, i);
      kijun[i] = iIchimoku(NULL, 0, 9, 26, 52, MODE_KIJUNSEN, i);
       
       }

   int    order;
   int    compare_tenkan_higher=0;
   int    compare_tenkan_lower=0;
   int    compare_kijun_higher=0;
   int    compare_kijun_lower=0;
//--- 新しいバーが更新されたときのみ、注文を出す
   if(Volume[0]>1) return;
//　転換線と終値を比較し、直近９本で高かった/低かった数を計測
   
   for(int k=0;k<=count;k++){
      if(tenkan[k]>=Close[k]){
         compare_tenkan_higher++;
      }
      else {
         compare_tenkan_lower++;
      }
   }
   for(int j=0; j<count; j++){
      if(kijun[j]>=Close[j]){
         compare_kijun_higher++;
            
      }
      else {
         compare_kijun_lower++;            
         }
   }


//--- 買条件


   if(tenkan[0] == kijun[0] || ( tenkan[1] < kijun[1] && tenkan[0] > kijun[0])){
   printf("buy condition");
   if(compare_tenkan_higher==count && compare_kijun_higher==count && chikou<Close[24])
     {
     printf("buy");
      order=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
 //---売条件
 }
   
   if(tenkan[0] == kijun[0] || ( tenkan[1] > kijun[1] && tenkan[0] < kijun[0] )){
   printf("sell condition");
   if(compare_kijun_lower==count && compare_kijun_lower==count && chikou>Close[24])
     {
      printf("sell");
      order=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"",MAGICMA,0,Red);
     
      return;
     }
   }

  }
  
  

     


  
//+------------------------------------------------------------------+
//| ポジションを決済する関数                               |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   
   
  printf("CloseProgram");
  
//--- 新しいローソク足が出てきたとき
   if(Volume[0]>1) return;

//---すべてのポジションを安全に決済できるようにループ処理
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      
      
      
      //--- 買いポジションのとき
      if(OrderType()==OP_BUY)
        {
         printf("BuyClosed");
         if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
            Print("OrderClose error ",GetLastError());    
        }
        
      //--- 売りポジションのとき
      else if(OrderType()==OP_SELL)
        {
         printf("SellClosed");  
         if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))   
            Print("OrderClose error ",GetLastError());
        }
     }
     
//---
  }



//+------------------------------------------------------------------+
//| start function →　常に読まれる。                                              |
//+------------------------------------------------------------------+

  
//+------------------------------------------------------------------+

void start()
{
double o = Open[1];
double h = High[1];
double c = Close[1];
double l = Low[1];


if(Bars<100 || IsTradeAllowed()==false)
   return;
      
static datetime time = Time[0];

//--- ポジションが０のとき

if(CalculateCurrentOrders(Symbol())==0){
   CheckForOpen();
   
   }
//--- 買いエントリーロスカット
else if(Close[1]< spana || Close[1]< spanb ){
 if(OrderType()==OP_BUY){
     printf("買いエントリーロスカット");
     if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
     Print("OrderClose error ",GetLastError());
 }  
}
//--- 売りエントリーロスカット
else if(Close[1]< spana || Close[1]< spanb ){
 if(OrderType()==OP_SELL){
     printf("売りエントリーロスカット");
     if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))   
     Print("OrderClose error ",GetLastError());
 }  
   
}
//--トレイリングストップの条件
else{
   // エントリー後のバーの計測
   if(Time[0] != time)
   {
   count_bars++;
   printf("count_bar incremented");
   printf("newbar%d",count_bars);
   time = Time[0];
   }
   
   // バーの数が25本になったら
   if(count_bars>=25){
   count_candle++;
   //買エントリーのトレイリングストップ条件を満たすとき
   if(OrderType()==OP_BUY && High[count_candle]-ProfitRange<Close[1]){
   CheckForClose();
   count_bars=0;
   count_candle=1;
   }
   //売エントリーのトレイリングストップ条件を満たすとき
   else if(OrderType()==OP_SELL && Low[count_candle]+ProfitRange>Close[1]){
   CheckForClose();
   count_bars=0;
   count_candle=1;
   }
   }
   
}
}