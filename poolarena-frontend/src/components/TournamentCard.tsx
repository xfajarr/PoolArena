import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Trophy, Users, Clock, TrendingUp } from "lucide-react";

interface TournamentCardProps {
  title: string;
  prizePool: string;
  participants: number;
  timeLeft: string;
  status: "live" | "upcoming" | "ended";
  type: "daily" | "weekly";
  onJoin?: () => void;
}

const TournamentCard = ({
  title,
  prizePool,
  participants,
  timeLeft,
  status,
  type,
  onJoin,
}: TournamentCardProps) => {
  const statusConfig = {
    live: { color: "text-success", bg: "bg-success/10", label: "🔴 LIVE" },
    upcoming: { color: "text-warning", bg: "bg-warning/10", label: "⏳ Soon" },
    ended: { color: "text-muted-foreground", bg: "bg-muted/10", label: "✅ Ended" },
  };

  const typeConfig = {
    daily: { color: "bg-primary/10 text-primary", label: "Daily" },
    weekly: { color: "bg-accent/10 text-accent", label: "Weekly" },
  };

  return (
    <Card className="card-gaming p-6 hover:scale-[1.02] transition-all duration-300 hover:glow-primary/50">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <Badge className={typeConfig[type].color}>
              {typeConfig[type].label}
            </Badge>
            <Badge className={statusConfig[status].bg + " " + statusConfig[status].color}>
              {statusConfig[status].label}
            </Badge>
          </div>
          <h3 className="text-xl font-bold">{title}</h3>
        </div>
        <Trophy className="h-6 w-6 text-primary" />
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="text-center p-3 bg-secondary/50 rounded-lg">
          <div className="text-2xl font-bold text-primary">{prizePool}</div>
          <div className="text-xs text-muted-foreground">Prize Pool</div>
        </div>
        
        <div className="text-center p-3 bg-secondary/50 rounded-lg">
          <div className="text-2xl font-bold text-primary">{participants}</div>
          <div className="text-xs text-muted-foreground flex items-center justify-center gap-1">
            <Users className="h-3 w-3" />
            Players
          </div>
        </div>
      </div>

      {/* Time Left */}
      <div className="flex items-center justify-center gap-2 mb-4 p-2 bg-muted/30 rounded-lg">
        <Clock className="h-4 w-4 text-warning" />
        <span className="text-sm font-medium">{timeLeft}</span>
      </div>

      {/* Action Button */}
      <div className="space-y-2">
        <Button 
          onClick={onJoin}
          className="w-full glow-primary"
          disabled={status === "ended"}
        >
          {status === "live" ? (
            <>
              <TrendingUp className="h-4 w-4 mr-2" />
              Join Live Battle
            </>
          ) : status === "upcoming" ? (
            "Register Now"
          ) : (
            "View Results"
          )}
        </Button>
        
        {status === "live" && (
          <Button 
            variant="outline" 
            size="sm" 
            className="w-full"
            onClick={() => window.location.href = `/tournaments/live/${title.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '')}`}
          >
            👁️ Watch Live
          </Button>
        )}
      </div>
    </Card>
  );
};

export default TournamentCard;