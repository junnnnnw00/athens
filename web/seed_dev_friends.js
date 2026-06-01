const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

// 1. Load dev configurations
const configPath = path.join(__dirname, '..', 'app', 'config', 'app_config_dev.json');
if (!fs.existsSync(configPath)) {
  console.error(`❌ Cannot find config file at: ${configPath}`);
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const supabaseUrl = config.SUPABASE_URL;
const supabaseAnonKey = config.SUPABASE_PUBLISHABLE_KEY;

console.log(`🔗 Connecting to Supabase dev instance: ${supabaseUrl}`);
const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: { persistSession: false }
});

// 2. Define items (songs/albums) to seed
const testItems = [
  {
    source: 'seed',
    source_id: 'loveless',
    kind: 'album',
    title: 'Loveless',
    primary_artist: 'My Bloody Valentine',
    tags: [
      { name: 'shoegaze', source: 'genre' },
      { name: 'noise pop', source: 'genre' },
      { name: 'dreamy', source: 'mood' }
    ]
  },
  {
    source: 'seed',
    source_id: 'souvlaki',
    kind: 'album',
    title: 'Souvlaki',
    primary_artist: 'Slowdive',
    tags: [
      { name: 'shoegaze', source: 'genre' },
      { name: 'dream pop', source: 'genre' },
      { name: 'dreamy', source: 'mood' }
    ]
  },
  {
    source: 'seed',
    source_id: 'heaven',
    kind: 'album',
    title: 'Heaven or Las Vegas',
    primary_artist: 'Cocteau Twins',
    tags: [
      { name: 'dream pop', source: 'genre' },
      { name: 'dreamy', source: 'mood' }
    ]
  },
  {
    source: 'seed',
    source_id: 'inrainbows',
    kind: 'album',
    title: 'In Rainbows',
    primary_artist: 'Radiohead',
    tags: [
      { name: 'art rock', source: 'genre' },
      { name: 'alternative', source: 'genre' },
      { name: 'melancholic', source: 'mood' }
    ]
  },
  {
    source: 'seed',
    source_id: 'vivid',
    kind: 'album',
    title: 'VIVID',
    primary_artist: 'ADOY',
    tags: [
      { name: 'synth-pop', source: 'genre' },
      { name: 'indie pop', source: 'genre' },
      { name: 'dreamy', source: 'mood' }
    ]
  }
];

// 3. Define users and their ratings (Elos translate to 0-10 scores)
const testUsers = [
  {
    email: 'alice@example.com',
    password: 'password123',
    handle: 'alice',
    display_name: 'Alice (Shoegaze Fan)',
    is_premium: true,
    ratings: {
      'loveless': 1300,   // ~9.0 score
      'souvlaki': 1250,   // ~8.5 score
      'heaven': 1100,     // ~6.5 score
      'inrainbows': 1000, // ~5.0 score
      'vivid': 800        // ~1.5 score
    }
  },
  {
    email: 'bob@example.com',
    password: 'password123',
    handle: 'bob',
    display_name: 'Bob (Indie Pop Fan)',
    is_premium: false,
    ratings: {
      'loveless': 800,     // ~1.5 score
      'souvlaki': 900,     // ~2.5 score
      'heaven': 1050,      // ~5.8 score
      'inrainbows': 1250,  // ~8.5 score
      'vivid': 1350        // ~9.5 score
    }
  },
  {
    email: 'charlie@example.com',
    password: 'password123',
    handle: 'charlie',
    display_name: 'Charlie (Balanced Listener)',
    is_premium: true,
    ratings: {
      'loveless': 1150,   // ~7.3 score
      'souvlaki': 1100,   // ~6.5 score
      'heaven': 1050,     // ~5.8 score
      'inrainbows': 1100, // ~6.5 score
      'vivid': 1050       // ~5.8 score
    }
  }
];

async function seed() {
  try {
    const itemUuidMap = {};
    let catalogSeeded = false;

    console.log('\n👤 1. Provisioning test users...');
    for (const u of testUsers) {
      console.log(`\nProcessing user: ${u.email}`);
      
      // Step A: SignUp or Login
      let session;
      const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
        email: u.email,
        password: u.password
      });

      if (signUpError) {
        if (signUpError.message.includes('already registered')) {
          console.log(`   User already registered, logging in...`);
          const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
            email: u.email,
            password: u.password
          });
          if (signInError) throw signInError;
          session = signInData.session;
        } else {
          throw signUpError;
        }
      } else {
        session = signUpData.session;
      }

      const userId = session.user.id;
      const userClient = createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          persistSession: false,
          autoRefreshToken: false
        },
        global: {
          headers: {
            Authorization: `Bearer ${session.access_token}`
          }
        }
      });

      // Step B: Seed catalog items using the first authenticated user
      if (!catalogSeeded) {
        console.log('📦 Seeding shared catalog items under authenticated user session...');
        const dbItems = [];
        for (const item of testItems) {
          const { data, error } = await userClient
            .from('items')
            .upsert(item, { onConflict: 'source,source_id' })
            .select();

          if (error) {
            console.error(`⚠️ Failed to seed item "${item.title}":`, error.message);
            throw error;
          }
          dbItems.push(data[0]);
        }
        console.log(`✅ Seeded ${dbItems.length} catalog items.`);

        // Map source_id to database uuid
        dbItems.forEach(i => {
          itemUuidMap[i.source_id] = i.id;
        });
        catalogSeeded = true;
      }

      // Step C: Update Profile
      console.log(`   Updating profile to public (handle: @${u.handle})...`);
      const { error: profileError } = await userClient
        .from('profiles')
        .update({
          handle: u.handle,
          display_name: u.display_name,
          is_public: true,
          is_premium: u.is_premium
        })
        .eq('id', userId);

      if (profileError) {
        console.error(`   ⚠️ Profile update failed:`, profileError.message);
        throw profileError;
      }

      // Step D: Seed Ratings
      console.log(`   Seeding ratings...`);
      for (const [sourceId, elo] of Object.entries(u.ratings)) {
        const itemId = itemUuidMap[sourceId];
        const { error: ratingError } = await userClient
          .from('ratings')
          .upsert({
            user_id: userId,
            item_id: itemId,
            elo: elo,
            comparisons: 10
          }, { onConflict: 'user_id,item_id' });

        if (ratingError) {
          console.error(`   ⚠️ Rating insert failed for ${sourceId}:`, ratingError.message);
          throw ratingError;
        }
      }
      console.log(`   ✅ User @${u.handle} seeded successfully!`);
    }

    console.log('\n🎉 ALL TEST USERS SEEDED SUCCESSFULLY!');
    console.log('You can now search for any of these handles in your app under the Friends tab:');
    console.log(' - @alice    (Alice (Shoegaze Fan))');
    console.log(' - @bob      (Bob (Indie Pop Fan))');
    console.log(' - @charlie  (Charlie (Balanced Listener))');
  } catch (err) {
    console.error('\n❌ Seeding failed with error:', err);
  }
}

seed();
