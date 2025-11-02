const mongoose = require('mongoose');
require('dotenv').config();

const MasterTool = require('../models/MasterTool');
const ToolUsageLog = require('../models/ToolUsageLog');

async function testToolLifeCalculation() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✓ Connected to MongoDB\n');

    // Test 1: Check if master tools exist
    console.log('=== TEST 1: Master Tools ===');
    const masterTools = await MasterTool.find().limit(5);
    console.log(`Found ${masterTools.length} master tools`);
    
    if (masterTools.length > 0) {
      const tool = masterTools[0];
      console.log(`\nSample Tool:`);
      console.log(`  Tool ID: ${tool.tool_id}`);
      console.log(`  Tool Name: ${tool.tool_name}`);
      console.log(`  Tool Life Threshold: ${tool.tool_life_threshold}`);
      console.log(`  Status: ${tool.status}`);
    } else {
      console.log('⚠ No master tools found. Please import master tools first.');
      process.exit(0);
    }

    // Test 2: Check usage logs
    console.log('\n=== TEST 2: Usage Logs ===');
    const usageLogs = await ToolUsageLog.find().sort({ timestamp: -1 }).limit(5);
    console.log(`Found ${usageLogs.length} usage logs`);
    
    if (usageLogs.length > 0) {
      const log = usageLogs[0];
      console.log(`\nLatest Usage Log:`);
      console.log(`  Tool ID: ${log.tool_id}`);
      console.log(`  Tool Name: ${log.tool_name}`);
      console.log(`  Component: ${log.component_id}`);
      console.log(`  No. of Holes: ${log.no_of_holes}`);
      console.log(`  Cutting Length: ${log.cutting_length}`);
      console.log(`  Usage Score: ${log.usage_score}`);
      console.log(`  Cumulative Before: ${log.cumulative_total_before}`);
      console.log(`  Cumulative After: ${log.cumulative_total_after}`);
      console.log(`  Usage %: ${log.usage_percentage.toFixed(2)}%`);
      console.log(`  Remaining Life: ${log.remaining_life}`);
      console.log(`  Alert Type: ${log.alert_type}`);
    }

    // Test 3: Verify calculation logic
    console.log('\n=== TEST 3: Calculation Verification ===');
    if (masterTools.length > 0 && usageLogs.length > 0) {
      const testTool = masterTools[0];
      const testLog = usageLogs.find(log => log.tool_id === testTool.tool_id) || usageLogs[0];
      
      console.log(`\nVerifying calculations for Tool ID ${testLog.tool_id}:`);
      
      // Manual calculation
      const expectedUsageScore = testLog.no_of_holes * testLog.cutting_length;
      const expectedCumulativeAfter = testLog.cumulative_total_before + expectedUsageScore;
      const expectedUsagePercentage = (testLog.cumulative_total_after / testLog.tool_life_threshold) * 100;
      const expectedRemainingLife = Math.max(0, testLog.tool_life_threshold - testLog.cumulative_total_after);
      
      console.log(`  Expected Usage Score: ${expectedUsageScore}`);
      console.log(`  Actual Usage Score: ${testLog.usage_score}`);
      console.log(`  Match: ${expectedUsageScore === testLog.usage_score ? '✓' : '✗'}`);
      
      console.log(`\n  Expected Cumulative After: ${expectedCumulativeAfter}`);
      console.log(`  Actual Cumulative After: ${testLog.cumulative_total_after}`);
      console.log(`  Match: ${expectedCumulativeAfter === testLog.cumulative_total_after ? '✓' : '✗'}`);
      
      console.log(`\n  Expected Usage %: ${expectedUsagePercentage.toFixed(2)}%`);
      console.log(`  Actual Usage %: ${testLog.usage_percentage.toFixed(2)}%`);
      console.log(`  Match: ${Math.abs(expectedUsagePercentage - testLog.usage_percentage) < 0.01 ? '✓' : '✗'}`);
      
      console.log(`\n  Expected Remaining Life: ${expectedRemainingLife}`);
      console.log(`  Actual Remaining Life: ${testLog.remaining_life}`);
      console.log(`  Match: ${expectedRemainingLife === testLog.remaining_life ? '✓' : '✗'}`);
      
      // Alert threshold check
      const warningThreshold = testLog.tool_life_threshold * 0.90;
      console.log(`\n  Tool Life Threshold: ${testLog.tool_life_threshold}`);
      console.log(`  Warning Threshold (90%): ${warningThreshold}`);
      console.log(`  Current Usage: ${testLog.cumulative_total_after}`);
      
      let expectedAlertType = 'NONE';
      if (testLog.cumulative_total_after >= testLog.tool_life_threshold) {
        expectedAlertType = 'CRITICAL';
      } else if (testLog.cumulative_total_after >= warningThreshold) {
        expectedAlertType = 'WARNING';
      }
      
      console.log(`  Expected Alert Type: ${expectedAlertType}`);
      console.log(`  Actual Alert Type: ${testLog.alert_type}`);
      console.log(`  Match: ${expectedAlertType === testLog.alert_type ? '✓' : '✗'}`);
    }

    // Test 4: Summary by tool
    console.log('\n=== TEST 4: Tool Usage Summary ===');
    const toolSummary = await ToolUsageLog.aggregate([
      {
        $group: {
          _id: '$tool_id',
          tool_name: { $first: '$tool_name' },
          total_logs: { $sum: 1 },
          latest_cumulative: { $max: '$cumulative_total_after' },
          latest_threshold: { $max: '$tool_life_threshold' }
        }
      },
      { $sort: { _id: 1 } },
      { $limit: 10 }
    ]);

    console.log(`\nTop 10 Tools by Usage:`);
    toolSummary.forEach(tool => {
      const usagePercent = (tool.latest_cumulative / tool.latest_threshold * 100).toFixed(2);
      console.log(`  Tool ${tool._id} (${tool.tool_name}): ${tool.latest_cumulative}/${tool.latest_threshold} (${usagePercent}%) - ${tool.total_logs} logs`);
    });

    console.log('\n✓ Tool Life Calculation Test Complete!');
    
  } catch (error) {
    console.error('✗ Error:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('\n✓ Disconnected from MongoDB');
  }
}

testToolLifeCalculation();
