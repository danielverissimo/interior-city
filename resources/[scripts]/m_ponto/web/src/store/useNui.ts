import { IUniform } from '@/components/config'
import { create } from 'zustand'

interface NuiState {
  uniforms: IUniform[]
  setUniforms: (uniforms: IUniform[]) => void
  showEditModal: boolean
  setShowEditModal: (showEditModal: boolean) => void
  currentEditUniform: IUniform | null
  setCurrentEditUniform: (uniform: IUniform) => void
  pointStart: number | undefined
  setPointStart: (pointStart: number | undefined) => void
}

export const useNui = create<NuiState>((set) => ({
  uniforms: [],
  setUniforms: (uniforms) => set({ uniforms }),
  showEditModal: false,
  setShowEditModal: (showEditModal) => set({ showEditModal }),
  currentEditUniform: null,
  setCurrentEditUniform: (currentEditUniform) => set({ currentEditUniform }),
  pointStart: undefined,
  setPointStart: (pointStart) => set({ pointStart }),
}))
