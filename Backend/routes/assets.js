import express from "express";
import multer from "multer";
import path from "path";
import db from "../db.js";  // ตรวจสอบให้แน่ใจว่า db.js อยู่ในที่ที่ถูกต้อง
import fs from "fs";
import { verifyToken, authorizeRole } from "./verifyToken.js";  // ตรวจสอบว่า verifyToken และ authorizeRole ทำงานถูกต้อง

const router = express.Router();

// ตั้งค่าการอัปโหลดรูปภาพ
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });


// ดึงรายการครุภัณฑ์
router.get("/assets", verifyToken, (req, res) => {
  const userId = req.user.id;
  const userRole = req.user.role.toUpperCase();

  let sql;
  let params = [];

  if (userRole === "STUDENT") {
  sql = `
    SELECT 
      a.id,
      a.name,
      a.image_url,
      a.description,

      CASE
        WHEN br.requester_id = ? AND br.status = 'pending' THEN 'pending'
        WHEN br.requester_id = ? AND br.status = 'approved' THEN 'borrowed'
        WHEN br.requester_id = ? AND br.status = 'borrowed' THEN 'borrowed'
        ELSE a.status
      END AS status,

      DATE_FORMAT(br.borrow_date, '%Y-%m-%d') AS borrow_date,
      DATE_FORMAT(br.return_date, '%Y-%m-%d') AS return_date

    FROM assets a
    LEFT JOIN (
      SELECT br1.*
      FROM borrow_requests br1
      JOIN (
        SELECT asset_id, MAX(id) AS latest_id
        FROM borrow_requests
        GROUP BY asset_id
      ) x ON br1.id = x.latest_id
    ) br ON br.asset_id = a.id

    WHERE a.status != 'disabled'
  `;

  params = [userId, userId, userId];
} else if (userRole === "LECTURER" || userRole === "STAFF") {
  sql = `
    SELECT
      a.id AS asset_id,
      a.name AS asset_name,
      a.image_url,
      a.description,

      -- ใช้สถานะล่าสุด ถ้าไม่มี → ใช้สถานะใน assets
      COALESCE(
   CASE 
     WHEN br_latest.status = 'approved' THEN 'borrowed'
     ELSE br_latest.status
   END,
   a.status
) AS asset_status
,

      br_latest.id AS request_id,
      br_latest.requester_id,
      u.full_name AS student_name,

      DATE_FORMAT(br_latest.borrow_date, '%Y-%m-%d') AS borrow_date,
      DATE_FORMAT(br_latest.return_date, '%Y-%m-%d') AS return_date

    FROM assets a

    LEFT JOIN (
      SELECT br1.*
      FROM borrow_requests br1
      JOIN (
        SELECT asset_id, MAX(id) AS latest_id
        FROM borrow_requests
        GROUP BY asset_id
      ) x ON br1.id = x.latest_id
    ) br_latest ON br_latest.asset_id = a.id

    LEFT JOIN users u ON u.id = br_latest.requester_id

    ORDER BY a.id ASC;
  `;
}





  db.query(sql, params, (err, results) => {
    if (err) {
      console.error("❌ [DB] Error fetching assets:", err);
      return res.status(500).json({ message: "Database error" });
    }

    console.log(`📦 [ASSETS] Role=${userRole} | UserID=${userId} | ${results.length} records fetched`);
    results.forEach((r) => {
      console.log(
        `   🔹 Asset #${r.asset_id || r.id} (${r.asset_name || r.name}) → ${r.asset_status || r.status}`
      );
    });

    res.json(results);
  });
});




