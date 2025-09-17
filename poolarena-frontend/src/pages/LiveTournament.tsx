import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { Separator } from "@/components/ui/separator";
import { 
  Trophy, 
  Users, 
  Clock, 
  TrendingUp, 
  TrendingDown,
  Zap,
  Target,
  Crown,
  Medal,
  Award,
  Activity,
  DollarSign,
  Timer,
  ChevronUp,
  ChevronDown,
  Minus,
  ArrowLeft,
  Volume2,
  VolumeX
} from "lucide-react";

const LiveTournament = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [participants, setParticipants] = useState([
    {
      id: 1,
      address: "0x742...89A3",
      position: "ETH/USDC",
      pnl: "$2,845",
      pnlPercent: "+127.4%",
      feesEarned: "$234.50",
      rank: 1,
      prevRank: 2,
      isActive: true,
      battleScore: 2847,
      entryTime: "2h 15m ago",
      lastUpdate: "2s ago"
    },
    {
      id: 2,
      address: "0x1B2...F4D8",
      position: "WBTC/ETH",
      pnl: "$2,198",
      pnlPercent: "+98.2%",
      feesEarned: "$189.20",
      rank: 2,
      prevRank: 1,
      isActive: true,
      battleScore: 2198,
      entryTime: "3h 42m ago",
      lastUpdate: "5s ago"
    },
    {
      id: 3,
      address: "0x9E1...C7B2",
      position: "PEPE/ETH",
      pnl: "$1,897",
      pnlPercent: "+89.7%",
      feesEarned: "$156.80",
      rank: 3,
      prevRank: 3,
      isActive: true,
      battleScore: 1897,
      entryTime: "1h 28m ago",
      lastUpdate: "1s ago"
    },
    {
      id: 4,
      address: "0x5C3...A8F1",
      position: "UNI/USDC",
      pnl: "$1,456",
      pnlPercent: "+67.3%",
      feesEarned: "$124.30",
      rank: 4,
      prevRank: 5,
      isActive: true,
      battleScore: 1456,
      entryTime: "4h 12m ago",
      lastUpdate: "3s ago"
    },
    {
      id: 5,
      address: "0x8A7...D2E9",
      position: "MATIC/ETH",
      pnl: "$1,289",
      pnlPercent: "+54.8%",
      feesEarned: "$98.70",
      rank: 5,
      prevRank: 4,
      isActive: false,
      battleScore: 1289,
      entryTime: "5h 33m ago",
      lastUpdate: "12s ago"
    }
  ]);

  const tournament = {
    title: "Daily Lightning Battle #247",
    prizePool: "$3,240",
    totalParticipants: 89,
    timeLeft: "3h 42m",
    status: "live",
    duration: "24h",
    entryFee: "$65",
    currentRewards: {
      first: "$1,296",
      second: "$648",
      third: "$324",
      topTen: "$97.20"
    }
  };

  useEffect(() => {
    // Simulate real-time updates
    const interval = setInterval(() => {
      setParticipants(prev => prev.map(p => ({
        ...p,
        lastUpdate: Math.random() > 0.7 ? "just now" : p.lastUpdate,
        pnl: Math.random() > 0.8 ? `$${(parseFloat(p.pnl.slice(1).replace(',', '')) + (Math.random() - 0.5) * 100).toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}` : p.pnl,
        feesEarned: Math.random() > 0.9 ? `$${(parseFloat(p.feesEarned.slice(1)) + Math.random() * 5).toFixed(2)}` : p.feesEarned
      })));
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  const getRankIcon = (rank: number) => {
    if (rank === 1) return <Crown className="h-5 w-5 text-warning" />;
    if (rank === 2) return <Medal className="h-5 w-5 text-muted-foreground" />;
    if (rank === 3) return <Award className="h-5 w-5 text-warning/70" />;
    return <span className="text-lg font-bold text-muted-foreground">#{rank}</span>;
  };

  const getRankChange = (rank: number, prevRank: number) => {
    if (rank < prevRank) return <ChevronUp className="h-4 w-4 text-success" />;
    if (rank > prevRank) return <ChevronDown className="h-4 w-4 text-destructive" />;
    return <Minus className="h-4 w-4 text-muted-foreground" />;
  };

  const progress = ((24 * 60 - (3 * 60 + 42)) / (24 * 60)) * 100;

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <Button 
            variant="outline" 
            size="sm" 
            onClick={() => navigate("/tournaments")}
            className="flex items-center gap-2"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Arena
          </Button>
          <div>
            <h1 className="text-2xl font-bold flex items-center gap-2">
              <Activity className="h-6 w-6 text-success animate-pulse" />
              {tournament.title}
            </h1>
            <p className="text-muted-foreground">Live Tournament Battle</p>
          </div>
        </div>
        
        <Button
          variant="outline"
          size="sm"
          onClick={() => setSoundEnabled(!soundEnabled)}
          className="flex items-center gap-2"
        >
          {soundEnabled ? <Volume2 className="h-4 w-4" /> : <VolumeX className="h-4 w-4" />}
          {soundEnabled ? "Sound On" : "Sound Off"}
        </Button>
      </div>

      {/* Tournament Status Bar */}
      <Card className="card-gaming p-6 mb-6 glow-primary animate-glow-pulse">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="text-center">
            <Trophy className="h-8 w-8 text-warning mx-auto mb-2" />
            <div className="text-2xl font-bold text-primary">{tournament.prizePool}</div>
            <div className="text-sm text-muted-foreground">Prize Pool</div>
          </div>
          
          <div className="text-center">
            <Users className="h-8 w-8 text-primary mx-auto mb-2" />
            <div className="text-2xl font-bold text-primary">{tournament.totalParticipants}</div>
            <div className="text-sm text-muted-foreground">Warriors</div>
          </div>
          
          <div className="text-center">
            <Timer className="h-8 w-8 text-warning mx-auto mb-2" />
            <div className="text-2xl font-bold text-warning">{tournament.timeLeft}</div>
            <div className="text-sm text-muted-foreground">Time Left</div>
          </div>
          
          <div className="text-center">
            <Target className="h-8 w-8 text-success mx-auto mb-2" />
            <div className="text-2xl font-bold text-success">{participants.filter(p => p.isActive).length}</div>
            <div className="text-sm text-muted-foreground">Active Now</div>
          </div>
        </div>
        
        <div className="mt-6">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm font-medium">Battle Progress</span>
            <span className="text-sm text-muted-foreground">{progress.toFixed(1)}% Complete</span>
          </div>
          <Progress value={progress} className="h-2" />
        </div>
      </Card>

      {/* Prize Distribution */}
      <Card className="card-gaming p-4 mb-6">
        <h3 className="font-bold mb-4 flex items-center gap-2">
          <DollarSign className="h-5 w-5 text-warning" />
          Live Reward Distribution
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="text-center p-3 bg-warning/10 rounded-lg border border-warning/20">
            <Crown className="h-5 w-5 text-warning mx-auto mb-1" />
            <div className="font-bold text-warning">{tournament.currentRewards.first}</div>
            <div className="text-xs text-muted-foreground">1st Place</div>
          </div>
          <div className="text-center p-3 bg-secondary/50 rounded-lg">
            <Medal className="h-5 w-5 text-muted-foreground mx-auto mb-1" />
            <div className="font-bold">{tournament.currentRewards.second}</div>
            <div className="text-xs text-muted-foreground">2nd Place</div>
          </div>
          <div className="text-center p-3 bg-secondary/50 rounded-lg">
            <Award className="h-5 w-5 text-warning/70 mx-auto mb-1" />
            <div className="font-bold">{tournament.currentRewards.third}</div>
            <div className="text-xs text-muted-foreground">3rd Place</div>
          </div>
          <div className="text-center p-3 bg-secondary/50 rounded-lg">
            <Target className="h-5 w-5 text-primary mx-auto mb-1" />
            <div className="font-bold text-primary">{tournament.currentRewards.topTen}</div>
            <div className="text-xs text-muted-foreground">Top 10</div>
          </div>
        </div>
      </Card>

      {/* Live Rankings */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Live Battle Rankings
          </h2>
          <Badge variant="outline" className="text-success border-success">
            <Activity className="h-3 w-3 mr-1 animate-pulse" />
            Live Updates
          </Badge>
        </div>

        {participants.map((participant, index) => (
          <Card 
            key={participant.id} 
            className={`card-gaming p-6 transition-all duration-500 hover:scale-[1.01] ${
              participant.rank === 1 ? "glow-primary animate-glow-pulse" : ""
            } ${participant.prevRank !== participant.rank ? "animate-rank-bounce" : ""}`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-6">
                {/* Rank */}
                <div className="flex items-center gap-2">
                  {getRankIcon(participant.rank)}
                  {getRankChange(participant.rank, participant.prevRank)}
                </div>
                
                {/* Player Info */}
                <div>
                  <div className="flex items-center gap-3 mb-1">
                    <span className="font-mono text-lg font-bold">{participant.address}</span>
                    <Badge variant={participant.isActive ? "default" : "secondary"}>
                      {participant.isActive ? "🟢 Active" : "⚪ Idle"}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-4 text-sm text-muted-foreground">
                    <span>Position: {participant.position}</span>
                    <span>Entry: {participant.entryTime}</span>
                    <span className="flex items-center gap-1">
                      <Zap className="h-3 w-3" />
                      Updated: {participant.lastUpdate}
                    </span>
                  </div>
                </div>
              </div>
              
              {/* Performance Stats */}
              <div className="text-right">
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <div className="text-lg font-bold text-primary">{participant.pnl}</div>
                    <div className="text-xs text-muted-foreground">PnL Value</div>
                  </div>
                  <div>
                    <div className={`text-lg font-bold ${
                      participant.pnlPercent.startsWith('+') ? 'text-success' : 'text-destructive'
                    }`}>
                      {participant.pnlPercent}
                    </div>
                    <div className="text-xs text-muted-foreground">PnL %</div>
                  </div>
                  <div>
                    <div className="text-lg font-bold text-warning">{participant.feesEarned}</div>
                    <div className="text-xs text-muted-foreground">Fees Earned</div>
                  </div>
                </div>
              </div>
            </div>
            
            {/* Battle Score Progress */}
            <div className="mt-4">
              <div className="flex justify-between items-center mb-2">
                <span className="text-xs text-muted-foreground">Battle Score</span>
                <span className="text-xs font-medium text-primary">{participant.battleScore}</span>
              </div>
              <Progress 
                value={(participant.battleScore / 3000) * 100} 
                className="h-1.5"
              />
            </div>
          </Card>
        ))}
      </div>

      {/* Your Status */}
      <Card className="card-gaming p-6 mt-8 border-primary/30">
        <div className="text-center">
          <h3 className="text-lg font-bold mb-4 flex items-center justify-center gap-2">
            <Target className="h-5 w-5 text-primary" />
            Your Battle Status
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <div className="text-2xl font-bold text-warning">Not Joined</div>
              <div className="text-sm text-muted-foreground">Current Status</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-primary">{tournament.entryFee}</div>
              <div className="text-sm text-muted-foreground">Entry Fee</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-success">{tournament.timeLeft}</div>
              <div className="text-sm text-muted-foreground">Time to Join</div>
            </div>
          </div>
          
          <Separator className="my-6" />
          
          <Button 
            size="lg" 
            className="glow-primary text-lg px-8 py-6"
            onClick={() => navigate("/tournaments")}
          >
            <Zap className="h-5 w-5 mr-2" />
            Join This Battle Now!
          </Button>
        </div>
      </Card>
    </div>
  );
};

export default LiveTournament;