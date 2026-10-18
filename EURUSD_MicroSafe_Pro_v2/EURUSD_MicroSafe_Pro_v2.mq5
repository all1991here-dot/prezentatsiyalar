// EURUSD MicroSafe Pro v2.0 — demo validation required.
#property strict
#property version "2.00"
#property description "Closed-bar EURUSD trend/pullback EA; broker-native risk sizing."
#include <Trade/Trade.mqh>
input ulong InpMagic=205020;
input double InpRiskPercent=0.5;
input bool InpAllowRealAccount=false;
input double InpDailyLossPercent=2.0;
input int InpMaxConsecutiveLosses=3;
input int InpLossCooldownMinutes=60;
input double InpMaxSpreadPips=1.5;
input double InpMinATRPips=3.0;
input double InpMaxATRPips=25.0;
input double InpMinADX=20.0;
input double InpMinTrendGapATR=0.25;
input double InpStopATR=1.8;
input double InpRewardRisk=2.0;
input double InpBreakEvenR=1.0;
input double InpBreakEvenOffsetPips=0.2;
input double InpTrailStartR=1.5;
input double InpTrailATR=1.5;
input int InpFridayStopHour=16; // broker server time
input int InpFridayCloseHour=20;
input int InpStartHour=7;
input int InpEndHour=21;
input int InpDeviationPoints=10;
input int InpMaxTickAgeSeconds=10;
input int InpReconnectQuietSeconds=60;
input double InpCostReservePercent=15.0; // reserve within the risk budget, not an exact fee model
input double InpFreeMarginReservePercent=20.0;
CTrade trade;
int ema50=INVALID_HANDLE,ema200=INVALID_HANDLE,ema20=INVALID_HANDLE;
int atr15=INVALID_HANDLE,atrH1=INVALID_HANDLE,adxH1=INVALID_HANDLE;
string key;
datetime lastBar=0,quietUntil=0;
bool connected=false,storageOK=true;
double pip=0;

void Log(string reason) { Print("[MicroSafe Pro v2] ",reason); }
string K(string suffix) { return key+suffix; }
bool Save(string suffix,double value)
{
   ResetLastError();
   if(GlobalVariableSet(K(suffix),value)==0) { storageOK=false; Log("STATE WRITE FAILED: "+suffix+" error="+IntegerToString(GetLastError())); return false; }
   return true;
}
double Read(string suffix) { return GlobalVariableGet(K(suffix)); }
datetime DayStart(datetime t)
{
   MqlDateTime d; TimeToStruct(t,d); d.hour=0; d.min=0; d.sec=0;
   return StructToTime(d);
}
bool BufferValue(int h,int buffer,int shift,double &v)
{
   double a[1];
   if(CopyBuffer(h,buffer,shift,1,a)!=1) return false;
   v=a[0]; return MathIsValidNumber(v) && v!=EMPTY_VALUE;
}
double TickRound(double price,int direction)
{
   double step=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(step<=0) return 0;
   double n=price/step;
   return NormalizeDouble((direction>0?MathCeil(n):MathFloor(n))*step,_Digits);
}
bool OwnedPosition()
{
   return PositionGetString(POSITION_SYMBOL)==_Symbol && (ulong)PositionGetInteger(POSITION_MAGIC)==InpMagic;
}
// On hedging accounts inspect all positions, never rely on PositionSelect(symbol).
bool OwnPositionExists()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(PositionGetTicket(i)>0 && OwnedPosition()) return true;
   return false;
}
// Any position/order on this account blocks entry, including manual trades.
bool ExposureExists() { return PositionsTotal()>0 || OrdersTotal()>0; }

bool BrokerResult(string operation,bool submitted)
{
   uint rc=trade.ResultRetcode();
   bool ok=submitted && (rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_DONE_PARTIAL);
   Log(StringFormat("%s: success=%s retcode=%u (%s), order=%I64u deal=%I64u, broker=%s, terminal=%d",
       operation,ok?"true":"false",rc,trade.ResultRetcodeDescription(),trade.ResultOrder(),trade.ResultDeal(),trade.ResultComment(),GetLastError()));
   return ok;
}

