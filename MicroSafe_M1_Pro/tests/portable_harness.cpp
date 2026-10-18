// Tests only. Implementations are extracted verbatim from the EA by check_portable.py.
#include "portable_logic.hpp"
#include <array>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <random>
#include <string>

namespace {
unsigned long checks = 0, failures = 0;
void Check(bool ok, const std::string &what) {
    ++checks;
    if (!ok) {
        ++failures;
        if (failures <= 20) std::cerr << "FAIL: " << what << '\n';
    }
}
MSFeatures BuyFixture() {
    MSFeatures f{};
    f.m5fast=100; f.m5slow=99; f.m5previous=99.5; f.adx=22; f.diPlus=30; f.diMinus=15;
    f.emaNow=100.2; f.emaPrevious=100; f.atr=1;
    f.breakoutHigh=101.4; f.breakoutLow=98.6;
    f.signal={100,101.2,99.9,101.1};
    f.pullback={100.15,100.5,99.7,100.1};
    return f;
}
MSBar MirrorBar(const MSBar &b, double center) {
    return {center-b.open,center-b.low,center-b.high,center-b.close};
}
MSFeatures Mirror(const MSFeatures &f, double center=2000) {
    MSFeatures g=f;
    g.m5fast=center-f.m5fast; g.m5slow=center-f.m5slow; g.m5previous=center-f.m5previous;
    g.emaNow=center-f.emaNow; g.emaPrevious=center-f.emaPrevious;
    g.breakoutHigh=center-f.breakoutLow; g.breakoutLow=center-f.breakoutHigh;
    g.diPlus=f.diMinus; g.diMinus=f.diPlus;
    g.signal=MirrorBar(f.signal,center); g.pullback=MirrorBar(f.pullback,center);
    return g;
}
MSFeatures Transform(MSFeatures f, double scale, double offset) {
    for (double *p : {&f.m5fast,&f.m5slow,&f.m5previous,&f.emaNow,&f.emaPrevious,&f.breakoutHigh,&f.breakoutLow,
                     &f.signal.open,&f.signal.high,&f.signal.low,&f.signal.close,
                     &f.pullback.open,&f.pullback.high,&f.pullback.low,&f.pullback.close}) *p=*p*scale+offset;
    f.atr*=scale;
    return f;
}
int Direction(const MSFeatures &f, int &reason, int &pattern, bool pullback=true, bool breakout=true) {
    return MSDirection(f,16,pullback,breakout,reason,pattern);
}
int Direction(const MSFeatures &f, int &reason) { int pattern=-1; return Direction(f,reason,pattern); }
void ExpectRejected(const MSFeatures &f, int expectedReason, const std::string &label) {
    int reason=-1,pattern=-1;
    Check(Direction(f,reason,pattern)==0,label+" rejected");
    Check(reason==expectedReason,label+" reason");
    Check(pattern==0,label+" no pattern");
    int mirroredReason=-1;
    Check(Direction(Mirror(f),mirroredReason,pattern)==0,label+" SELL mirror rejected");
    Check(mirroredReason==expectedReason,label+" SELL mirror reason");
    Check(pattern==0,label+" SELL mirror no pattern");
}
void ExpectSignal(const MSFeatures &f, int expectedPattern, bool pullback, bool breakout, const std::string &label) {
    int reason=-1,pattern=-1;
    Check(Direction(f,reason,pattern,pullback,breakout)==1,label+" BUY accepted");
    Check(reason==0 && pattern==expectedPattern,label+" BUY pattern");
    Check(Direction(Mirror(f),reason,pattern,pullback,breakout)==-1,label+" SELL accepted");
    Check(reason==0 && pattern==expectedPattern,label+" SELL pattern");
}
void SignalFixtures() {
    int reason=-1;
    Check(Direction(BuyFixture(),reason)==1 && reason==0,"valid BUY fixture");
    Check(Direction(Mirror(BuyFixture()),reason)==-1 && reason==0,"valid mirrored SELL fixture");
    auto f=BuyFixture(); f.adx=15.99; ExpectRejected(f,3,"weak ADX");
    f=BuyFixture(); f.pullback={100.35,100.6,100.3,100.4}; ExpectRejected(f,4,"no EMA pullback and no breakout");
    f=BuyFixture(); f.pullback.high=101.15; ExpectRejected(f,4,"no prior-high breakout");
    f=BuyFixture(); f.signal={100,103,99.9,102.9}; ExpectRejected(f,2,"oversized candle with strong body");
    f=BuyFixture(); f.signal.open=100.9; ExpectRejected(f,2,"weak candle body");
    f=BuyFixture(); f.m5previous=f.m5fast; ExpectRejected(f,4,"flat M5 trend slope");
    f=BuyFixture(); f.diPlus=f.diMinus; ExpectRejected(f,4,"equal directional movement");
    f=BuyFixture(); f.m5fast=f.m5slow; ExpectRejected(f,4,"flat M5 trend");
    f=BuyFixture(); f.atr=0; ExpectRejected(f,1,"zero ATR");
    f=BuyFixture(); f.signal.high=f.signal.low; ExpectRejected(f,1,"zero-range signal");
    f=BuyFixture(); f.pullback.low=f.pullback.high+1; ExpectRejected(f,1,"malformed pullback range");
    f=BuyFixture(); f.adx=16; Check(Direction(f,reason)==1,"ADX exactly at threshold accepted");
    f=BuyFixture(); f.signal.close=f.signal.high+0.1; ExpectRejected(f,1,"close outside signal OHLC");
    f=BuyFixture(); f.pullback.open=f.pullback.low-0.1; ExpectRejected(f,1,"open outside pullback OHLC");
    f=BuyFixture(); f.breakoutHigh=f.breakoutLow-1; ExpectRejected(f,1,"inverted breakout levels");
    f=BuyFixture(); f.breakoutHigh=100.8; f.signal={99.9,102,99.8,101};
    ExpectRejected(f,4,"BUY close outside top35percent despite valid body and breakout");

    // Pullback fixture deliberately does not clear the five-bar breakout level.
    ExpectSignal(BuyFixture(),1,true,false,"pullback-only enabled");
    ExpectSignal(BuyFixture(),1,true,true,"pullback independent of breakout");
    int pattern=-1;
    Check(Direction(BuyFixture(),reason,pattern,false,true)==0 && reason==4 && pattern==0,"disabled pullback cannot leak through breakout");
    Check(Direction(Mirror(BuyFixture()),reason,pattern,false,true)==0 && reason==4 && pattern==0,"disabled SELL pullback cannot leak through breakout");

    f=BuyFixture(); f.pullback={100.35,100.7,100.3,100.4}; f.breakoutHigh=100.8;
    ExpectSignal(f,2,false,true,"breakout-only enabled without EMA touch");
    ExpectSignal(f,2,true,true,"breakout independent of pullback");
    Check(Direction(f,reason,pattern,true,false)==0 && reason==4 && pattern==0,"disabled breakout does not trigger pullback");
    Check(Direction(Mirror(f),reason,pattern,true,false)==0 && reason==4 && pattern==0,"disabled SELL breakout does not trigger pullback");
    Check(Direction(f,reason,pattern,false,false)==0 && reason==4 && pattern==0,"both disabled produce no entry");
    Check(Direction(Mirror(f),reason,pattern,false,false)==0 && reason==4 && pattern==0,"both disabled produce no SELL entry");
    f.emaNow=f.signal.close-1.6*f.atr;
    ExpectRejected(f,4,"breakout too extended from EMA");
    f=BuyFixture(); f.breakoutHigh=100.8;
    ExpectSignal(f,1,true,true,"pullback takes precedence when both patterns pass");
    ExpectSignal(f,2,false,true,"breakout selected when overlapping pullback disabled");
    f=BuyFixture(); f.adx=-1; ExpectRejected(f,1,"negative ADX");
    f=BuyFixture(); f.diPlus=-1; ExpectRejected(f,1,"negative directional indicator");
    f=BuyFixture(); f.signal.low=0;
    Check(Direction(f,reason,pattern)==0 && reason==1 && pattern==0,"nonpositive candle price invalid");
    for (int field=0;field<6;++field) {
        f=BuyFixture();
        const std::array<double *,6> prices={&f.m5fast,&f.m5slow,&f.m5previous,&f.emaNow,&f.emaPrevious,&f.breakoutLow};
        *prices[static_cast<std::size_t>(field)]=0;
        Check(Direction(f,reason,pattern)==0 && reason==1 && pattern==0,"nonpositive indicator/level rejected");
    }
    for (double invalid : {std::numeric_limits<double>::quiet_NaN(),
                           std::numeric_limits<double>::infinity(),-std::numeric_limits<double>::infinity()}) {
        f=BuyFixture(); f.atr=invalid; ExpectRejected(f,1,"nonfinite ATR");
        f=BuyFixture(); f.adx=invalid; ExpectRejected(f,1,"nonfinite ADX");
        f=BuyFixture(); f.signal.close=invalid; ExpectRejected(f,1,"nonfinite OHLC");
        Check(MSDirection(BuyFixture(),invalid,true,true,reason,pattern)==0 && reason==1 && pattern==0,"nonfinite ADX threshold invalid");
    }
}
void VolumeFixtures() {
    // EURUSD Standard 0.01 lot, five-pip SL: $0.50 raw loss, no invented fee model.
    Check(MSVolume(50*0.005,0.50,0.01,50,0.01)==0,"$50 Standard minimum lot exceeds 0.5% risk");
    const double volume500=MSVolume(500*0.005,0.50,0.01,50,0.01);
    Check(volume500>=0.01 && volume500<=0.05+1e-12,"$500 Standard supports a valid lot");
    Check(volume500/0.01*0.50<=2.50+1e-12,"$500 raw SL loss remains in budget");
    const double costs=0.627; // independently supplied min-lot loss including a hypothetical cost reserve
    const double reserved=MSVolume(2.5,costs,0.01,50,0.01);
    Check(reserved/0.01*costs<=2.50+1e-12,"cost-inclusive minimum-lot loss remains in budget");
    Check(MSVolume(0,1,0.01,50,0.01)==0,"zero risk budget rejected");
    Check(MSVolume(-1,1,0.01,50,0.01)==0,"negative risk budget rejected");
    Check(MSVolume(1,0,0.01,50,0.01)==0,"zero minimum-lot loss rejected");
    Check(MSVolume(1,-1,0.01,50,0.01)==0,"negative minimum-lot loss rejected");
    Check(MSVolume(1,1,0,50,0.01)==0,"invalid minimum lot rejected");
    Check(MSVolume(1,1,0.01,0.001,0.01)==0,"maximum below minimum rejected");
    Check(MSVolume(1,1,0.01,50,0)==0,"zero lot step rejected");
    Check(MSVolume(0.49,0.50,0.01,50,0.01)==0,"minimum lot never forced above budget");
    Check(MSVolume(0.50,0.50,0.01,50,0.01)==0.01,"minimum lot allowed exactly at risk budget");
    Check(std::abs(MSVolume(1000,0.5,0.01,0.10,0.01)-0.10)<1e-12,"maximum volume cap obeyed");
    Check(std::abs(MSVolume(1000,0.5,0.01,0.105,0.01)-0.10)<1e-12,"maximum volume rounds down to step");
    const std::array<double,3> invalid={std::numeric_limits<double>::quiet_NaN(),
                                      std::numeric_limits<double>::infinity(),-std::numeric_limits<double>::infinity()};
    for (double v:invalid) {
        Check(MSVolume(v,1,0.01,50,0.01)==0,"nonfinite budget rejected");
        Check(MSVolume(1,v,0.01,50,0.01)==0,"nonfinite minimum-lot loss rejected");
        Check(MSVolume(1,1,v,50,0.01)==0,"nonfinite minimum lot rejected");
        Check(MSVolume(1,1,0.01,v,0.01)==0,"nonfinite maximum lot rejected");
        Check(MSVolume(1,1,0.01,50,v)==0,"nonfinite step rejected");
    }
}
void VolumeProperties(std::mt19937_64 &rng) {
    std::uniform_real_distribution<double> logarithm(-5,5), rawLoss(0.0001,1000);
    const std::array<double,6> steps={0.001,0.01,0.1,0.25,0.5,1};
    for (int i=0;i<12000;++i) {
        const double step=steps[static_cast<std::size_t>(i)%steps.size()];
        const double vmin=step*(1+(i%3));
        const double vmax=step*(10+(i%200));
        const double budget=std::pow(10.0,logarithm(rng));
        const double loss=rawLoss(rng);
        const double volume=MSVolume(budget,loss,vmin,vmax,step);
        const double tolerance=1e-9*std::max(1.0,budget);
        Check(std::isfinite(volume) && volume>=0,"volume finite and nonnegative");
        Check(volume<=vmax+1e-9,"volume respects broker maximum");
        Check(volume==0 || volume>=vmin-1e-9,"positive volume respects broker minimum");
        Check(std::abs(volume/step-std::round(volume/step))<1e-7,"volume lies on broker step grid");
        Check(volume/vmin*loss<=budget+tolerance,"volume risk never exceeds budget");
        Check(budget>=loss || volume==0,"insufficient minimum-lot budget fails closed");
        const double smaller=MSVolume(budget*0.99,loss,vmin,vmax,step);
        Check(smaller<=volume+1e-9,"lower budget cannot increase volume");
    }
}
void SignalProperties(std::mt19937_64 &rng) {
    std::uniform_real_distribution<double> scale(0.001,3), offset(20,1000), perturb(-2,2);
    for (int i=0;i<5000;++i) {
        const double multiplier=scale(rng);
        auto f=Transform(BuyFixture(),multiplier,offset(rng));
        int reason=-1,mirrorReason=-1;
        Check(Direction(f,reason)==1,"affine-transformed BUY fixture accepted");
        Check(Direction(Mirror(f,5000),reason)==-1,"affine-transformed SELL fixture accepted");
        // Vary regimes/thresholds and pullbacks while retaining valid OHLC candles.
        f.adx=16+perturb(rng)*4;
        f.m5previous+=perturb(rng)*multiplier;
        f.m5fast+=perturb(rng)*multiplier;
        f.emaPrevious+=perturb(rng)*multiplier;
        f.breakoutHigh+=perturb(rng)*multiplier;
        if (i%4==0) f.signal.open=f.signal.close-0.01*multiplier;
        if (i%7==0) f.atr*=0.2;
        int pattern=-1,mirrorPattern=-1;
        const bool pullback=i%3!=0,breakout=i%5!=0;
        const int direction=Direction(f,reason,pattern,pullback,breakout);
        const int opposite=Direction(Mirror(f,5000),mirrorReason,mirrorPattern,pullback,breakout);
        Check(direction>=-1 && direction<=1,"direction is BUY/SELL/NONE only");
        Check(opposite==-direction,"BUY/SELL mirror symmetry across varied regimes");
        Check(reason==mirrorReason,"mirror retains rejection category");
        Check(pattern==mirrorPattern,"mirror retains selected pattern");
        Check(direction==0?pattern==0:(pattern==1||pattern==2),"signal pattern agrees with direction");
        Check((pattern!=1||pullback) && (pattern!=2||breakout),"selected pattern respects independent toggles");
    }
}
} // namespace
int main() {
    SignalFixtures(); VolumeFixtures();
    std::mt19937_64 rng(20261018);
    VolumeProperties(rng); SignalProperties(rng);
    std::cout << checks << " arithmetic assertions; " << failures << " failures; "
              << "12000 volume cases and 5000 signal symmetry cases (deterministic seed).\n";
    return failures==0?EXIT_SUCCESS:EXIT_FAILURE;
}
