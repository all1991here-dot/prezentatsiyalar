// EURUSD MicroSafe M1 Pro — experimental demo-first strategy, no promised win rate.
#property strict
#property version "1.00"
#property description "Closed-bar M15/M5 trend, M1 pullback confirmation. Demo validation required."
#include <Trade/Trade.mqh>
input ulong InpMagic=206101;
input bool InpAllowRealAccount=false;
input double InpRiskPercent=0.5;
input double InpDailyLossPercent=2.0;
input int InpMaxConsecutiveLosses=3;
input int InpLossCooldownMinutes=60;
input double InpMaxSpreadPips=1.2;
input double InpMaxSpreadToStop=0.20;
input double InpMinATRPips=0.8;
input double InpMaxATRPips=8.0;
input double InpMinADX=18.0;
input double InpMinStopPips=5.0;
input double InpMaxStopPips=15.0;
input double InpStopATR=1.5;
input double InpRewardRisk=1.5;
input double InpBreakEvenR=1.0;
input double InpBreakEvenOffsetPips=0.3;
input double InpTrailStartR=1.25;
input double InpTrailATR=1.5;
input double InpCommissionPerLot=7.0; // round trip, account currency / 1.0 lot; verify broker
input double InpRiskReservePercent=10.0;
input double InpFreeMarginReservePercent=20.0;
input int InpStartHour=7; // broker server time, not local time
input int InpEndHour=20; // flatten at end of session
input int InpFridayStopHour=16;
input int InpFridayCloseHour=19;
input int InpDeviationPoints=5;
input int InpMaxTickAgeSeconds=5;
input int InpReconnectQuietSeconds=60;
input int InpEntryWindowSeconds=5;

// BEGIN PORTABLE LOGIC
// Platform-independent functions below are shared verbatim with offline tests.
// A direction is a deterministic rule outcome, NEVER a calibrated probability.
struct MSBar { double open; double high; double low; double close; };
struct MSFeatures
{
   double m15fast,m15slow,m15previous;
   double m5fast,m5slow,adx,diPlus,diMinus;
   double emaNow,emaPrevious,atr;
   MSBar signal,pullback;
};
int MSDirection(const MSFeatures &f,double minADX,int &reason)
{
   reason=0;
   if(!MathIsValidNumber(f.atr) || !MathIsValidNumber(f.adx) || f.atr<=0 ||
      f.signal.high<=f.signal.low || f.pullback.high<f.pullback.low)
   { reason=1; return 0; }
   double range=f.signal.high-f.signal.low;
   if(MathAbs(f.signal.close-f.signal.open)<0.40*range || range>2.5*f.atr)
   { reason=2; return 0; }
   if(f.adx<minADX) { reason=3; return 0; }
   bool up=f.m15fast>f.m15slow && f.m15fast>f.m15previous &&
      f.m5fast>f.m5slow && f.diPlus>f.diMinus;
   bool down=f.m15fast<f.m15slow && f.m15fast<f.m15previous &&
      f.m5fast<f.m5slow && f.diMinus>f.diPlus;
   bool longEntry=f.pullback.low<=f.emaPrevious+0.15*f.atr &&
      f.pullback.high>=f.emaPrevious-0.15*f.atr &&
      f.signal.close>f.emaNow && f.signal.close>f.signal.open && f.signal.close>f.pullback.high;
   bool shortEntry=f.pullback.high>=f.emaPrevious-0.15*f.atr &&
      f.pullback.low<=f.emaPrevious+0.15*f.atr &&
      f.signal.close<f.emaNow && f.signal.close<f.signal.open && f.signal.close<f.pullback.low;
   if(up && longEntry) return 1;
   if(down && shortEntry) return -1;
   reason=4; return 0;
}
double MSVolume(double budget,double minLotLoss,double vmin,double vmax,double step)
{
   if(!MathIsValidNumber(budget) || !MathIsValidNumber(minLotLoss) || !MathIsValidNumber(vmin) ||
      !MathIsValidNumber(vmax) || !MathIsValidNumber(step) ||
      budget<=0 || minLotLoss<=0 || vmin<=0 || vmax<vmin || step<=0) return 0;
   double raw=budget/minLotLoss*vmin;
   // Rounding always DOWN; never force the broker minimum above budget.
   double volume=MathFloor(MathMin(raw,vmax)/step)*step;
   if(!MathIsValidNumber(volume) || volume>vmax || volume<vmin-1e-10) return 0;
   return volume;
}
// END PORTABLE LOGIC

