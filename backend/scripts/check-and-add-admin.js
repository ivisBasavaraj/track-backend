require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcryptjs');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

const checkAndAddAdmin = async () => {
  try {
    // First, check existing users table structure by querying it
    const { data: existingUsers, error: queryError } = await supabase
      .from('users')
      .select('*')
      .limit(1);

    if (queryError) {
      console.log('Query error:', queryError.message);
      return;
    }

    console.log('Existing table structure:', existingUsers[0] ? Object.keys(existingUsers[0]) : 'No users found');

    // Try to add admin with minimal fields
    const args = process.argv.slice(2);
    const username = args[1] || 'admin';
    const password = args[2] || 'admin123';
    const hashedPassword = await bcrypt.hash(password, 12);

    const { data, error } = await supabase
      .from('users')
      .insert({
        username,
        password: hashedPassword
      })
      .select();

    if (error) {
      console.error('Insert error:', error.message);
    } else {
      console.log(`Admin '${username}' created successfully`);
    }
  } catch (err) {
    console.error('Error:', err.message);
  }
};

checkAndAddAdmin();