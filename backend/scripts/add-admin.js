const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

const addAdmin = async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  
  const admin = new User({
    name: 'Administrator',
    username: 'admin',
    password: 'admin123',
    role: 'Admin',
    isActive: true
  });
  
  await admin.save();
  console.log('Admin created successfully');
  mongoose.connection.close();
};

addAdmin().catch(console.error);