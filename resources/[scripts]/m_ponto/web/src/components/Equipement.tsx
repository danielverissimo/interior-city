import { useEffect, useState } from 'react'
import Item, { ItemProps } from './item'
import { emit } from '@/utils/emit'

interface WeaponResponse {
  success: boolean
  error?: string
}

export default function Equipement() {
  const [equipements, setEquipements] = useState<ItemProps[]>([])
  const [loadingWeapon, setLoadingWeapon] = useState<string | null>(null)

  useEffect(() => {
    emit<ItemProps[]>('getEquipments', {}, []).then((data) =>
      setEquipements(Array.isArray(data) ? data : []),
    )
  }, [])

  async function takeWeapon(equipement: ItemProps) {
    const weapon = equipement.weapon || equipement.name
    if (loadingWeapon) return
    setLoadingWeapon(weapon)
    try {
      await emit<WeaponResponse>('takeWeapon', { weapon })
    } finally {
      setLoadingWeapon(null)
    }
  }

  return (
    <div className="w-[35.5rem] h-fit rounded-[.5rem]">
      <div
        className="w-full h-[1.875rem] flex items-center pl-4 relative"
        style={{
          background:
            'linear-gradient(90deg, rgba(255, 255, 255, 0.04) 0%, rgba(255, 255, 255, 0.00) 100%)',
        }}
      >
        <div className="absolute left-0 h-full w-1 bg-[#D3132F]"></div>
        <span className="text-sm text-white">Equipamentos de trabalho</span>
        <span className="text-[11px] text-white/35 ml-auto mr-5">
          clique em uma arma para retirar
        </span>
      </div>
      <div className="w-[31.25rem] mask-list h-[13.75rem] foreground p-3 items-start content-start grid grid-cols-3 gap-1 mx-3 mt-4 overflow-y-auto flex-wrap overflow-x-hidden">
        {equipements.map((equipement) => (
          <Item
            key={equipement.name}
            {...equipement}
            loading={loadingWeapon === (equipement.weapon || equipement.name)}
            onClick={() => takeWeapon(equipement)}
          />
        ))}
      </div>
    </div>
  )
}
