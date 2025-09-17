import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import { 
  Trophy, 
  Target, 
  Flame, 
  Award, 
  TrendingUp, 
  Calendar,
  Zap,
  Crown,
  Coins,
  Star
} from "lucide-react";

const Profile = () => {
  const playerStats = [
    { label: "Total Winnings", value: "$3,247.50", icon: Coins, color: "text-success", change: "+$247 this week" },
    { label: "Battles Won", value: "17", icon: Trophy, color: "text-warning", change: "3 wins this week" },
    { label: "Current League", value: "Gold", icon: Crown, color: "text-primary", change: "Promoted last week" },
    { label: "Win Rate", value: "68%", icon: Target, color: "text-success", change: "+2% this month" },
  ];

  const achievements = [
    { name: "Diamond Hands", description: "Held position for 30+ days", icon: "💎", rarity: "Legendary" },
    { name: "Yield Hunter", description: "Earned 100%+ APY", icon: "🎯", rarity: "Epic" },
    { name: "Speed Demon", description: "Won daily battle in <1 hour", icon: "⚡", rarity: "Rare" },
    { name: "Sharpshooter", description: "Perfect price range 5 times", icon: "🎯", rarity: "Epic" },
    { name: "Battle Veteran", description: "Completed 25+ battles", icon: "⚔️", rarity: "Common" },
  ];

  const recentBattles = [
    { name: "Daily Sprint #247", result: "Victory", reward: "$240", rank: "3rd", date: "2 hours ago" },
    { name: "Weekly Championship", result: "Active", reward: "TBD", rank: "5th", date: "In progress" },
    { name: "Daily Sprint #246", result: "Defeat", reward: "$0", rank: "12th", date: "1 day ago" },
    { name: "Weekend Blitz", result: "Victory", reward: "$180", rank: "7th", date: "3 days ago" },
  ];

  const getRarityColor = (rarity: string) => {
    switch (rarity) {
      case "Legendary": return "border-warning bg-warning/10 text-warning";
      case "Epic": return "border-primary bg-primary/10 text-primary"; 
      case "Rare": return "border-blue-400 bg-blue-400/10 text-blue-400";
      default: return "border-muted-foreground bg-muted/10 text-muted-foreground";
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Player Profile</h1>
        <p className="text-muted-foreground">Your battle stats and achievements</p>
      </div>

      <div className="grid lg:grid-cols-3 gap-8">
        {/* Left Column - Profile Info */}
        <div className="lg:col-span-1 space-y-6">
          {/* Player Card */}
          <Card className="card-gaming p-6 text-center">
            <Avatar className="w-20 h-20 mx-auto mb-4 border-2 border-primary">
              <AvatarFallback className="bg-primary/20 text-2xl">P1</AvatarFallback>
            </Avatar>
            
            <h2 className="text-xl font-bold mb-1">Player #1247</h2>
            <p className="text-muted-foreground text-sm mb-4">0x742d...89A3</p>
            
            <div className="flex items-center justify-center space-x-2 mb-4">
              <Crown className="h-5 w-5 text-warning" />
              <span className="text-lg font-semibold text-warning">Gold League</span>
            </div>
            
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Progress to Platinum</span>
                <span className="text-primary">750/1000 XP</span>
              </div>
              <Progress value={75} className="h-2" />
            </div>
          </Card>

          {/* Quick Stats */}
          <Card className="card-gaming p-6">
            <h3 className="font-semibold mb-4 flex items-center">
              <Zap className="h-4 w-4 mr-2 text-primary" />
              Quick Stats
            </h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Battle Streak</span>
                <div className="flex items-center space-x-1">
                  <Flame className="h-4 w-4 text-warning" />
                  <span className="font-medium">5 wins</span>
                </div>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Best Rank</span>
                <span className="font-medium">#2 Global</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Total Battles</span>
                <span className="font-medium">47</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Member Since</span>
                <span className="font-medium">Dec 2024</span>
              </div>
            </div>
          </Card>
        </div>

        {/* Right Column - Stats & History */}
        <div className="lg:col-span-2 space-y-6">
          {/* Performance Stats */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {playerStats.map((stat, index) => (
              <Card key={index} className="card-gaming p-4 text-center">
                <stat.icon className={`h-6 w-6 mx-auto mb-2 ${stat.color}`} />
                <div className="text-lg font-bold">{stat.value}</div>
                <div className="text-xs text-muted-foreground mb-1">{stat.label}</div>
                <div className="text-xs text-success">{stat.change}</div>
              </Card>
            ))}
          </div>

          {/* Achievements */}
          <Card className="card-gaming p-6">
            <h3 className="text-lg font-semibold mb-4 flex items-center">
              <Award className="h-5 w-5 mr-2 text-warning" />
              Battle Achievements
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {achievements.map((achievement, index) => (
                <div key={index} className={`p-3 rounded-lg border ${getRarityColor(achievement.rarity)}`}>
                  <div className="flex items-start space-x-3">
                    <span className="text-2xl">{achievement.icon}</span>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center space-x-2">
                        <h4 className="font-medium truncate">{achievement.name}</h4>
                        <Badge variant="outline" className="text-xs">{achievement.rarity}</Badge>
                      </div>
                      <p className="text-xs text-muted-foreground mt-1">{achievement.description}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          {/* Recent Battles */}
          <Card className="card-gaming p-6">
            <h3 className="text-lg font-semibold mb-4 flex items-center">
              <Calendar className="h-5 w-5 mr-2 text-primary" />
              Recent Battles
            </h3>
            <div className="space-y-3">
              {recentBattles.map((battle, index) => (
                <div key={index} className="flex items-center justify-between p-3 bg-secondary/30 rounded-lg">
                  <div className="flex-1">
                    <h4 className="font-medium">{battle.name}</h4>
                    <div className="flex items-center space-x-4 text-sm text-muted-foreground mt-1">
                      <span>Rank: {battle.rank}</span>
                      <span>{battle.date}</span>
                    </div>
                  </div>
                  <div className="text-right">
                    <Badge 
                      variant={battle.result === "Victory" ? "default" : battle.result === "Active" ? "secondary" : "destructive"}
                      className="mb-1"
                    >
                      {battle.result}
                    </Badge>
                    <div className="text-sm font-medium">{battle.reward}</div>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default Profile;