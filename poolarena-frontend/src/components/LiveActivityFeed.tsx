import { useState, useEffect } from "react";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { 
  TrendingUp, 
  TrendingDown, 
  Zap, 
  Trophy, 
  Target,
  DollarSign,
  Activity,
  Crown
} from "lucide-react";

interface ActivityItem {
  id: string;
  type: "rank_change" | "big_win" | "new_join" | "milestone";
  address: string;
  message: string;
  timestamp: string;
  value?: string;
  icon: React.ReactNode;
  color: string;
}

const LiveActivityFeed = () => {
  const [activities, setActivities] = useState<ActivityItem[]>([
    {
      id: "1",
      type: "rank_change",
      address: "0x742...89A3",
      message: "moved to #1 position!",
      timestamp: "2s ago",
      value: "+$234",
      icon: <Crown className="h-4 w-4" />,
      color: "text-warning"
    },
    {
      id: "2", 
      type: "big_win",
      address: "0x9E1...C7B2",
      message: "earned massive fees!",
      timestamp: "15s ago",
      value: "+$156",
      icon: <DollarSign className="h-4 w-4" />,
      color: "text-success"
    },
    {
      id: "3",
      type: "new_join",
      address: "0x5A7...B9F1",
      message: "joined the battle!",
      timestamp: "45s ago",
      icon: <Zap className="h-4 w-4" />,
      color: "text-primary"
    }
  ]);

  useEffect(() => {
    const interval = setInterval(() => {
      // Simulate new activities
      if (Math.random() > 0.7) {
        const newActivity: ActivityItem = {
          id: Date.now().toString(),
          type: "rank_change",
          address: `0x${Math.random().toString(16).substr(2, 3)}...${Math.random().toString(16).substr(2, 4)}`,
          message: Math.random() > 0.5 ? "climbed the ranks!" : "earned big fees!",
          timestamp: "just now",
          value: `+$${(Math.random() * 200).toFixed(0)}`,
          icon: Math.random() > 0.5 ? <TrendingUp className="h-4 w-4" /> : <DollarSign className="h-4 w-4" />,
          color: Math.random() > 0.5 ? "text-success" : "text-warning"
        };

        setActivities(prev => [newActivity, ...prev.slice(0, 9)]);
      }
    }, 4000);

    return () => clearInterval(interval);
  }, []);

  return (
    <Card className="card-gaming p-4">
      <div className="flex items-center gap-2 mb-4">
        <Activity className="h-5 w-5 text-primary animate-pulse" />
        <h3 className="font-bold">Live Battle Feed</h3>
        <Badge variant="outline" className="text-xs">
          Real-time
        </Badge>
      </div>
      
      <ScrollArea className="h-64">
        <div className="space-y-3">
          {activities.map((activity) => (
            <div 
              key={activity.id}
              className="flex items-center gap-3 p-2 rounded-lg hover:bg-secondary/50 transition-colors animate-slide-up"
            >
              <div className={`${activity.color}`}>
                {activity.icon}
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="text-sm">
                  <span className="font-mono text-xs">{activity.address}</span>{" "}
                  <span className="text-muted-foreground">{activity.message}</span>
                  {activity.value && (
                    <span className={`ml-1 font-medium ${activity.color}`}>
                      {activity.value}
                    </span>
                  )}
                </div>
                <div className="text-xs text-muted-foreground">{activity.timestamp}</div>
              </div>
            </div>
          ))}
        </div>
      </ScrollArea>
    </Card>
  );
};

export default LiveActivityFeed;