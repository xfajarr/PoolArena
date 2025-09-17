import { ReactNode } from "react";
import MobileNavigation from "./MobileNavigation";
import DesktopNavigation from "./DesktopNavigation";
import { useLocation } from "react-router-dom";

interface LayoutProps {
  children: ReactNode;
}

const Layout = ({ children }: LayoutProps) => {
  const location = useLocation();
  const isLandingPage = location.pathname === "/";

  return (
    <div className="min-h-screen bg-background">
      {/* Desktop Navigation - hidden on landing page */}
      {!isLandingPage && (
        <div className="hidden md:block">
          <DesktopNavigation />
        </div>
      )}
      
      {/* Main Content */}
      <main className={`relative z-0 ${!isLandingPage ? "md:pb-0 pb-20" : "pb-20"}`}>
        {children}
      </main>
      
      {/* Mobile Navigation - always shown */}
      <div className="md:hidden">
        <MobileNavigation />
      </div>
    </div>
  );
};

export default Layout;