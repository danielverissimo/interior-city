import Speed from "/icons/speed.svg";
import Search from "/icons/search.svg";

import { MdOutlineStar } from "react-icons/md";

import { useEffect, useMemo, useState } from "react";

import { useGarage } from "./hooks/useGarage";
import fetch from "./utils/fetch";

import { Vehicle } from "./components/vehicle";
import { LendVehicleButton } from "./components/modals/lend-vehicle-modal";
import { SellVehicleButton } from "./components/modals/sell-vehicle-modal";


export function App() {
  const [search, setSearch] = useState<string>("");
  const [selection, setSelection] = useState<"special" | "normal" | "favorite" | null>(null);
  const [vehicleSelected, setVehicleSelected] = useState<number>(0);
  const [favoriteVehicles, setFavoriteVehicles] = useState<string[]>(
    JSON.parse(localStorage.getItem("favorited_vehicles") || "[]")
  );

  const { vehicles } = useGarage();

  const vehicleFiltered = useMemo(() => {
    return vehicles
      .filter(({ type }) => selection === null || selection === "favorite" || type === selection)
      .filter(({ key }) => selection !== "favorite" || favoriteVehicles.includes(key))
      .filter(({ name }) => name.toLowerCase().includes(search.toLowerCase()));
  }, [vehicles, search, selection, favoriteVehicles]);

  const handleFavoriteVehicle = (plate: string) => {
    if (favoriteVehicles.includes(plate)) {
      setFavoriteVehicles((prevState) => prevState.filter((currentPlate) => currentPlate !== plate));
    } else {
      setFavoriteVehicles((prevState) => [plate, ...prevState]);
    }

    localStorage.setItem("favorited_vehicles", JSON.stringify(favoriteVehicles));
  };

  useEffect(() => {
    setVehicleSelected(0);
  }, [selection]);

  return (
    <div
      className="w-[96.875rem] rounded-[0.8125rem] pt-[1.88rem] pb-[1.87rem] px-[1.87rem] flex items-start justify-center gap-16 relative"
      style={{
        background:
          "linear-gradient(180deg, rgba(255, 255, 255, 0.00) 0%, rgba(255, 255, 255, 0.02) 100%), radial-gradient(1133.06% 111.04% at 100.14% 50%, rgba(0, 0, 0, 0.45) 0%, rgba(0, 0, 0, 0.00) 100%), rgba(30, 30, 30, 0.94)",
      }}
    >
      <div className="w-[31.25rem] flex flex-col items-center">
        {vehicleFiltered.length > 0 && (
          <>
            <div className="w-full mb-7 flex flex-col gap-2.5">
              <div className="flex items-center gap-2">
                <p
                  className="text-white text-[2.5rem] font-extrabold leading-none uppercase"
                  style={{ textShadow: "0px 0px 14px rgba(255, 255, 255, 0.25)" }}
                >
                  {vehicleFiltered[vehicleSelected]?.name}
                </p>
                {favoriteVehicles.includes(vehicleFiltered[vehicleSelected]?.key) && (
                  <MdOutlineStar className="size-[1.3125rem] text-primary" />
                )}
              </div>
              <div className="flex items-center gap-[.94rem]">
                <svg
                  className="size-[3.625rem]"
                  width="58"
                  height="58"
                  viewBox="0 0 58 58"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M4.33013 34.5C2.36517 31.0966 2.36517 26.9034 4.33013 23.5L11.9019 10.3853C13.8669 6.98186 17.4983 4.88527 21.4282 4.88527L36.5718 4.88527C40.5017 4.88527 44.1331 6.98186 46.0981 10.3853L53.6699 23.5C55.6348 26.9034 55.6348 31.0966 53.6699 34.5L46.0981 47.6147C44.1331 51.0181 40.5017 53.1147 36.5718 53.1147L21.4282 53.1147C17.4983 53.1147 13.8669 51.0181 11.9019 47.6147L4.33013 34.5Z"
                    fill="url(#paint0_radial_182_5208)"
                    fill-opacity="0.45"
                    stroke="#2981FF"
                    stroke-width="2"
                  />
                  <path
                    d="M8.88675 34C7.10042 30.906 7.10042 27.094 8.88675 24L14.6132 14.0814C16.3996 10.9874 19.7008 9.08142 23.2735 9.08142L34.7265 9.08142C38.2992 9.08142 41.6004 10.9874 43.3868 14.0814L49.1132 24C50.8996 27.094 50.8996 30.906 49.1132 34L43.3868 43.9186C41.6004 47.0126 38.2992 48.9186 34.7265 48.9186L23.2735 48.9186C19.7008 48.9186 16.3996 47.0126 14.6132 43.9186L8.88675 34Z"
                    fill="#2981FF"
                  />
                  <path
                    d="M39.5 26.15L37.4 21.8C36.8 20.75 35.75 20 34.55 20H23.45C22.25 20 21.2 20.75 20.6 21.8L18.5 26.15C17.6 26.3 17 27.05 17 27.8V33.05C17 33.95 17.6 34.7 18.5 34.85V37.85C18.5 38.75 19.25 39.5 20.15 39.5H21.5C22.25 39.5 23 38.75 23 37.85V35H35V37.85C35 38.75 35.75 39.5 36.65 39.5H38C38.9 39.5 39.65 38.75 39.65 37.85V34.85C40.55 34.7 41.15 33.95 41.15 33.05V27.8C41 27.05 40.4 26.3 39.5 26.15ZM23 29.6C23 30.05 22.55 30.5 22.1 30.5H19.4C18.95 30.5 18.5 30.05 18.5 29.6V28.4C18.5 27.95 18.95 27.5 19.4 27.5H22.1C22.55 27.5 23 27.95 23 28.4V29.6ZM32 33.5H26V32H32V33.5ZM20.15 26L21.95 22.4C22.25 21.8 22.85 21.5 23.45 21.5H34.55C35.15 21.5 35.75 21.8 36.05 22.4L37.85 26H20.15ZM39.5 29.6C39.5 30.05 39.05 30.5 38.6 30.5H35.9C35.45 30.5 35 30.05 35 29.6V28.4C35 27.95 35.45 27.5 35.9 27.5H38.6C39.05 27.5 39.5 27.95 39.5 28.4V29.6Z"
                    fill="#1E1E1E"
                  />
                  <defs>
                    <radialGradient
                      id="paint0_radial_182_5208"
                      cx="0"
                      cy="0"
                      r="1"
                      gradientUnits="userSpaceOnUse"
                      gradientTransform="translate(29 -0.0828493) rotate(90) scale(64.4007 657.175)"
                    >
                      <stop />
                      <stop offset="1" stop-opacity="0" />
                    </radialGradient>
                  </defs>
                </svg>
                <p className="text-primary text-xl font-bold uppercase">
                  PLACA: {vehicleFiltered[vehicleSelected]?.plate}
                </p>
              </div>
            </div>
            <img
              src={vehicleFiltered[vehicleSelected]?.image_url || ""}
              draggable={false}
              onError={(e) => (e.currentTarget.src = "./images/default_vehicle.webp")}
              className="h-[16.125rem]"
            />
            <div className="mt-[1.87rem]">
              <div className="flex items-center gap-10 w-full overflow-x-hidden">
                <div>
                  <small className="text-white/70 text-[0.6875rem]">STATUS</small>
                  <p className="text-white text-[1.3125rem] font-bold leading-none">
                    {vehicleFiltered[vehicleSelected]?.arrested ? "PRESO" : "LIBERADO"}
                  </p>
                </div>
                <div>
                  <small className="text-white/70 text-[0.6875rem]">IPVA</small>
                  <p className="text-white text-[1.3125rem] font-bold leading-none">
                    {vehicleFiltered[vehicleSelected]?.ipva ? "NÃO PAGO" : "PAGO"}
                  </p>
                </div>
                <div>
                  <small className="text-white/70 text-[0.6875rem]">TIPO</small>
                  <p className="text-white text-[1.3125rem] font-bold leading-none uppercase truncate w-[6rem]">
                    {vehicleFiltered[vehicleSelected]?.category}
                  </p>
                </div>
              </div>
              <div className="flex flex-col gap-[.94rem] mt-[1.56rem] w-[27.5rem]">
                <div className="w-full flex flex-col gap-[.62rem]">
                  <div className="flex items-center justify-between">
                    <p className="text-white text-xs font-bold">FRENAGEM</p>
                    <p className="text-white/50 text-xs font-normal">{vehicleFiltered[vehicleSelected]?.braking}%</p>
                  </div>
                  <div className="w-full h-[0.5625rem] rounded-[0.1875rem] bg-white/10 border-[.0625rem] border-white/5 overflow-hidden">
                    <div
                      className="h-full bg-primary"
                      style={{ width: `${Math.min(vehicleFiltered[vehicleSelected]?.braking, 100)}%` }}
                    ></div>
                  </div>
                </div>
                <div className="w-full flex flex-col gap-[.62rem]">
                  <div className="flex items-center justify-between">
                    <p className="text-white text-xs font-bold">ACELERAÇÃO</p>
                    <p className="text-white/50 text-xs font-normal">{vehicleFiltered[vehicleSelected]?.agility}%</p>
                  </div>
                  <div className="w-full h-[0.5625rem] rounded-[0.1875rem] bg-white/10 border-[.0625rem] border-white/5 overflow-hidden">
                    <div
                      className="h-full bg-primary"
                      style={{ width: `${Math.min(vehicleFiltered[vehicleSelected]?.agility, 100)}%` }}
                    ></div>
                  </div>
                </div>
                <div className="w-full flex flex-col gap-[.62rem]">
                  <div className="flex items-center justify-between">
                    <p className="text-white text-xs font-bold">ADERÊNCIA</p>
                    <p className="text-white/50 text-xs font-normal">{vehicleFiltered[vehicleSelected]?.grip}%</p>
                  </div>
                  <div className="w-full h-[0.5625rem] rounded-[0.1875rem] bg-white/10 border-[.0625rem] border-white/5 overflow-hidden">
                    <div
                      className="h-full bg-primary"
                      style={{ width: `${Math.min(vehicleFiltered[vehicleSelected]?.grip, 100)}%` }}
                    ></div>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-[.62rem] mt-[1.62rem]">
                <img src={Speed} className="size-[2.25rem]" />
                <div>
                  <p className="text-white/70 text-[0.6875rem] font-normal uppercase">Velocidade máxima</p>
                  <h3 className="text-white text-[2.8125rem] font-extrabold leading-none">
                    {vehicleFiltered[vehicleSelected]?.max_speed}km/h
                  </h3>
                </div>
              </div>
              <div className="flex flex-col gap-2 mt-[1.78rem]">
                <div className="flex items-center gap-2">
                  <LendVehicleButton vehicle={vehicleFiltered[vehicleSelected]} />
                  <button
                    className="text-white/60 text-xs font-bold rounded-lg h-[2.8125rem] border-[.05rem] border-white/15 flex-1 hover:!bg-primary hover:!border-primary hover:!text-[#1E1E1E]"
                    onClick={() => fetch("TAKE_OUT", vehicleFiltered[vehicleSelected])}
                    style={{
                      background:
                        "linear-gradient(109deg, rgba(41, 129, 255, 0.00) 30%, rgba(41, 129, 255, 0.02) 100%), rgba(255, 255, 255, 0.07)",
                    }}
                  >
                    RETIRAR
                  </button>
                  <button
                    className="text-white/60 text-xs font-bold rounded-lg h-[2.8125rem] border-[.05rem] border-white/15 flex-1 hover:!bg-primary hover:!border-primary hover:!text-[#1E1E1E]"
                    onClick={() => fetch("PULL", vehicleFiltered[vehicleSelected])}
                    style={{
                      background:
                        "linear-gradient(109deg, rgba(41, 129, 255, 0.00) 30%, rgba(41, 129, 255, 0.02) 100%), rgba(255, 255, 255, 0.07)",
                    }}
                  >
                    GUARDAR
                  </button>
                </div>
                <div className="flex items-center gap-2">
                  <SellVehicleButton vehicle={vehicleFiltered[vehicleSelected]} />
                  <button
                    className="text-white/60 text-xs font-bold rounded-lg h-[2.8125rem] border-[.05rem] border-white/15 flex-1 hover:!bg-primary hover:!border-primary hover:!text-[#1E1E1E]"
                    style={{
                      background:
                        "linear-gradient(109deg, rgba(41, 129, 255, 0.00) 30%, rgba(41, 129, 255, 0.02) 100%), rgba(255, 255, 255, 0.07)",
                    }}
                    onClick={() => fetch("PULL_NEAREST")}
                  >
                    GUARDAR PRÓXIMO
                  </button>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
      <div className="w-[55.625rem] flex-none flex flex-col gap-[.63rem]">
        <div className="w-full flex items-center justify-between h-9">
          <div className="flex items-center gap-[.44rem] h-full">
            <div
              className="w-[20.6875rem] h-full flex items-center gap-[.31rem] px-[.62rem] rounded-[0.5625rem] border-[.0625rem] border-white/20"
              style={{
                background:
                  "linear-gradient(109deg, rgba(41, 129, 255, 0.00) 30%, rgba(41, 129, 255, 0.02) 100%), rgba(255, 255, 255, 0.07)",
              }}
            >
              <img src={Search} />
              <input
                type="text"
                onChange={(e) => setSearch(e.target.value)}
                placeholder="PESQUISAR"
                className="bg-transparent border-none outline-none text-[0.6875rem] text-white placeholder:text-white/60"
              />
            </div>
            <div
              className="h-full p-[.31rem] rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/[.08]"
              style={{
                background:
                  "linear-gradient(109deg, rgba(41, 129, 255, 0.00) 30%, rgba(41, 129, 255, 0.02) 100%), rgba(255, 255, 255, 0.07)",
              }}
            >
              <button
                onClick={() => setSelection((prevState) => (prevState === "normal" ? null : "normal"))}
                className={`${
                  selection === "normal" && "!bg-primary !border-primary !text-[#1E1E1E]"
                } text-white/70 text-[0.6875rem] font-bold h-full px-[.94rem] rounded-md  hover:border-primary`}
              >
                CONCE
              </button>
              <button
                onClick={() => setSelection((prevState) => (prevState === "special" ? null : "special"))}
                className={`${
                  selection === "special" && "!bg-primary !border-primary !text-[#1E1E1E]"
                } text-white/70 text-[0.6875rem] font-bold h-full px-[.94rem] rounded-md  hover:border-primary`}
              >
                VIP
              </button>
            </div>
          </div>
          <div
            onClick={() => setSelection((prevState) => (prevState === "favorite" ? null : "favorite"))}
            className={`${
              selection === "favorite" && "!bg-primary !border-primary !text-white"
            } group size-9 flex items-center justify-center rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/[.08] cursor-pointer duration-300 hover:!bg-primary`}
          >
            <MdOutlineStar
              className={`${selection === "favorite" && "!text-[#1E1E1E]"} size-5 text-white/30 group-hover:text-white`}
            />
          </div>
        </div>
        <div className="w-[102%] flex-none max-h-[50rem] overflow-auto overflow-x-hidden flex flex-wrap content-start gap-[.62rem]">
          {vehicleFiltered.map((vehicle, index) => (
            <Vehicle
              key={index}
              image_url={vehicle.image_url}
              name={vehicle.name}
              plate={vehicle.plate}
              engine={vehicle.braking}
              category={vehicle.category}
              selected={vehicleSelected === index}
              favorited={favoriteVehicles.includes(vehicle.key)}
              onFavorite={() => handleFavoriteVehicle(vehicle.key)}
              onSelect={() => setVehicleSelected(index)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
