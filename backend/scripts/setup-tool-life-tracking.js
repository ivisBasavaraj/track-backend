require('dotenv').config();
const mongoose = require('mongoose');
const MasterTool = require('../models/MasterTool');

const sampleTools = [
  {
    tool_id: 5,
    tool_name: 'CARBIDE DRILL',
    holder_name: 'ER32 100GPL',
    atc_pocket_no: 'P05',
    tool_room_no: '0',
    tool_life_threshold: 3000,
    status: 'ACTIVE',
    supervisor_email: 'supervisor@company.com'
  },
  {
    tool_id: 10,
    tool_name: 'END MILL',
    holder_name: 'ER32 75GPL',
    atc_pocket_no: 'P10',
    tool_room_no: '1',
    tool_life_threshold: 5000,
    status: 'ACTIVE',
    supervisor_email: 'supervisor@company.com'
  },
  {
    tool_id: 15,
    tool_name: 'FACE MILL',
    holder_name: 'BT40 100GPL',
    atc_pocket_no: 'P15',
    tool_room_no: '2',
    tool_life_threshold: 10000,
    status: 'ACTIVE',
    supervisor_email: 'supervisor@company.com'
  }
];

async function setupToolLifeTracking() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/trackpro');
    console.log('Connected to MongoDB');

    console.log('\nCreating sample master tools...');
    
    for (const tool of sampleTools) {
      const existing = await MasterTool.findOne({ tool_id: tool.tool_id });
      
      if (existing) {
        console.log(`Tool ID ${tool.tool_id} already exists, skipping...`);
      } else {
        await MasterTool.create(tool);
        console.log(`✓ Created tool: ${tool.tool_name} (ID: ${tool.tool_id})`);
      }
    }

    console.log('\n✓ Tool Life Tracking setup completed successfully!');
    console.log('\nSample tools created:');
    sampleTools.forEach(tool => {
      console.log(`  - Tool ID ${tool.tool_id}: ${tool.tool_name} (Threshold: ${tool.tool_life_threshold})`);
    });

    console.log('\nNext steps:');
    console.log('1. Start recording tool usage via POST /api/tool-life/usage/record');
    console.log('2. View tool status via GET /api/tool-life/:toolId/status');
    console.log('3. Check alerts via GET /api/tool-life/alerts/active');
    console.log('4. Access Flutter dashboard to monitor tools visually');

    process.exit(0);
  } catch (error) {
    console.error('Error setting up tool life tracking:', error);
    process.exit(1);
  }
}

setupToolLifeTracking();
