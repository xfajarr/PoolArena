import { Home, Trophy, BarChart3, User } from "lucide-react";
import { NavLink } from "react-router-dom";
import { cn } from "@/lib/utils";

const navigationItems = [
  {
    label: "Home",
    icon: Home,
    href: "/dashboard",
  },
  {
    label: "Tournaments",
    icon: Trophy,
    href: "/tournaments",
  },
  {
    label: "Leaderboard",
    icon: BarChart3,
    href: "/leaderboard",
  },
  {
    label: "Profile",
    icon: User,
    href: "/profile",
  },
];

const MobileNavigation = () => {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-card/95 backdrop-blur-sm border-t border-border">
      <div className="grid grid-cols-4 h-16">
        {navigationItems.map((item) => (
          <NavLink
            key={item.href}
            to={item.href}
            className={({ isActive }) =>
              cn(
                "flex flex-col items-center justify-center gap-1 text-xs transition-colors duration-200",
                isActive
                  ? "text-primary font-semibold"
                  : "text-muted-foreground hover:text-foreground"
              )
            }
          >
            <item.icon className="h-5 w-5" />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </div>
    </nav>
  );
};

export default MobileNavigation;