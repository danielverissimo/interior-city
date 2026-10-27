import { isEnvBrowser } from "./utils/misc";

import Message from "./components/message";
import { useCallback, useEffect, useRef, useState } from "react";
import clsx from 'clsx'
import { IMessage } from "./interfaces/global";
import Input from "./components/input";
import { listener } from "./hooks/listener";
import { useHistory } from "./hooks/useHistory";
import { fetchNui } from "./utils/fetchNui";
import { debugData } from "./utils/debugData";

import data from "@emoji-mart/data";
import Picker from "@emoji-mart/react";

debugData([
  {
    action: "create:message",
    data: {
      message: "Olá, tudo bem?",
      title: "Teste",
      type: "tip",
      icon: "tip",
    },
  },
  {
    action: "create:message",
    data: {
      message: "Olá, tudo bem?",
      title: "Teste",
      type: "vip",
      icon: "cart",
    },
  },
  {
    action: "create:message",
    data: {
      message: "Olá, tudo bem?",
      type: "box",
      icon: "box",
    },
  },
  {
    action: "create:message",
    data: {
      message: "Olá, tudo bem?",
      title: "Teste",
      type: "relacionamento",
      icon: "finishrelationship",
    },
  },
  {
    action: "create:message",
    data: {
      message: "Olá, tudo bem?",
      title: "Teste",
      type: "",
    },
  },
  {
    action: "create:message",
    data: {
      message: "Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem? Olá, tudo bem?",
      title: "Teste",
      prefixColor: "blue",
      type: "",
    },
  },
  {
    action: "create:message",
    data: {
      message: "ssss?",
      title: "Teste",
      prefixColor: "blue",
      type: "",
    },
  },
  {
    action: 'create:message',
    data: {
      icon: 'staff',
      title: 'AVISO STAFF',
      category: 'STAFF',
      message: 'TESTE',
      color: "#1EF026",
      boxColor: "#1EF026",
      background: 'radial-gradient(42.31% 191.71% at 87.65% 86.92%, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.00) 100%), linear-gradient(90deg, rgba(56, 56, 56, 0.20) 0%, rgba(56, 56, 56, 0.00) 100%), linear-gradient(90deg, rgba(0, 0, 0, 0.80) 0%, rgba(0, 0, 0, 0.60) 100%)'
    }
  },
  {
    action: 'create:message',
    data: {
      icon: 'staff',
      title: 'AVISO STAFF',
      category: 'STAFF',
      message: 'TESTE',
      color: "#1EF026",
      boxColor: "#1EF026",
      background: 'radial-gradient(42.31% 191.71% at 87.65% 86.92%, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.00) 100%), linear-gradient(90deg, rgba(56, 56, 56, 0.20) 0%, rgba(56, 56, 56, 0.00) 100%), linear-gradient(90deg, rgba(0, 0, 0, 0.80) 0%, rgba(0, 0, 0, 0.60) 100%)'
    }
  },
  {
    action: 'create:message',
    data: {
      icon: 'staff',
      title: 'AVISO STAFF',
      category: 'STAFF',
      message: 'TESTE',
      color: "#1EF026",
      boxColor: "#1EF026",
      background: 'radial-gradient(42.31% 191.71% at 87.65% 86.92%, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.00) 100%), linear-gradient(90deg, rgba(56, 56, 56, 0.20) 0%, rgba(56, 56, 56, 0.00) 100%), linear-gradient(90deg, rgba(0, 0, 0, 0.80) 0%, rgba(0, 0, 0, 0.60) 100%)'
    }
  },
  {
    action: 'create:message',
    data: {
      icon: 'staff',
      title: 'AVISO STAFF',
      category: 'STAFF',
      message: 'TESTE',
      color: "#1EF026",
      boxColor: "#1EF026",
      background: 'radial-gradient(42.31% 191.71% at 87.65% 86.92%, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.00) 100%), linear-gradient(90deg, rgba(56, 56, 56, 0.20) 0%, rgba(56, 56, 56, 0.00) 100%), linear-gradient(90deg, rgba(0, 0, 0, 0.80) 0%, rgba(0, 0, 0, 0.60) 100%)'
    }
  },
  {
    action: 'create:message',
    data: {
      icon: 'staff',
      title: 'AVISO STAFF',
      category: 'STAFF',
      message: 'flavio diz: essa mensagem é um teste para ver se quebra o tamanho',
      color: "#1EF026",
      boxColor: "#1EF026",
      background: 'radial-gradient(42.31% 191.71% at 87.65% 86.92%, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.00) 100%), linear-gradient(90deg, rgba(56, 56, 56, 0.20) 0%, rgba(56, 56, 56, 0.00) 100%), linear-gradient(90deg, rgba(0, 0, 0, 0.80) 0%, rgba(0, 0, 0, 0.60) 100%)'
    },
  },
  {
    action: 'create:message',
    data: {
      icon: 'staff',
      title: 'DICA',
      category: 'STAFF',
      message: 'flavio diz: essa mensagem é um teste para ver se quebra o tamanho',
      color: "#37B5F0",
      boxColor: "radial-gradient(85.48% 409.68% at 96.01% -15.75%, rgba(55, 181, 240, 0.55) 0%, rgba(55, 181, 240, 0.00) 100%), radial-gradient(604.06% 271.23% at 1.29% -10.27%, #37B5F0 0%, rgba(55, 181, 240, 0.00) 100%), linear-gradient(158deg, #0E0E0E 14.84%, rgba(14, 14, 14, 0.00) 166.28%)",
      background: 'linear-gradient(0deg, rgba(55, 181, 240, 0.35) 0%, rgba(55, 181, 240, 0.35) 100%), linear-gradient(90deg, rgba(0, 0, 0, 0.75) 0%, rgba(0, 0, 0, 0.56) 100%)'
    },
  },
]);

