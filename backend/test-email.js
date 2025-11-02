require('dotenv').config();
const { sendToolLifeAlert } = require('./services/emailService');

// Test email notification
const testEmail = async () => {
  console.log('Testing email notification...');
  console.log('EMAIL_USER:', process.env.EMAIL_USER ? 'Configured' : 'NOT CONFIGURED');
  
  if (!process.env.EMAIL_USER) {
    console.log('\n❌ Email not configured!');
    console.log('Please add to .env file:');
    console.log('EMAIL_HOST=smtp.gmail.com');
    console.log('EMAIL_PORT=587');
    console.log('EMAIL_USER=your-email@gmail.com');
    console.log('EMAIL_PASSWORD=your-app-password');
    return;
  }

  const result = await sendToolLifeAlert(process.env.EMAIL_USER, {
    tool_id: 1,
    tool_name: 'TEST TOOL - 125 ROUGHING FACEMILL',
    cumulative_usage: 9500,
    threshold: 10000,
    usage_percentage: 95,
    remaining_life: 500,
    components: ['COMP-001', 'COMP-002'],
    alert_type: 'WARNING',
    alert_severity: 'WARNING'
  });

  if (result.success) {
    console.log('\n✅ Email sent successfully!');
    console.log('Check your inbox:', process.env.EMAIL_USER);
  } else {
    console.log('\n❌ Email failed:', result.error);
  }
};

testEmail();
