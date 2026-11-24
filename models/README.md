# Mẫu hiệu chuẩn (STL)

Sinh bằng `scripts\models\make-cal-models.ps1` (chạy lại sẽ ghi đè ba file này). STL nhị phân, đơn vị mm, trục Z hướng lên, mỗi mẫu đặt sẵn trên mặt phẳng Z = 0. Máy nhỏ nhất là Bambu A1 Mini (bàn 180 × 180 mm); mọi mẫu dưới 120 mm mỗi chiều. Đầu phun 0,4 mm, lớp 0,2 mm.

| File | Kích thước (X × Y × Z) | Tam giác |
|---|---|---|
| `cal-a-frame-100x100x20.stl` | 100 × 100 × 20 mm | 48 |
| `cal-b-hole-pin.stl` | 90 × 58,9 × 10 mm | 1068 |
| `cal-c-overhang-tower.stl` | 56,6 × 20 × 40 mm | 36 |

## (a) Khung rỗng

Khung ngoài 100 × 100 × 20 mm, hở hai đầu (không đáy, không nắp), thành dày 2,4 mm (6 đường 0,4 mm).

- **Dấu nhận trục X**: hai góc phía +X (góc +X,-Y và +X,+Y) bị vát 5 × 5 mm; hai góc phía -X vuông. Đặt mẫu sao cho đầu có hai góc vát nằm ở +X của bàn in (nhìn từ phía trước máy là bên phải). Vát chỉ ở góc nên các mặt phẳng giữa cạnh vẫn đúng 100 mm.
- **Đo**: X là khoảng cách hai mặt phẳng ngoài của hai thành dọc trục X (đo ở giữa chiều cao, khoảng Z = 10 mm, ở giữa cạnh, tránh góc vát); Y đo tương tự trên hai thành còn lại; Z đo chiều cao thành. Mỗi kích thước đo 3 lần ở ba vị trí khác nhau rồi ghi vào phiếu.

## (b) Tấm lỗ và chốt

Tấm 90 × 40 × 5 mm có một lỗ tròn xuyên Ø8,00 mm (tâm X = -20) và một lỗ vuông xuyên 8,00 × 8,00 mm (tâm X = +20). Phía trên tấm (Y = +35) là hai chốt rời: chốt trụ Ø7,80 mm và chốt vuông 7,80 × 7,80 mm, cao 10 mm, in đứng.

- **Khe hở chốt chọn: 0,2 mm theo đường kính (0,1 mm mỗi bên).** Lý do: dung sai lỗ đã chốt ±0,15 mm, nên mỗi mẫu có thể lệch tới 0,15 mm đường kính; khe hở 0,2 mm là giá trị danh nghĩa để chốt trơn lắp được khi lỗ và chốt cùng đạt dung sai nhưng không rơ quá lớn. Đổi bằng tham số `-PinClearance` của script. Khe hở này chưa được thử trên máy thật; nếu cặp lỗ-chốt đạt dung sai mà vẫn kẹt, ghi vào phiếu rồi xem lại.
- **Dựng đa giác**: lỗ tròn và chốt tròn đều là đa giác đều 128 cạnh có các đỉnh nằm trên đường tròn danh nghĩa (đa giác nội tiếp). Đường kính qua hai đỉnh đối diện đúng Ø8,00 mm; đường kính giữa hai cạnh song song nhỏ hơn 8 × (1 - cos(π/128)) = 0,0024 mm, dưới 0,01 mm. Tham số `-Segments` (bội của 4, từ 96 trở lên) chỉnh số cạnh.
- **Đo lỗ**: đo đường kính lỗ tròn bằng hai hàm trong của thước cặp, 3 lần ở các hướng khác nhau.

## (c) Tháp nhô

Cột 20 × 20 mm, cao 40 mm, có ba bậc nhô về phía +X, mỗi bậc cao 8 mm, nghiêng so với phương thẳng đứng lần lượt 45°, 55°, 65° (từ dưới lên), giữa các bậc có đoạn thẳng đứng 4 mm. Mặt trái (-X) thẳng đứng để so bề mặt. Chỉ so bằng ảnh, không có số đo.

## Kiểm lưới

Script đọc lại từng file đã ghi và in: bounding box, số tam giác, số cạnh không thuộc đúng hai tam giác (phải bằng 0), thể tích có dấu dương (pháp tuyến hướng ra ngoài). Thể tích khung (a) tính từ lưới so với công thức hình học, lệch 0,0001 %.
