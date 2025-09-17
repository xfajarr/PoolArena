import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import TournamentCard from "@/components/TournamentCard";
import JoinTournamentModal from "@/components/JoinTournamentModal";
import { Filter, Trophy, Target } from "lucide-react";

const Tournaments = () => {
  const [filter, setFilter] = useState<"all" | "live" | "upcoming">("all");
  const [joinTournamentOpen, setJoinTournamentOpen] = useState(false);
  const [selectedTournament, setSelectedTournament] = useState<any>(null);

  const tournaments = [
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
    {
      title: "Daily Lightning Battle #248",
      prizePool: "$2,800",
      participants: 0,
      timeLeft: "Starts in 6h",
      status: "upcoming" as const,
      type: "daily" as const,
    },
    {
      title: "Weekend Blitz Arena",
      prizePool: "$8,900",
      participants: 156,
      timeLeft: "Starts tomorrow",
      status: "upcoming" as const,
      type: "weekly" as const,
    },
    {
      title: "Daily Lightning Battle #246",
      prizePool: "$2,950",
      participants: 74,
      timeLeft: "Battle ended 2h ago",
      status: "ended" as const,
      type: "daily" as const,
    },
  ];

  const filteredTournaments = tournaments.filter(
    (tournament) => filter === "all" || tournament.status === filter
  );

  const handleJoinTournament = (tournament: any) => {
    setSelectedTournament(tournament);
    setJoinTournamentOpen(true);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Battle Arena</h1>
        <p className="text-muted-foreground">Join competitive LP battles and claim victory rewards</p>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4 mb-6">
        <Filter className="h-5 w-5 text-muted-foreground" />
        <div className="flex gap-2">
          {["all", "live", "upcoming"].map((filterOption) => (
            <Button
              key={filterOption}
              variant={filter === filterOption ? "default" : "outline"}
              size="sm"
              onClick={() => setFilter(filterOption as typeof filter)}
              className={filter === filterOption ? "glow-primary" : ""}
            >
              {filterOption.charAt(0).toUpperCase() + filterOption.slice(1)}
            </Button>
          ))}
        </div>
      </div>

      {/* Arena Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-card/50 backdrop-blur-sm border border-border rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-success">2</div>
          <div className="text-sm text-muted-foreground">Live Battles</div>
        </div>
        <div className="bg-card/50 backdrop-blur-sm border border-border rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-warning">4</div>
          <div className="text-sm text-muted-foreground">Starting Soon</div>
        </div>
        <div className="bg-card/50 backdrop-blur-sm border border-border rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-primary">$27.4K</div>
          <div className="text-sm text-muted-foreground">Total Rewards</div>
        </div>
        <div className="bg-card/50 backdrop-blur-sm border border-border rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-primary">567</div>
          <div className="text-sm text-muted-foreground">Active Warriors</div>
        </div>
      </div>

      {/* Battle Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {filteredTournaments.map((tournament, index) => (
          <TournamentCard
            key={index}
            {...tournament}
            onJoin={() => handleJoinTournament(tournament)}
          />
        ))}
      </div>

      {filteredTournaments.length === 0 && (
        <div className="text-center py-12">
          <p className="text-muted-foreground">No battles found for the selected filter.</p>
        </div>
      )}
      
      <JoinTournamentModal 
        open={joinTournamentOpen} 
        onOpenChange={setJoinTournamentOpen}
        tournament={selectedTournament}
      />
    </div>
  );
};

export default Tournaments;