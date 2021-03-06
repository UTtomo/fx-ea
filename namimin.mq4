//+------------------------------------------------------------------+
//|                                                         nami.mq4 |
//|                                                          Tomochi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tomochi"
#property link      "https://www.mql5.com"
#property indicator_color4  Red
#property  indicator_width4  1
double BO1_upper[];

bool   ExtParameters=false;
//#property version   "1.00"
//#property strict
//#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

input int BandPeriod1 = 20;
int OnInit()
  {
  IndicatorDigits(Digits+1);
//--- drawing settings

   SetIndexStyle(3,DRAW_LINE);
   SetIndexDrawBegin(3,BandPeriod1);
   SetIndexBuffer(3,BO1_upper);
   SetIndexLabel(3,"BO1_upper");

      if(BandPeriod1<=1)
     {
      Print("Wrong input parameters");
      ExtParameters=false;
      return(INIT_FAILED);
     }
   else
      ExtParameters=true;
//--- initialization done
   return(INIT_SUCCEEDED);
  }
  
  
  int deinit(){
 return(0);
 }
 
 int start(){
   int BuyCount= 0;
   int SellCount =0;
   int Ticket = 0;
   int ErrCode = 0;
   
   //オーダー情報取得
   for(int i=0; i < OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false){
         return(0);
      }
   //オーダー確認
   if( OrderMagicNumber()!=123456789 || OrderSymbol()!= Symbol()){
      continue;
   }
   //買いポジションカウント
   if( OrderType() == OP_BUY){
   BuyCount++;
   }
   if(OrderType()==OP_SELL){
   SellCount++;
   }
   //オーダーチケット番号取得
   Ticket=OrderTicket();
   //ループを抜ける
   break;
   }
   
   //現在地がボリンジャーバンド＋２σを超えたかつ、リポジションがなければ成行売り
   if( iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_UPPER,0)<Bid && SellCount == 0){
      
      //買いポジションがあれば決済
      if (BuyCount>0){
         OrderClose(Ticket,0.1,Bid,30,Goldenrod);
         ErrCode = GetLastError();
      }
      //レートのリフレッシュ
      RefreshRates();
      
      //エラーがなければ成り行き売り
      if( ErrCode == 0){
         OrderSend(Symbol(),OP_SELL,9,1,Bid,30,0,0,NULL,123456789,Red);
         ErrCode = GetLastError();
       }
    }
    
    //現在地がボリンジャーバンド-2σ未満かつ買いポジションがなければ成行買い
    if( iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_LOWER,0) > Bid && BuyCount == 0){
      //売りポジションがあれば決済
      if( SellCount > 0){
         OrderClose(Ticket,0.1,Ask,30,Goldenrod);
         ErrCode = GetLastError();
      }
      
      //レートのリフレッシュ
      RefreshRates();
      
      //エラーがなければ成行買い
      if( ErrCode == 0){
         OrderSend(Symbol(),OP_BUY,0.1,Ask,30,0,0,NULL,123456789,0,Blue);
         ErrCode = GetLastError();
         
      }
    }
    
    //エラーが有る場合はエラーコードを出力
    if(ErrCode > 0){
      Print("ErrCode="+ErrCode);
    }
    return(0);
    }
  
  
