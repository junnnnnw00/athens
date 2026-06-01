'use client';

import { useEffect } from 'react';

export default function AuthRedirectHandler() {
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const search = window.location.search;
      const hash = window.location.hash;

      // Check if the URL contains auth parameters (e.g. from Supabase signup confirmation)
      const hasCode = search.includes('code=');
      const hasAccessToken = hash.includes('access_token=');
      const hasError = search.includes('error=') || hash.includes('error=');

      if (hasCode || hasAccessToken || hasError) {
        // Redirect to the Flutter web app with the same parameters
        window.location.replace(`/app/${search}${hash}`);
      }
    }
  }, []);

  return null;
}