CTrade trade;
int h15fast=INVALID_HANDLE,h15slow=INVALID_HANDLE,h5fast=INVALID_HANDLE,h5slow=INVALID_HANDLE;
int h5adx=INVALID_HANDLE,h1ema=INVALID_HANDLE,h1atr=INVALID_HANDLE;
int lockHandle=INVALID_HANDLE;
string key;
double pip=0;
bool durable=true,connected=false,historyDirty=true,tester=false;
datetime lastBar=0,lastTick=0,quietUntil=0,lastAction=0,lastHistory=0,lastHistoryDay=0;
datetime lastLoss=0;
int lossStreak=0;
double dayNet=0,dayCash=0;
ulong rejects[16]; ulong signalsBuy=0,signalsSell=0,entryAttempts=0;

void Log(string text) { Print("[MicroSafe M1] ",text); }
string K(string name) { return key+name; }
bool Put(string name,double value)
{
   ResetLastError();
   if(GlobalVariableSet(K(name),value)==0)
   { durable=false; Log("STATE WRITE FAILED "+name+" error="+IntegerToString(GetLastError())); return false; }
   return true;
}
bool Has(string name) { return GlobalVariableCheck(K(name)); }
double Get(string name) { return GlobalVariableGet(K(name)); }
// Exclude broker credit consistently: a bonus must not create extra loss allowance.
double RiskEquity() { return AccountInfoDouble(ACCOUNT_EQUITY)-AccountInfoDouble(ACCOUNT_CREDIT); }
ulong IntentOrder()
{
   if(!Has("orderHi") || !Has("orderLo")) return 0;
   return ((ulong)Get("orderHi")<<32) | (ulong)Get("orderLo");
}
string IntentComment()
{
   if(!Has("token")) return "";
   return StringFormat("MM1.%I64d",(long)Get("token"));
}
void Reject(int category,string text)
{
   if(category>=0 && category<16) rejects[category]++;
   Log("REJECT "+IntegerToString(category)+": "+text);
}
datetime Midnight(datetime t)
{
   MqlDateTime d; TimeToStruct(t,d); d.hour=0; d.min=0; d.sec=0; return StructToTime(d);
}
bool Value(int handle,int buffer,int shift,double &result)
{
   double data[1];
   if(shift<1 || CopyBuffer(handle,buffer,shift,1,data)!=1) return false;
   result=data[0]; return MathIsValidNumber(result) && result!=EMPTY_VALUE;
}
double RoundPrice(double price,int direction)
{
   double step=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(step<=0) return 0;
   return NormalizeDouble((direction>0?MathCeil(price/step):MathFloor(price/step))*step,_Digits);
}
bool OwnSelected()
{
   return PositionGetString(POSITION_SYMBOL)==_Symbol && (ulong)PositionGetInteger(POSITION_MAGIC)==InpMagic;
}
bool OwnOpen()
{
   for(int i=PositionsTotal()-1;i>=0;i--) if(PositionGetTicket(i)>0 && OwnSelected()) return true;
   return false;
}
bool Exposure() { return PositionsTotal()>0 || OrdersTotal()>0; }
string PositionKey(string field,ulong id) { return field+StringFormat("%I64u",id); }
void Latch(string why)
{
   if(!Has("halt") || Get("halt")==0) { Put("halt",1); GlobalVariablesFlush(); Log("HALT: "+why); }
}

bool Result(string action,bool submitted,int error)
{
   uint code=trade.ResultRetcode();
   bool ok=submitted && (code==TRADE_RETCODE_DONE || code==TRADE_RETCODE_DONE_PARTIAL);
   Log(StringFormat("%s submitted=%s retcode=%u (%s) order=%I64u deal=%I64u comment=%s terminal=%d",
      action,submitted?"true":"false",code,trade.ResultRetcodeDescription(),trade.ResultOrder(),trade.ResultDeal(),trade.ResultComment(),error));
   return ok;
}
bool DefinitelyRejected(uint code)
{
   // Unknown/timeout/connection/placed remain unresolved: NEVER automatically resend.
   return code==TRADE_RETCODE_REQUOTE || code==TRADE_RETCODE_REJECT || code==TRADE_RETCODE_CANCEL ||
      code==TRADE_RETCODE_INVALID || code==TRADE_RETCODE_INVALID_VOLUME || code==TRADE_RETCODE_INVALID_PRICE ||
      code==TRADE_RETCODE_INVALID_STOPS || code==TRADE_RETCODE_TRADE_DISABLED || code==TRADE_RETCODE_MARKET_CLOSED ||
      code==TRADE_RETCODE_NO_MONEY || code==TRADE_RETCODE_PRICE_CHANGED || code==TRADE_RETCODE_PRICE_OFF ||
      code==TRADE_RETCODE_INVALID_EXPIRATION || code==TRADE_RETCODE_TOO_MANY_REQUESTS ||
      code==TRADE_RETCODE_SERVER_DISABLES_AT || code==TRADE_RETCODE_CLIENT_DISABLES_AT || code==TRADE_RETCODE_INVALID_FILL ||
      code==TRADE_RETCODE_LIMIT_ORDERS || code==TRADE_RETCODE_LIMIT_VOLUME || code==TRADE_RETCODE_INVALID_ORDER;
}
void CloseOwn(string why)
{
   if(TimeCurrent()-lastAction<5) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || !OwnSelected()) continue;
      lastAction=TimeCurrent(); Log(why); ResetLastError();
      bool sent=trade.PositionClose(ticket,(ulong)InpDeviationPoints); int error=GetLastError();
      Result("CLOSE",sent,error);
   }
}

