package main

import (
	"database/sql"
	"fmt"
	"log"

	"crypto/sha256"
	"os"

	_ "github.com/mattn/go-sqlite3"
	"gonum.org/v1/gonum/mat"
)

func main() {
    hasha := fmt.Sprintf("%x", sha256.Sum256([]byte("402325")))
    fmt.Println(hasha)

    // データベースの初期化
    db_name := "world.db"
    init_world(db_name)

    // データベースの読み込み
    db, err := sql.Open("sqlite3", db_name)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    // affineMatrix := select_three_points(db)

    // fmt.Println(isExistHash(db, affineMatrix))
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

    // angle_x := -4.0
    // affine_matrix_x := []float64{
    //     1, 0, 0, 4,
    //     0, math.Cos(angle_x), math.Sin(angle_x), 5,
    //     0, -1 * math.Sin(angle_x), math.Cos(angle_x), 20,
    //     0, 0, 0, 1,
    // }
    affine_matrix_x_T := []float64{
        1, 0, 0, 4,
        0, 1, 0, 5,
        0, 0, 1, 20,
        0, 0, 0, 1,
    }

    affine_matrix_1 := mat.NewDense(4, 4, affine_matrix_x_T)

    // angle_y := 3.0
    // affine_matrix_y := []float64{
    //     math.Cos(angle_y), math.Sin(angle_y), 0, 6,
    //     -1 * math.Sin(angle_y), math.Cos(angle_y), 0, 8,
    //     0, 0, 1, 10,
    //     0, 0, 0, 1,
    // }
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
                // colorCode := fmt.Sprintf("%02x%02x%02x", uint8(x), uint8(y), uint8(z))
                // hash := fmt.Sprintf("%x", sha256.Sum256([]byte(fmt.Sprintf("%d%d%d", x, y, z))))
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

func select_three_points(db *sql.DB) mat.Matrix {
    // 3 つの hash を指定して、それぞれの座標を取得する
    stmt, err := db.Prepare("SELECT x, y, z, matrix_1_x, matrix_1_y, matrix_1_z, matrix_2_x, matrix_2_y, matrix_2_z FROM world WHERE hash = ?")
    if err != nil {
        log.Fatal(err)
    }
    defer stmt.Close()

    var x_1, y_1, z_1 , matrix_1_x_1, matrix_1_y_1, matrix_1_z_1, matrix_2_x_1, matrix_2_y_1, matrix_2_z_1 float64
    hash1 := fmt.Sprintf("%x", sha256.Sum256([]byte("151113")))
    err = stmt.QueryRow(hash1).Scan(&x_1, &y_1, &z_1, &matrix_1_x_1, &matrix_1_y_1, &matrix_1_z_1, &matrix_2_x_1, &matrix_2_y_1, &matrix_2_z_1)
    if err != nil {
        log.Fatal(err)
    }

    var x_2, y_2, z_2 , matrix_1_x_2, matrix_1_y_2, matrix_1_z_2, matrix_2_x_2, matrix_2_y_2, matrix_2_z_2 float64
    hash2 := fmt.Sprintf("%x", sha256.Sum256([]byte("223226")))
    err = stmt.QueryRow(hash2).Scan(&x_2, &y_2, &z_2, &matrix_1_x_2, &matrix_1_y_2, &matrix_1_z_2, &matrix_2_x_2, &matrix_2_y_2, &matrix_2_z_2)
    if err != nil {
        log.Fatal(err)
    }

    var x_3, y_3, z_3 , matrix_1_x_3, matrix_1_y_3, matrix_1_z_3, matrix_2_x_3, matrix_2_y_3, matrix_2_z_3 float64
    hash3 := fmt.Sprintf("%x", sha256.Sum256([]byte("302720")))
    err = stmt.QueryRow(hash3).Scan(&x_3, &y_3, &z_3, &matrix_1_x_3, &matrix_1_y_3, &matrix_1_z_3, &matrix_2_x_3, &matrix_2_y_3, &matrix_2_z_3)
    if err != nil {
        log.Fatal(err)
    }

    // matrix := mat.NewDense(4, 4, []float64{
    //     x_1, y_1, z_1, 1,
    //     x_2, y_2, z_2, 1,
    //     x_3, y_3, z_3, 1,
    //     1, 1, 1, 1,
    // })

    // matrix_dash := mat.NewDense(4, 4, []float64{
    //     matrix_1_x_1, matrix_1_y_1, matrix_1_z_1, 1,
    //     matrix_1_x_2, matrix_1_y_2, matrix_1_z_2, 1,
    //     matrix_1_x_3, matrix_1_y_3, matrix_1_z_3, 1,
    //     1, 1, 1, 1,
    // })

    // matrixTtimesMatrix := mat.NewDense(4, 4, nil)

    // matrixTtimesMatrix.Mul(matrix.T(), matrix)

    // matrixTtimesMatrixInv := mat.NewDense(4, 4, nil)

    // matrixTtimesMatrixInv.Inverse(matrixTtimesMatrix)

    // matrixTtimesMatrixInvTimesMatrixT := mat.NewDense(4, 4, nil)

    // matrixTtimesMatrixInvTimesMatrixT.Mul(matrixTtimesMatrixInv, matrix.T())

    // matrixTTimesmatrixTimesMatrixInvTimesMatrixDash := mat.NewDense(4, 4, nil)

    // matrixTTimesmatrixTimesMatrixInvTimesMatrixDash.Mul(matrixTtimesMatrixInvTimesMatrixT, matrix_dash)

    // fmt.Println(matrixTTimesmatrixTimesMatrixInvTimesMatrixDash.RawMatrix().Data)

    matrix_1_ext := mat.NewDense(4, 4, []float64{
        x_1, y_1, z_1, 1,
        x_2, y_2, z_2, 1,
        x_3, y_3, z_3, 1,
        1, 1, 1, 1,
    })

    matrix_2_ext := mat.NewDense(4, 4, []float64{
        matrix_2_x_1, matrix_2_y_1, matrix_2_z_1, 1,
        matrix_2_x_2, matrix_2_y_2, matrix_2_z_2, 1,
        matrix_2_x_3, matrix_2_y_3, matrix_2_z_3, 1,
        1, 1, 1, 1,
    })

    leastSquaresMethod := clacLeastSquaresMethod(matrix_1_ext, matrix_2_ext)
    return leastSquaresMethod
}

func isExistHash(db *sql.DB, affine mat.Matrix) bool {
    stmt, err := db.Prepare("SELECT x, y, z, matrix_1_x, matrix_1_y, matrix_1_z, matrix_2_x, matrix_2_y, matrix_2_z FROM world WHERE hash = ?")
    if err != nil {
        log.Fatal(err)
    }
    defer stmt.Close()

    hash := fmt.Sprintf("%x", sha256.Sum256([]byte("404040")))
    var x, y, z , matrix_1_x, matrix_1_y, matrix_1_z, matrix_2_x, matrix_2_y, matrix_2_z float64
    err = stmt.QueryRow(hash).Scan(&x, &y, &z, &matrix_1_x, &matrix_1_y, &matrix_1_z, &matrix_2_x, &matrix_2_y, &matrix_2_z)
    if err != nil {
        return false
    }

    matrix_1_dash := mat.NewDense(1, 4, []float64{ matrix_1_x, matrix_1_y, matrix_1_z, 1 })

    fmt.Println(
        affine.At(0,0), affine.At(0,1), affine.At(0,2), affine.At(0,3),"\n",
        affine.At(1,0), affine.At(1,1), affine.At(1,2), affine.At(1,3),"\n",
        affine.At(2,0), affine.At(2,1), affine.At(2,2), affine.At(2,3),"\n",
        affine.At(3,0), affine.At(3,1), affine.At(3,2), affine.At(3,3),"\n",
    )

    affineTimesMatrix_1_dash := mat.NewDense(1, 4, nil)
    affineTimesMatrix_1_dash.Mul(affine,matrix_1_dash)

    fmt.Println(affineTimesMatrix_1_dash.At(0,0), affineTimesMatrix_1_dash.At(0,1), affineTimesMatrix_1_dash.At(0,2))
    fmt.Println(matrix_2_x, matrix_2_y, matrix_2_z)

    return affineTimesMatrix_1_dash.At(0,0) == matrix_2_x && affineTimesMatrix_1_dash.At(0,1) == matrix_2_y && affineTimesMatrix_1_dash.At(0,2) == matrix_2_z
}


func clacLeastSquaresMethod(P *mat.Dense, Q *mat.Dense) mat.Matrix {
    P_T := P.T()
    P_T_times_P := mat.NewDense(4, 4, nil)
    P_T_times_P.Mul(P_T, P)

    P_T_times_P_inv := mat.NewDense(4, 4, nil)
    P_T_times_P_inv.Inverse(P_T_times_P)

    P_T_times_P_inv_times_P_T := mat.NewDense(4, 4, nil)
    P_T_times_P_inv_times_P_T.Mul(P_T_times_P_inv, P_T)

    P_T_times_P_inv_times_P_T_times_Q := mat.NewDense(4, 4, nil)
    P_T_times_P_inv_times_P_T_times_Q.Mul(P_T_times_P_inv_times_P_T, Q)

    P_T_times_P_inv_times_P_T_times_Q_T := P_T_times_P_inv_times_P_T_times_Q.T()

    return P_T_times_P_inv_times_P_T_times_Q_T
}