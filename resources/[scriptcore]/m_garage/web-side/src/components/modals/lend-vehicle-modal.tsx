import * as Dialog from "@radix-ui/react-dialog";
import clsx from "clsx";
import { useRef } from "react";
import { VehicleProps } from "../../hooks/useGarage";
import fetch from "../../utils/fetch";

import Car from "/icons/car.svg";

interface LendVehicleButtonProps {
  vehicle: VehicleProps;
}

export function LendVehicleButton({ vehicle }: LendVehicleButtonProps) {
  const inputUserRef = useRef<HTMLInputElement>(null);

  function handleConfirm() {
    fetch("LEND_VEHICLE", {
      vehicle,
      userId: Number(inputUserRef.current?.value),
    });
  }

  return (
    <Dialog.Root>
      <Dialog.Trigger
        className="disabled:opacity-20 disabled:pointer-events-none text-white/60 text-xs font-bold rounded-lg h-[2.8125rem] border-[.05rem] border-white/15 flex-1 hover:!bg-primary hover:!border-primary hover:!text-[#1E1E1E] bg-white/[.13]"
        disabled={vehicle?.type === "service"}
      >
        EMPRESTAR
      </Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/90" />
        <Dialog.Content
          className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 flex flex-col items-center gap-5 p-[1.875rem] rounded-[0.8125rem] border-[.0625rem] border-white/30 focus:outline-none"
          style={{
            background:
              "linear-gradient(180deg, rgba(255, 255, 255, 0.00) 0%, rgba(255, 255, 255, 0.02) 100%), radial-gradient(1133.06% 111.04% at 100.14% 50%, rgba(0, 0, 0, 0.45) 0%, rgba(0, 0, 0, 0.00) 100%), rgba(30, 30, 30, 0.94)",
          }}
        >
          <svg className="size-[4.375rem]" viewBox="0 0 70 70" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path
              d="M4.33013 40.5C2.36517 37.0966 2.36516 32.9034 4.33013 29.5L14.9019 11.1891C16.8669 7.7857 20.4983 5.68911 24.4282 5.68911L45.5718 5.68911C49.5017 5.68911 53.1331 7.7857 55.0981 11.1891L65.6699 29.5C67.6348 32.9034 67.6348 37.0966 65.6699 40.5L55.0981 58.8109C53.1331 62.2143 49.5017 64.3109 45.5718 64.3109L24.4282 64.3109C20.4983 64.3109 16.8669 62.2143 14.9019 58.8109L4.33013 40.5Z"
              fill="url(#paint0_radial_182_5264)"
              fill-opacity="0.45"
              stroke="#2981FF"
              stroke-width="2"
            />
            <path
              d="M8.88675 40C7.10042 36.906 7.10042 33.094 8.88675 30L17.6132 14.8853C19.3996 11.7913 22.7008 9.88527 26.2735 9.88527L43.7265 9.88527C47.2992 9.88527 50.6004 11.7913 52.3868 14.8853L61.1132 30C62.8996 33.094 62.8996 36.906 61.1132 40L52.3868 55.1147C50.6004 58.2087 47.2992 60.1147 43.7265 60.1147L26.2735 60.1147C22.7008 60.1147 19.3996 58.2087 17.6132 55.1147L8.88675 40Z"
              fill="#2981FF"
            />
            <path
              d="M47.25 31.675L44.8 26.6C44.1 25.375 42.875 24.5 41.475 24.5H28.525C27.125 24.5 25.9 25.375 25.2 26.6L22.75 31.675C21.7 31.85 21 32.725 21 33.6V39.725C21 40.775 21.7 41.65 22.75 41.825V45.325C22.75 46.375 23.625 47.25 24.675 47.25H26.25C27.125 47.25 28 46.375 28 45.325V42H42V45.325C42 46.375 42.875 47.25 43.925 47.25H45.5C46.55 47.25 47.425 46.375 47.425 45.325V41.825C48.475 41.65 49.175 40.775 49.175 39.725V33.6C49 32.725 48.3 31.85 47.25 31.675ZM28 35.7C28 36.225 27.475 36.75 26.95 36.75H23.8C23.275 36.75 22.75 36.225 22.75 35.7V34.3C22.75 33.775 23.275 33.25 23.8 33.25H26.95C27.475 33.25 28 33.775 28 34.3V35.7ZM38.5 40.25H31.5V38.5H38.5V40.25ZM24.675 31.5L26.775 27.3C27.125 26.6 27.825 26.25 28.525 26.25H41.475C42.175 26.25 42.875 26.6 43.225 27.3L45.325 31.5H24.675ZM47.25 35.7C47.25 36.225 46.725 36.75 46.2 36.75H43.05C42.525 36.75 42 36.225 42 35.7V34.3C42 33.775 42.525 33.25 43.05 33.25H46.2C46.725 33.25 47.25 33.775 47.25 34.3V35.7Z"
              fill="#1E1E1E"
            />
            <defs>
              <radialGradient
                id="paint0_radial_182_5264"
                cx="0"
                cy="0"
                r="1"
                gradientUnits="userSpaceOnUse"
                gradientTransform="translate(34.9999 -0.0999952) rotate(90) scale(77.725 793.143)"
              >
                <stop />
                <stop offset="1" stop-opacity="0" />
              </radialGradient>
            </defs>
          </svg>
          <div className="flex flex-col gap-2 text-center">
            <Dialog.Title asChild>
              <h4 className="text-white font-extrabold text-xl uppercase">{vehicle?.name}</h4>
            </Dialog.Title>
          </div>
          <Dialog.Description asChild>
            <p className="text-white/70 text-xs text-center uppercase">
              Insira o id de quem deseja <strong className="font-semibold text-white/90">emprestar a chave</strong>{" "}
              <br /> do seu veículo.
            </p>
          </Dialog.Description>
          <div className="w-[21.25rem] flex flex-col gap-2 items-end">
            <input
              ref={inputUserRef}
              type="number"
              min={0}
              className="border-[.0313rem] border-white/25 w-full h-[3.125rem] bg-white/[.08] text-xs leading-[normal] focus:outline-none px-4 rounded-[0.5625rem] text-white placeholder:text-white/60 font-normal"
              placeholder="ID DO JOGADOR"
            />
            <div className="flex items-center gap-2 h-[2.8125rem] w-full">
              <Dialog.Close asChild>
                <button className="uppercase flex-1 h-full rounded-[0.5625rem] bg-white/[.13] grid place-items-center font-bold text-xs leading-[normal] border-[.0313rem] border-white/25 text-white/80">
                  Cancelar
                </button>
              </Dialog.Close>
              <Dialog.Close asChild>
                <button
                  className="flex-1 h-full rounded-[0.5625rem] bg-primary border-[.0625rem] border-primary shadow-primary grid place-items-center font-bold text-xs leading-[normal] text-[#1E1E1E]"
                  onClick={handleConfirm}
                >
                  CONFIRMAR
                </button>
              </Dialog.Close>
            </div>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
