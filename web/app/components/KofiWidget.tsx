"use client";

import Script from "next/script";

export default function KofiWidget() {
  return (
    <Script 
      src="https://storage.ko-fi.com/cdn/widget/Widget_2.js" 
      strategy="lazyOnload"
      onLoad={() => {
        // @ts-ignore
        if (typeof kofiwidget2 !== 'undefined') {
          // @ts-ignore
          kofiwidget2.init('Support me on Ko-fi', '#74E0A4', 'C3V820LKKR');
          // @ts-ignore
          kofiwidget2.draw();
        }
      }}
    />
  );
}
