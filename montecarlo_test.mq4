
#property copyright "モンテカルロ　テスト" 

//+---------------------------------------------------------------------+
//				パラメーター設定
//+---------------------------------------------------------------------+

int Direction=2;

int MAGIC = 0;
int Slippage=3;

extern int StepPips=20;//pips間隔
extern int rangeHalfPer=10;//MA

extern double BaseLots=0.01;
int takeprofit=10;
int stoploss=0;


//その他項目 
double Lots;

int RV; //Return Value
int C[1000]={1,2,3}; //Column
int Count=3;
int Bet = 4;
int Ticket;
datetime OldTime;
double OrderPrice;
double OrderLot;
double TP;
int SLP=0;
bool sell=False;
bool buy = False;



//+---------------------------------------------------------------------+
//				一般関数
//+---------------------------------------------------------------------+

double AdjustPoint(string Currency)//ポイント調整
{
	 int Symbol_Digits=MarketInfo(Currency,MODE_DIGITS);
	 double Calculated_Point=0;
	 if (Symbol_Digits==2 || Symbol_Digits==3)
	 {
		 Calculated_Point=0.01;
	 }
	 else if (Symbol_Digits==4 || Symbol_Digits==5)
	 {
		 Calculated_Point=0.0001;
	 }
	 return(Calculated_Point);
}

int AdjustSlippage(string Currency,int Slippage_pips )//スリッページ調整
{
	 int Calculated_Slippage=0;
	 int Symbol_Digits=MarketInfo(Currency,MODE_DIGITS);
	 if (Symbol_Digits==2 || Symbol_Digits==3)
	 {
		 Calculated_Slippage=Slippage_pips;
	 }
	 else if (Symbol_Digits==4 || Symbol_Digits==5)
	 {
		 Calculated_Slippage=Slippage_pips*10;
	 }
	 return(Calculated_Slippage); 
}

//オーダーキャンセル関数
void CancelOrder(int CancelPosition) 
{
	 for(int i=OrdersTotal()-1;i>=0;i--)
	 {
		 int res;
		 if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==MAGIC && OrderSymbol()==Symbol())
		 {
			 if( (OrderType()==OP_SELLLIMIT || OrderType()==OP_SELLSTOP) && CancelPosition==-1) //売りオーダーのキャンセル
			 {
				 res=OrderDelete(OrderTicket(),Silver);
			 }
			 else if( (OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP) && CancelPosition==1)  //買いオーダーのキャンセル
			 {
				 res=OrderDelete(OrderTicket(),Silver);
			 }
		 }
	 }
}

//+---------------------------------------------------------------------+
//				イニシャル処理
//+---------------------------------------------------------------------+

void init()
{
	 //注文をすべてキャンセル
	 CancelOrder(1);
	 CancelOrder(-1);
	 TP=takeprofit*AdjustPoint(Symbol()); 
    SLP=AdjustSlippage(Symbol(),Slippage ); 
    
}

//+---------------------------------------------------------------------+
//				ティック毎の処理
//+---------------------------------------------------------------------+
void start()
{
    
   
	 
	 // ニューバーの発生直後以外は取引しない 
	 static datetime bartime=Time[0]; 
	 if (Time[0]==bartime) return; 
	 bartime=Time[0]; 
	 
	 int total = OrdersTotal();
	 if(total >= 1){
	   // TakeProfit
      if(buy && (OrderPrice + TP < Ask))
      {
         RV = OrderClose(Ticket,OrderLot,Bid,SLP);
         
         if(RV){
            if (Count <= 3)
            {
               Count = 3;
               C[0] = 1;
               C[1] = 2;
               C[2] = 3;
               for(int j=3;j<=999;j++)
               {
                  C[j]=0;
               }
               Bet = 4;
            }
            else
            {
               for(int i=0;i < Count-2;i++) {
                  C[i]=C[i+1];
            }
               C[Count-2] = 0;
               C[Count-1] = 0;
               Bet = C[0] + C[Count-3];
               Count-=2;
            }
         }
      }
      // StopLoss
      if(buy && (OrderPrice - TP > Bid))
      {
      RV = OrderClose(Ticket,OrderLot,Bid,SLP);
      if (RV){
         C[Count] = Bet;
         Bet = C[0]+C[Count];
         Count++;
         }
      }
     //close sell
     if(sell && (OrderPrice + TP > Bid))
      {
         RV = OrderClose(Ticket,OrderLot,Ask,SLP);
         
         if(RV){
            if (Count <= 3)
            {
               Count = 3;
               C[0] = 1;
               C[1] = 2;
               C[2] = 3;
               for(j=3;j<=999;j++)
               {
                  C[j]=0;
               }
               Bet = 4;
            }
            else
            {
               for(i=0;i < Count-2;i++) {
                  C[i]=C[i+1];
            }
               C[Count-2] = 0;
               C[Count-1] = 0;
               Bet = C[0] + C[Count-3];
               Count-=2;
            }
         }
      }
      // StopLoss
      if(sell && (OrderPrice - TP < Ask))
      {
      RV = OrderClose(Ticket,OrderLot,Ask,SLP);
      if (RV){
         C[Count] = Bet;
         Bet = C[0]+C[Count];
         Count++;
         }
      }
         
    }
    
	 
	 if(total == 0){
   
   	 
   	 double rangeHalf=iMA(NULL,NULL,rangeHalfPer,0,MODE_SMA,PRICE_CLOSE,0);
   	 double lastValue=iClose(NULL,0,1);
   	 
   	 
   	 if ((lastValue - rangeHalf) > StepPips*AdjustPoint(Symbol())){
   	   Ticket = OrderSend(Symbol(),OP_SELL,BaseLots*Bet,Bid,SLP,0,0,NULL,MAGIC);
         Print("Bet: " + Bet+" Cout: "+Count);
         OrderPrice = Bid;
         OrderLot = BaseLots * Bet;
         sell = True;
   	 }
   	 if ((-lastValue + rangeHalf) > StepPips*AdjustPoint(Symbol())){
   	   Ticket = OrderSend(Symbol(),OP_BUY,BaseLots*Bet,Ask,SLP,0,0,NULL,MAGIC);
         Print("Bet: " + Bet+" Cout: "+Count);
         OrderPrice = Ask;
         OrderLot = BaseLots * Bet;
         buy = True;
   	 }
   	 
   }
   	





}
