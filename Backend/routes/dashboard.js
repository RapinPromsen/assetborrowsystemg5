import express from "express";
import db from "../db.js";
import { verifyToken, authorizeRole } from "./verifyToken.js";

const router = express.Router();

// ✅ ดึงจำนวนสินทรัพย์แต่ละสถานะ
router.get(
  "/dashboard/summary",
  verifyToken,
  authorizeRole("STAFF", "LECTURER"),
  (req, res) => {
    const sql = `
      SELECT 
        SUM(status='available') AS available,
        SUM(status='pending') AS pending,
        SUM(status='borrowed') AS borrowed,
        SUM(status='disabled') AS disabled
      FROM assets
    `;

    db.query(sql, (err, rows) => {
      if (err) {
        console.error("❌ [DB] Dashboard summary error:", err);
        return res.status(500).json({ message: "Database error" });
      }

      // ✅ ส่งเฉพาะตัวเลขแบบ integer
      const result = rows[0];
      res.json({
        available: Number(result.available) || 0,
        pending: Number(result.pending) || 0,
        borrowed: Number(result.borrowed) || 0,
        disabled: Number(result.disabled) || 0,
      });
    });
  }
);

export default router;
