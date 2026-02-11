import os
import re

def test_report_structure(file_path):
    if not os.path.exists(file_path):
        print(f"FAIL: File not found {file_path}")
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Required sequences (Regex for headers)
    sections = [
        r"Executive Summary",
        r"Stock Performance",
        r"AI Tooling & Experts",
        r"Hospitality Tech"
    ]
    
    positions = []
    for section in sections:
        match = re.search(section, content)
        if not match:
            print(f"FAIL: Section '{section}' not found.")
            return False
        positions.append(match.start())
    
    # Check order
    if positions == sorted(positions):
        print("PASS: Sections are in the correct sequence.")
        
        # Check for citation footnotes [1]
        if re.search(r"\[\d+\]", content):
            print("FAIL: Found footnote markers like [1].")
            return False
        else:
            print("PASS: No digital footnote markers found.")
            
        # Check for numeric change in stock table
        # Look for the stock body and check the second TD for a percentage
        stock_match = re.search(r"<tbody id=\"stockBody\">(.*?)</tbody>", content, re.DOTALL)
        if stock_match:
            rows = re.findall(r"<tr>(.*?)</tr>", stock_match.group(1), re.DOTALL)
            for row in rows:
                cols = re.findall(r"<td.*?>(.*?)</td>", row, re.DOTALL)
                if len(cols) >= 2:
                    change_val = cols[1].strip()
                    if not re.search(r"[+-]?\d+", change_val) or "Featured" in change_val or "T" in change_val:
                        print(f"FAIL: Stock Change (%) Column has invalid data: '{change_val}'")
                        return False
            print("PASS: Stock table uses numeric changes.")
        
        return True
    else:
        print("FAIL: Sections are OUT OF ORDER.")
        return False

if __name__ == "__main__":
    # Test latest report
    reports_dir = r"c:\Users\749534\Desktop\Daily-Report\reports"
    files = [f for f in os.listdir(reports_dir) if f.startswith("Daily_Report_") and f.endswith(".html")]
    if not files:
        print("No reports to test.")
    else:
        latest = sorted(files)[-1]
        full_path = os.path.join(reports_dir, latest)
        print(f"Testing {latest}...")
        test_report_structure(full_path)
