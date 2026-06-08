"use client";

import Script from "next/script";

export default function KofiWidget() {
  return (
    <Script 
      src="https://storage.ko-fi.com/cdn/scripts/overlay-widget.js" 
      strategy="lazyOnload"
      onLoad={() => {
        // @ts-ignore
        if (typeof kofiWidgetOverlay !== 'undefined') {
          // Prevent duplicates on hot-reload / hydration
          if (!document.querySelector('.floatingchat-container-wrap')) {
            // @ts-ignore
            kofiWidgetOverlay.draw('C3V820LKKR', {
              'type': 'floating-chat',
              'floating-chat.donateButton.text': 'Support me on Ko-fi',
              'floating-chat.donateButton.background-color': '#f57873',
              'floating-chat.donateButton.text-color': '#fff'
            });
          }
        }
      }}
    />
  );
}