// Reconstruct complete EA position lifecycles. Refresh on transactions/reconnect,
// once per minute, and at initialization. Entry and all exit fees are included.
bool RefreshHistory()
{
   if(!historyDirty && lastHistoryDay==Midnight(TimeCurrent()) && TimeCurrent()-lastHistory<60) return true;
   if(!HistorySelect(0,TimeCurrent())) return false;
   ulong ids[]; double pnls[]; datetime exits[]; bool closed[];
   datetime today=Midnight(TimeCurrent()); dayNet=0; dayCash=0;
   bool intentResolved=false;
   for(int i=0;i<HistoryDealsTotal();i++)
   {
      ulong deal=HistoryDealGetTicket(i); if(deal==0) return false;
      long type=HistoryDealGetInteger(deal,DEAL_TYPE);
      datetime when=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
      double net=HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_COMMISSION)+
         HistoryDealGetDouble(deal,DEAL_SWAP)+HistoryDealGetDouble(deal,DEAL_FEE);
      if(when>=today)
      {
         if(type==DEAL_TYPE_BALANCE || type==DEAL_TYPE_CREDIT || type==DEAL_TYPE_CORRECTION || type==DEAL_TYPE_BONUS) dayCash+=net;
         else dayNet+=net;
      }
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol || (type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL)) continue;
      ulong id=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
      long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
      bool magic=(ulong)HistoryDealGetInteger(deal,DEAL_MAGIC)==InpMagic;
      int ix=-1;
      for(int j=0;j<ArraySize(ids);j++) if(ids[j]==id) { ix=j; break; }
      if(ix<0 && !magic) continue; // unrelated reversals must not poison EA history
      if(entry==DEAL_ENTRY_INOUT) { Log("Owned netting reversal: mixed/manual trading unsupported"); return false; }
      if(ix<0)
      {
         if(entry!=DEAL_ENTRY_IN) { Log("Owned exit without entry: incomplete history"); return false; }
         ix=ArraySize(ids); ArrayResize(ids,ix+1); ArrayResize(pnls,ix+1); ArrayResize(exits,ix+1); ArrayResize(closed,ix+1);
         ids[ix]=id; pnls[ix]=0; exits[ix]=0; closed[ix]=false;
      }
      pnls[ix]+=net;
      if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY) { exits[ix]=when; closed[ix]=true; }
      if(magic && entry==DEAL_ENTRY_IN && Has("intentTime") && when>=(datetime)Get("intentTime") && Get("intentTime")>0)
      {
         ulong order=(ulong)HistoryDealGetInteger(deal,DEAL_ORDER);
         string comment=HistoryDealGetString(deal,DEAL_COMMENT),expected=IntentComment();
         if((IntentOrder()>0 && order==IntentOrder()) || (expected!="" && comment==expected)) intentResolved=true;
      }
   }
   for(int i=0;i<ArraySize(ids);i++)
      for(int j=PositionsTotal()-1;j>=0;j--)
         if(PositionGetTicket(j)>0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==ids[i]) { closed[i]=false; break; }
   lastLoss=0; lossStreak=0;
   for(int i=0;i<ArraySize(ids);i++) if(closed[i] && pnls[i]<-1e-8) lastLoss=(datetime)MathMax(lastLoss,exits[i]);
   // Consume a separate flag; never mutate exit times used for cooldown.
   bool consumed[]; ArrayResize(consumed,ArraySize(ids)); for(int i=0;i<ArraySize(consumed);i++) consumed[i]=false;
   while(true)
   {
      int latest=-1;
      for(int i=0;i<ArraySize(ids);i++)
         if(closed[i] && !consumed[i] && exits[i]>=today && (latest<0 || exits[i]>exits[latest])) latest=i;
      if(latest<0) break;
      if(pnls[latest]>=-1e-8) break;
      lossStreak++; consumed[latest]=true;
   }
   if(intentResolved && Has("pending") && Get("pending")!=0) { Put("pending",0); GlobalVariablesFlush(); Log("Entry intent reconciled with broker deal history"); }
   historyDirty=false; lastHistory=TimeCurrent(); lastHistoryDay=today; return true;
}
bool DailyRisk()
{
   datetime day=Midnight(TimeCurrent());
   if(!RefreshHistory()) { Log("History unavailable: entry blocked"); return false; }
   bool initialized=Has("day");
   if(!initialized || (datetime)Get("day")!=day)
   {
      if(initialized && OwnOpen()) { CloseOwn("Overnight position: flatten before resetting day"); return false; }
      // Balance minus today's account-wide trading result reconstructs the day
      // opening balance (adjusted for cash transfers). No fabricated midnight equity.
      double base=AccountInfoDouble(ACCOUNT_BALANCE)-dayNet;
      if(base<=0 || !MathIsValidNumber(base)) return false;
      if(!Put("base",base) || !Put("cash",dayCash) || !Put("halt",0) || !Put("day",(double)day)) return false;
      GlobalVariablesFlush();
      Log(StringFormat("Daily baseline=%.2f, today's account trading P/L=%.2f (balance-based incl floating loss)",base,dayNet));
   }
   if(!Has("base") || !Has("cash") || !Has("halt") || Get("base")<=0) { durable=false; return false; }
   if(MathAbs(dayCash-Get("cash"))>0.000001) Latch("cash transfer detected; no trading until next server day");
   if(RiskEquity()<=Get("base")*(1-InpDailyLossPercent/100.0)) Latch("account daily loss threshold");
   if(lossStreak>=InpMaxConsecutiveLosses) Latch("daily consecutive loss threshold");
   return durable && Get("halt")==0;
}

