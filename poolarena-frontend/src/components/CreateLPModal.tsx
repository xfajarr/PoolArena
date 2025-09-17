import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { 
  Coins, 
  TrendingUp, 
  Zap, 
  Shield, 
  Target,
  ArrowRight,
  Wallet,
  Info
} from "lucide-react";

interface CreateLPModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const CreateLPModal = ({ open, onOpenChange }: CreateLPModalProps) => {
  const [step, setStep] = useState(1);
  const [selectedPool, setSelectedPool] = useState("");
  const [amount1, setAmount1] = useState("");
  const [amount2, setAmount2] = useState("");
  const [priceRange, setPriceRange] = useState({ min: "", max: "" });
  const { toast } = useToast();

  const popularPools = [
    { 
      name: "ETH/USDC", 
      apy: "12.5%", 
      volume: "$24.5M", 
      risk: "Low",
      description: "Most stable, perfect for beginners"
    },
    { 
      name: "WBTC/ETH", 
      apy: "18.7%", 
      volume: "$8.2M", 
      risk: "Medium",
      description: "Popular crypto pair with good yields"
    },
    { 
      name: "PEPE/ETH", 
      apy: "45.2%", 
      volume: "$15.1M", 
      risk: "High",
      description: "High risk, high reward memecoin pair"
    },
  ];

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case "Low": return "bg-success/10 text-success border-success/20";
      case "Medium": return "bg-warning/10 text-warning border-warning/20";
      case "High": return "bg-destructive/10 text-destructive border-destructive/20";
      default: return "bg-muted/10 text-muted-foreground border-muted/20";
    }
  };

  const handleCreateLP = () => {
    // Simulate LP creation
    toast({
      title: "LP Position Created! 🎉",
      description: "Your liquidity is now active and earning rewards. Ready to join battles!",
    });
    
    setStep(1);
    setSelectedPool("");
    setAmount1("");
    setAmount2("");
    setPriceRange({ min: "", max: "" });
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center space-x-2">
            <Coins className="h-5 w-5 text-primary" />
            <span>Create Your Battle Position</span>
          </DialogTitle>
        </DialogHeader>

        {step === 1 && (
          <div className="space-y-6">
            <div className="text-center p-4 bg-primary/5 rounded-lg border border-primary/20">
              <Zap className="h-8 w-8 text-primary mx-auto mb-2" />
              <h3 className="font-semibold mb-1">Choose Your Weapon</h3>
              <p className="text-sm text-muted-foreground">
                Select a liquidity pool to create your battle position. Each pool has different risk and reward levels.
              </p>
            </div>

            <div className="space-y-3">
              <Label className="text-base font-medium">Popular Battle Pools</Label>
              {popularPools.map((pool) => (
                <Card 
                  key={pool.name}
                  className={`p-4 cursor-pointer transition-all duration-200 hover:scale-[1.02] ${
                    selectedPool === pool.name ? "ring-2 ring-primary bg-primary/5" : "hover:bg-secondary/50"
                  }`}
                  onClick={() => setSelectedPool(pool.name)}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center space-x-3">
                      <div className="font-bold text-lg">{pool.name}</div>
                      <Badge className={getRiskColor(pool.risk)}>{pool.risk} Risk</Badge>
                    </div>
                    <div className="text-right">
                      <div className="text-lg font-bold text-success">{pool.apy}</div>
                      <div className="text-xs text-muted-foreground">Expected APY</div>
                    </div>
                  </div>
                  
                  <p className="text-sm text-muted-foreground mb-2">{pool.description}</p>
                  
                  <div className="flex items-center justify-between text-sm">
                    <div className="text-muted-foreground">24h Volume: {pool.volume}</div>
                    {selectedPool === pool.name && (
                      <div className="flex items-center text-primary">
                        <span className="text-xs">Selected</span>
                        <Target className="h-3 w-3 ml-1" />
                      </div>
                    )}
                  </div>
                </Card>
              ))}
            </div>

            <Button 
              className="w-full" 
              disabled={!selectedPool}
              onClick={() => setStep(2)}
            >
              Continue to Position Setup
              <ArrowRight className="h-4 w-4 ml-2" />
            </Button>
          </div>
        )}

        {step === 2 && (
          <div className="space-y-6">
            <div className="text-center p-4 bg-warning/5 rounded-lg border border-warning/20">
              <Shield className="h-8 w-8 text-warning mx-auto mb-2" />
              <h3 className="font-semibold mb-1">Set Your Battle Parameters</h3>
              <p className="text-sm text-muted-foreground">
                Configure your position size and price range for maximum efficiency.
              </p>
            </div>

            <Card className="p-4 bg-primary/5 border-primary/20">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium">Selected Pool</span>
                <Badge variant="outline">{selectedPool}</Badge>
              </div>
            </Card>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Token 1 Amount</Label>
                <Input
                  placeholder="0.0"
                  value={amount1}
                  onChange={(e) => setAmount1(e.target.value)}
                />
                <div className="text-xs text-muted-foreground">ETH Balance: 2.45</div>
              </div>
              
              <div className="space-y-2">
                <Label>Token 2 Amount</Label>
                <Input
                  placeholder="0.0"
                  value={amount2}
                  onChange={(e) => setAmount2(e.target.value)}
                />
                <div className="text-xs text-muted-foreground">USDC Balance: 5,240</div>
              </div>
            </div>

            <div className="space-y-4">
              <Label className="text-base font-medium">Price Range Strategy</Label>
              
              <div className="grid grid-cols-3 gap-3">
                <Button variant="outline" size="sm" onClick={() => setPriceRange({ min: "0.95", max: "1.05" })}>
                  <Target className="h-4 w-4 mr-2" />
                  Tight (±5%)
                </Button>
                <Button variant="outline" size="sm" onClick={() => setPriceRange({ min: "0.85", max: "1.15" })}>
                  <TrendingUp className="h-4 w-4 mr-2" />
                  Balanced (±15%)
                </Button>
                <Button variant="outline" size="sm" onClick={() => setPriceRange({ min: "0.70", max: "1.30" })}>
                  <Zap className="h-4 w-4 mr-2" />
                  Wide (±30%)
                </Button>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Min Price</Label>
                  <Input
                    placeholder="0.0"
                    value={priceRange.min}
                    onChange={(e) => setPriceRange({ ...priceRange, min: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Max Price</Label>
                  <Input
                    placeholder="0.0"
                    value={priceRange.max}
                    onChange={(e) => setPriceRange({ ...priceRange, max: e.target.value })}
                  />
                </div>
              </div>
            </div>

            <Card className="p-4 bg-info/5 border-info/20">
              <div className="flex items-start space-x-2">
                <Info className="h-4 w-4 text-info mt-0.5" />
                <div className="text-sm">
                  <div className="font-medium mb-1">Battle Tips:</div>
                  <ul className="text-muted-foreground space-y-1 text-xs">
                    <li>• Tighter ranges = Higher fees but more risk of going out of range</li>
                    <li>• Wider ranges = Lower fees but safer positioning</li>
                    <li>• You can adjust your position during battles</li>
                  </ul>
                </div>
              </div>
            </Card>

            <div className="flex space-x-3">
              <Button variant="outline" onClick={() => setStep(1)} className="flex-1">
                Back
              </Button>
              <Button 
                className="flex-1" 
                disabled={!amount1 || !amount2 || !priceRange.min || !priceRange.max}
                onClick={handleCreateLP}
              >
                <Wallet className="h-4 w-4 mr-2" />
                Create Position
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default CreateLPModal;