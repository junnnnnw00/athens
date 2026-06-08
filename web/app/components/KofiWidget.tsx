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
            kofiWidgetOverlay.draw('nerdyahh_', {
              'type': 'floating-chat',
              'floating-chat.donateButton.text': 'Support me',
              'floating-chat.donateButton.background-color': '#f45d22',
              'floating-chat.donateButton.text-color': '#fff'
            });
          }
        }
      }}
    />
  );
}
