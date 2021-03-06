//Directionを3に変更するとトレンドフォロー型
//Directionが0の時は取引を中断


#property copyright "テスト" 

//+---------------------------------------------------------------------+
//				パラメーター設定
//+---------------------------------------------------------------------+

int Direction=2;

int MAGIC = 0;
int Slippage=3;

extern double RangeMax=140;
extern double RangeMin=100;
int OrderRange=100;

extern int StepPips=20;//pips間隔
extern int rangeHalfPer=10;//MA

extern double BaseLots=0.20;
int takeprofit=10;
int stoploss=0;
input int margin = 3;

extern int LotsAdjustPer=20;//Pips間隔 
double LotsAdjustPer3=10;//最大加算回数 

//その他項目 
double Lots;
double band_bottom,band_up;
double short_ave,mid_ave,long_ave;


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

double AdjustValByPips(double BeforeAdjustVal)
{
	 double Num=0;
	 double ret=0;
	 Num=MathRound(   (BeforeAdjustVal-RangeMin) / (StepPips*AdjustPoint(Symbol()))   );
	 ret=RangeMin+(Num*  (StepPips*AdjustPoint( Symbol() )  )   );  
	 return (ret);
}
int LongPosition()//ロングポジション数を取得
{
	 int buys=0;
	 for(int i=0;i<OrdersTotal();i++)
	 {
		 if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
		 {
			 if(OrderType()==OP_BUY)  buys++;
		 }
	 }
	 return(buys);
}

int ShortPosition()//ショートポジション数を取得
{
	 int sells=0;
	 for(int i=0;i<OrdersTotal();i++)
	 {
		 if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
		 {
			 if(OrderType()==OP_SELL) sells++;
		 }
	 }
	 return(sells);
}

int LongOrder()//ロング注文数を取得
{
	 int buys=0;
	 for(int i=0;i<OrdersTotal();i++)
	 {
		 if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
		 {
			 if(OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP)  buys++;
		 }
	 }
	 return(buys);
}

int ShortOrder()//ショート注文数を取得
{
	 int sells=0;
	 for(int i=0;i<OrdersTotal();i++)
	 {
		 if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
		 {
			 if(OrderType()==OP_SELLLIMIT || OrderType()==OP_SELLSTOP ) sells++;
		 }
	 }
	 return(sells);
}

//ポジション数調整関数 
double LotsAdjustment(double startPrice, double targetPrice, double Base, int everyPips, double addLots, int maxTimes)
{
	 int addTimes=MathFloor ( MathAbs(startPrice-targetPrice) / (everyPips*AdjustPoint(Symbol()) )  )  ; 
	 if (addTimes>maxTimes ) addTimes=maxTimes;
	 double LotSize= Base + (addLots * addTimes);
	 if (LotSize<=MarketInfo(Symbol(),MODE_MINLOT))
	 {
		 LotSize=MarketInfo(Symbol(),MODE_MINLOT);
	 }
	 else if (LotSize>=MarketInfo(Symbol(),MODE_MAXLOT))
	 {
		 LotSize=MarketInfo(Symbol(),MODE_MAXLOT);
	 }
	 return(LotSize);
}

//+---------------------------------------------------------------------+
//				エグジット関連関数
//+---------------------------------------------------------------------+

//ポジションクローズ関数
void CloseOrder(int ClosePosition)
{
	 for(int i=OrdersTotal()-1;i>=0;i--)
	 {
		 int res;
		 if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
		 {
			 if(OrderMagicNumber()==MAGIC && OrderSymbol()==Symbol())
			 {
				 if(OrderType()==OP_SELL && (ClosePosition==-1 || ClosePosition==0 )) //売りポジションのクローズ
				 {
					 res=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),10,Silver);
				 }
				 else if(OrderType()==OP_BUY && (ClosePosition==1 || ClosePosition==0 ) ) //買いポジションのクローズ
				 {
					 res=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),10,Silver);
				 }
			 }
		 }
	 }
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
//				　インジケーター
//+---------------------------------------------------------------------+
//+---------------------------------------------------------------------+
//				取引中断
//+---------------------------------------------------------------------+


