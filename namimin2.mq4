//+------------------------------------------------------------------+
//|                                                     namimin2.mq4 |
//|                                                          Tomochi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Tomochi"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
double o = iOpen(NULL,0,0);
double h = iHigh(NULL,0,0);
double c = iClose(NULL,0,0);
double l = iLow(NULL,0,0);
   printf(o);
   printf(h);
   printf(l);
   printf(c);
   
  }
//+------------------------------------------------------------------+
