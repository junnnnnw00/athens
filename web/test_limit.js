const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../app/config/app_config.json'), 'utf8'));

const supabaseUrl = config.SUPABASE_URL;
const supabaseAnonKey = config.SUPABASE_PUBLISHABLE_KEY;

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function run() {
  try {
    const res = await supabase.functions.invoke('spotify-app-token');
    const token = res.data.access_token;
    console.log('Got Spotify app token.');

    // Query 1: type=track, limit=30
    console.log('Querying type=track, limit=30...');
    const res30 = await fetch('https://api.spotify.com/v1/search?q=radiohead&type=track&limit=30', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    console.log('Limit 30 status:', res30.status);
    const body30 = await res30.json();
    if (res30.status !== 200) {
      console.log('Limit 30 error:', body30);
    } else {
      console.log('Limit 30 tracks:', body30.tracks?.items?.length || 0);
    }

    // Query 2: type=track, limit=10
    console.log('Querying type=track, limit=10...');
    const res10 = await fetch('https://api.spotify.com/v1/search?q=radiohead&type=track&limit=10', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    console.log('Limit 10 status:', res10.status);
    const body10 = await res10.json();
    if (res10.status !== 200) {
      console.log('Limit 10 error:', body10);
    } else {
      console.log('Limit 10 tracks:', body10.tracks?.items?.length || 0);
    }

  } catch (e) {
    console.error('Failed:', e);
  }
}

run();
