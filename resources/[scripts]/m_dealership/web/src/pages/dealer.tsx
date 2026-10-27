import Header from "@/components/header";
import { Search } from "lucide-react";
import { motion } from "framer-motion";
import { clsx } from "clsx";
import { useState, useRef, useEffect, useMemo } from "react";
import { emit } from "@/utils/emit";
import defaultVehicle from "../assets/default_vehicle.webp";
import { ColorPicker } from "antd";

import aceleration from "../assets/aceleration.svg";
import seats from "../assets/seats.svg";
import trunk from "../assets/trunk.svg";
import { useLocation, useNavigate } from "react-router-dom";

interface IVehicle {
  name: string;
  value: number;
  image: string;
  acceleration: string;
  speed: number;
  seats: number;
  trunk: number;
  stock: number;
  category: string;
  spawn: string;
}

interface IActionResponse {
  ok: boolean;
  price?: number;
  message?: string;
}

export default function Dealer() {
  const navigate = useNavigate();
  const location = useLocation();
  const [vehicles, setVehicles] = useState<IVehicle[]>([]);
  const [selectedVehicle, setSelectedVehicle] = useState<IVehicle | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const [search, setSearch] = useState<string>("");
  const [myVehicles, setMyVehicles] = useState<Omit<IVehicle, "category" | "stock">[]>([]);
  const [modalVisible, setModalVisible] = useState(false);
  const [color, setColor] = useState<string>("#8e1e1e");
  const initialCategory = useMemo(() => {
    const value = new URLSearchParams(location.search).get("category");
    return value || "esportivos";
  }, []);
  const [category, setCategory] = useState<string>(initialCategory);
  const [actionBusy, setActionBusy] = useState<"buy" | "sell" | "test" | null>(null);
  const [loadingVehicles, setLoadingVehicles] = useState(true);
  const [purchasePrice, setPurchasePrice] = useState<number | null>(null);

  const filteredVehicles = useMemo(() => {
    return vehicles.filter((vehicle) => vehicle.category === category && vehicle.name.toLowerCase().includes(search.toLowerCase()));
  }, [vehicles, search, category]);

  function convertHexToRgba(hex: string) {
    return `rgba(${parseInt(hex.slice(1, 3), 16)}, ${parseInt(hex.slice(3, 5), 16)}, ${parseInt(hex.slice(5, 7), 16)}, 1)`;
  }

  const loadVehicles = async () => {
    try {
      const data = await emit<IVehicle[]>("GET_VEHICLES", {}, []);
      setVehicles(Array.isArray(data) ? data : []);
    } catch {
      setVehicles([]);
    } finally {
      setLoadingVehicles(false);
    }
  };

  const loadMyVehicles = async () => {
    try {
      const data = await emit<IVehicle[]>("GET_MY_VEHICLES", {}, []);
      setMyVehicles(Array.isArray(data) ? data : []);
    } catch {
      setMyVehicles([]);
    }
  };

  const handleBuy = async () => {
    if (!selectedVehicle?.spawn || actionBusy) return;

    setActionBusy("buy");
    try {
      const response = await emit<IActionResponse>("CAN_BUY", {
        vehicle: selectedVehicle,
        color: convertHexToRgba(color),
      }, { ok: true, price: selectedVehicle.value });

      if (response?.ok) {
        setPurchasePrice(response.price ?? selectedVehicle.value);
        setModalVisible(true);
        await loadVehicles();
      }
    } catch {
      // A rota NUI já registra a falha no console; o botão é liberado no finally.
    } finally {
      setActionBusy(null);
    }
  };

  const handleSell = async () => {
    if (!selectedVehicle?.spawn || actionBusy) return;

    setActionBusy("sell");
    try {
      const response = await emit<IActionResponse>("SELL_VEHICLE", {
        vehicle: selectedVehicle,
      }, { ok: true });

      if (response?.ok) {
        setSelectedVehicle(null);
        await loadMyVehicles();
      }
    } catch {
      // Falha tratada pela rota NUI/servidor.
    } finally {
      setActionBusy(null);
    }
  };

  const handleTestDrive = async () => {
    if (!selectedVehicle?.spawn || actionBusy) return;

    setActionBusy("test");
    try {
      await emit<IActionResponse>("TEST_DRIVE", { vehicle: selectedVehicle }, { ok: true });
    } catch {
      setActionBusy(null);
      return;
    }

    // Quando o test-drive inicia, a própria NUI é fechada. Caso falhe,
    // o callback retorna imediatamente e o botão volta a ficar disponível.
    window.setTimeout(() => setActionBusy(null), 750);
  };

  useEffect(() => {
    void loadVehicles();
    void loadMyVehicles();
  }, []);

  useEffect(() => {
    const value = new URLSearchParams(location.search).get("category");
    if (value && value !== category) setCategory(value);
  }, [location.search]);

  useEffect(() => {
    setSearch("");
    setSelectedVehicle(null);
    if (category === "meus-veiculos") void loadMyVehicles();
  }, [category]);


  return (
    <div
      className="w-[99.375rem] h-[51.875rem] p-10 rounded-[0.8125rem] border-[.0625rem] border-white/30 flex flex-col gap-[2.56rem] overflow-hidden"
      style={{
        background:
          "linear-gradient(180deg, rgba(255, 255, 255, 0.00) 0%, rgba(255, 255, 255, 0.02) 100%), radial-gradient(1133.06% 111.04% at 100.14% 50%, rgba(0, 0, 0, 0.45) 0%, rgba(0, 0, 0, 0.00) 100%), rgba(30, 30, 30, 0.94)",
      }}
    >
      <Header category={category} setCategory={setCategory} />
      <div className="flex-1 min-h-0 flex flex-col overflow-hidden">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="flex items-center gap-2 shrink-0"
        >
          <motion.div
            onClick={() => selectedVehicle ? setSelectedVehicle(null) : navigate("/")}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="w-[5.625rem] h-[2.1875rem] bg-white/15 flex items-center justify-center gap-1 cursor-pointer rounded-lg border-[.0625rem] border-white/[.04]"
          >
            <svg width="13" height="13" viewBox="0 0 13 13" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path
                d="M4.535 6.7715L8.71475 10.754C8.78449 10.8205 8.87714 10.8576 8.9735 10.8576C9.06985 10.8576 9.1625 10.8205 9.23225 10.754L9.23675 10.7495C9.27067 10.7173 9.29769 10.6785 9.31615 10.6355C9.33461 10.5925 9.34413 10.5462 9.34413 10.4994C9.34413 10.4526 9.33461 10.4063 9.31615 10.3633C9.29769 10.3203 9.27067 10.2815 9.23675 10.2493L5.30075 6.49925L9.23675 2.75075C9.27067 2.71852 9.29769 2.67973 9.31615 2.63673C9.33461 2.59373 9.34413 2.54742 9.34413 2.50063C9.34413 2.45383 9.33461 2.40753 9.31615 2.36453C9.29769 2.32153 9.27067 2.28273 9.23675 2.2505L9.23225 2.246C9.1625 2.17952 9.06985 2.14243 8.9735 2.14243C8.87714 2.14243 8.78449 2.17952 8.71475 2.246L4.535 6.2285C4.49824 6.26353 4.46897 6.30565 4.44898 6.35232C4.42898 6.39899 4.41867 6.44923 4.41867 6.5C4.41867 6.55078 4.42898 6.60102 4.44898 6.64769C4.46897 6.69436 4.49824 6.73648 4.535 6.7715Z"
                fill="white"
                fillOpacity="0.5"
              />
            </svg>
            <p className="text-white/70 text-[0.6875rem] font-bold uppercase">Voltar</p>
          </motion.div>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="flex-1 h-[2.1875rem] px-3 bg-white/[.04] border-[.0625rem] border-white/[.04] rounded-lg relative"
          >
            <input
              ref={inputRef}
              type="text"
              className="w-full h-full px-3 bg-transparent border-none placeholder:text-white/40 text-white text-[0.6875rem]"
              placeholder="BUSQUE PELO NOME..."
              onChange={(e) => setSearch(e.target.value)}
            />
            <Search className="size-[1.25rem] text-white/50 absolute right-3 top-1" />
          </motion.div>
        </motion.div>
        <div className="flex flex-1 min-h-0 gap-[1.25rem] mt-2.5 overflow-hidden">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
            className={clsx("w-[46.25rem] h-full min-h-0 relative flex flex-col justify-between pb-2 overflow-hidden", {
              hidden: !selectedVehicle,
            })}
          >
            {selectedVehicle && selectedVehicle.category !== "meus-veiculos" && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.5 }}
                className="space-y-1 absolute top-20"
              >
                <p className="text-[0.6875rem] text-white/70 font-medium uppercase">Cor do veículo</p>
                <ColorPicker value={color} format="hex" onChange={(value) => setColor(value.toHexString())} />{" "}
              </motion.div>
            )}
            <motion.p
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3 }}
              className="text-white text-[3.4375rem] font-bold uppercase w-full truncate"
            >
              {selectedVehicle?.name}
            </motion.p>
            <motion.img
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.5, delay: 0.4 }}
              src={selectedVehicle?.image}
              onError={(e) => {
                e.currentTarget.src = defaultVehicle;
              }}
              className="w-full h-[21rem] object-contain"
              alt=""
            />
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.6 }}
              className="w-full flex flex-col gap-4"
            >
              <div className="flex w-full justify-between">
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.3, delay: 0.7 }}
                  className="flex gap-3"
                >
                  {selectedVehicle?.category !== "meus-veiculos" && (
                    <p className="text-white text-[2.1875rem] leading-normal font-bold">
                      R${selectedVehicle?.value.toLocaleString("pt-BR")}
                    </p>
                  )}
                </motion.div>
                <motion.div
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.3, delay: 0.7 }}
                  className="flex items-center gap-3"
                >
                  {category !== "meus-veiculos" && (
                    <motion.button
                      onClick={handleTestDrive}
                      disabled={actionBusy !== null}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      className="w-[10.718rem] h-[2.3125rem] bg-white/[.12] border-[.0625rem] border-white/15 font-bold uppercase text-white/70 text-xs rounded-lg disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      {actionBusy === "test" ? "AGUARDE..." : "TEST-DRIVE"}
                    </motion.button>
                  )}
                  {(category === "meus-veiculos" || category !== "vips") && (
                    <motion.button
                      onClick={category === "meus-veiculos" ? handleSell : handleBuy}
                      disabled={actionBusy !== null}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      className="w-[10.718rem] h-[2.3125rem] bg-[#2981FF] font-bold uppercase text-[#FFF] text-xs rounded-lg disabled:opacity-40 disabled:cursor-not-allowed"
                      style={{
                        boxShadow: "0 0 .25rem 0 rgba(0, 0, 0, 0.10), 0rem 0 .875rem 0 rgba(41, 129, 255, 0.45)",
                      }}
                    >
                      {actionBusy === "sell" ? "VENDENDO..." : actionBusy === "buy" ? "COMPRANDO..." : category === "meus-veiculos" ? "VENDER" : "COMPRAR"}
                    </motion.button>
                  )}
                </motion.div>
              </div>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.8 }}
                className="w-full flex items-center justify-between px-5 h-[6.875rem] border border-white/[.04] rounded-lg bg-white/[.04]"
              >
                <div className="flex items-center gap-2">
                  <img className="size-[2.8125rem]" src={aceleration} alt="" />
                  <div>
                    <p className="text-white/50 text-[0.6875rem] relative z-20 uppercase">Aceleração</p>
                    <p className="text-white text-[1.375rem] font-bold uppercase leading-[1rem] relative z-10">
                      {selectedVehicle?.acceleration}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <img className="size-[2.8125rem]" src={trunk} alt="" />
                  <div>
                    <p className="text-white/50 text-[0.6875rem] relative z-20 uppercase">Porta Malas</p>
                    <p className="text-white text-[1.375rem] font-bold uppercase leading-[1rem] relative z-10">
                      {selectedVehicle?.trunk}KG
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <img className="size-[2.8125rem]" src={aceleration} alt="" />
                  <div>
                    <p className="text-white/50 text-[0.6875rem] relative z-20 uppercase">Velocidade</p>
                    <p className="text-white text-[1.375rem] font-bold uppercase leading-[1rem] relative z-10">
                      {selectedVehicle?.speed}KM/H
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <img className="size-[2.8125rem]" src={seats} alt="" />
                  <div>
                    <p className="text-white/50 text-[0.6875rem] relative z-20 uppercase">Assentos</p>
                    <p className="text-white text-[1.375rem] font-bold uppercase leading-[1rem] relative z-10">
                      {selectedVehicle?.seats}
                    </p>
                  </div>
                </div>
              </motion.div>
            </motion.div>
          </motion.div>
          <div
            className={clsx(
              "flex-1 min-w-0 min-h-0 h-full grid grid-cols-4 gap-2.5 content-start overflow-y-auto overflow-x-hidden pr-1",
              {
                "!w-[38.6875rem] !grid-cols-2": selectedVehicle,
              }
            )}
          >
            {loadingVehicles && category !== "meus-veiculos" && (
              <div className="col-span-full h-[8rem] flex items-center justify-center text-white/45 text-[.8rem] font-bold uppercase">
                Carregando veículos...
              </div>
            )}
            {category === "meus-veiculos"
              ? myVehicles.map((vehicle, index) => {
                  return (
                    <motion.div
                      key={(vehicle as IVehicle).spawn || `${vehicle.name}-${index}`}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.5, delay: index * 0.1 }}
                      className="flex-none flex flex-col gap-3 h-[9.75rem] w-[23.125rem] rounded-lg bg-white/[.04] relative p-2.5"
                      style={{
                        background:
                          selectedVehicle?.name === vehicle.name
                            ? "linear-gradient(180deg, rgba(41, 129, 255, 0.00) 0%, rgba(41, 129, 255, 0.25) 128.57%), linear-gradient(90deg, rgba(0, 0, 0, 0.50) 0%, rgba(0, 0, 0, 0.43) 100%)"
                            : "",
                        boxShadow: "inset 0 0 0 .125rem rgba(255, 255, 255, 0.04)",
                      }}
                    >
                      <div className="flex items-center w-full h-[5.4375rem]">
                        <img
                          src={vehicle.image}
                          onError={(e) => {
                            e.currentTarget.src = defaultVehicle;
                          }}
                          className="w-40 h-[5.4375rem] object-contain"
                        />
                        <div className="flex-1 ">
                          <p className="w-[11.5rem]  text-white text-[1.0625rem] font-extrabold uppercase truncate leading-none">
                            {vehicle.name}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-[.44rem] w-full">
                        <button
                          onClick={() => setSelectedVehicle(vehicle as IVehicle)}
                          className="flex-1 h-[2.0625rem] bg-white/15 border-[.0625rem] border-white/15 rounded-lg text-white/80 text-[0.6875rem] font-extrabold"
                        >
                          SELECIONAR
                        </button>
                      </div>
                      {/* <p className="text-white text-sm absolute top-5 left-5 uppercase font-bold">{vehicle.name}</p>
                      <img
                        src={debounce}
                        alt=""
                        className="absolute top-1/2 left-1/2 max-h-[8.125rem] -translate-x-1/2 -translate-y-1/2 object-cover"
                      />
                      <img
                        src={vehicle.image}
                        alt=""
                        onError={(e) => {
                          e.currentTarget.src = defaultVehicle;
                        }}
                        className="absolute top-1/2 left-1/2 max-h-[5.8rem] -translate-x-1/2 -translate-y-1/2 object-cover"
                      />
                      <div className="space-y-4 w-full absolute left-1/2 -translate-x-1/2 bottom-2.5 px-5">
                        <div className="flex items-center w-full justify-between">
                          <p className="text-white/70 font-bold">R${vehicle.value.toLocaleString("pt-BR")}</p>
                        </div>
                        <motion.button
                          onClick={() => setSelectedVehicle(vehicle as IVehicle)}
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                          className={clsx(
                            "muted-foreground w-full h-[2.5rem] text-sm text-white/70 font-bold uppercase",
                            {
                              accent: selectedVehicle?.name === vehicle.name,
                            }
                          )}
                        >
                          DETALHES
                        </motion.button>
                      </div> */}
                    </motion.div>
                  );
                })
              : filteredVehicles.map((vehicle, index) => {
                  return (
                    <motion.div
                      key={vehicle.spawn || `${vehicle.name}-${index}`}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.5, delay: index * 0.1 }}
                      className="flex-none flex flex-col gap-3 h-[11.5625rem] w-[23.125rem] rounded-lg bg-white/[.04] relative p-2.5"
                      style={{
                        background:
                          selectedVehicle?.name === vehicle.name
                            ? "linear-gradient(180deg, rgba(41, 129, 255, 0.00) 0%, rgba(41, 129, 255, 0.25) 128.57%), linear-gradient(90deg, rgba(0, 0, 0, 0.50) 0%, rgba(0, 0, 0, 0.43) 100%)"
                            : "",
                        boxShadow: "inset 0 0 0 .125rem rgba(255, 255, 255, 0.04)",
                      }}
                    >
                      <div className="flex items-center w-full h-[5.4375rem]">
                        <img
                          src={vehicle.image}
                          onError={(e) => {
                            e.currentTarget.src = defaultVehicle;
                          }}
                          className="w-40 h-[5.4375rem] object-contain"
                        />
                        <div className="flex-1 ">
                          <p className="w-[11.5rem]  text-white text-[1.0625rem] font-extrabold uppercase truncate leading-none">
                            {vehicle.name}
                          </p>
                          <p className="w-[11.5rem] text-white/80 text-[0.8125rem] font-medium uppercase truncate leading-none">
                            {vehicle.category}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-[.38rem]">
                          <svg
                            width="15"
                            height="15"
                            className="size-4"
                            viewBox="0 0 15 15"
                            fill="none"
                            xmlns="http://www.w3.org/2000/svg"
                          >
                            <g clip-path="url(#clip0_1121_1085)">
                              <path
                                d="M7.303 0.039987C7.36525 0.0133021 7.43227 -0.000457764 7.5 -0.000457764C7.56773 -0.000457764 7.63475 0.0133021 7.697 0.039987L14.5 2.95599L7.5 5.95599L0.5 2.95599L7.303 0.039987ZM0 3.82999V11.5C0 11.7 0.12 11.88 0.303 11.96L7 14.83V6.82999L0 3.82999ZM8 6.82999L15 3.82999V11.5C15.0001 11.5979 14.9714 11.6937 14.9176 11.7755C14.8637 11.8572 14.787 11.9214 14.697 11.96L8 14.83V6.82999Z"
                                fill="white"
                                fill-opacity="0.4"
                              />
                            </g>
                            <defs>
                              <clipPath id="clip0_1121_1085">
                                <rect width="15" height="15" fill="white" />
                              </clipPath>
                            </defs>
                          </svg>
                          <p className="text-white/60 text-[0.8125rem] font-medium">
                            Estoque: <b className="text-white">{vehicle.stock}</b>
                          </p>
                        </div>
                        <p className="text-white text-[1.125rem] font-extrabold leading-none">
                          R${vehicle.value.toLocaleString("pt-BR")}
                        </p>
                      </div>
                      <div className="flex items-center gap-[.44rem] w-full">
                        <button
                          onClick={() => setSelectedVehicle(vehicle)}
                          className="flex-1 h-[2.0625rem] bg-white/15 border-[.0625rem] border-white/15 rounded-lg text-white/80 text-[0.6875rem] font-extrabold"
                        >
                          SELECIONAR
                        </button>
                      </div>
                    </motion.div>
                  );
                })}
          </div>
        </div>
      </div>
      {modalVisible && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.3 }}
          className={clsx("absolute w-full h-full bg-black/60 flex items-center justify-center left-0 bottom-0", {
            hidden: !modalVisible,
          })}
        >
          <motion.div
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="w-[21.875rem] p-10 flex flex-col items-center rounded-lg border-[.0625rem] border-white/30"
            style={{
              background:
                "linear-gradient(180deg, rgba(255, 255, 255, 0.00) 0%, rgba(255, 255, 255, 0.03) 100%), radial-gradient(1133.06% 111.04% at 100.14% 50%, rgba(0, 0, 0, 0.45) 0%, rgba(0, 0, 0, 0.00) 100%), rgba(30, 30, 30, 0.94)",
            }}
          >
            <svg
              className="size-[6.25rem] mb-[1.88rem]"
              viewBox="0 0 100 100"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M50 100C36.7392 100 24.0215 94.7322 14.6447 85.3553C5.26784 75.9785 0 63.2608 0 50C0 36.7392 5.26784 24.0215 14.6447 14.6447C24.0215 5.26784 36.7392 0 50 0C63.2608 0 75.9785 5.26784 85.3553 14.6447C94.7322 24.0215 100 36.7392 100 50C100 63.2608 94.7322 75.9785 85.3553 85.3553C75.9785 94.7322 63.2608 100 50 100ZM40 75L85 32.5L77.5 25L40 60L22.5 42.5L15 50L40 75Z"
                fill="#2981FF"
              />
            </svg>
            <motion.h6
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: 0.6 }}
              className="text-white text-[1.875rem] font-extrabold"
            >
              SUCESSO
            </motion.h6>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: 0.7 }}
              className="text-white/70 text-center text-[0.9375rem] w-[17rem]"
            >
              VOCÊ REALIZOU A COMPRA DE UM VEÍCULO{" "}
              <span className="font-bold text-white uppercase">{selectedVehicle?.name}</span> POR{" "}
              <span className="font-bold text-white uppercase">R${(purchasePrice ?? selectedVehicle?.value ?? 0).toLocaleString("pt-BR")}</span>
            </motion.p>
            <motion.button
              onClick={() => {
                setModalVisible(false);
                setSelectedVehicle(null);
                setPurchasePrice(null);
              }}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: 0.8 }}
              className="w-[18.125rem] bg-white/15 border-[.0625rem] border-white/15 mt-6 h-[2.8125rem] rounded-lg text-sm text-white font-bold uppercase hover:bg-[#2981FF] hover:text-[#FFF] transition-all duration-300"
            >
              CONFIRMAR
            </motion.button>
          </motion.div>
        </motion.div>
      )}
    </div>
  );
}
