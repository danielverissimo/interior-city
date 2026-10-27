import { Settings } from 'lucide-react'
import Config from './config'
import { emit } from '@/utils/emit'
import { useEffect, useState } from 'react'

interface IUser {
  name: string,
  group: string,
  org: string,
  isDeveloper: boolean,
}

export default function Header() {
  const [user, setUser] = useState<IUser>({
    name: 'Joaoasdadssadsa',
    group: "Sub-tenente",
    org: "Policia",
    isDeveloper: false,
  })

  useEffect(() => {
    emit<IUser>('getUser', {}, { isDeveloper: true, name: 'Joao', group: "Sub-tenente", org: "Policia" },
    ).then((user) => setUser(user))
  }, [])

  return (
    <>
      <div className="w-full flex items-center">
        <div className="flex items-center w-[220px]">
          <div className='w-full'>
            <p
              className="text-sm text-white font-bold"
              style={{ lineHeight: '14px' }}
            >
              {user.org}
            </p>
            <p className="text-sm text-white/50 truncate overflow-hidden text-ellipsis whitespace-nowrap w-[12rem]">
              {user.name} | {user.group}
            </p>
          </div>
        </div>
        <div className="w-[25.375rem] h-[2.125rem] bg-white/5 rounded-[2.375rem] grid place-items-center ml-8">
          <p className="text-white/60 text-sm">
            www.{user.org.toLowerCase().replaceAll(' ', '')}.011.com/
            <span className="text-white/40">index</span>
          </p>
        </div>
          {user.isDeveloper && 
            <div className="w-[2.125rem] h-[2.125rem] grid place-items-center bg-white/5 rounded ml-[8rem]">
              <Config>
                <Settings size={16} className="text-white/50" />
              </Config>
            </div>
          }
      </div>
      <hr className="h-[0.0625rem] w-full border-none bg-white/5 mt-5" />
    </>
  )
}
