import { useNui } from '@/store/useNui'
import { emit } from '@/utils/emit'
import { useEffect, useState } from 'react'

interface PointResponse {
  success: boolean
  startedAt?: number
  elapsed?: number
  error?: string
}

function formatElapsed(seconds: number) {
  const safe = Math.max(0, Math.floor(seconds))
  const hours = Math.floor(safe / 3600)
  const minutes = Math.floor((safe % 3600) / 60)
  const secs = safe % 60
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
}

export default function Point() {
  const { pointStart, setPointStart } = useNui()
  const [formattedTime, setFormattedTime] = useState('00:00:00')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const update = () => {
      if (!pointStart) {
        setFormattedTime('00:00:00')
        return
      }
      const now = Math.floor(Date.now() / 1000)
      setFormattedTime(formatElapsed(now - pointStart))
    }

    update()
    const interval = setInterval(update, 1000)
    return () => clearInterval(interval)
  }, [pointStart])

  async function handlePoint() {
    if (loading) return
    setLoading(true)
    try {
      const response = await emit<PointResponse>('point', { status: !pointStart })
      if (response?.success) {
        if (!pointStart) {
          setPointStart(response.startedAt || Math.floor(Date.now() / 1000))
        } else {
          setPointStart(undefined)
        }
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="w-[18.75rem] flex flex-col h-[11.25rem] muted">
      <div
        className="w-full h-[1.875rem] flex items-center pl-4 relative"
        style={{
          background:
            'linear-gradient(90deg, rgba(255, 255, 255, 0.04) 0%, rgba(255, 255, 255, 0.00) 100%)',
        }}
      >
        <div className="absolute left-0 h-full w-1 bg-[#D3132F]"></div>
        <span className="text-sm text-white">Bate-ponto</span>
      </div>
      <div className="flex items-center gap-3 ml-4 mt-4">
        <svg
          width="41"
          height="41"
          viewBox="0 0 41 41"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M20.5 3.84375C17.2057 3.84375 13.9854 4.82062 11.2463 6.65083C8.50718 8.48105 6.37231 11.0824 5.11164 14.1259C3.85097 17.1695 3.52112 20.5185 4.1638 23.7495C4.80649 26.9805 6.39284 29.9483 8.72226 32.2777C11.0517 34.6072 14.0195 36.1935 17.2505 36.8362C20.4815 37.4789 23.8305 37.149 26.8741 35.8884C29.9176 34.6277 32.519 32.4928 34.3492 29.7537C36.1794 27.0146 37.1563 23.7943 37.1563 20.5C37.1516 16.0839 35.3952 11.85 32.2726 8.7274C29.15 5.60476 24.9161 3.84841 20.5 3.84375ZM20.5 34.5938C17.7125 34.5938 14.9876 33.7672 12.6699 32.2185C10.3522 30.6699 8.5458 28.4687 7.47908 25.8934C6.41236 23.3181 6.13325 20.4844 6.67706 17.7504C7.22088 15.0165 8.56318 12.5053 10.5342 10.5342C12.5053 8.56317 15.0165 7.22087 17.7505 6.67706C20.4844 6.13325 23.3182 6.41235 25.8935 7.47907C28.4687 8.5458 30.6699 10.3522 32.2185 12.6699C33.7672 14.9876 34.5938 17.7125 34.5938 20.5C34.5895 24.2366 33.1033 27.8189 30.4611 30.4611C27.8189 33.1033 24.2366 34.5895 20.5 34.5938ZM30.75 20.5C30.75 20.8398 30.615 21.1657 30.3747 21.406C30.1345 21.6463 29.8086 21.7812 29.4688 21.7812H20.5C20.1602 21.7812 19.8343 21.6463 19.594 21.406C19.3537 21.1657 19.2188 20.8398 19.2188 20.5V11.5312C19.2188 11.1914 19.3537 10.8656 19.594 10.6253C19.8343 10.385 20.1602 10.25 20.5 10.25C20.8398 10.25 21.1657 10.385 21.406 10.6253C21.6463 10.8656 21.7813 11.1914 21.7813 11.5312V19.2188H29.4688C29.8086 19.2188 30.1345 19.3537 30.3747 19.594C30.615 19.8343 30.75 20.1602 30.75 20.5Z"
            fill="#D3132F"
          />
        </svg>
        <div>
          <p className="text-white/50 leading-3">Tempo atual do ponto</p>
          <p className="text-white font-bold text-[1.875rem]">{formattedTime}</p>
        </div>
      </div>
      <button
        disabled={loading}
        onClick={handlePoint}
        className="text-[#D3132F] disabled:opacity-50 font-bold bg-[#D3132F] bg-opacity-15 w-[16.75rem] h-[2.75rem] rounded self-center mt-3.5"
      >
        {loading ? 'AGUARDE...' : !pointStart ? 'BATER PONTO' : 'ENCERRAR PONTO'}
      </button>
    </div>
  )
}
