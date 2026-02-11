1. Toàn bộ các yêu cầu trích xuất dữ liệu liệu (dù chỉ là 01 file) cũng cần được lưu trữ trong 01 sub-folder riêng biệt
2. Folder name format: {YYYYMMDD}_{PII/nonPII}_{description}
Ví dụ:
98_Shared_External > 10_Extracted_Data/
                        ├── 20260130_nonPII_So_luot_booking_Vinpearl/
                            └── some_excel_file.xlsx 
                        └── 20260131_PII_Vinclub_order_du_lieu_KH_Vinhomes/
                            └── some_excel_file.xlsx

3. Toàn bộ folder này cần được share cho đúng nhân sự được phân quyền truy cập dữ liệu (theo email được phê duyệt).
4. File Excel cần được lock bằng password, DA gửi password này trực tiếp qua email đến đúng nhân sự được phân quyền truy cập dữ liệu (theo email được phê duyệt).