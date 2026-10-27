import React, { forwardRef, Ref } from "react";
import Send from "/icons/send.svg";
import Emoji from "/images/emoji.png";

interface IInput {
  inputVisibled: boolean;
  setInputVisibled: (inputVisibled: boolean) => void;

  emojiVisibled: boolean;
  setEmojiVisibled: (emojiVisibled: boolean) => void;

  handleSend: () => void;
}

const Input = forwardRef(function Input(
  { inputVisibled, setEmojiVisibled, emojiVisibled, handleSend }: IInput,
  ref: Ref<HTMLInputElement>
) {
  if (!inputVisibled) return null;

  return (
    <div
      className="w-full flex items-center gap-[.38rem] h-[2.1875rem] rounded-md px-2"
      style={{
        background: "radial-gradient(1133.06% 111.04% at 100.14% 50%, rgba(0, 0, 0, 0.45) 0%, rgba(0, 0, 0, 0.00) 100%)",
        boxShadow: "inset 0 0 0 .0625rem rgba(255, 255, 255, 0.30)"
      }}
    >
      <input
        ref={ref}
        type="text"
        placeholder="Mensagem aqui..."
        onKeyDown={(e) => e.key === "Enter" && handleSend()}
        className="bg-transparent flex-1 text-[0.8125rem] text-white font-normal placeholder:text-white/80 outline-none botder-none"
      />
      <div className="flex items-center gap-2.5">
        <img
          onClick={() => setEmojiVisibled(!emojiVisibled)}
          src={Emoji}
          className="w-[1.0285rem] h-[1.0285rem]"
          alt="Emoji"
        />
        <svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
          <g clip-path="url(#clip0_34_2074)">
            <path
              d="M15.0019 7.50002L0.182495 1.04065L2.24187 6.87502H6.87499V8.12502H2.24187L0.182495 13.96L15.0019 7.50002Z"
              fill="white"
            />
          </g>
          <defs>
            <clipPath id="clip0_34_2074">
              <rect width="15" height="15" fill="white" />
            </clipPath>
          </defs>
        </svg>
      </div>
    </div>
  );
});

export default Input;
