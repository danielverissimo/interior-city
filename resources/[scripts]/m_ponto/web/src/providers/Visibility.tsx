import React, {
  Context,
  createContext,
  useContext,
  useEffect,
  useState,
} from 'react'
import { isEnvBrowser } from '../utils/misc'
import { observe } from '../hooks/observe'
import { emit } from '../utils/emit'
import { useNui } from '@/store/useNui'

interface VisibilityProviderValue {}

const VisibilityContext = createContext<VisibilityProviderValue | null>(null)

export const VisibilityProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [visible, setVisible] = useState(isEnvBrowser())
  const { setPointStart } = useNui()

  observe('open', (data) => {
    setPointStart(data.point)
    setVisible(true)
  })

  observe('close', () => setVisible(false))

  useEffect(() => {
    if (!visible) return

    const keyHandler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (!isEnvBrowser()) {
          emit('hideFrame')
          setVisible(false)
        } else setVisible(!visible)
      }
    }

    window.addEventListener('keydown', keyHandler)
    return () => window.removeEventListener('keydown', keyHandler)
  }, [visible])

  return (
    <VisibilityContext.Provider value={{}}>
      {visible && children}
    </VisibilityContext.Provider>
  )
}

export const useVisibility = () =>
  useContext<VisibilityProviderValue>(
    VisibilityContext as Context<VisibilityProviderValue>,
  )
