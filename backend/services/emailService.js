const nodemailer = require('nodemailer');

const createTransporter = () => {
  return nodemailer.createTransporter({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: process.env.EMAIL_PORT || 587,
    secure: false,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD
    }
  });
};

const sendToolLifeAlert = async (supervisorEmail, alertData) => {
  try {
    const transporter = createTransporter();
    
    const { tool_id, tool_name, cumulative_usage, threshold, usage_percentage, remaining_life, components, alert_type } = alertData;
    
    const isCritical = alert_type === 'CRITICAL';
    const subject = isCritical 
      ? `🚨 CRITICAL: Tool ${tool_id} - ${tool_name} Requires Immediate Replacement`
      : `⚠️ WARNING: Tool ${tool_id} - ${tool_name} Nearing End of Life`;
    
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: ${isCritical ? '#dc3545' : '#ff9800'}; color: white; padding: 20px; border-radius: 5px 5px 0 0; }
          .content { background: #f9f9f9; padding: 20px; border: 1px solid #ddd; }
          .alert-box { background: ${isCritical ? '#fff5f5' : '#fff8e1'}; border-left: 4px solid ${isCritical ? '#dc3545' : '#ff9800'}; padding: 15px; margin: 15px 0; }
          .details { background: white; padding: 15px; border-radius: 5px; margin: 15px 0; }
          .detail-row { padding: 8px 0; border-bottom: 1px solid #eee; }
          .progress-bar { background: #e0e0e0; height: 30px; border-radius: 15px; overflow: hidden; margin: 10px 0; }
          .progress-fill { background: ${isCritical ? '#dc3545' : '#ff9800'}; height: 100%; text-align: center; color: white; font-weight: bold; line-height: 30px; }
          .footer { background: #333; color: white; padding: 15px; text-align: center; border-radius: 0 0 5px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 style="margin: 0;">${isCritical ? '🚨 CRITICAL ALERT' : '⚠️ WARNING ALERT'}</h1>
            <p style="margin: 5px 0 0 0;">Tool Life Management System</p>
          </div>
          <div class="content">
            <div class="alert-box">
              <h2 style="margin-top: 0;">${isCritical ? 'Immediate Action Required' : 'Attention Required'}</h2>
              <p>${isCritical 
                ? `Tool <strong>${tool_id} - ${tool_name}</strong> has reached its tool life limit.`
                : `Tool <strong>${tool_id} - ${tool_name}</strong> is nearing its tool life limit.`
              }</p>
            </div>
            <div class="details">
              <h3>Usage Statistics</h3>
              <div class="detail-row"><strong>Cumulative Usage:</strong> ${cumulative_usage} units</div>
              <div class="detail-row"><strong>Tool Life Threshold:</strong> ${threshold} units</div>
              <div class="detail-row"><strong>Remaining Life:</strong> ${remaining_life} units</div>
              <div class="progress-bar">
                <div class="progress-fill" style="width: ${Math.min(usage_percentage, 100)}%;">
                  ${usage_percentage.toFixed(1)}%
                </div>
              </div>
            </div>
            ${components && components.length > 0 ? `
            <div class="details">
              <h3>Components Affected</h3>
              <p>${components.join(', ')}</p>
            </div>
            ` : ''}
          </div>
          <div class="footer">
            <p style="margin: 0;">TrackPro Tool Life Management System</p>
          </div>
        </div>
      </body>
      </html>
    `;
    
    const mailOptions = {
      from: `"TrackPro Alert" <${process.env.EMAIL_USER}>`,
      to: supervisorEmail,
      subject: subject,
      html: htmlContent
    };
    
    const info = await transporter.sendMail(mailOptions);
    console.log(`Email sent to ${supervisorEmail}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
    
  } catch (error) {
    console.error('Email error:', error);
    return { success: false, error: error.message };
  }
};

module.exports = { sendToolLifeAlert };
