import { create } from "zustand"

interface NuiState {
  history: string[];
  historyIndex: number;
  setHistory: (history: string[] | ((prevState: string[]) => string[] | undefined)) => void;
  setHistoryIndex: (index: number | ((prevState: number) => number)) => void;
}

export const useHistory = create<NuiState>((set) => ({
  history: [],
  historyIndex: -1,
  setHistory: (history: string[] | ((prevState: string[]) => string[] | undefined)) => set((prevState) => ({ history: typeof history === 'function' ? history(prevState.history) : history })),
  setHistoryIndex: (historyIndex: number | ((prevState: number) => number)) => set((prevState) => ({ historyIndex: typeof historyIndex === 'function' ? historyIndex(prevState.historyIndex) : historyIndex })),
}))