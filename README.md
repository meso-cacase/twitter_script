twitter_script
======================

Twitter APIを利用してツイートやフォロワーの一覧などを取得するPerlスクリプト。
各スクリプトはそれぞれ単独で実行できます。

### home_timeline.pl ###
  Twitterで自分のタイムラインを取得する
  (from [gist:1153778](https://gist.github.com/1153778))

### user_timeline.pl ###
  Twitterで指定ユーザのツイートを取得する
  (from [gist:1153781](https://gist.github.com/1153781))

### get_direct_messages.pl ###
  Twitterでダイレクトメッセージを取得する
  (from [gist:1153782](https://gist.github.com/1153782))

### get_followers.pl ###
  Twitterで特定ユーザのフォロワー一覧を取得する
  (from [gist:1213322](https://gist.github.com/1213322))

### get_friends.pl ###
  Twitterで特定ユーザのフォロー一覧を取得する
  (from [gist:1213324](https://gist.github.com/1213324))

### user_getfav.pl ###
  Twitterで特定ユーザのfavoritesを取得する
  (from [gist:3088629](https://gist.github.com/3088629))


使い方
------

使い方やコマンドオプションは各スクリプト内に書かれています。

OAuth認証をするためには、
 `consumer_key`,
 `consumer_secret`,
 `access_token`,
 `access_token_secret`
の値を、各スクリプトの twitter_oauth サブルーチン内に記載します
（下記の xxxxxxxx... を書き換える）。これらの値を取得するためには
https://dev.twitter.com/apps へのアプリケーション登録が必要です。

```
# ====================
sub twitter_oauth {  # 下記の値は https://dev.twitter.com/apps で取得すること
$twit = Net::Twitter::Lite->new(
	consumer_key => 'xxxxxxxxxxxxxxxxxxxx',
	consumer_secret => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	access_token => 'xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	access_token_secret =>'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
) ;
} ;
# ====================
```

OAuth認証なしでも使える機能があります（詳細は各スクリプト内の説明を参照）。
たとえば user_timeline.pl では、

```
# OAuth認証（OAuth認証しない場合はコメントアウトする）
my $twit ;
twitter_oauth() ;

# OAuth認証しない場合（OAuth認証する場合はコメントアウトする）
# my $twit = Net::Twitter::Lite->new() ;
#
# 【説明】user_timelineはOAuth認証なしでも取得可。ただしAPI制限が異なる
# OAuth認証した場合は毎時350リクエストまで（2011年8月現在）
# OAuth認証しない場合は毎時150リクエストまで（2011年8月現在）
```

という部分があり、OAuth認証しない場合は

```
# OAuth認証（OAuth認証しない場合はコメントアウトする）
# my $twit ;
# twitter_oauth() ;

# OAuth認証しない場合（OAuth認証する場合はコメントアウトする）
my $twit = Net::Twitter::Lite->new() ;
#
# 【説明】user_timelineはOAuth認証なしでも取得可。ただしAPI制限が異なる
# OAuth認証した場合は毎時350リクエストまで（2011年8月現在）
# OAuth認証しない場合は毎時150リクエストまで（2011年8月現在）
```

のように改変してください。その場合は
 `consumer_key`,
 `consumer_secret`,
 `access_token`,
 `access_token_secret`
の値をスクリプト内に記載する必要はありません。


関連情報
--------

+ https://dev.twitter.com/docs/api -
  Twitter REST APIの説明
+ https://dev.twitter.com/apps -
  Twitterのアプリケーション登録。OAuth認証に必要な値を取得できる


ライセンス
--------

Copyright &copy; 2011-2012 Yuki Naito
 ([@meso_cacase](http://twitter.com/meso_cacase))  
This software is distributed under modified BSD license
 (http://www.opensource.org/licenses/bsd-license.php)
