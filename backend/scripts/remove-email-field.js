const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

async function removeEmailField() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/trackpro');
    console.log('Connected to MongoDB');

    // Remove email field from all user documents
    console.log('Removing email field from all users...');
    const result = await User.updateMany(
      {}, // Match all documents
      { $unset: { email: 1 } } // Remove the email field
    );

    console.log(`Email field removed from ${result.modifiedCount} user documents`);

    // Verify the changes
    const userCount = await User.countDocuments({});
    console.log(`Total users in database: ${userCount}`);

    console.log('Migration completed successfully!');

  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

removeEmailField();