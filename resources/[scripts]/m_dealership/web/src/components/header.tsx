import clsx from "clsx";
import { motion } from "framer-motion";
import { useLocation, useNavigate } from "react-router-dom";
import logo from "../assets/logo.svg";

const categories = [
  { id: "esportivos", label: "ESPORTIVOS" },
  { id: "sedan", label: "SEDAN" },
  { id: "meus-veiculos", label: "MEUS CARROS" },
  { id: "motos", label: "MOTOS" },
  { id: "vips", label: "VIPS", vip: true },
  { id: "off-roads", label: "OFF-ROADS" },
  { id: "caminhoes", label: "CAMINHÕES" },
  { id: "aeronaves", label: "AERONAVES" },
  { id: "brasileiros", label: "BRASILEIROS" },
  { id: "outros", label: "OUTROS" },
];

export default function Header({
  category,
  setCategory,
}: {
  category: string;
  setCategory: (category: string) => void;
}) {
  const navigate = useNavigate();
  const location = useLocation();

  const handleCategoryChange = (newCategory: string) => {
    setCategory(newCategory);

    const destination = `/dealer?category=${encodeURIComponent(newCategory)}`;
    if (`${location.pathname}${location.search}` !== destination) {
      navigate(destination);
    }
  };

  return (
    <header className="w-full min-h-[3.25rem] flex items-center gap-[1.65rem] border-b border-white/[.06] pb-[.75rem]">
      <motion.button
        type="button"
        aria-label="Ir para o início da concessionária"
        onClick={() => navigate("/")}
        initial={{ opacity: 0, x: -16 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.3 }}
        whileHover={{ scale: 1.03 }}
        whileTap={{ scale: 0.98 }}
        className="flex-none h-[2.75rem] min-w-[8.6rem] flex items-center justify-start pr-[1.5rem] border-r border-white/[.08]"
      >
        <img className="h-[2.55rem] w-auto object-contain" src={logo} alt="Dealership" />
      </motion.button>

      <nav className="flex-1 min-w-0 flex items-center justify-between gap-[1rem] whitespace-nowrap">
        {categories.map((item, index) => {
          const active = category === item.id;

          return (
            <motion.button
              key={item.id}
              type="button"
              onClick={() => handleCategoryChange(item.id)}
              initial={{ opacity: 0, y: -12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.24, delay: Math.min(index * 0.035, 0.25) }}
              whileTap={{ scale: 0.97 }}
              className={clsx(
                "relative flex-none h-[2.25rem] px-[.2rem] flex items-center justify-center text-[0.76rem] font-bold transition-colors duration-150",
                item.vip
                  ? "rounded-lg px-[.9rem]"
                  : "text-white/65 hover:text-white",
                active && !item.vip && "!text-white",
                item.vip &&
                  (active
                    ? "bg-[#2981FF] text-white"
                    : "bg-[#2981FF]/20 text-white/80 hover:bg-[#2981FF]/35 hover:text-white"),
              )}
              style={
                item.vip && active
                  ? {
                      boxShadow:
                        "0 0 .25rem rgba(0,0,0,.10), 0 0 .875rem rgba(41,129,255,.45)",
                    }
                  : undefined
              }
            >
              {item.label}
              {!item.vip && (
                <span
                  className={clsx(
                    "absolute left-0 right-0 -bottom-[.52rem] h-[.12rem] rounded-full bg-[#2981FF] transition-opacity duration-150",
                    active ? "opacity-100" : "opacity-0",
                  )}
                />
              )}
            </motion.button>
          );
        })}
      </nav>
    </header>
  );
}
