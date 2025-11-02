-- Create users table matching MongoDB schema
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  username VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'User' CHECK (role IN ('Admin', 'Supervisor', 'User')),
  "isActive" BOOLEAN DEFAULT true,
  "assignedTask" VARCHAR(100) CHECK ("assignedTask" IN ('Incoming Inspection', 'Finishing', 'Quality Control', 'Delivery')),
  "completedToday" INTEGER DEFAULT 0,
  "totalAssigned" INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);