// Persist actual initial risk independently of mutable TP or input RR.
// If a position's origin/state cannot be recovered, flatten rather than guess.
bool RegisterPosition(ulong id,double entry,double sl,datetime opened)
{
   string rk=PositionKey("R",id),ck=PositionKey("C",id);
   if(Has(rk) && Has(ck)) return Get(rk)>0 && Get(ck)>0;
   if(!Has("intentTime") || !Has("intentSL") || !Has("intentCap") || !Has("intentRR") ||
      opened<(datetime)Get("intentTime") || Get("intentCap")<=0 || Get("intentRR")<=0) return false;
   double r=MathAbs(entry-Get("intentSL"));
   if(r<=0 || MathAbs(sl-Get("intentSL"))>2*_Point) return false;
   if(!Put(rk,r) || !Put(ck,Get("intentCap"))) return false;
   GlobalVariablesFlush(); return true;
}
void Manage(const MqlTick &tick)
{
   double atr=0; bool ready=Value(h1atr,0,1,atr);
   double stops=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;
   double freeze=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL)*_Point;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || !OwnSelected()) continue;
      ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      bool buy=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      double entry=PositionGetDouble(POSITION_PRICE_OPEN),sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
      double volume=PositionGetDouble(POSITION_VOLUME);
      datetime opened=(datetime)PositionGetInteger(POSITION_TIME);
      if(sl<=0 || tp<=0 || !RegisterPosition(id,entry,sl,opened)) { CloseOwn("EMERGENCY: unprotected/untracked position"); return; }
      double cap=Get(PositionKey("C",id)),r=Get(PositionKey("R",id)),loss=0;
      ENUM_ORDER_TYPE type=buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
      if(!OrderCalcProfit(type,_Symbol,volume,entry,sl,loss)) { CloseOwn("EMERGENCY: cannot audit actual position risk"); return; }
      double actualRisk=(MathMax(0,-loss)+InpCommissionPerLot*volume)*(1+InpRiskReservePercent/100.0);
      if(actualRisk>cap+0.01) { Latch("actual fill risk exceeded budget"); CloseOwn("EMERGENCY: fill risk beyond reserved cap"); return; }
      if(!ready || atr<=0 || TimeCurrent()-lastAction<5) continue;
      double price=buy?tick.bid:tick.ask,gain=buy?price-entry:entry-price;
      double candidate=sl;
      if(gain>=InpBreakEvenR*r)
      {
         double be=entry+(buy?1:-1)*InpBreakEvenOffsetPips*pip;
         candidate=buy?MathMax(candidate,be):MathMin(candidate,be);
      }
      if(gain>=InpTrailStartR*r)
      {
         double trail=price+(buy?-1:1)*InpTrailATR*atr;
         candidate=buy?MathMax(candidate,trail):MathMin(candidate,trail);
      }
      candidate=RoundPrice(candidate,buy?-1:1);
      bool improves=buy?candidate>sl+_Point:candidate<sl-_Point;
      double distance=buy?tick.bid-candidate:candidate-tick.ask;
      double tpDistance=buy?tp-tick.bid:tick.ask-tp;
      // A stop currently in the freeze zone cannot be modified either.
      double oldDistance=buy?tick.bid-sl:sl-tick.ask;
      if(improves && distance>MathMax(stops,freeze)+2*_Point && tpDistance>freeze && oldDistance>freeze)
      {
         lastAction=TimeCurrent(); ResetLastError(); bool sent=trade.PositionModify(ticket,candidate,tp); int error=GetLastError();
         Result("MODIFY SL",sent,error);
      }
   }
}

