const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

const addCustomAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    // Customize these values
    const adminData = {
      name: 'New Admin',
      username: 'newadmin',
      password: 'password123',
      role: 'Admin',
      isActive: true
    };
    
    const existingUser = await User.findOne({ username: adminData.username });
    if (existingUser) {
      console.log(`User with username '${adminData.username}' already exists`);
      mongoose.connection.close();
      return;
    }
    
    const admin = new User(adminData);
    await admin.save();
    console.log('Admin created successfully:');
    console.log(`Username: ${adminData.username}`);
    console.log(`Name: ${adminData.name}`);
    mongoose.connection.close();
  } catch (error) {
    console.error('Error creating admin:', error);
    mongoose.connection.close();
  }
};

addCustomAdmin();
