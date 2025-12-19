import Link from 'next/link';

interface StatCardProps {
  title: string;
  value: string | number;
  icon?: React.ReactNode;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  color?: 'blue' | 'green' | 'yellow' | 'red' | 'indigo' | 'purple';
  href?: string;
}

export default function StatCard({ title, value, icon, trend, color = 'blue', href }: StatCardProps) {
  const colors = {
    blue: 'bg-blue-500',
    green: 'bg-green-500',
    yellow: 'bg-yellow-500',
    red: 'bg-red-500',
    indigo: 'bg-indigo-500',
    purple: 'bg-purple-500',
  };

  const content = (
    <div className="p-5">
      <div className="flex items-center">
        {icon && (
          <div className={`flex-shrink-0 rounded-md p-3 ${colors[color]}`}>
            <div className="text-white">
              {icon}
            </div>
          </div>
        )}
        <div className={`${icon ? 'ml-5' : ''} w-0 flex-1`}>
          <dl>
            <dt className="text-sm font-medium text-gray-500 truncate">
              {title}
            </dt>
            <dd className="flex items-baseline">
              <div className="text-2xl font-semibold text-gray-900">
                {value}
              </div>
              {trend && (
                <div className={`ml-2 flex items-baseline text-sm font-semibold ${trend.isPositive ? 'text-green-600' : 'text-red-600'}`}>
                  <span>{trend.isPositive ? '↑' : '↓'}</span>
                  <span className="ml-1">{Math.abs(trend.value)}%</span>
                </div>
              )}
            </dd>
          </dl>
        </div>
      </div>
    </div>
  );

  if (href) {
    return (
      <Link href={href} className="block">
        <div className="bg-white overflow-hidden shadow rounded-lg hover:shadow-lg hover:scale-105 transition-all cursor-pointer">
          {content}
        </div>
      </Link>
    );
  }

  return (
    <div className="bg-white overflow-hidden shadow rounded-lg hover:shadow-md transition-shadow">
      {content}
    </div>
  );
}
