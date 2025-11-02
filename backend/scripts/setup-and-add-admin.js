require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcryptjs');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

const setupAndAddAdmin = async () => {
  const args = process.argv.slice(2);
  const name = args[0] || 'Administrator';
  const username = args[1] || 'admin';
  const password = args[2] || 'admin123';
  const hashedPassword = await bcrypt.hash(password, 12);

  const { data, error } = await supabase
    .from('users')
    .insert({
      name,
      username,
      password: hashedPassword,
      role: 'Admin',
      isActive: true,
      assignedTask: null,
      completedToday: 0,
      totalAssigned: 0
    })
    .select();

  if (error) {
    console.error('Error:', error.message);
  } else {
    console.log(`Admin '${username}' created successfully`);
  }
};

setupAndAddAdmin();