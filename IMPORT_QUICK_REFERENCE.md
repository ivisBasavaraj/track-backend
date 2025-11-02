# 🚀 Quick Reference - Import Your Master Tools

## One Command Import

```bash
cd trackpro/backend
node scripts/import-master-tools.js
```

**Result**: 45 tools imported with default threshold 5000

---

## What Gets Imported

From your `full_tool_list.csv`:

✅ **45 Active Tools** (Tool IDs: 1-50, excluding N/A entries)
- All tool names, holders, ATC pocket numbers
- Default threshold: **5000** for all tools

❌ **15 Skipped** (N/A entries at slots 31-37, 44, 56-60)

---

## Update Specific Thresholds

### Via Postman (Recommended)

```http
PATCH /api/tool-life/master/5
Authorization: Bearer YOUR_TOKEN

{
  "tool_life_threshold": 3000,
  "supervisor_email": "supervisor@company.com"
}
```

### Quick Updates for Common Tools

```bash
# Tool 5: 5 CARBIDE DRILL
PATCH /api/tool-life/master/5
{ "tool_life_threshold": 3000 }

# Tool 17: 125 FINISHING FACEMILL
PATCH /api/tool-life/master/17
{ "tool_life_threshold": 15000 }

# Tool 21: M6 ST TAP
PATCH /api/tool-life/master/21
{ "tool_life_threshold": 2000 }
```

---

## Verify Import

### Check Count
```bash
GET /api/tool-life/master/all
# Should return 45 tools
```

### Check Specific Tool
```bash
GET /api/tool-life/5/status
# Returns: Tool 5 - 5 CARBIDE DRILL
```

### In Flutter
1. Open app
2. Go to Tool Life Dashboard
3. See all 45 tools listed

---

## Your Imported Tools

| ID | Tool Name | Holder | Threshold |
|----|-----------|--------|-----------|
| 1 | 125 ROUGHING FACEMILL | SLA40 100GPL | 5000 |
| 2 | 63 ROUGHING SHOULDERMILL | FMB22 150GPL | 5000 |
| 3 | 80 ROUGHING SHOULDERMILL | FMB27 150GPL | 5000 |
| 4 | 16 FINISHING ENDMILL | ER32 150GPL | 5000 |
| 5 | 5 CARBIDE DRILL | ER32 100GPL | 5000 |
| 6 | 6.8 CARBIDE DRILL | ER16 200GPL | 5000 |
| 7 | 10.2 CARBIDE DRILL | ER25 150GPL | 5000 |
| 8 | 14 CARBIDE DRILL | ER25 150GPL | 5000 |
| ... | ... | ... | ... |
| 50 | 80 FINISHING SHOULDERMILL | SMS27 220GPL | 5000 |

---

## Recommended Thresholds by Tool Type

### Drills
- **Small (< 10mm)**: 3000-5000
- **Medium (10-20mm)**: 5000-8000
- **Large (> 20mm)**: 8000-10000

### End Mills
- **Roughing**: 5000-8000
- **Finishing**: 8000-12000

### Face Mills
- **Roughing**: 10000-15000
- **Finishing**: 15000-20000

### Taps
- **Small (M6-M12)**: 2000-3000
- **Large (M14-M24)**: 3000-5000

### Reamers
- **All sizes**: 5000-8000

---

## Complete Workflow

### 1. Import (1 minute)
```bash
node scripts/import-master-tools.js
```

### 2. Update Critical Tools (5 minutes)
Use Postman to update thresholds for your most-used tools

### 3. Start Tracking (Immediate)
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-141",
  "no_of_holes": 43,
  "cutting_length": 23
}
```

### 4. Monitor (Ongoing)
- Check dashboard for tool status
- Receive alerts at 90% and 100%
- Reset tools after maintenance

---

## Files Created

✅ `scripts/import-master-tools.js` - Import script
✅ `IMPORT_MASTER_TOOLS.md` - Detailed guide
✅ `IMPORT_QUICK_REFERENCE.md` - This file
✅ Updated API endpoint: `PATCH /master/:toolId`
✅ Updated Postman collection

---

## Need Help?

- **Full Guide**: See `IMPORT_MASTER_TOOLS.md`
- **System Docs**: See `START_HERE_TOOL_LIFE.md`
- **API Docs**: See `TOOL_LIFE_TRACKING_GUIDE.md`

---

**Ready? Run the import command above! ⬆️**
