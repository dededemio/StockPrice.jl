using SMTPClient, JSON, Dates

# 設定ファイルの作成
function initsmtpsetting()
    setting = Dict(
        "url" => "smtps://smtp.gmail.com:465",
        "from" => "You",
        "username" => "you@gmail.com",
        "passwd" => "yourgmailpassword"
    )
    json = JSON.json(setting)
    open("./setting/smtp.json", "w") do f
        print(f, json)
    end
end

# 設定ファイルの読み込み
function readsmtpsetting()
    str = open(f -> read(f, String), "./setting/smtp.json")
    setting = JSON.parse(str)
    return setting
end

# タイトルと本文を指定すると，自分のメールアカウントを使って自分にメールを送る
function sendmail(subject::String, message::String)
    setting = readsmtpsetting()
    opt = SendOptions(
        isSSL=true,
        username=setting["username"],
        passwd=setting["passwd"])
    # Provide the message body as RFC5322 within an IO
    dtstr = Dates.format(Dates.now(), "e, dd u YYYY HH:MM:SS +0900")
    body = IOBuffer(
        "Date: " * dtstr * "\r\n" *
        "From: " * setting["from"] * " <" * setting["username"] * ">\r\n" *
        "To: " * setting["username"] * "\r\n" *
        "Subject: " * subject * "\r\n" *
        "\r\n" *
        message * 
        "\r\n")
    url = setting["url"]
    rcpt = ["<" * setting["username"] * ">"]
    from = "<" * setting["username"] * ">"
    resp = send(url, rcpt, from, body, opt)
end
