# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2005-2010 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at 
# http://www.gnu.org/copyleft/gpl.html
#
###############################################################################
package Foswiki::Plugins::RedDotPlugin;
use strict;

###############################################################################


our $VERSION = '$Rev$';
our $RELEASE = '3.00';
our $NO_PREFS_IN_TOPIC = 1;
our $SHORTDESCRIPTION = 'Renders edit-links as little red dots';
our $baseTopic;
our $baseWeb;
our $counter;
our $currentAction;
our $user;

use constant DEBUG => 0; # toggle me

###############################################################################
sub writeDebug {
  #Foswiki::Func::writeDebug("- RedDotPlugin - " . $_[0]) if DEBUG;
  print STDERR "- RedDotPlugin - " . $_[0] . "\n" if DEBUG;
}

###############################################################################
sub initPlugin {
  ($baseTopic, $baseWeb, $user) = @_;

  Foswiki::Func::registerTagHandler('REDDOT', \&renderRedDot);
    
  $counter = 0;
  $baseWeb =~ s/\//\./go;
  $currentAction = '';

  return 1;
}

###############################################################################
sub renderRedDot {
  my ($session, $params, $theTopic, $theWeb) = @_;

  #writeDebug("called renderRedDot($theWeb, $theTopic), parms=".$params->stringify);

  my $theAction = getRequestAction();
  return '' unless $theAction =~ /^view/; 

  my $theWebTopics = $params->{_DEFAULT} || "$theWeb.$theTopic";
  my $theRedirect = $params->{redirect};
  my $theText = $params->{text};
  my $theStyle = $params->{style} || '';
  my $theClass = $params->{class} || '';
  my $theIcon = $params->{icon} || 'pencil';
  my $theGrant = $params->{grant} || '.*';
  my $theTitle = $params->{title};
  my $theAnimate = $params->{animate} || 'on';

  my $mode = 'redDotIconMode';
  if ($theText) {
    if (defined $theText) {
      $mode = 'redDotTextMode';
    } else {
      $mode = 'redDotDefaultMode';
      $theText = '.';
    }
    $theText = "<span>$theText</span>";
  } else {
    $theText = "%JQICON{$theIcon}%";
  }
  if ($theAnimate eq 'on') {
    $mode .= ' redDotAnimated';
  }

  my $query = Foswiki::Func::getCgiQuery();
  unless ($theRedirect) {
    my $redirectPref = Foswiki::Func::getPreferencesValue("REDDOT_REDIRECT");
    if ($redirectPref) {
      $redirectPref = Foswiki::Func::expandCommonVariables($redirectPref);
      my ($redirectWeb, $redirectTopic) = Foswiki::Func::normalizeWebTopicName($baseWeb, $redirectPref);
      $theRedirect = Foswiki::Func::getScriptUrl($redirectWeb, $redirectTopic, 'view');
    } else {
      my $queryString = $query->query_string;

      # SMELL: double quotes, even encoded truncate the redirectto. 
      # so we double encode them
      $queryString =~ s/\%22/\%2522/g;

      $theRedirect = Foswiki::Func::getScriptUrl($baseWeb, $baseTopic, 'view').
        '?'.$queryString;
    }
    $theRedirect .= "#reddot$counter";
  }

  # find the first webtopic that we have access to
  my $thisWeb;
  my $thisTopic;
  my $hasEditAccess = 0;
  my $wikiName = Foswiki::Func::getWikiName();

  foreach my $webTopic (split(/\s*,\s*/, $theWebTopics)) {
    #writeDebug("testing webTopic=$webTopic");

    ($thisWeb, $thisTopic) = 
      Foswiki::Func::normalizeWebTopicName($baseWeb, $webTopic);
    $thisWeb =~ s/\//\./go;

    if (Foswiki::Func::topicExists($thisWeb, $thisTopic)) {
      #writeDebug("checking access on $thisWeb.$thisTopic for $wikiName");
      $hasEditAccess = Foswiki::Func::checkAccessPermission("CHANGE", 
	$wikiName, undef, $thisTopic, $thisWeb);
      if ($hasEditAccess) {
	$hasEditAccess = 0 unless $wikiName =~ /$theGrant/; 
	# SMELL: use the users and groups functions to check
	# if we are in theGrant
      }
      if ($hasEditAccess) {
	#writeDebug("granted");
	last;
      }
    }
  }

  if (!$hasEditAccess) {
    return '';
  }

  #writeDebug("rendering red dot on $thisWeb.$thisTopic for $wikiName");

  # red dotting
  my $result = 
    "<span class='redDot $mode $theClass' ";
  $result .= "style='$theStyle' " if $theStyle;
  $result .=
    '><a name=\'reddot'.($counter++).'\' '.
    'href=\''.
    Foswiki::Func::getScriptUrl($thisWeb,$thisTopic, 'edit', 't'=>time());
  $result .= 
    "&redirectto=".urlEncode($theRedirect) if $theRedirect ne "$thisWeb.$thisTopic";
  $result .= '\' ';
  if ($theTitle) {
    $result .= "title='%ENCODE{\"$theTitle\" type=\"entity\"}%'";
  } else {
    $result .= "title='Edit&nbsp;<nop>$thisWeb.$thisTopic'";
  }
  $result .= ">$theText</a></span>";

  #writeDebug("done renderRedDot");

  # add stuff to head
  Foswiki::Func::addToZone('head', 'REDDOTPLUGIN::CSS', <<'HERE');
<link rel='stylesheet' href='%PUBURLPATH%/%SYSTEMWEB%/RedDotPlugin/reddot.css' media='all' />
HERE

  if ($theAnimate eq 'on') {
    Foswiki::Func::addToZone('script', 'REDDOTPLUGIN::JS', <<'HERE', "JQUERYPLUGIN::FOSWIKI");
<script src='%PUBURLPATH%/%SYSTEMWEB%/RedDotPlugin/reddot.js'></script>
HERE
  }

  return $result;
}

###############################################################################
sub urlEncode {
  my $text = shift;

  $text =~ s/([^0-9a-zA-Z-_.:~!*'()\/%])/'%'.sprintf('%02x',ord($1))/ge;

  return $text;
}

###############################################################################
# take the REQUEST_URI, strip off the PATH_INFO from the end, the last word
# is the action; this is done that complicated as there may be different
# paths for the same action depending on the apache configuration (rewrites, aliases)
sub getRequestAction {

  return $currentAction if $currentAction;

  my $request = Foswiki::Func::getCgiQuery();

  if (defined($request->action)) {
    $currentAction = $request->action();
  } else {
    my $context = Foswiki::Func::getContext();

    # not all cgi actions we want to distinguish set their context
    # so only use those we are sure of
    return 'edit' if $context->{'edit'};
    return 'view' if $context->{'view'};
    return 'save' if $context->{'save'};
    # TODO: more

    # fall back to analyzing the path info
    my $pathInfo = $ENV{'PATH_INFO'} || '';
    $currentAction = $ENV{'REQUEST_URI'} || '';
    if ($currentAction =~ /^.*?\/([^\/]+)$pathInfo.*$/) {
      $currentAction = $1;
    } else {
      $currentAction = 'view';
    }
    #writeDebug("PATH_INFO=$ENV{'PATH_INFO'}");
    #writeDebug("REQUEST_URI=$ENV{'REQUEST_URI'}");
    #writeDebug("currentAction=$currentAction");

  }

  return $currentAction;
}

1;
