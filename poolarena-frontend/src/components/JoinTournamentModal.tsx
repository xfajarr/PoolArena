import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { useToast } from "@/hooks/use-toast";
import { 
  Trophy, 
  Users, 
  Clock, 
  Zap, 
  Shield, 
  Coins,
  Target,
  Sword,
  Crown,
  CheckCircle,
  Wallet,
  AlertTriangle
} from "lucide-react";

interface JoinTournamentModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  tournament: {
    title: string;
    prizePool: string;
    participants: number;
    timeLeft: string;
    status: "live" | "upcoming" | "ended";
    type: "daily" | "weekly";
  } | null;
}

const JoinTournamentModal = ({ open, onOpenChange, tournament }: JoinTournamentModalProps) => {
  const [step, setStep] = useState(1);
  const [selectedLP, setSelectedLP] = useState("");
  const [walletConnected, setWalletConnected] = useState(false);
  const { toast } = useToast();

  const userLPPositions = [
    { 
      id: "lp1", 
      pool: "ETH/USDC", 
      value: "$4,250", 
      apy: "12.5%",
      status: "Active",
      eligible: true,
      risk: "Low"
    },
    { 
      id: "lp2", 
      pool: "WBTC/ETH", 
      value: "$2,800", 
      apy: "18.7%",
      status: "Active", 
      eligible: true,
      risk: "Medium"
    },
    { 
      id: "lp3", 
      pool: "PEPE/ETH", 
      value: "$1,450", 
      apy: "45.2%",
      status: "Out of Range", 
      eligible: false,
      risk: "High"
    },
  ];

  const battleRules = [
    "Battle duration: Full tournament period",
    "LP position must stay active throughout",
    "Rewards based on fees earned vs other players",
    "Entry fee: 2% of your LP value (refunded if you finish top 50%)",
    "Early withdrawal = automatic disqualification"
  ];

  const handleJoinBattle = () => {
    if (!selectedLP) return;
    
    // Simulate joining tournament
    toast({
      title: "Battle Joined! ⚔️",
      description: `Welcome to ${tournament?.title}! You're now live in the arena. Good luck, warrior!`,
    });
    
    // Redirect to live tournament view after joining
    setTimeout(() => {
      window.location.href = `/tournaments/live/${tournament?.title.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '')}`;
    }, 2000);
    
    setStep(1);
    setSelectedLP("");
    onOpenChange(false);
  };

  const connectWallet = () => {
    // Simulate wallet connection
    setWalletConnected(true);
    setStep(2);
    toast({
      title: "Wallet Connected! 🔗",
      description: "Your battle positions are now loaded.",
    });
  };

  if (!tournament) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center space-x-2">
            <Sword className="h-5 w-5 text-primary" />
            <span>Join Battle: {tournament.title}</span>
          </DialogTitle>
        </DialogHeader>

        {/* Tournament Info Header */}
        <Card className="p-4 bg-gradient-to-r from-primary/10 to-warning/10 border-primary/20">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div>
              <Trophy className="h-5 w-5 text-warning mx-auto mb-1" />
              <div className="font-bold text-lg">{tournament.prizePool}</div>
              <div className="text-xs text-muted-foreground">Prize Pool</div>
            </div>
            <div>
              <Users className="h-5 w-5 text-primary mx-auto mb-1" />
              <div className="font-bold text-lg">{tournament.participants}</div>
              <div className="text-xs text-muted-foreground">Warriors</div>
            </div>
            <div>
              <Clock className="h-5 w-5 text-success mx-auto mb-1" />
              <div className="font-bold text-lg">{tournament.timeLeft}</div>
              <div className="text-xs text-muted-foreground">Time Left</div>
            </div>
            <div>
              <Crown className="h-5 w-5 text-warning mx-auto mb-1" />
              <div className="font-bold text-lg">{tournament.type === "daily" ? "24h" : "7d"}</div>
              <div className="text-xs text-muted-foreground">Duration</div>
            </div>
          </div>
        </Card>

        {step === 1 && !walletConnected && (
          <div className="space-y-6">
            <div className="text-center p-6 bg-secondary/30 rounded-lg">
              <Wallet className="h-12 w-12 text-primary mx-auto mb-4" />
              <h3 className="text-xl font-semibold mb-2">Ready to Battle?</h3>
              <p className="text-muted-foreground mb-4">
                Connect your wallet to view your LP positions and join the battle.
              </p>
              <Button onClick={connectWallet} className="glow-primary">
                <Wallet className="h-4 w-4 mr-2" />
                Connect Battle Wallet
              </Button>
            </div>

            <Card className="p-4">
              <h4 className="font-semibold mb-3 flex items-center">
                <Shield className="h-4 w-4 mr-2 text-primary" />
                Battle Rules
              </h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                {battleRules.map((rule, index) => (
                  <li key={index} className="flex items-start space-x-2">
                    <div className="w-1.5 h-1.5 bg-primary rounded-full mt-2 flex-shrink-0" />
                    <span>{rule}</span>
                  </li>
                ))}
              </ul>
            </Card>
          </div>
        )}

        {step === 2 && walletConnected && (
          <div className="space-y-6">
            <div className="text-center p-4 bg-success/5 rounded-lg border border-success/20">
              <Target className="h-8 w-8 text-success mx-auto mb-2" />
              <h3 className="font-semibold mb-1">Choose Your Battle Position</h3>
              <p className="text-sm text-muted-foreground">
                Select which LP position you want to battle with. Only eligible positions are shown.
              </p>
            </div>

            <div className="space-y-3">
              {userLPPositions.map((lp) => (
                <Card 
                  key={lp.id}
                  className={`p-4 cursor-pointer transition-all duration-200 ${
                    !lp.eligible 
                      ? "opacity-50 cursor-not-allowed" 
                      : selectedLP === lp.id 
                        ? "ring-2 ring-primary bg-primary/5 hover:scale-[1.02]" 
                        : "hover:bg-secondary/50 hover:scale-[1.01]"
                  }`}
                  onClick={() => lp.eligible && setSelectedLP(lp.id)}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <div className="w-10 h-10 bg-gradient-to-br from-primary/20 to-warning/20 rounded-lg flex items-center justify-center">
                        <Coins className="h-5 w-5 text-primary" />
                      </div>
                      
                      <div>
                        <div className="flex items-center space-x-2">
                          <h4 className="font-semibold">{lp.pool}</h4>
                          <Badge variant={lp.eligible ? "default" : "destructive"}>
                            {lp.eligible ? "Eligible" : "Not Eligible"}
                          </Badge>
                        </div>
                        <div className="flex items-center space-x-4 text-sm text-muted-foreground">
                          <span>Value: {lp.value}</span>
                          <span>APY: {lp.apy}</span>
                          <span>Status: {lp.status}</span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="text-right">
                      {lp.eligible ? (
                        selectedLP === lp.id ? (
                          <CheckCircle className="h-6 w-6 text-success" />
                        ) : (
                          <div className="w-6 h-6 border-2 border-muted rounded-full" />
                        )
                      ) : (
                        <AlertTriangle className="h-6 w-6 text-destructive" />
                      )}
                    </div>
                  </div>
                  
                  {!lp.eligible && (
                    <div className="mt-2 text-xs text-destructive bg-destructive/10 p-2 rounded">
                      Position out of range - rebalance to join battles
                    </div>
                  )}
                </Card>
              ))}
            </div>

            {selectedLP && (
              <Card className="p-4 bg-warning/5 border-warning/20">
                <div className="flex items-start space-x-2">
                  <Zap className="h-4 w-4 text-warning mt-0.5" />
                  <div className="text-sm">
                    <div className="font-medium mb-1">Battle Entry Fee</div>
                    <p className="text-muted-foreground">
                      Entry fee: <span className="text-warning font-semibold">$85</span> (2% of position value)
                      <br />
                      <span className="text-xs">💰 Refunded if you finish in top 50%</span>
                    </p>
                  </div>
                </div>
              </Card>
            )}

            <div className="flex space-x-3">
              <Button variant="outline" onClick={() => setStep(1)} className="flex-1">
                Back
              </Button>
              <Button 
                className="flex-1 glow-primary" 
                disabled={!selectedLP}
                onClick={handleJoinBattle}
              >
                <Sword className="h-4 w-4 mr-2" />
                Join Battle!
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default JoinTournamentModal;