import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import TournamentCard from "@/components/TournamentCard";
import CreateLPModal from "@/components/CreateLPModal";
import JoinTournamentModal from "@/components/JoinTournamentModal";
import { Plus, Wallet, TrendingUp, Award, Zap, Target, Crown, Trophy } from "lucide-react";

const Dashboard = () => {
  const [createLPOpen, setCreateLPOpen] = useState(false);
  const [joinTournamentOpen, setJoinTournamentOpen] = useState(false);
  const [selectedTournament, setSelectedTournament] = useState<any>(null);
  const activeTournaments = [
    {
      title: "Daily Lightning Battle #247",
      prizePool: "$3,240",
      participants: 89,
      timeLeft: "4h 23m left",
      status: "live" as const,
      type: "daily" as const,
    },
    {
      title: "Weekly Championship Arena",
      prizePool: "$12,450",
      participants: 247,
      timeLeft: "2d 14h left",
      status: "live" as const,
      type: "weekly" as const,
    },
  ];

  const userPositions = [
    {
      pool: "ETH/USDC",
      value: "$4,250",
      pnl: "+$340",
      pnlPercent: "+8.7%",
      apy: "12.5%",
      status: "Active Battle Ready",
      risk: "Low"
    },
    {
      pool: "WBTC/ETH", 
      value: "$2,800",
      pnl: "+$180",
      pnlPercent: "+6.9%",
      apy: "18.7%",
      status: "Active Battle Ready",
      risk: "Medium"
    },
  ];

  const userStats = [
    { label: "Battle Winnings", value: "$1,247.50", icon: TrendingUp, color: "text-success" },
    { label: "Victories", value: "3", icon: Award, color: "text-warning" },
    { label: "Arena Rank", value: "#42", icon: Crown, color: "text-primary" },
  ];

  const handleJoinTournament = (tournament: any) => {
    setSelectedTournament(tournament);
    setJoinTournamentOpen(true);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Battle Arena</h1>
        <p className="text-muted-foreground">Manage your battle positions and join epic tournaments</p>
      </div>

      {/* User Stats */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        {userStats.map((stat, index) => (
          <Card key={index} className="card-gaming p-4 text-center">
            <stat.icon className={`h-6 w-6 mx-auto mb-2 ${stat.color}`} />
            <div className="text-lg font-bold">{stat.value}</div>
            <div className="text-xs text-muted-foreground">{stat.label}</div>
          </Card>
        ))}
      </div>

      {/* Battle Positions */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold flex items-center">
            <Target className="h-5 w-5 mr-2 text-primary" />
            Your Battle Positions
          </h2>
          <Button variant="outline" size="sm" onClick={() => setCreateLPOpen(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Create Position
          </Button>
        </div>
        
        {userPositions.length > 0 ? (
          <div className="grid gap-4 md:grid-cols-2">
            {userPositions.map((position, index) => (
              <Card key={index} className="card-gaming p-6 hover:scale-[1.02] transition-all duration-300">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-bold">{position.pool}</h3>
                    <p className="text-sm text-muted-foreground">{position.status}</p>
                  </div>
                  <div className="flex items-center space-x-1">
                    <Zap className="h-4 w-4 text-success" />
                    <span className="text-sm font-medium text-success">Ready</span>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div className="text-center p-3 bg-secondary/50 rounded-lg">
                    <div className="text-lg font-bold">{position.value}</div>
                    <div className="text-xs text-muted-foreground">Position Value</div>
                  </div>
                  <div className="text-center p-3 bg-secondary/50 rounded-lg">
                    <div className="text-lg font-bold text-success">{position.pnl}</div>
                    <div className="text-xs text-muted-foreground">Total P&L</div>
                  </div>
                </div>
                
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">APY: {position.apy}</span>
                  <span className={`font-medium ${position.pnl.startsWith('+') ? 'text-success' : 'text-destructive'}`}>
                    {position.pnlPercent}
                  </span>
                </div>
              </Card>
            ))}
          </div>
        ) : (
          <Card className="card-gaming p-6">
            <div className="flex items-center justify-center py-8 text-muted-foreground">
              <Wallet className="h-8 w-8 mr-3" />
              <div className="text-center">
                <p className="font-medium mb-1">No battle positions found</p>
                <p className="text-sm">Create your first position to enter the arena</p>
              </div>
            </div>
          </Card>
        )}
      </div>

      {/* Live Battles */}
      <div>
        <h2 className="text-xl font-bold mb-4 flex items-center">
          <Trophy className="h-5 w-5 mr-2 text-warning" />
          Live Battle Arena
        </h2>
        <div className="grid gap-4 md:grid-cols-2">
          {activeTournaments.map((tournament, index) => (
            <TournamentCard
              key={index}
              {...tournament}
              onJoin={() => handleJoinTournament(tournament)}
            />
          ))}
        </div>
      </div>
      
      <CreateLPModal open={createLPOpen} onOpenChange={setCreateLPOpen} />
      <JoinTournamentModal 
        open={joinTournamentOpen} 
        onOpenChange={setJoinTournamentOpen}
        tournament={selectedTournament}
      />
    </div>
  );
};

export default Dashboard;