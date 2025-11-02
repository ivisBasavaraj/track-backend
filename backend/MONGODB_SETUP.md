# TrackPro MongoDB Setup Guide

This project has been converted from Supabase to MongoDB. Follow these steps to set up and run the application.

## Prerequisites

1. **MongoDB**: Install MongoDB Community Server from [https://www.mongodb.com/try/download/community](https://www.mongodb.com/try/download/community)
2. **Node.js**: Version 14 or higher

## Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Configuration

The `.env` file has been updated with MongoDB configuration:

```env
MONGODB_URI=mongodb://localhost:27017/trackpro
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRE=7d
PORT=3001
```

**Important**: Change the `JWT_SECRET` to a secure random string in production.

### 3. Start MongoDB

Make sure MongoDB is running on your system:

- **Windows**: MongoDB should start automatically as a service after installation
- **macOS/Linux**: Run `mongod` or start the MongoDB service

### 4. Create Admin User

Run the script to create an initial admin user:

```bash
node scripts/add-admin-mongodb.js
```

This will create an admin user with:
- Username: `admin`
- Password: `admin123`

### 5. Start the Server

```bash
npm start
# or for development
npm run dev
```

The server will start on port 3001 (or the port specified in your .env file).

## Database Schema

The application uses the following MongoDB collections:

- **users**: User accounts and authentication
- **inspections**: Incoming inspection records
- **finishing**: Finishing process records
- **qualitycontrols**: Quality control inspection records
- **deliveries**: Delivery management records
- **toollists**: Tool list uploads and data

## API Endpoints

All previous API endpoints remain the same:

- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration (Admin only)
- `GET /api/auth/profile` - Get user profile
- `GET /api/users` - Get all users
- `POST /api/inspections` - Create inspection record
- `POST /api/finishing` - Create finishing record
- `POST /api/quality` - Create quality control record
- `POST /api/delivery` - Create delivery record
- `POST /api/tools/upload` - Upload tool list
- `GET /api/dashboard/admin` - Admin dashboard data
- `GET /api/dashboard/supervisor` - Supervisor dashboard data
- `GET /api/dashboard/user` - User dashboard data

## Changes Made

### Removed Supabase Dependencies
- Removed `@supabase/supabase-js` package
- Removed `config/supabase.js`
- Removed entire `supabase-backend` folder

### Added MongoDB Support
- Added `mongoose` package
- Created `config/database.js` for MongoDB connection
- Updated all route files to use Mongoose instead of Supabase
- Updated middleware to work with MongoDB ObjectIds

### Model Updates
All Mongoose models were already present and compatible:
- User model with password hashing
- Inspection model with timer events
- Finishing model with tool tracking
- QualityControl model with automatic tolerance checking
- Delivery model with status tracking
- ToolList model for Excel uploads

## Troubleshooting

### MongoDB Connection Issues
1. Ensure MongoDB is running: `mongod --version`
2. Check if the database URL is correct in `.env`
3. Verify MongoDB is listening on port 27017

### Authentication Issues
1. Make sure JWT_SECRET is set in `.env`
2. Verify admin user was created successfully
3. Check password hashing in User model

### API Issues
1. All routes now use MongoDB ObjectIds instead of Supabase UUIDs
2. Field names have been converted from snake_case to camelCase
3. Population queries replace Supabase joins

## Production Deployment

For production deployment:

1. Use MongoDB Atlas or a dedicated MongoDB server
2. Update `MONGODB_URI` to point to your production database
3. Set a strong `JWT_SECRET`
4. Enable MongoDB authentication
5. Use environment variables for all sensitive configuration

## Migration Notes

- All data will need to be migrated from Supabase to MongoDB
- User IDs have changed from UUIDs to MongoDB ObjectIds
- Some field names have been converted to camelCase
- All functionality remains the same from the frontend perspective