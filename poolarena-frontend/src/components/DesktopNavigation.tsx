import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { NavLink } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Trophy, BarChart3, User, Wallet, Gamepad2 } from "lucide-react";

const DesktopNavigation = () => {
  const navigationItems = [
    { label: "Arena", icon: Gamepad2, href: "/dashboard" },
    { label: "Battles", icon: Trophy, href: "/tournaments" },
    { label: "Rankings", icon: BarChart3, href: "/leaderboard" },
    { label: "Profile", icon: User, href: "/profile" },
  ];

  return (
    <header className="sticky top-0 z-50 bg-card/95 backdrop-blur-sm border-b border-border">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        {/* Logo */}
        <NavLink to="/" className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-gradient-to-br from-primary to-primary/70 rounded-lg flex items-center justify-center">
            <Trophy className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-xl font-bold text-gradient">PoolArena</span>
        </NavLink>

        {/* Navigation */}
        <nav className="hidden md:flex items-center space-x-1">
          {navigationItems.map((item) => (
            <NavLink
              key={item.href}
              to={item.href}
              className={({ isActive }) =>
                cn(
                  "flex items-center space-x-2 px-4 py-2 rounded-lg transition-all duration-200 text-sm font-medium",
                  isActive
                    ? "bg-primary/10 text-primary glow-primary/20"
                    : "text-muted-foreground hover:text-foreground hover:bg-secondary/50"
                )
              }
            >
              <item.icon className="h-4 w-4" />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        {/* Actions */}
        <div className="flex items-center space-x-3">
          <Badge variant="outline" className="hidden sm:flex items-center space-x-1">
            <div className="w-2 h-2 bg-success rounded-full animate-pulse" />
            <span className="text-xs">2 Live Battles</span>
          </Badge>
          
          <Button variant="outline" size="sm" className="hidden sm:flex items-center space-x-2">
            <Wallet className="h-4 w-4" />
            <span>Connect Wallet</span>
          </Button>
        </div>
      </div>
    </header>
  );
};

export default DesktopNavigation;