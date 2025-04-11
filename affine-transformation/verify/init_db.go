package main

import (
	"database/sql"
	"fmt"
	"log"

	"os"

	_ "github.com/mattn/go-sqlite3"
	"gonum.org/v1/gonum/mat"
)

func main() {
    // データベースの初期化
    db_name := "world.db"
    init_world(db_name)
}

func init_world(db_name string) {
    if _, err := os.Stat(db_name); err == nil {
        return
    }

    db, err := sql.Open("sqlite3", db_name)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    _, err = db.Exec("CREATE TABLE world (x INTEGER, y INTEGER, z INTEGER, hash TEXT, matrix_1_x REAL, matrix_1_y REAL, matrix_1_z REAL, matrix_2_x REAL, matrix_2_y REAL, matrix_2_z REAL)")
    if err != nil {
        log.Fatal(err)
    }

    stmt, err := db.Prepare("INSERT INTO world (x, y, z, hash, matrix_1_x, matrix_1_y, matrix_1_z, matrix_2_x, matrix_2_y, matrix_2_z) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
    if err != nil {
        log.Fatal(err)
    }
    defer stmt.Close()

    affine_matrix_x_T := []float64{
        1, 0, 0, 4,
        0, 1, 0, 5,
        0, 0, 1, 20,
        0, 0, 0, 1,
    }

    affine_matrix_1 := mat.NewDense(4, 4, affine_matrix_x_T)

    affine_matrix_y_T := []float64{
        1, 0, 0, 6,
        0, 1, 0, 8,
        0, 0, 1, 10,
        0, 0, 0, 1,
    }
    affine_matrix_2 := mat.NewDense(4, 4, affine_matrix_y_T)

    for x := 0; x <= 50; x++ {
        for y := 0; y <= 50; y++ {
            for z := 0; z <= 50; z++ {
                hash := fmt.Sprintf("%d%d%d", x, y, z)
                world_position := mat.NewDense(4, 1, []float64{float64(x), float64(y), float64(z), 1})

                matrix_1 := mat.NewDense(4, 1, nil)
                matrix_1.Mul(affine_matrix_1, world_position)
                matrix_1_x, matrix_1_y, matrix_1_z := matrix_1.At(0, 0), matrix_1.At(1, 0), matrix_1.At(2, 0)

                matrix_2 := mat.NewDense(4, 1, nil)
                matrix_2.Mul(affine_matrix_2, matrix_1)
                matrix_2_x, matrix_2_y, matrix_2_z := matrix_2.At(0, 0), matrix_2.At(1, 0), matrix_2.At(2, 0)

                _, err = stmt.Exec(x, y, z, hash, matrix_1_x, matrix_1_y, matrix_1_z, matrix_2_x, matrix_2_y, matrix_2_z)
                if err != nil {
                    log.Fatal(err)
                }
            }
        }
    }
}
