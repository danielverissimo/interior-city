import clsx from "clsx";
import { MdOutlineStar } from "react-icons/md";

import Engine from "/icons/engine.svg";

interface VehicleProps {
  name: string;
  image_url: string;
  category: string;
  selected: boolean;
  favorited: boolean;
  onFavorite: () => void;
  onSelect: () => void;
  engine: number;
  plate: string;
}

export function Vehicle({
  engine,
  image_url,
  name,
  category,
  favorited,
  selected,
  onFavorite,
  onSelect,
  plate,
}: VehicleProps) {
  return (
    <div
      className={clsx(
        selected && "!bg-gradient-to-b from-[#D3132F00] to-[#2981FF66]",
        "w-[18.125rem] h-[9.0625rem] flex-none flex flex-col items-center justify-between p-[.62rem] rounded-[0.5625rem] relative"
      )}
      style={{
        boxShadow: "inset 0 0 0 .0625rem rgb(255, 255, 255, .13)",
        background: !selected
          ? "linear-gradient(109deg, rgba(41, 129, 255, 0.00) 30%, rgba(41, 129, 255, 0.02) 100%), rgba(255, 255, 255, 0.07)"
          : "",
      }}
    >
      <div className="flex items-center gap-[.94rem]">
        <div className="flex flex-col gap-2">
          <div className="flex items-center gap-3">
            <div className="w-[5.875rem] h-[2.125rem] rounded-[0.5625rem] border-[.0625rem] border-white/20 flex items-center justify-center">
              <p className="text-white/80 text-[0.6875rem] font-bold">{plate}</p>
            </div>
            <MdOutlineStar
              onClick={onFavorite}
              className={`${favorited ? "text-primary" : "text-white/30"} size-5 group-hover:text-white cursor-pointer`}
            />
          </div>
          <div>
            <h3 className="text-white text-[0.9375rem] font-bold truncate w-[6.3125rem]">{name}</h3>
            <p className="text-white/80 text-[0.6875rem] font-medium">{category}</p>
          </div>
        </div>
        <img
          src={image_url || ""}
          draggable={false}
          onError={(e) => (e.currentTarget.src = "/images/default_vehicle.webp")}
          className="w-[8.875rem] h-[4.5625rem]"
        />
      </div>
      <div className="flex items-center gap-[.44rem] w-full h-[2.0625rem]">
        <div className="w-[3.75rem] h-full rounded-lg border-[.05rem] border-white/15 bg-white/[.13] flex items-center justify-center gap-[.31rem]">
          <img src={Engine} className="w-[0.8125rem]" />
          <p className="text-white text-[0.6875rem] font-extrabold">{engine}%</p>
        </div>
        <button
          onClick={onSelect}
          className={clsx(
            "flex-1 h-full rounded-lg border-[.05rem] border-white/15 bg-primary text-[#1E1E1E] text-[0.6875rem] font-extrabold uppercase"
          )}
          style={{ boxShadow: "0px 0px .25rem 0px rgba(0, 0, 0, 0.10), 0px 0px .875rem 0px rgba(41, 129, 255, 0.45)" }}
        >
          {selected ? "SELECIONADO" : "SELECIONAR"}
        </button>
      </div>
    </div>
  );
}
