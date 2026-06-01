async function testItunes(entity) {
  try {
    const url = `https://itunes.apple.com/search?term=radiohead&media=music&entity=${entity}&limit=30&offset=0`;
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    console.log(`Entity: ${entity}, Status: ${res.status}`);
    const body = await res.json();
    console.log(`  Count: ${body.results?.length || 0}`);
  } catch (e) {
    console.error(`  Failed for ${entity}:`, e);
  }
}

async function run() {
  await testItunes('song');
  await testItunes('album');
  await testItunes('musicArtist');
}

run();
