'use client';

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  Legend,
} from 'recharts';
import { motion } from 'framer-motion';

interface ChartData {
  name: string;
  value: number;
  color?: string;
}

interface LineChartData {
  date: string;
  reports: number;
  infractions: number;
}

const COLORS = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899'];

const tooltipStyle = {
  borderRadius: '0.75rem',
  border: '1px solid hsl(0 0% 90%)',
  boxShadow: '0 10px 25px -5px rgba(0,0,0,0.08)',
  fontSize: '0.875rem',
};

const chartCardVariants = {
  hidden: { opacity: 0, scale: 0.95 },
  show: { opacity: 1, scale: 1, transition: { duration: 0.4, ease: 'easeOut' as const } },
};

function ChartCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <motion.div
      className="bg-card rounded-xl border border-border/50 shadow-card p-6 glow-on-hover"
      variants={chartCardVariants}
      initial="hidden"
      animate="show"
      whileHover={{ y: -2 }}
      transition={{ duration: 0.3 }}
    >
      <h3 className="text-base font-semibold text-foreground mb-4">{title}</h3>
      <div className="h-64">
        {children}
      </div>
    </motion.div>
  );
}

export function ReportsByStatusChart({ data }: { data: ChartData[] }) {
  return (
    <ChartCard title="Reportes por Estado">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
            outerRadius={80}
            fill="#8884d8"
            dataKey="value"
            animationBegin={200}
            animationDuration={800}
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color || COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip contentStyle={tooltipStyle} />
        </PieChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

export function CitationsByStatusChart({ data }: { data: ChartData[] }) {
  return (
    <ChartCard title="Citaciones por Estado">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
            outerRadius={80}
            fill="#8884d8"
            dataKey="value"
            animationBegin={400}
            animationDuration={800}
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color || COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip contentStyle={tooltipStyle} />
        </PieChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

export function ActivityTrendChart({ data }: { data: LineChartData[] }) {
  return (
    <ChartCard title="Actividad Últimos 30 Días">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(0 0% 90%)" />
          <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="hsl(0 0% 45%)" />
          <YAxis tick={{ fontSize: 12 }} stroke="hsl(0 0% 45%)" />
          <Tooltip contentStyle={tooltipStyle} />
          <Legend />
          <Line
            type="monotone"
            dataKey="reports"
            stroke="#3B82F6"
            strokeWidth={2}
            name="Reportes"
            dot={{ r: 3 }}
            activeDot={{ r: 5 }}
          />
          <Line
            type="monotone"
            dataKey="infractions"
            stroke="#EF4444"
            strokeWidth={2}
            name="Infracciones"
            dot={{ r: 3 }}
            activeDot={{ r: 5 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

export function UsersByRoleChart({ data }: { data: ChartData[] }) {
  return (
    <ChartCard title="Usuarios por Rol">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={40}
            outerRadius={80}
            fill="#8884d8"
            paddingAngle={5}
            dataKey="value"
            animationBegin={600}
            animationDuration={800}
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color || COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip contentStyle={tooltipStyle} />
          <Legend />
        </PieChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}

export function TopInspectorsChart({ data }: { data: { name: string; count: number }[] }) {
  return (
    <ChartCard title="Top Inspectores">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(0 0% 90%)" />
          <XAxis dataKey="name" tick={{ fontSize: 12 }} stroke="hsl(0 0% 45%)" />
          <YAxis tick={{ fontSize: 12 }} stroke="hsl(0 0% 45%)" />
          <Tooltip contentStyle={tooltipStyle} />
          <Bar dataKey="count" fill="#8B5CF6" radius={[6, 6, 0, 0]} name="Infracciones" />
        </BarChart>
      </ResponsiveContainer>
    </ChartCard>
  );
}