// Sum complete position lifecycles, including entry/exit fees and partial exits.
// Full history is intentional: a loss closed today can have an entry on a prior day.
bool LossState(datetime &lastLoss,int &streak)
{
   lastLoss=0; streak=0;
   if(!HistorySelect(0,TimeCurrent())) return false;
   ulong ids[]; double pnl[]; datetime ends[]; bool exited[];
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
   {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0) return false;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol) continue;
      long type=HistoryDealGetInteger(deal,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      ulong id=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
      long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
      if(entry==DEAL_ENTRY_INOUT) { Log("REJECT: netting reversal in history; separate account required"); return false; }
      int ix=-1;
      for(int j=0;j<ArraySize(ids);j++) if(ids[j]==id) { ix=j; break; }
      if(ix<0)
      {
         // Track positions initiated by this EA, then include manual closures of them.
         if((ulong)HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpMagic || entry!=DEAL_ENTRY_IN) continue;
         ix=ArraySize(ids); ArrayResize(ids,ix+1); ArrayResize(pnl,ix+1); ArrayResize(ends,ix+1); ArrayResize(exited,ix+1);
         ids[ix]=id; pnl[ix]=0; ends[ix]=0; exited[ix]=false;
      }
      pnl[ix]+=HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_SWAP)
               +HistoryDealGetDouble(deal,DEAL_COMMISSION)+HistoryDealGetDouble(deal,DEAL_FEE);
      if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY)
      { exited[ix]=true; ends[ix]=(datetime)HistoryDealGetInteger(deal,DEAL_TIME); }
   }
   // Sort by final exit, independent of entry order.
   for(int i=0;i<ArraySize(ids);i++)
   {
      bool open=false;
      for(int j=PositionsTotal()-1;j>=0;j--)
         if(PositionGetTicket(j)>0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==ids[i]) { open=true; break; }
      if(open) ends[i]=0;
   }
   datetime floorTime=(datetime)Read("streakEpoch");
   while(true)
   {
      int latest=-1;
      for(int i=0;i<ArraySize(ids);i++)
         if(exited[i] && ends[i]>=floorTime && ends[i]>0 && (latest<0 || ends[i]>ends[latest])) latest=i;
      if(latest<0) break;
      if(pnl[latest]<-0.0000001)
      { if(lastLoss==0) lastLoss=ends[latest]; streak++; ends[latest]=0; }
      else break;
   }
   // Cooldown also survives an intervening profitable/manual closure.
   for(int i=0;i<ArraySize(ids);i++)
      if(exited[i] && pnl[i]<-0.0000001 && ends[i]>lastLoss) lastLoss=ends[i];
   return true;
}

bool RiskDay()
{
   datetime day=DayStart(TimeCurrent());
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(!GlobalVariableCheck(K("day")))
   {
      // First installation baseline is current equity, not a fabricated midnight balance.
      Save("base",equity); Save("halt",0); Save("streakEpoch",day); Save("day",(double)day);
      GlobalVariablesFlush(); Log("Daily baseline initialized at attachment equity");
   }
   else if((datetime)Read("day")!=day)
   {
      // First observed equity of the new server day; open trades crossing midnight
      // are liquidated before a new day's trading is permitted.
      Save("base",equity); Save("halt",OwnPositionExists()?1:0);
      Save("streakEpoch",day); Save("day",(double)day); GlobalVariablesFlush();
   }
   if(!storageOK || Read("base")<=0) return false;
   if(equity<=Read("base")*(1.0-InpDailyLossPercent/100.0))
   {
      if(Read("halt")==0) { Save("halt",1); GlobalVariablesFlush(); Log("DAILY HALT: account equity loss limit reached"); }
   }
   return Read("halt")==0;
}
void CloseOwn(string reason)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !OwnedPosition()) continue;
      Log(reason); BrokerResult("CLOSE",trade.PositionClose(ticket,(ulong)InpDeviationPoints));
   }
}
void Manage(const MqlTick &tick)
{
   double atr=0; bool atrReady=BufferValue(atr15,0,1,atr);
   double freeze=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL)*_Point;
   double minDist=MathMax(freeze,(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point)+2*_Point;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || !OwnedPosition()) continue;
      double entry=PositionGetDouble(POSITION_PRICE_OPEN),sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
      bool buy=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      if(sl<=0 || tp<=0) { Log("EMERGENCY: position missing SL/TP"); BrokerResult("CLOSE UNPROTECTED",trade.PositionClose(ticket)); continue; }
      if(!atrReady || atr<=0) continue;
      // TP remains unchanged throughout position lifetime, preserving original R after restart.
      double r=MathAbs(tp-entry)/InpRewardRisk;
      if(r<=0) continue;
      double price=buy?tick.bid:tick.ask, gain=buy?price-entry:entry-price;
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
      candidate=TickRound(candidate,buy?-1:1);
      bool improves=buy?candidate>sl+_Point:candidate<sl-_Point;
      bool legal=buy?(tick.bid-candidate>minDist && tp-tick.bid>freeze):(candidate-tick.ask>minDist && tick.ask-tp>freeze);
      if(improves && legal) BrokerResult("MODIFY SL",trade.PositionModify(ticket,candidate,tp));
   }
}

