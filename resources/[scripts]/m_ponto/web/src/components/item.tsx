export interface ItemProps {
  name: string
  image: string
  weapon?: string
  loading?: boolean
  onClick?: () => void
}

export default function Item({ name, image, loading, onClick }: ItemProps) {
  return (
    <button
      type="button"
      disabled={loading}
      onClick={onClick}
      title={`Retirar ${name}`}
      className="w-[10.375rem] h-[4rem] flex flex-col-reverse items-start my-1 px-4 gap-3 cursor-pointer hover:!bg-white/5 disabled:opacity-50 disabled:cursor-wait"
      style={{
        zoom: '.9',
        background:
          'radial-gradient(95.47% 60.03% at 49.84% 76.67%, rgba(217, 217, 217, 0.03) 0%, rgba(115, 115, 115, 0.00) 100%), linear-gradient(91deg, rgba(255, 255, 255, 0.03) 0%, rgba(255, 255, 255, 0.02) 100%)',
      }}
    >
      <img src={image} className="h-[1.85rem] self-center" alt="" />
      <p className="text-white text-sm font-bold truncate">
        {loading ? 'Retirando...' : name}
      </p>
    </button>
  )
}
