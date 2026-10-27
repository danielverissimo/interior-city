import { Pen } from 'lucide-react'
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from './ui/dialog'
import { useEffect, useState } from 'react'
import { emit } from '@/utils/emit'
import { useNui } from '@/store/useNui'

export interface IUniform {
  name: string,
  preset?: any
}

export default function Config({ children }: { children: React.ReactNode }) {
  const { setUniforms, uniforms, setShowEditModal, setCurrentEditUniform } =
    useNui()
  const [radio, setRadio] = useState<number>(0)

  useEffect(() => {
    emit(
      'getUniforms',
      {},
      {
        radio: 444,
        uniforms: [
          {
            name: 'Uniforme 1',
          },
          {
            name: 'Uniforme 2',
          },
          {
            name: 'Uniforme 3',
          },
          {
            name: 'Uniforme 4',
          },
          {
            name: 'Uniforme 5',
          },
          {
            name: 'Uniforme 6',
          },
          {
            name: 'Uniforme 7',
          },
          {
            name: 'Uniforme 8',
          },
          {
            name: 'Uniforme 9',
          },
          {
            name: 'Uniforme 10',
          },
        ],
      },
    ).then((data) => {
      setUniforms(data.uniforms)
      setRadio(data.radio)
    })
  }, [])

  function handleEdit(data: IUniform) {
    setShowEditModal(true)
    setCurrentEditUniform(data)
  }

  return (
    <Dialog>
      <DialogTrigger>{children}</DialogTrigger>
      <DialogContent className="w-[32.5rem] h-[45.125rem] bg-[#101215] border-none p-0 text-white">
        <DialogHeader className="p-0">
          <div className="relative">
            <DialogTitle className="w-[14rem] h-[2.559rem] rounded bg-[#C3112A] grid place-items-center absolute -top-6 left-[8.6rem] text-white font-bold">
              CONFIGURAÇÕES
            </DialogTitle>
          </div>
        </DialogHeader>
        <div className="mt-[.1rem]">
          <div
            className="w-[32.5rem] h-[1.91925rem] text-sm text-white flex items-center pl-4 relative"
            style={{
              background:
                'linear-gradient(90deg, rgba(255, 255, 255, 0.04) 0%, rgba(255, 255, 255, 0.00) 100%)',
            }}
          >
            <div className="h-[1.875rem] w-[.25rem] bg-[#C3112A] absolute left-0"></div>
            Configurações da vestimenta
          </div>
          <div className="flex flex-col ml-4 mt-[13.71px] h-[25rem] w-[29.2rem] gap-2 mask-list overflow-y-auto overflow-x-hidden">
            {uniforms.map((uniform) => (
              <div
                key={uniform.name}
                className="w-[468px] flex-none h-[40px] foreground flex items-center px-3 justify-between"
              >
                <span className="text-sm text-white font-bold capitalize">
                  {uniform.name}
                </span>
                <DialogClose onClick={() => handleEdit(uniform)}>
                  <Pen size={16} className="text-white/50 cursor-pointer" />
                </DialogClose>
              </div>
            ))}
          </div>
          <div
            className="w-[32.5rem] h-[1.91925rem] text-sm text-white flex items-center pl-4 relative"
            style={{
              background:
                'linear-gradient(90deg, rgba(255, 255, 255, 0.04) 0%, rgba(255, 255, 255, 0.00) 100%)',
            }}
          >
            <div className="h-[1.875rem] w-[.25rem] bg-[#C3112A] absolute left-0"></div>
            Frequência do rádio
          </div>
          <div className="w-[29.2rem] h-[5.125rem] foreground ml-4 mt-3.5 p-3">
            <span className="text-sm text-white/50">{radio}</span>
          </div>
          <DialogFooter className="w-[29.2rem] h-[3.125rem] justify-center self-center rounded-sm bg-[#C3112A] ml-4 mt-4 cursor-pointer">
            <DialogClose>
              <button className="font-bold">SALVAR CONFIGURAÇÕES</button>
            </DialogClose>
          </DialogFooter>
        </div>
      </DialogContent>
    </Dialog>
  )
}
