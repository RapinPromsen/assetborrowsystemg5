import express from "express";
import db from "../db.js";
import { verifyToken, authorizeRole } from "./verifyToken.js";

const router = express.Router();

// ======================================================
// 🧑‍🎓 STUDENT: ยืมสินทรัพย์ (Borrow Asset)
// ======================================================
router.post("/borrow", verifyToken, authorizeRole("STUDENT"), (req, res) => {
  const { asset_id } = req.body;
  const student_id = req.user.id;

  console.log(`📦 [BORROW REQUEST] Student #${student_id} requests asset #${asset_id}`);

  // 🧩 Step 1: ตรวจว่านักเรียนมีคำขอยืมที่ยังไม่จบหรือไม่
 const checkExistingSql = `
  SELECT COUNT(*) AS count
  FROM borrow_requests
  WHERE requester_id = ?
    AND (
      status IN ('pending', 'approved', 'borrowed')
      OR (
        status = 'returned'
        AND DATE(return_date) = DATE(borrow_date)
        AND DATE(return_date) = CURDATE()
      )
    )
`;


  db.query(checkExistingSql, [student_id], (err, existingResult) => {
    if (err) {
      console.error("❌ [DB] Check existing borrow failed:", err);
      return res.status(500).json({ message: "Database error (check existing)" });
    }

    if (existingResult[0].count > 0) {
      console.warn(`⚠️ [BLOCKED] Student #${student_id} already has an active borrow.`);
      return res.status(400).json({
        message: "You already have an active borrow request. You can only borrow one item at a time.",
      });
    }

    // 🧩 Step 2: ตรวจสอบว่าสินทรัพย์พร้อมให้ยืมหรือไม่
    const checkAssetSql = `SELECT status FROM assets WHERE id = ?`;
    db.query(checkAssetSql, [asset_id], (err2, assetResult) => {
      if (err2) {
        console.error("❌ [DB] Asset check failed:", err2);
        return res.status(500).json({ message: "Database error (asset check)" });
      }
      if (assetResult.length === 0)
        return res.status(404).json({ message: "Asset not found" });

      const assetStatus = assetResult[0].status.toLowerCase();
      console.log(`🔍 [ASSET STATUS] Asset #${asset_id} is '${assetStatus}'`);

      if (["borrowed", "pending", "disabled"].includes(assetStatus)) {
        console.warn(`⚠️ [BLOCKED] Asset #${asset_id} is not available.`);
        return res.status(400).json({
          message: `Asset is currently '${assetStatus}' and cannot be borrowed.`,
        });
      }

      // 🧩 Step 3: สร้างคำขอยืมใหม่
      const insertSql = `
        INSERT INTO borrow_requests (requester_id, asset_id, borrow_date, return_date, status)
        VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY), 'pending')
      `;
      db.query(insertSql, [student_id, asset_id], (err3, result2) => {
        if (err3) {
          console.error("❌ [DB] Insert borrow failed:", err3);
          return res.status(500).json({ message: "Database error (insert)" });
        }

        console.log(`✅ [BORROW CREATED] Request #${result2.insertId} created.`);

        // 🧩 Step 4: อัปเดตสถานะสินทรัพย์เป็น pending
        const updateAssetSql = `UPDATE assets SET status = 'pending' WHERE id = ?`;
        db.query(updateAssetSql, [asset_id], (err4) => {
          if (err4) {
            console.error("❌ [DB] Update asset status failed:", err4);
            return res.status(500).json({ message: "Failed to update asset status" });
          }

          console.log(`🔁 [ASSET] Asset #${asset_id} status → pending`);
          res.json({
            message: "Borrow request created successfully (Pending)",
            request_id: result2.insertId,
          });
        });
      });
    });
  });
});


// ======================================================
// 👨‍🏫 LECTURER: ดูคำขอยืมสินทรัพย์ที่รออนุมัติ (Pending Requests)
// ======================================================
router.get("/borrow/pending", verifyToken, authorizeRole("LECTURER"), (req, res) => {
  const sql = `
    SELECT 
      br.id AS request_id,
      br.requester_id,
      br.asset_id,
      a.name AS asset_name,
      a.description,
      a.image_url,
      br.status,
      br.borrow_date,
      br.return_date,
      u.full_name AS student_name
    FROM borrow_requests br
    JOIN assets a ON br.asset_id = a.id
    JOIN users u ON br.requester_id = u.id
    WHERE br.status = 'pending'
    ORDER BY br.borrow_date DESC
  `;

  db.query(sql, (err, result) => {
    if (err) {
      console.error("❌ [DB] Error fetching pending requests:", err);
      return res.status(500).json({ message: "Database error" });
    }

    console.log(`📋 [LECTURER FETCH] ${result.length} pending requests`);
    res.json(result);
  });
});



