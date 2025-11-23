USE master;
GO
-- Xóa database cũ nếu tồn tại
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'ShopeeDB')
BEGIN
    ALTER DATABASE ShopeeDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ShopeeDB;
END
GO

CREATE DATABASE ShopeeDB;
GO

USE ShopeeDB;
GO

-- ============================================================
-- 1. BẢNG USER (Người dùng)
-- ============================================================
CREATE TABLE [User] (
    User_id INT IDENTITY(1,1) PRIMARY KEY,
    Ten_dang_nhap VARCHAR(50) NOT NULL UNIQUE,
    Mat_khau VARCHAR(255) NOT NULL, 
    Email VARCHAR(100) NOT NULL UNIQUE,
    SDT VARCHAR(15) NOT NULL UNIQUE,
    Ho NVARCHAR(50) NOT NULL,
    Ten NVARCHAR(50) NOT NULL,
    Ten_lot NVARCHAR(50),
    Trang_thai_tai_khoan VARCHAR(20) DEFAULT 'Active' CHECK (Trang_thai_tai_khoan IN ('Active', 'Inactive', 'Suspended')),
    CONSTRAINT CHK_Email_Format CHECK (Email LIKE '%_@__%.__%'),
    CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10)
);
GO

-- ============================================================
-- 2. BẢNG SELLER (Người bán)
-- ============================================================
CREATE TABLE Seller (
    User_id INT PRIMARY KEY,
    Seller_type VARCHAR(50) CHECK (Seller_type IN ('Individual', 'Business', 'Enterprise')), 
    CONSTRAINT FK_Seller_User FOREIGN KEY (User_id) REFERENCES [User](User_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 3. BẢNG BUYER (Người mua)
-- ============================================================
CREATE TABLE Buyer (
    User_id INT PRIMARY KEY,    
    CONSTRAINT FK_Buyer_User FOREIGN KEY (User_id) REFERENCES [User](User_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 4. BẢNG STORE (Gian hàng)
-- ============================================================
CREATE TABLE Store (
    Store_id INT IDENTITY(1,1) PRIMARY KEY,
    Seller_id INT NOT NULL,
    Ten_gian_hang NVARCHAR(100) NOT NULL,
    Mo_ta NVARCHAR(255),
    Ngay_tao DATETIME DEFAULT GETDATE(),
    Thong_tin_phap_ly NVARCHAR(MAX),
    CONSTRAINT FK_Store_Seller FOREIGN KEY (Seller_id) REFERENCES Seller(User_id)
);
GO

-- ============================================================
-- 5. BẢNG CATEGORY (Danh mục)
-- ============================================================
CREATE TABLE Category (
    Category_id INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    Mo_ta NVARCHAR(255),
    Super_Category_id INT NULL,
    CONSTRAINT FK_Category_Super FOREIGN KEY (Super_Category_id) REFERENCES Category(Category_id)
);
GO

-- ============================================================
-- 6. BẢNG PRODUCT (Sản phẩm)
-- ============================================================
CREATE TABLE Product (
    Product_id INT IDENTITY(1,1) PRIMARY KEY,
    Store_id INT NOT NULL,
    Ten_san_pham NVARCHAR(200) NOT NULL,
    Mo_ta_chi_tiet NVARCHAR(MAX), 
    Tinh_trang VARCHAR(20) CHECK (Tinh_trang IN ('New', 'Used', 'Refurbished')),
    Trong_luong DECIMAL(10,2) CHECK (Trong_luong > 0),
    Trang_thai_dang VARCHAR(20) DEFAULT 'Hidden' CHECK (Trang_thai_dang IN ('Active', 'Hidden', 'Deleted')),
    Ngay_dang DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Product_Store FOREIGN KEY (Store_id) REFERENCES Store(Store_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 7. BẢNG VARIANT (Phân loại sản phẩm)
-- ============================================================
CREATE TABLE Variant (
    Product_id INT NOT NULL,
    SKU NVARCHAR(100) NOT NULL,
    Mau_sac NVARCHAR(50) NOT NULL,
    Kich_thuoc NVARCHAR(50) NOT NULL,
    Gia_ban DECIMAL(18,2) NOT NULL CHECK (Gia_ban >= 0),
    So_luong_ton_kho INT DEFAULT 0 CHECK (So_luong_ton_kho >= 0),
    
    PRIMARY KEY (Product_id, SKU),
    CONSTRAINT FK_Variant_Product FOREIGN KEY (Product_id) REFERENCES Product(Product_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 8. BẢNG IMAGE (Hình ảnh sản phẩm)
-- ============================================================
CREATE TABLE [Image] (
    Product_id INT NOT NULL,
    Image_id INT NOT NULL,
    Duong_dan_anh NVARCHAR(500) NOT NULL,
    
    PRIMARY KEY (Product_id, Image_id),
    CONSTRAINT FK_Image_Product FOREIGN KEY (Product_id) REFERENCES Product(Product_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 9. BẢNG THUOC_VE (Quan hệ Product-Category)
-- ============================================================
CREATE TABLE Thuoc_ve (
    Category_id INT NOT NULL,
    Product_id INT NOT NULL,
    
    PRIMARY KEY (Category_id, Product_id),
    CONSTRAINT FK_Thuoc_ve_Category FOREIGN KEY (Category_id) REFERENCES Category(Category_id) ON DELETE CASCADE,
    CONSTRAINT FK_Thuoc_ve_Product FOREIGN KEY (Product_id) REFERENCES Product(Product_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 10. BẢNG ORDER (Đơn hàng)
-- ============================================================
CREATE TABLE [Order] (
    Order_id INT IDENTITY(1,1) PRIMARY KEY,
    Buyer_id INT NOT NULL,
    Trang_thai_don NVARCHAR(50) DEFAULT N'Chờ Xác Nhận' 
        CHECK (Trang_thai_don IN (N'Chờ Xác Nhận', N'Chờ Lấy Hàng', N'Đang Vận Chuyển', N'Đã Giao', N'Đã Hủy', N'Hoàn Trả')),
    Ngay_dat_hang DATETIME DEFAULT GETDATE(),
    Dia_chi_giao_hang NVARCHAR(255) NOT NULL,
    
    CONSTRAINT FK_Order_Buyer FOREIGN KEY (Buyer_id) REFERENCES Buyer(User_id)
);
GO

-- ============================================================
-- 11. BẢNG ORDER_ITEM (Chi tiết đơn hàng)
-- ============================================================
CREATE TABLE Order_item (
    Order_id INT NOT NULL,
    Item_id INT NOT NULL,
    Product_id INT NOT NULL,
    SKU NVARCHAR(100) NOT NULL, 
    So_luong INT NOT NULL CHECK (So_luong > 0),
    
    PRIMARY KEY (Order_id, Item_id),
    CONSTRAINT FK_Order_item_Order FOREIGN KEY (Order_id) REFERENCES [Order](Order_id) ON DELETE CASCADE,
    CONSTRAINT FK_Order_item_Variant FOREIGN KEY (Product_id, SKU) REFERENCES Variant(Product_id, SKU)
);
GO

-- ============================================================
-- 12. BẢNG COUPON (Mã giảm giá)
-- ============================================================
CREATE TABLE Coupon (
    Coupon_id INT IDENTITY(1,1) PRIMARY KEY, 
    Ti_le_giam DECIMAL(5,2) CHECK (Ti_le_giam >= 0 AND Ti_le_giam <= 100),
    Thoi_han DATETIME NOT NULL,
    Dieu_kien_gia_toi_thieu DECIMAL(18,2) DEFAULT 0 CHECK (Dieu_kien_gia_toi_thieu >= 0)
);
GO

-- ============================================================
-- 13. BẢNG AP_DUNG (Áp dụng coupon cho order_item)
-- ============================================================
CREATE TABLE Ap_dung (
    Order_id INT NOT NULL,
    Item_id INT NOT NULL,
    Coupon_id INT NOT NULL,
    
    PRIMARY KEY (Order_id, Item_id, Coupon_id),
    CONSTRAINT FK_Ap_dung_Order_item FOREIGN KEY (Order_id, Item_id) REFERENCES Order_item(Order_id, Item_id) ON DELETE CASCADE,
    CONSTRAINT FK_Ap_dung_Coupon FOREIGN KEY (Coupon_id) REFERENCES Coupon(Coupon_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 14. BẢNG PAYMENT (Thanh toán)
-- ============================================================
CREATE TABLE Payment (
    Payment_id INT IDENTITY(1,1) PRIMARY KEY,
    Order_id INT NOT NULL UNIQUE, -- Một order chỉ có một payment
    Trang_thai_thanh_toan NVARCHAR(50) DEFAULT N'Chờ Thanh Toán' 
        CHECK (Trang_thai_thanh_toan IN (N'Chờ Thanh Toán', N'Đã Thanh Toán', N'Thất Bại', N'Hoàn Tiền')),
    Phuong_thuc_thanh_toan NVARCHAR(100) 
        CHECK (Phuong_thuc_thanh_toan IN ('COD', 'Credit Card', 'Debit Card', 'ShopeePay', 'Bank Transfer', 'SPayLater')),
    Ma_giao_dich NVARCHAR(100) UNIQUE, -- Mã giao dịch duy nhất từ cổng thanh toán
    
    
    CONSTRAINT FK_Payment_Order FOREIGN KEY (Order_id) REFERENCES [Order](Order_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 15. BẢNG SHIPPER (Đơn vị vận chuyển)
-- ============================================================
CREATE TABLE Shipper (
    Shipper_id INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    Thong_tin_lien_he NVARCHAR(255)
);
GO

-- ============================================================
-- 16. BẢNG SHIPMENT (Vận chuyển)
-- ============================================================
CREATE TABLE Shipment (
    Shipment_id INT IDENTITY(1,1) PRIMARY KEY,
    Order_id INT NOT NULL UNIQUE, -- Một order chỉ có một shipment
    Shipper_id INT NOT NULL,
    Phuong_thuc_van_chuyen NVARCHAR(100),
    Ma_theo_doi NVARCHAR(100) UNIQUE,
    Ngay_gui DATETIME,
    Ngay_giao_du_kien DATETIME,
    Ngay_giao_thuc_te DATETIME NULL, 
    
    CONSTRAINT FK_Shipment_Order FOREIGN KEY (Order_id) REFERENCES [Order](Order_id) ON DELETE CASCADE,
    CONSTRAINT FK_Shipment_Shipper FOREIGN KEY (Shipper_id) REFERENCES Shipper(Shipper_id),
    CONSTRAINT CHK_Shipment_Dates CHECK (Ngay_giao_du_kien IS NULL OR Ngay_gui IS NULL OR Ngay_giao_du_kien > Ngay_gui),
    CONSTRAINT CHK_Shipment_Dates_real CHECK (Ngay_giao_thuc_te IS NULL OR Ngay_gui IS NULL OR Ngay_giao_thuc_te > Ngay_gui)
);
GO

-- ============================================================
-- 17. BẢNG TRO_CHUYEN (Cuộc trò chuyện giữa Seller và Buyer)
-- ============================================================
CREATE TABLE Tro_Chuyen (
    Seller_id INT NOT NULL,
    Buyer_id INT NOT NULL,
    
    PRIMARY KEY (Seller_id, Buyer_id),
    CONSTRAINT FK_Tro_Chuyen_Seller FOREIGN KEY (Seller_id) REFERENCES Seller(User_id),
    CONSTRAINT FK_Tro_Chuyen_Buyer FOREIGN KEY (Buyer_id) REFERENCES Buyer(User_id)
);
GO

-- ============================================================
-- 18. BẢNG CUOC_TRO_CHUYEN (Tin nhắn trong cuộc trò chuyện)
-- ============================================================
CREATE TABLE Cuoc_Tro_Chuyen (
    Seller_id INT NOT NULL,
    Buyer_id INT NOT NULL,
    Thoi_gian DATETIME NOT NULL DEFAULT GETDATE(),
    Noi_dung NVARCHAR(255) NOT NULL,
    
    PRIMARY KEY (Seller_id, Buyer_id, Thoi_gian, Noi_dung),
    CONSTRAINT FK_Cuoc_Tro_Chuyen_Tro_Chuyen FOREIGN KEY (Seller_id, Buyer_id) 
        REFERENCES Tro_Chuyen(Seller_id, Buyer_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 19. BẢNG ADDRESS_BUYER (Địa chỉ người mua)
-- ============================================================
CREATE TABLE Address_buyer (
    Buyer_id INT NOT NULL,
    Dia_chi NVARCHAR(255) NOT NULL,
    
    PRIMARY KEY (Buyer_id, Dia_chi),
    CONSTRAINT FK_Address_buyer_Buyer FOREIGN KEY (Buyer_id) REFERENCES Buyer(User_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 20. BẢNG ADDRESS_STORE (Địa chỉ gian hàng)
-- ============================================================
CREATE TABLE Address_store (
    Store_id INT NOT NULL,
    Dia_chi NVARCHAR(255) NOT NULL,
    
    PRIMARY KEY (Store_id, Dia_chi),
    CONSTRAINT FK_Address_store_Store FOREIGN KEY (Store_id) REFERENCES Store(Store_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 21. BẢNG DANH_GIA (Đánh giá sản phẩm)
-- ============================================================
CREATE TABLE Danh_gia (
    Product_id INT NOT NULL,
    Order_id INT NOT NULL,
    Ngay_danh_gia DATETIME DEFAULT GETDATE(),
    So_sao INT NOT NULL CHECK (So_sao >= 1 AND So_sao <= 5),
    Noi_dung_binh_luan NVARCHAR(MAX),
    Phan_hoi_cua_nguoi_ban NVARCHAR(MAX),
    
    PRIMARY KEY (Product_id, Order_id),
    CONSTRAINT FK_Danh_gia_Product FOREIGN KEY (Product_id) REFERENCES Product(Product_id),
    CONSTRAINT FK_Danh_gia_Order FOREIGN KEY (Order_id) REFERENCES [Order](Order_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- TRIGGERS - RÀNG BUỘC NGỮ NGHĨA
-- ============================================================

-- TRIGGER 1: Người mua không được mua sản phẩm từ cửa hàng của chính mình
GO
CREATE TRIGGER trg_Prevent_Self_Purchase
ON [Order]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Order_item oi ON i.Order_id = oi.Order_id
        INNER JOIN Product p ON oi.Product_id = p.Product_id
        INNER JOIN Store s ON p.Store_id = s.Store_id
        WHERE i.Buyer_id = s.Seller_id
    )
    BEGIN
        RAISERROR (N'Người mua không được phép đặt mua sản phẩm từ cửa hàng của chính mình.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 2: Sản phẩm chỉ được Active khi có ít nhất 1 ảnh và thuộc category
GO
CREATE TRIGGER trg_Product_Active_Validation
ON Product
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.Trang_thai_dang = 'Active'
        AND (
            -- Không có ảnh
            NOT EXISTS (SELECT 1 FROM [Image] WHERE Product_id = i.Product_id)
            -- Hoặc không thuộc category nào
            OR NOT EXISTS (SELECT 1 FROM Thuoc_ve WHERE Product_id = i.Product_id)
        )
    )
    BEGIN
        RAISERROR (N'Sản phẩm chỉ được Active khi có ít nhất 1 ảnh và thuộc category.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 3: Buyer chỉ được đánh giá sau khi đơn hàng "Đã Giao"
GO
CREATE TRIGGER trg_Review_After_Delivery
ON Danh_gia
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN [Order] o ON i.Order_id = o.Order_id
        WHERE o.Trang_thai_don <> N'Đã Giao'
    )
    BEGIN
        RAISERROR (N'Người mua chỉ được đánh giá sau khi đơn hàng đã được giao thành công.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 4: Kiểm tra tồn kho trước khi tạo order_item
GO
CREATE TRIGGER trg_Check_Stock_Before_Order
ON Order_item
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Variant v ON i.Product_id = v.Product_id AND i.SKU = v.SKU
        WHERE v.So_luong_ton_kho < i.So_luong
    )
    BEGIN
        RAISERROR (N'Số lượng sản phẩm trong kho không đủ để đáp ứng đơn hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 5: Coupon phải còn hạn sử dụng
GO
CREATE TRIGGER trg_Coupon_Valid
ON Ap_dung
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Coupon c ON i.Coupon_id = c.Coupon_id
        WHERE c.Thoi_han < GETDATE()
    )
    BEGIN
        RAISERROR (N'Mã giảm giá đã hết hạn sử dụng.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 6: Tự động cập nhật ngày giao thực tế khi shipment "Đã Giao"
GO
CREATE TRIGGER trg_Update_Delivery_Date
ON [Order]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE s
    SET Ngay_giao_thuc_te = GETDATE()
    FROM Shipment s
    INNER JOIN inserted i ON s.Order_id = i.Order_id
    WHERE i.Trang_thai_don = N'Đã Giao'
    AND s.Ngay_giao_thuc_te IS NULL;
END;
GO

PRINT N'========================================';
PRINT N'Tạo cơ sở dữ liệu thành công!';
PRINT N'Tổng số bảng: 21';
PRINT N'Tổng số triggers: 6';
PRINT N'========================================';
GO