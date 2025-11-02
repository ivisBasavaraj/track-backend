# Import Master Tools from CSV

## Quick Import

Your master tool list (`full_tool_list.csv`) is ready to import!

### Step 1: Run Import Script

```bash
cd trackpro/backend
node scripts/import-master-tools.js
```

### Expected Output

```
Connecting to MongoDB...
Connected to MongoDB

Reading CSV from: C:\Users\Aryan\Desktop\TrackPro-HKL\trackpro\full_tool_list.csv
Found 60 tools in CSV

✓ Imported: Tool 1 - 125 ROUGHING FACEMILL (Threshold: 5000)
✓ Imported: Tool 2 - 63 ROUGHING SHOULDERMILL (Threshold: 5000)
✓ Imported: Tool 3 - 80 ROUGHING SHOULDERMILL (Threshold: 5000)
...
✓ Imported: Tool 50 - 80 FINISHING SHOULDERMILL (Threshold: 5000)

============================================================
Import Summary:
  Imported: 45 tools
  Updated: 0 tools
  Skipped: 15 empty entries
  Total: 45 active tools
============================================================

Note: All tools imported with default threshold of 5000
```

### What Happens

- ✅ Reads `full_tool_list.csv`
- ✅ Imports all valid tools (skips N/A entries)
- ✅ Sets default threshold: **5000** (since CSV has N/A)
- ✅ Creates master tool records in MongoDB
- ✅ Ready for usage tracking

## Update Tool Life Thresholds

After import, update specific tool thresholds:

### Via API (Postman)

```bash
PATCH /api/tool-life/master/5
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "tool_life_threshold": 3000,
  "supervisor_email": "supervisor@company.com"
}
```

### Example: Update Multiple Tools

```bash
# Tool 5: CARBIDE DRILL → 3000
PATCH /api/tool-life/master/5
{ "tool_life_threshold": 3000 }

# Tool 7: CARBIDE DRILL → 4000
PATCH /api/tool-life/master/7
{ "tool_life_threshold": 4000 }

# Tool 17: FACEMILL → 10000
PATCH /api/tool-life/master/17
{ "tool_life_threshold": 10000 }
```

## Verify Import

### Check in MongoDB

```bash
mongo mongodb://localhost:27017/trackpro
db.mastertools.count()  # Should show 45
db.mastertools.find({ tool_id: 5 }).pretty()
```

### Check via API

```bash
GET /api/tool-life/master/all
```

### Check in Flutter

1. Open app
2. Navigate to Tool Life Dashboard
3. See all 45 tools listed

## Your Tools

From your CSV, these tools will be imported:

| Tool ID | Tool Name | Holder | Default Threshold |
|---------|-----------|--------|-------------------|
| 1 | 125 ROUGHING FACEMILL | SLA40 100GPL | 5000 |
| 2 | 63 ROUGHING SHOULDERMILL | FMB22 150GPL | 5000 |
| 3 | 80 ROUGHING SHOULDERMILL | FMB27 150GPL | 5000 |
| 4 | 16 FINISHING ENDMILL | ER32 150GPL | 5000 |
| 5 | 5 CARBIDE DRILL | ER32 100GPL | 5000 |
| ... | ... | ... | ... |
| 50 | 80 FINISHING SHOULDERMILL | SMS27 220GPL | 5000 |

**Total: 45 active tools** (15 N/A entries skipped)

## Recommended Thresholds

Based on tool types, consider these thresholds:

### Drills
- Small drills (< 10mm): 3000-5000
- Medium drills (10-20mm): 5000-8000
- Large drills (> 20mm): 8000-10000

### End Mills
- Roughing: 5000-8000
- Finishing: 8000-12000

### Face Mills
- Roughing: 10000-15000
- Finishing: 15000-20000

### Taps
- Small taps (M6-M12): 2000-3000
- Large taps (M14-M24): 3000-5000

### Reamers
- All sizes: 5000-8000

## Update Script for Common Tools

Create a file `update-thresholds.js`:

```javascript
require('dotenv').config();
const mongoose = require('mongoose');
const MasterTool = require('../models/MasterTool');

const thresholds = {
  5: 3000,   // 5 CARBIDE DRILL
  7: 4000,   // 10.2 CARBIDE DRILL
  8: 4000,   // 14 CARBIDE DRILL
  17: 15000, // 125 FINISHING FACEMILL
  // Add more as needed
};

async function updateThresholds() {
  await mongoose.connect(process.env.MONGODB_URI);
  
  for (const [toolId, threshold] of Object.entries(thresholds)) {
    await MasterTool.updateOne(
      { tool_id: parseInt(toolId) },
      { $set: { tool_life_threshold: threshold } }
    );
    console.log(`Updated Tool ${toolId} → ${threshold}`);
  }
  
  process.exit(0);
}

updateThresholds();
```

Run it:
```bash
node scripts/update-thresholds.js
```

## Re-import (If Needed)

If you need to re-import:

```bash
# Script will update existing tools
node scripts/import-master-tools.js
```

Existing tools will be updated, not duplicated.

## Next Steps

1. ✅ Import tools (run script above)
2. ✅ Verify in MongoDB or API
3. ✅ Update thresholds for critical tools
4. ✅ Set supervisor email
5. ✅ Start tracking usage!

## Troubleshooting

### "CSV file not found"
**Solution**: Script looks for `full_tool_list.csv` in `trackpro/` folder

### "Duplicate key error"
**Solution**: Tools already imported. Script will update them.

### "Cannot connect to MongoDB"
**Solution**: Start MongoDB first
```bash
# Windows
net start MongoDB

# Linux/Mac
sudo systemctl start mongod
```

---

**Ready to import? Run the command above! 🚀**
