import { IMessage } from "../interfaces/global";

export default function Message({ icon, message, title, category, boxColor, background, color, created_at }: IMessage) {
  return (
    <div
      className="animate-fade-right w-full py-3 px-2.5 flex item-start gap-2.5 rounded-md"
      style={{
        boxShadow: `inset 0 0 0 .05rem  ${color ? color : "rgba(255, 255, 255, 0.30)"}`,
        background: background
          ? background
          : "radial-gradient(1133.06% 111.04% at 100.14% 50%, rgba(0, 0, 0, 0.45) 0%, rgba(0, 0, 0, 0.00) 100%)",
      }}
    >
      <img src={`./icons/${icon || "default"}.svg`} alt={icon || "default"} className="w-[1.75rem] h-[1.625rem]" />
      <div className="flex-1">
        <div className="flex items-center justify-between">
          <p
            className="text-white text-xs font-bold uppercase"
            style={{ letterSpacing: "0.0075rem" }}
            dangerouslySetInnerHTML={{ __html: title || "Chat" }}
          />
          <p className="text-white/50 text-[0.5625rem] font-normal">
            {created_at?.toLocaleTimeString([], {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </p>
        </div>
        <span>
          <p className="text-white/70 text-[0.6875rem] font-normal" dangerouslySetInnerHTML={{ __html: message }}></p>
        </span>
      </div>
    </div>
  );
}
