#!/usr/bin/perl

# Twitterで自分宛または送信したダイレクトメッセージを取得し、タブ区切りテキスト形式で出力する
#
# Usage:
# ./get_direct_messages.pl  [-s  SINCE_ID]  [-m MAX_ID]
#     自分宛のダイレクトメッセージを取得する
# ./get_direct_messages.pl  -t  [-s  SINCE_ID]  [-m MAX_ID]
#     自分が送信したダイレクトメッセージを取得する
#
# Options:
# -t
#     自分が送信したダイレクトメッセージを取得する
#     省略時は自分宛のダイレクトメッセージを取得する
# -s SINCE_ID, --since=SINCE_ID
#     SINCE_ID（数値）よりステータスIDが大きい（つまり新しい）メッセージを取得する
#     更新時などはこの値を指定すると所得済のメッセージを転送しなくてすむ
#     省略時は遡れるかぎりメッセージを取得する（2013年6月現在約800件まで）
# -m MAX_ID, --max=MAX_ID
#     MAX_ID（数値）以下のステータスIDをもつ（つまり古い）メッセージを取得する
#     省略時は現在までのメッセージを取得する
#
# 必要なモジュール：
# Net::Twitter::Lite::WithAPIv1_1
# HTTP::Date
# Encode
#
# あらかじめ https://dev.twitter.com/apps より登録して、OAuth認証に必要な
# consumer_key, consumer_secret, access_token, access_token_secret を取得し、
# ソース内の twitter_oauth サブルーチン内に記載すること
#
# ダイレクトメッセージ関連のAPIの実行のためには、read, write & direct message
# の権限が付与されたトークンを取得する必要がある
#
# 2011-08-15 Yuki Naito (@meso_cacase)
# 2013-06-12 Yuki Naito (@meso_cacase) Twitter API v1.1に対応
# 2014-01-23 Yuki Naito (@meso_cacase) Net::Twitter::Lite::WithAPIv1_1に乗り換え

use warnings ;
use strict ;
use Getopt::Long ;
use Math::BigInt ;
eval 'use Net::Twitter::Lite::WithAPIv1_1 ; 1' or  # Twitter APIモジュール
	die "ERROR : cannot load Net::Twitter::Lite::WithAPIv1_1\n" ;
eval 'use HTTP::Date ; 1' or                       # 日時の変換・フォーマット
	die "ERROR : cannot load HTTP::Date\n" ;
eval 'use Encode ; 1' or                           # 文字コード変換
	die "ERROR : cannot load Encode\n" ;

# コマンドラインオプションを取得
my $since_id = '' ;
my $max_id   = '' ;
my $sent     = '' ;
GetOptions(
	'since=s' => \$since_id,
	'max=s'   => \$max_id,
	't'       => \$sent,
) ;
# 【補足】since_id と max_id は整数なので本来 since=i や max=i で取得すべきだが、
# 値が大きすぎて浮動小数点に変換されてしまうため文字列として取得しパタンチェックする
$since_id and not $since_id =~ /^\d+$/ and die "since_id must be number.\n" ;
$max_id   and not $max_id   =~ /^\d+$/ and die "max_id must be number.\n" ;

# OAuth認証
my $twit ;
twitter_oauth() ;

# ダイレクトメッセージを取得
# 一度に取得できないので、$max_idを書き換えながら取得を繰り返す
while (my @timeline = get_direct_messages($since_id, $max_id)){
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
$twit = Net::Twitter::Lite::WithAPIv1_1->new(
	consumer_key        => 'xxxxxxxxxxxxxxxxxxxx',
	consumer_secret     => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	access_token        => 'xxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	access_token_secret => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
	ssl                 => 1
) ;
} ;
# ====================
sub get_direct_messages {  # Usage: @timeline = get_direct_messages($since_id, $max_id, $count) ;
my %arg ;
$_[0] and $arg{'since_id'} = $_[0] ;  # ステータスIDが指定した値より大きいメッセージのみ取得するオプション
$_[1] and $arg{'max_id'}   = $_[1] ;  # ステータスIDが指定した値以下のメッセージのみ取得するオプション
$arg{'count'} = $_[2] // 200 ;        # 取得するメッセージ数の最大値。省略時は200（Twitter APIの上限値）
my @tweet_tsv ;

my $timeline_ref = ($sent) ?
	($twit->sent_direct_messages({%arg})) :
	($twit->direct_messages({%arg})) ;

foreach (@$timeline_ref){
	my $tweet_time = $_->{'created_at'}            // '' ;
	my $tweet_id   = $_->{'id'}                    // '' ;
	my $tweet_text = $_->{'text'}                  // '' ;
	my $sender     = $_->{'sender_screen_name'}    // '' ;
	my $recipient  = $_->{'recipient_screen_name'} // '' ;

	# ローカル時間帯での日付時刻に変換し、整形して出力
	$tweet_time =~ s/\+0000/UTC/ ;
	$tweet_time = HTTP::Date::str2time($tweet_time) ;
	$tweet_time = HTTP::Date::time2iso($tweet_time) ;

	# メッセージ内の改行やタブをスペースに置換
	$tweet_text =~ s/[\n\r\t]/ /g ;

	my $tweet = join "\t", (
		$tweet_id,
		$tweet_time,
		$sender,
		"D $recipient $tweet_text"
	) ;

	Encode::is_utf8($tweet) and $tweet = Encode::encode('utf-8', $tweet) ;
	push @tweet_tsv, $tweet ;
}
return @tweet_tsv ;
} ;
# ====================
