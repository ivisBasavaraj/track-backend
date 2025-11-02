import csv
import sys

def clean_csv(input_file, output_file):
    """Remove empty columns and clean CSV data"""
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
    
    if not rows:
        print("Error: CSV file is empty")
        return
    
    # Find header row (first non-empty row)
    header_idx = 0
    for i, row in enumerate(rows):
        if any(cell.strip() for cell in row):
            header_idx = i
            break
    
    header = rows[header_idx]
    
    # Find non-empty column indices
    non_empty_cols = []
    for i, cell in enumerate(header):
        if cell.strip():
            non_empty_cols.append(i)
    
    # Extract data with only non-empty columns
    cleaned_rows = []
    cleaned_rows.append([header[i] for i in non_empty_cols])
    
    # Process data rows
    for row in rows[header_idx + 1:]:
        if len(row) > 0:
            cleaned_row = []
            for i in non_empty_cols:
                if i < len(row):
                    cleaned_row.append(row[i].strip())
                else:
                    cleaned_row.append('')
            cleaned_rows.append(cleaned_row)
    
    # Write cleaned CSV
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(cleaned_rows)
    
    print(f"Cleaned CSV saved to: {output_file}")
    print(f"  Columns: {len(non_empty_cols)}")
    print(f"  Rows: {len(cleaned_rows) - 1}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        input_file = "AMS-141 COLUMN.csv"
        output_file = "AMS-141 COLUMN_cleaned.csv"
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else input_file.replace('.csv', '_cleaned.csv')
    
    clean_csv(input_file, output_file)
