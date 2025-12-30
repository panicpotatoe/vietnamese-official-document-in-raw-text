
---

## PHẦN 9: RỦI RO & GIẢI PHÁP

| Danh mục Rủi ro | Mô tả Rủi ro | Khả năng xảy ra | Tác động | Chiến lược Giảm thiểu | Chủ sở hữu |
|---------------|------------------|------------|--------|---------------------|-------|
| Inadequate PII Protection (Bảo vệ PII không đầy đủ) | PII leak qua gap trong masking logic | Thấp (Low) | Nghiêm trọng (Critical) | - Defense in depth (phòng thủ chiều sâu: detection + masking + access control)<br>- Regular penetration testing (kiểm tra thâm nhập định kỳ)<br>- Incident response plan (kế hoạch phản ứng sự cố)<br>- Quarterly security audits (kiểm toán an ninh hàng quý)<br>- Automated PII exposure alerts (cảnh báo phơi nhiễm PII tự động) | Security Team |
| Audit Failures (Thất bại Kiểm toán) | Không pass annual compliance audit (Không đạt kiểm toán tuân thủ hàng năm) | Thấp (Low) | Cao (High) | - Pre-audit self-assessments (tự đánh giá trước kiểm toán quý)<br>- Mock audits với external consultants (kiểm toán thử với tư vấn bên ngoài)<br>- Compliance checklist automated (danh mục kiểm tra tuân thủ tự động)<br>- Documentation ready at all times (tài liệu luôn sẵn sàng) | Compliance Officer |
| **AI-Specific Risks (Rủi ro Đặc thù AI)** | | | | | |
| Model Trained on Poor Data (Mô hình huấn luyện trên dữ liệu kém) | Quality gates fail, model trained on garbage data (Quality gates thất bại, mô hình huấn luyện trên dữ liệu rác) | Trung bình (Medium) | Cao (High) | - Mandatory quality validation (xác thực chất lượng bắt buộc - blocking)<br>- Quality score thresholds (ngưỡng điểm chất lượng >80)<br>- Human review for critical models (đánh giá con người cho mô hình quan trọng)<br>- Rollback capability if post-deployment issues (khả năng rollback nếu có vấn đề hậu triển khai) | ML Lead |
| Data Drift Not Detected (Data Drift không được phát hiện) | Production data drifts but not caught (Dữ liệu production bị drift nhưng không bắt được) | Trung bình (Medium) | Trung bình (Medium) | - Automated drift monitoring (giám sát drift tự động hàng ngày)<br>- Alerts với clear thresholds (cảnh báo với ngưỡng rõ ràng)<br>- Retraining triggers based on drift severity (trigger huấn luyện lại dựa trên mức độ drift)<br>- Manual review process for borderline cases (quy trình đánh giá thủ công cho trường hợp ranh giới) | ML Ops Engineer |
| Lineage Breaks (Đứt gãy Lineage) | Model lineage không tracked correctly (Model lineage không được theo dõi đúng) | Trung bình (Medium) | Thấp (Low) | - Automated lineage validation tests (kiểm tra xác thực lineage tự động)<br>- Manual documentation fallback (tài liệu thủ công dự phòng)<br>- Quarterly lineage audits (kiểm toán lineage hàng quý)<br>- Accept imperfect lineage (chấp nhận lineage 80%) | ML Ops Engineer |

---
