# StockPrice.jl
株価データの取得とメールによるアラート通知を行うプログラムです．

## 動作環境
* 以下の環境で動作を確認しています
  - Windows 10 21H1
  - Julia 1.5.3
* 以下のライブラリが必要です
  - JSON
  - Parameters
  - TimeZones
  - Logging
  - DataFrames
  - Dates
  - CSV
  - SMTPClient

## 使い方
1. 本プロジェクトをCloneあるいはZIPダウンロードして任意のフォルダに展開します．
2. 株価の定期取得を実行するには，取得対象のティッカーを`GetDailyStockPrice.jl`で指定し，`GetDailyStockPrice.cmd`をタスクスケジューラから1日1回定期実行します．
3. 株価のアラート通知を行うには，`./setting/`以下に設定ファイルを設置し，`AlertStockPrice.cmd`をタスクスケジューラから1日1回定期実行します．
* 詳細は`./doc/README.md`を参照ください．また，[ブログ(白旗製作所)](http://dededemio.blog.fc2.com)を参照ください．

## ライセンス
MITライセンスで公開します．

