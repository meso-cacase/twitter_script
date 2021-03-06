#!/usr/bin/perl

# Twitterで特定ユーザのフォロー一覧を取得し、タブ区切りテキスト形式で出力する
#
# Usage:  ./get_friends.pl  [USER]
#
# USER（screen name）で指定したユーザのフォロー一覧を取得する
# 省略時は自分自身のフォロー一覧を取得する
#
# 必要なモジュール：
# Net::Twitter::Lite::WithAPIv1_1
# Encode
#
# あらかじめ https://dev.twitter.com/apps より登録して、OAuth認証に必要な
# consumer_key, consumer_secret, access_token, access_token_secret を取得し、
# ソース内の twitter_oauth サブルーチン内に記載すること
#
# 2011-09-13 Yuki Naito (@meso_cacase)
# 2013-06-12 Yuki Naito (@meso_cacase) Twitter API v1.1に対応
# 2014-01-23 Yuki Naito (@meso_cacase) Net::Twitter::Lite::WithAPIv1_1に乗り換え

use warnings ;
use strict ;
eval 'use Net::Twitter::Lite::WithAPIv1_1 ; 1' or  # Twitter APIモジュール
	die "ERROR : cannot load Net::Twitter::Lite::WithAPIv1_1\n" ;
eval 'use Encode ; 1' or                           # 文字コード変換
	die "ERROR : cannot load Encode\n" ;

# OAuth認証
my $twit ;
twitter_oauth() ;

# IDリスト取得
my @ids = get_friends($ARGV[0]) ;

# ユーザリストに変換
# 100件ごとに分割して取得
while (my @ids_100 = splice(@ids, 0, 100)){
	my @users = users_lookup(@ids_100) ;
	$" = "\n" ;
	print "@users\n" ;
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
sub get_friends {  # Usage: @ids = get_friends($screen_name) ;
my %arg ;
$_[0] and $arg{'screen_name'} = $_[0] ;  # 省略時は自分になる
$arg{'cursor'} = -1 ;  # 1ページ目は -1 を指定
my @ids ;
while ($arg{'cursor'}){ # 一度に5000までしか取得できないのでcursorを書き換えながら取得を繰り返す
	my $friends_ref = $twit->friends_ids({%arg}) ;
	my $ids_ref = $friends_ref->{'ids'} ;
	push @ids, @$ids_ref ;
	$arg{'cursor'} = $friends_ref->{'next_cursor'} ;
	print STDERR "Fetched: ids=", scalar @$ids_ref, ",next_cursor=$arg{'cursor'}\n" ;
}
return @ids ;
} ;
# ====================
sub users_lookup {  # usage: @userinfo = users_lookup(@user_id_list)
@_ or die "ERROR: users_lookup() : user_id_list is empty\n" ;
scalar (@_) <= 100 or die "ERROR: users_lookup() : user_id_list > 100\n" ;
my $user_id_list = join ',', @_ ;
my $user_ref = $twit->lookup_users({ user_id => $user_id_list }) ;
my @user_info ;
foreach (@$user_ref){
	my $screen_name       = $_->{'screen_name'}       // '' ;
	my $name              = $_->{'name'}              // '' ;
	my $location          = $_->{'location'}          // '' ;
	my $description       = $_->{'description'}       // '' ;
	my $url               = $_->{'url'}               // '' ;
	my $profile_image_url = $_->{'profile_image_url'} // '' ;

	# 改行やタブをスペースに置換
	$name        =~ s/[\n\r\t]/ /g ;
	$location    =~ s/[\n\r\t]/ /g ;
	$description =~ s/[\n\r\t]/ /g ;

	my $userinfo = join "\t", (
		$screen_name,
		$name,
		$location,
		$description,
		$url,
		$profile_image_url
	) ;

	Encode::is_utf8($userinfo) and $userinfo = Encode::encode('utf-8', $userinfo) ;
	push @user_info, $userinfo ;
}
return @user_info ;
} ;
# ====================