void Evaluate(const MqlTick &tick)
{
   if(!durable) { Reject(0,"durable state unavailable"); return; }
   if(Has("pending") && Get("pending")!=0) { Reject(0,"unresolved earlier entry; broker reconciliation required, no retry"); return; }
   if(!tester && (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))) { Reject(0,"terminal/EA automated trading permission disabled"); return; }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) { Reject(0,"account trading disabled"); return; }
   if(!DailyRisk()) { Reject(1,"history/daily/streak safety block"); return; }
   if(Exposure()) { Reject(2,"account position or pending order already exists"); return; }
   MqlDateTime now; TimeToStruct(TimeCurrent(),now);
   if(now.day_of_week==0 || now.day_of_week==6 || now.hour<InpStartHour || now.hour>=InpEndHour ||
      (now.day_of_week==5 && now.hour>=InpFridayStopHour)) { Reject(3,"server-time session/Friday filter"); return; }
   if(lastLoss>0 && TimeCurrent()-lastLoss<InpLossCooldownMinutes*60) { Reject(4,"60-minute loss cooldown"); return; }
   double spread=(tick.ask-tick.bid)/pip;
   if(spread>InpMaxSpreadPips) { Reject(5,StringFormat("spread %.2f > %.2f pips",spread,InpMaxSpreadPips)); return; }
   if(!SeriesInfoInteger(_Symbol,PERIOD_M1,SERIES_SYNCHRONIZED) || !SeriesInfoInteger(_Symbol,PERIOD_M5,SERIES_SYNCHRONIZED) ||
      !SeriesInfoInteger(_Symbol,PERIOD_M15,SERIES_SYNCHRONIZED) || BarsCalculated(h15slow)<205)
   { Reject(6,"M1/M5/M15 history/EMA warmup unavailable"); return; }
   MSFeatures f;
   if(!Value(h15fast,0,1,f.m15fast) || !Value(h15fast,0,3,f.m15previous) || !Value(h15slow,0,1,f.m15slow) ||
      !Value(h5fast,0,1,f.m5fast) || !Value(h5slow,0,1,f.m5slow) || !Value(h5adx,0,1,f.adx) ||
      !Value(h5adx,1,1,f.diPlus) || !Value(h5adx,2,1,f.diMinus) || !Value(h1ema,0,1,f.emaNow) ||
      !Value(h1ema,0,2,f.emaPrevious) || !Value(h1atr,0,1,f.atr)) { Reject(6,"closed-bar indicator buffers unavailable"); return; }
   if(f.atr/pip<InpMinATRPips || f.atr/pip>InpMaxATRPips) { Reject(7,StringFormat("M1 ATR %.2f pips outside range",f.atr/pip)); return; }
   MqlRates bars[]; ArraySetAsSeries(bars,true);
   if(CopyRates(_Symbol,PERIOD_M1,1,5,bars)!=5) { Reject(6,"M1 bars unavailable"); return; }
   f.signal.open=bars[0].open; f.signal.high=bars[0].high; f.signal.low=bars[0].low; f.signal.close=bars[0].close;
   f.pullback.open=bars[1].open; f.pullback.high=bars[1].high; f.pullback.low=bars[1].low; f.pullback.close=bars[1].close;
   int why=0,direction=MSDirection(f,InpMinADX,why);
   if(direction==0) { Reject(8,StringFormat("NO SIGNAL rule=%d (1 invalid bars, 2 candle, 3 ADX, 4 trend/pullback/breakout)",why)); return; }
   bool buy=direction>0;
   if(buy) signalsBuy++; else signalsSell++;
   Log(StringFormat("SIGNAL %s: ADX=%.1f ATR=%.2f pips spread=%.2f pips; rule outcome, NOT a win probability",buy?"BUY":"SELL",f.adx,f.atr/pip,spread));
   // Signal candles are Bid bars for both directions; never compare ask to Bid close.
   if(MathAbs(tick.bid-bars[0].close)>0.5*f.atr) { Reject(9,"signal price moved >0.5 ATR"); return; }
   long mode=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE),flags=SymbolInfoInteger(_Symbol,SYMBOL_ORDER_MODE);
   if(mode==SYMBOL_TRADE_MODE_DISABLED || mode==SYMBOL_TRADE_MODE_CLOSEONLY ||
      (buy && mode==SYMBOL_TRADE_MODE_SHORTONLY) || (!buy && mode==SYMBOL_TRADE_MODE_LONGONLY) ||
      (flags&SYMBOL_ORDER_MARKET)==0 || (flags&SYMBOL_ORDER_SL)==0 || (flags&SYMBOL_ORDER_TP)==0)
   { Reject(10,"broker symbol order/direction restrictions"); return; }
   double extreme=buy?bars[0].low:bars[0].high;
   for(int i=1;i<5;i++) extreme=buy?MathMin(extreme,bars[i].low):MathMax(extreme,bars[i].high);
   double entry=buy?tick.ask:tick.bid;
   double distance=MathMax(InpMinStopPips*pip,InpStopATR*f.atr);
   distance=MathMax(distance,(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+tick.ask-tick.bid+2*_Point);
   double structure=extreme+(buy?-1:1)*0.2*f.atr;
   // SELL stop pays the ask spread even though structural highs are Bid bars.
   if(!buy) structure+=tick.ask-tick.bid;
   double sl=RoundPrice(buy?MathMin(entry-distance,structure):MathMax(entry+distance,structure),buy?-1:1);
   distance=MathAbs(entry-sl);
   if(distance>InpMaxStopPips*pip) { Reject(11,"stop exceeds maximum pips"); return; }
   if(tick.ask-tick.bid>InpMaxSpreadToStop*distance) { Reject(5,"spread consumes too much of stop distance"); return; }
   double tp=RoundPrice(entry+(buy?1:-1)*distance*InpRewardRisk,buy?1:-1);
   double equity=RiskEquity();
   double budget=MathMin(equity,AccountInfoDouble(ACCOUNT_BALANCE))*InpRiskPercent/100.0;
   budget=MathMin(budget,equity-Get("base")*(1-InpDailyLossPercent/100.0));
   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),maxLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX),step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double adverse=entry+(buy?1:-1)*InpDeviationPoints*_Point,lossMin=0;
   ENUM_ORDER_TYPE type=buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   if(!OrderCalcProfit(type,_Symbol,minLot,adverse,sl,lossMin) || lossMin>=0) { Reject(12,"broker loss calculation failed"); return; }
   double factor=1+InpRiskReservePercent/100.0;
   double minRisk=(MathAbs(lossMin)+InpCommissionPerLot*minLot)*factor;
   double volume=NormalizeDouble(MSVolume(budget,minRisk,minLot,maxLot,step),8);
   if(volume<minLot || volume<=0) { Reject(12,StringFormat("min lot %.8f needs %.4f; budget=%.4f %s",minLot,minRisk,budget,AccountInfoString(ACCOUNT_CURRENCY))); return; }
   double loss=0,margin=0;
   if(!OrderCalcProfit(type,_Symbol,volume,adverse,sl,loss) || loss>=0 ||
      (MathAbs(loss)+InpCommissionPerLot*volume)*factor>budget+1e-8 ||
      !OrderCalcMargin(type,_Symbol,volume,adverse,margin) || margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE)*(1-InpFreeMarginReservePercent/100.0))
   { Reject(12,"final risk/volume/margin check"); return; }
   MqlTick fresh; if(!SymbolInfoTick(_Symbol,fresh) || fresh.time_msc!=tick.time_msc || fresh.bid!=tick.bid || fresh.ask!=tick.ask)
   { Reject(9,"quote changed during evaluation; no stale order"); return; }
   if(Exposure()) { Reject(2,"exposure changed before submit"); return; }
   // Durable unresolved intent is independent of per-bar guard and survives restart.
   if(!Put("intentTime",(double)TimeCurrent()) || !Put("intentSL",sl) || !Put("intentCap",budget) ||
      !Put("intentRR",InpRewardRisk) || !Put("token",(double)tick.time_msc) ||
      !Put("orderHi",0) || !Put("orderLo",0) || !Put("pending",1)) return;
   GlobalVariablesFlush(); entryAttempts++;
   Log(StringFormat("ORDER %s volume=%.8f SL=%.*f TP=%.*f risk<=%.4f %s (estimate)",buy?"BUY":"SELL",volume,_Digits,sl,_Digits,tp,budget,AccountInfoString(ACCOUNT_CURRENCY)));
   ResetLastError(); bool sent=buy?trade.Buy(volume,_Symbol,0,sl,tp,IntentComment()):trade.Sell(volume,_Symbol,0,sl,tp,IntentComment()); int error=GetLastError();
   Result("ENTRY; never resend uncertain request",sent,error);
   ulong order=trade.ResultOrder();
   if(order>0) { Put("orderHi",(double)(order>>32)); Put("orderLo",(double)(order & (ulong)0xFFFFFFFF)); GlobalVariablesFlush(); }
   if(DefinitelyRejected(trade.ResultRetcode())) { Put("pending",0); GlobalVariablesFlush(); }
   historyDirty=true;
   // Any actual position must immediately pass protection and monetary-risk audit.
   Manage(tick);
}