void Evaluate(const MqlTick &tick)
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
      !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) { Log("REJECT: automated trading permission disabled"); return; }
   if(!storageOK) { Log("REJECT: durable state unavailable"); return; }
   if(Read("halt")!=0) { Log("REJECT: daily/streak safety halt"); return; }
   if(ExposureExists()) { Log("REJECT: account already has a position/order"); return; }
   MqlDateTime now; TimeToStruct(TimeCurrent(),now);
   if(now.day_of_week==0 || now.day_of_week==6 || now.hour<InpStartHour || now.hour>=InpEndHour ||
      (now.day_of_week==5 && now.hour>=InpFridayStopHour)) { Log("REJECT: server-time session/Friday filter"); return; }
   datetime loss; int streak;
   if(!LossState(loss,streak)) { Log("REJECT: trade history could not be reconstructed"); return; }
   if(streak>=InpMaxConsecutiveLosses) { Save("halt",1); GlobalVariablesFlush(); Log("REJECT: consecutive loss limit; halted until next server day"); return; }
   if(loss>0 && TimeCurrent()-loss<InpLossCooldownMinutes*60) { Log("REJECT: loss cooldown"); return; }
   if((tick.ask-tick.bid)/pip>InpMaxSpreadPips) { Log("REJECT: spread too wide"); return; }
   if(!SeriesInfoInteger(_Symbol,PERIOD_H1,SERIES_SYNCHRONIZED) || !SeriesInfoInteger(_Symbol,PERIOD_M15,SERIES_SYNCHRONIZED) ||
      BarsCalculated(ema200)<205) { Log("REJECT: historical bars not ready"); return; }
   double fast,slow,priorFast,mid,atr,hatr,adx,plus,minus;
   if(!BufferValue(ema50,0,1,fast) || !BufferValue(ema50,0,2,priorFast) || !BufferValue(ema200,0,1,slow) ||
      !BufferValue(ema20,0,1,mid) || !BufferValue(atr15,0,1,atr) || !BufferValue(atrH1,0,1,hatr) ||
      !BufferValue(adxH1,0,1,adx) || !BufferValue(adxH1,1,1,plus) || !BufferValue(adxH1,2,1,minus)) { Log("REJECT: indicator buffers unavailable"); return; }
   if(atr<=0 || hatr<=0 || atr/pip<InpMinATRPips || atr/pip>InpMaxATRPips) { Log("REJECT: ATR volatility filter"); return; }
   if(adx<InpMinADX || MathAbs(fast-slow)<InpMinTrendGapATR*hatr) { Log("REJECT: weak H1 trend"); return; }
   MqlRates b[]; ArraySetAsSeries(b,true);
   if(CopyRates(_Symbol,PERIOD_M15,1,8,b)!=8) { Log("REJECT: M15 bars unavailable"); return; }
   double range=b[0].high-b[0].low;
   if(range<=0 || MathAbs(b[0].close-b[0].open)<0.45*range || range>2.0*atr) { Log("REJECT: candle body/range filter"); return; }
   // Recent two-bar structure must rise/fall relative to preceding two-bar structure.
   double recentHigh=MathMax(b[1].high,b[2].high),olderHigh=MathMax(b[3].high,b[4].high);
   double recentLow=MathMin(b[1].low,b[2].low),olderLow=MathMin(b[3].low,b[4].low);
   bool buy=fast>slow && fast>priorFast && plus>minus && recentHigh>olderHigh && recentLow>olderLow &&
      b[0].low<=mid+0.15*atr && b[0].close>mid && b[0].close>b[0].open && b[0].close>b[1].high;
   bool sell=fast<slow && fast<priorFast && minus>plus && recentHigh<olderHigh && recentLow<olderLow &&
      b[0].high>=mid-0.15*atr && b[0].close<mid && b[0].close<b[0].open && b[0].close<b[1].low;
   if(!buy && !sell) { Log("NO SIGNAL: H1 direction / M15 structure / EMA pullback / candle confirmation"); return; }
   Log(StringFormat("SIGNAL %s: ADX=%.2f ATR=%.2f pips spread=%.2f pips",buy?"BUY":"SELL",adx,atr/pip,(tick.ask-tick.bid)/pip));
   if(MathAbs((buy?tick.ask:tick.bid)-b[0].close)>0.4*atr) { Log("REJECT: entry moved too far from signal close"); return; }
   long mode=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
   if(mode==SYMBOL_TRADE_MODE_DISABLED || mode==SYMBOL_TRADE_MODE_CLOSEONLY ||
      (buy && mode==SYMBOL_TRADE_MODE_SHORTONLY) || (!buy && mode==SYMBOL_TRADE_MODE_LONGONLY)) { Log("REJECT: symbol trade direction disabled"); return; }
   long orders=SymbolInfoInteger(_Symbol,SYMBOL_ORDER_MODE);
   if((orders&SYMBOL_ORDER_MARKET)==0 || (orders&SYMBOL_ORDER_SL)==0 || (orders&SYMBOL_ORDER_TP)==0) { Log("REJECT: market/SL/TP unsupported"); return; }
   double entry=buy?tick.ask:tick.bid;
   double distance=MathMax(InpStopATR*atr,(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point+(tick.ask-tick.bid)+2*_Point);
   double structure=buy?MathMin(b[0].low,recentLow)-0.2*atr:MathMax(b[0].high,recentHigh)+0.2*atr;
   double sl=TickRound(buy?MathMin(entry-distance,structure):MathMax(entry+distance,structure),buy?-1:1);
   distance=MathAbs(entry-sl);
   if(distance>4*atr) { Log("REJECT: structure stop too distant"); return; }
   double tp=TickRound(entry+(buy?1:-1)*distance*InpRewardRisk,buy?1:-1);
   ENUM_ORDER_TYPE type=buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   double vmin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double vmax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX),lossMin=0;
   if(vmin<=0 || step<=0 || !OrderCalcProfit(type,_Symbol,vmin,entry,sl,lossMin) || lossMin>=0) { Log("REJECT: broker risk calculation unavailable"); return; }
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double budget=MathMin(equity,AccountInfoDouble(ACCOUNT_BALANCE))*InpRiskPercent/100.0;
   double remaining=equity-Read("base")*(1-InpDailyLossPercent/100.0);
   budget=MathMin(budget,remaining);
   if(budget<=0) { Log("REJECT: no daily risk budget"); return; }
   double factor=1+InpCostReservePercent/100.0;
   // Include configured adverse execution deviation in sizing.
   double adverseEntry=entry+(buy?1:-1)*InpDeviationPoints*_Point;
   if(!OrderCalcProfit(type,_Symbol,vmin,adverseEntry,sl,lossMin) || lossMin>=0) { Log("REJECT: adverse fill risk unavailable"); return; }
   double raw=budget/(MathAbs(lossMin)*factor)*vmin;
   double lot=NormalizeDouble(MathFloor(MathMin(raw,vmax)/step)*step,8);
   if(lot<vmin) { Log(StringFormat("REJECT: minimum lot %.8f risk %.4f exceeds budget %.4f",vmin,MathAbs(lossMin)*factor,budget)); return; }
   double cashLoss=0,margin=0;
   if(!OrderCalcProfit(type,_Symbol,lot,adverseEntry,sl,cashLoss) || MathAbs(cashLoss)*factor>budget+0.00000001 ||
      !OrderCalcMargin(type,_Symbol,lot,adverseEntry,margin) || margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE)*(1-InpFreeMarginReservePercent/100.0)) { Log("REJECT: final risk/margin check"); return; }
   // Recheck global account exposure immediately before sending; one instance per account.
   if(ExposureExists()) { Log("REJECT: exposure changed before send"); return; }
   Log(StringFormat("ORDER: volume=%.8f SL=%.*f TP=%.*f reservedRisk=%.4f budget=%.4f",lot,_Digits,sl,_Digits,tp,MathAbs(cashLoss)*factor,budget));
   ResetLastError();
   bool sent=buy?trade.Buy(lot,_Symbol,0,sl,tp,"MicroSafe Pro v2"):trade.Sell(lot,_Symbol,0,sl,tp,"MicroSafe Pro v2");
   BrokerResult("ENTRY (no automatic retry)",sent);
}

