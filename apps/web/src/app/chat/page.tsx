"use client";

import { FormEvent, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { getStoredUser, sendChat } from "@/lib/api";

interface Message {
  role: "user" | "assistant";
  content: string;
}

export default function ChatPage() {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: "assistant",
      content:
        "Hello! I'm the AI receptionist at CityCare General Hospital. How can I help you today? I can help with appointments, finding doctors, hospital info, and more.",
    },
  ]);
  const [input, setInput] = useState("");
  const [sessionId, setSessionId] = useState<string>();
  const [loading, setLoading] = useState(false);
  const [patientId, setPatientId] = useState<number>(1);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const user = getStoredUser();
    if (user?.role === "patient") {
      setPatientId(user.id);
    }
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!input.trim() || loading) return;

    const userMessage = input.trim();
    setInput("");
    setMessages((prev) => [...prev, { role: "user", content: userMessage }]);
    setLoading(true);

    try {
      const response = await sendChat(userMessage, sessionId, patientId);
      setSessionId(response.session_id);
      setMessages((prev) => [...prev, { role: "assistant", content: response.message }]);
    } catch {
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: "Sorry, I'm having trouble connecting. Please try again or call (555) 123-4567.",
        },
      ]);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex h-screen flex-col bg-slate-50">
      <header className="border-b border-slate-200 bg-white px-6 py-4">
        <div className="mx-auto flex max-w-3xl items-center justify-between">
          <div>
            <Link href="/" className="text-sm text-teal-600 hover:underline">
              ← Home
            </Link>
            <h1 className="text-lg font-semibold">AI Receptionist</h1>
          </div>
          <div className="text-right text-sm text-slate-500">
            <label className="mr-2">Patient ID:</label>
            <input
              type="number"
              value={patientId}
              onChange={(e) => setPatientId(Number(e.target.value))}
              className="w-16 rounded border border-slate-300 px-2 py-1 text-center"
              min={1}
            />
          </div>
        </div>
      </header>

      <div className="mx-auto flex w-full max-w-3xl flex-1 flex-col overflow-hidden px-4 py-4">
        <div className="flex-1 space-y-4 overflow-y-auto rounded-xl border border-slate-200 bg-white p-4">
          {messages.map((msg, i) => (
            <div
              key={i}
              className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
            >
              <div
                className={`max-w-[80%] rounded-2xl px-4 py-3 text-sm whitespace-pre-wrap ${
                  msg.role === "user"
                    ? "bg-teal-600 text-white"
                    : "bg-slate-100 text-slate-800"
                }`}
              >
                {msg.content}
              </div>
            </div>
          ))}
          {loading && (
            <div className="flex justify-start">
              <div className="rounded-2xl bg-slate-100 px-4 py-3 text-sm text-slate-500">
                Typing...
              </div>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        <form onSubmit={handleSubmit} className="mt-4 flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Ask about appointments, doctors, hours..."
            className="flex-1 rounded-xl border border-slate-300 px-4 py-3 focus:border-teal-500 focus:outline-none focus:ring-1 focus:ring-teal-500"
            disabled={loading}
          />
          <button
            type="submit"
            disabled={loading || !input.trim()}
            className="rounded-xl bg-teal-600 px-6 py-3 font-medium text-white hover:bg-teal-700 disabled:opacity-50"
          >
            Send
          </button>
        </form>
      </div>
    </div>
  );
}
