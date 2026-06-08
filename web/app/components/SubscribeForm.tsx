"use client";

import { useState } from "react";
import { createClient } from "@supabase/supabase-js";

export default function SubscribeForm() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [message, setMessage] = useState("");

  const handleSubscribe = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !email.includes("@")) {
      setStatus("error");
      setMessage("Please enter a valid email address.");
      return;
    }

    setStatus("loading");
    setMessage("");

    try {
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
      const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

      if (!supabaseUrl || !supabaseAnonKey) {
        throw new Error("Supabase configuration is missing on the client side.");
      }

      const supabase = createClient(supabaseUrl, supabaseAnonKey);

      const { error } = await supabase
        .from("prelaunch_subscribers")
        .insert([{ email: email.trim().toLowerCase() }]);

      if (error) {
        if (error.code === "23505") { // Unique violation in Postgres
          setStatus("success"); // Act friendly even if they already subscribed
          setMessage("You're already subscribed! Thank you!");
        } else {
          throw error;
        }
      } else {
        setStatus("success");
        setMessage("Awesome! You've successfully subscribed.");
        setEmail("");
      }
    } catch (err: any) {
      console.error("Subscription error:", err);
      setStatus("error");
      setMessage(err.message || "Something went wrong. Please try again.");
    }
  };

  return (
    <div className="lp-subscribe-container">
      {status === "success" ? (
        <div className="lp-subscribe-success">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" style={{ marginRight: '8px', color: 'var(--accent)' }}>
            <polyline points="20 6 9 17 4 12" />
          </svg>
          {message}
        </div>
      ) : (
        <form onSubmit={handleSubscribe} className="lp-subscribe-form">
          <input
            type="email"
            placeholder="Enter your email address"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={status === "loading"}
            className="lp-subscribe-input"
            required
          />
          <button type="submit" disabled={status === "loading"} className="lp-subscribe-btn">
            {status === "loading" ? "Subscribing..." : "Notify Me"}
          </button>
        </form>
      )}
      {status === "error" && (
        <div className="lp-subscribe-error">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" style={{ marginRight: '6px', color: '#ff5c5c' }}>
            <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          {message}
        </div>
      )}
    </div>
  );
}