// เพิ่มครุภัณฑ์ (เฉพาะ Staff)
router.post(
  "/assets",
  verifyToken,
  authorizeRole("STAFF"),
  upload.single("image"),
  (req, res) => {
    const { name, status } = req.body;
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    // ตรวจสอบค่าที่จำเป็น
    if (!name) {
      return res.status(400).json({ message: "Name is required" });
    }

    // ✅ ดึง code ล่าสุดจากฐานข้อมูล
    const getLastCodeSql = "SELECT code FROM assets ORDER BY id DESC LIMIT 1";
    db.query(getLastCodeSql, (err, results) => {
      if (err) {
        console.error("❌ Database Error (getLastCode):", err);
        return res.status(500).json({ message: "Database error" });
      }

      // ✅ สร้าง code ใหม่
      let newCode = "AS-001";
      if (results.length > 0 && results[0].code) {
        const lastCode = results[0].code; // ตัวอย่าง "AS-009"
        const lastNumber = parseInt(lastCode.split("-")[1]); // 9
        const nextNumber = lastNumber + 1;
        newCode = `AS-${nextNumber.toString().padStart(3, "0")}`; // "AS-010"
      }

      // ✅ บันทึกข้อมูลลงฐานข้อมูล
      const insertSql =
        "INSERT INTO assets (code, name, status, image_url) VALUES (?, ?, ?, ?)";
      db.query(
        insertSql,
        [newCode, name, status || "available", imageUrl],
        (err, result) => {
          if (err) {
            console.error("❌ Database Error (insert):", err);
            return res.status(500).json({ message: "Database error" });
          }

          res.status(201).json({
            message: "✅ Asset added successfully",
            asset: {
              id: result.insertId,
              code: newCode,
              name,
              status: status || "available",
              image_url: imageUrl,
            },
          });
        }
      );
    });
  }
);

// แก้ไขครุภัณฑ์ (เฉพาะ Staff)
// แก้ไขครุภัณฑ์ (เฉพาะ Staff) — PATCH รองรับ multipart
router.patch(
  "/assets/:id",
  verifyToken,
  authorizeRole("STAFF"),
  upload.single("image"),
  (req, res) => {
    const { id } = req.params;
    let { name, description, status } = req.body;

    console.log("----------- PATCH /assets/:id -----------");
    console.log("Incoming fields:", req.body);
    console.log("Incoming file:", req.file);

    const newImageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    const validStatuses = ["available", "pending", "borrowed", "disabled"];
    if (!validStatuses.includes((status || "").toLowerCase())) {
      console.log("Invalid status received → forcing available");
      status = "available";
    }

    // ดึงรูปเก่า
    db.query("SELECT image_url FROM assets WHERE id = ?", [id], (err, result) => {
      if (err) {
        console.log("DB error getOldImage:", err);
        return res.status(500).json({ message: "Database error" });
      }
      if (!result.length) {
        console.log("Asset not found:", id);
        return res.status(404).json({ message: "Asset not found" });
      }

      const oldImage = result[0].image_url;
      console.log("Old image:", oldImage);

      const sql = newImageUrl
        ? "UPDATE assets SET name=?, description=?, status=?, image_url=? WHERE id=?"
        : "UPDATE assets SET name=?, description=?, status=? WHERE id=?";

      const data = newImageUrl
        ? [name, description, status, newImageUrl, id]
        : [name, description, status, id];

      console.log("SQL:", sql);
      console.log("Data:", data);

      db.query(sql, data, (err2) => {
        if (err2) {
          console.log("DB error update:", err2);
          return res.status(500).json({ message: "Database error" });
        }

        // ลบไฟล์เก่าถ้ามีรูปใหม่อัปมาแทน
        if (newImageUrl && oldImage) {
          const oldPath = path.join(process.cwd(), oldImage);
          console.log("Deleting old file:", oldPath);

          if (fs.existsSync(oldPath)) fs.unlink(oldPath, () => {});
        }

        return res.json({
          message: "PATCH updated successfully",
          updated: {
            id,
            name,
            description,
            status,
            image_url: newImageUrl || oldImage,
          },
        });
      });
    });
  }
);



router.delete(
  "/assets/:id",
  verifyToken,
  authorizeRole("STAFF"),
  (req, res) => {
    const { id } = req.params;

    db.query("SELECT image_url FROM assets WHERE id = ?", [id], (err, results) => {
      if (err) return res.status(500).json({ message: "Database error" });
      if (!results.length) return res.status(404).json({ message: "Asset not found" });

      const imageUrl = results[0].image_url;

      db.query("DELETE FROM assets WHERE id=?", [id], (err) => {
        if (err) return res.status(500).json({ message: "Database error" });

        if (imageUrl) {
          const filePath = path.join(process.cwd(), imageUrl);
          if (fs.existsSync(filePath)) fs.unlink(filePath, () => {});
        }

        res.json({ message: "Asset deleted successfully" });
      });
    });
  }
);


export default router;
