import { useEffect, useState } from "react";
import { MdClose, MdDirectionsCar, MdSearch, MdSpeed, MdStar } from "react-icons/md";
import { Vehicle } from "./components/vehicle";
import { VehicleImage } from "./components/vehicle-image";
import { LendVehicleButton } from "./components/modals/lend-vehicle-modal";
import { SellVehicleButton } from "./components/modals/sell-vehicle-modal";
import { useGarage } from "./hooks/useGarage";
import { useVisibility } from "./providers/visibility";
import fetch from "./utils/fetch";
import { isEnvBrowser } from "./utils/misc";

const filters = [
  { value: "all", label: "Todos" },
  { value: "normal", label: "Concessionária" },
  { value: "special", label: "VIP" },
  { value: "favorite", label: "Favoritos" },
] as const;

function readFavorites(): string[] {
  try {
    const value = JSON.parse(localStorage.getItem("favorited_vehicles") || "[]");
    return Array.isArray(value) ? value.filter((item) => typeof item === "string") : [];
  } catch {
    return [];
  }
}

export function App() {
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<(typeof filters)[number]["value"]>("all");
  const [selectedKey, setSelectedKey] = useState<string>();
  const [favorites, setFavorites] = useState(readFavorites);
  const { vehicles } = useGarage();
  const close = useVisibility();
  const query = search.trim().toLocaleLowerCase("pt-BR");

  useEffect(() => {
    localStorage.setItem("favorited_vehicles", JSON.stringify(favorites));
  }, [favorites]);

  const visibleVehicles = vehicles.filter((vehicle) => {
    const matchesFilter = filter === "all" || vehicle.type === filter
      || (filter === "favorite" && favorites.includes(vehicle.key));
    return matchesFilter && [vehicle.name, vehicle.plate, vehicle.category]
      .some((value) => value?.toLocaleLowerCase("pt-BR").includes(query));
  });
  const selected = visibleVehicles.find(({ key }) => key === selectedKey) ?? visibleVehicles[0];
  const stats = selected ? [
    { label: "Frenagem", value: selected.braking },
    { label: "Aceleração", value: selected.agility },
    { label: "Aderência", value: selected.grip },
  ] : [];

  function toggleFavorite(key: string) {
    setFavorites((current) => current.includes(key)
      ? current.filter((favorite) => favorite !== key)
      : [key, ...current]);
  }

  return (
    <main className="garage-panel" aria-labelledby="garage-title">
      <header className="garage-header">
        <div className="garage-brand">
          <span className="garage-mark"><MdDirectionsCar aria-hidden="true" /></span>
          <div>
            <span className="garage-city">Interior City</span>
            <h1 id="garage-title">Garagem</h1>
          </div>
        </div>
        <button type="button" className="garage-close" onClick={close} aria-label="Fechar garagem">
          <kbd>ESC</kbd><MdClose aria-hidden="true" />
        </button>
      </header>
      <div className="garage-content">
        <section className="garage-list" aria-labelledby="garage-list-title">
          <div className="garage-list-title">
            <h2 id="garage-list-title">Veículos</h2>
            <span>{visibleVehicles.length} de {vehicles.length}</span>
          </div>
          <label className="garage-search">
            <MdSearch aria-hidden="true" />
            <input value={search} onChange={(event) => setSearch(event.target.value)}
              placeholder="Buscar por nome, placa ou categoria" aria-label="Buscar veículos" />
          </label>
          <div className="garage-filters" aria-label="Filtrar veículos">
            {filters.map(({ value, label }) => (
              <button type="button" key={value} aria-pressed={filter === value} onClick={() => setFilter(value)}>
                {value === "favorite" && <MdStar aria-hidden="true" />}{label}
              </button>
            ))}
          </div>
          {visibleVehicles.length ? (
            <div className="garage-grid">
              {visibleVehicles.map((vehicle) => (
                <Vehicle key={vehicle.key} vehicle={vehicle} selected={selected?.key === vehicle.key}
                  favorited={favorites.includes(vehicle.key)} onFavorite={() => toggleFavorite(vehicle.key)}
                  onSelect={() => setSelectedKey(vehicle.key)} />
              ))}
            </div>
          ) : (
            <div className="garage-empty">
              <MdDirectionsCar aria-hidden="true" />
              <p>{vehicles.length ? "Nenhum veículo encontrado." : "Nenhum veículo disponível nesta garagem."}</p>
              {vehicles.length > 0 && <button type="button" onClick={() => { setSearch(""); setFilter("all"); }}>Limpar filtros</button>}
            </div>
          )}
        </section>
        <aside className="garage-details" aria-label="Detalhes do veículo">
          {selected && (
            <>
              <div className="garage-detail-heading">
                <div className="garage-detail-meta"><span>{selected.category || "Veículo"}</span><span className="garage-plate">{selected.plate}</span></div>
                <h2>{selected.name}</h2>
              </div>
              <VehicleImage model={selected.key} src={selected.image_url} className="garage-hero" />
              <div className="garage-summary">
                <div><span>Status</span><strong data-warning={Boolean(selected.arrested)}>{selected.arrested ? "Preso" : "Liberado"}</strong></div>
                <div><span>IPVA</span><strong data-warning={Boolean(selected.ipva)}>{selected.ipva ? "Não pago" : "Pago"}</strong></div>
                <div><span>Velocidade máxima</span><strong><MdSpeed aria-hidden="true" />{selected.max_speed} km/h</strong></div>
              </div>
              <div className="garage-stats">
                {stats.map(({ label, value }) => {
                  const percent = Math.min(100, Math.max(0, Number(value) || 0));
                  return <div key={label}>
                    <div><span>{label}</span><strong>{percent}%</strong></div>
                    <div className="garage-stat-track"><span style={{ width: percent + "%" }} /></div>
                  </div>;
                })}
              </div>
            </>
          )}
          <div className="garage-actions">
            {selected && (
              <>
                <button type="button" className="garage-primary" onClick={() => fetch("TAKE_OUT", selected)}>
                  Retirar veículo
                </button>
                <button type="button" onClick={() => fetch("PULL", selected)}>Guardar veículo</button>
                <LendVehicleButton vehicle={selected} />
                <SellVehicleButton vehicle={selected} />
              </>
            )}
            <button type="button" className="garage-nearby" onClick={() => !isEnvBrowser() && fetch("PULL_NEAREST")}>
              Guardar veículo próximo
            </button>
          </div>
        </aside>
      </div>
    </main>
  );
}
