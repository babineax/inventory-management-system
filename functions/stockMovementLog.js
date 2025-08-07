const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.logStockMovementOnUpdate = functions.firestore
  .document("coll_stock/{stockId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const stockId = context.params.stockId;

    const oldQty = before.item_qty;
    const newQty = after.item_qty;

    // Exit if quantity didn't change
    if (oldQty === newQty) return null;

    const changeAmount = newQty - oldQty;
    const reason = changeAmount > 0 ? "restock" : "stock out";

    const logEntry = {
      itemId: stockId,
      itemName: after.item_name,
      change: changeAmount,
      quantityAfter: newQty,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      reason: reason,
      note: "Auto-logged by Cloud Function",
      userId: after.updated_by || "system",
    };

    await db.collection("coll_stock_logs").add(logEntry);

    return null;
  });