int OnInit()
{
   if(InpRiskPercent<0.5 || InpRiskPercent>1 || InpDailyLossPercent<=0 || InpDailyLossPercent>2 ||
      InpMaxConsecutiveLosses<1 || InpMaxConsecutiveLosses>3 || InpLossCooldownMinutes<60 ||
      InpStopATR<=0 || InpRewardRisk<1 || InpBreakEvenR<=0 || InpTrailStartR<InpBreakEvenR || InpTrailATR<=0 ||
      InpMaxSpreadPips<=0 || InpMinATRPips<=0 || InpMaxATRPips<=InpMinATRPips || InpMinADX<0 || InpMinTrendGapATR<0 ||
      InpFridayStopHour<0 || InpFridayCloseHour<InpFridayStopHour || InpFridayCloseHour>23 ||
      InpStartHour<0 || InpEndHour>24 || InpStartHour>=InpEndHour || InpDeviationPoints<0 ||
      InpMaxTickAgeSeconds<1 || InpReconnectQuietSeconds<1 || InpCostReservePercent<0 ||
      InpFreeMarginReservePercent<0 || InpFreeMarginReservePercent>=100 || InpBreakEvenOffsetPips<0 || InpMagic==0) return INIT_PARAMETERS_INCORRECT;
   if(SymbolInfoString(_Symbol,SYMBOL_CURRENCY_BASE)!="EUR" || SymbolInfoString(_Symbol,SYMBOL_CURRENCY_PROFIT)!="USD") { Log("INIT FAILED: attach to broker EURUSD symbol (suffix allowed)"); return INIT_FAILED; }
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL && !InpAllowRealAccount) { Log("INIT FAILED: real account locked; demo first"); return INIT_FAILED; }
   pip=(_Digits==3 || _Digits==5)?10*_Point:_Point;
   // Isolate Strategy Tester state from live/demo terminal global variables.
   uint serverHash=2166136261;
   string server=AccountInfoString(ACCOUNT_SERVER)+"|"+_Symbol;
   for(int i=0;i<StringLen(server);i++) serverHash=(serverHash^(uint)StringGetCharacter(server,i))*16777619;
   key=StringFormat("%s.%u.%I64d.%I64u.",MQLInfoInteger(MQL_TESTER)?"MST2":"MSP2",serverHash,AccountInfoInteger(ACCOUNT_LOGIN),InpMagic);
   if(MQLInfoInteger(MQL_TESTER)) GlobalVariablesDeleteAll(key);
   if(StringLen(key)>48) { Log("INIT FAILED: state key too long"); return INIT_FAILED; }
   if(GlobalVariableCheck(K("day")) && (!GlobalVariableCheck(K("base")) || !GlobalVariableCheck(K("halt")) || !GlobalVariableCheck(K("streakEpoch")))) { Log("INIT FAILED: incomplete persisted day state"); return INIT_FAILED; }
   ema50=iMA(_Symbol,PERIOD_H1,50,0,MODE_EMA,PRICE_CLOSE);
   ema200=iMA(_Symbol,PERIOD_H1,200,0,MODE_EMA,PRICE_CLOSE);
   ema20=iMA(_Symbol,PERIOD_M15,20,0,MODE_EMA,PRICE_CLOSE);
   atr15=iATR(_Symbol,PERIOD_M15,14); atrH1=iATR(_Symbol,PERIOD_H1,14); adxH1=iADX(_Symbol,PERIOD_H1,14);
   if(ema50==INVALID_HANDLE || ema200==INVALID_HANDLE || ema20==INVALID_HANDLE || atr15==INVALID_HANDLE || atrH1==INVALID_HANDLE || adxH1==INVALID_HANDLE) return INIT_FAILED;
   trade.SetExpertMagicNumber(InpMagic); trade.SetDeviationInPoints(InpDeviationPoints); trade.SetAsyncMode(false);
   if(!trade.SetTypeFillingBySymbol(_Symbol)) return INIT_FAILED;
   lastBar=iTime(_Symbol,PERIOD_M15,0); quietUntil=TimeCurrent()+InpReconnectQuietSeconds;
   connected=(bool)TerminalInfoInteger(TERMINAL_CONNECTED);
   if(!EventSetTimer(1)) return INIT_FAILED;
   RiskDay();
   Log("Initialized. One instance per dedicated account. No old-bar entry on attach. Server-time daily/session limits. No profit guarantee.");
   return storageOK?INIT_SUCCEEDED:INIT_FAILED;
}
void OnTimer()
{
   bool live=(bool)TerminalInfoInteger(TERMINAL_CONNECTED);
   if(!live || !connected)
   {
      quietUntil=TimeCurrent()+InpReconnectQuietSeconds;
      lastBar=iTime(_Symbol,PERIOD_M15,0);
      if(live && !connected) Log("Connection restored: quiet interval, old signal discarded");
   }
   connected=live;
}
void OnTick()
{
   if(!TerminalInfoInteger(TERMINAL_CONNECTED)) { connected=false; return; }
   MqlTick tick; if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=tick.bid || tick.bid<=0) return;
   // TimeTradeServer estimates server clock between ticks. In tester it follows modeled time.
   datetime clock=TimeTradeServer();
   if(clock>0 && (clock-tick.time>InpMaxTickAgeSeconds || tick.time-clock>InpMaxTickAgeSeconds)) { Log("REJECT: stale/future quote"); return; }
   if(!connected) { connected=true; quietUntil=TimeCurrent()+InpReconnectQuietSeconds; lastBar=iTime(_Symbol,PERIOD_M15,0); }
   bool dayOK=RiskDay();
   MqlDateTime now; TimeToStruct(TimeCurrent(),now);
   if(!dayOK) CloseOwn("Safety halt: flatten owned positions");
   else if(now.day_of_week==5 && now.hour>=InpFridayCloseHour) CloseOwn("Friday mandatory exit");
   else Manage(tick);
   datetime bar=iTime(_Symbol,PERIOD_M15,0);
   if(bar==0 || bar==lastBar) return;
   lastBar=bar;
   if(TimeCurrent()<quietUntil) { Log("REJECT: startup/reconnect quiet interval"); return; }
   // Only first seconds of a new bar: never act on a delayed/replayed signal.
   if(TimeCurrent()-bar>30) { Log("REJECT: delayed M15 bar; signal discarded"); return; }
   if(GlobalVariableCheck(K("attemptBar")) && Read("attemptBar")>=(double)bar) { Log("REJECT: bar already evaluated before restart"); return; }
   // Persist before submission; a timeout must not cause a duplicate order retry.
   if(!Save("attemptBar",(double)bar)) return;
   GlobalVariablesFlush(); Evaluate(tick);
}
void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
{
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD && trans.deal>0 && HistoryDealSelect(trans.deal))
   {
      if(HistoryDealGetString(trans.deal,DEAL_SYMBOL)==_Symbol)
         Log(StringFormat("DEAL: ticket=%I64u position=%I64d entry=%d magic=%I64d profit=%.4f commission=%.4f swap=%.4f fee=%.4f",
            trans.deal,HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID),(int)HistoryDealGetInteger(trans.deal,DEAL_ENTRY),
            HistoryDealGetInteger(trans.deal,DEAL_MAGIC),HistoryDealGetDouble(trans.deal,DEAL_PROFIT),
            HistoryDealGetDouble(trans.deal,DEAL_COMMISSION),HistoryDealGetDouble(trans.deal,DEAL_SWAP),HistoryDealGetDouble(trans.deal,DEAL_FEE)));
   }
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   if(ema50!=INVALID_HANDLE) IndicatorRelease(ema50);
   if(ema200!=INVALID_HANDLE) IndicatorRelease(ema200);
   if(ema20!=INVALID_HANDLE) IndicatorRelease(ema20);
   if(atr15!=INVALID_HANDLE) IndicatorRelease(atr15);
   if(atrH1!=INVALID_HANDLE) IndicatorRelease(atrH1);
   if(adxH1!=INVALID_HANDLE) IndicatorRelease(adxH1);
   GlobalVariablesFlush();
}
