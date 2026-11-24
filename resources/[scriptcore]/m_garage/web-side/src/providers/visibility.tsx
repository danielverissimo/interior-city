import { createContext, useContext, useEffect, useState } from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";
import { useGarage, type VehicleProps } from "../hooks/useGarage";
import fetch from "../utils/fetch";
import { isEnvBrowser } from "../utils/misc";

const VisibilityContext = createContext<() => void>(() => {});
const previewVehicles: VehicleProps[] = [
  { key: "exemplar", name: "Exemplar", category: "Coupé", plate: "NTN4TIYL", image_url: "", type: "normal", max_speed: 185, braking: 59, agility: 78, grip: 91, ipva: false, arrested: false, service: false },
  { key: "hornetagstore", name: "Honda Hornet", category: "Motocicleta", plate: "ICM8V204", image_url: "", type: "special", max_speed: 210, braking: 80, agility: 93, grip: 72, ipva: false, arrested: false, service: false },
  { key: "wrx7pol", name: "BMW X7", category: "SUV", plate: "ICM3B512", image_url: "./images/vehicles/wrx7pol.png", type: "special", max_speed: 190, braking: 90, agility: 70, grip: 88, ipva: true, arrested: false, service: false },
  { key: "chevys10", name: "Chevrolet S10", category: "SUV", plate: "ICI6C318", image_url: "./images/vehicles/ausente.png", type: "normal", max_speed: 112, braking: 40, agility: 53, grip: 100, ipva: true, arrested: false, service: false },
];

export function VisibilityProvider({ children }: { children: React.ReactNode }) {
  const [visible, setVisible] = useState(isEnvBrowser());
  const update = useGarage((state) => state.update);

  useNuiEvent("open", () => setVisible(true));
  useNuiEvent("close", () => setVisible(false));

  function close() {
    setVisible(false);
    if (!isEnvBrowser()) void fetch("CLOSE").catch(console.error);
  }

  useEffect(() => {
    if (!visible) return;
    let current = true;
    fetch<VehicleProps[]>("GET_GARAGE", null, previewVehicles)
      .then((vehicles) => { if (current) update({ vehicles: Array.isArray(vehicles) ? vehicles : [] }); })
      .catch((error) => {
        if (current) update({ vehicles: [] });
        console.error(error);
      });
    return () => { current = false; };
  }, [visible, update]);

  useEffect(() => {
    if (!visible) return;
    const keyHandler = (event: KeyboardEvent) => {
      if (event.code === "Escape" && !event.defaultPrevented) close();
    };
    window.addEventListener("keydown", keyHandler);
    return () => window.removeEventListener("keydown", keyHandler);
  }, [visible]);

  return (
    <VisibilityContext.Provider value={close}>
      {visible && children}
    </VisibilityContext.Provider>
  );
}

export const useVisibility = () => useContext(VisibilityContext);
