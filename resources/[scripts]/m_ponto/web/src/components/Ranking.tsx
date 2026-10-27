import { emit } from '@/utils/emit'
import { useEffect, useState } from 'react'

interface IRanking {
  user_id: number
  name: string
  seconds: number
  formatted: string
}

export default function Ranking() {
  const [ranking, setRanking] = useState<IRanking[]>([])

  useEffect(() => {
    let active = true

    const load = async () => {
      const data = await emit<IRanking[]>('getRanking', {}, [])
      if (active && Array.isArray(data)) setRanking(data)
    }

    load()
    const interval = setInterval(load, 15000)
    return () => {
      active = false
      clearInterval(interval)
    }
  }, [])

  return (
    <div className="mt-3 muted w-[18.75rem] h-[14.375rem]">
      <div
        className="mt-2.5 w-full h-[1.875rem] relative pl-4 flex items-center"
        style={{
          background:
            'linear-gradient(90deg, rgba(255, 255, 255, 0.04) 0%, rgba(255, 255, 255, 0.00) 100%)',
        }}
      >
        <div className="absolute left-0 h-full w-1 bg-[#D3132F]"></div>
        <span className="text-sm text-white">Ranking de horas</span>
      </div>
      <div className="flex flex-col gap-1.5 m-4 overflow-auto overflow-x-hidden max-h-[11rem]">
        {ranking.length === 0 && (
          <div className="text-white/40 text-sm text-center py-6">
            Nenhuma hora registrada ainda.
          </div>
        )}
        {ranking.map((rank, index) => (
          <div
            key={`${rank.user_id}-${index}`}
            className="flex-none w-[16.75rem] min-h-[2.6rem] foreground rounded-sm flex items-center px-3 gap-2"
          >
            <p className="font-bold text-white w-[2rem]">{index + 1}°</p>
            <div className="min-w-0 flex-1">
              <p className="font-bold text-white truncate">{rank.name}</p>
              <p className="text-[11px] text-white/45">ID {rank.user_id}</p>
            </div>
            <p className="text-xs font-bold text-[#D3132F] whitespace-nowrap">
              {rank.formatted}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}
