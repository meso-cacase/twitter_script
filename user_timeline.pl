#!/usr/bin/perl

# Twitterで特定ユーザのツイートを取得し、タブ区切りテキスト形式で出力する
#
# Usage:  ./user_timeline.pl  [-u  USER_ID]  [-s  SINCE_ID]  [-m MAX_ID]
#
# Options:
# -u USER_ID, --user=USER_ID
#     USER_ID（数値またはscreen name）で指定したユーザのツイートを取得する
#     省略時は、OAuthで認証した場合は自分自身のツイートを取得する
#     OAuth認証しない場合は省略するとエラーになる
# -s SINCE_ID, --since=SINCE_ID
#     SINCE_ID（数値）よりステータスIDが大きい（つまり新しい）ツイートを取得する
#     更新時などはこの値を指定すると所得済のツイートを転送しなくてすむ
#     省略時は遡れるかぎりツイートを取得する（2011年8月現在約3200件まで）
# -m MAX_ID, --max=MAX_ID
#     MAX_ID（数値）以下のステータスIDをもつ（つまり古い）ツイートを取得する
#     省略時は現在までのツイートを取得する
#
# 必要なモジュール：
# Net::Twitter::Lite
# HTTP::Date
# Encode
#
# OAuth認証する場合は、あらかじめ https://dev.twitter.com/apps より登録して、
# 認証に必要な consumer_key, consumer_secret, access_token, access_token_secret
# を取得し、ソース内の twitter_oauth サブルーチン内に記載すること
#
# 2011-08-14 Yuki Naito (@meso_cacase)

use warnings ;
use strict ;
use Getopt::Long ;
use Math::BigInt ;
eval 'use Net::Twitter::Lite ; 1' or  # Twitter API用モジュール、ない場合はエラー表示
	die "ERROR : cannot load Net::Twitter::Lite\n" ;
eval 'use HTTP::Date ; 1' or          # 日時の変換・フォーマット用、ない場合はエラー表示
	die "ERROR : cannot load HTTP::Date\n" ;
eval 'use Encode ; 1' or              # 文字コード変換、ない場合はエラー表示
	die "ERROR : cannot load Encode\n" ;

# コマンドラインオプションを取得
my $user_id  = '' ;  # デフォルトは空
my $since_id = '' ;  # デフォルトは空
my $max_id   = '' ;  # デフォルトは空
GetOptions(
	'user=s'  => \$user_id,
	'since=s' => \$since_id,
	'max=s'   => \$max_id,
) ;
# 【補足】since_id と max_id は整数なので本来 since=i や max=i で取得すべきだが、
# 値が大きすぎて浮動小数点に変換されてしまうため文字列として取得しパタンチェックする
$since_id and not $since_id =~ /^\d+$/ and die "since_id must be number.\n" ;
$max_id   and not $max_id   =~ /^\d+$/ and die "max_id must be number.\n" ;

# OAuth認証（OAuth認証しない場合はコメントアウトする）
my $twit ;
twitter_oauth() ;

# OAuth認証しない場合（OAuth認証する場合はコメントアウトする）
# my $twit = Net::Twitter::Lite->new() ;
#
# 【説明】user_timelineはOAuth認証なしでも取得可。ただしAPI制限が異なる
# OAuth認証した場合は毎時350リクエストまで（2011年8月現在）
# OAuth認証しない場合は毎時150リクエストまで（2011年8月現在）

# 特定ユーザのツイートを取得
# 一度に取得できないので、$max_idを書き換えながら取得を繰り返す
while (my @timeline = get_user_timeline($since_id,$max_id,50,$user_id)){
	my $last_id = (split /\t/, $timeline[-1])[0] ;
	$max_id = Math::BigInt->new($last_id) - 1 ;  # 桁数が多いのでBigIntで処理する
	$max_id = "$max_id" ;  # 数値から文字列に変換（整数が浮動小数点に変換されるのを防ぐ）
	$" = "\n" ;
	print "@timeline\n" ;
	print STDERR "Fetched: since_id=$since_id,max_id=$max_id,tweets=", scalar @timeline, "\n" ;
}

exit ;

# ====================
sub twitter_oauth {  # 下記の値は https://dev.twitter.com/apps で取得すること
$twit = Net::Twitter::Lite->new(
	consumer_key        => 'xxxxxxxxxxxxxxxxxxxx',
	consumer_secret     => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	access_token        => 'xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	access_token_secret => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
) ;
} ;
# ====================
sub get_user_timeline {  # Usage: @timeline = get_timeline($since_id,$max_id,$count,$user_id) ;
my %arg ;
$_[0] and $arg{'since_id'} = $_[0] ;  # ステータスIDが指定した値より大きいツイートのみ取得するオプション
$_[1] and $arg{'max_id'}   = $_[1] ;  # ステータスIDが指定した値以下のツイートのみ取得するオプション
$arg{'count'} = $_[2] // 200 ;        # 取得するツイート数の最大値。省略時は200（Twitter APIの上限値）
if ($_[3] and $_[3] =~ /^\d+$/){      # 指定したユーザのツイートを取得するオプション
	$arg{'user_id'} = $_[3] ;         # 整数 → user_id
} elsif ($_[3]){
	$arg{'screen_name'} = $_[3] ;     # それ以外 → screen_name
}
$arg{'include_rts'} = 'true' ;        # リツイートも取得
my @tweet_tsv ;

my $timeline_ref = $twit->user_timeline({%arg}) ;
foreach (@$timeline_ref){
	my $tweet_time      = $_->{'created_at'}            // '' ;
	my $tweet_id        = $_->{'id'}                    // '' ;
	my $tweet_text      = $_->{'text'}                  // '' ;
	my $tweet_source    = $_->{'source'}                // '' ;
	my $tweet_replyto   = $_->{'in_reply_to_status_id'} // '' ;
	my $user_screenname = $_->{'user'}{'screen_name'}   // '' ;

	# ローカル時間帯での日付時刻に変換し、整形して出力
	$tweet_time =~ s/\+0000/UTC/ ;
	$tweet_time = HTTP::Date::str2time($tweet_time) ;
	$tweet_time = HTTP::Date::time2iso($tweet_time) ;

	# ツイート内の改行やタブをスペースに置換
	$tweet_text =~ s/[\n\r\t]/ /g ;

	# クライアント名に含まれるリンクを除去
	$tweet_source =~ s/<.*?>//g ;

	my $tweet = "$tweet_id	$tweet_time	$user_screenname	$tweet_text	$tweet_replyto	$tweet_source" ;
	Encode::is_utf8($tweet) and $tweet = Encode::encode('utf-8',$tweet) ;
	push @tweet_tsv, $tweet ;
}
return @tweet_tsv ;
} ;
# ====================
