// SQLite Web Worker for sqflite_common_ffi_web
importScripts("https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/sql-wasm.js");

let db = null;

self.addEventListener("message", async function (e) {
  const { id, method, args } = e.data;

  try {
    let result;

    switch (method) {
      case "init":
        const SQL = await initSqlJs({
          locateFile: (file) =>
            `https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/${file}`,
        });
        db = new SQL.Database();
        result = { success: true };
        break;

      case "execute":
        if (!db) throw new Error("Database not initialized");
        const [sql, params] = args;
        if (sql.trim().toLowerCase().startsWith("select")) {
          const stmt = db.prepare(sql);
          const rows = [];
          stmt.bind(params || []);
          while (stmt.step()) {
            rows.push(stmt.getAsObject());
          }
          stmt.free();
          result = rows;
        } else {
          db.run(sql, params || []);
          result = {
            changes: db.getRowsModified(),
            lastInsertRowid:
              db.exec("SELECT last_insert_rowid()")[0]?.values[0]?.[0] || 0,
          };
        }
        break;

      case "close":
        if (db) {
          db.close();
          db = null;
        }
        result = { success: true };
        break;

      default:
        throw new Error(`Unknown method: ${method}`);
    }

    self.postMessage({ id, result });
  } catch (error) {
    self.postMessage({ id, error: error.message });
  }
});