void CheckDirection()
{
   
   band_up = iBands(NULL,0,80,2,0,PRICE_CLOSE,1,0);
   band_bottom = iBands(NULL,0,80,2,0,PRICE_CLOSE,2,0);
   short_ave=iMA(NULL,0,20,0,MODE_SMA,PRICE_CLOSE,0);
   mid_ave=iMA(NULL,0,80,0,MODE_SMA,PRICE_CLOSE,0);
   long_ave=iMA(NULL,0,320,0,MODE_SMA,PRICE_CLOSE,0);
   
   if(
       (short_ave > band_bottom) && (short_ave < band_up) &&
       (mid_ave > band_bottom) && (mid_ave < band_up) &&
       (long_ave > band_bottom) && (long_ave < band_up) &&
       (Close[0] > band_up + margin*AdjustPoint(Symbol())) && Direction == 2
       
       ){
       Direction = 0;
       return;
       }
   if(
       (short_ave > band_bottom) && (short_ave < band_up) &&
       (mid_ave > band_bottom) && (mid_ave < band_up) &&
       (long_ave > band_bottom) && (long_ave < band_up) &&
       (Close[0] < band_bottom + margin*AdjustPoint(Symbol())) && Direction==2
       
       ){
       Direction = 0;
       return;
       } 
       
   if(Direction == 0 && Close[0] > band_bottom && Open[0] > band_bottom && Close[0] < band_up && Close[0] < band_up){
      Direction = 2;
      return;
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
	 
	 CheckDirection();
	 
	 
	 
	 int EntryBuy=0;
	 int EntrySell=0;
	 int ExitBuy=0;
	 int ExitSell=0;
	 
	 
	 int LongNum=LongPosition();
	 int ShortNum=ShortPosition();
	 int LongOrderNum=LongOrder();
	 int ShortOrderNum=ShortOrder();
	 
	 double rangeHalf=iMA(NULL,1440,rangeHalfPer,0,MODE_SMA,PRICE_CLOSE,0);
	 double lastValue=iClose(NULL,0,1);
	 if(Direction==2)
	 {
		 if(lastValue>rangeHalf) 
		 { 
		 EntrySell=1; 
		 } 
		 else 
		 { 
		 EntryBuy=1; 
		 } 
	 }
	 
	 
	 //クローズロジックは選択されていません
	 
	 //クローズ判定
	 //買いのクローズロジックは選択されていません
	 //売りのクローズロジックは選択されていません

	 int Strtagy=0;
	 if (EntryBuy==1) Strtagy=1 ; 
	 if (EntrySell==1) Strtagy=-1 ; 

	 //方向が違う場合にはポジション決済 
	 if (LongNum!=0 && (EntrySell==1 || Strtagy==-99  || Direction==-99 ) )  
	 { 
		 CloseOrder(1);
		 LongNum=LongPosition();
	 } 

	 if (ShortNum!=0 && ( EntryBuy==1 || Strtagy==-99 || Direction==-99 ) )  
	 { 
		 CloseOrder(-1);
		 ShortNum=ShortPosition();
	 } 


	 //エントリ方向又はフィルターとトラップの向きが違う場合は全注文キャンセル 
	 if ((LongOrderNum!=0 && EntrySell==1 ) | Direction ==0)
	 { 
		 CancelOrder(1);
		 LongOrderNum=0;
	 } 

	 if ((ShortOrderNum!=0 && EntryBuy==1 ) | Direction == 0) 
	 { 
		 CancelOrder(-1);
		 ShortOrderNum=0;
	 } 

	 if (LongNum!=0 && Strtagy==-1)  
	 { 
		 CancelOrder(1);
		 LongOrderNum=0;
	 } 

	 if (ShortNum!=0 && Strtagy==1)  
	 { 
		 CancelOrder(-1);
		 ShortOrderNum=0;
	 } 

	 if (Strtagy==0 && (LongOrderNum!=0 || ShortOrderNum!=0)  ) 
	 { 
		 CancelOrder(1);
		 LongOrderNum=0;
		 CancelOrder(-1);
		 ShortOrderNum=0;
	 } 


	 //注文がレンジ範囲外の場合にはトラップを範囲外のトラップをキャンセル 
	 double OrderRangeMin; 
	 double OrderRangeMax; 
	 double CurrentPrice=0; 
	 if (EntryBuy==1) CurrentPrice=Bid; 
	 if (EntrySell==1) CurrentPrice=Ask; 
	 OrderRangeMin=CurrentPrice-(OrderRange*0.5)*AdjustPoint(Symbol()); 
	 OrderRangeMax=CurrentPrice+(OrderRange*0.5)*AdjustPoint(Symbol()); 

	 int res; 
	 int i; 
	 for(i=OrdersTotal()-1;i>=0;i--) 
	{ 
		 if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC)
		 {
			 if( (OrderType()==OP_SELLLIMIT || OrderType()==OP_SELLSTOP) &&  ( (RangeMin>OrderOpenPrice() || OrderOpenPrice()>RangeMax ) || (OrderRangeMin>OrderOpenPrice() || OrderOpenPrice()>OrderRangeMax ) )  )//売りオーダーのキャンセル 
			 {
				 res=OrderDelete(OrderTicket(),Silver);
				 ShortOrderNum=ShortOrderNum-1;
			 }
			 else if( (OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP)  && ( (RangeMin>OrderOpenPrice() || OrderOpenPrice()>RangeMax ) || (OrderRangeMin>OrderOpenPrice() || OrderOpenPrice()>OrderRangeMax ) ) ) //買いオーダーのキャンセル
			 {
				 res=OrderDelete(OrderTicket(),Silver);
				 LongOrderNum=LongOrderNum-1;
			 }
		 }
	 } 

   if (Direction ==2){
	 // 
	 //トラップを張る 
	 // 
   	 int SLP=AdjustSlippage(Symbol(),Slippage ); 
   	 double OrderPrice; 
   	 double TP=0; 
   	 double SL=0; 
   	 int size=0; 
   	 double rangeArray[]; 
   	 double positionArray[]; 
   
   	 //オーダー範囲内の金額を配列に記録 
   	 for(i=0; RangeMax>RangeMin+((StepPips*i)*AdjustPoint(Symbol())); i++ ) 
   	 { 
   		 OrderPrice=RangeMin+((StepPips*i)*AdjustPoint(Symbol())); 
   		 if (OrderRangeMin<OrderPrice && OrderPrice<OrderRangeMax )  
   		 { 
   			 size=ArraySize(rangeArray)+1; 
   			 ArrayResize(rangeArray,size); 
   			 rangeArray[size-1]=OrderPrice; 
   		 } 
   	 } 
   	 //注文ずみを配列に記録 
   	 for(i=OrdersTotal()-1;i>=0;i--) 
   	 { 
   		 if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC && OrderCloseTime()==0 ) 
   		 { 
   			 size=ArraySize(positionArray)+1; 
   			 ArrayResize(positionArray,size); 
   			 if(EntryBuy==1) positionArray[size-1]=AdjustValByPips(OrderOpenPrice()); 
   			 if(EntrySell==1) positionArray[size-1]=AdjustValByPips(OrderOpenPrice()); 
   		 } 
   	 } 
   	 //オーダー範囲内にあるのにpositionがない場合に注文追加 
   	 double search; 
   	 int ret; 
   	 for(i=0;i<ArraySize(rangeArray)-1;i++) 
   	 { 
   		 search=AdjustValByPips(rangeArray[i]); 
   		 ret=0; 
   		 for(int j=0;j<ArraySize(positionArray)-1;j++) 
   		 { 
   			 if (positionArray[j]==search && ret==0) 
   			 { 
   				 ret=1; 
   				 break; 
   			 } 
   		 } 
   		  
   		 if (ret==0) 
   		 { 
   			 OrderPrice=search; 
   			 //ロットサイズ調整 
   			 Lots=LotsAdjustment(rangeHalf,OrderPrice,BaseLots,LotsAdjustPer,0.5*BaseLots,LotsAdjustPer3);//一定間隔毎に一定ロットを加算
   			 if (EntryBuy==1 && Strtagy==1 ) 
   			 { 
   				 TP=OrderPrice+(takeprofit*AdjustPoint(Symbol())); 
   				 if(stoploss!=0) SL=OrderPrice-(stoploss*AdjustPoint(Symbol())); 
   				 if (OrderPrice<Bid ) 
   				 { 
   					 //指値 
   					 res=OrderSend(Symbol(),OP_BUYLIMIT,Lots ,OrderPrice,SLP,SL,TP,"test",MAGIC,0,Red); 
   				 } 
   				 else 
   				 { 
   					 //逆指値 
   					 res=OrderSend(Symbol(),OP_BUYSTOP,Lots ,OrderPrice,SLP,SL,TP,"test",MAGIC,0,Red); 
   				 } 
   			 } 
   			  
   			 if (EntrySell==1 && Strtagy==-1 ) 
   			 { 
   				 TP=OrderPrice-(takeprofit*AdjustPoint(Symbol())); 
   				 if(stoploss!=0) SL=OrderPrice+(stoploss*AdjustPoint(Symbol())); 
   				 if (OrderPrice>Ask) 
   				 { 
   					 //指値 
   					 res=OrderSend(Symbol(),OP_SELLLIMIT,Lots ,OrderPrice,SLP,SL,TP,"test",MAGIC,0,Red); 
   				 } 
   				 else 
   				 { 
   					 //逆指 
   					 res=OrderSend(Symbol(),OP_SELLSTOP,Lots ,OrderPrice,SLP,SL,TP,"test",MAGIC,0,Red); 
   				 } 
   			 } 
   		 } 
   	 }
   	}
}

