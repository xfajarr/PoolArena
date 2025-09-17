import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Trophy, Users, Shield, Zap } from "lucide-react";
import heroBg from "@/assets/hero-bg.jpg";

const LandingHero = () => {
  return (
    <div className="relative min-h-screen bg-background overflow-hidden">
      {/* Hero Background */}
      <div 
        className="absolute inset-0 bg-cover bg-center bg-no-repeat opacity-20"
        style={{ backgroundImage: `url(${heroBg})` }}
      />
      
      {/* Gradient Overlay */}
      <div className="absolute inset-0 bg-gradient-to-b from-background/80 via-background/90 to-background" />
      
      {/* Content */}
      <div className="relative z-10 container mx-auto px-4 pt-20 pb-16">
        {/* Main Hero */}
        <div className="text-center mb-16 animate-slide-up">
          <h1 className="text-5xl md:text-7xl font-bold mb-6">
            <span className="text-gradient">Turn Your LP Into a Game</span> 🎮
          </h1>
          <p className="text-xl md:text-2xl text-muted-foreground mb-8 max-w-3xl mx-auto">
            Turn your Uniswap V4 LP positions into competitive gaming. Compete with others while keeping your strategies encrypted and private by Fhenix.
          </p>
            <Button
            size="lg"
            className="glow-primary animate-glow-pulse text-lg px-8 py-6 rounded-xl font-semibold"
            asChild
            >
            <a href="/dashboard">
              Join Tournament Now
            </a>
            </Button>
        </div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
          <Card className="card-gaming p-6 text-center hover:scale-105 transition-transform duration-300">
            <Trophy className="h-12 w-12 text-primary mx-auto mb-4" />
            <h3 className="font-bold text-lg mb-2">Daily & Weekly Tournaments</h3>
            <p className="text-sm text-muted-foreground">Compete regularly with dynamic prize pools</p>
          </Card>
          
          <Card className="card-gaming p-6 text-center hover:scale-105 transition-transform duration-300">
            <Users className="h-12 w-12 text-primary mx-auto mb-4" />
            <h3 className="font-bold text-lg mb-2">Global Leaderboards</h3>
            <p className="text-sm text-muted-foreground">Real-time rankings with encrypted data</p>
          </Card>
          
          <Card className="card-gaming p-6 text-center hover:scale-105 transition-transform duration-300">
            <Shield className="h-12 w-12 text-primary mx-auto mb-4" />
            <h3 className="font-bold text-lg mb-2">Privacy Protected</h3>
            <p className="text-sm text-muted-foreground">FHE encryption keeps your data secure</p>
          </Card>
          
          <Card className="card-gaming p-6 text-center hover:scale-105 transition-transform duration-300">
            <Zap className="h-12 w-12 text-primary mx-auto mb-4" />
            <h3 className="font-bold text-lg mb-2">Instant LP Creation</h3>
            <p className="text-sm text-muted-foreground">Create positions directly in PoolArena</p>
          </Card>
        </div>

        {/* Live Tournament Teaser */}
        <div className="bg-card/50 backdrop-blur-sm border border-border rounded-2xl p-8 text-center">
          <h2 className="text-3xl font-bold mb-4">🏆 Live Tournament</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div>
              <div className="text-2xl font-bold text-primary">$12,450</div>
              <div className="text-sm text-muted-foreground">Prize Pool</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-primary">247</div>
              <div className="text-sm text-muted-foreground">Participants</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-warning">2h 34m</div>
              <div className="text-sm text-muted-foreground">Time Left</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-success">Live</div>
              <div className="text-sm text-muted-foreground">Status</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LandingHero;