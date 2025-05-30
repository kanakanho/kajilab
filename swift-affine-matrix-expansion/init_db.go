// package main

// import (
// 	"database/sql"
// 	"fmt"
// 	"log"
// 	"math"

// 	"os"

// 	_ "github.com/mattn/go-sqlite3"
// 	"gonum.org/v1/gonum/mat"
// )

// type RotationAngle struct {
//     X float64
//     Y float64
//     Z float64
// }

// type RotationRadius struct {
//     X float64
//     Y float64
//     Z float64
// }

// func (r *RotationAngle) ToRotationRadius() RotationRadius {
//     return RotationRadius{
//         X: math.Pi * r.X / 180.0,
//         Y: math.Pi * r.Y / 180.0,
//         Z: math.Pi * r.Z / 180.0,
//     }
// }

// func (r *RotationRadius) ToRotationAngle() RotationAngle {
//     return RotationAngle{
//         X: 180.0 * r.X / math.Pi,
//         Y: 180.0 * r.Y / math.Pi,
//         Z: 180.0 * r.Z / math.Pi,
//     }
// }

// func ToRotationAngle(m *mat.Dense) RotationAngle {
//     rows, cols := m.Dims()
//     if rows < 3 || cols < 3 {
//         log.Fatalf("ToRotationAngle: matrix dimensions are too small (rows: %d, cols: %d)", rows, cols)
//     }

//     r31 := m.At(2, 0)
//     r32 := m.At(2, 1)
//     r33 := m.At(2, 2)
//     r21 := m.At(1, 0)
//     r11 := m.At(0, 0)
//     r12 := m.At(0, 1)
//     r13 := m.At(0, 2)

//     var pitch float64
//     var roll float64
//     var yaw float64
//     if math.Abs(r31) != 1.0 {
// 		pitch = -math.Asin(r31)
// 		roll = math.Atan2(r32, r33)
// 		yaw = math.Atan2(r21, r11)
//         return RotationAngle{
//             X: roll,
//             Y: pitch,
//             Z: yaw,
//         }
// 	} else {
// 		pitch = math.Pi / 2
// 		if r31 == -1 {
// 			yaw = math.Atan2(r12, r13)
// 		} else {
// 			pitch = -pitch
// 			yaw = math.Atan2(-r12, -r13)
// 		}
// 		roll = 0
// 	}
//     return RotationAngle{
//         X: roll,
//         Y: pitch,
//         Z: yaw,
//     }
// }


// func (r *RotationAngle) ClaculateRotationMatrix(dense *mat.Dense) *mat.Dense {
//     r_rad := r.ToRotationRadius()
//     return r_rad.ClaculateRotationMatrix(dense)
// }

// func (r *RotationRadius) ClaculateRotationMatrix(dense *mat.Dense) *mat.Dense {
//     rotation_x := mat.NewDense(4, 4, []float64{
//         1, 0, 0, 0,
//         0, math.Cos(r.X), -math.Sin(r.X), 0,
//         0, math.Sin(r.X), math.Cos(r.X), 0,
//         0, 0, 0, 1,
//     })

//     rotation_y := mat.NewDense(4, 4, []float64{
//         math.Cos(r.Y), 0, math.Sin(r.Y), 0,
//         0, 1, 0, 0,
//         -math.Sin(r.Y), 0, math.Cos(r.Y), 0,
//         0, 0, 0, 1,
//     })

//     rotation_z := mat.NewDense(4, 4, []float64{
//         math.Cos(r.Z), -math.Sin(r.Z), 0, 0,
//         math.Sin(r.Z), math.Cos(r.Z), 0, 0,
//         0, 0, 1, 0,
//         0, 0, 0, 1,
//     })

//     rotation_matrix := mat.NewDense(4, 4, nil)
//     rotation_matrix.Mul(rotation_x, rotation_y)
//     rotation_matrix.Mul(rotation_matrix, rotation_z)
//     rotation_matrix.Mul(rotation_matrix, dense)

//     return rotation_matrix
// }

// func main() {
//     // データベースの初期化
//     db_name := "world.db"
//     init_world(db_name)
// }

// func init_world(db_name string) {
//     db, err := sql.Open("sqlite3", db_name)
//     if err != nil {
//         log.Fatal(err)
//     }
//     defer db.Close()

//     if _, err := os.Stat(db_name); err == nil {
//         log.Println("Database already exists, skipping initialization.")
//         return
//     } else {
//         _, err = db.Exec("CREATE TABLE world (x INTEGER, y INTEGER, z INTEGER, hash TEXT, matrix_1_x REAL, matrix_1_y REAL, matrix_1_z REAL, matrix_2_x REAL, matrix_2_y REAL, matrix_2_z REAL)")
//         if err != nil {
//             log.Fatal(err)
//         }
//     }

//     stmt, err := db.Prepare("INSERT INTO world (x, y, z, hash, matrix_1_x, matrix_1_y, matrix_1_z, matrix_2_x, matrix_2_y, matrix_2_z) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
//     if err != nil {
//         log.Fatal(err)
//     }
//     defer stmt.Close()

//     affine_matrix_x_T := []float64{
//         1, 0, 0, 4,
//         0, 1, 0, 5,
//         0, 0, 1, 20,
//         0, 0, 0, 1,
//     }

//     rotation_x := RotationAngle{
//         X: 30,
//         Y: 45,
//         Z: 30,
//     }

//     affine_matrix_1 := mat.NewDense(4, 4, affine_matrix_x_T)
//     affine_matrix_1 = rotation_x.ClaculateRotationMatrix(affine_matrix_1)

//     affine_matrix_y_T := []float64{
//         1, 0, 0, 6,
//         0, 1, 0, 8,
//         0, 0, 1, 10,
//         0, 0, 0, 1,
//     }

//     rotation_y := RotationAngle{
//         X: 60,
//         Y: 30,
//         Z: 45,
//     }

//     affine_matrix_2 := mat.NewDense(4, 4, affine_matrix_y_T)
//     affine_matrix_2 = rotation_y.ClaculateRotationMatrix(affine_matrix_2)

//     for x := 0; x <= 50; x++ {
//         for y := 0; y <= 50; y++ {
//             for z := 0; z <= 50; z++ {
//                 hash := fmt.Sprintf("%d%d%d", x, y, z)
//                 world_position := mat.NewDense(4, 1, []float64{float64(x), float64(y), float64(z), 1})

//                 matrix_1 := mat.NewDense(4, 1, nil)
//                 matrix_1.Mul(affine_matrix_1, world_position)
//                 matrix_1_x, matrix_1_y, matrix_1_z := matrix_1.At(0, 0), matrix_1.At(1, 0), matrix_1.At(2, 0)

//                 matrix_2 := mat.NewDense(4, 1, nil)
//                 matrix_2.Mul(affine_matrix_2, matrix_1)
//                 matrix_2_x, matrix_2_y, matrix_2_z := matrix_2.At(0, 0), matrix_2.At(1, 0), matrix_2.At(2, 0)

//                 _, err = stmt.Exec(x, y, z, hash, matrix_1_x, matrix_1_y, matrix_1_z, matrix_2_x, matrix_2_y, matrix_2_z)
//                 if err != nil {
//                     log.Fatal(err)
//                 }
//             }
//         }
//     }
// }
