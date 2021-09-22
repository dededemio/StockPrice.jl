# Juliaを使った株価のアラート通知
using JSON, Parameters, TimeZones, Logging
# cd(raw"C:\workspace\StockPrice.jl") # for debug
include("SendGmail.jl")
include("GetStockPrice.jl")

# -----------------------------------------
# アラート設定
# -----------------------------------------
@with_kw mutable struct AlertSetting
    stock::String   # 株価ティッカー
    func::String    # アラート関数
    value::Float64   # アラートのしきい値とする値
    enable::Bool  # アラートの有効化フラグ
    alerted::Bool # アラートがその日に上がったことを示すフラグ
end

# 設定ファイルの作成
function initalertsetting()
    settings = Dict(
        "stock" => "SPXL",
        "func" => "checklowerlimit",
        "value" => 1.0,
        "enable" => true,
        "alerted" => false
    )
    json = JSON.json(settings)
    open("./setting/SPXL_alert_setting.json", "w") do f
        print(f, json)
    end
end

## 設定をDictで読み取りstructにマッピングする-----------------
# 参考：https://matsueushi.github.io/posts/julia-mapping-nested-dict/
# キーを文字列からシンボルに変換する関数
keytosymbol(x) = Dict(Symbol(k) => v for (k, v) in pairs(x))
# アラート設定を記載したJSONファイルを読み込みstructのインスタンスを返す
function readalertsetting(jsonfile)
    str = open(f -> read(f, String), jsonfile)
    json = JSON.parse(str)
    setting = AlertSetting(;keytosymbol(json)...)
    return setting
end

# 指定したdirからkeyを含むファイル名からsettingを読み込みリスト化する．
# dir: 設定読み込み先ディレクトリ名
# key: 読み込む設定に該当するキー
function readalertsettings(;key=".json", dir="./")
    filelist = readdir(dir)
    flag = contains.(filelist, key)
    settings_json = filelist[flag]
    settings = readalertsetting.(dir .* settings_json)
    return settings
end

# -----------------------------------------
# アラート関数：動作検証済み
# -----------------------------------------
# 設定下限値を下回った場合にアラート
function checklowerlimit(alert::AlertSetting, prices)
    message = ""
    lowerlimit = alert.value
    if ( sum(prices."close" .< lowerlimit) > 0 )
        alert.alerted = true
        meet = prices[prices."close" .< lowerlimit,:] # 条件に当てはまったデータ
        price = string(round(meet[1,"close"], digits=1))
        dt = meet[1, "timestamp"]
        dtfmt = "YYYY/mm/dd HH:MM:SS"
        message = alert.stock * "の株価が下限値設定を下回りました．\r\n" * 
            "下限値: " * string(lowerlimit) * "\r\n" *
            "時刻: " * Dates.format(dt, dtfmt) * "\r\n" * 
            "株価: " * price * "\r\n"
    end
    return message
end

# -----------------------------------------
# アラート実行
# -----------------------------------------
# 指定されたalertsリストのアラートをチェックして，条件を満たせばアラートメールを発信する
# alerts Array{AlertSetting, 1}
function exealert(alerts)
    # 開場時間取得
    now_tk = now() # 日本時間
    now_ny = now(tz"America/New_York") # 米国東部時間
    open_ny = (Time(now_ny) > Time(9, 30)) && (Time(now_ny) < Time(16, 0)) # NY証券取引所
    open_tk = (Time(now_tk) > Time(9, 00)) && (Time(now_tk) < Time(15, 0)) # 東京証券取引所

    # 開場時にまだアラートが発されていなければ，アラートチェックする
    for alert in alerts
        market_open = ( open_ny && !contains(alert.stock, ".T") ) || 
               ( open_tk &&  contains(alert.stock, ".T") ) # 開場判定
        if !alert.alerted && market_open && alert.enable
            info("株価を確認します: " * alert.stock)
            prices = getstockprice(alert.stock)
            message = eval(:( $(Symbol(alert.func))($alert, $prices) )) # 文字列で与えた関数の評価
            if alert.alerted
                title = "【株価アラート通知】" * alert.stock
                info("アラートメールを発信します．\n" * message)
                sendmail(title, message) # アラートメールの発信
                info("アラートメールを発信しました．")
            end
        end
    end

end


# settingリストからアラートを1つずつ3時まで定期実行する
# それぞれのアラートを個別チェックし，最大日に1回ずつアラートするようにする
function managealerts()
    # アラート定義の取得
    global alerts = readalertsettings(key="alert_setting.json", dir="./setting/")
    [info(alert) for alert in alerts] # アラートの内容出力
    
    # アラートを9時に起動して翌6時まで10分おき想定で実行
    int = 60 * 10 # アラートチェック間隔=10分の秒数
    period = 21 * 3600 # 朝9時～翌6時の秒数
    info("株価を" * string(int / 60) * "分間隔で" * string(period / 60 / 60) * "時間監視します．")
    cb(timer) = (exealert(alerts))
    t = Timer(cb, 0, interval=int)
    wait(t)
    sleep(period) 
    close(t)
end

# ConsoleLoggerに時刻出力を追加
function timed_metafmt(level, _module, group, id, file, line)
    color, prefix, suffix = Logging.default_metafmt(level, _module, group, id, file, line)
    timestamp = Dates.now()
    prefix2 = "$timestamp : $prefix"
    return color, prefix2, suffix
end

# flushを付加
function info(x)
    @info x
    flush(io)
end
function warn(x)
    @warn x
    flush(io)
end

function main()
    # Loggingの設定: log.txtに追加書き込みでInfo以上のログを書き出し．debug, info, warn, errorがあり．
    global io = open("log.txt", "a+")
    logger = Logging.ConsoleLogger(io, Logging.Info, meta_formatter=timed_metafmt)
    Logging.global_logger(logger)
    info(logger)

    managealerts()

    close(io) # close log file
end

main()