// ======================================================
// 👨‍🏫 LECTURER: อนุมัติคำขอยืม (Approve)
// ======================================================
router.put("/borrow/approve/:id", verifyToken, authorizeRole("LECTURER"), (req, res) => {
  const { id } = req.params;
  const lecturer_id = req.user.id;
  const { note } = req.body;

  console.log(`🟢 [APPROVE] Lecturer #${lecturer_id} approving request #${id}`);

  const getSql = `SELECT asset_id, status FROM borrow_requests WHERE id = ? AND status = 'pending'`;
  db.query(getSql, [id], (err, rows) => {
    if (err) {
      console.error("❌ [DB] Error retrieving request:", err);
      return res.status(500).json({ message: "Database error" });
    }
    if (rows.length === 0) {
      console.warn(`⚠️ [APPROVE FAILED] Request #${id} not found or already processed.`);
      return res.status(400).json({ message: "Request not found or already processed" });
    }

    const assetId = rows[0].asset_id;
    console.log(`📦 [FOUND] Request #${id} → asset #${assetId}`);

    const updateBorrow = `
      UPDATE borrow_requests
      SET status = 'approved', decided_by = ?, decided_at = NOW(), decision_note = ?
      WHERE id = ?
    `;
    db.query(updateBorrow, [lecturer_id, note || null, id], (err2) => {
      if (err2) {
        console.error("❌ [DB] Error approving request:", err2);
        return res.status(500).json({ message: "Database error while approving" });
      }

      const updateAsset = `UPDATE assets SET status = 'borrowed' WHERE id = ?`;
      db.query(updateAsset, [assetId], (err3) => {
        if (err3) {
          console.error("❌ [DB] Error updating asset:", err3);
          return res.status(500).json({ message: "Failed to update asset status" });
        }

        console.log(
  `✅ [APPROVED] Request #${id} approved by lecturer #${lecturer_id}` +
  (note ? ` | 📝 Note: ${note}` : " | (no note)")
);
res.json({ message: "Borrow request approved", note });
      });
    });
  });
});

// ======================================================
// 🔴 LECTURER: ปฏิเสธคำขอยืม (Reject)
// ======================================================
router.put("/borrow/reject/:id", verifyToken, authorizeRole("LECTURER"), (req, res) => {
  const { id } = req.params;
  const lecturer_id = req.user.id;
  const { note } = req.body;

  if (!note || note.trim() === "") {
    return res.status(400).json({ message: "Rejection note is required." });
  }

  console.log(`🔴 [REJECT] Lecturer #${lecturer_id} rejecting request #${id}`);

  const getSql = `SELECT asset_id, status FROM borrow_requests WHERE id = ? AND status = 'pending'`;
  db.query(getSql, [id], (err, rows) => {
    if (err) {
      console.error("❌ [DB] Error retrieving request:", err);
      return res.status(500).json({ message: "Database error" });
    }
    if (rows.length === 0) {
      return res.status(400).json({ message: "Request not found or already processed" });
    }

    const assetId = rows[0].asset_id;

    const updateBorrow = `
      UPDATE borrow_requests
      SET status = 'rejected', decided_by = ?, decided_at = NOW(), decision_note = ?
      WHERE id = ?
    `;
    db.query(updateBorrow, [lecturer_id, note.trim(), id], (err2) => {
      if (err2) {
        console.error("❌ [DB] Error rejecting request:", err2);
        return res.status(500).json({ message: "Database error when rejecting" });
      }

      const updateAsset = `UPDATE assets SET status = 'available' WHERE id = ?`;
      db.query(updateAsset, [assetId], (err3) => {
        if (err3) {
          console.error("❌ [DB] Error updating asset:", err3);
          return res.status(500).json({ message: "Failed to update asset status" });
        }

        console.log(`🚫 [REJECTED] Request #${id} rejected with note: "${note.trim()}"`);
        res.json({ message: "Borrow request rejected", note });
      });
    });
  });
});

// ======================================================
// 🧑‍🔧 STAFF: คืนของ (Return asset)
// ======================================================
router.put("/return/:id", verifyToken, authorizeRole("STAFF"), (req, res) => {
  const { id } = req.params;
  const staff_id = req.user.id;

  console.log(`📦 [RETURN] Staff #${staff_id} attempting to return request #${id}`);

  const checkSql = `
    SELECT br.asset_id, br.status, a.name AS asset_name
    FROM borrow_requests br
    JOIN assets a ON br.asset_id = a.id
    WHERE br.id = ? AND br.status IN ('approved', 'borrowed')
  `;

  db.query(checkSql, [id], (err, result) => {
    if (err) {
      console.error("❌ [DB] Error checking request:", err);
      return res.status(500).json({ message: "Database error" });
    }

    if (result.length === 0) {
      console.warn(`⚠️ [RETURN FAILED] Request #${id} not found or already returned.`);
      return res.status(400).json({ message: "Invalid or already returned" });
    }

    const { asset_id: assetId, asset_name: assetName, status: oldStatus } = result[0];
    console.log(`🔎 [FOUND] Asset '${assetName}' (ID: ${assetId}) currently borrowed.`);

    // 1️⃣ อัปเดต borrow_requests → returned
    const updateBorrowSql = `
      UPDATE borrow_requests
      SET status = 'returned',
          return_date = CURDATE(),
          got_back_by = ?, 
          decided_at = NOW()
      WHERE id = ?
    `;

    db.query(updateBorrowSql, [staff_id, id], (err2) => {
      if (err2) {
        console.error("❌ [DB] Error updating borrow_requests:", err2);
        return res.status(500).json({ message: "Database error" });
      }

      // 2️⃣ เปลี่ยนสินทรัพย์กลับเป็น available
      const updateAssetSql = `UPDATE assets SET status = 'available' WHERE id = ?`;

      db.query(updateAssetSql, [assetId], (err3) => {
        if (err3) {
          console.error("❌ [DB] Error updating asset status:", err3);
          return res.status(500).json({ message: "Failed to update asset status" });
        }

        console.log(`♻️ [ASSET UPDATED] Asset #${assetId} (${assetName}) is now available again.`);
        console.log(`✅ [SUCCESS] Request #${id} successfully returned and asset reset to available.`);

        res.json({
          message: "Item returned successfully by staff",
          request_id: id,
          asset_id: assetId,
          asset_name: assetName,
          returned_by: staff_id,
        });
      });
    });
  });
});



export default router;
