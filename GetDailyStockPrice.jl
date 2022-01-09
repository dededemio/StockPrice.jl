# Juliaを使った株価の取得と通知

using DataFrames, Dates, CSV
include("GetStockPrice.jl")

uniqueindex(x) = findfirst.(isequal.(unique(x)), [x]) # 重複しない行のindexを計算

# 株価データの初期化．新たに銘柄追加するときだけこれを実行する
function initdailystockprice(stock)
    range = "7d"    # 取得データの期間
    interval = "1m" # 取得データの間隔
    df = getstockprice(stock, range, interval)

    # CSV書き込み前に時刻のフォーマットを変更しておく
    dtfmt = "yyyy/mm/dd HH:MM:SS"
    df."timestamp" = Dates.format.(df."timestamp", dtfmt)

    # CSVへの書き込み
    println("write stock price: " * stock * ".csv")
    CSV.write("./data/" * stock * ".csv", df)
end

# 1日分の1分足データを取得し，CSVにマージする
function savedailystockprice(stock)
    range = "1d"    # 取得データの期間
    interval = "1m" # 取得データの間隔
    today = getstockprice(stock, range, interval)
    dtfmt = "yyyy/mm/dd HH:MM:SS"

    # CSV読み込み
    past = DataFrame(CSV.File("./data/" * stock * ".csv", header = true))
    past."timestamp" = DateTime.(past."timestamp", dtfmt)

    # データを結合
    all = vcat(past, today)

    # 重複データを削除
    all = all[uniqueindex(all.timestamp), :]

    # 日付順でソート
    all = sort(all)

    # CSV書き込み前に時刻のフォーマットを変更しておく
    all."timestamp" = Dates.format.(all."timestamp", dtfmt)

    # CSVへの書き込み
    println("write stock price: " * stock * ".csv")
    CSV.write("./data/" * stock * ".csv", all)
end

function main()
    # 取得対象の銘柄の指定．東証の株価は".T"をつける．
    stocks = ["1557.T" "SPY" "SPXL" "SPXS" "TECL" "CURE" "SOXL" "DRN" "TNA" "EDC"]
    try
        savedailystockprice.(stocks)
    catch err
        println(err)
    end
end

main()


