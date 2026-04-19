import Sidebar from './Sidebar';
import Header from './Header';
import AnimatedLayout from './AnimatedLayout';
import SOSAlertProvider from '../notifications/SOSAlertProvider';

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SOSAlertProvider>
      <div className="min-h-screen bg-background">
        <Sidebar />
        <div className="md:pl-64 flex flex-col flex-1 transition-all duration-300">
          <Header />
          <main className="flex-1">
            <div className="py-6">
              <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <AnimatedLayout>
                  {children}
                </AnimatedLayout>
              </div>
            </div>
          </main>
        </div>
      </div>
    </SOSAlertProvider>
  );
}
