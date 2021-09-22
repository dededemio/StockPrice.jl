# Juliaを使った株価の取得と通知
using JSON, DataFrames, Dates, CSV

# 株式名or番号，取得期間，取得間隔を指定してURLを生成
function yahoofinurl(stock, period, interval)
    prefix = "https://query1.finance.yahoo.com/v7/finance/chart/"
    url = prefix * stock * "?range=" * period * "&interval=" * interval * "&indicators=quote&includeTimestamps=true"
    println(url)
    return url
end

# Yahoo!FinanceのJSONからDataFrameに変換
function stockjson2df(json; dropnan=true)
    # 時刻の変換
    unixtime = json["chart"]["result"][1]["timestamp"]
    dt = Dates.unix2datetime.(unixtime) + Dates.Hour(9) # 時刻は日本時間としている．米国時間の場合"+Dates.Hour(9)"を削る

    # DataFrameに代入
    df = DataFrame()
    df."timestamp" = dt
    df."open" = json["chart"]["result"][1]["indicators"]["quote"][1]["open"]
    df."low" = json["chart"]["result"][1]["indicators"]["quote"][1]["low"]
    df."high" = json["chart"]["result"][1]["indicators"]["quote"][1]["high"]
    df."close" = json["chart"]["result"][1]["indicators"]["quote"][1]["close"]
    df."volume" = json["chart"]["result"][1]["indicators"]["quote"][1]["volume"]

    # nothingを削除あるいはNaNに変換
    idx = (df."open" .== nothing) # nothingのある行
    if dropnan
        # 1557.TなどNothingが含まれる物がある．DataFrameからnothingを含む行を削除する．
        df = df[.!idx,:]
    else
        # nothingのある行をNaNにする
        df[idx,2:end] = ones(sum(idx), 5) .* NaN
    end

    # 数値をFloat64にする
    df2 = hcat(df."timestamp", convert.(Float64, df[:,2:end]))
    rename!(df2, "x1" => "timestamp")

    return df2
end

# 株価をYahoo!Financeから取得する．
# stock: 株価ティッカー
# period: 株価取得期間．"1d"なら1日，"1y"なら1年
# interval: 株価間隔．"1m"なら1分
function getstockprice(stock, period="1d", interval="1m")
    # URLの作成
    url = yahoofinurl(stock, period, interval)

    # データ取得・JSON->DataFrameへ変換
    str = read(download(url), String) # urlからjson文字列の取得
    json = JSON.parse(str) # json文字列をパースしてDict型に変換
    df = stockjson2df(json) # JSONからDataFrameに変換
end

# 過去の1日単位のS&P500関連の株価を最大期間(30年分)取得する
function getstockpricepast()
    # 取得対象の銘柄の指定．東証の株価は".T"をつける．
    stocks = ["1557.T" "SPY" "SPXL" "SPXS"]  
    periods = ["10y" "30y" "30y" "30y"]    # 取得期間 1y, 2y, 1d, 2dという指定方法．1557は10yまでしか無い模様．
    savestockprice.(stocks, periods)
end

# 1日足データ，過去最大期間のデータを取得し，CSVで保存する．
function savestockprice(stock, period)
    interval = "1d" # 取得データの間隔
    df = getstockprice(stock, period, interval)
    
    # ファイル名用の時刻文字列
    now = Dates.format(df."timestamp"[end], "_yyyymmdd_HHMMSS")

    # CSV書き込み前に時刻のフォーマットを変更しておく
    df."timestamp" = Dates.format.(df."timestamp", "yyyy/mm/dd HH:MM:SS")

    # CSVへの書き込み
    println("write stock price: " * stock * now * ".csv")
    CSV.write(stock * now * ".csv", df)
end

# 現在のS&P500関連の株価を取得する
function getstockpricenow(stock)
    price = getstockprice(stock, "10m", "1m")."close"[end]
end


