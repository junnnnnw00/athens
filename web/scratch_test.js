const { createClient } = require('@supabase/supabase-js');

// Read from config file
const fs = require('fs');
const path = require('path');
const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../app/config/app_config.json'), 'utf8'));

const supabaseUrl = config.SUPABASE_URL;
const supabaseAnonKey = config.SUPABASE_PUBLISHABLE_KEY;

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function run() {
  console.log('Querying public_profiles table...');
  const { data, error } = await supabase
    .from('public_profiles')
    .select('*');
  
  if (error) {
    console.error('Error fetching public_profiles:', error);
  } else {
    console.log('Profiles found:', data.length);
    data.forEach(p => {
      console.log('User handle:', p.handle);
      const itemsTags = p.top_items.slice(0, 10).map(i => ({
        title: i.title,
        tags: i.tags
      }));
      console.log(JSON.stringify(itemsTags, null, 2));
    });
  }
}

run();