int OnInit()
{
   if(InpRiskPercent<=0 || InpRiskPercent>1 || InpDailyLossPercent<=0 || InpDailyLossPercent>2 ||
      InpMaxConsecutiveLosses<1 || InpMaxConsecutiveLosses>3 || InpLossCooldownMinutes<60 || InpMaxSpreadPips<=0 ||
      InpMaxSpreadToStop<=0 || InpMaxSpreadToStop>0.3 || InpMinATRPips<=0 || InpMaxATRPips<=InpMinATRPips || InpMinADX<0 ||
      InpMinStopPips<=0 || InpMaxStopPips<InpMinStopPips || InpStopATR<=0 || InpRewardRisk<1 ||
      InpBreakEvenR<=0 || InpBreakEvenOffsetPips<0 || InpTrailStartR<InpBreakEvenR || InpTrailATR<=0 ||
      InpCommissionPerLot<0 || InpRiskReservePercent<0 || InpFreeMarginReservePercent<0 || InpFreeMarginReservePercent>=100 ||
      InpStartHour<0 || InpEndHour>23 || InpStartHour>=InpEndHour || InpFridayStopHour<0 || InpFridayCloseHour>23 ||
      InpFridayStopHour>InpFridayCloseHour || InpDeviationPoints<0 || InpMaxTickAgeSeconds<1 ||
      InpReconnectQuietSeconds<1 || InpEntryWindowSeconds<1 || InpEntryWindowSeconds>10 || InpMagic==0)
   { Log("INIT FAILED: invalid safety inputs"); return INIT_PARAMETERS_INCORRECT; }
   tester=(bool)MQLInfoInteger(MQL_TESTER);
   if(!tester && AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL && !InpAllowRealAccount)
   { Log("INIT FAILED: real account locked, use demo first"); return INIT_FAILED; }
   if(SymbolInfoString(_Symbol,SYMBOL_CURRENCY_BASE)!="EUR" || SymbolInfoString(_Symbol,SYMBOL_CURRENCY_PROFIT)!="USD" ||
      (_Digits!=4 && _Digits!=5)) { Log("INIT FAILED: EURUSD Forex symbol required (suffix allowed)"); return INIT_FAILED; }
   pip=(_Digits==5)?10*_Point:_Point;
   uint hash=2166136261; string server=AccountInfoString(ACCOUNT_SERVER);
   for(int i=0;i<StringLen(server);i++) hash=(hash^(uint)StringGetCharacter(server,i))*16777619;
   // Account-scoped safety state cannot be reset by changing chart symbol or magic.
   key=StringFormat("%s.%u.%I64d.",tester?"MM1T":"MM1",hash,AccountInfoInteger(ACCOUNT_LOGIN));
   if(StringLen(key)>39) { Log("INIT FAILED: key too long"); return INIT_FAILED; }
   if(tester) GlobalVariablesDeleteAll(key);
   else
   {
      // No SHARE_READ/SHARE_WRITE: exclusive OS handle, released after process crash.
      lockHandle=FileOpen(key+"lock",FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
      if(lockHandle==INVALID_HANDLE) { Log("INIT FAILED: another account instance/terminal holds lock, or file access denied"); return INIT_FAILED; }
   }
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(PositionGetTicket(i)>0 && !OwnSelected())
      { Log("INIT FAILED: foreign symbol/magic position; restore its original EA/inputs, do not mix accounts"); return INIT_FAILED; }
   if(Has("day") && (!Has("base") || !Has("halt") || !Has("cash"))) { Log("INIT FAILED: partial durable day state; reconcile before use"); return INIT_FAILED; }
   h15fast=iMA(_Symbol,PERIOD_M15,50,0,MODE_EMA,PRICE_CLOSE); h15slow=iMA(_Symbol,PERIOD_M15,200,0,MODE_EMA,PRICE_CLOSE);
   h5fast=iMA(_Symbol,PERIOD_M5,20,0,MODE_EMA,PRICE_CLOSE); h5slow=iMA(_Symbol,PERIOD_M5,50,0,MODE_EMA,PRICE_CLOSE);
   h5adx=iADX(_Symbol,PERIOD_M5,14); h1ema=iMA(_Symbol,PERIOD_M1,20,0,MODE_EMA,PRICE_CLOSE); h1atr=iATR(_Symbol,PERIOD_M1,14);
   if(h15fast==INVALID_HANDLE || h15slow==INVALID_HANDLE || h5fast==INVALID_HANDLE || h5slow==INVALID_HANDLE ||
      h5adx==INVALID_HANDLE || h1ema==INVALID_HANDLE || h1atr==INVALID_HANDLE) { Log("INIT FAILED: indicator handles"); return INIT_FAILED; }
   trade.SetExpertMagicNumber(InpMagic); trade.SetDeviationInPoints(InpDeviationPoints); trade.SetAsyncMode(false);
   if(!trade.SetTypeFillingBySymbol(_Symbol)) { Log("INIT FAILED: broker filling policy"); return INIT_FAILED; }
   lastBar=iTime(_Symbol,PERIOD_M1,0); quietUntil=TimeCurrent()+InpReconnectQuietSeconds;
   connected=tester || (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
   if(!EventSetTimer(5)) { Log("INIT FAILED: timer"); return INIT_FAILED; }
   if(!DailyRisk()) Log("Initialized in safety-block state; see history/daily/pending diagnostics");
   Log(StringFormat("Initialized: M1 signals, M5/M15 context; contract=%.2f minlot=%.8f step=%.8f currency=%s; no 80%% guarantee",
      SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE),SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP),AccountInfoString(ACCOUNT_CURRENCY)));
   return durable?INIT_SUCCEEDED:INIT_FAILED;
}
void OnTimer()
{
   if(tester) return;
   bool now=(bool)TerminalInfoInteger(TERMINAL_CONNECTED);
   if(!now || !connected)
   {
      quietUntil=TimeCurrent()+InpReconnectQuietSeconds; lastBar=iTime(_Symbol,PERIOD_M1,0); historyDirty=true;
      if(now && !connected) Log("Connection restored: discard old bar, quiet interval");
   }
   connected=now;
}
void OnTick()
{
   if(!tester && !TerminalInfoInteger(TERMINAL_CONNECTED)) { connected=false; return; }
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick) || !MathIsValidNumber(tick.ask) || !MathIsValidNumber(tick.bid) || tick.bid<=0 || tick.ask<tick.bid) return;
   datetime clock=TimeTradeServer();
   if(!tester && clock>0 && MathAbs((double)(clock-tick.time))>InpMaxTickAgeSeconds) return;
   if(!connected || (lastTick>0 && tick.time-lastTick>90))
   { quietUntil=TimeCurrent()+InpReconnectQuietSeconds; lastBar=iTime(_Symbol,PERIOD_M1,0); historyDirty=true; connected=true; Log("Reconnect/tick gap: old signal discarded"); }
   lastTick=tick.time;
   bool safe=DailyRisk();
   MqlDateTime now; TimeToStruct(TimeCurrent(),now);
   if(!safe) CloseOwn("Daily/history/state safety close");
   else if(now.hour>=InpEndHour || now.hour<InpStartHour || (now.day_of_week==5 && now.hour>=InpFridayCloseHour) || now.day_of_week==6 || now.day_of_week==0)
      CloseOwn("Session/Friday mandatory exit");
   else Manage(tick);
   datetime bar=iTime(_Symbol,PERIOD_M1,0);
   if(bar==0 || bar==lastBar) return;
   lastBar=bar;
   if(TimeCurrent()<quietUntil) { Reject(13,"startup/reconnect quiet interval"); return; }
   if(TimeCurrent()-bar>InpEntryWindowSeconds) { Reject(13,"late M1 bar; do not chase"); return; }
   if(Has("bar") && Get("bar")>=(double)bar) { Reject(13,"bar already evaluated before restart"); return; }
   if(!Put("bar",(double)bar)) return;
   GlobalVariablesFlush(); Evaluate(tick);
}
void OnTradeTransaction(const MqlTradeTransaction &tx,const MqlTradeRequest &request,const MqlTradeResult &result)
{
   historyDirty=true;
   if(tx.type==TRADE_TRANSACTION_DEAL_ADD && tx.deal>0 && HistoryDealSelect(tx.deal))
      Log(StringFormat("DEAL=%I64u symbol=%s magic=%I64d entry=%d profit=%.4f commission=%.4f swap=%.4f fee=%.4f",
         tx.deal,HistoryDealGetString(tx.deal,DEAL_SYMBOL),HistoryDealGetInteger(tx.deal,DEAL_MAGIC),
         (int)HistoryDealGetInteger(tx.deal,DEAL_ENTRY),HistoryDealGetDouble(tx.deal,DEAL_PROFIT),
         HistoryDealGetDouble(tx.deal,DEAL_COMMISSION),HistoryDealGetDouble(tx.deal,DEAL_SWAP),HistoryDealGetDouble(tx.deal,DEAL_FEE)));
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   if(h15fast!=INVALID_HANDLE) IndicatorRelease(h15fast);
   if(h15slow!=INVALID_HANDLE) IndicatorRelease(h15slow);
   if(h5fast!=INVALID_HANDLE) IndicatorRelease(h5fast);
   if(h5slow!=INVALID_HANDLE) IndicatorRelease(h5slow);
   if(h5adx!=INVALID_HANDLE) IndicatorRelease(h5adx);
   if(h1ema!=INVALID_HANDLE) IndicatorRelease(h1ema);
   if(h1atr!=INVALID_HANDLE) IndicatorRelease(h1atr);
   if(lockHandle!=INVALID_HANDLE) FileClose(lockHandle);
   GlobalVariablesFlush();
   Log(StringFormat("SUMMARY signals BUY=%I64u SELL=%I64u entryAttempts=%I64u",signalsBuy,signalsSell,entryAttempts));
   for(int i=0;i<16;i++) if(rejects[i]>0) Log(StringFormat("SUMMARY rejectionCategory=%d count=%I64u",i,rejects[i]));
}
