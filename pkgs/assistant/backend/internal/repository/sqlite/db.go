package sqlite

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"github.com/mattn/go-sqlite3"
)

var registerDriverOnce sync.Once

func findVec0Extension() string {
	candidates := []string{
		os.Getenv("SQLITE_VEC_PATH"),
		"/run/current-system/sw/lib/vec0.so",
		"/usr/lib/vec0.so",
		"/usr/local/lib/vec0.so",
	}
	matches, _ := filepath.Glob("/nix/store/*-sqlite-vec-*/lib/vec0.so")
	candidates = append(candidates, matches...)

	for _, p := range candidates {
		if p != "" {
			if _, err := os.Stat(p); err == nil {
				return p
			}
		}
	}
	return ""
}

func registerCustomSQLiteDriver(vecPath string) {
	registerDriverOnce.Do(func() {
		sql.Register("sqlite3_custom", &sqlite3.SQLiteDriver{
			ConnectHook: func(conn *sqlite3.SQLiteConn) error {
				if vecPath != "" {
					if err := conn.LoadExtension(vecPath, "sqlite3_vec_init"); err != nil {
						fmt.Printf("[RAG DB] Auto-load vec0 extension (%s) thất bại: %v\n", vecPath, err)
					} else {
						fmt.Printf("[RAG DB] Kích hoạt extension sqlite-vec thành công: %s\n", vecPath)
					}
				}
				return nil
			},
		})
	})
}

// OpenRAGDB mở cơ sở dữ liệu SQLite hỗ trợ FTS5 và sqlite-vec
func OpenRAGDB(dbPath string) (*sql.DB, string, error) {
	vecExt := findVec0Extension()
	driverName := "sqlite3"
	if vecExt != "" {
		registerCustomSQLiteDriver(vecExt)
		driverName = "sqlite3_custom"
	}

	actualPath := dbPath
	if actualPath == "" {
		actualPath = ":memory:"
	} else {
		home, _ := os.UserHomeDir()
		userRAGDir := filepath.Join(home, ".local", "share", "bamos")
		_ = os.MkdirAll(userRAGDir, 0755)

		fi, err := os.Stat(actualPath)
		if err == nil && fi.IsDir() {
			testFile := filepath.Join(actualPath, ".write_test")
			if wErr := os.WriteFile(testFile, []byte("ok"), 0644); wErr != nil {
				actualPath = filepath.Join(userRAGDir, "rag_knowledge.sqlite")
			} else {
				_ = os.Remove(testFile)
				actualPath = filepath.Join(actualPath, "rag_knowledge.sqlite")
			}
		} else {
			dir := filepath.Dir(actualPath)
			if err := os.MkdirAll(dir, 0755); err != nil {
				actualPath = filepath.Join(userRAGDir, "rag_knowledge.sqlite")
			}
		}
	}

	dsn := fmt.Sprintf("%s?_journal_mode=WAL", actualPath)
	db, err := sql.Open(driverName, dsn)
	if err != nil {
		return nil, vecExt, err
	}

	if err := db.Ping(); err != nil {
		fmt.Printf("[RAG DB] Cảnh báo ping SQLite: %v\n", err)
	}

	initSchema(db, vecExt)
	return db, vecExt, nil
}

func initSchema(db *sql.DB, vecExt string) {
	_, _ = db.Exec(`
		CREATE TABLE IF NOT EXISTS documents (
			id TEXT PRIMARY KEY,
			source TEXT,
			title TEXT,
			domain TEXT,
			content TEXT,
			embedding BLOB,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		);
	`)

	_, _ = db.Exec(`
		CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
			id UNINDEXED,
			title,
			content,
			tokenize = 'unicode61 remove_diacritics 2'
		);
	`)

	if vecExt != "" {
		_, _ = db.Exec(`
			CREATE VIRTUAL TABLE IF NOT EXISTS documents_vec USING vec0(
				doc_id text partition key,
				embedding float[1024] distance_metric=cosine
			);
		`)
	}
}
