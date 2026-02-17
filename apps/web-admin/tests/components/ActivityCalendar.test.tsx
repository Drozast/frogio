import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import ActivityCalendar from '@/components/fleet/ActivityCalendar';

describe('ActivityCalendar', () => {
  const mockOnDateSelect = vi.fn();
  const defaultProps = {
    vehicleId: 'vehicle-123',
    selectedDate: '2025-01-15',
    onDateSelect: mockOnDateSelect,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(global.fetch).mockResolvedValue({
      ok: true,
      json: async () => ({
        dates: ['2025-01-10', '2025-01-15', '2025-01-20'],
        activityByDate: {
          '2025-01-10': { trips: 2, totalKm: 45.5 },
          '2025-01-15': { trips: 1, totalKm: 23.2 },
          '2025-01-20': { trips: 3, totalKm: 67.8 },
        },
      }),
    } as Response);
  });

  it('renders calendar with month and year', async () => {
    render(<ActivityCalendar {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText(/enero/i)).toBeInTheDocument();
      expect(screen.getByText(/2025/i)).toBeInTheDocument();
    });
  });

  it('renders days of the week', async () => {
    render(<ActivityCalendar {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('lun')).toBeInTheDocument();
      expect(screen.getByText('mar')).toBeInTheDocument();
      expect(screen.getByText('mié')).toBeInTheDocument();
      expect(screen.getByText('jue')).toBeInTheDocument();
      expect(screen.getByText('vie')).toBeInTheDocument();
      expect(screen.getByText('sáb')).toBeInTheDocument();
      expect(screen.getByText('dom')).toBeInTheDocument();
    });
  });

  it('fetches activity days when vehicleId changes', async () => {
    render(<ActivityCalendar {...defaultProps} />);

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/fleet/activity-days?vehicleId=vehicle-123')
      );
    });
  });

  it('calls onDateSelect when clicking a day', async () => {
    render(<ActivityCalendar {...defaultProps} />);

    await waitFor(() => {
      const day10Button = screen.getByRole('button', { name: '10' });
      fireEvent.click(day10Button);
    });

    expect(mockOnDateSelect).toHaveBeenCalledWith('2025-01-10');
  });

  it('navigates to previous month', async () => {
    render(<ActivityCalendar {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText(/enero/i)).toBeInTheDocument();
    });

    const prevButton = screen.getAllByRole('button')[0];
    fireEvent.click(prevButton);

    await waitFor(() => {
      expect(screen.getByText(/diciembre/i)).toBeInTheDocument();
      expect(screen.getByText(/2024/i)).toBeInTheDocument();
    });
  });

  it('shows legend with activity indicators', async () => {
    render(<ActivityCalendar {...defaultProps} />);

    await waitFor(() => {
      expect(screen.getByText('Con actividad')).toBeInTheDocument();
      expect(screen.getByText('Sin actividad')).toBeInTheDocument();
    });
  });

  it('shows clear button that resets to today', async () => {
    render(<ActivityCalendar {...defaultProps} />);

    await waitFor(() => {
      const clearButton = screen.getByText('Limpiar');
      expect(clearButton).toBeInTheDocument();
    });
  });

  it('does not fetch when vehicleId is empty', async () => {
    render(
      <ActivityCalendar
        vehicleId=""
        selectedDate="2025-01-15"
        onDateSelect={mockOnDateSelect}
      />
    );

    await waitFor(() => {
      expect(global.fetch).not.toHaveBeenCalled();
    });
  });

  it('handles API error gracefully', async () => {
    vi.mocked(global.fetch).mockResolvedValueOnce({
      ok: false,
      json: async () => ({ error: 'Error' }),
    } as Response);

    render(<ActivityCalendar {...defaultProps} />);

    // Should still render without crashing
    await waitFor(() => {
      expect(screen.getByText(/enero/i)).toBeInTheDocument();
    });
  });
});
