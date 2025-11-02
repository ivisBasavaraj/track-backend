const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

// Create uploads directory if it doesn't exist
const uploadDir = path.resolve(__dirname, '../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    // Generate secure unique filename
    const uniqueSuffix = Date.now() + '-' + crypto.randomBytes(8).toString('hex');
    const sanitizedOriginalName = path.basename(file.originalname);
    const ext = path.extname(sanitizedOriginalName);
    const filename = file.fieldname + '-' + uniqueSuffix + ext;
    cb(null, filename);
  }
});

// File filter
const fileFilter = (req, file, cb) => {
  // Allowed extensions
  const allowedExtensions = ['.csv'];
  const fileExtension = path.extname(file.originalname).toLowerCase();

  if (allowedExtensions.includes(fileExtension)) {
    cb(null, true);
  } else {
    console.log(`Rejected file: ${file.originalname}`);
    cb(new Error(`Only CSV files (${allowedExtensions.join(', ')}) are allowed`));
  }
};

// Configure multer
const csvUpload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  }
});

module.exports = csvUpload;