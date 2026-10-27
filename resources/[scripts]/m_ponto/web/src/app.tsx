import { Navigate, Route, Routes } from 'react-router-dom'
import Home from './pages/Home'
import { isEnvBrowser } from './utils/misc'
import { VisibilityProvider } from './providers/Visibility'
import clsx from 'clsx'
import toast, { Toaster } from 'react-hot-toast'
import { observe } from './hooks/observe'

export default function App() {
  observe('showToast', (data: string) => {
    toast(data, {
      icon: '✉️',
    })
  })

  return (
    <VisibilityProvider>
      <div
        className={clsx(
          'w-screen h-screen grid place-items-center',
          isEnvBrowser() && 'bg-zinc-700',
        )}
      >
        <div
          id="interface"
          className="w-[932px] h-[586px] bg-[#101215] border-[18px] rounded-[24px] border-[#050505] py-[1.31rem] px-[1.63rem]"
        >
          <Routes>
            <Route path="/home" element={<Home />} />
            <Route path="*" element={<Navigate to="/home" />} />
          </Routes>
        </div>
      </div>
      <Toaster position="top-center" reverseOrder={false} />
    </VisibilityProvider>
  )
}
