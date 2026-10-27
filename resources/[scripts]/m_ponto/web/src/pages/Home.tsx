import Equipement from '@/components/Equipement'
import Header from '@/components/header'
import Point from '@/components/Point'
import Ranking from '@/components/Ranking'
import Uniform from '../assets/uniform.png'
import Radio from '../assets/radio.png'
import EditUniform from '@/components/edit-uniform'
import { useNui } from '@/store/useNui'
import { emit } from '@/utils/emit'
import { useState } from 'react'

export default function Home() {
  const { showEditModal } = useNui()
  const [equipping, setEquipping] = useState(false)

  async function handleEquip() {
    if (equipping) return
    setEquipping(true)
    try {
      await emit('equip')
    } finally {
      setEquipping(false)
    }
  }
  return (
    <div>
      <Header />
      <div className="flex gap-3 mt-[.81rem]">
        <div className="">
          <Point />
          <Ranking />
        </div>
        <div className="flex flex-col w-[33.25rem] h-[26.375rem] rounded-[0.5rem] muted">
          <Equipement />
          <div
            className="flex items-center gap-3 w-[34.25rem] h-[6.125rem] foreground p-3 mt-3 ml-4 rounded"
            style={{ zoom: '.88' }}
          >
            <div
              className="w-[15.59375rem] h-[4.625rem] flex items-center justify-center gap-3 rounded cursor-pointer hover:!bg-white/5"
              style={{
                background:
                  'radial-gradient(95.47% 60.03% at 49.84% 76.67%, rgba(217, 217, 217, 0.03) 0%, rgba(115, 115, 115, 0.00) 100%), linear-gradient(91deg, rgba(255, 255, 255, 0.03) 0%, rgba(255, 255, 255, 0.02) 100%)',
              }}
            >
              <img className="h-[2.0625rem]" src={Radio} alt="" />
              <p className="text-sm text-white font-bold">Rádio</p>
            </div>
            <div
              className="w-[15.59375rem] h-[4.625rem] flex items-center justify-center gap-3 rounded cursor-pointer hover:!bg-white/5"
              style={{
                background:
                  'radial-gradient(95.47% 60.03% at 49.84% 76.67%, rgba(217, 217, 217, 0.03) 0%, rgba(115, 115, 115, 0.00) 100%), linear-gradient(91deg, rgba(255, 255, 255, 0.03) 0%, rgba(255, 255, 255, 0.02) 100%)',
              }}
            >
              <img className="h-[3.0625rem]" src={Uniform} alt="" />
              <p className="text-sm text-white font-bold">Uniforme</p>
            </div>
          </div>
          <button
            onClick={handleEquip}
            disabled={equipping}
            className="h-[2.25rem] disabled:opacity-50 ml-4 w-[31.25rem] bg-[#D3132F] rounded text-sm text-white font-bold mt-3"
          >
            {equipping ? 'EQUIPANDO...' : 'EQUIPAR TUDO'}
          </button>
        </div>
      </div>
      {showEditModal && <EditUniform />}
    </div>
  )
}
