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

OAuth認証をするために、
 `consumer_key`,
 `consumer_secret`,
 `access_token`,
 `access_token_secret`
の値を、各スクリプトの twitter_oauth サブルーチン内に記載します
（下記の xxxxxxxx... を書き換える）。これらの値を取得するためには
https://dev.twitter.com/apps へのアプリケーション登録が必要です。

```perl
# ====================
sub twitter_oauth {  # 下記の値は https://dev.twitter.com/apps で取得すること
$twit = Net::Twitter::Lite::WithAPIv1_1->new(
	consumer_key        => 'xxxxxxxxxxxxxxxxxxxx',
	consumer_secret     => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	access_token        => 'xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	access_token_secret => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	ssl                 => 1
) ;
} ;
# ====================
```


関連情報
--------

+ https://dev.twitter.com/docs/api  
  Twitter REST APIの説明
+ https://dev.twitter.com/apps  
  Twitterのアプリケーション登録。OAuth認証に必要な値を取得できる


ライセンス
--------

Copyright &copy; 2011-2014 Yuki Naito
 ([@meso_cacase](http://twitter.com/meso_cacase))  
This software is distributed under [modified BSD license]
 (http://www.opensource.org/licenses/bsd-license.php).
