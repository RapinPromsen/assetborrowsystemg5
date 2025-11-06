import express from "express";
import db from "../db.js";
import { verifyToken, authorizeRole } from "./verifyToken.js";

const router = express.Router();

// ======================================================
// 📜 HISTORY: ดูประวัติการยืม/คืน
// ======================================================
// 📜 HISTORY: ดูประวัติการยืม/คืนตามสิทธิ์
router.get(
  "/history",
  verifyToken,
  authorizeRole("STUDENT", "LECTURER", "STAFF"),
  (req, res) => {
    const { id: user_id, role } = req.user;
    const roleUpper = role.toUpperCase();

    console.log(`📜 [HISTORY] Role=${roleUpper}, UserID=${user_id}`);

    let sql = `
      SELECT 
        br.id AS request_id,
        a.name AS asset_name,
        br.status,
        DATE_FORMAT(br.borrow_date, '%Y-%m-%d') AS borrow_date,
        DATE_FORMAT(br.return_date, '%Y-%m-%d') AS return_date,
        u.username AS requester_name,
        l.username AS approved_by,
        s.username AS got_back_by,
        br.decision_note
      FROM borrow_requests br
      JOIN assets a ON br.asset_id = a.id
      LEFT JOIN users u ON br.requester_id = u.id
      LEFT JOIN users l ON br.decided_by = l.id
      LEFT JOIN request_history rh 
          ON rh.request_id = br.id AND rh.new_status = 'returned'
      LEFT JOIN users s ON rh.changed_by_id = s.id
    `;

    let params = [];

    if (roleUpper === "STUDENT") {
      sql += `WHERE br.requester_id = ?`;
      params = [user_id];
    } else if (roleUpper === "LECTURER") {
      sql += `WHERE br.decided_by = ?`;
      params = [user_id];
    } else if (roleUpper === "STAFF") {
      sql += `WHERE 1=1`;
    }

    sql += ` ORDER BY br.borrow_date DESC`;

    db.query(sql, params, (err, results) => {
      if (err) {
        console.error("❌ [DB] Error fetching history:", err);
        return res.status(500).json({ message: "Database error" });
      }

      console.log(`📜 [HISTORY] Role=${roleUpper} | Found ${results.length} records`);
      res.json(results);
    });
  }
);


export default router;
