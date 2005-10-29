#!/usr/bin/perl -w

use IO::Socket;

my $listen = IO::Socket::INET->new(
  Proto => 'tcp', LocalPort => 2000, Listen => 5, Reuse => 1
) or die $!;

while (my $client = $listen->accept()) {
  print $client "

----------------------------------------------------------------

Foreground:
\c[[2mDark   \c[[31mRed \c[[32mGreen \c[[33mYellow \c[[34mBlue \c[[35mMagenta \c[[36mCyan \c[[37mWhite \c[[0mReset 
Normal \c[[31mRed \c[[32mGreen \c[[33mYellow \c[[34mBlue \c[[35mMagenta \c[[36mCyan \c[[37mWhite \c[[0mReset 
\c[[1mLight  \c[[31mRed \c[[32mGreen \c[[33mYellow \c[[34mBlue \c[[35mMagenta \c[[36mCyan \c[[37mWhite \c[[0mReset 

Background:
\c[[2mDark   \c[[41mRed \c[[42mGreen \c[[43mYellow \c[[44mBlue \c[[45mMagenta \c[[46mCyan \c[[47mWhite \c[[0mReset 
Normal \c[[41mRed \c[[42mGreen \c[[43mYellow \c[[44mBlue \c[[45mMagenta \c[[46mCyan \c[[47mWhite \c[[0mReset 
\c[[1mLight  \c[[41mRed \c[[42mGreen \c[[43mYellow \c[[44mBlue \c[[45mMagenta \c[[46mCyan \c[[47mWhite \c[[0mReset 

";
  close $client;
  exec "$^X $0";
}