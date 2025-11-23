require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const connectDB = require('./config/database');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const inspectionRoutes = require('./routes/inspections');
const finishingRoutes = require('./routes/finishing');
const qualityRoutes = require('./routes/quality');
const deliveryRoutes = require('./routes/delivery');
const dashboardRoutes = require('./routes/dashboard');
const toolRoutes = require('./routes/tools');
const toolLifeRoutes = require('./routes/toolLifeTracking');
const toolStockRoutes = require('./routes/toolStock');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/inspections', inspectionRoutes);
app.use('/api/finishing', finishingRoutes);
app.use('/api/quality', qualityRoutes);
app.use('/api/delivery', deliveryRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/tools', toolRoutes);
app.use('/api/tool-life', toolLifeRoutes);
app.use('/api/tool-stock', toolStockRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Connect to MongoDB and create default admin
const User = require('./models/User');

connectDB().then(async () => {
  try {
    const adminExists = await User.findOne({ username: 'admin' });
    if (!adminExists) {
      const admin = new User({
        name: 'Administrator',
        username: 'admin',
        password: 'admin123',
        role: 'Admin'
      });
      await admin.save();
      console.log('✓ Default admin created: admin/admin123');
    }
  } catch (err) {
    console.log('Admin user setup:', err.message);
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;