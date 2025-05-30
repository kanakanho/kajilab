import pandas as pd

def generate_hashes(hashMin, hashMax) -> pd.DataFrame:
    hashes = [f"{i:03}{j:03}{k:03}" for i in range(hashMin, hashMax + 1) for j in range(hashMin, hashMax + 1) for k in range(hashMin, hashMax + 1)]
    # 重複しない4つのhash値を選ぶ
    hash_df = pd.DataFrame(columns=['hash_a', 'hash_b', 'hash_c', 'hash_d'])
    for i in range(len(hashes)):
        for j in range(i + 1, len(hashes)):
            for k in range(j + 1, len(hashes)):
                for l in range(k + 1, len(hashes)):
                    hash_df = pd.concat([hash_df, pd.DataFrame([[hashes[i], hashes[j], hashes[k], hashes[l]]], columns=['hash_a', 'hash_b', 'hash_c', 'hash_d'])], ignore_index=True)
    return hash_df

def main():
    hashMin = 0
    hashMax = 50
    hash_df = generate_hashes(hashMin, hashMax)
    hash_df.to_csv('hash_list.csv', index=False)

if __name__ == "__main__":
    main()