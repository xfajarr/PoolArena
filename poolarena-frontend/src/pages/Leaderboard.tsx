import { useState } from "react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Crown, Medal, Award, TrendingUp, Users, Eye, Calendar, Clock, Trophy, Zap } from "lucide-react";

const Leaderboard = () => {
  const [activeTab, setActiveTab] = useState("daily");
  
  const dailyTopPlayers = [
    {
      rank: 1,
      address: "0x742...89A3",
      pnl: "***",
      pnlPercent: "+127.4%",
      status: "Active ✅",
      badges: ["Diamond Hands", "Yield Wizard"],
    },
    {
      rank: 2,
      address: "0x1B2...F4D8",
      pnl: "***", 
      pnlPercent: "+98.2%",
      status: "Active ✅",
      badges: ["Sharpshooter LP"],
    },
    {
      rank: 3,
      address: "0x9E1...C7B2",
      pnl: "***",
      pnlPercent: "+89.7%",
      status: "Active ✅",
      badges: ["Diamond Hands"],
    },
  ];

  const weeklyTopPlayers = [
    {
      rank: 1,
      address: "0x1A3...B8F2",
      pnl: "***",
      pnlPercent: "+342.8%",
      status: "Legend ⚡",
      badges: ["Week Champion", "Consistency King", "Volume Master"],
    },
    {
      rank: 2,
      address: "0x742...89A3",
      pnl: "***", 
      pnlPercent: "+289.4%",
      status: "Elite ✨",
      badges: ["Diamond Hands", "Strategy Master"],
    },
    {
      rank: 3,
      address: "0x9E1...C7B2",
      pnl: "***",
      pnlPercent: "+245.7%",
      status: "Champion 🏆",
      badges: ["Risk Navigator", "Yield Wizard"],
    },
  ];

  const dailyOtherPlayers = [
    { rankRange: "4-6", addresses: 3, avgPnl: "+High%" },
    { rankRange: "7-12", addresses: 6, avgPnl: "+Medium%" },
    { rankRange: "13-25", addresses: 13, avgPnl: "+Low%" },
    { rankRange: "26-50", addresses: 25, avgPnl: "Mixed" },
  ];

  const weeklyOtherPlayers = [
    { rankRange: "4-8", addresses: 5, avgPnl: "+Ultra High%" },
    { rankRange: "9-20", addresses: 12, avgPnl: "+Very High%" },
    { rankRange: "21-50", addresses: 30, avgPnl: "+High%" },
    { rankRange: "51-100", addresses: 50, avgPnl: "Positive" },
  ];

  const getRankIcon = (rank: number) => {
    if (rank === 1) return <Crown className="h-6 w-6 text-warning" />;
    if (rank === 2) return <Medal className="h-6 w-6 text-muted-foreground" />;
    if (rank === 3) return <Award className="h-6 w-6 text-warning/70" />;
    return null;
  };

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2 flex items-center gap-2">
          <Trophy className="h-8 w-8 text-warning" />
          Battle Rankings
        </h1>
        <p className="text-muted-foreground">Live tournament rankings with privacy protection</p>
      </div>

      {/* Privacy Notice */}
      <Card className="card-gaming p-4 mb-6 border-primary/20">
        <div className="flex items-center gap-3">
          <Eye className="h-5 w-5 text-primary" />
          <div className="text-sm">
            <span className="font-medium text-primary">Privacy Protected:</span>{" "}
            Exact values encrypted via Fhenix FHE. Rankings update in real-time.
          </div>
        </div>
      </Card>

      {/* Leaderboard Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="mb-8">
        <TabsList className="grid w-full grid-cols-2 max-w-md mx-auto">
          <TabsTrigger value="daily" className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            Daily Battles
          </TabsTrigger>
          <TabsTrigger value="weekly" className="flex items-center gap-2">
            <Calendar className="h-4 w-4" />
            Weekly Wars
          </TabsTrigger>
        </TabsList>

        <TabsContent value="daily" className="space-y-8 mt-8">
          {/* Daily Top 3 Champions */}
          <div>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Zap className="h-5 w-5 text-warning" />
              Daily Battle Champions
            </h2>
            
            <div className="grid gap-4">
              {dailyTopPlayers.map((player) => (
                <Card 
                  key={player.rank}
                  className={`card-gaming p-6 ${
                    player.rank === 1 ? "glow-primary animate-glow-pulse" : ""
                  }`}
                >
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-4">
                      <div className="flex items-center gap-2">
                        {getRankIcon(player.rank)}
                        <span className="text-2xl font-bold">#{player.rank}</span>
                      </div>
                      <div>
                        <div className="font-mono text-lg">{player.address}</div>
                        <div className="text-sm text-muted-foreground">{player.status}</div>
                      </div>
                    </div>
                    
                    <div className="text-right">
                      <div className="text-sm text-muted-foreground">PnL Value</div>
                      <div className="text-lg font-bold text-primary">{player.pnl}</div>
                      <div className={`text-sm font-medium ${
                        player.pnlPercent.startsWith('+') ? 'text-success' : 'text-destructive'
                      }`}>
                        {player.pnlPercent}
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex gap-2 flex-wrap">
                    {player.badges.map((badge) => (
                      <Badge key={badge} variant="outline" className="text-xs">
                        {badge}
                      </Badge>
                    ))}
                  </div>
                </Card>
              ))}
            </div>
          </div>

          {/* Daily Other Rankings */}
          <div>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Users className="h-5 w-5" />
              Other Daily Rankings (Encrypted)
            </h2>
            
            <div className="grid gap-3">
              {dailyOtherPlayers.map((group, index) => (
                <Card key={index} className="card-gaming p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="text-lg font-bold text-muted-foreground">
                        #{group.rankRange}
                      </div>
                      <div>
                        <div className="font-medium">{group.addresses} Players</div>
                        <div className="text-sm text-muted-foreground">Daily Rank Range</div>
                      </div>
                    </div>
                    
                    <div className="text-right">
                      <div className="text-lg font-bold text-primary">***</div>
                      <div className="text-sm text-muted-foreground">Avg: {group.avgPnl}</div>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        </TabsContent>

        <TabsContent value="weekly" className="space-y-8 mt-8">
          {/* Weekly Top 3 Champions */}
          <div>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Crown className="h-5 w-5 text-warning" />
              Weekly War Legends
            </h2>
            
            <div className="grid gap-4">
              {weeklyTopPlayers.map((player) => (
                <Card 
                  key={player.rank}
                  className={`card-gaming p-6 ${
                    player.rank === 1 ? "glow-primary animate-glow-pulse" : ""
                  }`}
                >
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-4">
                      <div className="flex items-center gap-2">
                        {getRankIcon(player.rank)}
                        <span className="text-2xl font-bold">#{player.rank}</span>
                      </div>
                      <div>
                        <div className="font-mono text-lg">{player.address}</div>
                        <div className="text-sm text-muted-foreground">{player.status}</div>
                      </div>
                    </div>
                    
                    <div className="text-right">
                      <div className="text-sm text-muted-foreground">Weekly PnL</div>
                      <div className="text-lg font-bold text-primary">{player.pnl}</div>
                      <div className={`text-sm font-medium ${
                        player.pnlPercent.startsWith('+') ? 'text-success' : 'text-destructive'
                      }`}>
                        {player.pnlPercent}
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex gap-2 flex-wrap">
                    {player.badges.map((badge) => (
                      <Badge key={badge} variant="outline" className="text-xs">
                        {badge}
                      </Badge>
                    ))}
                  </div>
                </Card>
              ))}
            </div>
          </div>

          {/* Weekly Other Rankings */}
          <div>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Users className="h-5 w-5" />
              Other Weekly Rankings (Encrypted)
            </h2>
            
            <div className="grid gap-3">
              {weeklyOtherPlayers.map((group, index) => (
                <Card key={index} className="card-gaming p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="text-lg font-bold text-muted-foreground">
                        #{group.rankRange}
                      </div>
                      <div>
                        <div className="font-medium">{group.addresses} Players</div>
                        <div className="text-sm text-muted-foreground">Weekly Rank Range</div>
                      </div>
                    </div>
                    
                    <div className="text-right">
                      <div className="text-lg font-bold text-primary">***</div>
                      <div className="text-sm text-muted-foreground">Avg: {group.avgPnl}</div>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        </TabsContent>
      </Tabs>

      {/* Your Battle Status */}
      <Card className="card-gaming p-6 mt-8 border-primary/30">
        <div className="text-center">
          <h3 className="text-lg font-bold mb-2">Your Battle Status</h3>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <div className="text-2xl font-bold text-primary">Top 10-20</div>
              <div className="text-sm text-muted-foreground">Current Range</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-success">+67.3%</div>
              <div className="text-sm text-muted-foreground">Battle Score</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-primary">Active ⚔️</div>
              <div className="text-sm text-muted-foreground">Battle Status</div>
            </div>
          </div>
        </div>
      </Card>
    </div>
  );
};

export default Leaderboard;