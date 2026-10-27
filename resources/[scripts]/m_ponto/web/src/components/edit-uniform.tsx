import { useNui } from '@/store/useNui'
import { IUniform } from './config'
import { useState } from 'react'
import { emit } from '@/utils/emit'

export default function EditUniform() {
  const { setShowEditModal, currentEditUniform } = useNui()
  const [text, setText] = useState<string>('')

  function handleEdit() {
    if (text !== '') {
      emit('editUniform', { text, uniform: currentEditUniform })
    }
    setShowEditModal(false)
  }

  return (
    <div className="w-[30rem] h-[16.25rem] z-[100000] bg-[#101215] border border-white/5 transform -translate-x-1/2 -translate-y-1/2 left-1/2 top-1/2 absolute rounded">
      <div className="relative">
        <div className="w-[14rem] h-[2.559rem] bg-[#C3112A] rounded grid place-items-center absolute left-[8rem] -top-4">
          <p className="text-[1.125rem] font-bold text-white">CONFIGURAÇÕES</p>
        </div>
      </div>
      <div
        className="w-full h-[1.875rem] flex items-center pl-4 relative mt-[3rem]"
        style={{
          background:
            'linear-gradient(90deg, rgba(255, 255, 255, 0.04) 0%, rgba(255, 255, 255, 0.00) 100%)',
        }}
      >
        <div className="absolute left-0 h-full w-1 bg-[#D3132F]"></div>
        <span className="text-sm text-white">
          Configurações da vestimenta
        </span>
      </div>
      <textarea
        onChange={(e) => setText(e.target.value)}
        name=""
        defaultValue={JSON.stringify(currentEditUniform?.preset, null, 2)}
        placeholder="Digite o novo preset"
        className="w-[28rem] h-[5.125rem] foreground mt-4 ml-3 rounded p-3 text-sm placeholder:text-white/50 text-white resize-none outline-none"
        id=""
      ></textarea>
      <button
        onClick={handleEdit}
        className="w-[28rem] h-[3.125rem] bg-[#D3132F] text-white font-bold rounded mt-2.5 ml-3"
      >
        SALVAR CONFIGURAÇÕES
      </button>
    </div>
  )
}
