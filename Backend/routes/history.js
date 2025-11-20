import express from "express";
import db from "../db.js";
import { verifyToken, authorizeRole } from "./verifyToken.js";

const router = express.Router();

// ======================================================
// 📜 HISTORY: ดูประวัติการยืม/คืนตามสิทธิ์ (Student / Lecturer / Staff)
// ======================================================
router.get(
  "/borrow/history",
  verifyToken,
  authorizeRole("STUDENT", "LECTURER", "STAFF"),
  (req, res) => {
    const { id: user_id, role } = req.user;
    const roleUpper = role.toUpperCase();

    console.log(`📜 [HISTORY] Role=${roleUpper}, UserID=${user_id}`);

    let sql = `
      SELECT 
        br.id,
        a.name AS asset_name,
        req.full_name AS student_name,
        lec.full_name AS decided_by,
        stf.full_name AS got_back_by,
        br.status,
        DATE_FORMAT(br.borrow_date, '%Y-%m-%d') AS borrow_date,
        DATE_FORMAT(br.return_date, '%Y-%m-%d') AS return_date,
        COALESCE(br.decision_note, '') AS decision_note
      FROM borrow_requests br
      JOIN assets a ON br.asset_id = a.id
      LEFT JOIN users req  ON br.requester_id = req.id
      LEFT JOIN users lec  ON br.decided_by   = lec.id
      LEFT JOIN users stf  ON br.got_back_by  = stf.id
    `;

    const params = [];

    // ---------------------------
    // ROLE: Student → เฉพาะของตัวเอง
    // ---------------------------
    if (roleUpper === "STUDENT") {
      sql += ` WHERE br.requester_id = ?`;
      params.push(user_id);
    }

    // ---------------------------
    // ROLE: Lecturer → เฉพาะที่ตน "decided"
    // ---------------------------
    else if (roleUpper === "LECTURER") {
      sql += ` 
        WHERE br.decided_by = ?
          AND br.status IN ('approved', 'borrowed', 'returned', 'rejected')
      `;
      params.push(user_id);
    }

    // ---------------------------
    // ROLE: Staff → ดูได้ทั้งหมด
    // ---------------------------
    else if (roleUpper === "STAFF") {
      sql += ` WHERE br.status IS NOT NULL`; // 全部 history
    }

    sql += ` ORDER BY br.id DESC`;

    db.query(sql, params, (err, results) => {
      if (err) {
        console.error("❌ [DB] Error fetching history:", err);
        return res.status(500).json({ message: "Database error" });
      }

      console.log(`✅ [HISTORY] ${results.length} record(s) for ${roleUpper}`);
      res.json(results);
    });
  }
);

export default router;
