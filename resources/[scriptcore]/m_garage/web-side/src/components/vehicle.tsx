import { MdCheck, MdOutlineStarBorder, MdStar } from "react-icons/md";
import type { VehicleProps } from "../hooks/useGarage";
import { VehicleImage } from "./vehicle-image";

interface VehicleCardProps {
  vehicle: VehicleProps;
  selected: boolean;
  favorited: boolean;
  onFavorite: () => void;
  onSelect: () => void;
}

export function Vehicle({ vehicle, selected, favorited, onFavorite, onSelect }: VehicleCardProps) {
  return (
    <article className="garage-card" data-selected={selected}>
      <button type="button" className="garage-card-select" onClick={onSelect} aria-pressed={selected}
        aria-label={vehicle.name + ", placa " + vehicle.plate}>
        <span className="garage-card-top">
          <span className="garage-plate">{vehicle.plate}</span>
          {selected && <MdCheck className="garage-card-check" aria-hidden="true" />}
        </span>
        <VehicleImage model={vehicle.key} src={vehicle.image_url} className="garage-thumb" />
        <span className="garage-card-name" title={vehicle.name}>{vehicle.name}</span>
        <span className="garage-card-category">{vehicle.category || "Veículo"}</span>
      </button>
      <button type="button" className="garage-card-favorite" aria-pressed={favorited}
        aria-label={(favorited ? "Remover dos favoritos: " : "Favoritar: ") + vehicle.name} onClick={onFavorite}>
        {favorited ? <MdStar aria-hidden="true" /> : <MdOutlineStarBorder aria-hidden="true" />}
      </button>
    </article>
  );
}
