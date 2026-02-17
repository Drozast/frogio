'use client';

import { useState, useEffect, useCallback } from 'react';
import { ChevronLeftIcon, ChevronRightIcon } from '@heroicons/react/24/outline';

interface ActivityData {
  trips: number;
  totalKm: number;
}

interface ActivityCalendarProps {
  vehicleId: string;
  selectedDate: string;
  onDateSelect: (date: string) => void;
}

const DAYS_OF_WEEK = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const MONTHS = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];

export default function ActivityCalendar({
  vehicleId,
  selectedDate,
  onDateSelect,
}: ActivityCalendarProps) {
  const [currentDate, setCurrentDate] = useState(() => {
    const date = selectedDate ? new Date(selectedDate + 'T12:00:00') : new Date();
    return { year: date.getFullYear(), month: date.getMonth() };
  });
  const [activityDays, setActivityDays] = useState<Set<string>>(new Set());
  const [activityByDate, setActivityByDate] = useState<Record<string, ActivityData>>({});
  const [loading, setLoading] = useState(false);
  const [hoveredDate, setHoveredDate] = useState<string | null>(null);

  const fetchActivityDays = useCallback(async () => {
    if (!vehicleId) {
      setActivityDays(new Set());
      setActivityByDate({});
      return;
    }

    setLoading(true);
    try {
      const response = await fetch(
        `/api/fleet/activity-days?vehicleId=${vehicleId}&year=${currentDate.year}&month=${currentDate.month + 1}`
      );

      if (response.ok) {
        const data = await response.json();
        setActivityDays(new Set(data.dates || []));
        setActivityByDate(data.activityByDate || {});
      }
    } catch (error) {
      console.error('Error fetching activity days:', error);
    } finally {
      setLoading(false);
    }
  }, [vehicleId, currentDate.year, currentDate.month]);

  useEffect(() => {
    fetchActivityDays();
  }, [fetchActivityDays]);

  const getDaysInMonth = (year: number, month: number) => {
    return new Date(year, month + 1, 0).getDate();
  };

  const getFirstDayOfMonth = (year: number, month: number) => {
    const day = new Date(year, month, 1).getDay();
    return day === 0 ? 6 : day - 1;
  };

  const previousMonth = () => {
    setCurrentDate(prev => {
      if (prev.month === 0) {
        return { year: prev.year - 1, month: 11 };
      }
      return { year: prev.year, month: prev.month - 1 };
    });
  };

  const nextMonth = () => {
    const now = new Date();
    const nextDate = new Date(currentDate.year, currentDate.month + 1, 1);
    if (nextDate > now) return;

    setCurrentDate(prev => {
      if (prev.month === 11) {
        return { year: prev.year + 1, month: 0 };
      }
      return { year: prev.year, month: prev.month + 1 };
    });
  };

  const handleDateClick = (day: number) => {
    const dateStr = `${currentDate.year}-${String(currentDate.month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    onDateSelect(dateStr);
  };

  const isToday = (day: number) => {
    const today = new Date();
    return (
      today.getDate() === day &&
      today.getMonth() === currentDate.month &&
      today.getFullYear() === currentDate.year
    );
  };

  const isSelected = (day: number) => {
    if (!selectedDate) return false;
    const dateStr = `${currentDate.year}-${String(currentDate.month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return dateStr === selectedDate;
  };

  const isFutureDate = (day: number) => {
    const date = new Date(currentDate.year, currentDate.month, day);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return date > today;
  };

  const hasActivity = (day: number) => {
    const dateStr = `${currentDate.year}-${String(currentDate.month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return activityDays.has(dateStr);
  };

  const getActivityInfo = (day: number): ActivityData | null => {
    const dateStr = `${currentDate.year}-${String(currentDate.month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return activityByDate[dateStr] || null;
  };

  const clearDate = () => {
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];
    onDateSelect(todayStr);
  };

  const daysInMonth = getDaysInMonth(currentDate.year, currentDate.month);
  const firstDay = getFirstDayOfMonth(currentDate.year, currentDate.month);
  const days = Array.from({ length: daysInMonth }, (_, i) => i + 1);
  const paddingDays = Array.from({ length: firstDay }, (_, i) => i);

  const canGoNext = () => {
    const now = new Date();
    const nextDate = new Date(currentDate.year, currentDate.month + 1, 1);
    return nextDate <= now;
  };

  return (
    <div className="bg-gray-900 rounded-xl p-4 text-white shadow-lg">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <button
          onClick={previousMonth}
          className="p-1 hover:bg-gray-700 rounded-lg transition-colors"
        >
          <ChevronLeftIcon className="h-5 w-5" />
        </button>
        <div className="flex items-center gap-2">
          <span className="font-medium capitalize">
            {MONTHS[currentDate.month]} de {currentDate.year}
          </span>
          {loading && (
            <div className="w-4 h-4 border-2 border-indigo-400 border-t-transparent rounded-full animate-spin" />
          )}
        </div>
        <button
          onClick={nextMonth}
          disabled={!canGoNext()}
          className="p-1 hover:bg-gray-700 rounded-lg transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
        >
          <ChevronRightIcon className="h-5 w-5" />
        </button>
      </div>

      {/* Days of week */}
      <div className="grid grid-cols-7 gap-1 mb-2">
        {DAYS_OF_WEEK.map((day) => (
          <div
            key={day}
            className="text-center text-xs text-gray-400 font-medium py-1"
          >
            {day}
          </div>
        ))}
      </div>

      {/* Calendar grid */}
      <div className="grid grid-cols-7 gap-1">
        {/* Padding for first week */}
        {paddingDays.map((i) => (
          <div key={`pad-${i}`} className="aspect-square" />
        ))}

        {/* Days */}
        {days.map((day) => {
          const future = isFutureDate(day);
          const activity = hasActivity(day);
          const selected = isSelected(day);
          const today = isToday(day);
          const activityInfo = getActivityInfo(day);
          const dateStr = `${currentDate.year}-${String(currentDate.month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;

          return (
            <div key={day} className="relative">
              <button
                onClick={() => !future && handleDateClick(day)}
                onMouseEnter={() => activity && setHoveredDate(dateStr)}
                onMouseLeave={() => setHoveredDate(null)}
                disabled={future}
                className={`
                  w-full aspect-square rounded-lg text-sm font-medium
                  flex items-center justify-center relative
                  transition-all duration-200
                  ${future
                    ? 'text-gray-600 cursor-not-allowed'
                    : activity
                      ? 'bg-emerald-600 hover:bg-emerald-500 text-white cursor-pointer'
                      : 'text-gray-300 hover:bg-gray-700 cursor-pointer'
                  }
                  ${selected ? 'ring-2 ring-indigo-400 ring-offset-1 ring-offset-gray-900' : ''}
                  ${today && !selected ? 'ring-1 ring-gray-500' : ''}
                `}
              >
                {day}
                {activity && (
                  <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1.5 h-1.5 bg-white rounded-full" />
                )}
              </button>

              {/* Tooltip */}
              {hoveredDate === dateStr && activityInfo && (
                <div className="absolute z-50 bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-2 bg-gray-800 rounded-lg shadow-lg text-xs whitespace-nowrap border border-gray-700">
                  <div className="font-medium text-emerald-400 mb-1">Actividad registrada</div>
                  <div className="text-gray-300">
                    {activityInfo.trips} {activityInfo.trips === 1 ? 'viaje' : 'viajes'}
                  </div>
                  <div className="text-gray-300">
                    {activityInfo.totalKm.toFixed(1)} km recorridos
                  </div>
                  <div className="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-full">
                    <div className="border-8 border-transparent border-t-gray-800" />
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Legend */}
      <div className="mt-4 pt-3 border-t border-gray-700">
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-1.5">
              <div className="w-3 h-3 rounded bg-emerald-600" />
              <span className="text-gray-400">Con actividad</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div className="w-3 h-3 rounded bg-gray-700" />
              <span className="text-gray-400">Sin actividad</span>
            </div>
          </div>
          <button
            onClick={clearDate}
            className="text-indigo-400 hover:text-indigo-300 transition-colors"
          >
            Limpiar
          </button>
        </div>
      </div>
    </div>
  );
}
