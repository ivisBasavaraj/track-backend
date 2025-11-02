require('dotenv').config();
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');
const MasterTool = require('../models/MasterTool');

const DEFAULT_TOOL_LIFE = 5000; // Default threshold when N/A

async function importMasterTools() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/trackpro');
    console.log('Connected to MongoDB\n');

    const csvPath = path.join(__dirname, '../../full_tool_list.csv');
    console.log(`Reading CSV from: ${csvPath}`);
    
    const csvContent = fs.readFileSync(csvPath, 'utf-8');
    const records = parse(csvContent, {
      columns: true,
      skip_empty_lines: true,
      trim: true
    });

    console.log(`Found ${records.length} tools in CSV\n`);

    let imported = 0;
    let skipped = 0;
    let updated = 0;

    for (const record of records) {
      const toolName = record['TOOL NAME'];
      const slNo = parseInt(record['SL.NO']);
      
      // Skip empty tools
      if (!toolName || toolName === 'N/A' || toolName.trim() === '') {
        skipped++;
        continue;
      }

      const toolLifeRaw = record['TOOL LIFE TIME'];
      const toolLifeThreshold = (toolLifeRaw && toolLifeRaw !== 'N/A') 
        ? parseInt(toolLifeRaw) 
        : DEFAULT_TOOL_LIFE;

      const toolData = {
        tool_id: slNo,
        tool_name: toolName,
        holder_name: record['HOLDER NAME'] || '',
        atc_pocket_no: record['ATC POCKET-NO'] || '',
        tool_room_no: '0',
        tool_life_threshold: toolLifeThreshold,
        status: 'ACTIVE',
        supervisor_email: process.env.SUPERVISOR_EMAIL || ''
      };

      const existing = await MasterTool.findOne({ tool_id: slNo });
      
      if (existing) {
        await MasterTool.updateOne({ tool_id: slNo }, { $set: toolData });
        console.log(`✓ Updated: Tool ${slNo} - ${toolName} (Threshold: ${toolLifeThreshold})`);
        updated++;
      } else {
        await MasterTool.create(toolData);
        console.log(`✓ Imported: Tool ${slNo} - ${toolName} (Threshold: ${toolLifeThreshold})`);
        imported++;
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('Import Summary:');
    console.log(`  Imported: ${imported} tools`);
    console.log(`  Updated: ${updated} tools`);
    console.log(`  Skipped: ${skipped} empty entries`);
    console.log(`  Total: ${imported + updated} active tools`);
    console.log('='.repeat(60));
    
    console.log('\nNote: All tools imported with default threshold of', DEFAULT_TOOL_LIFE);
    console.log('You can update individual thresholds via API:\n');
    console.log('  PATCH /api/tool-life/master/:toolId');
    console.log('  { "tool_life_threshold": 3000 }\n');

    process.exit(0);
  } catch (error) {
    console.error('Error importing tools:', error);
    process.exit(1);
  }
}

importMasterTools();
