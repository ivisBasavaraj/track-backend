require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    const admin = new User({
      name: 'Administrator',
      username: 'admin',
      password: 'admin123',
      role: 'Admin'
    });
    await admin.save();
    console.log('Admin created: admin/admin123');
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });