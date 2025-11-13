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
    // 🧩 นักเรียนเห็นเฉพาะสินทรัพย์ที่ตัวเองยืมหรือว่าง
    sql = `
      SELECT 
        a.id, a.name, a.image_url, a.description,
        CASE
          WHEN br.requester_id = ? AND br.status = 'pending' THEN 'pending'
          WHEN br.requester_id = ? AND br.status = 'approved' THEN 'borrowed'
          ELSE a.status
        END AS status
      FROM assets a
      LEFT JOIN borrow_requests br 
        ON a.id = br.asset_id 
        AND br.status IN ('pending', 'approved')
      WHERE a.status != 'disabled'
    `;
    params = [userId, userId];

  } else if (userRole === "LECTURER" || userRole === "STAFF") {
    // 👨‍🏫 Lecturer และ 🧑‍🔧 Staff เห็นทุกสินทรัพย์ + request_id
    sql = `
      SELECT 
        a.id AS asset_id,
        a.name AS asset_name,
        a.image_url,
        a.description,
        a.status AS asset_status,
        br.id AS request_id,
        br.requester_id,
        u.full_name AS student_name,
        br.status AS request_status
      FROM assets a
      LEFT JOIN borrow_requests br 
        ON a.id = br.asset_id 
        AND br.status IN ('pending', 'approved', 'borrowed')
      LEFT JOIN users u 
        ON br.requester_id = u.id
      ORDER BY a.id ASC
    `;
  }

  db.query(sql, params, (err, results) => {
    if (err) {
      console.error("❌ [DB] Error fetching assets:", err);
      return res.status(500).json({ message: "Database error" });
    }

    console.log(`📦 [ASSETS] Role=${userRole} | UserID=${userId} | ${results.length} records fetched`);
    results.forEach((r) => {
      console.log(`   🔹 Asset #${r.asset_id || r.id} (${r.asset_name || r.name}) → ${r.asset_status || r.status}`);
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
// แก้ไขครุภัณฑ์ (เฉพาะ Staff)
router.put(
  "/assets/:id",
  verifyToken,
  authorizeRole("STAFF"),
  upload.single("image"),
  (req, res) => {
    const { id } = req.params;
    let { name, description, status } = req.body;
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    console.log(`🟡 [UPDATE] Asset #${id} → name="${name}", status="${status}"`);

    // ✅ ตรวจสอบค่า status ก่อนอัปเดต (กัน error ENUM)
    const validStatuses = ["available", "pending", "borrowed", "disabled"];
    if (!validStatuses.includes((status || "").toLowerCase())) {
      console.warn(
        `⚠️ [UPDATE] Invalid status '${status}' → defaulted to 'available'`
      );
      status = "available";
    }

    // ✅ ดึงชื่อไฟล์เก่าก่อนอัปเดต
    const getOldImageSql = "SELECT image_url FROM assets WHERE id = ?";
    db.query(getOldImageSql, [id], (err, results) => {
      if (err) {
        console.error("❌ Database Error (getOldImage):", err);
        return res.status(500).json({ message: "Database error" });
      }

      const oldImagePath = results[0]?.image_url;

      // ✅ เตรียมคำสั่ง SQL
      const sql = imageUrl
        ? "UPDATE assets SET name=?, description=?, status=?, image_url=? WHERE id=?"
        : "UPDATE assets SET name=?, description=?, status=? WHERE id=?";

      const values = imageUrl
        ? [name, description, status, imageUrl, id]
        : [name, description, status, id];

      console.log("🧩 [UPDATE] SQL:", sql);
      console.log("🧩 [UPDATE] Values:", values);

      db.query(sql, values, (err) => {
        if (err) {
          console.error("❌ Database Error (update):", err);
          return res.status(500).json({ message: "Database error" });
        }

        // ✅ ลบรูปเก่า (เฉพาะกรณีที่อัปโหลดใหม่)
        if (
          imageUrl &&
          oldImagePath &&
          fs.existsSync(path.join(process.cwd(), oldImagePath))
        ) {
          fs.unlink(path.join(process.cwd(), oldImagePath), (err) => {
            if (err)
              console.error("⚠️ Failed to delete old image:", err);
            else console.log(`🗑️ Deleted old image: ${oldImagePath}`);
          });
        }

        console.log(`✅ [UPDATE] Asset #${id} updated successfully`);
        res.json({ message: "✅ Asset updated successfully" });
      });
    });
  }
);


// ลบครุภัณฑ์ (เฉพาะ Staff)
router.delete("/assets/:id", verifyToken, authorizeRole("STAFF"), (req, res) => {
  const { id } = req.params;
  db.query("DELETE FROM assets WHERE id=?", [id], (err) => {
    if (err) return res.status(500).json({ message: "Database error" });
    res.json({ message: "Asset deleted successfully" });
  });
});

export default router;
