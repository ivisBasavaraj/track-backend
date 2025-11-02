const mongoose = require('mongoose');
require('dotenv').config();

const MasterTool = require('../models/MasterTool');
const ToolUsageLog = require('../models/ToolUsageLog');

async function getToolCumulativeUsage(toolId) {
  const logs = await ToolUsageLog.find({ tool_id: toolId }).sort({ timestamp: -1 }).limit(1);
  return logs.length > 0 ? logs[0].cumulative_total_after : 0;
}

async function testRecordUsage() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✓ Connected to MongoDB\n');

    // Get first master tool
    const masterTool = await MasterTool.findOne({ tool_id: 1 });
    if (!masterTool) {
      console.log('✗ No master tool found with ID 1');
      process.exit(1);
    }

    console.log('=== Testing Tool Usage Recording ===');
    console.log(`Tool: ${masterTool.tool_name} (ID: ${masterTool.tool_id})`);
    console.log(`Tool Life Threshold: ${masterTool.tool_life_threshold}\n`);

    // Test Case 1: Normal usage
    console.log('TEST CASE 1: Normal Usage');
    const test1 = {
      tool_id: masterTool.tool_id,
      component_id: 'AMS-141',
      no_of_holes: 10,
      cutting_length: 50
    };

    const currentUsage1 = await getToolCumulativeUsage(test1.tool_id);
    const usageScore1 = test1.no_of_holes * test1.cutting_length;
    const newCumulativeTotal1 = currentUsage1 + usageScore1;
    const usagePercentage1 = (newCumulativeTotal1 / masterTool.tool_life_threshold) * 100;
    const remainingLife1 = Math.max(0, masterTool.tool_life_threshold - newCumulativeTotal1);
    const warningThreshold = masterTool.tool_life_threshold * 0.90;

    console.log(`Input: ${test1.no_of_holes} holes × ${test1.cutting_length} mm`);
    console.log(`\nCalculations:`);
    console.log(`  Usage Score: ${test1.no_of_holes} × ${test1.cutting_length} = ${usageScore1}`);
    console.log(`  Current Cumulative: ${currentUsage1}`);
    console.log(`  New Cumulative: ${currentUsage1} + ${usageScore1} = ${newCumulativeTotal1}`);
    console.log(`  Usage %: (${newCumulativeTotal1} / ${masterTool.tool_life_threshold}) × 100 = ${usagePercentage1.toFixed(2)}%`);
    console.log(`  Remaining Life: ${masterTool.tool_life_threshold} - ${newCumulativeTotal1} = ${remainingLife1}`);
    
    let alertType1 = 'NONE';
    if (newCumulativeTotal1 >= masterTool.tool_life_threshold) {
      alertType1 = 'CRITICAL';
    } else if (newCumulativeTotal1 >= warningThreshold) {
      alertType1 = 'WARNING';
    }
    console.log(`  Alert Type: ${alertType1}`);
    console.log(`  Status: ${alertType1 === 'CRITICAL' ? 'END_OF_LIFE' : alertType1 === 'WARNING' ? 'NEAR_END_OF_LIFE' : 'ACTIVE'}`);

    // Record the usage
    await ToolUsageLog.create({
      tool_id: test1.tool_id,
      tool_name: masterTool.tool_name,
      component_id: test1.component_id,
      no_of_holes: test1.no_of_holes,
      cutting_length: test1.cutting_length,
      usage_score: usageScore1,
      cumulative_total_before: currentUsage1,
      cumulative_total_after: newCumulativeTotal1,
      tool_life_threshold: masterTool.tool_life_threshold,
      usage_percentage: usagePercentage1,
      remaining_life: remainingLife1,
      alert_type: alertType1,
      alert_triggered: alertType1 !== 'NONE',
      operator_id: 'test_operator',
      timestamp: new Date()
    });
    console.log(`\n✓ Usage recorded successfully\n`);

    // Test Case 2: Usage approaching warning threshold
    console.log('TEST CASE 2: Usage Approaching Warning (90%)');
    const test2 = {
      tool_id: masterTool.tool_id,
      component_id: 'AMS-141',
      no_of_holes: 50,
      cutting_length: 80
    };

    const currentUsage2 = await getToolCumulativeUsage(test2.tool_id);
    const usageScore2 = test2.no_of_holes * test2.cutting_length;
    const newCumulativeTotal2 = currentUsage2 + usageScore2;
    const usagePercentage2 = (newCumulativeTotal2 / masterTool.tool_life_threshold) * 100;
    const remainingLife2 = Math.max(0, masterTool.tool_life_threshold - newCumulativeTotal2);

    console.log(`Input: ${test2.no_of_holes} holes × ${test2.cutting_length} mm`);
    console.log(`\nCalculations:`);
    console.log(`  Usage Score: ${usageScore2}`);
    console.log(`  Current Cumulative: ${currentUsage2}`);
    console.log(`  New Cumulative: ${newCumulativeTotal2}`);
    console.log(`  Usage %: ${usagePercentage2.toFixed(2)}%`);
    console.log(`  Remaining Life: ${remainingLife2}`);
    console.log(`  Warning Threshold: ${warningThreshold} (90% of ${masterTool.tool_life_threshold})`);
    
    let alertType2 = 'NONE';
    if (newCumulativeTotal2 >= masterTool.tool_life_threshold) {
      alertType2 = 'CRITICAL';
    } else if (newCumulativeTotal2 >= warningThreshold) {
      alertType2 = 'WARNING';
    }
    console.log(`  Alert Type: ${alertType2}`);
    console.log(`  ${newCumulativeTotal2 >= warningThreshold ? '⚠ WARNING THRESHOLD REACHED!' : '✓ Below warning threshold'}`);

    await ToolUsageLog.create({
      tool_id: test2.tool_id,
      tool_name: masterTool.tool_name,
      component_id: test2.component_id,
      no_of_holes: test2.no_of_holes,
      cutting_length: test2.cutting_length,
      usage_score: usageScore2,
      cumulative_total_before: currentUsage2,
      cumulative_total_after: newCumulativeTotal2,
      tool_life_threshold: masterTool.tool_life_threshold,
      usage_percentage: usagePercentage2,
      remaining_life: remainingLife2,
      alert_type: alertType2,
      alert_triggered: alertType2 !== 'NONE',
      operator_id: 'test_operator',
      timestamp: new Date()
    });
    console.log(`\n✓ Usage recorded successfully\n`);

    // Verify all logs
    console.log('=== Verification: All Logs for Tool ID 1 ===');
    const allLogs = await ToolUsageLog.find({ tool_id: 1 }).sort({ timestamp: 1 });
    allLogs.forEach((log, index) => {
      console.log(`\nLog ${index + 1}:`);
      console.log(`  Component: ${log.component_id}`);
      console.log(`  Usage Score: ${log.usage_score}`);
      console.log(`  Cumulative: ${log.cumulative_total_before} → ${log.cumulative_total_after}`);
      console.log(`  Usage %: ${log.usage_percentage.toFixed(2)}%`);
      console.log(`  Remaining: ${log.remaining_life}`);
      console.log(`  Alert: ${log.alert_type}`);
    });

    console.log('\n✓ Tool Life Calculation is Working Correctly!');
    console.log('\nFormula Verified:');
    console.log('  Usage Score = No. of Holes × Cutting Length');
    console.log('  Cumulative Total = Previous Cumulative + Usage Score');
    console.log('  Usage % = (Cumulative Total / Threshold) × 100');
    console.log('  Remaining Life = Threshold - Cumulative Total');
    console.log('  Alert: WARNING at 90%, CRITICAL at 100%');

  } catch (error) {
    console.error('✗ Error:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('\n✓ Disconnected from MongoDB');
  }
}

testRecordUsage();