export default function App() {
  let timeout: any;
  const chat = useRef<HTMLDivElement | null>(null);
  const input = useRef<HTMLInputElement | null>(null);

  const [messages, setMessages] = useState<IMessage[]>([]);

  const [visibled, setVisibled] = useState(isEnvBrowser());
  const [emojiVisibled, setEmojiVisibled] = useState(false);
  const [inputVisibled, setInputVisibled] = useState(isEnvBrowser());

  const { history, historyIndex, setHistory, setHistoryIndex } = useHistory();

  const scrollToBottom = useCallback(() => {
    if (chat.current) {
      chat.current.lastElementChild!.scrollIntoView()
    }
  }, []);

  const handleEmojiSelect = useCallback((emoji: any) => {
    if (input.current) input.current.value += emoji.native
    setEmojiVisibled(false);
  }, []);

  const handleSend = () => {
    if (!input.current) return

    setHistory((prev) => [input.current!.value, ...prev]);
    fetchNui("new:command", { message: input.current.value }, true);

    setHistoryIndex(-1);
    setInputVisibled(false);
    input.current.value = ''
    if (timeout) clearTimeout(timeout);
  };

  listener("create:message", (data) => {
    let message = {
      ...data,
      created_at: new Date(),
    };
    setMessages((messages) => [...messages, message]);
  
    setVisibled(true);
  
    if (timeout) clearTimeout(timeout);
    setTimeout(scrollToBottom, 100);
  });

  listener("clear:messages", () => setMessages([]));

  listener("chat:show", () => {
    if (input.current) input.current.value = ''

    setVisibled(true);
    setInputVisibled(true);

    if (timeout) clearTimeout(timeout);

    scrollToBottom();
    setTimeout(() => {
      input.current?.focus();
    }, 200);

    setHistoryIndex(-1);
  });

  listener("chat:hide", () => {
    setVisibled(false);
    setInputVisibled(false);
  });

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.code === "PageUp") {
        e.preventDefault();
        if (chat.current) {
          chat.current.scrollTop -= chat.current.clientHeight;
        }
      } else if (e.code === "PageDown") {
        e.preventDefault();
        if (chat.current) {
          chat.current.scrollTop += chat.current.clientHeight;
        }
      } else if (e.code === "Escape") {
        e.preventDefault();
        setInputVisibled(false);
        fetchNui("closeChat");
      } else if (e.code === "ArrowDown") {
        e.preventDefault();
        if (historyIndex > 0) {
          if (input.current) input.current.value = history[historyIndex - 1]
          setHistoryIndex(historyIndex - 1);
        } else {
          if (input.current) input.current.value = history[0]
        }
      } else if (e.code === "ArrowUp") {
        e.preventDefault();
        if (historyIndex < history.length - 1) {
          if (input.current) input.current.value = history[historyIndex + 1]
          setHistoryIndex(historyIndex + 1);
        } else {
          if (input.current) input.current.value = history[0]
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [history, historyIndex, setHistory, setHistoryIndex]);

  useEffect(() => {
    timeout = setTimeout(() => {
      if (!inputVisibled) setVisibled(false);
    }, 10 * 1000);

    return () => clearTimeout(timeout);
  }, [messages, inputVisibled, visibled]);

  return (
    <div className={clsx("w-[22.375rem] flex flex-col gap-[.38rem] absolute top-[1.56rem] left-[1.56rem] overflow-visible", !visibled && '!opacity-0')}>
      <div ref={chat} className="overflow-y-auto overflow-x-visible flex flex-col gap-[.31rem] h-[15.625rem] max-h-[15.625rem] w-full rounded-[0.1875rem]" >
        {messages.map((message, index) => (
          <Message key={Number(message.created_at)} {...message} />
        ))}
      </div>
      <Input
        ref={input}
        handleSend={handleSend}
        inputVisibled={inputVisibled}
        emojiVisibled={emojiVisibled}
        setInputVisibled={setInputVisibled}
        setEmojiVisibled={setEmojiVisibled}
      />
      {emojiVisibled && (
        <div className="absolute scale-75 -bottom-[27.5rem] -right-[17rem]">
          <Picker data={data} onEmojiSelect={handleEmojiSelect} />
        </div>
      )}
    </div>
  );
}
