import re
import sys
import os

class DocumentCleaner:
    def __init__(self, file_path):
        self.file_path = file_path

    def is_garbage(self, line):
        s = line.strip()
        # Remove "about:blank"
        if s == 'about:blank': 
            return True
        # Remove page numbers like "1/26"
        if re.match(r'^\d+/\d+$', s): 
            return True
        # Remove date/timestamps
        clean_s = s.replace('\x0c', '').strip()
        if re.match(r'^\d{1,2}/\d{1,2}/\d{2}, \d{1,2}:\d{2} [AP]M$', clean_s): 
            return True
        # Remove form feed
        if s == '\x0c': 
            return True
        return False

    def should_join(self, current_line_stripped, next_line_content):
        curr = current_line_stripped
        if not curr:
            return False
        # Do not join if current line ends with punctuation
        if curr[-1] in ['.', ';', '!', '?', ':']:
            return False
        # Do not join if current line is a separator
        if '-----' in curr:
            return False
        # Do not join headers/titles
        if re.match(r'^(Điều \d|Chương [IVX]+|Mục \d)', curr):
            return False
        if curr.isupper() and len(curr) > 1:
            return False
        # Do not join short numbered lists
        if re.match(r'^\d+\.', curr) and len(curr) < 40:
            return False
        
        # Check next line
        # Do not join if next line is a list item or header
        if re.match(r'^(\d+\.|[a-z]\)|-|Điều|Chương|Mục)', next_line_content):
            return False
        if next_line_content.isupper() and len(next_line_content) > 1:
            return False
            
        return True

    def clean(self):
        if not os.path.exists(self.file_path):
            print(f"File not found: {self.file_path}")
            return

        with open(self.file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # Step 1: Filter garbage lines
        valid_lines = []
        for line in lines:
            if not self.is_garbage(line):
                valid_lines.append(line)

        # Step 2: Join broken lines
        joined_lines = []
        i = 0
        n = len(valid_lines)
        while i < n:
            current_line_raw = valid_lines[i].rstrip('\n')
            buffer = current_line_raw
            next_ptr = i + 1
            while next_ptr < n:
                next_line_raw = valid_lines[next_ptr].rstrip('\n')
                next_line_content = next_line_raw.strip()
                
                # If buffer is empty or next line matches garbage patterns (though strictly filtered), break
                if not buffer.strip():
                    break
                if not next_line_content:
                    break
                
                if self.should_join(buffer.strip(), next_line_content):
                    buffer = buffer.strip() + ' ' + next_line_content
                    next_ptr += 1
                else:
                    break
            joined_lines.append(buffer)
            i = next_ptr

        # Step 3: Remove dots strings (more than 3 dots)
        final_lines = []
        for line in joined_lines:
            # Replace 3 or more dots with empty string
            # User request: "remove parts that contain more than 3 dots"
            new_line = re.sub(r'\.{3,}', '', line)
            
            # Step 4: Remove empty lines (ensure clean spacing)
            s_line = new_line.strip()
            if s_line:
                final_lines.append(s_line)

        # Write back to file
        with open(self.file_path, 'w', encoding='utf-8') as f:
            for line in final_lines:
                f.write(line + '\n')
        
        print(f"Successfully cleaned {self.file_path}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        target_path = sys.argv[1]
        
        if os.path.isdir(target_path):
            print(f"Scanning directory: {target_path}")
            txt_files = [f for f in os.listdir(target_path) if f.endswith('.txt')]
            if not txt_files:
                print("No .txt files found in directory.")
            
            for file_name in txt_files:
                full_path = os.path.join(target_path, file_name)
                print(f"Processing {full_path}...")
                cleaner = DocumentCleaner(full_path)
                cleaner.clean()
        else:
            cleaner = DocumentCleaner(target_path)
            cleaner.clean()
    else:
        # Default behavior for current context if no arg provided
        default_file = '/Users/nhantran/git/vietnamese-official-document-in-raw-text/13.2023.NĐ-CP.txt'
        print(f"No argument provided. Defaulting to {default_file}")
        cleaner = DocumentCleaner(default_file)
        cleaner.clean()
