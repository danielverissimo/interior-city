import { create } from 'zustand'

export interface IProps {
  hud: { velocimeter: number, stats: number}
  updateHud: (hud: { velocimeter: number, stats: number }) => void;
}

const defaultHudState = {
  stats: 1,
  velocimeter: 2,
}

const getInitialState = () => {
  const stored = localStorage.getItem('hud-state')
  if (stored) {
    return JSON.parse(stored)
  }
  return defaultHudState
}

export const useHud = create<IProps>((set) => ({
  hud: getInitialState(),
  updateHud: (hud: { velocimeter: number, stats: number }) => {
    localStorage.setItem('hud-state', JSON.stringify(hud))
    window.dispatchEvent(new CustomEvent('hud:layout', { detail: hud }))
    set({ hud })
  }
}))