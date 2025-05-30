package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

func initDB() (*sql.DB, error) {
	db, err := sql.Open("sqlite3", "./hashes.db")
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Create table if it doesn't exist
	createTableSQL := `
	CREATE TABLE IF NOT EXISTS hashes (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		hash_a TEXT NOT NULL,
		hash_b TEXT NOT NULL,
		hash_c TEXT NOT NULL,
		hash_d TEXT NOT NULL
	);`
	if _, err := db.Exec(createTableSQL); err != nil {
		return nil, fmt.Errorf("failed to create table: %w", err)
	}

	return db, nil
}

func insertHashes(db *sql.DB, hashA, hashB, hashC, hashD string) error {
	insertSQL := `INSERT INTO hashes (hash_a, hash_b, hash_c, hash_d) VALUES (?, ?, ?, ?)`
	_, err := db.Exec(insertSQL, hashA, hashB, hashC, hashD)
	if err != nil {
		return fmt.Errorf("failed to insert hashes: %w", err)
	}
	return nil
}

func main() {
	db, err := initDB()
	if err != nil {
		log.Fatalf("Error initializing database: %v", err)
	}
	defer db.Close()

	hashMin := 0
	hashMax := 50

	/*
hash値は `{hashMin~hashMaxのいずれか1つ}{hashMin~hashMaxのいずれか1つ}{hashMin~hashMaxのいずれか1つ}` で生成されます
それらのhash値が重複しない様に、4つ選びます
その4つは組み合わせを考える必要はありません
順序のみかんがえればよいです
	*/

	for a := hashMin; a <= hashMax; a+=5 {
		for b := hashMin; b <= hashMax; b+=5 {
			for c := hashMin; c <= hashMax; c+=5 {
				for d := hashMin; d <= hashMax; d+=5 {
					// 重複を避けるために、a, b, c, dの順序を考慮してハッシュを生成
					if a == b || a == c || a == d || b == c || b == d || c == d {
						continue // 重複がある場合はスキップ
					}
					hashA := fmt.Sprintf("%d%d%d", a, b, c)
					hashB := fmt.Sprintf("%d%d%d", b, c, d)
					hashC := fmt.Sprintf("%d%d%d", c, d, a)
					hashD := fmt.Sprintf("%d%d%d", d, a, b)

					if err := insertHashes(db, hashA, hashB, hashC, hashD); err != nil {
						log.Printf("Error inserting hashes (%s, %s, %s, %s): %v", hashA, hashB, hashC, hashD, err)
					}
				}
			}
		}
	}
}
