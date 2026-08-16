import { Outlet } from 'react-router-dom';
import AppSidebar from '@/components/AppSidebar';

export default function DashboardLayout() {
  return (
    <div className="flex min-h-screen bg-background relative">
      {/* Subtle background effects */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div className="absolute top-0 right-0 w-[800px] h-[800px] rounded-full opacity-[0.03]"
          style={{ background: 'radial-gradient(circle, hsl(270 100% 65%) 0%, transparent 70%)' }} />
        <div className="absolute bottom-0 left-1/3 w-[600px] h-[600px] rounded-full opacity-[0.02]"
          style={{ background: 'radial-gradient(circle, hsl(320 100% 60%) 0%, transparent 70%)' }} />
        <div className="absolute inset-0 opacity-[0.015]"
          style={{ backgroundImage: 'linear-gradient(hsl(270 100% 65%) 1px, transparent 1px), linear-gradient(90deg, hsl(270 100% 65%) 1px, transparent 1px)', backgroundSize: '80px 80px' }}
        />
      </div>
      <AppSidebar />
      <main className="flex-1 overflow-auto relative">
        <div className="p-8">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
