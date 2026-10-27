import clsx from "clsx";
import { useData } from "../hooks/useData";
import { useHud } from "../hooks/useHud";

const RING_PATH = "M40.25 21C40.25 26.1054 38.2219 31.0017 34.6118 34.6118C31.0017 38.2219 26.1054 40.25 21 40.25C15.8946 40.25 10.9983 38.2219 7.3882 34.6118C3.77812 31.0017 1.75 26.1054 1.75 21C1.75 15.8946 3.77812 10.9983 7.38819 7.3882C10.9983 3.77812 15.8946 1.75 21 1.75C26.1054 1.75 31.0017 3.77812 34.6118 7.38819C38.2219 10.9983 40.25 15.8946 40.25 21L40.25 21Z";

function CircularStat({ type, value }: { type: "health" | "armour"; value: number }) {
  const isHealth = type === "health";
  const color = isHealth ? "#D3132F" : "#2974EB";
  const maskId = `hud-v1-${type}-strokes`;
  const normalized = Math.max(0, Math.min(100, Number(value) || 0));
  const dashOffset = 100.01 - (normalized / 100) * 100.01;

  return (
    <div
      className="size-12 rounded-full relative flex items-center justify-center"
      style={{
        background: "linear-gradient(90deg, rgba(17, 17, 17, 0.80) 0%, rgba(26, 26, 26, 0.56) 100%)",
        boxShadow: "0 0 0 3px rgba(0, 0, 0, 0.25)",
      }}
    >
      <svg className="absolute -translate-x-1/2 -translate-y-1/2 left-1/2 top-1/2" width="42" height="42" viewBox="0 0 42 42" fill="none">
        <defs>
          <mask id={maskId} maskUnits="userSpaceOnUse" x="0" y="0" width="42" height="42">
            <path d={RING_PATH} stroke="white" strokeWidth="4" strokeDasharray="10 2" />
          </mask>
        </defs>
        <path d={RING_PATH} stroke="#FFFFFF33" strokeWidth="4" strokeDasharray="100.01" pathLength="100.01" mask={`url(#${maskId})`} />
        <path d={RING_PATH} stroke={color} strokeWidth="4" strokeDasharray="100.01" pathLength="100.01" strokeDashoffset={dashOffset} mask={`url(#${maskId})`} />
      </svg>

      <div className="w-[1.875rem] h-[1.875rem] rounded-full flex items-center justify-center" style={{ background: `${color}26` }}>
        {isHealth ? (
          <svg width="14" height="13" viewBox="0 0 14 13" fill="none">
            <path d="M7.00004 12.2333L6.03337 11.3533C2.60004 8.24 0.333374 6.18 0.333374 3.66667C0.333374 1.60667 1.94671 0 4.00004 0C5.16004 0 6.27337 0.54 7.00004 1.38667C7.72671 0.54 8.84004 0 10 0C12.0534 0 13.6667 1.60667 13.6667 3.66667C13.6667 6.18 11.4 8.24 7.96671 11.3533L7.00004 12.2333Z" fill={color}/>
          </svg>
        ) : (
          <svg width="17" height="16" viewBox="0 0 17 16" fill="none">
            <path d="M14.4752 3.47944C14.4692 3.36769 14.4313 3.26152 14.3674 3.17794C14.3035 3.09436 14.2175 3.03821 14.123 3.01849C11.8186 2.53659 10.8489 2.1597 8.76786 1.06715C8.56 0.976836 8.43116 0.978399 8.23214 1.06715C6.1511 2.16095 5.18143 2.53597 2.877 3.01849C2.78252 3.03821 2.69646 3.09436 2.63259 3.17794C2.56873 3.26152 2.53075 3.36769 2.52476 3.47944C2.42163 5.3889 2.64101 7.1671 3.17727 8.76561C3.6158 10.0691 4.26541 11.2618 5.09063 12.2786C6.28717 13.7608 7.61391 14.6262 8.29803 14.9537C8.42775 15.0154 8.57305 15.0154 8.70277 14.9537C9.42601 14.6124 10.7035 13.7718 11.9094 12.2779C12.7345 11.2613 13.3841 10.0689 13.8227 8.76561C14.359 7.16742 14.5784 5.3889 14.4752 3.47944Z" fill={color}/>
          </svg>
        )}
      </div>
    </div>
  );
}

export function PlayerStats() {
  const { hud } = useHud();
  const { data } = useData();
  const vehicleOpen = data.vehicle?.show === true;

  return (
    <div
      className={clsx(
        "flex flex-col gap-3 w-14 mb-1",
        hud.velocimeter === 2 && vehicleOpen && "absolute bottom-6"
      )}
      style={{ right: hud.velocimeter === 2 && vehicleOpen ? "1.75rem" : undefined }}
    >
      <CircularStat type="health" value={data.health} />
      <CircularStat type="armour" value={data.armour} />
    </div>
  );
}
