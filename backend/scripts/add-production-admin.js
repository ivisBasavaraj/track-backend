const mongoose = require('mongoose');
const User = require('../models/User');

const PRODUCTION_MONGODB_URI = 'YOUR_RAILWAY_MONGODB_URI_HERE';

const addAdmin = async () => {
  try {
    await mongoose.connect(PRODUCTION_MONGODB_URI);
    console.log('Connected to production database');
    
    const existingAdmin = await User.findOne({ username: 'admin' });
    if (existingAdmin) {
      console.log('Admin already exists');
      mongoose.connection.close();
      return;
    }
    
    const admin = new User({
      name: 'Administrator',
      username: 'admin',
      password: 'admin123',
      role: 'Admin',
      isActive: true
    });
    
    await admin.save();
    console.log('Production admin created successfully');
    console.log('Username: admin');
    console.log('Password: admin123');
    mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
    mongoose.connection.close();
  }
};

addAdmin();
